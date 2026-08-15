//
//  AppInputModeViewController.swift
//  ModernKey
//
//  VIPER View for AppInputMode module.
//

import Cocoa

@objc(AppInputModeViewController)
class AppInputModeViewController: NSViewController, AppInputModeViewProtocol, NSTableViewDataSource, NSTableViewDelegate, NSSearchFieldDelegate {

    @IBOutlet weak var searchField: NSSearchField!
    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet weak var statsLabel: NSTextField!
    @IBOutlet weak var emptyLabel: NSTextField!
    @IBOutlet weak var addButton: NSButton!
    @IBOutlet weak var removeButton: NSButton!
    @IBOutlet weak var clearAllButton: NSButton!

    var presenter: AppInputModePresenterProtocol?
    private var displayedItems: [AppInputModeItem] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = self
        tableView.delegate = self
        searchField.delegate = self
        
        tableView.rowHeight = 36
        tableView.selectionHighlightStyle = .regular
        tableView.allowsEmptySelection = true
        
        if presenter == nil {
            _ = AppInputModeBuilder.setup(view: self)
        }
        presenter?.viewDidLoad()
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        self.view.window?.title = "Quản lý Chế độ Gõ theo Ứng dụng"
        presenter?.viewDidLoad()
    }

    // MARK: - AppInputModeViewProtocol
    func displayItems(_ items: [AppInputModeItem], stats: AppInputModeStats) {
        self.displayedItems = items
        tableView.reloadData()
        
        emptyLabel?.isHidden = !items.isEmpty
        removeButton?.isEnabled = tableView.selectedRow >= 0
        clearAllButton?.isEnabled = stats.totalCount > 0
        
        if stats.totalCount == 0 {
            statsLabel.stringValue = "Chưa có ứng dụng nào được cấu hình"
        } else {
            statsLabel.stringValue = "Tổng số: \(stats.totalCount) ứng dụng (\(stats.vietnameseCount) Tiếng Việt · \(stats.englishCount) Tiếng Anh)"
        }
    }

    func showMessage(_ message: String) {
        let alert = NSAlert()
        alert.messageText = "Thông báo"
        alert.informativeText = message
        alert.addButton(withTitle: "OK")
        
        if let window = self.view.window {
            alert.beginSheetModal(for: window) { _ in }
        } else {
            alert.runModal()
        }
    }

    // MARK: - Actions
    @IBAction func onSearchChanged(_ sender: Any) {
        let query = (sender as? NSSearchField)?.stringValue ?? searchField?.stringValue ?? ""
        presenter?.didSearch(query: query)
    }

    @IBAction func onAddApp(_ sender: Any) {
        presenter?.didTapAddApp(window: self.view.window)
    }

    @IBAction func onRemoveApp(_ sender: Any) {
        let row = tableView.selectedRow
        guard row >= 0, displayedItems.indices.contains(row) else { return }
        let item = displayedItems[row]
        presenter?.didTapDelete(bundleId: item.bundleId)
    }

    @IBAction func onClearAll(_ sender: Any) {
        presenter?.didTapClearAll(window: self.view.window)
    }

    @IBAction func onModeSegmentChanged(_ sender: NSSegmentedControl) {
        let row = sender.tag
        guard displayedItems.indices.contains(row) else { return }
        let item = displayedItems[row]
        let isVietnamese = (sender.selectedSegment == 0)
        presenter?.didToggleLanguage(bundleId: item.bundleId, isVietnamese: isVietnamese)
    }

    @IBAction func onClose(_ sender: Any) {
        self.view.window?.close()
    }

    // MARK: - NSTableViewDataSource & Delegate
    func numberOfRows(in tableView: NSTableView) -> Int {
        return displayedItems.count
    }

    func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
        let identifier = NSUserInterfaceItemIdentifier("AppInputModeRowView")
        var rowView = tableView.makeView(withIdentifier: identifier, owner: self) as? AppInputModeRowView
        if rowView == nil {
            rowView = AppInputModeRowView()
            rowView?.identifier = identifier
        }
        return rowView
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard displayedItems.indices.contains(row) else { return nil }
        let item = displayedItems[row]
        let colId = tableColumn?.identifier.rawValue ?? ""

        if colId == "AppColumn" {
            let identifier = NSUserInterfaceItemIdentifier("AppCellView")
            var cell = tableView.makeView(withIdentifier: identifier, owner: self) as? NSTableCellView
            if cell == nil {
                let cellView = NSTableCellView()
                cellView.identifier = identifier

                let imageView = NSImageView(frame: NSRect(x: 8, y: 4, width: 28, height: 28))
                imageView.imageScaling = .scaleProportionallyUpOrDown
                cellView.imageView = imageView
                cellView.addSubview(imageView)

                let titleLabel = NSTextField(frame: NSRect(x: 44, y: 17, width: 260, height: 16))
                titleLabel.isBezeled = false
                titleLabel.drawsBackground = false
                titleLabel.isEditable = false
                titleLabel.font = .systemFont(ofSize: 13, weight: .medium)
                titleLabel.textColor = .labelColor
                titleLabel.lineBreakMode = .byTruncatingTail
                cellView.textField = titleLabel
                cellView.addSubview(titleLabel)

                let subtitleLabel = NSTextField(frame: NSRect(x: 44, y: 2, width: 260, height: 14))
                subtitleLabel.isBezeled = false
                subtitleLabel.drawsBackground = false
                subtitleLabel.isEditable = false
                subtitleLabel.font = .systemFont(ofSize: 11)
                subtitleLabel.textColor = .secondaryLabelColor
                subtitleLabel.lineBreakMode = .byTruncatingMiddle
                subtitleLabel.tag = 101
                cellView.addSubview(subtitleLabel)

                cell = cellView
            }

            let isSelected = (tableView.selectedRow == row)
            cell?.imageView?.image = item.icon
            cell?.textField?.stringValue = item.appName
            cell?.textField?.textColor = isSelected ? .white : .labelColor
            if let sub = cell?.viewWithTag(101) as? NSTextField {
                sub.stringValue = item.bundleId
                sub.textColor = isSelected ? NSColor.white.withAlphaComponent(0.85) : .secondaryLabelColor
            }
            return cell

        } else if colId == "ModeColumn" {
            let identifier = NSUserInterfaceItemIdentifier("ModeCellView")
            var cell = tableView.makeView(withIdentifier: identifier, owner: self)
            if cell == nil {
                let cellView = NSView()
                cellView.identifier = identifier

                let segment = NSSegmentedControl(labels: ["Tiếng Việt", "English"], trackingMode: .selectOne, target: self, action: #selector(onModeSegmentChanged(_:)))
                segment.frame = NSRect(x: 10, y: 6, width: 170, height: 24)
                segment.tag = 201
                cellView.addSubview(segment)
                cell = cellView
            }

            if let segment = cell?.subviews.first as? NSSegmentedControl {
                segment.tag = row
                segment.selectedSegment = item.isVietnamese ? 0 : 1
            }
            return cell
        }

        return nil
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        removeButton?.isEnabled = tableView.selectedRow >= 0
        tableView.enumerateAvailableRowViews { rowView, row in
            rowView.needsDisplay = true
            if let cell = rowView.view(atColumn: 0) as? NSTableCellView {
                let isSelected = (row == self.tableView.selectedRow)
                cell.textField?.textColor = isSelected ? .white : .labelColor
                if let sub = cell.viewWithTag(101) as? NSTextField {
                    sub.textColor = isSelected ? NSColor.white.withAlphaComponent(0.85) : .secondaryLabelColor
                }
            }
        }
    }

    func tableView(_ tableView: NSTableView, didAdd rowView: NSTableRowView, forRow row: Int) {
        rowView.isEmphasized = true
    }

    // MARK: - NSSearchFieldDelegate
    func controlTextDidChange(_ obj: Notification) {
        let query = searchField?.stringValue ?? ""
        presenter?.didSearch(query: query)
    }
    
    func searchFieldDidEndSearching(_ sender: NSSearchField) {
        presenter?.didSearch(query: "")
    }
}

