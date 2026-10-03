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

Select for a `.csproj` using `Microsoft.NET.Sdk.Web`, `Microsoft.NET.Sdk.Worker`, or EF Core. Resolve inherited `Sdk` values in `Directory.Build.props` / imported targets and EF Core versions through `Directory.Packages.props`; if those files cannot be resolved, report the framework as unconfirmed. Web and Worker projects do not require the same entry-point/controller structure. EF Core guidance applies to backend libraries only when an EF Core package is actually referenced; plain class libraries stay unselected.

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
