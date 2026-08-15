//
//  ClipboardPanel.swift
//  ModernKey
//
//  VIPER View for Clipboard picker panel.
//

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

/// Body of the preview bubble.
final class ClipboardPreviewView: NSView {
    static let inset = NSEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
    
    override func layout() {
        super.layout()
        guard let subview = subviews.first else { return }
        let width = max(0, bounds.width - Self.inset.left - Self.inset.right)
        let height = max(0, bounds.height - Self.inset.top - Self.inset.bottom)
        let y = isFlipped ? Self.inset.top : Self.inset.bottom
        subview.frame = NSRect(x: Self.inset.left, y: y, width: width, height: height)
    }
}

/// The history picker the clipboard hotkey pops up at the text caret.
final class ClipboardPanel: NSObject, ClipboardPanelViewProtocol, NSTableViewDataSource, NSTableViewDelegate {
    static let shared = ClipboardPanel()

    var presenter: ClipboardPresenterProtocol?

    private static let maxVisibleRows = 12
    private var rowHeight: CGFloat = 26
    private var headerHeight: CGFloat = 38
    private var footerHeight: CGFloat = 30
    private static let caretGap: CGFloat = 6
    private static let shortcutLabelTag = 7
    private static let cornerRadius: CGFloat = 20
    private var lastRowShowPreview: Int = 0

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

    @IBOutlet var panel: NonFocusPanel!
    @IBOutlet weak var searchField: NSSearchField!
    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet weak var emptyLabel: NSTextField!
    @IBOutlet var previewView: NSView!
    @IBOutlet weak var previewLabel: NSTextField!
    @IBOutlet weak var previewScroll: NSScrollView!

    private var items: [String] = []
    private var clickMonitor: Any?

    private static let previewMinWidth: CGFloat = 80
    private static let previewMaxWidth: CGFloat = 360
    private static let previewMinHeight: CGFloat = 32
    private static let previewMaxHeight: CGFloat = 320
    private static let previewDelay: TimeInterval = 0.08
    private lazy var preview: NSPopover = {
        let popover = NSPopover()
        popover.behavior = .applicationDefined
        popover.animates = false
        let controller = NSViewController()
        controller.view = previewView
        popover.contentViewController = controller
        return popover
    }()
    private var previewTimer: Timer?
    private var previewDocument: NSView?

    var isOpen: Bool {
        return (presenter?.isOpen ?? false) && panel?.isVisible == true
    }

    override init() {
        super.init()
        _ = ClipboardBuilder.setup(panel: self)
    }

    // MARK: - Presenting / ClipboardPanelViewProtocol

    func present() {
        guard let _ = loadPanelIfNeeded() else { return }
        presenter?.open(at: nil)
    }

    func dismiss() {
        presenter?.close()
    }

    func displayItems(_ items: [String]) {
        self.items = items
        tableView?.reloadData()
        emptyLabel?.isHidden = !items.isEmpty
        resizeToFitRows()
    }

    func updateSelection(index: Int) {
        guard items.indices.contains(index) else { return }
        tableView?.selectRowIndexes(IndexSet(integer: index), byExtendingSelection: false)
        tableView?.scrollRowToVisible(index)
        showPreviewForSelection()
    }

    func showPanel(at caretPoint: CGPoint?) {
        guard let panel = loadPanelIfNeeded() else { return }
        searchField.stringValue = ""
        panel.setFrame(panelFrame(rowCount: items.count), display: false)
        panel.orderFrontRegardless()
        panel.invalidateShadow()
        installClickMonitor()
        showPreviewForSelection()
    }

