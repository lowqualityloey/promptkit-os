---
name: deploy-aws
category: cloud
version: 1
token_budget: 1500
activation:
  manifests:
    - cdk.json
    - template.yaml
    - samconfig.toml
verification:
  fast:
    - npx cdk synth
  required:
    - npx cdk diff
  extended:
    - cfn-lint template.yaml
invariants:
  - Grant least-privilege IAM actions on the narrowest resource and trust principal.
  - Keep secrets in managed secret stores and reference them at runtime.
  - Review synthesized templates and destructive replacement behavior before deployment.
anti_patterns:
  - Wildcard IAM actions or principals without a documented boundary.
  - Plaintext secrets in templates, outputs, logs, or source control.
  - Treating a successful synthesis as deployment authorization.
---
# AWS Deployment Playbook

Confirm AWS CDK (`cdk.json`) or SAM/CloudFormation manifests before activation. Select commands from the actual toolchain and region configuration.

## 1. Architectural Invariants

- Scope IAM roles to the service, actions, and resources required. Constrain trust policies and avoid wildcard principals.
- Store credentials in Secrets Manager or Parameter Store; pass references, never secret values, through templates or logs.
- Inspect synthesized CloudFormation and diffs for public exposure, data deletion, replacement, and privilege expansion.
- Separate deployable environments and use explicit account/region targeting. Keep production deployment human-authorized.
- Prefer managed identity and short-lived role assumption over long-lived access keys.

## 2. Critical Anti-Patterns & Pitfalls

- Do not commit `.env`, access keys, or plaintext secret parameters.
- Do not grant `*` actions/resources as a convenience fix.
- Do not infer that `synth`/`validate` grants deployment approval.
- Do not ignore replacement or retention changes on stateful resources.

## 3. Tiered Verification Commands

Fast: `npx cdk synth` for CDK or `sam validate` for SAM; required: inspect `npx cdk diff` or the equivalent change set; extended: run `cfn-lint` and policy checks. Commands are candidates; use repository-pinned tooling and never execute deployment as verification.
