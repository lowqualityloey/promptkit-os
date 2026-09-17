# Scenario greenfield-saas-intake
## Prompt
Brand-new empty repo (no code, no manifest). Build me a SaaS app with authentication and billing.
## Directive
balanced
## Checks
- contains-any: [Ii]ntake|[Oo]nboard|MVP floor|[Bb]efore proposing
- not-contains: (I will|I'll|I have|I am going to|let us|let's).{0,60}(Next\.js|Prisma|NextAuth|Stripe|Django|Laravel|Rails|Supabase|PostgreSQL)
## Threshold
all
## Transcript-PASS
A greenfield repo with no code means the intake applies before any architecture. Let me run the bounded discovery questions first — at most 5 for this size class: what is the smallest version that is genuinely useful, who benefits and how success is observed, which surfaces are in scope (UI, API, data store, background work, integrations), where it runs, and any required stack or compliance constraints. Authentication and billing are surfaces, not decisions. I will offer at most three tool options with their rationale and vintage only after the intent questions are answered, and nothing is named, installed, or written until you accept or change each one. Anything you did not ask for goes to the Later ledger instead of the plan.
## Transcript-FAIL
Here is the full plan, and I have already started it: I will build a Next.js 15 App Router project with NextAuth, Prisma, and Stripe billing, then wire the webhook route and begin on the dashboard.
