# weeder

A new Flutter project.

## Android 海外网页安装（压缩包体）

- **单 APK**：`flutter build apk --release`  
  已开启 R8 压缩、资源裁剪，且仅包含 ARM（arm64-v8a + armeabi-v7a），不包含 x86，体积更小。

- **按 ABI 分包（推荐）**：每个架构一个 APK，体积更小，网页按设备推荐下载：
  ```bash
  ./scripts/build_apk_release.sh
  ```
  或手动执行：
  ```bash
  flutter build apk --release --split-per-abi --obfuscate --split-debug-info=build/app/outputs/symbols
  ```
  输出在 `build/app/outputs/flutter-apk/`：`app-arm64-v8a-release.apk`（推荐）、`app-armeabi-v7a-release.apk`。

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
