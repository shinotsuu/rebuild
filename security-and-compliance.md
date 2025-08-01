# Security and Compliance

Status: Baseline for MVP with clear upgrade path

This document outlines authentication/authorization, transport and storage security, input validation, and privacy/telemetry policies. It highlights minimum viable protections for early phases and identifies follow-on work.

## AuthN/AuthZ

Authentication
- Primary: Local email + password
- Hashing: bcrypt (default) or argon2 (configurable); per-user salts
- Sessions: Cookie session (HttpOnly, Secure in prod, SameSite=Lax by default) or JWT bearer
- CSRF: Required for cookie session on mutating routes using header token (e.g., X-CSRF-Token)
- Password policy: minimum length (>= 12), deny common passwords; rate limit login

Authorization
- Roles: admin, user, pending
- Route guards:
  - admin: access to /api/admin/*
  - user: standard app operations
  - pending: minimal access until verified or approved
- Ownership checks: ensure users can only access their resources (folders, chats, notes)

## Transport and CORS

Transport
- HTTPS in staging and production
- HSTS enabled at reverse proxy (nginx/ingress)

CORS
- Dev: allow http://localhost:5173 and http://localhost:8080 (configurable via CORS_ALLOW_ORIGIN)
- Prod: restrict to exact origins; disallow wildcard

## Input Validation and Limits

Validation
- Pydantic schemas for all bodies; strict types, min/max lengths
- Param parsing for pagination, filters; sane defaults and maximums
- File upload validation: MIME sniffing (python-magic or equivalent), whitelist extensions

Limits
- Request body size caps (e.g., 10–50 MB configurable)
- Per-user/day upload caps (future)
- Generation endpoints:
  - token budget caps (max_tokens)
  - server-side guardrails on temperature, concurrent requests

## Files and Storage Safety

Paths
- Safe join under uploads/{user_id}/{date}/{uuid_filename}
- Reject .. and absolute paths
- Normalize and sanitize filenames prior to storage

MIME and Antivirus
- MIME detector required; reject executables/binaries unless explicitly allowed
- Antivirus hook placeholder (Assumed): integrate clamav or provider scanner later

Deletion and Purge
- Deleting a file:
  - Remove bytes from object storage (local FS now; S3 adapter later)
  - Purge vectors by file_id/checksum from vector store
  - Update references in messages/notes if present

## Secrets Management

Configuration
- Environment variables for OLLAMA_BASE_URL, OPENAI_API_KEY, DB URL, SECRET_KEY
- Avoid exposing secrets to client; SSR guards for SvelteKit
- Optional secrets-from-file (e.g., *_FILE) to read from mounted paths

Rotation
- Keys (OpenAI, Azure) replaceable via admin settings
- JWT signing keys and cookie secrets rotated with overlap windows (advanced; future)

## RBAC and Admin

- Admin can manage users (list, change role)
- Admin controls model connections, offline mode, telemetry flags
- Auditing: log admin actions with request_id and actor

## Rate Limiting and Abuse Prevention

- Token bucket on /api/completions; per-user/ip basis
- Authentication attempts limited; introduce cooldowns on repeated failures
- Upload endpoints guarded by size and frequency caps

## Logs and Telemetry

- Structured logs: level, timestamp, request_id, user_id (if authenticated), route, latency
- PII scrubbing: never log passwords, tokens, API keys, embeddings
- Telemetry flags:
  - DO_NOT_TRACK=true (default in dev)
  - ANONYMIZED_TELEMETRY=false (default in dev)
- OpenTelemetry (optional compose variant) for traces/metrics (experimental)

## Privacy

- Email is PII; limit exposure and avoid in verbose logs
- Right to delete: ensure cascade deletes of vectors/files
- Data retention: configurable retention windows (future)

## Compliance Considerations (Future)

- GDPR/CCPA readiness: data export/delete endpoints
- SOC2-type controls: change management, monitoring, backups, DR
- Vendor assessments for external providers (OpenAI/Azure)
- Encryption at rest:
  - Local FS: OS-level encryption (ops)
  - DB: Postgres TDE or disk encryption (ops)
  - S3: SSE-S3 or SSE-KMS keys

## Security Testing

- Unit tests for validators/guards
- Integration tests for auth flows and role boundaries
- DAST (OWASP ZAP) in CI (future)
- Dependency scanning (npm audit, pip/uv audit) and container scanning

## Incident Response (Initial Playbook)

- Identify via logs request_id, user_id, route
- Contain by revoking tokens/keys
- Eradicate: patch, rotate secrets
- Recovery: deploy patched images; verify via smoke tests
- Postmortem: document cause, mitigations, monitoring additions