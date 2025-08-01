# RAG Pipeline

Status: Draft for Phase 3

This document describes the Retrieval Augmented Generation (RAG) pipeline for uploading, chunking, embedding, indexing, retrieving, reranking, prompt assembly, and model invocation. The MVP targets a local vector DB (Chroma or Qdrant). Hybrid retrieval with BM25 is included as a fallback/boost path.

## Objectives

- Enable users to upload knowledge (txt, md, pdf) and query it in chats.
- Provide relevant context snippets alongside answers, with source metadata.
- Keep providers pluggable (Ollama, OpenAI-compatible) for both completions and embeddings.

## Ingestion

Supported file types in MVP
- .txt, .md: direct text parsing
- .pdf: parsed via pypdf
- (Assumed) Future: .docx, .pptx, .csv via unstructured and companions

Security and validation
- MIME sniffing, size limits
- Safe storage paths: uploads/{user_id}/{date}/{uuid}
- Checksums recorded to detect duplicates; enable dedupe if desired

Extraction
- txt/md: read as UTF-8 text
- pdf: extract text per page; retain page indices for metadata

## Chunking

Parameters (configurable)
- chunk_size: 800–1200 chars
- chunk_overlap: 150–250 chars
- strategy: simple by characters; optional Markdown header-aware splitter later

Algorithm (simple)
1) Normalize whitespace
2) Slide window of chunk_size with overlap
3) For Markdown-aware, split by header boundaries first, then window sub-chunks

Metadata per chunk
- file_id, checksum
- page (for PDFs) or header path (for Markdown-aware mode)
- folder_id
- mime, created_at

## Embeddings

Providers
- OpenAI-compatible embeddings: text-embedding-3-* or similar
- Ollama local embeddings (e.g., nomic-embed-text)
- Sentence-transformers (future optional)

Batching
- Batch chunks for efficient embedding calls
- Retries with backoff on provider errors
- Cache embeddings by checksum + chunk hash (optional later)

## Indexing

Vector DB options
- Chroma (default, simple local)
- Qdrant (alternative; local or remote)
- Pinecone/PGVector (future options)

Collection schema (logical)
- id: UUID
- text: string
- embedding: vector[dim]
- metadata: JSON { file_id, checksum, page?, section?, folder_id?, mime?, created_at }

Index lifecycle
- On upload: create/update collection for folder or global
- On delete: purge vectors filtered by file_id/checksum
- On re-upload changed file: re-embed and upsert by checksum change

## Retrieval

Vector search
- embed(query) -> query_vector
- top_k nearest with cosine or dot-product similarity
- return { text, score, metadata }

Hybrid with BM25
- Optionally combine BM25 textual search with vector search
- Simple blending: normalized_score = alpha * vector + (1 - alpha) * bm25
- Fallback path: if embeddings/provider unavailable, use BM25 only

Reranker (simple)
- Cosine-based re-rank on subset; or sentence-transformer cross-encoder later
- Deduplicate near-identical chunks

Windowing
- Select N tokens worth of text to fit model max context
- Prefer multi-file coverage if scores comparable

## Prompt Assembly

Template (representative)
```
You are a helpful assistant. Use the provided context to answer the user's question.
If the answer is not in the context, say you don't know.

Question:
{{query}}

Context:
{{#each contexts}}
[Source: {{metadata.file_id}} page={{metadata.page}} score={{score}}]
{{text}}

{{/each}}

Answer:
```

Source metadata
- Include a sources array in the response with file_id, page/section, and checksums
- UI displays “Sources” panel for transparency

## Model Invocation

Providers
- OpenAI-compatible or Ollama via backend abstraction
- Streaming preferred: SSE (Phase 1) then WebSocket upgrade (Phase 8)

Parameters
- model, temperature, max_tokens
- stop sequences (optional)
- system prompt augmentation from folder/system context

## Cost and Latency Notes

- Embeddings: batch requests to reduce per-call overhead
- Cache repeated queries where allowed
- Use local embeddings (Ollama) in offline mode
- Limit chunk count and top_k to keep prompt assembly efficient

## Failure Modes and Fallbacks

- Embedding provider down: BM25-only fallback
- Vector DB unavailable: show reason and skip RAG
- File parser failure: mark file with error; skip indexing
- Oversized context: drop lowest score chunks to fit

## Observability

- Log retrieval stats: top_k, scores, durations
- Counters: ingested files, chunks, embedding calls, search calls
- Trace request_id through provider calls and response

## Deletion and Reindex Policy

- Deleting a file:
  - Remove file from storage
  - Purge vectors by file_id/checksum
  - Invalidate caches
- Reindex trigger on file updates or chunking parameter changes