# vpdf

빠른 macOS 네이티브 PDF 뷰어. AppKit + PDFKit 기반 (SwiftUI 미사용).

## 설치

### Homebrew

```bash
brew install --cask seongilp/tap/vpdf
```

업데이트:

```bash
brew upgrade --cask vpdf
```

### 직접 다운로드

[Releases](https://github.com/seongilp/vpdf/releases)에서 최신 DMG를 받아 `vpdf.app`을 응용 프로그램 폴더로 옮기면 됩니다.

## 빌드

```bash
./build.sh        # 릴리스 빌드 후 vpdf.app 생성
open -a ./vpdf.app 파일.pdf
```

## 기능

- **항상 폭 맞춤(fit width)**: 창 크기가 바뀌어도 페이지 폭이 화면에 맞게 유지됨
- **화살표 페이지 넘김**: ←/→ 키로 페이지 이동 (단일 페이지 모드 기본)
- 썸네일 사이드바 (⌃⌘S 토글)
- 비동기 검색: 툴바 검색 필드, ⌘F 포커스, ⌘G / ⇧⌘G 다음·이전 매치, 매치 하이라이트
- 페이지 인디케이터 클릭 또는 ⌥⌘G 로 페이지 점프
- 확대/축소 (⌘+ / ⌘- / ⌘0 실제 크기 / ⌘9 폭 맞추기 / ⌘8 페이지 맞추기)
- 보기 모드: 한 페이지 / 연속 스크롤 / 두 페이지 / 두 페이지 연속
- 최근 문서 열기, 여러 창 동시 열기, Finder "다음으로 열기" 지원

## 속도를 위한 설계

- PDFKit(Preview.app과 동일한 시스템 렌더러) — 하드웨어 최적화된 타일 렌더링
- 문서 로드는 백그라운드 스레드에서 수행 (대용량 PDF도 UI 블로킹 없음)
- 검색은 `beginFindString` 비동기 API 사용, 하이라이트는 64개 단위 배치 갱신
- 페이지 그림자 비활성화 등 불필요한 렌더링 비용 제거

## 구조

```
Sources/vpdf/
├── main.swift                  # 엔트리포인트
├── AppDelegate.swift           # 앱 라이프사이클, 파일 열기
├── MainMenu.swift              # 메뉴바 구성
├── ViewerWindowController.swift # 뷰어 창, 폭 맞춤, 탐색/줌
├── ViewerToolbar.swift         # 툴바 (사이드바 토글, 페이지, 검색)
└── ViewerSearch.swift          # 비동기 검색
```
