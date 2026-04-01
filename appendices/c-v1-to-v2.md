# Appendix C: From V1 to V2 — What Changed and Why

## Context

V1 refers to two things: the *Agentic Design Patterns* textbook by Alessandro Gulli (21 patterns, 4 parts) and the [Codex Agentic Patterns](https://github.com/artvandelay/codex-agentic-patterns) project that grounded those patterns in OpenAI's Codex CLI. V2 is this book.

## Entirely New Chapters (not in v1)

| Chapter | Why it's new |
|---------|-------------|
| **Session Lifecycle** (Ch 9) | V1 assumes stateless turns. Production sessions have boot sequences, latches, stop hooks, resumability, and compaction. |
| **Context Economics** (Ch 11) | V1 doesn't address cost. Production systems are dominated by cache stability, prefix sharing, and diminishing-returns detection. |
| **Permission Pipelines** (Ch 12) | V1 has no security model. Production permissions are an eight-layer pipeline shaped by real vulnerability reports. |
| **Sandboxing and Isolation** (Ch 15) | V1 doesn't cover execution isolation. Production sandboxing addresses LLM-specific threats: prompt injection → heap scraping, token exfiltration. |
| **Operating an Agent Runtime** (Ch 19) | V1 has no synthesizing chapter. This chapter argues that agent operation is environment engineering, not prompt engineering. |

## Substantially Upgraded from V1

| Chapter | What changed |
|---------|-------------|
| **Prompt Assembly** (Ch 2) | V1: write good prompts. V2: prompts are assembled from layered sources with cache implications. |
| **Tool Use** (Ch 3) | V1: function calling mechanics. V2: per-tool failure semantics, tool definitions as cache surface. |
| **Planning** (Ch 7) | V1: plan-then-execute. V2: budget-aware planning with diminishing-returns stop signals. |
| **Memory** (Ch 10) | V1: store and retrieve. V2: accumulate-then-consolidate, mutual exclusion, rollback on failure. |
| **Multi-Agent** (Ch 16) | V1: topologies (coordinator, worker, peer). V2: conversation-as-protocol, cache-aware forks, bounded coordination. |
| **Observability** (Ch 17) | V1: test suites and benchmarks. V2: stop hook economies, PII-typed analytics, inspection-first debugging. |

## Merged or Removed from V1

| V1 pattern | Disposition |
|-----------|------------|
| Learning and Adaptation | Merged into Memory Management (Ch 10) |
| Goal Setting and Monitoring | Merged into Planning and Decomposition (Ch 7) |
| Prioritization | Merged into Planning (sub-pattern, not top-level) |
| Exploration and Discovery | Merged into Reflection (Ch 8) |
| Knowledge Retrieval (RAG) | Merged into Extension and Integration (Ch 18) — RAG is an integration pattern, not a standalone architecture |
| Inter-Agent Communication | Merged into Multi-Agent Coordination (Ch 16) — the communication mechanism *is* the coordination mechanism |

## Structural Changes

| Aspect | V1 | V2 |
|--------|----|----|
| Chapter count | 21 | 19 |
| Parts | 4 | 5 (added Safety as a standalone part) |
| Source material | Codex CLI (Rust) | Claude Code (TypeScript, ~500K lines) |
| Chapter template | Varies | Standardized: pattern, problem, how it works, production considerations, composability, common mistakes |
| Grounding | Textbook patterns + Codex source | Production observations mapped in CHAPTER-MAP.md before writing |

## The Core Shift

V1 answers: **What are the patterns?**

V2 answers: **What do the patterns look like when they actually run in production, under load, with real money and real adversaries?**

The patterns don't change. The engineering does.
