# Activity 01: High-Throughput, Resilient API System Design

## Overview
Design a high-throughput, fault-tolerant payment webhook ingestion and dispatch engine capable of handling $10,000\text{ req/sec}$ traffic spikes during Black Friday sales without dropping events or double-charging customers.

---

## Scenario & Requirements

### Functional Requirements
1. **Idempotent Ingestion**: Ingest incoming payment event webhooks from providers (Stripe, PayPal, Adyen), which guarantee at-least-once delivery: record event IDs in an idempotency ledger and return duplicates without re-executing side effects, for effectively-once processing — redeliveries and replays never drop events or double-charge customers.
2. **Asynchronous Dispatch**: Dispatch processed payment events to internal consumer services (Order Fulfillment, Fraud Detection, Customer Notification).
3. **Replayability & Audit**: Support event replay capabilities for failed consumer deliveries up to 7 days.

### Non-Functional Requirements
- **Throughput**: Baseline $2,500\text{ req/sec}$, peak surge $10,000\text{ req/sec}$.
- **Latency**: Ingestion endpoint p99 response time $< 50\text{ms}$.
- **Availability**: 99.99% uptime with zero data loss.
- **Resilience**: Downstream consumer outages must not backpressure or fail the ingestion gateway.

---

## Simulation Steps

### Step 1: Spec-Driven Planning (`pk:plan` / `pk:spike`)
1. Activate the plan workflow: `pk:plan for high-throughput webhook system` (or `pk:spike` to benchmark queueing trade-offs).
2. Define explicit system boundaries, components, and data contracts.
3. Choose the appropriate persistence and queueing models (e.g., Redis Streams, Apache Kafka, AWS SQS vs. PostgreSQL with partitioned tables).

### Step 2: Architecture & Threat Modeling
1. Design the idempotency mechanism:
   - How is the idempotency key extracted and validated?
   - How are in-flight concurrent duplicate requests locked (Distributed lock vs. DB unique constraint)?
2. Design the rate limiter and circuit breaker:
   - Token bucket vs. Leaky bucket algorithm.
   - Fallback strategies when downstream services degrade.

### Step 3: Draft the Technical Specification
1. Use `.promptkit/templates/tech-spec-template.md` to draft a complete RFC in `./docs/specs/`.
2. Include sequence diagrams, schema definitions, and failure recovery policies.

### Step 4: Retrospective & ADR Creation (`pk:retro`)
1. Run `pk:retro` with your mentor.
2. Create an Architectural Decision Record in `./docs/adrs/` justifying your queueing and idempotency design.

---

## Success Criteria
- [ ] Technical spec document thoroughly accounts for peak load, network partition, and duplicate deliveries.
- [ ] Schema design prevents race conditions on duplicate webhook delivery.
- [ ] ADR is committed in `./docs/adrs/` with clear trade-off justification.