    func hidePanel() {
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

    override func awakeFromNib() {
        super.awakeFromNib()
        guard let panel = panel else { return }
        panel.level = .popUpMenu
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.hidesOnDeactivate = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        if let background = panel.contentView as? NSVisualEffectView {
            background.wantsLayer = true
            background.layer?.cornerRadius = Self.cornerRadius
            background.layer?.masksToBounds = true
            background.maskImage = Self.roundedMask(radius: Self.cornerRadius)
        }
        tableView.style = .plain
        tableView.refusesFirstResponder = true
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
            previewScroll.autoresizingMask = []
            previewLabel.autoresizingMask = []
            previewScroll.hasHorizontalScroller = false
            previewScroll.scrollerStyle = .overlay
            previewScroll.autohidesScrollers = true
            previewScroll.borderType = .noBorder
            previewScroll.drawsBackground = false
            previewScroll.contentView.drawsBackground = false
        }
        (searchField.cell as? NSSearchFieldCell)?.cancelButtonCell = nil
    }

    // MARK: - Placement

    private func panelHeight(rowCount: Int) -> CGFloat {
        let rows = min(max(rowCount, 1), Self.maxVisibleRows)
        return headerHeight + CGFloat(rows) * rowHeight + footerHeight
    }

    private func resizeToFitRows() {
        guard let panel = panel, panel.isVisible else { return }
        let height = panelHeight(rowCount: items.count)
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
        var anchor: NSPoint
        var caretHeight: CGFloat = 0

        if let caret = focusedCaretScreenRect() {
            anchor = NSPoint(x: caret.minX, y: caret.minY - Self.caretGap)
            caretHeight = caret.height
        } else {
            let mouse = NSEvent.mouseLocation
            anchor = NSPoint(x: mouse.x - size.width / 2, y: mouse.y - Self.caretGap)
        }

        let screen = (NSScreen.screens.first { $0.frame.contains(anchor) }
                      ?? NSScreen.main)?.visibleFrame
            ?? NSRect(origin: .zero, size: size)

        anchor.x = min(max(anchor.x, screen.minX), screen.maxX - size.width)

        var originY = anchor.y - size.height
        if originY < screen.minY {
            let flippedY = anchor.y + size.height + caretHeight + Self.caretGap * 2
            if flippedY <= screen.maxY {
                originY = anchor.y + caretHeight + Self.caretGap * 2
            } else {
                originY = screen.minY
            }
        }
        if originY + size.height > screen.maxY {
            originY = screen.maxY - size.height
        }

        return NSRect(origin: NSPoint(x: anchor.x, y: originY), size: size)
    }

