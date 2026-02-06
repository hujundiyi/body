#!/usr/bin/env bash
# 海外网页安装用：生成体积更小的 release APK
# 用法: ./scripts/build_apk_release.sh
# 输出: build/app/outputs/flutter-apk/ 下多个 APK

set -e
cd "$(dirname "$0")/.."

echo ">>> 清理并构建 release APK（按 ABI 分包 + 混淆）..."
flutter clean
flutter pub get
flutter build apk --release \
  --split-per-abi \
  --obfuscate \
  --split-debug-info=build/app/outputs/symbols

echo ""
echo ">>> 构建完成。APK 位置："
ls -la build/app/outputs/flutter-apk/*.apk 2>/dev/null || true
echo ""
echo "网页分发建议："
echo "  - app-armeabi-v7a-release.apk  适合较老机型（32 位 ARM）"
echo "  - app-arm64-v8a-release.apk    适合绝大多数海外手机（64 位 ARM，推荐）"
echo "  可根据 User-Agent 或让用户选择后下载对应 APK。"
