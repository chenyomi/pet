# macOS 后台悬浮窗实现指南

## 概述

本指南说明如何在 macOS 上实现后台悬浮窗功能。当游戏退出时，宠物会在独立的 always-on-top 窗口中显示。

---

## 架构设计

### 通信流程
```
Flutter App (Dart)
    ↓↑ (Method Channel)
macOS Runner (Swift)
    ↓↑
FloatingWindow (Cocoa)
```

### 关键组件
1. **Dart 层**: `FloatingWindowManager` - 调用原生方法
2. **Swift 层**: Method Channel Handler - 创建/管理窗口
3. **窗口进程**: 独立的 NSWindow + NSView

---

## 实现步骤

### 1️⃣ 创建 Method Channel Handler

编辑 `macos/Runner/MainFlutterWindow.swift`，添加以下代码：

```swift
import Cocoa
import FlutterMacOS


class FloatingWindowManager {
    static let shared = FloatingWindowManager()
    var floatingWindow: NSWindow?
    var floatingViewController: FloatingPetViewController?
    
    func showFloatingWindow(petName: String, eventText: String) -> Bool {
        // 如果已存在，先关闭
        hideFloatingWindow()
        
        // 创建窗口
        let screenFrame = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1024, height: 768)
        let windowSize = NSSize(width: 160, height: 120)
        let windowRect = NSRect(
            x: screenFrame.maxX - windowSize.width - 20,
            y: screenFrame.minY + 20,
            width: windowSize.width,
            height: windowSize.height
        )
        
        let window = NSWindow(contentRect: windowRect, styleMask: [.borderless], backing: .buffered, defer: false)
        window.isOpaque = false
        window.backgroundColor = NSColor.clear
        window.level = .floating
        window.isMovableByWindowBackground = true
        
        // 设置窗口样式
        window.titlebarAppearsTransparent = true
        window.isReleasedWhenClosed = false
        window.collectionBehavior = [.canJoinAllSpaces, .moveToActiveSpace]
        
        // 创建 View Controller
        let viewController = FloatingPetViewController(petName: petName, eventText: eventText)
        window.contentViewController = viewController
        
        // 显示窗口
        window.makeKeyAndOrderFront(nil)
        
        self.floatingWindow = window
        self.floatingViewController = viewController
        
        return true
    }
    
    func hideFloatingWindow() -> Bool {
        floatingWindow?.close()
        floatingWindow = nil
        floatingViewController = nil
        return true
    }
    
    func updateFloatingWindow(petName: String, eventText: String) -> Bool {
        floatingViewController?.updatePet(petName: petName, eventText: eventText)
        return true
    }
}


class FloatingPetViewController: NSViewController {
    private let petNameLabel = NSTextField()
    private let eventTextLabel = NSTextField()
    private let petImageView = NSImageView()
    
    let petName: String
    let eventText: String
    
    init(petName: String, eventText: String) {
        self.petName = petName
        self.eventText = eventText
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        let containerView = NSView()
        containerView.wantsLayer = true
        containerView.layer?.cornerRadius = 12
        containerView.layer?.backgroundColor = NSColor(red: 1, green: 0.97, blue: 0.9, alpha: 0.95).cgColor
        containerView.layer?.borderColor = NSColor(red: 0.125, green: 0.212, blue: 0.227, alpha: 1).cgColor
        containerView.layer?.borderWidth = 2
        containerView.layer?.shadowColor = NSColor.black.cgColor
        containerView.layer?.shadowOpacity = 0.2
        containerView.layer?.shadowOffset = NSSize(width: 0, height: -2)
        containerView.layer?.shadowRadius = 8
        
        // 宠物图像占位符
        petImageView.wantsLayer = true
        petImageView.image = NSImage(systemSymbolName: "star.fill", accessibilityDescription: nil)
        petImageView.frame = NSRect(x: 8, y: 60, width: 40, height: 40)
        
        // 宠物名字
        petNameLabel.stringValue = petName
        petNameLabel.isEditable = false
        petNameLabel.isBezeled = false
        petNameLabel.backgroundColor = NSColor.clear
        petNameLabel.font = NSFont.systemFont(ofSize: 11, weight: .bold)
        petNameLabel.frame = NSRect(x: 52, y: 65, width: 100, height: 16)
        
        // 状态文本
        eventTextLabel.stringValue = eventText
        eventTextLabel.isEditable = false
        eventTextLabel.isBezeled = false
        eventTextLabel.backgroundColor = NSColor.clear
        eventTextLabel.font = NSFont.systemFont(ofSize: 10)
        eventTextLabel.frame = NSRect(x: 52, y: 50, width: 100, height: 12)
        
        containerView.addSubview(petImageView)
        containerView.addSubview(petNameLabel)
        containerView.addSubview(eventTextLabel)
        
        self.view = containerView
    }
    
    func updatePet(petName: String, eventText: String) {
        petNameLabel.stringValue = petName
        eventTextLabel.stringValue = eventText
    }
}
```

---

### 2️⃣ 设置 Method Channel

在 `macos/Runner/MainFlutterWindow.swift` 的初始化中添加：

