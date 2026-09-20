---
name: systems-go
category: systems
version: 2
token_budget: 1500
activation:
  manifests:
    - go.mod
verification:
  fast:
    - go vet ./...
  required:
    - go test -race ./...
  extended:
    - golangci-lint run
invariants:
  - "Check every returned error explicitly — never discard errors with blank identifier assignments"
  - "Propagate context.Context as the first argument to all blocking, network, or asynchronous functions"
  - "Every spawned goroutine must have a deterministic termination path to prevent goroutine leaks"
  - "Always run test suites with the race detector enabled using the -race flag"
  - "Prefer small, single-method interfaces declared at the consumer site rather than the producer site"
anti_patterns:
  - "Using panic() for standard runtime error conditions instead of returning an error value"
  - "Spawning unbuffered channels without consumers or cancellation contexts leading to deadlocks"
  - "Reading or mutating shared variables concurrently without mutexes or atomic primitives"
  - "Passing large structs by value when pointer receivers or references are appropriate"
---

# Go Systems & Service Playbook

Operational guidelines, invariants, and failure modes for systems services, microservices, and backend tooling implemented in Go.

## 1. Architectural Invariants

- **Explicit Error Handling**: In Go, errors are normal values. Every function returning `(val, error)` must have its error evaluated immediately: `if err != nil { return fmt.Errorf("failed operation: %w", err) }`. Never assign errors to the blank identifier `_` unless explicitly justified in a comment.
- **Context Propagation**: The `ctx context.Context` parameter must always be the first parameter of any function performing I/O, database queries, RPCs, or long-running computation. Functions must monitor `ctx.Done()` or pass `ctx` directly down to underlying drivers to ensure cancellations and timeouts abort in-flight work immediately.
- **Goroutine Leak Prevention**: Never spawn a goroutine (`go worker()`) without knowing precisely when and how it will exit. Every goroutine must listen on a cancellation channel (`<-ctx.Done()`) or complete bounded work. An orphaned goroutine holding references prevents garbage collection and leaks OS threads.
- **Race Detection Mandate**: Go provides a native race detector. Always include `-race` when running tests locally and in CI (`go test -race ./...`). Concurrency bugs that appear intermittent in production are caught deterministically by the race detector.
- **Consumer-Side Interfaces**: Define interfaces where they are consumed, not where they are implemented. Keep interfaces focused and minimal (often 1 or 2 methods, e.g. `io.Reader`, `io.Writer`). This allows easy mocking and loose coupling across internal packages.

## 2. Critical Anti-Patterns & Pitfalls

- **Panic in Business Logic**: Using `panic()` outside program initialization (`main()` / `init()`) abruptly kills the entire process, circumventing HTTP middleware recovery and graceful shutdown routines.
- **Goroutine Leaks on Channels**: Sending to an unbuffered channel when no receiver is listening blocks the goroutine indefinitely, silently consuming memory over time.
- **Shadowed Variables**: Misusing the short variable declaration operator `:=` inside an `if` block can shadow an outer error variable (`err`), leading to logic that erroneously believes a step succeeded.
- **Pointer to Loop Variable**: In older Go patterns (pre-Go 1.22), taking the address of a loop variable (`&item`) inside a goroutine captured the same mutating memory address. While Go 1.22 fixes loop scope per iteration, explicit variable passing into goroutines remains best practice.

## 3. Tiered Verification Commands

- **Fast (L0/L1 Direct)**:
  `go vet ./...` to perform instant static analysis, checking for suspicious constructs, printf formatting errors, and unkeyed struct literals.
- **Required (L2 Controlled / Pre-Commit)**:
  `go test -race ./...` to execute all unit and integration tests with data race detection enabled.
- **Extended (L3 Release / CI)**:
  `golangci-lint run` to run comprehensive multi-linter checks, static check analysis, and dead code detection.

## 4. Performance Profiling Baseline

- **Statistically Valid Benchmarks**: Use `go test -bench=. -benchmem -count=10` and compare runs with `benchstat` — a single benchmark run is scheduler noise, not evidence; lock the baseline before optimizing and re-measure the delta after.
- **CPU & Heap Localization**: Profile before touching code: `go test -cpuprofile=cpu.out -memprofile=mem.out -bench=.` then `go tool pprof -http=:<port>` to find where cycles and allocations actually go; optimize top pprof entries, one variable per measurement.
- **Race/Perf Separation**: The `-race` mandate covers correctness runs, not timing runs — benchmarks measured for performance must run without `-race`, whose instrumentation overhead distorts timings by an order of magnitude.
- **Workflow Bridge**: Baseline → localize → optimize → measure delta per `pk:perf`; this playbook supplies the Go tooling.
