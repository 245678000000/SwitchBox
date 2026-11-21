# SwitchBox

macOS 菜单栏系统开关合集（SwiftUI，macOS 14+）。

## 使用
双击 `SwitchBox.app` 运行（建议拖到“应用程序”文件夹）。点击菜单栏图标打开面板。

## 功能
- 开关：隐藏桌面图标、深色模式、保持亮屏、夜览、麦克风静音、自动隐藏程序坞 / 菜单栏、显示隐藏文件
- 一键操作：屏幕保护、屏幕清洁（长按 esc 3 秒退出）、清空废纸篓、推出磁盘
- 自定义显示哪些开关及顺序
- 全局快捷键 + 状态提示浮窗
- 登录时启动

## 构建
```
./build.sh        # 生成 SwitchBox.app
.build/release/SwitchBox --snapshot /tmp/sbsnap   # 导出界面截图（开发用）
```

## 目录
- `Sources/SwitchBox/Controls.swift`  系统功能实现、权限检测
- `Sources/SwitchBox/Store.swift`     开关定义与状态
- `Sources/SwitchBox/Views.swift`     菜单面板与设置窗口
- `Sources/SwitchBox/Design.swift`    配色、图标、按钮样式
- `Sources/SwitchBox/HotKeys.swift`   全局快捷键、录制控件、提示浮窗
- `Sources/SwitchBox/ScreenCleaner.swift` 屏幕清洁
