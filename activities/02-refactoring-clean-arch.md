# Activity 02: Refactoring Legacy Monolith to Clean / Hexagonal Architecture

## Overview
Refactor a tightly-coupled, 1,200-line monolithic Express/Fastify route handler containing mixed SQL queries, third-party Stripe API calls, nodemailer logic, and HTTP response handling into a decoupled, highly testable **Clean / Hexagonal (Ports and Adapters)** architecture.

---

## Scenario & Legacy Code Anti-Patterns

The existing legacy handler suffers from multiple architectural smells:
1. **Direct Database Coupling**: Raw SQL queries written directly inside HTTP controllers.
2. **Third-Party Vendor Lock-In**: Direct invocation of external SDKs (Stripe, SendGrid) without interface abstraction, leaving tests no seam for fast hermetic doubles — coverage leans on slow network-level mocks or live calls instead of typed adapter fakes.
3. **Implicit Side Effects**: Email dispatch and database mutations performed without transactional rollback on downstream failures.
4. **Zero Domain Model Encapsulation**: Plain JSON objects mutated haphazardly across helper functions.

---

## Simulation Steps

### Step 1: Architectural Assessment (`pk:tutor`)
1. Activate `pk:tutor` to review the legacy code structure.
2. Identify domain entities, application use cases, and external infrastructure ports.
3. Map out the Clean Architecture ring:
   ```text
   [HTTP Router / Controller] ──► [Use Case / Interactor] ──► [Domain Entities]
                                           │
                                           ▼ (Ports)
                                  [Repository / Mailer Interface]
                                           ▲ (Implements)
                                           │
                                  [Database / SMTP Adapter]
   ```

### Step 2: Extract Domain Entities & Value Objects
1. Create isolated domain models with business invariants (e.g., `Order`, `Money`, `OrderStatus`).
2. Ensure domain entities have zero external framework dependencies.

### Step 3: Define Ports (Interfaces)
1. Define repository interfaces (e.g., `OrderRepository`, `PaymentGateway`, `NotificationService`).
2. Implement dependency inversion so application use cases depend only on abstractions.

### Step 4: Implement Adapters & Use Cases
1. Write pure application use cases (e.g., `PlaceOrderUseCase`).
2. Build concrete adapters (e.g., `PrismaOrderRepository`, `StripePaymentAdapter`).

### Step 5: Senior Code Review (`pk:review`)
1. Run `pk:review` on the refactored code.
2. Verify that unit tests for the use case run in milliseconds without spinning up a real database or network server.

---

## Success Criteria
- [ ] Business logic isolated in pure TypeScript/JavaScript use cases with 100% unit test coverage.
- [ ] External infrastructure (database, payment provider, email) fully swappable via dependency injection.
- [ ] No framework or database imports inside the core domain layer.
