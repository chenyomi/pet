# 运行与打包

本文档覆盖这个 Flutter 电子宠物项目最常用的运行和打包方式。

项目目录:

```bash
cd /Users/chenyuming/Desktop/cym/电子宠物/flutter_pet
```

## 1. 前置要求

- Flutter 已安装并可执行
- 第一次运行前执行 `flutter pub get`
- macOS 打包需要 Xcode
- Android 打包需要 Android Studio / Android SDK
- iOS 打包需要 macOS + Xcode + Apple 开发者环境

## 2. 常用入口

### 直接用 Makefile

```bash
make setup
make analyze
make test
make run-web-server
make run-macos
make build-web
make build-macos
make build-apk
make build-aab
make build-ios
```

### 直接用脚本

```bash
bash tool/run_web.sh
bash tool/run_macos.sh
bash tool/build_web.sh
bash tool/build_macos.sh
bash tool/build_apk.sh
bash tool/build_aab.sh
bash tool/build_ios.sh
```

## 3. 开发运行

### Web 本地服务

```bash
flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8080
```

打开:

- [http://localhost:8080](http://localhost:8080)

### Web Chrome

```bash
flutter run -d chrome
```

### macOS

```bash
flutter run -d macos
```

### Android

```bash
flutter devices
flutter run -d android
```

### iOS

```bash
flutter devices
flutter run -d ios
```

## 4. 发布打包

### Web Release

```bash
flutter build web
```

输出目录:

- `build/web/`

### macOS Release

```bash
flutter build macos
```

输出目录:

- `build/macos/Build/Products/Release/flutter_pet.app`

### Android APK

```bash
flutter build apk
```

输出目录:

- `build/app/outputs/flutter-apk/app-release.apk`

### Android App Bundle

```bash
flutter build appbundle
```

输出目录:

- `build/app/outputs/bundle/release/app-release.aab`

### iOS

```bash
flutter build ios --no-codesign
```

输出目录:

- `build/ios/iphoneos/Runner.app`

说明:

- 真正上架或安装到真机前，还需要证书、签名和 Xcode 配置

## 5. 常用检查

```bash
flutter analyze
flutter test
flutter clean
flutter pub get
```

## 6. 常见问题

### Flutter 不在 PATH

如果你的终端里 `flutter` 能跑，但脚本里不行，可以手动指定:

```bash
FLUTTER_BIN="$HOME/fvm/cache.git/bin/flutter" bash tool/run_web.sh
```

### Web 端报平台环境错误

当前项目已经做了 Web 存档兼容:

- Web 使用 `localStorage`
- 桌面端使用本地文件

### 后台悬浮窗

现在主界面里展示的是“悬浮窗预览 UI”。  
真正的 macOS 后台悬浮小窗还需要下一步接入桌面窗口控制能力，例如:

- always on top
- 无边框窗口
- 后台常驻
- 点击小窗展开主面板
