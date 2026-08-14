import Cocoa
import Carbon
import ApplicationServices

/// Never takes key status: the picker must not pull focus off whatever the user
/// is typing in, so keystrokes are fed in from the engine's event tap instead.
final class NonFocusPanel: NSPanel {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

/// A scroll view's document view is unflipped by default, which puts the origin
/// at the bottom — so "scroll to the start" would land on the last line.
private final class FlippedView: NSView {
    override var isFlipped: Bool { true }
}

/// Body of the preview bubble. It insets its single subview here, in `layout()`,
/// rather than at the call site: NSPopover resizes its content view whenever it
/// pleases, and only re-applying the inset on every pass keeps the padding from
/// being quietly undone.
final class ClipboardPreviewView: NSView {
    static let inset = NSSize(width: 12, height: 8)

    override func layout() {
        super.layout()
        subviews.first?.frame = bounds.insetBy(dx: Self.inset.width, dy: Self.inset.height)
    }
}

/// The history picker the clipboard hotkey pops up at the text caret.
///
/// It deliberately never activates OpenKey — the app you were typing in keeps
/// its focus and its caret, so the paste lands exactly where you left off.
/// Keystrokes arrive from `OpenKeyCallback` while `isOpen` is true.
/// The layout lives in `ClipboardPanel.xib`.
final class ClipboardPanel: NSObject, NSTableViewDataSource, NSTableViewDelegate {
    static let shared = ClipboardPanel()

    private static let maxVisibleRows = 12

    // Measured from the nib rather than hardcoded: the panel's height has to be
    // header + rows + footer *exactly*, or the list is a few points shorter than
    // its content and scrolls when everything already fits. Editing the xib then
    // silently breaks the fit, which is how that bug got in.
    private var rowHeight: CGFloat = 26
    private var headerHeight: CGFloat = 38
    private var footerHeight: CGFloat = 30
    /// Gap between the caret and the top of the panel.
    private static let caretGap: CGFloat = 6
    /// Tag of the ⌘-number label inside the prototype row, set in the xib.
    private static let shortcutLabelTag = 7
    private static let cornerRadius: CGFloat = 20

    /// A resizable rounded rectangle. `behindWindow` blur is clipped by the
    /// view's mask image, not by its layer, so a corner radius alone leaves the
    /// material square at the corners.
    private static func roundedMask(radius: CGFloat) -> NSImage {
        let edge = radius * 2 + 1
        let image = NSImage(size: NSSize(width: edge, height: edge), flipped: false) { rect in
            NSColor.black.setFill()
            NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius).fill()
            return true
        }
        image.capInsets = NSEdgeInsets(top: radius, left: radius, bottom: radius, right: radius)
        image.resizingMode = .stretch
        return image
    }

    // Top-level nib objects need a strong reference; the rest hang off the panel.
    @IBOutlet var panel: NonFocusPanel!
    @IBOutlet weak var searchField: NSSearchField!
    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet weak var emptyLabel: NSTextField!
    /// Contents of the preview bubble; a top-level nib object, so held strongly.
    @IBOutlet var previewView: NSView!
    @IBOutlet weak var previewLabel: NSTextField!
    @IBOutlet weak var previewScroll: NSScrollView!

    private var filtered: [String] = []
    private var query = ""
    private var clickMonitor: Any?

    private static let previewMaxWidth: CGFloat = 360
    private static let previewMaxHeight: CGFloat = 320
    /// Just enough to coalesce a held-down arrow key.
    private static let previewDelay: TimeInterval = 0.08
    private lazy var preview: NSPopover = {
        let popover = NSPopover()
        // .applicationDefined: nothing but us opens or closes it, and it never
        // tries to take focus from the app underneath.
        popover.behavior = .applicationDefined
        popover.animates = false
        let controller = NSViewController()
        controller.view = previewView
        popover.contentViewController = controller
        return popover
    }()
    private var previewTimer: Timer?
    /// Breathing room between the bubble's edge and its text, applied by
    /// `ClipboardPreviewView.layout()`.
    private static var previewInset: NSSize { ClipboardPreviewView.inset }
    private var previewPadding: NSSize {
        NSSize(width: Self.previewInset.width * 2, height: Self.previewInset.height * 2)
    }
    private var previewDocument: NSView?

    var isOpen: Bool { panel?.isVisible == true }

    // MARK: - Presenting