    private func focusedCaretScreenRect() -> NSRect? {
        func axValue(_ element: AXUIElement, _ attribute: String) -> AnyObject? {
            var value: AnyObject?
            let error = AXUIElementCopyAttributeValue(element, attribute as CFString, &value)
            return error == .success ? value : nil
        }

        let systemWide = AXUIElementCreateSystemWide()
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

    static func screenRect(fromAccessibility axRect: CGRect) -> NSRect? {
        let primary = NSScreen.screens.first { $0.frame.origin == .zero } ?? NSScreen.screens.first
        guard let primaryFrame = primary?.frame else { return nil }
        return NSRect(x: axRect.minX,
                      y: primaryFrame.maxY - axRect.maxY,
                      width: max(axRect.width, 1),
                      height: axRect.height)
    }

    @IBAction func onRowClicked(_ sender: Any) {
        let clicked = tableView.clickedRow
        if clicked >= 0 {
            presenter?.didConfirmSelection(index: clicked)
        }
    }

    // MARK: - Hover preview

    func showPreviewForSelection() {
        previewTimer?.invalidate()
        previewTimer = nil
        guard isOpen, items.indices.contains(tableView.selectedRow) else {
            if preview.isShown { preview.performClose(nil) }
            return
        }
        let row = tableView.selectedRow
        previewTimer = Timer.scheduledTimer(withTimeInterval: Self.previewDelay, repeats: false) { [weak self] _ in
            self?.presenter?.didSelectRow(row)
        }
    }

    func showPreview(text: String, forRow row: Int) {
        guard lastRowShowPreview != row else { return }
        lastRowShowPreview = row
        guard let previewLabel = previewLabel, let previewScroll = previewScroll else { return }
        previewLabel.stringValue = text

        let font = previewLabel.font ?? .systemFont(ofSize: 12)
        let horizontalPadding = ClipboardPreviewView.inset.left + ClipboardPreviewView.inset.right
        let verticalPadding = ClipboardPreviewView.inset.top + ClipboardPreviewView.inset.bottom
        let maxTextWidth = Self.previewMaxWidth - horizontalPadding

        // Measure text bounding rect
        let measured = (text as NSString).boundingRect(
            with: NSSize(width: maxTextWidth, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: font])

        // Add small safety margin to prevent glyph clipping / unexpected word wraps
        let textWidth = min(maxTextWidth, max(50, ceil(measured.width) + 8))
        let textHeight = max(16, ceil(measured.height) + 4)

        let screenLimit = (panel.screen ?? NSScreen.main)
            .map { $0.visibleFrame.height - 80 } ?? Self.previewMaxHeight
        let visibleHeight = min(textHeight, min(Self.previewMaxHeight - verticalPadding, screenLimit))

        let targetWidth = min(Self.previewMaxWidth, max(Self.previewMinWidth, textWidth + horizontalPadding))
        let targetHeight = min(Self.previewMaxHeight, max(Self.previewMinHeight, visibleHeight + verticalPadding))
        let targetSize = NSSize(width: targetWidth, height: targetHeight)

        let scrollWidth = targetWidth - horizontalPadding
        let scrollHeight = targetHeight - verticalPadding

        if preview.isShown && preview.contentSize != targetSize {
            preview.close()
        }

        preview.contentSize = targetSize
        previewView.frame = NSRect(origin: .zero, size: targetSize)
        previewScroll.frame = NSRect(x: ClipboardPreviewView.inset.left, y: ClipboardPreviewView.inset.bottom, width: scrollWidth, height: scrollHeight)
        previewDocument?.frame = NSRect(x: 0, y: 0, width: scrollWidth, height: max(scrollHeight, textHeight))
        previewLabel.frame = NSRect(x: 0, y: 0, width: scrollWidth, height: max(scrollHeight, textHeight))
        
        previewView.needsLayout = true
        previewView.layoutSubtreeIfNeeded()

        previewScroll.contentView.scroll(to: .zero)
        previewScroll.reflectScrolledClipView(previewScroll.contentView)

        preview.show(relativeTo: tableView.rect(ofRow: row), of: tableView, preferredEdge: .maxX)
        preview.contentViewController?.view.window?.level = .popUpMenu
    }

    func hidePreview() {
        previewTimer?.invalidate()
        previewTimer = nil
        if preview.isShown {
            preview.performClose(nil)
        }
    }

    // MARK: - Input

    func handleKeyDown(keyCode: CGKeyCode, characters: String, flags: CGEventFlags) -> Bool {
        guard isOpen else { return false }
        let command = flags.contains(.maskCommand)
        let control = flags.contains(.maskControl)
        let option = flags.contains(.maskAlternate)

        switch Int(keyCode) {
        case kVK_Escape:
            dismiss()
        case kVK_Return, kVK_ANSI_KeypadEnter:
            if tableView.selectedRow >= 0 {
                presenter?.didConfirmSelection(index: tableView.selectedRow)
            }
        case kVK_UpArrow:
            move(by: -1)
        case kVK_DownArrow:
            move(by: 1)
        case kVK_PageUp:
            move(by: -Self.maxVisibleRows)
        case kVK_PageDown:
            move(by: Self.maxVisibleRows)
        case kVK_Delete:
            var q = searchField.stringValue
            if !q.isEmpty {
                q.removeLast()
                searchField.stringValue = q
                presenter?.didSearch(query: q)
            }
        default:
            if command, let digit = Int(characters), (1...9).contains(digit) {
                presenter?.didConfirmSelection(index: digit - 1)
            } else if !command && !control && !option,
                      let scalar = characters.unicodeScalars.first,
                      scalar.value >= 32, scalar.value != 127 {
                var q = searchField.stringValue
                q.append(Character(scalar))
                searchField.stringValue = q
                presenter?.didSearch(query: q)
            }
        }
        return true
    }

    private func move(by delta: Int) {
        guard !items.isEmpty else { return }
        let next = min(max(tableView.selectedRow + delta, 0), items.count - 1)
        updateSelection(index: next)
    }

    private func installClickMonitor() {
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
        return items.count
    }

    func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
        let identifier = NSUserInterfaceItemIdentifier("ClipboardTableRowView")
        var rowView = tableView.makeView(withIdentifier: identifier, owner: self) as? ClipboardTableRowView
        if rowView == nil {
            rowView = ClipboardTableRowView()
            rowView?.identifier = identifier
        }
        return rowView
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let identifier = NSUserInterfaceItemIdentifier("ClipboardRow")
        guard items.indices.contains(row),
              let cell = tableView.makeView(withIdentifier: identifier, owner: self) as? NSTableCellView else {
            return nil
        }
        let isSelected = (tableView.selectedRow == row)
        
        cell.textField?.stringValue = items[row]
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\t", with: " ")
            .trimmingCharacters(in: .whitespaces)
        cell.textField?.textColor = isSelected ? .white : .labelColor

        if let sct = cell.viewWithTag(Self.shortcutLabelTag) as? NSTextField {
            sct.stringValue = row < 9 ? "⌘\(row + 1)" : ""
            sct.textColor = isSelected ? NSColor.white.withAlphaComponent(0.8) : .secondaryLabelColor
        }
        return cell
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        showPreviewForSelection()
        tableView.enumerateAvailableRowViews { rowView, row in
            rowView.needsDisplay = true
            if let cell = rowView.view(atColumn: 0) as? NSTableCellView {
                let isSelected = (row == self.tableView.selectedRow)
                cell.textField?.textColor = isSelected ? .white : .labelColor
                if let sct = cell.viewWithTag(Self.shortcutLabelTag) as? NSTextField {
                    sct.textColor = isSelected ? NSColor.white.withAlphaComponent(0.8) : .secondaryLabelColor
                }
            }
        }
    }