```swift
// 在 MainFlutterWindow 类的初始化或 didFinishLaunching 中

class MainFlutterWindow: NSWindow {
    // ... 既有代码 ...
    
    func setupMethodChannels() {
        guard let controller = rootViewController as? FlutterViewController else { return }
        
        let methodChannel = FlutterMethodChannel(
            name: "com.digipet/floating_window",
            binaryMessenger: controller.binaryMessenger
        )
        
        methodChannel.setMethodCallHandler { [weak self] (call, result) in
            switch call.method {
            case "showFloatingWindow":
                let args = call.arguments as? [String: Any]
                let petName = args?["petName"] as? String ?? "宠物"
                let eventText = args?["eventText"] as? String ?? "平静"
                let success = FloatingWindowManager.shared.showFloatingWindow(
                    petName: petName,
                    eventText: eventText
                )
                result(success)
                
            case "hideFloatingWindow":
                let success = FloatingWindowManager.shared.hideFloatingWindow()
                result(success)
                
            case "updateFloatingWindow":
                let args = call.arguments as? [String: Any]
                let petName = args?["petName"] as? String ?? "宠物"
                let eventText = args?["eventText"] as? String ?? "平静"
                let success = FloatingWindowManager.shared.updateFloatingWindow(
                    petName: petName,
                    eventText: eventText
                )
                result(success)
                
            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }
}
```

---

### 3️⃣ 在主窗口初始化时调用

```swift
// 在 GeneratedPluginRegistrant.swift 或相应的启动代码中

override func windowDidLoad() {
    super.windowDidLoad()
    
    // ... 其他初始化代码 ...
    
    setupMethodChannels()
}
```

---

## 增强功能

### 特性 1: 点击悬浮窗启动游戏

```swift
override func mouseDown(with event: NSEvent) {
    // 重新启动主应用窗口
    let mainWindow = NSApplication.shared.windows.first
    mainWindow?.makeKeyAndOrderFront(nil)
}
```

### 特性 2: 右键菜单关闭

```swift
// 在 FloatingPetViewController 中

override func viewDidLoad() {
    super.viewDidLoad()
    
    let menu = NSMenu()
    menu.addItem(NSMenuItem(title: "关闭", action: #selector(closeWindow), keyEquivalent: ""))
    
    view.menu = menu
}

@objc func closeWindow() {
    FloatingWindowManager.shared.hideFloatingWindow()
}
```

### 特性 3: 自动定位

```swift
// 屏幕右下角
let screenFrame = NSScreen.main?.visibleFrame ?? NSRect(...)
let position = CGPoint(
    x: screenFrame.maxX - windowWidth - 20,
    y: screenFrame.minY + 20
)
```

---

## 调试与测试

### 测试步骤

1. 启动 Flutter 应用
2. 在应用主界面保持一段时间让宠物有状态
3. 按 Cmd+Q 或 Cmd+W 关闭窗口
4. 检查右下角是否出现浮窗

### 常见问题

| 问题 | 解决方案 |
|------|-------|
| 浮窗不显示 | 检查 Method Channel 名称是否匹配 |
| 浮窗在后台 | 检查 `window.level = .floating` 设置 |
| 关闭后无法重新打开 | 检查 `isReleasedWhenClosed = false` |
| 宠物图像不显示 | 需要从 Flutter 传递图像数据或使用系统图标 |

---

## 高级实现：传输像素艺术

虽然当前简化实现使用系统图标，但完整版本应该传输真实宠物像素艺术。

### 方案 A：Base64 编码

```dart
// Flutter 端
import 'dart:convert';
import 'dart:ui' as ui;

Future<void> _sendPetImage() async {
  // 绘制宠物像素艺术
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  // ... 绘制代码 ...
  
  final image = await recorder.endRecording().toImage(60, 60);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  final base64Image = base64Encode(bytes!.buffer.asUint8List());
  
  await FloatingWindowManager.updateFloatingWindow(
    petName: species.name,
    eventText: state.eventText,
    imageBase64: base64Image,
  );
}
```

```swift
// Swift 端
if let imageBase64 = args?["imageBase64"] as? String,
   let imageData = Data(base64Encoded: imageBase64) {
    let image = NSImage(data: imageData)
    petImageView.image = image
}
```

### 方案 B：临时文件共享

```dart
// Flutter 端
import 'package:path_provider/path_provider.dart';

Future<void> _savePetIcon() async {
  final tempDir = await getTemporaryDirectory();
  final file = File('${tempDir.path}/pet_icon.png');
  
  // 绘制并保存宠物
  // ...
  
  await FloatingWindowManager.showFloatingWindow(
    petName: species.name,
    eventText: state.eventText,
    imagePath: file.path,
  );
}
```

---

## 最终检查清单

- [ ] Method Channel 名称 `com.digipet/floating_window` 在 Dart 和 Swift 中一致
- [ ] 窗口设置为 `level = .floating` 和 `isMovableByWindowBackground = true`
- [ ] 添加应用生命周期监听 (`AppLifecycleManager`)
- [ ] 测试应用退出时悬浮窗自动显示
- [ ] 测试点击悬浮窗后应用恢复
- [ ] 右键菜单可关闭浮窗
- [ ] 宠物信息动态更新正常

---

## 下一步

实现后，可进一步探索：
1. 多个宠物并行显示（多窗口）
2. 音效提醒（宠物饥饿时发出声音）
3. 拖拽排列悬浮窗
4. 窗口透明度调整
5. 深色模式适配

---

References:
- [Apple NSWindow Documentation](https://developer.apple.com/documentation/appkit/nswindow)
- [Flutter Method Channels](https://flutter.dev/docs/development/platform-integration/platform-channels)
- [macOS App Development](https://developer.apple.com/macos/)