    /// Opens the picker at the text caret, falling back to the mouse when the
    /// focused app exposes no caret (or refuses accessibility queries).
    func present() {
        guard let panel = loadPanelIfNeeded() else { return }
        query = ""
        searchField.stringValue = ""
        filtered = ClipboardManager.shared.history
        reload(selecting: 0)

        panel.setFrame(panelFrame(rowCount: filtered.count), display: false)
        // orderFrontRegardless, not makeKeyAndOrderFront: showing must not steal focus.
        panel.orderFrontRegardless()
        // The shadow is cached from the old shape; recompute it for the rounded one.
        panel.invalidateShadow()
        installClickMonitor()
        showPreviewForSelection()
    }

    func dismiss() {
        guard panel?.isVisible == true else { return }
        hidePreview()
        removeClickMonitor()
        panel?.orderOut(nil)
    }

    // MARK: - Loading

    private func loadPanelIfNeeded() -> NonFocusPanel? {
        if let panel = panel { return panel }
        guard Bundle.main.loadNibNamed("ClipboardPanel", owner: self, topLevelObjects: nil) else {
            return nil
        }
        return panel
    }

    /// Sent to File's Owner once the nib's outlets are hooked up. Everything here
    /// is window behaviour and appearance the nib format has no place for.
    override func awakeFromNib() {
        super.awakeFromNib()
        guard let panel = panel else { return }
        panel.level = .popUpMenu
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.hidesOnDeactivate = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        // The blur itself comes from the xib's NSVisualEffectView; rounding it
        // has to happen here, because a nib applies runtime attributes before
        // the backing layer exists and `layer.cornerRadius` silently does nothing.
        if let background = panel.contentView as? NSVisualEffectView {
            background.wantsLayer = true
            background.layer?.cornerRadius = Self.cornerRadius
            background.layer?.masksToBounds = true
            background.maskImage = Self.roundedMask(radius: Self.cornerRadius)
        }
        // .plain drops the inset margins the default style adds around rows.
        tableView.style = .plain
        tableView.refusesFirstResponder = true
        // Enforced here rather than left to the xib: a scroll view border insets
        // the clip view by a pixel on each side, which makes the content taller
        // than the visible area and shows a scroller even when the rows fit.
        if let scrollView = tableView.enclosingScrollView {
            scrollView.borderType = .noBorder
            scrollView.drawsBackground = false
            scrollView.hasVerticalScroller = true
            scrollView.autohidesScrollers = true
            scrollView.contentView.drawsBackground = false
            scrollView.contentView.frame = scrollView.bounds
            if let content = panel.contentView {
                headerHeight = content.bounds.height - scrollView.frame.maxY
                footerHeight = scrollView.frame.minY
            }
        }
        rowHeight = tableView.rowHeight
        tableView.backgroundColor = .clear

        panel.acceptsMouseMovedEvents = true

        if previewView != nil, let previewScroll = previewScroll, let previewLabel = previewLabel {
            let document = FlippedView(frame: previewLabel.frame)
            document.addSubview(previewLabel)
            previewScroll.documentView = document
            previewDocument = document

            previewLabel.lineBreakMode = .byWordWrapping
            previewLabel.maximumNumberOfLines = 0
            // showPreview lays these out by hand. Leaving the masks on lets the
            // resize of their superview undo that, and the error compounds every
            // time the bubble is shown.
            previewScroll.autoresizingMask = []
            previewLabel.autoresizingMask = []
            // Legacy scrollers reserve a strip of the clip view for themselves —
            // 19pt at the bottom for the horizontal one — which makes the content
            // look too tall for the bubble and shows a scroller that isn't needed.
            previewScroll.hasHorizontalScroller = false
            previewScroll.scrollerStyle = .overlay
            previewScroll.autohidesScrollers = true
            // And a border would inset the clip view by a point on each side.
            previewScroll.borderType = .noBorder
            previewScroll.drawsBackground = false
            previewScroll.contentView.drawsBackground = false
        }
        // Nothing to click: the field only mirrors what the event tap collected.
        (searchField.cell as? NSSearchFieldCell)?.cancelButtonCell = nil
    }

    // MARK: - Placement

    /// Exactly tall enough for the rows on show, so the list never scrolls until
    /// it has more than `maxVisibleRows` in it.
    private func panelHeight(rowCount: Int) -> CGFloat {
        let rows = min(max(rowCount, 1), Self.maxVisibleRows)
        return headerHeight + CGFloat(rows) * rowHeight + footerHeight
    }

