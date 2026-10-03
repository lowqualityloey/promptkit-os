---
name: deploy-gcp
category: cloud
version: 1
token_budget: 1500
activation:
  manifests:
    - cloudbuild.yaml
    - app.yaml
    - service.yaml
    - '*.tf'
verification:
  fast:
    - gcloud run services describe SERVICE --region REGION
  required:
    - gcloud run services replace service.yaml --dry-run
  extended:
    - terraform validate
invariants:
  - Use narrowly scoped service accounts and workload identity, not downloaded keys.
  - Bind secrets from Secret Manager at runtime without rendering values into build logs.
  - Review ingress, egress, region, and rollout configuration before release.
anti_patterns:
  - Project-wide Editor roles for a single service.
  - Service-account key files committed to source control.
  - Treating a dry run as deployment authorization.
---
# Google Cloud Deployment Playbook

Treat these manifest names as candidates, never as proof. Confirm Cloud Run with a `serving.knative.dev/v1` `Service` that also carries Google-specific `run.googleapis.com/*` configuration, a separate `run.googleapis.com` service declaration, or a checked-in command explicitly targeting Cloud Run. A generic Knative Service is not proof of Google Cloud because Knative also runs on other Kubernetes platforms. Confirm Functions with a Functions deployment declaration or command naming the function target. Terraform must declare the Google provider and a Cloud Run or Functions resource. Cloud Build must contain a step that deploys one of those confirmed targets; a generic `cloudbuild.yaml` is insufficient. Dockerfiles, generic `*.tf`, language manifests, and Google SDK dependencies alone do not activate this playbook. If target identity or scope is unresolved, report it as unconfirmed.

## 1. Architectural Invariants

- Give each workload a dedicated service account with only required roles; prefer Workload Identity Federation over service-account keys.
- Reference Secret Manager versions at runtime. Do not render secret values into Cloud Build substitutions, artifacts, or logs.
- Set Cloud Run ingress, egress, region, concurrency, and scaling limits deliberately; review exposure and cost implications.
- Use immutable image digests and separate build identity from runtime identity.
- Production deploys and IAM grants require explicit human authorization.

## 2. Critical Anti-Patterns & Pitfalls

- Do not assign project-wide Owner or Editor to a workload service account.
- Do not commit JSON key files or echo secret substitutions in logs.
- Do not expose all ingress or attach public invocation without an explicit access decision.
- Do not interpret validation or dry-run success as permission to deploy.

## 3. Tiered Verification Commands

Fast: validate the selected manifest (`gcloud run services describe` for a known deployed service); required: run `gcloud run services replace SERVICE.yaml --dry-run` to validate without applying it; extended: run `terraform validate` and policy checks. Confirm flags against the repository's installed CLI/provider versions.
