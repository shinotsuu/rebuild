# API Reference

Status: Draft for Phase 1 MVP

This document describes the initial API design for the backend service. It focuses on core endpoints required by the phased rebuild plan. Schemas are representative and may be implemented via Pydantic models.

Base URL
- Dev Docker Compose: http://localhost:3000
- API Prefix: /api

Auth and Security
- Session cookie or JWT bearer. Cookie mode requires CSRF for mutating requests.
- CORS configured via env. Rate limiting recommended on generation endpoints.
- Request-Id header and response echo for tracing.

Error Shape
{
  "error": { "code": "string", "message": "string", "details": {} },
  "request_id": "uuid"
}

Pagination
- Query params: page (default 1), page_size (default 20, max 100).
- Response fields: items[], page, page_size, total.

Auth
POST /api/auth/signup
- Body: { "email": "string", "password": "string" }
- 201 Created
- Errors: 409 if exists, 400 invalid
POST /api/auth/login
- Body: { "email": "string", "password": "string" }
- 200 OK; set-cookie session or returns { "token": "..." }
POST /api/auth/logout
- 204 No Content; clears session

Users
GET /api/users
- Admin-only; Query: page, page_size
- 200 { items: User[], page, page_size, total }
PUT /api/users/{id}/role
- Admin-only; Body: { "role": "admin|user|pending" }
- 200 User

Models
GET /api/models
- 200 { providers: [{ name, models: [{ name, type, capabilities }], cached? }] }
POST /api/completions
- Body: { "model": "string", "messages": [{role, content}], "temperature"?: number, "max_tokens"?: number, "metadata"?: {} }
- Streaming SSE by default. Non-streaming available via header Accept: application/json
- Headers forwarded: X-Chat-Id when present
POST /api/embeddings
- Body: { "model": "string", "input": ["text", ...] }
- 200 { data: [{ embedding: number[] }], model }

Chats
POST /api/chats
- Body: { "folder_id"?: string, "title"?: string }
- 201 Chat
GET /api/chats
- Query: folder_id?, page?, page_size?
- 200 { items: Chat[], page, page_size, total }
GET /api/chats/{id}
- 200 Chat with last N messages
POST /api/chats/{id}/messages
- Body: { "role": "user|assistant|system", "content": "string", "files"?: [file_id], "params"?: {} }
- SSE stream of tokens: event: token|done|error; data: { id, delta, finish_reason?, sources? }

Knowledge and Files
POST /api/knowledge/upload
- multipart/form-data file upload
- 201 KnowledgeFile
GET /api/knowledge
- Query: folder_id?, page?, page_size?
- 200 { items: KnowledgeFile[], page, page_size, total }
DELETE /api/knowledge/{id}
- 204 plus vector purge best-effort

Retrieval
POST /api/retrieval/query
- Body: { "query": "string", "folder_id"?: string, "top_k"?: number, "hybrid"?: boolean }
- 200 { contexts: [{ text, score, metadata }], model?: "embedding-model" }

Folders
POST /api/folders
- Body: { "name": "string", "system_prompt"?: "string" }
- 201 Folder
GET /api/folders
- 200 { items: Folder[] }
GET /api/folders/{id}
- 200 Folder
PUT /api/folders/{id}
- Body: { "name"?: "string", "system_prompt"?: "string" }
- 200 Folder
DELETE /api/folders/{id}
- 204

Notes
POST /api/notes
- Body: { "title": "string", "content": "richtext-json-or-markdown" }
- 201 Note
GET /api/notes
- 200 { items: Note[] }
GET /api/notes/{id}
- 200 Note
PUT /api/notes/{id}
- Body: { "title"?: "string", "content"?: "..." }
- 200 Note
DELETE /api/notes/{id}
- 204
POST /api/notes/{id}/enhance
- Body: { "prompt"?: "string", "model"?: "string" }
- 200 Note (updated content) or SSE stream

Admin/Workspace
GET /api/admin/settings
- Admin-only; returns connection settings, flags
PUT /api/admin/settings
- Admin-only; Body: { "ollama_base_url"?: "...", "openai_api_key"?: "...", "offline_mode"?: boolean, "telemetry"?: boolean, "model_list_cache_ttl"?: number }

Schemas (Representative)
User
- id: string, email: string, role: "admin"|"user"|"pending", created_at, updated_at
Folder
- id, name, system_prompt?, owner_id, created_at
Chat
- id, folder_id?, owner_id, title, created_at
Message
- id, chat_id, role, content, metadata?, sources?, created_at
KnowledgeFile
- id, folder_id?, path, mime, size, checksum, created_at
Note
- id, owner_id, title, content (rich), created_at, updated_at

Security Considerations
- Cookie session: HttpOnly, Secure, SameSite default Lax in dev
- JWT: short-lived access tokens, refresh via rotation
- RBAC on routers; rate limit model endpoints
- Validate MIME, size limits on uploads; path traversal prevention