    /// Regrows or shrinks the open panel around its top edge as filtering changes
    /// how many rows there are.
    private func resizeToFitRows() {
        guard let panel = panel, panel.isVisible else { return }
        let height = panelHeight(rowCount: filtered.count)
        guard height != panel.frame.height else { return }

        var frame = panel.frame
        frame.origin.y = frame.maxY - height
        frame.size.height = height
        if let visible = (NSScreen.screens.first { $0.frame.intersects(frame) } ?? NSScreen.main)?.visibleFrame,
           frame.minY < visible.minY {
            frame.origin.y = visible.minY
        }
        panel.setFrame(frame, display: true)
        panel.invalidateShadow()
    }

    private func panelFrame(rowCount: Int) -> NSRect {
        let size = NSSize(width: panel.frame.width, height: panelHeight(rowCount: rowCount))

        var anchor: NSPoint          // where the top-left of the panel wants to sit
        var caretHeight: CGFloat = 0
        if let caret = caretRectInScreenCoordinates() {
            anchor = NSPoint(x: caret.minX, y: caret.minY - Self.caretGap)
            caretHeight = caret.height
        } else {
            anchor = NSEvent.mouseLocation
        }

        var origin = NSPoint(x: anchor.x, y: anchor.y - size.height)
        let screen = NSScreen.screens.first { $0.frame.contains(anchor) } ?? NSScreen.main
        if let visible = screen?.visibleFrame {
            origin.x = min(max(origin.x, visible.minX), visible.maxX - size.width)
            // No room underneath the caret — flip the panel above the line.
            if origin.y < visible.minY {
                let above = anchor.y + Self.caretGap * 2 + caretHeight
                origin.y = above + size.height <= visible.maxY ? above : visible.minY
            }
        }
        return NSRect(origin: origin, size: size)
    }

    /// Chromium/Electron apps expose no accessibility tree until asked to build
    /// one. Asking once per process is enough, and it is a no-op elsewhere.
    private var manualAccessibilityEnabled = Set<pid_t>()

