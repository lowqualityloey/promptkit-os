---
name: systems-java-spring
category: systems
version: 1
token_budget: 1500
activation:
  manifests:
    - pom.xml
    - build.gradle
    - build.gradle.kts
verification:
  fast:
    - ./mvnw -q -DskipTests compile
  required:
    - ./mvnw test
  extended:
    - ./mvnw verify
invariants:
  - Keep HTTP controllers thin; put use-case policy in services and persistence behind repositories.
  - Scope injected beans deliberately; request state must not live in singleton services.
  - Bound ORM fetch plans and paginate collections to prevent N+1 queries and unbounded reads.
anti_patterns:
  - Returning persistence entities directly from public APIs.
  - Hiding remote calls or transactions in entity callbacks.
  - Swallowing exceptions in broad controller advice.
---
# Java Spring Backend Playbook

Confirm Spring Boot dependencies or plugins in Maven/Gradle before activation. Use the wrapper and commands declared by the repository; the Maven commands below are candidates.

## 1. Architectural Invariants

- Controllers parse transport input and map responses; services own use cases; repositories own persistence queries.
- Treat singleton beans as stateless. Put per-request data in method arguments or request-scoped components with explicit lifecycle.
- Define fetch joins/entity graphs for required relations, cap collection endpoints with cursor or page limits, and inspect generated SQL.
- Keep transaction boundaries around one use case. Publish external effects after commit through an outbox when delivery must survive retries.
- Map persistence entities to API DTOs; validate authorization before loading or mutating tenant-owned rows.

## 2. Critical Anti-Patterns & Pitfalls

- Do not serialize JPA entities or let lazy loading drive response queries.
- Do not make network calls inside a database transaction.
- Do not use field injection or mutable singleton fields for user/session state.
- Do not catch `Exception` and return success-shaped defaults.

## 3. Tiered Verification Commands

Fast: `./mvnw -q -DskipTests compile`; required: `./mvnw test`; extended: `./mvnw verify`. For Gradle, inspect project tasks and use `./gradlew compileJava`, `./gradlew test`, then `./gradlew check` as repository-appropriate equivalents.
