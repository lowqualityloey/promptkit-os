---
name: api-fastapi
category: web
version: 1
token_budget: 1500
activation:
  manifests:
    - pyproject.toml
    - requirements.txt
    - Pipfile
    - alembic.ini
verification:
  fast:
    - ruff check .
    - mypy .
  required:
    - pytest
  extended:
    - pytest --cov=. --cov-report=term-missing
invariants:
  - "Define request and response payloads using explicit Pydantic v2 BaseModel schemas with Field constraints"
  - "Use native async def for non-blocking I/O operations and def for sync blocking or CPU-bound tasks"
  - "Manage connection pools and shared state using FastAPI lifespan async context managers, not on_event hooks"
  - "Inject database sessions and clients using FastAPI Depends() with generator yield cleanup"
  - "Isolate database ORM entities from public API schemas; never return raw database models across endpoints"
  - "Return structured error responses using HTTPException envelopes; never leak raw unhandled tracebacks"
anti_patterns:
  - "Executing blocking synchronous calls (time.sleep, sync requests) inside async def route handlers"
  - "Using deprecated @app.on_event('startup') or @app.on_event('shutdown') handlers instead of lifespan"
  - "Returning raw SQLAlchemy, SQLModel, or Tortoise ORM models directly without response_model validation"
  - "Instantiating global unmanaged database connection pools or HTTP clients outside dependency injection"
  - "Catching broad generic Exception and swallowing errors without structured status codes or logging"
  - "Omitting response_model or type annotations, disabling OpenAPI documentation and schema validation"
---

# FastAPI Application & API Playbook

Operational guidelines, async architectural invariants, Pydantic v2 schemas, and verification tiers for FastAPI services.

## 1. Architectural Invariants

- **Pydantic v2 Schema Boundary Separation**: Route endpoints must define distinct request and response schemas inherited from `pydantic.BaseModel`. Apply granular validation constraints using `Field(..., min_length=..., ge=...)`. Never expose internal database entities or ORM instances directly in response models; use `model_config = ConfigDict(from_attributes=True)` to map attributes safely without leaking sensitive columns (such as password hashes or internal tenant IDs).
- **Async vs Sync Handler Discipline**: Declare route handlers as `async def` only when invoking asynchronous, non-blocking I/O operations (`await db.execute()`, `await client.get()`). For synchronous or CPU-intensive operations (standard disk I/O, hashing, external SDKs lacking async support), declare handlers as standard `def`; FastAPI automatically delegates standard `def` functions to an external threadpool, preventing event loop thread starvation.
- **Modern Lifespan Resource Management**: Configure application startup and shutdown hooks using the `@asynccontextmanager` lifespan protocol on the `FastAPI(lifespan=...)` instance. Initialize database connection pools, cache clients (Redis), and background task workers before yielding, and gracefully close connections in the teardown phase. Deprecated `@app.on_event("startup")` and `@app.on_event("shutdown")` decorators must not be used.
- **Dependency Injection & Resource Lifecycles**: Manage database sessions, security tokens, and third-party service clients through FastAPI's `Depends()` mechanism. Yield session objects within context-managed generators (e.g., `async with async_session() as session: yield session`) so connections are automatically returned to the pool after response serialization, even when unhandled exceptions occur.
- **Structured Error Handling**: Raise `fastapi.HTTPException` with explicit `status_code` and structured JSON `detail` payloads for client-correctable failures (400, 401, 403, 404, 409, 422). Register global exception handlers (`@app.exception_handler`) to catch domain errors and transform them into predictable envelopes, preventing unhandled 500 crashes and internal server traceback disclosures.

## 2. Critical Anti-Patterns & Pitfalls

- **Event Loop Thread Starvation**: Invoking blocking functions (`time.sleep()`, synchronous `requests.get()`, or non-async database drivers) inside an `async def` handler freezes the single-threaded event loop, halting concurrent request handling across all workers.
- **Deprecated Event Handlers**: Utilizing `@app.on_event("startup")` or `"shutdown"` bypasses modern ASGI lifespan context guarantees and fails state sharing across middleware.
- **Unbounded Global Sessions**: Creating long-lived database transactions or HTTP clients in module-level global variables causes cross-request contamination, thread-safety violations, and socket leaks.
- **Direct ORM Exposure**: Exposing SQLAlchemy or SQLModel models in route returns exposes internal foreign keys, table layout changes, and triggers accidental N+1 lazy-loading cascades during serialization.
- **Swallowing Unhandled Exceptions**: Catching bare `except Exception:` without re-raising or logging with correlation IDs hides system faults and converts actionable defects into silent failures.

## 3. Tiered Verification Commands

- **Fast Tier (Pre-Commit / Pre-Build)**:
  - `ruff check .`: Fast linting and formatting verification enforcing PEP 8 and Python modern standards.
  - `mypy .`: Strict static type analysis verifying type annotations, Pydantic schemas, and endpoint signatures.
- **Required Tier (CI PR Gate / Pre-Merge)**:
  - `pytest`: Executes unit and API route tests using `httpx.AsyncClient` or `TestClient`.
- **Extended Tier (Nightly / Release Pipeline)**:
  - `pytest --cov=. --cov-report=term-missing`: Executes the full test suite with code coverage analysis to detect untested branches and edge cases.