    private func axValue(_ element: AXUIElement, _ attribute: String) -> CFTypeRef? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute as CFString, &value) == .success else {
            return nil
        }
        return value
    }

    /// The caret's rectangle, converted from the accessibility API's
    /// top-left-origin screen space into Cocoa's bottom-left-origin one.
    ///
    /// Falls back to the focused control's own frame when the app exposes no
    /// caret; only when even that is missing does the caller drop to the mouse.
    private func caretRectInScreenCoordinates() -> NSRect? {
        if let pid = NSWorkspace.shared.frontmostApplication?.processIdentifier,
           !manualAccessibilityEnabled.contains(pid) {
            manualAccessibilityEnabled.insert(pid)
            let application = AXUIElementCreateApplication(pid)
            AXUIElementSetMessagingTimeout(application, 0.25)
            AXUIElementSetAttributeValue(application, "AXManualAccessibility" as CFString, kCFBooleanTrue)
        }

        let systemWide = AXUIElementCreateSystemWide()
        // This runs on the event tap's thread. An app that is slow to answer must
        // not stall it, or the system disables the tap for timing out.
        AXUIElementSetMessagingTimeout(systemWide, 0.25)

        guard let focusedElement = axValue(systemWide, kAXFocusedUIElementAttribute) else { return nil }
        let element = unsafeBitCast(focusedElement, to: AXUIElement.self)
        AXUIElementSetMessagingTimeout(element, 0.25)

        var axRect = CGRect.zero
        var found = false

        if let selectedRange = axValue(element, kAXSelectedTextRangeAttribute) {
            var boundsValue: CFTypeRef?
            if AXUIElementCopyParameterizedAttributeValue(
                    element, kAXBoundsForRangeParameterizedAttribute as CFString,
                    selectedRange, &boundsValue) == .success,
               let bounds = boundsValue,
               AXValueGetValue(unsafeBitCast(bounds, to: AXValue.self), .cgRect, &axRect),
               axRect.height > 0 {
                found = true
            }
        }

        // No caret on offer — sit under the focused control instead.
        if !found,
           let positionValue = axValue(element, kAXPositionAttribute),
           let sizeValue = axValue(element, kAXSizeAttribute) {
            var origin = CGPoint.zero
            var size = CGSize.zero
            if AXValueGetValue(unsafeBitCast(positionValue, to: AXValue.self), .cgPoint, &origin),
               AXValueGetValue(unsafeBitCast(sizeValue, to: AXValue.self), .cgSize, &size),
               size.height > 0 {
                axRect = CGRect(origin: origin, size: size)
                found = true
            }
        }

        guard found else { return nil }
        return Self.screenRect(fromAccessibility: axRect)
    }

    /// Accessibility measures y downwards from the top-left of the primary
    /// screen; Cocoa measures it upwards from that screen's bottom-left. Displays
    /// stacked above the primary therefore have negative accessibility y.
    static func screenRect(fromAccessibility axRect: CGRect) -> NSRect? {
        let primary = NSScreen.screens.first { $0.frame.origin == .zero } ?? NSScreen.screens.first
        guard let primaryFrame = primary?.frame else { return nil }
        return NSRect(x: axRect.minX,
                      y: primaryFrame.maxY - axRect.maxY,
                      width: max(axRect.width, 1),
                      height: axRect.height)
    }

    // MARK: - Contents

    private func reload(selecting row: Int) {
        tableView.reloadData()
        emptyLabel.isHidden = !filtered.isEmpty
        guard !filtered.isEmpty else { return }
        let index = min(max(row, 0), filtered.count - 1)
        tableView.selectRowIndexes(IndexSet(integer: index), byExtendingSelection: false)
        tableView.scrollRowToVisible(index)
    }

    private func applyQuery() {
        searchField.stringValue = query
        let needle = query.lowercased()
        let history = ClipboardManager.shared.history
        filtered = needle.isEmpty ? history : history.filter { $0.lowercased().contains(needle) }
        // The bubble belongs to a row that may not exist any more.
        hidePreview()
        // Reload first: resizing redisplays the table, and it would still be
        // asking for the old row count against the new, shorter array.
        reload(selecting: 0)
        resizeToFitRows()
    }

    private func move(by delta: Int) {
        guard !filtered.isEmpty else { return }
        let next = min(max(tableView.selectedRow + delta, 0), filtered.count - 1)
        tableView.selectRowIndexes(IndexSet(integer: next), byExtendingSelection: false)
        tableView.scrollRowToVisible(next)
    }

    private func choose(_ index: Int) {
        guard filtered.indices.contains(index) else { return }
        let text = filtered[index]
        dismiss()
        // The target app never lost focus, so the paste can go out immediately.
        ClipboardManager.shared.copyAndPaste(item: text)
    }

    @IBAction func onRowClicked(_ sender: Any) {
        choose(tableView.clickedRow)
    }

    // MARK: - Hover preview

    /// The bubble follows the selected row: rows are truncated to one line, so
    /// this is how the whole item stays readable while moving through the list.
    func showPreviewForSelection() {
        previewTimer?.invalidate()
        previewTimer = nil
        guard isOpen, filtered.indices.contains(tableView.selectedRow) else {
            if preview.isShown { preview.performClose(nil) }
            return
        }
        let row = tableView.selectedRow
        // A short beat so holding an arrow key does not restage the bubble per row.
        previewTimer = Timer.scheduledTimer(withTimeInterval: Self.previewDelay, repeats: false) { [weak self] _ in
            self?.showPreview(forRow: row)
        }
    }

    func showPreview(forRow row: Int) {
        guard filtered.indices.contains(row), let previewLabel = previewLabel else { return }
        let text = filtered[row]
        previewLabel.stringValue = text

        let font = previewLabel.font ?? .systemFont(ofSize: 12)
        let maxTextWidth = Self.previewMaxWidth - previewPadding.width
        // Measure without a height limit, so the label holds the item in full and
        // anything past the bubble's height is reachable by scrolling.
        let measured = (text as NSString).boundingRect(
            with: NSSize(width: maxTextWidth, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: font])
        let textWidth = min(maxTextWidth, ceil(measured.width))
        let textHeight = ceil(measured.height)

        // Never taller than the screen it pops up on.
        let screenLimit = (panel.screen ?? NSScreen.main)
            .map { $0.visibleFrame.height - 80 } ?? Self.previewMaxHeight
        let visibleHeight = min(textHeight, min(Self.previewMaxHeight, screenLimit))

        let size = NSSize(width: textWidth + previewPadding.width,
                          height: visibleHeight + previewPadding.height)
        // Resizing a popover that is already on screen moves its window but leaves
        // the content view at its old origin inside the new frame, which shows up
        // as the padding sliding off to one side. Take it down and put it back up.
        if preview.isShown && preview.contentSize != size {
            preview.close()
        }

        // Size the bubble first: that moves previewView, and only then is it safe
        // to place the scroll view and label inside it.
        preview.contentSize = size
        previewView.frame = NSRect(origin: .zero, size: preview.contentSize)
        // ClipboardPreviewView.layout() insets the scroll view; just ask for it.
        previewView.needsLayout = true
        previewView.layoutSubtreeIfNeeded()
        previewDocument?.frame = NSRect(x: 0, y: 0, width: textWidth, height: textHeight)
        previewLabel.frame = NSRect(x: 0, y: 0, width: textWidth, height: textHeight)
        // Flipped document view, so the start of the text is the origin.
        previewScroll.contentView.scroll(to: .zero)
        previewScroll.reflectScrolledClipView(previewScroll.contentView)

        preview.show(relativeTo: tableView.rect(ofRow: row), of: tableView, preferredEdge: .maxX)
        // Our panel floats at pop-up level; the bubble has to clear it.
        preview.contentViewController?.view.window?.level = .popUpMenu
    }

    func hidePreview() {
        previewTimer?.invalidate()
        previewTimer = nil
        if preview.isShown {
            preview.performClose(nil)
        }
    }

    // MARK: - Input, fed from the engine's event tap

    /// Handles one key press while the picker is open.
    /// Everything is swallowed so stray keys never leak into the app underneath.
    func handleKeyDown(keyCode: CGKeyCode, characters: String, flags: CGEventFlags) -> Bool {
        guard isOpen else { return false }
        let command = flags.contains(.maskCommand)
        let control = flags.contains(.maskControl)
        let option = flags.contains(.maskAlternate)

        switch Int(keyCode) {
        case kVK_Escape:
            dismiss()
        case kVK_Return, kVK_ANSI_KeypadEnter:
            choose(tableView.selectedRow)
        case kVK_UpArrow:
            move(by: -1)
        case kVK_DownArrow:
            move(by: 1)
        case kVK_PageUp:
            move(by: -Self.maxVisibleRows)
        case kVK_PageDown:
            move(by: Self.maxVisibleRows)
        case kVK_Delete:
            if !query.isEmpty {
                query.removeLast()
                applyQuery()
            }
        default:
            if command, let digit = Int(characters), (1...9).contains(digit) {
                choose(digit - 1)
            } else if !command && !control && !option,
                      let scalar = characters.unicodeScalars.first,
                      scalar.value >= 32, scalar.value != 127 {
                query.append(Character(scalar))
                applyQuery()
            }
        }
        return true
    }

    private func installClickMonitor() {
        // Global monitors only see events delivered to *other* apps, so this fires
        // for clicks outside the panel and never for clicks on it.
        if clickMonitor == nil {
            clickMonitor = NSEvent.addGlobalMonitorForEvents(
                matching: [.leftMouseDown, .rightMouseDown, .otherMouseDown]) { [weak self] _ in
                self?.dismiss()
            }
        }
    }

    private func removeClickMonitor() {
        if let monitor = clickMonitor {
            NSEvent.removeMonitor(monitor)
            clickMonitor = nil
        }
    }

    // MARK: - NSTableViewDataSource / Delegate

    func numberOfRows(in tableView: NSTableView) -> Int {
        return filtered.count
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let identifier = NSUserInterfaceItemIdentifier("ClipboardRow")
        // A redisplay can land here with the table's cached row count still ahead
        // of the array, so never trust `row` blindly.
        guard filtered.indices.contains(row),
              let cell = tableView.makeView(withIdentifier: identifier, owner: self) as? NSTableCellView else {
            return nil
        }
        // Multi-line snippets have to collapse onto one line to stay readable.
        cell.textField?.stringValue = filtered[row]
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\t", with: " ")
            .trimmingCharacters(in: .whitespaces)
        (cell.viewWithTag(Self.shortcutLabelTag) as? NSTextField)?.stringValue =
            row < 9 ? "⌘\(row + 1)" : ""
        return cell
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        showPreviewForSelection()
    }

    /// The panel is never key, so ask for the emphasized (blue) selection anyway.
    func tableView(_ tableView: NSTableView, didAdd rowView: NSTableRowView, forRow row: Int) {
        rowView.isEmphasized = true
    }
}
