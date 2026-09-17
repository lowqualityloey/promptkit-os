---
name: cli-python
category: cli
version: 1
token_budget: 1500
activation:
  manifests:
    - pyproject.toml
    - setup.cfg
    - requirements.txt
verification:
  fast:
    - ruff check .
  required:
    - pytest
  extended:
    - mypy .
invariants:
  - "Enforce strict virtual environment isolation — never run global unconstrained pip commands"
  - "Annotate public functions and data models with explicit Python type hints"
  - "Emit deterministic exit status codes using sys.exit(0) on success and sys.exit(1) on failure"
  - "Leverage ruff as the primary sub-millisecond linting and AST hygiene feedback loop"
  - "Declare dependencies deterministically with exact version constraints in pyproject.toml"
anti_patterns:
  - "Catching raw generic Exception without re-raising or structured logging of the traceback"
  - "Using mutable default arguments like empty lists or dictionaries in function parameter lists"
  - "Importing modules inside nested loop bodies instead of at the top of the file"
  - "Executing subprocess commands with shell=True exposing the CLI to shell injection vulnerabilities"
---

# Python CLI & Systems Playbook

Operational guidelines, invariants, and failure modes for command-line utilities, automation scripts, and native tools implemented in Python.

## 1. Architectural Invariants

- **Virtual Environment Isolation**: Never install dependencies or execute scripts against the global system Python environment. All development and testing must take place inside an activated virtual environment (`.venv`, `uv venv`, `poetry shell`). Installing packages globally pollutes system binaries and triggers host dependency conflicts.
- **Strict Typing with Mypy**: Modern Python CLI tools require full type annotations (`from typing import Optional, List, Dict` or native generics `list[str]` in Python 3.10+). Treat type checking as a mandatory pre-commit quality gate using `mypy .` or `pyright`.
- **Deterministic CLI Exit Status Codes**: A CLI tool must clearly communicate success or failure to calling shell pipelines. Exit with `sys.exit(0)` on clean termination, `sys.exit(1)` on anticipated operational failure, and `sys.exit(2)` on invalid command-line flag syntax. Never allow unhandled tracebacks to dump raw Python errors when user errors occur.
- **The Fast Feedback Loop with Ruff**: Use `ruff check .` and `ruff format --check .` for immediate AST and style validation. Running Ruff takes single-digit milliseconds, making it ideal for the L0/L1 fast-path verification before executing heavier pytest suites.
- **Modern Project Packaging**: Standardize on `pyproject.toml` (PEP 517/518/621) with modern build backends (e.g. `hatchling`, `flit`, `setuptools`). Avoid legacy `setup.py` scripts with executable installation logic.

## 2. Critical Anti-Patterns & Pitfalls

- **The Mutable Default Argument Trap**: Writing `def append_item(val, items=[]):` creates a single shared list across all function invocations, corrupting state between runs. Always use `items: Optional[list[str]] = None` and initialize with `if items is None: items = []`.
- **Broad Exception Swallowing**: Writing `except Exception:` and passing silently (`pass`) hides critical bugs (e.g. `KeyboardInterrupt`, syntax errors, missing files), leaving the user with zero diagnostic information when an operation fails.
- **Subprocess Shell Injection**: Running `subprocess.run(f"grep {query} {file}", shell=True)` exposes the application to arbitrary shell command execution. Always pass commands as discrete argument lists: `subprocess.run(["grep", query, file], shell=False)`.
- **Hardcoding Path Separators**: Building file paths with string concatenation (`folder + "/" + file`) breaks on Windows. Always use `pathlib.Path` or `os.path.join()`.

## 3. Tiered Verification Commands

- **Fast (L0/L1 Direct)**:
  `ruff check .` to execute blazing-fast linting, syntax error detection, and import hygiene.
- **Required (L2 Controlled / Pre-Commit)**:
  `pytest` to execute unit tests, CLI runner assertions (e.g. `CliRunner` with Typer/Click), and mock fixtures.
- **Extended (L3 Release / CI)**:
  `mypy .` to enforce strict type checking and interface compatibility across all modules.