/// Custom row view rendering a padded, rounded-corner selection highlight.
final class AppInputModeRowView: NSTableRowView {
    static let cornerRadius: CGFloat = 6.0
    static let horizontalInset: CGFloat = 4.0
    static let verticalInset: CGFloat = 1.5

    override var isEmphasized: Bool {
        get { true }
        set {}
    }

    override func drawSelection(in dirtyRect: NSRect) {
        guard isSelected else { return }
        let selectionRect = bounds.insetBy(dx: Self.horizontalInset, dy: Self.verticalInset)
        let path = NSBezierPath(roundedRect: selectionRect, xRadius: Self.cornerRadius, yRadius: Self.cornerRadius)
        let selectionColor = NSColor.systemBlue
        selectionColor.setFill()
        path.fill()
    }
}

// MARK: - Module Builder
enum AppInputModeBuilder {
    static func build() -> AppInputModeViewController {
        let view = AppInputModeViewController(nibName: "AppInputModeViewController", bundle: nil)
        return setup(view: view)
    }

    @discardableResult
    static func setup(view: AppInputModeViewController) -> AppInputModeViewController {
        let presenter = AppInputModePresenter()
        let interactor = AppInputModeInteractor()
        let router = AppInputModeRouter()

        view.presenter = presenter
        presenter.view = view
        presenter.interactor = interactor
        presenter.router = router
        interactor.presenter = presenter

        return view
    }
}
