# Glossary

This glossary defines common terms used across the project.

AI Provider
- A remote or local model endpoint that generates text or embeddings (e.g., OpenAI-compatible, Azure OpenAI, Ollama).

Alembic
- Database migration tool for SQLAlchemy. Used to evolve schema across phases.

Artifact
- Output object produced by tools or code interpreter (e.g., a chart, CSV) referenced by messages.

BM25
- Classical lexical retrieval scoring function used as a fallback/boost with vector search in hybrid retrieval.

Chat
- A conversation consisting of ordered messages between a user and assistant (and optional tools).

Chroma
- A lightweight local vector database used in dev environments.

CSRF
- Cross-Site Request Forgery protection; required when using cookie-based sessions.

Embeddings
- Numeric vector representations of text used for similarity search.

Folder
- Organizational container for chats and knowledge. Can hold a system prompt applied to child chats.

Hybrid Retrieval
- Combining vector search with BM25 lexical search to improve recall/precision.

i18next
- Internationalization framework used on the frontend.

Indexing
- The process of chunking files, embedding text, and writing entries into a vector store.

Knowledge
- User-uploaded files (txt/md/pdf initially) processed for retrieval.

Message
- One entry in a chat with role (system, user, assistant, tool) and content plus optional metadata.

MVP
- Minimum Viable Product: a reduced scope enabling key flows (auth, chat, RAG, notes).

Note
- Rich-text document edited with TipTap and optionally “enhanced” via a model.

Ollama
- Local model runtime exposing HTTP APIs for completions/embeddings.

PGVector
- Postgres extension for vector similarity search.

Provider Abstraction
- Service layer that normalizes calls to multiple model providers for completions and embeddings.

RAG
- Retrieval Augmented Generation: query embeddings/vector DB to fetch relevant context and augment prompts.

Redis
- Optional in-memory datastore used for pub/sub to coordinate stop/cancel across WebSocket replicas.

S3-compatible
- Object storage API used for file persistence beyond local filesystem.

SSE
- Server-Sent Events: HTTP streaming used initially to deliver tokens for chat responses.

Stop Generation
- User-triggered cancellation for ongoing streaming responses.

System Prompt
- Instructional prefix applied to a conversation or folder to guide assistant behavior.

TipTap v3
- Rich text editor framework used for notes editing.

Vector DB
- Database that stores embeddings and supports nearest-neighbor search (Chroma, Qdrant, Pinecone, PGVector).

WebSocket
- Full-duplex connection used for reliable streaming and stop/cancel across replicas in later phases.