---
name: mobile-kmp
category: mobile
version: 1
token_budget: 1500
activation:
  manifests:
    - settings.gradle.kts
    - settings.gradle
    - build.gradle.kts
    - build.gradle
    - gradle/libs.versions.toml
verification:
  fast:
    - ./gradlew compileCommonMainKotlinMetadata
  required:
    - ./gradlew allTests
  extended:
    - ./gradlew check
invariants:
  - commonMain never imports platform APIs; keep platform implementations behind narrow interfaces.
  - Keep plugin and dependency versions in the version catalog and align Kotlin, Compose, KSP, and serialization plugins.
  - Do not use runBlocking in commonMain; use coroutine dispatchers supported by every target.
anti_patterns:
  - Leaking Android Context or UIKit controllers into shared domain code.
  - Claiming iOS tests passed from Linux or Windows.
  - Exporting the entire shared module as the iOS framework API.
---
# Kotlin Multiplatform Playbook

Confirm `org.jetbrains.kotlin.multiplatform` is applied in Kotlin or Groovy Gradle configuration. A catalog alias counts only when build configuration applies it and it resolves to that plugin ID. Convention plugins that cannot be resolved are unconfirmed; Gradle filenames alone do not activate this playbook. Plain Android/JVM builds are excluded.

## 1. Architectural Invariants

- Keep `commonMain` platform-neutral. Prefer injected platform implementations over broad `expect`/`actual` class hierarchies.
- Keep shared ViewModels and domain models free of `Context`, `UIViewController`, and platform lifecycle objects.
- Use Compose Multiplatform resources for assets genuinely shared by targets; keep platform-only resources in their source sets.
- Export a curated iOS framework API and keep Kotlin, Compose, KSP, and serialization plugin versions compatible.

## 2. Critical Anti-Patterns & Pitfalls

- Do not infer KMP from Android plugins or an unused catalog alias.
- Do not report iOS coverage from a non-macOS host. Mark unavailable targets `not measured`.
- Do not assume `allTests` covers every configured target; inspect Gradle tasks and toolchains first.
- Do not pin versions in this playbook; follow the repository's catalog and convention plugins.

## 3. Tiered Verification Commands

Discover module prefixes and actual task names with `./gradlew tasks` before running candidates. Fast: `./gradlew compileCommonMainKotlinMetadata`; required: `./gradlew allTests`; extended: `./gradlew check`. A project may need `:shared:` prefixes or different aggregates. Record each target and host actually exercised; iOS tests require macOS.
