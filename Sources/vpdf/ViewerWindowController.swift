import AppKit
import PDFKit

final class ViewerWindowController: NSWindowController, NSWindowDelegate {
    let documentURL: URL
    let pdfView = PDFView()
    let thumbnailView = PDFThumbnailView()
    let pageLabel = NSTextField(labelWithString: "– / –")
    let searchToolbarItem = NSSearchToolbarItem(itemIdentifier: .vpdfSearch)

    // 검색 상태 (ViewerSearch.swift에서 사용)
    var searchResults: [PDFSelection] = []
    var currentMatchIndex = -1

    private var splitViewController: NSSplitViewController?
    private var observers: [NSObjectProtocol] = []
    private var keyMonitor: Any?
    private var autoFitEnabled = true
    var onClose: ((ViewerWindowController) -> Void)?

    init(url: URL) {
        self.documentURL = url
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1100, height: 820),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = url.lastPathComponent
        window.representedURL = url
        window.toolbarStyle = .unified
        super.init(window: window)
        window.delegate = self

        setupPDFView()
        setupSplitView()
        setupToolbar()
        observePageChanges()
        installArrowKeyMonitor()

        window.center()
        window.setFrameAutosaveName("vpdf.viewer")
        loadDocument()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("not supported")
    }

    deinit {
        observers.forEach { NotificationCenter.default.removeObserver($0) }
    }

    // MARK: - Setup

    private func setupPDFView() {
        // 폭 맞춤 스케일을 직접 관리하므로 autoScales는 끈다
        pdfView.autoScales = false
        pdfView.displayMode = .singlePage
        pdfView.displaysPageBreaks = false
        pdfView.pageShadowsEnabled = false
        pdfView.interpolationQuality = .high
        pdfView.maxScaleFactor = 8.0
        pdfView.minScaleFactor = 0.1
        pdfView.backgroundColor = .windowBackgroundColor

        thumbnailView.pdfView = pdfView
        thumbnailView.thumbnailSize = CGSize(width: 110, height: 150)
        thumbnailView.backgroundColor = .clear
    }

    private func setupSplitView() {
        let sidebarController = NSViewController()
        sidebarController.view = thumbnailView

        let contentController = NSViewController()
        contentController.view = pdfView

        let sidebarItem = NSSplitViewItem(sidebarWithViewController: sidebarController)
        sidebarItem.minimumThickness = 140
        sidebarItem.maximumThickness = 240
        sidebarItem.canCollapse = true
        sidebarItem.isCollapsed = true

        let contentItem = NSSplitViewItem(viewController: contentController)

        let split = NSSplitViewController()
        split.addSplitViewItem(sidebarItem)
        split.addSplitViewItem(contentItem)
        splitViewController = split
        window?.contentViewController = split
    }

    private func observePageChanges() {
        observers.append(NotificationCenter.default.addObserver(
            forName: .PDFViewPageChanged,
            object: pdfView,
            queue: .main
        ) { [weak self] _ in
            self?.updatePageLabel()
            self?.applyAutoFitIfNeeded()
        })

        // 창 크기가 바뀌어도 항상 맞춤 스케일을 유지한다
        pdfView.postsFrameChangedNotifications = true
        observers.append(NotificationCenter.default.addObserver(
            forName: NSView.frameDidChangeNotification,
            object: pdfView,
            queue: .main
        ) { [weak self] _ in
            self?.applyAutoFitIfNeeded()
        })
    }

    // MARK: - Arrow Key Navigation

    // 포커스가 어디에 있든 (검색 필드 입력 중 제외) ←/→ 로 페이지를 넘긴다
    private func installArrowKeyMonitor() {
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self,
                  event.window === self.window,
                  event.modifierFlags.intersection([.command, .option, .control]).isEmpty else {
                return event
            }
            // 검색 필드 등 텍스트 편집 중이면 그대로 통과
            if self.window?.firstResponder is NSText {
                return event
            }
            switch event.keyCode {
            case 123: // ←
                self.previousPage(nil)
                return nil
            case 124: // →
                self.nextPage(nil)
                return nil
            default:
                return event
            }
        }
    }

    // MARK: - Auto Fit

    // 가로형(슬라이드)은 폭에, 세로형(A4 등)은 높이에 맞춘다
    private func applyAutoFitIfNeeded() {
        guard autoFitEnabled, let page = pdfView.currentPage else { return }
        let bounds = page.bounds(for: pdfView.displayBox)
        var pageSize = bounds.size
        if page.rotation % 180 != 0 {
            pageSize = CGSize(width: pageSize.height, height: pageSize.width)
        }
        let viewSize = pdfView.bounds.size
        guard pageSize.width > 0, pageSize.height > 0,
              viewSize.width > 0, viewSize.height > 0 else { return }

        let isLandscape = pageSize.width > pageSize.height
        let scale = isLandscape
            ? viewSize.width / pageSize.width
            : viewSize.height / pageSize.height
        pdfView.minScaleFactor = min(0.1, scale)
        if abs(pdfView.scaleFactor - scale) > 0.001 {
            pdfView.scaleFactor = scale
        }
    }

    // MARK: - Document Loading

    private func loadDocument() {
        let url = documentURL
        // 대용량 PDF도 UI를 막지 않도록 백그라운드에서 로드
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let document = PDFDocument(url: url)
            DispatchQueue.main.async {
                guard let self else { return }
                guard let document else {
                    self.presentLoadError()
                    return
                }
                document.delegate = self
                self.pdfView.document = document
                self.updatePageLabel()
                self.applyAutoFitIfNeeded()
                // 화살표 키로 바로 페이지를 넘길 수 있도록 포커스를 준다
                self.window?.makeFirstResponder(self.pdfView)
            }
        }
    }

    private func presentLoadError() {
        guard let window else { return }
        let alert = NSAlert()
        alert.alertStyle = .critical
        alert.messageText = "PDF를 열 수 없습니다"
        alert.informativeText = documentURL.path
        alert.beginSheetModal(for: window) { _ in
            window.close()
        }
    }

    // MARK: - Page Label

    func updatePageLabel() {
        guard let document = pdfView.document,
              let currentPage = pdfView.currentPage else {
            pageLabel.stringValue = "– / –"
            return
        }
        let index = document.index(for: currentPage) + 1
        pageLabel.stringValue = "\(index) / \(document.pageCount)"
    }

    // MARK: - Actions: Zoom

    @objc func zoomIn(_ sender: Any?) {
        autoFitEnabled = false
        pdfView.zoomIn(sender)
    }

    @objc func zoomOut(_ sender: Any?) {
        autoFitEnabled = false
        pdfView.zoomOut(sender)
    }

    @objc func actualSize(_ sender: Any?) {
        autoFitEnabled = false
        pdfView.scaleFactor = 1.0
    }

    @objc func zoomToFit(_ sender: Any?) {
        autoFitEnabled = false
        pdfView.autoScales = true
    }

    @objc func autoFit(_ sender: Any?) {
        autoFitEnabled = true
        pdfView.autoScales = false
        applyAutoFitIfNeeded()
    }

    // MARK: - Actions: Navigation

    @objc func nextPage(_ sender: Any?) {
        if pdfView.canGoToNextPage { pdfView.goToNextPage(sender) }
    }

    @objc func previousPage(_ sender: Any?) {
        if pdfView.canGoToPreviousPage { pdfView.goToPreviousPage(sender) }
    }

    @objc func firstPage(_ sender: Any?) {
        if pdfView.canGoToFirstPage { pdfView.goToFirstPage(sender) }
    }

    @objc func lastPage(_ sender: Any?) {
        if pdfView.canGoToLastPage { pdfView.goToLastPage(sender) }
    }

    @objc func goToPage(_ sender: Any?) {
        guard let window, let document = pdfView.document else { return }
        let alert = NSAlert()
        alert.messageText = "페이지 이동"
        alert.informativeText = "1 – \(document.pageCount) 사이의 번호를 입력하세요."
        let input = NSTextField(frame: NSRect(x: 0, y: 0, width: 140, height: 24))
        alert.accessoryView = input
        alert.addButton(withTitle: "이동")
        alert.addButton(withTitle: "취소")
        alert.window.initialFirstResponder = input
        alert.beginSheetModal(for: window) { [weak self] response in
            guard response == .alertFirstButtonReturn,
                  let self,
                  let number = Int(input.stringValue),
                  number >= 1, number <= document.pageCount,
                  let page = document.page(at: number - 1) else { return }
            self.pdfView.go(to: page)
        }
    }

    // MARK: - Actions: Display Mode

    @objc func changeDisplayMode(_ sender: NSMenuItem) {
        guard let mode = PDFDisplayMode(rawValue: sender.tag) else { return }
        pdfView.displayMode = mode
        applyAutoFitIfNeeded()
    }

    // MARK: - NSWindowDelegate

    func windowWillClose(_ notification: Notification) {
        pdfView.document?.cancelFindString()
        if let keyMonitor {
            NSEvent.removeMonitor(keyMonitor)
            self.keyMonitor = nil
        }
        onClose?(self)
    }
}

// MARK: - Menu Validation

extension ViewerWindowController: NSMenuItemValidation {
    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        switch menuItem.action {
        case #selector(changeDisplayMode(_:)):
            menuItem.state = (pdfView.displayMode.rawValue == menuItem.tag) ? .on : .off
            return pdfView.document != nil
        case #selector(autoFit(_:)):
            menuItem.state = autoFitEnabled ? .on : .off
            return pdfView.document != nil
        case #selector(nextPage(_:)):
            return pdfView.canGoToNextPage
        case #selector(previousPage(_:)):
            return pdfView.canGoToPreviousPage
        case #selector(firstPage(_:)):
            return pdfView.canGoToFirstPage
        case #selector(lastPage(_:)):
            return pdfView.canGoToLastPage
        case #selector(findNext(_:)), #selector(findPrevious(_:)):
            return !searchResults.isEmpty
        default:
            return pdfView.document != nil
        }
    }
}
