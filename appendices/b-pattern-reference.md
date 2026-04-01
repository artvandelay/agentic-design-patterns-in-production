# Appendix B: Pattern Quick-Reference

Every pattern in the book, one line each.

| # | Pattern | One-line summary |
|---|---------|-----------------|
| 1 | Agent Loop | Input → reason → act → observe. The heartbeat. Reads parallelize, writes serialize. |
| 2 | Prompt Assembly | System prompts are assembled at runtime from layered sources. Prompt is configuration, not content. |
| 3 | Tool Use | Tools are a contract between model and runtime. Failure semantics are per-tool. Definitions are cache surface. |
| 4 | Routing | Dispatch to the right model, mode, provider, or sub-agent. Routing decisions have cost and observability requirements. |
| 5 | Prompt Chaining | Sequential phases (explore → plan → execute → verify) with gate functions between them. |
| 6 | Parallelization | Fan-out reads, serialize writes. Asymmetric failure propagation. Cache-aware fork design. |
| 7 | Planning | Plans are durable artifacts, not transient thoughts. Budget-aware with diminishing-returns stop signals. |
| 8 | Reflection | Bounded self-correction. Diminishing-returns detection + turn caps. Evidence-based beats judgment-based. |
| 9 | Session Lifecycle | Boot (assemble, latch), run (agent loop), stop hooks (parallel post-turn work), interrupt/resume. |
| 10 | Memory Management | Append-only accumulation, separate consolidation (Dream task), mutual exclusion between writers. |
| 11 | Context Economics | Cache stability as engineering constraint. Prefix sharing. Stable framing beats clever rephrasing. |
| 12 | Permission Pipelines | Eight-layer defense-in-depth. Fixed-point env-var stripping. Compound command splitting. Build-toolchain constraints. |
| 13 | Human-in-the-Loop | Place the human after exploration, before mutation. Manage outcomes, not keystrokes. |
| 14 | Guardrails | Reject over truncate. Compute rather than store. Build-time canary detection constrains security code. |
| 15 | Sandboxing | LLM-specific threat model: prompt injection → ambient authority. Heap-only tokens. Fail-open design. |
| 16 | Multi-Agent Coordination | Conversation-as-protocol. Cache-aware forks share one prefix. Bounded coordination — nothing outlives the session. |
| 17 | Observability | Stop hook economy. PII-typed analytics. Runtime killswitches. Inspection-first debugging for users, not just operators. |
| 18 | Extension & Integration | Extension points as first-class architecture (no-op stubs → full implementations). RAG as integration, not standalone. |
| 19 | Operating a Runtime | The agent is infrastructure. Transport versioning, feature flags, dependency reality. Environment engineering > prompt engineering. |
