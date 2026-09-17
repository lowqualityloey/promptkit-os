---
name: mobile-flutter
category: mobile
version: 1
token_budget: 1500
activation:
  manifests:
    - pubspec.yaml
verification:
  fast:
    - flutter analyze
  required:
    - flutter test
  extended:
    - flutter build bundle
invariants:
  - "Never use BuildContext across asynchronous gaps without checking if (!mounted) return"
  - "Widget build() methods must remain pure functions without side effects or network requests"
  - "Serialize Platform Channel messages strictly with supported StandardMessageCodec types"
  - "Dispose all controllers, stream subscriptions, and animation tickers in State.dispose()"
  - "Enforce const constructors aggressively on immutable widgets to optimize element tree caching"
anti_patterns:
  - "Calling setState() after an unawaited asynchronous operation without a mounted guard"
  - "Instantiating service singletons or triggering HTTP requests directly inside widget build() methods"
  - "Omitting keys on reorderable or dynamically inserted stateful list items causing state corruption"
  - "Passing non-primitive custom Dart objects directly across platform channels without encoding"
---

# Flutter Mobile Playbook

Operational guidelines, invariants, and failure modes for cross-platform mobile development using Flutter and Dart.

## 1. Architectural Invariants

- **Asynchronous BuildContext Guard**: In Flutter, a `BuildContext` belongs to an Element in the widget tree. If you invoke an asynchronous gap (`await api.fetchUser()`), the widget may have been unmounted by the user navigating away. NEVER access `context` (e.g. `Navigator.of(context)`, `Theme.of(context)`) or call `setState()` after an `await` without an explicit guard: `if (!mounted) return;`.
- **Pure Widget Rendering**: The `Widget.build(BuildContext context)` method can be called 60 to 120 times per second during animations or scrolls. Keep `build()` strictly deterministic and side-effect free. Never instantiate long-lived controllers, register global event listeners, or trigger asynchronous tasks inside `build()`.
- **Platform Channel Type Bounds**: Communication between Dart and native host platforms (iOS Swift, Android Kotlin) uses `MethodChannel` with `StandardMessageCodec`. Restrict message payloads to supported primitives: `null`, `bool`, `int`, `double`, `String`, `Uint8List`, `List`, and `Map`. Complex domain entities must be serialized to JSON maps before transit.
- **Resource Cleanup in Dispose**: Every `StatefulWidget` that instantiates an `AnimationController`, `TextEditingController`, `ScrollController`, or `StreamSubscription` must cancel and dispose of them in `dispose()`. Failure to do so leads to silent memory leaks and background CPU battery drain.
- **Aggressive Const Usage**: Mark all stateless widgets and subtrees with `const` wherever properties are known at compile time. This prevents Flutter from rebuilding those elements during tree reconciliation.

## 2. Critical Anti-Patterns & Pitfalls

- **Unprotected setState After Async**: Invoking `setState()` on a disposed widget throws `FlutterError: setState() called after dispose()`, causing application crash reports.
- **Global Key Overuse**: Using `GlobalKey` excessively as a shortcut for state passing bypasses standard Flutter state management (Riverpod, Bloc, Provider) and causes heavy performance penalties during layout passes.
- **Over-Sized Image Memory Footprint**: Loading large raw network images without specifying `cacheWidth` or `cacheHeight` in `Image.network` forces full-resolution bitmap decompression in memory, triggering out-of-memory (OOM) crashes on low-end devices.
- **Platform Channel Main Thread Blocking**: Executing long-running computation on the native side of a platform channel blocks the native platform main thread, causing frame drops and severe jank.

## 3. Tiered Verification Commands

- **Fast (L0/L1 Direct)**:
  `flutter analyze` to run Dart static analysis, linting rules, type checking, and dead code detection.
- **Required (L2 Controlled / Pre-Commit)**:
  `flutter test` to execute the full unit and widget test suite with mocked platform dependencies.
- **Extended (L3 Release / CI)**:
  `flutter build bundle` to assert compilation integrity, asset packaging, and release tree-shaking.
