import AppKit

extension NSToolbarItem.Identifier {
    static let vpdfPageIndicator = NSToolbarItem.Identifier("vpdf.pageIndicator")
    static let vpdfSearch = NSToolbarItem.Identifier("vpdf.search")
}

extension ViewerWindowController: NSToolbarDelegate {
    func setupToolbar() {
        let toolbar = NSToolbar(identifier: "vpdf.toolbar")
        toolbar.delegate = self
        toolbar.displayMode = .iconOnly
        toolbar.allowsUserCustomization = false

        pageLabel.font = .monospacedDigitSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)
        pageLabel.textColor = .secondaryLabelColor
        pageLabel.alignment = .center

        let clickRecognizer = NSClickGestureRecognizer(target: self, action: #selector(goToPage(_:)))
        pageLabel.addGestureRecognizer(clickRecognizer)

        let searchField = searchToolbarItem.searchField
        searchField.placeholderString = "검색"
        searchField.target = self
        searchField.action = #selector(searchFieldChanged(_:))
        searchField.sendsSearchStringImmediately = false
        searchField.sendsWholeSearchString = false

        window?.toolbar = toolbar
    }

    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        [.toggleSidebar, .flexibleSpace, .vpdfPageIndicator, .flexibleSpace, .vpdfSearch]
    }

    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        toolbarDefaultItemIdentifiers(toolbar)
    }

    func toolbar(_ toolbar: NSToolbar,
                 itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier,
                 willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        switch itemIdentifier {
        case .vpdfPageIndicator:
            let item = NSToolbarItem(itemIdentifier: itemIdentifier)
            item.view = pageLabel
            item.label = "페이지"
            return item
        case .vpdfSearch:
            return searchToolbarItem
        default:
            return nil
        }
    }
}
