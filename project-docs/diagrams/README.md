# Diagrams Placeholders

This folder holds system and process diagrams referenced by docs/rebuild.md.

Provide either binary diagram sources (e.g., .drawio) and generated images (e.g., .png/.svg), or keep these Markdown stubs updated until graphics are produced.

Planned diagrams:
1. System architecture (architecture.drawio / architecture.png)
   - High-level overview of frontend (SvelteKit), backend (FastAPI), database, vector DB, object storage, and optional Redis.
   - Deployment contexts: local (Compose) and future K8s.

2. Build pipeline flow (build-pipeline.drawio / build-pipeline.png)
   - Steps: install dependencies → lint/typecheck → unit tests → build → e2e tests → package/deploy.
   - CI/CD alignment with local scripts.

3. Data flow diagram (data-flow.drawio / data-flow.png)
   - Chat request path: FE → API → provider/vector DB → streaming back to FE.
   - Knowledge ingestion: upload → extract → chunk → embed → index → retrieve.

Place diagram sources here when ready:
- architecture.drawio
- build-pipeline.drawio
- data-flow.drawio

Export guidance (suggested):
- PNG: 1920px width
- SVG: include text as text, not curves