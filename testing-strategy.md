# Testing Strategy

Status: Initial coverage for MVP with CI gates

This document outlines testing levels, tooling, fixtures, and CI gates to ensure quality across backend and frontend. It prioritizes critical paths: auth, chat streaming (SSE), knowledge upload, and retrieval.

## Test Levels

Unit Tests
- Scope: pure functions, providers adapters (mocked IO), chunker, validators
- Backend: pytest with unittest.mock or respx/httpx mocking for outbound calls
- Frontend: vitest for stores and utilities

Integration Tests
- Scope: FastAPI routers with in-memory or temp SQLite DB, temporary storage directories, and mock providers
- SSE streaming tests using httpx AsyncClient and event parsing
- File upload and retrieval flow with stubbed embeddings/vector DB

End-to-End (E2E)
- Cypress: UI flows
  - login/signup
  - start chat, stream assistant tokens
  - upload file, ask RAG question and see sources
  - notes enhance basic happy path
- Optional: Playwright for cross-browser parity (later)

## Backend Testing

Tools
- pytest, pytest-asyncio
- httpx AsyncClient for API calls
- respx for httpx mocking or pytest-httpserver to emulate providers
- temporary directories via pytest tmp_path for storage

Fixtures
- app client: FastAPI app with dependency overrides for DB and storage
- db: SQLite in-memory or file-based temp database
- storage: temp directory with safe path adapter
- providers: fake embedding/completion backends returning deterministic outputs
- seed: create user, folder, chat

Examples (pseudocode)
- test_auth_signup_login_logout
- test_models_list_providers
- test_chats_stream_sse_yields_tokens
- test_knowledge_upload_and_index_stubbed
- test_retrieval_query_returns_contexts
- test_notes_enhance_passthrough

Coverage Targets
- Unit: 70%+ for services/utils
- Integration: cover all routers’ happy paths and key error cases

## Frontend Testing

Unit/Component
- vitest + @testing-library/svelte
- Stores: session, models, chats
- Components: Chat input, message list (render deltas), model selector

E2E
- Cypress tests triggered after docker-compose up
- Smoke spec suite to keep runs fast (<5 min)

## CI Gates

Stages
1) Lint/Typecheck
   - eslint + prettier (frontend)
   - black/pylint (backend)
   - svelte-check, tsc
2) Unit
   - vitest
   - pytest (unit-only markers)
3) Integration
   - pytest (integration markers)
4) E2E Smoke (optional on PR; required on main)
   - bring up compose
   - run Cypress spec subset

Artifacts
- Coverage reports uploaded on CI
- Cypress videos/screenshots on failure
- Logs from API container for debugging

## Test Data

- Minimal seed via scripts/bootstrap.sh and API routes
- Synthetic texts for RAG (short md/pdf extracts)
- Deterministic embeddings in tests (e.g., fixed vectors) to avoid nondeterminism

## Performance and Flakiness

- SSE test timeouts with generous margins; retry a few times in CI for robustness
- Use idempotent resource names with suffixes to avoid cross-test contamination
- Parallelize pytest with xdist cautiously (DB and ports isolation required)

## Security Tests

- Negative tests: invalid auth, role violations, CORS rejection
- Upload abuse tests: oversize files, disallowed MIME
- Path traversal attempts on storage layer

## Local Developer Workflow

- Backend: pytest -q
- Frontend: npm run test:frontend
- E2E: docker compose -f sourcecode/docker-compose.yaml up -d && npx cypress run

## Roadmap

- Contract tests for provider integrations (OpenAI/Azure/Ollama) behind toggles
- Load testing: simple k6/Gatling scripts for chat streaming throughput
- DAST/ZAP scanning stage with allowlist