    func tableView(_ tableView: NSTableView, didAdd rowView: NSTableRowView, forRow row: Int) {
        rowView.isEmphasized = true
    }
}

/// Custom row view rendering a padded, rounded-corner selection highlight.
final class ClipboardTableRowView: NSTableRowView {
    static let cornerRadius: CGFloat = 6.0
    static let horizontalInset: CGFloat = 8.0
    static let verticalInset: CGFloat = 1.5

    override var isEmphasized: Bool {
        get { true }
        set {}
    }

    override func drawSelection(in dirtyRect: NSRect) {
        guard isSelected else { return }
        let selectionRect = bounds.insetBy(dx: Self.horizontalInset, dy: Self.verticalInset)
        let path = NSBezierPath(roundedRect: selectionRect, xRadius: Self.cornerRadius, yRadius: Self.cornerRadius)
        
        let selectionColor: NSColor
        if #available(macOS 10.14, *) {
            selectionColor = NSColor.controlAccentColor
        } else {
            selectionColor = NSColor.selectedContentBackgroundColor
        }
        selectionColor.setFill()
        path.fill()
    }
}

// MARK: - Module Builder
enum ClipboardBuilder {
    static func setup(panel: ClipboardPanel) -> ClipboardPanel {
        let presenter = ClipboardPresenter()
        let interactor = ClipboardInteractor()
        let router = ClipboardRouter()

        panel.presenter = presenter
        presenter.view = panel
        presenter.interactor = interactor
        presenter.router = router
        interactor.presenter = presenter

        return panel
    }
}
