# # ClipboardHistory — ClipboardHistory

<p align="center">
  <img src="assets/icon.svg" width="128" height="128" alt="ClipboardHistory">
</p>

<p align="center">
  <strong>ClipboardHistory</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.0+-02569B?style=flat&logo=flutter" alt="Flutter">
  <img src="https://img.shields.io/badge/Android-6.0+-3DDC84?style=flat&logo=android" alt="Android">
  <img src="https://img.shields.io/badge/macOS-10.14+-007AFF?style=flat&logo=apple" alt="macOS">
  <img src="https://img.shields.io/badge/iOS-13.0+-007AFF?style=flat&logo=apple" alt="iOS">
  <img src="https://img.shields.io/badge/License-MIT-green?style=flat" alt="License">
</p>

---

## 📖 简介

ClipboardHistory 是一款跨平台ClipboardHistory工具，基于 Flutter 框架开发，支持 Android、macOS、iOS 三平台。

## 🏗️ 技术栈

- Flutter 3.0+ / Dart 3.0+
- Material Design 3
- 本地数据持久化

## 📁 项目结构

```
ClipboardHistory/
├── lib/main.dart          # 主程序
├── assets/icon.svg        # 应用图标
├── android/ ios/ macos/   # 平台工程
├── pubspec.yaml           # 依赖配置
└── README.md
```

## 🚀 构建运行

```bash
flutter pub get
flutter run -d android / macos / ios
flutter build apk --release
flutter build macos --release
flutter build ios --release
```

## 📝 更新日志

### v1.0.0
- 首次发布
- ClipboardHistory核心功能
- 三平台支持
- Material Design 3 + 深色模式

## 📄 许可证

MIT License
