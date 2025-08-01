# Streaming Protocols

Status: SSE for Phase 1, WebSocket upgrade in Phase 8

This document specifies the initial Server-Sent Events (SSE) streaming protocol for chat completions, and the later WebSocket design to support reliable stop/cancel and multi-replica coordination.

## SSE (Phase 1)

Endpoint
- POST /api/chats/{id}/messages
- Response: Content-Type: text/event-stream; cache-control: no-cache

Events
- event: token
  data: { "id": "message-id", "delta": "text" }
- event: done
  data: { "id": "message-id", "finish_reason": "stop|length|error", "sources"?: [ {...} ] }
- event: error
  data: { "id": "message-id", "code": "string", "message": "string" }

Headers
- X-Chat-Id: forwards chat id to provider requests for tracing
- X-Request-Id: request correlation id
- Retry: 0

Stop behavior
- Client stops by closing the SSE connection
- Backend cleans up generator and provider requests

Error handling
- On provider error, send event:error then terminate stream
- Include message and optional details

## WebSocket (Phase 8)

URL
- GET /api/ws/chats/{id}

Message types
- client -> server:
  - start: { "messages": [...], "params": {...} }
  - stop: { "message_id": "..." }
- server -> client:
  - token: { "message_id": "...", "delta": "..." }
  - done: { "message_id": "...", "finish_reason": "..." }
  - error: { "message_id": "...", "code": "...", "message": "..." }

Rooms and scale-out
- Room keyed by chat id
- Optional Redis pub/sub for stop signal across replicas
- Locking with timeouts for concurrent writers

Backpressure and heartbeats
- Ping/pong every 15–30s
- Drop connection on timeout to avoid zombie streams

Security
- Auth required; enforce permissions on chat id
- Rate limits and message size caps