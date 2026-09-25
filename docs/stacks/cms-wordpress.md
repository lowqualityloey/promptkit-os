---
name: cms-wordpress
category: web
version: 1
token_budget: 1500
activation:
  manifests:
    - wp-config.php
    - composer.json
    - theme.json
verification:
  fast:
    - composer validate --no-check-all
    - vendor/bin/phpcs -q --standard=WordPress src/
  required:
    - composer test
    - vendor/bin/phpcs --standard=WordPress .
  extended:
    - vendor/bin/phpunit
    - wp core verify-checksums
invariants:
  - "Use $wpdb->prepare() with %s, %d, %f type specifiers for all direct database queries; string concatenation is prohibited"
  - "Verify anti-CSRF nonces using check_admin_referer(), check_ajax_referer(), or wp_verify_nonce() on all mutating requests"
  - "Assert explicit user capabilities via current_user_can() before executing administrative actions or custom REST mutations"
  - "Apply contextual late escaping (esc_html, esc_attr, esc_url, wp_kses_post) at render time; input sanitization does not replace output escaping"
  - "Enforce explicit pagination in WP_Query and prime metadata caches to prevent N+1 query loops in template files"
  - "Encapsulate plugin and theme functionality in modular hooks (init, rest_api_init); never run side effects on file include"
anti_patterns:
  - "Direct raw SQL interpolation in $wpdb queries without prepare(), creating SQL injection vulnerabilities"
  - "Processing form submissions, AJAX actions, or REST updates without verifying a valid nonce"
  - "Using is_admin() as an authorization check; is_admin() verifies the URI request path, not user capability"
  - "Directly echoing unsanitized $_GET, $_POST, or database variables into HTML without late escaping"
  - "Querying posts_per_page => -1 or executing get_post_meta() inside loops without batch cache hydration"
  - "Editing WordPress core or third-party vendor code directly instead of using hooks, filters, and child themes"
---

# WordPress CMS & Modern Application Playbook

Operational guidelines, security invariants, database safety, and verification tiers for WordPress plugins, themes, and Bedrock installations.

## 1. Architectural Invariants

- **Mandatory Prepared SQL Statements**: When using `$wpdb`, queries must strictly use `$wpdb->prepare()` with explicit placeholders (`%s`, `%d`, `%f`). String concatenation and direct interpolation of `$_GET`/`$_POST` are prohibited. For standard post retrieval, use `WP_Query` or `wp_insert_post()`.
- **State Mutation Nonce Verification**: Every state-changing action must verify a valid nonce. Web forms require `wp_nonce_field()` with `check_admin_referer()`, AJAX actions require `check_ajax_referer()`, and REST routes require a `permission_callback` checking `wp_rest` nonces. Mutating state without nonce verification creates CSRF vulnerabilities.
- **Explicit Capability Authorization**: Never use `is_admin()` for authorization; it checks only if the URL is within `/wp-admin/` and returns `true` during unauthenticated `admin-ajax.php` requests. Check permissions against explicit capabilities using `current_user_can()` before executing privileged logic.
- **Contextual Late Output Escaping**: All dynamic data, options, and user inputs must be escaped at the exact moment of output: `esc_html()` for inner text, `esc_attr()` for attributes, `esc_url()` for links, `esc_js()` for scripts, and `wp_kses_post()` for allowed HTML. Early input sanitization never replaces contextual late escaping.
- **Unbounded Query & Meta Loop Prevention**: `WP_Query` instances must never set `'posts_per_page' => -1` on public endpoints without strict boundaries. Avoid executing `get_post_meta()` inside template loops; call `update_post_caches()` or `update_postmeta_cache()` to hydrate the object cache in a single batched query, preventing N+1 cascades.
- **Lifecycle & Declarative Architecture**: Hook initialization logic into standard WordPress lifecycle actions (`init`, `wp_enqueue_scripts`, `rest_api_init`). Never execute side effects upon file inclusion. In modern themes, configure design tokens and block settings declaratively in `theme.json` rather than hardcoding styles in PHP templates.

## 2. Critical Anti-Patterns & Pitfalls

- **SQL Injection via Concatenation**: Concatenating variables into queries (`"$wpdb->prefix . table WHERE id = " . $_GET['id']`) enables SQL injection.
- **Authorization Bypass via is_admin()**: Checking `if (is_admin())` instead of `current_user_can()` permits unauthenticated users to invoke privileged endpoints via AJAX.
- **XSS via Early Sanitization Fallacy**: Assuming `sanitize_text_field()` on input makes a variable safe to echo raw into `<input value="<?php echo $val; ?>">` causes attribute breakout; late escaping with `esc_attr()` is mandatory.
- **Catastrophic N+1 Loops**: Fetching post metadata inside post loops without prefetching executes an independent SQL query per post, degrading throughput.
- **Core and Plugin Tampering**: Editing files in `/wp-admin/`, `/wp-includes/`, or third-party plugin directories breaks upstream update paths and guarantees lost changes on upgrades.

## 3. Tiered Verification Commands

- **Fast Tier (Pre-Commit / Pre-Build)**:
  - `composer validate --no-check-all`: Validates `composer.json` syntax and Bedrock package dependencies.
  - `vendor/bin/phpcs -q --standard=WordPress src/`: Fast static analysis checking WordPress Coding Standards (WPCS).
- **Required Tier (CI PR Gate / Pre-Merge)**:
  - `composer test`: Executes static analysis, syntax linting, and automated unit tests.
  - `vendor/bin/phpcs --standard=WordPress .`: Comprehensive codebase WPCS scan checking escaping, nonces, and prepared SQL.
- **Extended Tier (Nightly / Release Pipeline)**:
  - `vendor/bin/phpunit`: Runs PHPUnit integration tests with WordPress test suite and database mock.
  - `wp core verify-checksums`: Verifies WordPress core integrity against official checksums via WP-CLI.
