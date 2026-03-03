# Flutter Scratch Card Demo

An interactive scratch card experience built with Flutter for the web. Scratch to reveal hidden content with satisfying haptic feedback and sound effects.

## Features

- **Scratch-to-reveal mechanic** — Custom painter with `BlendMode.clear` erases a silver overlay to expose content underneath
- **3D perspective tilt** — Card tilts toward your finger/cursor position while scratching, with smooth spring-back animation on release
- **Carousel of cards** — Swipeable `PageView` with multiple colored cards, story-style segment indicators, and arrow navigation
- **Web haptics** — Tactile feedback via [web_haptics](https://pub.dev/packages/web_haptics) (Taptic Engine on iOS Safari, `navigator.vibrate()` on Android Chrome)
- **Scratch sound effect** — Looping audio plays while scratching using the Web Audio API
- **Auto-reveal** — Once 40%+ of the card is scratched, the overlay is removed on pointer release
- **Reset** — Per-card "Scratch Again" button and a global "Reset All" option

## Getting Started

```bash
flutter pub get
flutter run -d chrome
```

## Tech Stack

- **Flutter** (web-only)
- **web_haptics** — Cross-browser haptic feedback
- **dart:js_interop** — Lightweight HTML audio playback without extra dependencies
- **CustomPainter** — `saveLayer` + `BlendMode.clear` for the scratch effect
- **Matrix4** — Perspective transform for the 3D card tilt

## License

MIT License — see [LICENSE](LICENSE) for details.
