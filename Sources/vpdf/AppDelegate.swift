import AppKit
import UniformTypeIdentifiers

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var controllers: [ViewerWindowController] = []
    private var activeOpenPanels = 0

    func applicationWillFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.mainMenu = MainMenuBuilder.build()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.activate(ignoringOtherApps: true)
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        for url in urls {
            openViewer(for: url)
        }
    }

    // 파일 없이 실행된 경우에만 시스템이 호출해준다 (open urls와의 순서 경합 없음)
    func applicationOpenUntitledFile(_ sender: NSApplication) -> Bool {
        openDocument(nil)
        return true
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            openDocument(nil)
        }
        return true
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // 열기 패널이 닫힐 때 뷰어 창이 열리기 전에 앱이 종료되면 안 된다
        activeOpenPanels == 0
    }

    @objc func openDocument(_ sender: Any?) {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.pdf]
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        activeOpenPanels += 1
        panel.begin { [weak self] response in
            guard let self else { return }
            if response == .OK {
                for url in panel.urls {
                    self.openViewer(for: url)
                }
            }
            self.activeOpenPanels -= 1
        }
    }

    func openViewer(for url: URL) {
        // 이미 열려 있는 문서면 해당 창을 앞으로
        if let existing = controllers.first(where: { $0.documentURL == url }) {
            existing.window?.makeKeyAndOrderFront(nil)
            return
        }
        let controller = ViewerWindowController(url: url)
        controller.onClose = { [weak self] closed in
            self?.controllers.removeAll { $0 === closed }
        }
        controllers.append(controller)
        controller.showWindow(nil)
        NSDocumentController.shared.noteNewRecentDocumentURL(url)
    }
}
