---
name: systems-rust
category: systems
version: 2
token_budget: 1500
activation:
  manifests:
    - Cargo.toml
verification:
  fast:
    - cargo check
  required:
    - cargo test
  extended:
    - cargo clippy -- -D warnings
invariants:
  - "Use cargo check as the primary inner development loop to verify types without code generation"
  - "Zero panics in production — propagate errors via Result and the question-mark operator"
  - "Prefer borrowed slices and references over eager data cloning and memory allocations"
  - "Model domain errors explicitly with thiserror for libraries and anyhow for applications"
  - "Document all unsafe code blocks with explicit SAFETY comments explaining the fulfilled invariants"
anti_patterns:
  - "Using unwrap() or expect() on fallible operations like I/O, user parsing, or network calls"
  - "Scattering premature .clone() calls across the codebase to appease the borrow checker"
  - "Running full cargo build or cargo test during rapid iterative syntax exploration"
  - "Writing unbounded recursive functions without tail recursion or heap-allocated stacks"
---

# Rust Systems & Native Playbook

Operational guidelines, invariants, and failure modes for systems software, CLI tools, and services implemented in Rust.

## 1. Architectural Invariants

- **The Fast Feedback Inner Loop**: In Rust, the compiler's code generation (`rustc` LLVM backend) accounts for the vast majority of build time. During normal code changes, type refactors, and implementation steps, execute `cargo check` exclusively. It verifies syntax, lifetimes, and type coherence in sub-second times without writing machine binaries.
- **Zero Panic Discipline**: Production systems code must never terminate ungracefully. Avoid `.unwrap()` and `.expect()` in non-test paths. All fallible operations (file access, serialization, network requests) must return `Result<T, E>` and utilize the `?` operator for clean propagation.
- **Borrow Checker Idioms**: Design APIs around borrowed views (`&str`, `&[T]`, `&Path`) rather than owned copies (`String`, `Vec<T>`, `PathBuf`) unless ownership transfer is strictly required. Do not use `.clone()` as a band-aid to circumvent lifetime design; restructure ownership boundaries instead.
- **Error Hierarchy**:
  - In libraries and crates: Use `thiserror` to define structured, enumerated domain error types (`#[derive(thiserror::Error)]`).
  - In CLI binaries and top-level services: Use `anyhow::Result` to provide rich error context chains (`.context("failed to open config")`).
- **Unsafe Code Audit Trail**: If `unsafe` is unavoidable (e.g. FFI bindings, low-level memory mapped I/O), every `unsafe` block must be immediately preceded by a `// SAFETY:` comment articulating the exact hardware, pointer, or alignment guarantees that prevent undefined behavior.

## 2. Critical Anti-Patterns & Pitfalls

- **Unwrap in Production Paths**: Invoking `.unwrap()` on a missing file or unexpected JSON payload triggers an uncontrolled thread panic, bringing down server workers or terminating CLI runs with raw stack traces.
- **Unbounded Collections**: Appending to a `Vec` inside an unconstrained loop without calling `Vec::with_capacity(n)` leads to repeated dynamic reallocations and memory fragmentation.
- **Lock Contention across Await**: Holding an active standard library mutex guard (`std::sync::MutexGuard`) across an asynchronous `.await` boundary causes Tokio or async runtimes to panic or deadlock worker threads. Use `tokio::sync::Mutex` only when locks must span `.await` points.
- **Dead Code Blindness**: Ignoring unused imports or dead code warnings during prototyping. Rust Clippy treats dead code as an anti-pattern that masks broken references.

## 3. Tiered Verification Commands

- **Fast (L0/L1 Direct)**:
  `cargo check` to perform instant compiler static analysis, borrow check verification, and type checking.
- **Required (L2 Controlled / Pre-Commit)**:
  `cargo test` to execute unit tests, integration tests, and doc-tests.
- **Extended (L3 Release / CI)**:
  `cargo clippy -- -D warnings` to enforce idiomatic Rust syntax, performance lints, and deny all warnings.

## 4. Performance Profiling Baseline

- **Named Bench Baselines**: Use `cargo bench` with Criterion (`--save-baseline <name>`) to lock a named baseline before optimizing; compare candidates with `critcmp <baseline> <candidate>` instead of eyeballing single runs.
- **Hot-Path Localization**: Profile before touching code: `cargo flamegraph` (or `perf record --call-graph dwarf` + `perf report`) on a release-profile build to find where cycles actually go; optimize what the flamegraph shows, not what intuition says.
- **Measurement Discipline**: Benchmarks are extended-tier (L3/CI) evidence — never the fast inner loop (`cargo check` stays the loop); no micro-benchmarks from debug builds (inlining and overflow checks distort results); change one variable per measurement.
- **Workflow Bridge**: Baseline → localize → optimize → measure delta per `pk:perf`; this playbook supplies the Rust tooling.
