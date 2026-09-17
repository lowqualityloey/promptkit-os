---
name: mobile-expo
category: mobile
version: 1
token_budget: 1500
activation:
  manifests:
    - app.json
    - app.config.js
    - app.config.ts
verification:
  fast:
    - npx expo-doctor
  required:
    - npx tsc --noEmit
  extended:
    - npx expo export --dump-sourcemap
invariants:
  - "Distinguish Managed vs Bare workflow — verify Config Plugin compatibility before adding native modules"
  - "Separate platform-specific logic via .ios.tsx and .android.tsx extensions rather than sprawling inline switches"
  - "Account for Hermes JavaScript engine constraints and provide polyfills for missing browser globals"
  - "Model mobile application lifecycle states (active, background, inactive) explicitly in persistent state"
  - "Ensure all interactive touch targets meet minimum accessibility dimensions of 44x44 points"
anti_patterns:
  - "Accessing web-only browser globals like window, document, or localStorage directly in React Native code"
  - "Installing native libraries that require custom Gradle or Podfile edits without running prebuild"
  - "Rendering unbounded lists with ScrollView instead of virtualized FlatList or FlashList components"
  - "Triggering unmemoized re-renders on high-frequency gesture responders or animated style calculations"
---

# Expo & React Native Mobile Playbook

Operational guidelines, invariants, and failure modes for cross-platform mobile development using Expo and React Native.

## 1. Architectural Invariants

- **Workflow Boundary & Config Plugins**: Default to the Expo Managed Workflow (`expo prebuild`). Before installing any third-party library with native code (Objective-C, Swift, Java, Kotlin), verify that it provides an Expo Config Plugin. Never manually modify files in `ios/` or `android/` if using continuous native generation (`CNG`).
- **Platform File Segregation**: When iOS and Android behaviors diverge significantly, split components into distinct files (`Component.ios.tsx` and `Component.android.tsx`) rather than littering rendering logic with nested `Platform.OS === 'ios'` ternary branches.
- **Hermes Engine Constraints**: React Native standardizes on the Hermes JavaScript engine. Hermes is highly optimized for mobile cold starts but does not ship full ECMAScript Intl coverage or browser APIs out of the box. Test date formatting, crypto routines, and URL polyfills explicitly.
- **Mobile Storage Architecture**: Do not use `localStorage`. Use `@react-native-async-storage/async-storage` for general application cache, and `expo-secure-store` for sensitive authentication tokens and cryptographic credentials.
- **Virtualized Lists & Performance**: Always render variable-length collections using `FlatList` or `FlashList` with stable `keyExtractor` functions and memoized item components (`React.memo`).

## 2. Critical Anti-Patterns & Pitfalls

- **Web Global Leakage**: Referencing `window.location`, `document.getElementById`, or CSS class strings causes immediate native crashes (`ReferenceError: window is not defined`).
- **Inline Arrow Functions in Lists**: Passing `renderItem={({ item }) => <Item data={item} />}` directly in list props creates a new function instance on every parent render, forcing full list reconciliation.
- **Synchronous Storage Blocking**: Attempting synchronous disk access during app initialization freezes the native main thread, resulting in OS watchdog termination (crash on launch).
- **Ignoring Safe Area Insets**: Rendering buttons or headers without `<SafeAreaView>` or `react-native-safe-area-context` causes UI elements to be obscured by the dynamic island, camera notch, or home indicator bar.

## 3. Tiered Verification Commands

- **Fast (L0/L1 Direct)**:
  `npx expo-doctor` to validate package dependency compatibility, duplicate dependencies, and Expo SDK peer version integrity.
- **Required (L2 Controlled / Pre-Commit)**:
  `npx tsc --noEmit` to verify strict TypeScript types, component props, and native bridge interfaces.
- **Extended (L3 Release / CI)**:
  `npx expo export --dump-sourcemap` to perform a production bundle export, validating Hermes bytecode packaging and asset resolution.
