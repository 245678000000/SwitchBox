#!/bin/zsh
# 编译并打包成 SwitchBox.app
set -e
cd "$(dirname "$0")"
swift build -c release
APP=build/SwitchBox.app
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp .build/release/SwitchBox "$APP/Contents/MacOS/"

# App 图标（首次自动生成）
if [ ! -f Resources/AppIcon.icns ]; then
  mkdir -p Resources build/AppIcon.iconset
  .build/release/SwitchBox --render-icon build/icon_1024.png
  for s in 16 32 128 256 512; do
    sips -z $s $s build/icon_1024.png --out build/AppIcon.iconset/icon_${s}x${s}.png >/dev/null
    sips -z $((s*2)) $((s*2)) build/icon_1024.png --out build/AppIcon.iconset/icon_${s}x${s}@2x.png >/dev/null
  done
  iconutil -c icns build/AppIcon.iconset -o Resources/AppIcon.icns
fi
cp Resources/AppIcon.icns "$APP/Contents/Resources/"
cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleName</key><string>SwitchBox</string>
  <key>CFBundleDisplayName</key><string>SwitchBox</string>
  <key>CFBundleIdentifier</key><string>local.switchbox.app</string>
  <key>CFBundleExecutable</key><string>SwitchBox</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>1.0.0</string>
  <key>CFBundleVersion</key><string>1</string>
  <key>LSMinimumSystemVersion</key><string>14.0</string>
  <key>LSUIElement</key><true/>
  <key>CFBundleIconFile</key><string>AppIcon</string>
  <key>NSBluetoothAlwaysUsageDescription</key><string>SwitchBox 需要蓝牙权限来打开或关闭蓝牙。</string>
  <key>NSAppleEventsUsageDescription</key><string>SwitchBox 需要控制“系统事件”和“访达”来切换外观、程序坞和清空废纸篓。</string>
</dict></plist>
PLIST
codesign --force --deep -s - "$APP"
rm -rf SwitchBox.app && cp -R "$APP" SwitchBox.app
# 如果“应用程序”里装过，顺便更新
if [ -d /Applications/SwitchBox.app ]; then rm -rf /Applications/SwitchBox.app && cp -R "$APP" /Applications/; echo "↻ 已同步更新 /Applications/SwitchBox.app"; fi
echo "✅ 已生成 SwitchBox.app"
