# Task Spec: Greeting module

<!-- Synthetic example (fixture-grade): demonstrates the format at Level 1.
     It runs against the tiny seed repo the operator creates for the batch;
     it is not a claim about real-world performance. -->

- **Task ID**: `BENCH-L1-01`
- **Level**: `L1`
- **Seed Repository**: `[operator-provided seed repo with src/app.ts exporting main()]`
- **Prompt**: `"Add an exported greet(name: string) function to src/app.ts that returns the string 'Hello, ' + name, and call it from main() with the value 'world'. Do not change any other file."`
- **Setup**: `None`

## Rubric

- [ ] `R1`: `src/app.ts` contains an exported `greet` function taking one string parameter.
- [ ] `R2`: `greet('world')` returns exactly `Hello, world` (string concatenation, no template changes elsewhere).
- [ ] `R3`: `main()` calls `greet` with the argument `world`.
- [ ] `R4`: No file other than `src/app.ts` is modified (checked on the stripped diff).

## Notes

- The task is deliberately over-specified on the return format so the rubric is
  mechanical; agents that add tests or comments are neither rewarded nor penalized
  (R1–R4 only).
