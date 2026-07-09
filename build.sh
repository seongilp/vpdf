#!/bin/bash
# vpdf 릴리스 빌드 후 .app 번들을 조립한다.
set -euo pipefail
cd "$(dirname "$0")"

APP_NAME="vpdf"
APP_BUNDLE="${APP_NAME}.app"

echo "==> swift build (release)"
swift build -c release

echo "==> ${APP_BUNDLE} 조립"
rm -rf "${APP_BUNDLE}"
mkdir -p "${APP_BUNDLE}/Contents/MacOS" "${APP_BUNDLE}/Contents/Resources"
cp ".build/release/${APP_NAME}" "${APP_BUNDLE}/Contents/MacOS/${APP_NAME}"
cp "Resources/Info.plist" "${APP_BUNDLE}/Contents/Info.plist"
cp "Resources/AppIcon.icns" "${APP_BUNDLE}/Contents/Resources/AppIcon.icns"

echo "==> ad-hoc 코드 서명"
codesign --force --sign - "${APP_BUNDLE}"

echo "완료: $(pwd)/${APP_BUNDLE}"
