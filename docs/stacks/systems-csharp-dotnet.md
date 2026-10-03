---
name: systems-csharp-dotnet
category: systems
version: 1
token_budget: 1500
activation:
  manifests:
    - '*.csproj'
    - '*.sln'
verification:
  fast:
    - dotnet build --no-restore
  required:
    - dotnet test
  extended:
    - dotnet format --verify-no-changes
invariants:
  - Keep controllers thin and put use-case policy in application services.
  - Bound EF Core query shape and project to DTOs to avoid N+1 reads.
  - Keep DbContext scoped to a request or unit of work; never capture it in a singleton.
anti_patterns:
  - Returning EF entities from public APIs.
  - Running parallel operations on one DbContext.
  - Holding database transactions open across network calls.
---
# C# .NET Backend Playbook

Confirm ASP.NET Core and EF Core references in the project before selecting this guidance. Use the solution's target framework and existing central package management rather than pinning versions here.

## 1. Architectural Invariants

- Controllers bind and validate transport contracts; application services own use cases; infrastructure owns EF Core access.
- Keep `DbContext` request-scoped. Do not inject it into singleton services or use it concurrently across tasks.
- Project queries to response DTOs, use explicit `Include`/split-query decisions, and paginate unbounded collections.
- Place transactions around local database work. Keep remote calls outside transactions; use an outbox for durable event delivery.
- Enforce tenant and authorization filters at the query/mutation boundary, not only in UI code.

## 2. Critical Anti-Patterns & Pitfalls

- Do not serialize tracked entities or trigger lazy-loading N+1 queries in serializers.
- Do not call `Task.WhenAll` with multiple operations on one context.
- Do not swallow exceptions into empty result objects or success HTTP responses.
- Do not edit an applied migration; add a forward migration and a recovery plan.

## 3. Tiered Verification Commands

Fast: `dotnet build --no-restore`; required: `dotnet test`; extended: `dotnet format --verify-no-changes`. Discover the solution and target frameworks first; run tests per target when the repository defines a matrix.
