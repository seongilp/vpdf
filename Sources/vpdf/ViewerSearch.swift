import AppKit
import PDFKit

// PDFKit의 비동기 검색(beginFindString)을 사용해 대용량 문서에서도
// 메인 스레드를 막지 않는다.
extension ViewerWindowController: PDFDocumentDelegate {

    @objc func focusSearchField(_ sender: Any?) {
        window?.makeFirstResponder(searchToolbarItem.searchField)
    }

    @objc func searchFieldChanged(_ sender: NSSearchField) {
        startSearch(sender.stringValue)
    }

    func startSearch(_ query: String) {
        guard let document = pdfView.document else { return }
        if document.isFinding {
            document.cancelFindString()
        }
        searchResults.removeAll()
        currentMatchIndex = -1
        pdfView.highlightedSelections = nil

        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        document.beginFindString(trimmed, withOptions: [.caseInsensitive])
    }

    // PDFDocumentDelegate: 매치될 때마다 호출됨
    func didMatchString(_ instance: PDFSelection) {
        instance.color = NSColor.systemYellow.withAlphaComponent(0.5)
        searchResults.append(instance)

        // 첫 매치는 즉시 이동해 체감 속도를 높인다
        if searchResults.count == 1 {
            DispatchQueue.main.async { [weak self] in
                self?.jumpToMatch(at: 0)
            }
        }
        // 하이라이트는 과도한 리렌더를 피하기 위해 배치로 갱신
        if searchResults.count % 64 == 0 {
            let snapshot = searchResults
            DispatchQueue.main.async { [weak self] in
                self?.pdfView.highlightedSelections = snapshot
            }
        }
    }

    func documentDidEndDocumentFind(_ notification: Notification) {
        pdfView.highlightedSelections = searchResults.isEmpty ? nil : searchResults
        if searchResults.isEmpty {
            NSSound.beep()
        }
    }

    @objc func findNext(_ sender: Any?) {
        advanceMatch(by: 1)
    }

    @objc func findPrevious(_ sender: Any?) {
        advanceMatch(by: -1)
    }

    private func advanceMatch(by delta: Int) {
        guard !searchResults.isEmpty else {
            NSSound.beep()
            return
        }
        let count = searchResults.count
        let next = ((currentMatchIndex + delta) % count + count) % count
        jumpToMatch(at: next)
    }

    private func jumpToMatch(at index: Int) {
        guard index >= 0, index < searchResults.count else { return }
        currentMatchIndex = index
        let selection = searchResults[index]
        pdfView.setCurrentSelection(selection, animate: true)
        pdfView.go(to: selection)
    }
}
