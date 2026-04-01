# Appendix A: Glossary

**Agent loop** — The cycle of input -> reason -> act -> observe that defines agentic behavior. The fundamental unit of agent execution. (Ch 1)

**Bounded coordination** — The constraint that agents cannot make commitments that outlive their session. Agent IDs do not survive restart. (Ch 16)

**Cache prefix** — The byte-identical portion of the prompt that is reused across turns. Cache hits reduce cost; any change to the prefix busts the cache. (Ch 11)

**Cache snapshot** — A frozen copy of conversation state saved after each turn, enabling side-channel operations to reuse the cached prefix. (Ch 9, 11)

**Compaction** — Mid-session compression of conversation history. Resets latches, rebuilds the cache prefix, reduces per-turn cost. (Ch 9, 11)

**Consolidation** — The phase of memory management where accumulated daily logs are distilled into structured topic files. Performed by the Dream task. (Ch 10)

**Conversation-as-protocol** — Using structured XML inside conversation messages as the coordination mechanism for multi-agent systems, instead of a separate message bus. (Ch 16)

**Defense-in-depth** — Layering multiple independent security mechanisms so that failure of one layer does not compromise the system. (Ch 12, 14, 15)

**Diminishing-returns detection** — Automated measurement of tokens consumed per iteration. If two consecutive iterations produce fewer than ~500 tokens of change, the system stops. (Ch 7, 8, 11)

**Dream task** — A bounded background sub-agent that consolidates accumulated memory logs into structured topic files. Has a turn cap and rollback on failure. (Ch 10)

**Environment engineering** — The practice of shaping the operating environment (context, tools, permissions, memory, integrations) rather than optimizing prompt wording. The central thesis of the book. (Ch 19)

**Extraction fork** — A background agent that runs after each turn to distill conversation into persistent memory. Has mutual exclusion with the main agent's memory writes. (Ch 10)

**Fail-open** — Security design where a failed security component degrades protection rather than blocking all work. (Ch 15)

**Fixed-point iteration** — Repeating a transformation until no more changes occur. Used in permission pipelines for env-var stripping where wrappers can nest arbitrarily. (Ch 12)

**Fork** — Creating parallel child agents that share a byte-identical prompt prefix with the parent, diverging only in the task directive. (Ch 6, 16)

**Gate function** — A decision point between chain phases that determines whether to proceed, retry, abort, or redirect. (Ch 5)

**HITL (Human-in-the-Loop)** — A human decision point inside the agent's execution loop. Most effective when placed after exploration and before mutation. (Ch 13)

**Latch** — A session configuration value that is set once at boot and cannot be changed mid-session without compacting or clearing. Exists to protect cache stability. (Ch 9)

**MCP (Model Context Protocol)** — A standardized protocol for connecting agents to external tools, resources, and knowledge sources at runtime. (Ch 18)

**Mutual exclusion** — Coordination mechanism ensuring only one writer can update a shared resource at a time. Applied to memory extraction to prevent duplicate writes. (Ch 10)

**Permission pipeline** — A layered sequence of security checks between the agent's proposed action and actual execution. Not a blocklist — a multi-layer evaluation. (Ch 12)

**Prefix sharing** — Engineering parallel agents to share a byte-identical prompt prefix, paying for one cached prefix instead of N independent ones. (Ch 6, 11, 16)

**Prompt assembly** — Building the system prompt at runtime from layered sources: project instructions, user memory, extracted memories, tool definitions, conversation history. (Ch 2)

**Reject-over-truncate** — The safety principle that oversized input should be rejected entirely rather than truncated, because truncation changes meaning and can be exploited. (Ch 14)

**Skill** — A reusable instruction set that teaches the agent domain-specific behavior. Loaded into the prompt as additional context. (Ch 18)

**Stop hooks** — Parallel post-turn processes: cache snapshots, memory extraction, job classification, consolidation checks, resource cleanup. (Ch 9, 17)

**Token budget** — A limit on tokens consumed per session or task, enforced by the runtime. May use hard caps, soft caps, or diminishing-returns detection. (Ch 7, 11)

**Tool pool** — The set of tools available to a specific agent. Scoped per role for safety, focus, and cache economics. (Ch 1, 3)

**Transport layer** — The communication protocol connecting IDE extensions to CLI backends. Has its own versioning, auth models, and event delivery guarantees. (Ch 19)
