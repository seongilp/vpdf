import AppKit
import PDFKit

enum MainMenuBuilder {
    static func build() -> NSMenu {
        let main = NSMenu()
        main.addItem(submenu(appMenu(), title: "vpdf"))
        main.addItem(submenu(fileMenu(), title: "파일"))
        main.addItem(submenu(editMenu(), title: "편집"))
        main.addItem(submenu(viewMenu(), title: "보기"))
        main.addItem(submenu(goMenu(), title: "이동"))
        main.addItem(submenu(windowMenu(), title: "윈도우"))
        return main
    }

    private static func submenu(_ menu: NSMenu, title: String) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        item.submenu = menu
        return item
    }

    private static func appMenu() -> NSMenu {
        let menu = NSMenu(title: "vpdf")
        menu.addItem(withTitle: "vpdf에 관하여",
                     action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)),
                     keyEquivalent: "")
        menu.addItem(.separator())
        menu.addItem(withTitle: "vpdf 가리기",
                     action: #selector(NSApplication.hide(_:)),
                     keyEquivalent: "h")
        let hideOthers = menu.addItem(withTitle: "기타 가리기",
                                      action: #selector(NSApplication.hideOtherApplications(_:)),
                                      keyEquivalent: "h")
        hideOthers.keyEquivalentModifierMask = [.command, .option]
        menu.addItem(withTitle: "모두 보기",
                     action: #selector(NSApplication.unhideAllApplications(_:)),
                     keyEquivalent: "")
        menu.addItem(.separator())
        menu.addItem(withTitle: "vpdf 종료",
                     action: #selector(NSApplication.terminate(_:)),
                     keyEquivalent: "q")
        return menu
    }

    private static func fileMenu() -> NSMenu {
        let menu = NSMenu(title: "파일")
        menu.addItem(withTitle: "열기…",
                     action: #selector(AppDelegate.openDocument(_:)),
                     keyEquivalent: "o")

        let recentItem = NSMenuItem(title: "최근 문서 열기", action: nil, keyEquivalent: "")
        let recentMenu = NSMenu(title: "최근 문서 열기")
        // AppKit 내부 이름을 지정하면 시스템이 최근 문서 목록을 자동 관리한다
        recentMenu.perform(NSSelectorFromString("_setMenuName:"), with: "NSRecentDocumentsMenu")
        recentItem.submenu = recentMenu
        menu.addItem(recentItem)

        menu.addItem(.separator())
        menu.addItem(withTitle: "닫기",
                     action: #selector(NSWindow.performClose(_:)),
                     keyEquivalent: "w")
        return menu
    }

    private static func editMenu() -> NSMenu {
        let menu = NSMenu(title: "편집")
        menu.addItem(withTitle: "복사",
                     action: #selector(NSText.copy(_:)),
                     keyEquivalent: "c")
        menu.addItem(withTitle: "모두 선택",
                     action: #selector(NSText.selectAll(_:)),
                     keyEquivalent: "a")
        menu.addItem(.separator())
        menu.addItem(withTitle: "찾기…",
                     action: #selector(ViewerWindowController.focusSearchField(_:)),
                     keyEquivalent: "f")
        menu.addItem(withTitle: "다음 찾기",
                     action: #selector(ViewerWindowController.findNext(_:)),
                     keyEquivalent: "g")
        let prev = menu.addItem(withTitle: "이전 찾기",
                                action: #selector(ViewerWindowController.findPrevious(_:)),
                                keyEquivalent: "g")
        prev.keyEquivalentModifierMask = [.command, .shift]
        return menu
    }

    private static func viewMenu() -> NSMenu {
        let menu = NSMenu(title: "보기")
        let sidebar = menu.addItem(withTitle: "썸네일 사이드바",
                                   action: #selector(NSSplitViewController.toggleSidebar(_:)),
                                   keyEquivalent: "s")
        sidebar.keyEquivalentModifierMask = [.command, .control]
        menu.addItem(.separator())

        menu.addItem(withTitle: "확대",
                     action: #selector(ViewerWindowController.zoomIn(_:)),
                     keyEquivalent: "+")
        menu.addItem(withTitle: "축소",
                     action: #selector(ViewerWindowController.zoomOut(_:)),
                     keyEquivalent: "-")
        menu.addItem(withTitle: "실제 크기",
                     action: #selector(ViewerWindowController.actualSize(_:)),
                     keyEquivalent: "0")
        menu.addItem(withTitle: "자동 맞추기 (슬라이드는 폭, 문서는 높이)",
                     action: #selector(ViewerWindowController.autoFit(_:)),
                     keyEquivalent: "9")
        menu.addItem(withTitle: "페이지 맞추기",
                     action: #selector(ViewerWindowController.zoomToFit(_:)),
                     keyEquivalent: "8")
        menu.addItem(.separator())

        let single = displayModeItem("한 페이지씩", mode: .singlePage)
        let continuous = displayModeItem("연속 스크롤", mode: .singlePageContinuous)
        let twoUp = displayModeItem("두 페이지", mode: .twoUp)
        let twoUpContinuous = displayModeItem("두 페이지 연속", mode: .twoUpContinuous)
        [single, continuous, twoUp, twoUpContinuous].forEach { menu.addItem($0) }
        return menu
    }

    private static func displayModeItem(_ title: String, mode: PDFDisplayMode) -> NSMenuItem {
        let item = NSMenuItem(title: title,
                              action: #selector(ViewerWindowController.changeDisplayMode(_:)),
                              keyEquivalent: "")
        item.tag = mode.rawValue
        return item
    }

    private static func goMenu() -> NSMenu {
        let menu = NSMenu(title: "이동")
        let next = menu.addItem(withTitle: "다음 페이지",
                                action: #selector(ViewerWindowController.nextPage(_:)),
                                keyEquivalent: "]")
        next.keyEquivalentModifierMask = [.command]
        let prev = menu.addItem(withTitle: "이전 페이지",
                                action: #selector(ViewerWindowController.previousPage(_:)),
                                keyEquivalent: "[")
        prev.keyEquivalentModifierMask = [.command]
        menu.addItem(.separator())
        menu.addItem(withTitle: "첫 페이지",
                     action: #selector(ViewerWindowController.firstPage(_:)),
                     keyEquivalent: "")
        menu.addItem(withTitle: "마지막 페이지",
                     action: #selector(ViewerWindowController.lastPage(_:)),
                     keyEquivalent: "")
        menu.addItem(.separator())
        let goto = menu.addItem(withTitle: "페이지 이동…",
                                action: #selector(ViewerWindowController.goToPage(_:)),
                                keyEquivalent: "g")
        goto.keyEquivalentModifierMask = [.command, .option]
        return menu
    }

    private static func windowMenu() -> NSMenu {
        let menu = NSMenu(title: "윈도우")
        menu.addItem(withTitle: "최소화",
                     action: #selector(NSWindow.miniaturize(_:)),
                     keyEquivalent: "m")
        menu.addItem(withTitle: "확대/축소",
                     action: #selector(NSWindow.zoom(_:)),
                     keyEquivalent: "")
        NSApp.windowsMenu = menu
        return menu
    }
}
