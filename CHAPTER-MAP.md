# Chapter Map: Editorial Backbone

This document maps every proposed chapter to the concrete production observations that
justify its existence as a standalone chapter. A chapter that cannot point to at least
two non-obvious insights from real production systems is either merged into a neighbor
or cut.

Source: `how to use Claude Code better.md` (workflow principles + architecture reveals,
sections 1–32). References are by section number in that document.

---

## Verdict Key

- **EARNS IT** — Has 2+ concrete production insights that are not in v1. Write it.
- **STRONG** — Has 3+ genuinely novel insights. Anchor chapter for the Part.
- **MERGE** — Insufficient unique content at book-length. Absorbed into a neighbor.
- **THIN** — Has one real insight. Either slim chapter or merge.

---

## Part One: Foundations

### Ch 1 — The Agent Loop
**Verdict: EARNS IT**

The opening chapter must answer: why is an agent runtime different from a chat API call?
The architecture of Claude Code answers this directly: the system is not a chatbot with
file access, it is a full execution pipeline with a query engine, tool execution loop,
permission manager, memory system, and multi-agent coordinator all wired together.

Key production observations grounding this chapter:
- **§1**: "Tweaking prompt wording optimizes one layer of a much larger system." The
  system coordinates prompts, tools, memory, permissions, session state, background work,
  and multiple surfaces. This is the agent vs. chatbot distinction made concrete.
- **§2**: The architecture distinguishes read-heavy operations (parallelizable) from
  mutation-heavy operations (serializable). A chatbot has no such distinction. The
  existence of this constraint is proof of agentic architecture.
- **§10**: "In simple mode, workers get only three tools: Bash, Read, and Edit." The
  tool-pool as a scoped capability surface — configured per agent role — is not a chatbot
  concept. It is a runtime concept.

What this tells us beyond v1: v1 defines the agent loop abstractly (perceive -> reason ->
act). This chapter shows what the loop looks like when implemented: the query engine as
the heartbeat, the tool execution loop as the act phase, and the reasons why reads and
writes must be handled differently at the loop level.

---

### Ch 2 — Prompt Assembly
**Verdict: STRONG**

System prompts are not written by humans and submitted once. They are assembled at
runtime from multiple sources: project-level instructions, user-level memory, extracted
memories, team memory, session-level context, and injected tool definitions. The prompt
is configuration, not content.

Key production observations grounding this chapter:
- **§1**: "Context lives in multiple places. Project instructions, user memory, extracted
  memories, and team memory form a stack. Manage all those layers intentionally." This is
  not a tip — it is a description of how the system is architecturally built.
- **§9**: Several API headers are "latched" once per session and frozen, even if you
  toggle the setting afterward. The latch mechanism exists specifically to protect prompt
  cache stability. This means the assembled prompt has economic consequences: changing it
  mid-session is expensive.
- **§10**: "The coordinator understands [worker communication] format because its system
  prompt documents the schema." The system prompt is the contract between orchestrator and
  worker. It defines the protocol, not just the persona.

What this tells us beyond v1: v1 covers prompt design (clear instructions, few-shot
examples, etc.). This chapter covers prompt *architecture*: layering, assembly order,
cache stability, and why the system prompt is the configuration layer of an agent runtime.
This has no equivalent in v1.

---

### Ch 3 — Tool Use
**Verdict: STRONG**

Tool use in production is not about which tools to define — it is about the contract
between model and runtime: how tools are scoped per agent role, why tool definitions are
part of the prompt cache surface, and how tool failure semantics shape execution behavior.

Key production observations grounding this chapter:
- **§12**: "Only Bash errors trigger sibling cancellation — aborting all concurrent
  siblings with synthetic error messages. Failures from Read, WebFetch, and other tools
  explicitly do not." This is a deeply non-obvious production decision: Bash failure means
  the environment is broken (stop everything), while a file-read failure is informative
  text the model can reason about (continue). The failure semantics are per-tool, not
  universal.
- **§22**: "The fork agent keeps the Agent tool in its tool list even though it cannot
  use it, because removing it would change the tool definition block and bust the cache."
  Tool definitions are part of the prompt cache key. Changing the tool list is an
  expensive operation. This is the production reality of tool pool management.
- **§2**: The architecture distinguishes read-heavy tools (parallelizable) from mutation
  tools (serializable). Tool categories have different execution contracts.

What this tells us beyond v1: v1 covers function calling mechanics. This chapter covers
the runtime contract: failure semantics, cache implications of tool definition changes,
and why tool pools are scoped rather than universal.

---

### Ch 4 — Routing
**Verdict: EARNS IT**

Routing in agent systems means dispatching the right work to the right compute surface:
the right model (capability routing), the right mode (planning vs. execution), the right
provider (local vs. cloud), or the right sub-agent (specialist dispatch). In production,
routing is itself an architectural decision with cost and latency consequences.

Key production observations grounding this chapter:
- **§15**: `/ultraplan` does not run a bigger prompt locally. It calls `teleportToRemote`,
  launching a remote session on Opus, then polls for up to 30 minutes. Some slash commands
  are not local operations — they are orchestration commands that move the entire session
  context to a different compute surface. Routing can change the execution environment,
  not just the model.
- **§7**: Two users can have meaningfully different experiences while thinking they use
  the same product. Feature flags and rollout groups create different capability surfaces.
  This is routing applied to users: different code paths, different models, different
  feature sets — managed at the infrastructure level.
- **§4**: "Claude Code is heavily feature-flagged and environment-dependent." The
  `/doctor` command exists to inspect which routing decisions are active. Routing state
  is observable and inspectable — a production requirement.

What this tells us beyond v1: v1 covers routing as "send task A to model X, task B to
model Y." This chapter covers routing as infrastructure: surface routing (local vs. remote
compute), feature routing (flag-gated capabilities), and the principle that routing
decisions have first-class observability requirements.

---

## Part Two: Orchestration

### Ch 5 — Prompt Chaining
**Verdict: EARNS IT**

Chaining is the foundational orchestration pattern: output of step N feeds input of step
N+1, with gate functions between steps. The production insight is that chains should be
designed around *phases* that match how the runtime distinguishes different types of
work — not just sequential steps.

Key production observations grounding this chapter:
- **§2**: "Split large tasks into phases: gather context, propose a plan, make the change,
  verify. Mixing exploration, implementation, and validation into a single sprawling
  request fights the product instead of using it." The four-phase pattern (explore,
  plan, execute, verify) is not a user tip — it is a description of how the system's
  architecture divides work internally.
- **§6**: "Give clear goals, constraints, and stop conditions, but avoid over-constraining
  intermediate steps. Let long-running work settle instead of constantly interrupting."
  Gate functions between chain steps should operate on outcomes, not micromanage the
  intermediate process.
- **§8**: "A checkpointable workflow with explicit progress markers and a clear next step
  is robust. Tasks that survive interruption also tend to execute better on the first
  pass." Chain design and interruption resilience are not separate concerns. Well-designed
  chains are naturally recoverable.

What this tells us beyond v1: v1 covers chaining mechanics. This chapter's production
angle is the *phase alignment* insight: chains that align with the runtime's internal
distinction between read-heavy and mutation-heavy work outperform chains that don't.

---

### Ch 6 — Parallelization
**Verdict: STRONG**

Parallel execution in agent systems is not "run things at the same time." It is a
carefully scoped contract: which operations are safe to parallelize, how failure in one
branch affects siblings, and how to structure work so parallel agents share computation
rather than duplicate it.

Key production observations grounding this chapter:
- **§12**: "Only Bash errors trigger sibling cancellation. Failures from Read, WebFetch,
  and other tools explicitly do not." The cancellation model is asymmetric by design:
  environment failures (Bash) cascade, informational failures (file reads) don't.
  Understanding this asymmetry is the difference between building fragile and resilient
  parallel pipelines.
- **§22**: "It clones the parent's assistant message with a new UUID, uses an identical
  fixed placeholder for every tool_result, and varies only the final directive text... This
  is deliberate cache optimization: byte-identical prefixes across fork children maximize
  shared prompt cache hits." Fork parallelism is engineered around cache economics. The
  system pays for one prompt prefix and reuses it across all children.
- **§2**: "Claude Code is built for decomposition and staged execution... It distinguishes
  read-heavy operations (parallelizable) from mutation-heavy operations (serializable)."
  The rule is architectural: reads fan out, writes serialize. This is the fundamental
  constraint governing what can be parallelized.

What this tells us beyond v1: v1 covers parallelization at the workflow level. This
chapter covers the production constraints: asymmetric failure propagation, cache-aware
fork design, and the read/write rule that governs what is safe to parallelize.

---

### Ch 7 — Planning and Decomposition
**Verdict: STRONG**

Planning in production agent systems is not just "think before you act." It is a budget-
aware, interruption-safe, phase-gated process where the plan itself is a durable artifact,
not a transient thought.

Key production observations grounding this chapter:
- **§24**: "After three continuations, it tracks the delta of tokens consumed since the
  last check. If both the current and previous deltas are under 500 tokens, it stops —
  even if the 90% soft cap has not been reached." The system uses diminishing-returns
  detection, not just hard caps. Planning that doesn't make meaningful progress per turn
  gets cut off. Plans must be structured to produce real forward motion each turn.
- **§2**: "Worktrees extend this principle. When the risk is shared state rather than
  reasoning, a separate worktree beats a better prompt. For long-running work — cleanup,
  repo-wide checks — give the system a clear end condition and room to run." Decomposition
  is not just about task splitting — it is about isolating shared state risk.
- **§29**: Proactive mode has strict rules about not wasting turns. The model must call
  `Sleep` instead of producing "still waiting" messages — each wake-up is an API call and
  prompt cache expires after roughly five minutes of inactivity. Planning must respect
  the economic cost of each step.

What this tells us beyond v1: v1 covers plan-then-execute as a pattern. This chapter
adds the production layer: budget-aware planning, diminishing-returns detection as a stop
signal, and the isolation principle (separate state = separate plan).

---

### Ch 8 — Reflection and Self-Correction
**Verdict: EARNS IT**

Reflection — an agent evaluating and revising its own output — runs into a production
constraint that v1 doesn't address: reflection has a cost, and unconstrained reflection
becomes a sink for compute. Production systems need mechanisms to detect when reflection
is producing returns vs. spinning in place.

Key production observations grounding this chapter:
- **§24**: The diminishing-returns detector measures the delta of tokens consumed per
  continuation. If progress stalls (two consecutive deltas under 500 tokens), the system
  stops. This is automated detection of reflection-loop pathology — the system kills
  verification rabbit holes before they drain the budget.
- **§31**: "The extraction fork... has a hard cap of 5 turns to prevent verification
  rabbit holes." Even in the memory extraction sub-agent (a form of self-correction),
  there is an explicit turn cap. Reflection is bounded, not open-ended.
- **§17**: `codex-agentic-patterns` Ch 17 (turn-diff tracking) — tracking git-style diffs
  between turns gives reflection a concrete feedback signal: what changed, not just
  "did it get better?" Diff tracking converts the reflection loop from judgment-based to
  evidence-based.

What this tells us beyond v1: v1 covers reflection as "critique your output and revise."
This chapter adds the production constraint: when to stop reflecting, how to detect
diminishing returns, and how diff tracking gives reflection a concrete signal rather than
a subjective one.

---

## Part Three: State and Memory

### Ch 9 — Session Lifecycle
**Verdict: STRONG**

A session is not a conversation. A session is a stateful execution context with a boot
phase, an economic posture (cache configuration), a set of active latches, and a shutdown
sequence that runs background work. Understanding session lifecycle is prerequisite to
understanding everything in Parts 3 and 4.

Key production observations grounding this chapter:
- **§9**: "Several API headers are set once per session and frozen, even if you toggle the
  corresponding setting afterward." The latch pattern — state that is set once and
  intentionally not changeable mid-session — is a novel concept absent from v1. Latches
  exist to protect cache economics. The only resets are `/clear` and `/compact`.
- **§23**: Stop hooks run a parallel economy after every turn: cache snapshot, memory
  extraction, job classification, auto-dream, MCP cleanup. These are not cleanup routines
  — they are scheduled work with duration tracking. Session end is not when the user
  stops typing, it is when the stop hooks complete.
- **§8**: `/resume`, `/summary`, remote continuity, reconnect logic all point to the same
  design principle: the ideal session is one that can be paused, recovered, audited, and
  continued. Session state must be externalizable and resumable.

What this tells us beyond v1: v1 doesn't address session lifecycle at all — it assumes
sessions are stateless between turns. This chapter is entirely new: the boot-to-shutdown
lifecycle, latch patterns, stop hook economics, and resumability as a design requirement.

---

### Ch 10 — Memory Management
**Verdict: STRONG**

Memory in an agent runtime is not a database lookup. It is a multi-layer system with
distinct accumulation and consolidation phases, mutual exclusion between writers, and
explicit rollback mechanisms for failed consolidation runs.

Key production observations grounding this chapter:
- **§13**: "KAIROS replaces this with append-only daily log files... The complement is a
  Dream task: a background subagent (30 turns max) that reviews accumulated daily logs
  and distills them into topic files and a fresh MEMORY.md. If killed mid-run, a rollback
  mechanism reverts partial changes." The accumulate-then-distill pattern is a first-class
  architectural choice, not a UX feature. Append-only accumulation prevents partial-write
  corruption; the Dream task handles consolidation separately.
- **§31**: "If the main agent already wrote to auto-memory paths during the turn,
  extraction skips entirely and advances its cursor — preventing duplicate writes... It
  has a hard cap of 5 turns to prevent verification rabbit holes." Memory writing has
  mutual exclusion between the main agent and the extraction fork. Two agents can't both
  write memory for the same turn.
- **§7**: "Move it into CLAUDE.md, a slash command, a script, a permission rule, a test,
  or a skill. Chat is volatile; artifacts are stable." The human-facing lesson maps
  directly to the architecture: the memory system exists to externalize volatile session
  state into durable artifacts. This is not convenience — it is reliability engineering.

What this tells us beyond v1: v1 covers memory as "store and retrieve context." This
chapter covers the engineering: append-only vs. mutable strategies, the
accumulation/consolidation split, mutual exclusion between memory writers, and rollback.

---

### Ch 11 — Context Economics
**Verdict: STRONG**

Context is not a convenience concern. In production agent systems, context configuration
affects cache hit rates, API costs, session quality, and token budget allocation. Managing
context is a first-class engineering discipline.

Key production observations grounding this chapter:
- **§9**: Headers are latched once per session to protect prompt cache. Toggling a setting
  would bust 50,000–70,000 tokens of prompt cache. Context management is not about what
  the model "knows" — it is about the cost structure of the session.
- **§11**: "`/btw` lets you ask a quick side question without derailing the main
  conversation. At the end of every turn, a stop hook saves a CacheSafeParams snapshot.
  When `/btw` fires, it reuses that snapshot — a prompt-cache hit on the full prior
  conversation rather than context assembled from scratch." Cache snapshots are first-
  class objects, not implementation details. Context management strategies can be designed
  around them.
- **§22**: "Fork subagents share byte-identical prompt prefixes for cache hits. The fork
  agent keeps the Agent tool in its tool list even though it cannot use it, because
  removing it would change the tool definition block and bust the cache." The principle:
  byte-identical context = shared cache cost. Even tool definitions that aren't used are
  kept in the prompt to preserve the cache prefix. Context stability has economic value
  independent of semantic content.
- **§24**: Diminishing-returns detection stops execution when token consumption stalls.
  The budget system is measuring productivity-per-token, not just total tokens. Context
  economics includes input efficiency, not just size.

What this tells us beyond v1: v1 doesn't address context economics at all. This is
entirely new territory: cache stability as an engineering constraint, prompt prefix sharing
across parallel agents, and productivity-per-token measurement.

---

### Ch 12 — Knowledge Retrieval (RAG)
**Verdict: MERGE into Ch 20 (Extension and Integration)**

The source material (Claude Code architecture) is thin on RAG as a production pattern.
The strongest relevant observations are in §5 (extend the agent into real systems) and
the general integration theme. These fit more naturally in the Extension chapter, where
RAG is treated as one kind of external knowledge source an agent can be connected to —
alongside APIs, documentation systems, and internal tooling.

RAG as a standalone pattern is well-covered in v1 and in the general LLM literature.
Writing a full chapter here without novel production grounding would produce padding.

**Action**: Merge RAG concepts into Ch 19 (Extension and Integration). Final chapter
count drops from 21 to 19.

---

## Part Four: Safety

> Note: After merging Ch 12, Part Four renumbers to chapters 12–15.

### Ch 12 (was 13) — Permission Pipelines
**Verdict: STRONG**

Security in agent systems is not a blocklist. It is a layered pipeline shaped by real
vulnerability reports, runtime quirks, and bundler constraints. This is the most detailed
production security pattern in the entire book.

Key production observations grounding this chapter:
- **§21**: The Bash tool's permission system is eight layers: exact deny match (with env-
  var stripping), prefix deny/ask match, path constraints (added post-HackerOne report),
  exact allow short-circuit, prefix allow, sed constraint validation, mode check, read-only
  validation. Each layer has its own edge cases. This is defense-in-depth shaped by real
  attack surfaces, not a permission checklist.
- **§21**: "Env-var stripping uses fixed-point iteration because wrappers like `nice` and
  `env` can nest arbitrarily. HackerOne report #3543050 revealed that stripping env vars
  after wrappers could turn `VAR=val` into a command name." A permission system designed
  without real adversarial input misses this class of vulnerability entirely.
- **§21**: "A Bun bundler complexity budget constrains the permission function. If imports
  push it over Bun's per-function constant-folding limit, ternaries silently fold to
  `false`, dropping the speculative classifier." The permission system has constraints
  from the build toolchain — not just from the threat model. Production security has
  non-obvious dependencies.

What this tells us beyond v1: v1 doesn't cover permission systems. This chapter is
entirely new: the layered pipeline model, fixed-point env-var stripping, path constraints
from real vulnerability reports, and build-toolchain constraints on security code.

---

### Ch 13 (was 14) — Human-in-the-Loop
**Verdict: EARNS IT**

HITL in production is not just "add an approval step." It is a question of where to
place the human in the execution loop, how much context the human needs to make a
meaningful decision, and how to design the handoff so the human's decision is
actually respected by the system.

Key production observations grounding this chapter:
- **§6**: "Give clear goals, constraints, and stop conditions, but avoid over-constraining
  intermediate steps. Let long-running work settle instead of constantly interrupting. If
  you cancel something substantial, give the system a beat before stacking the next
  request." The human-in-the-loop design principle is: manage outcomes, not keystrokes.
  HITL that fires too frequently degrades both the human's attention and the system's
  ability to make progress.
- **§4**: "Frustrating behavior is often not about intelligence. It is about environment
  health, fallback behavior, feature gating, or routing." The human's intervention point
  should be the runtime state, not just the model output. Use `/doctor`, `/context`, and
  `/cost` to inspect the machine before intervening.
- **§2**: Plan mode as a forcing function: "Split large tasks into phases: gather context,
  propose a plan, make the change, verify." The plan review is the HITL checkpoint — and
  it is positioned *after* context gathering (so the human has enough information) and
  *before* mutations (so the human can redirect before damage).

What this tells us beyond v1: v1 covers HITL as approval workflows. This chapter adds
the production angle: where in the loop to place the human (after exploration, before
mutation), what the human should be reviewing (the plan + runtime state, not just the
output), and the cost of over-interrupting.

---

### Ch 14 (was 15) — Guardrails and Safety Patterns
**Verdict: EARNS IT**

Guardrails in production are not filter lists applied to inputs and outputs. They are
engineering properties designed into the system: rejection over truncation, runtime
construction of sensitive strings, and build-time canary detection that forces security
tooling to evolve.

Key production observations grounding this chapter:
- **§27**: "The `claude://` protocol handler enforces a 5,000-character query limit. When
  exceeded, it rejects the entire link rather than truncating — truncation 'changes
  meaning' and could be exploited." The reject-over-truncate principle is a production
  safety insight: partial information is more dangerous than no information when the
  partial form can be crafted by an attacker.
- **§30**: "The secret scanner assembles the Anthropic API key prefix at runtime using
  `['sk','ant','api'].join('-')` so the literal string never appears in the bundle." The
  build system's canary detection is so aggressive that the product's own security tooling
  must work around it. Defense-in-depth applied at the build pipeline level.
- **§14**: The companion system's "bones" (species, rarity, stats) are always re-derived
  from a hash of the user ID at runtime — not stored. "You cannot edit your config to get
  a legendary companion." This is anti-tamper by design: critical properties are computed,
  not stored, so they cannot be modified by editing configuration files.

What this tells us beyond v1: v1 covers guardrails as input/output filtering. This
chapter covers guardrails as system design properties: reject-over-truncate, computed-
not-stored for tamper resistance, and build-time canary detection.

---

### Ch 15 (was 16) — Sandboxing and Isolation
**Verdict: EARNS IT**

Sandboxing in production agent systems is not "run code in a container." It is a
defense-in-depth stack addressing specific threat models: prompt injection leading to heap
scraping, token exfiltration via debugger attachment, and TLS interception by MITM
proxies.

Key production observations grounding this chapter:
- **§19**: "The session token is read from `/run/ccr/session_token`, then
  `prctl(PR_SET_DUMPABLE, 0)` is called via Bun FFI to block same-UID ptrace. The
  explicit threat model is a prompt-injected `gdb -p $PPID` scraping the token from the
  heap." The sandbox's specific threat model (prompt injection -> debugger -> heap scrape)
  is not a generic security concern. It is a concern specific to LLM agents operating
  with ambient authority.
- **§19**: "After the relay starts, the token file is unlinked. The token exists only in
  process memory." Fail-open design at every step: the token file is unlinked *after*
  relay confirmation so a supervisor can retry if startup fails. Security never blocks
  work.
- **§19**: The relay "tunnels CONNECT over WebSocket (GKE L7 has no raw CONNECT
  matcher), uses hand-rolled protobuf encoding for a single-field message to avoid a
  dependency, dual auth layers." Production sandboxing has infrastructure constraints
  (load balancer limitations, proxy behavior) that shape the implementation.

What this tells us beyond v1: v1 doesn't cover sandboxing. This chapter is new: the
LLM-specific threat model (prompt injection -> ambient authority abuse), heap-only token
patterns, fail-open security design, and infrastructure constraints on sandbox
implementation.

---

## Part Five: Production

> Note: After merging Ch 18 into Ch 17, and absorbing Ch 12 (RAG) into Ch 19,
> Part Five runs chapters 16–19.

### Ch 16 (was 17+18) — Multi-Agent Coordination
**Verdict: STRONG — absorbs Inter-Agent Communication**

Coordinator/worker systems are the core multi-agent pattern. The communication mechanism
*is* the coordination mechanism — they cannot be meaningfully separated at book length
without padding one of them.

Key production observations grounding this chapter:
- **§10**: "Worker results do not arrive through function calls or IPC. They arrive as
  user-role conversation messages containing `<task-notification>` XML with fields for
  task ID, status, summary, result, and usage." The model is the protocol layer. Multi-
  agent coordination flows through the conversational channel the model already
  understands. This is a paradigm-shifting insight: you don't need a separate message bus.
- **§22**: "It clones the parent's assistant message with a new UUID, uses an identical
  fixed placeholder for every tool_result, and varies only the final directive text. Byte-
  identical prefixes across fork children maximize shared prompt cache hits." Fork
  parallelism is engineered around cache economics. One prompt prefix, N worker agents.
- **§28**: "Teammates are told in their system prompt that plain text is invisible to the
  team — only `SendMessage` reaches other agents." Communication in multi-agent systems
  requires explicit channels. Implicit side effects (like printing to stdout) don't
  propagate. The protocol must be designed, not assumed. And: "Cron tasks reject durable
  scheduling for teammates because agent IDs do not survive restart." Bounded coordination
  — agents cannot make commitments that outlive their session.

What this tells us beyond v1: v1 covers multi-agent systems as a topology (coordinator,
worker, peer). This chapter covers the implementation: conversation-as-protocol, cache-
aware fork design, bounded coordination, and why session scope constrains what multi-
agent systems can commit to.

---

### Ch 17 (was 19) — Observability and Evaluation
**Verdict: STRONG**

Observability in agent systems is not logging. It is a structured economy of post-turn
work: cache snapshots, memory extraction, job classification, analytics routing, and PII
management — all running in parallel after every turn, with their own timeout and
failure semantics.

Key production observations grounding this chapter:
- **§23**: "At the end of every turn, a set of stop hooks fires... `saveCacheSafeParams`
  snapshots conversation state for `/btw` and SDK side questions. Memory extraction forks
  a separate agent (max 5 turns). A job classifier (60-second timeout, `.unref()`'d so it
  cannot block process exit) categorizes the session for the timeline UI. Auto-dream
  checks whether enough sessions have accumulated to trigger memory consolidation." Five
  distinct post-turn processes, each with its own lifecycle and error handling.
- **§25**: "A GrowthBook config key named `tengu_frond_boric` (deliberately obfuscated)
  can kill individual sinks — Datadog or first-party — at runtime... Events carry type-
  level markers distinguishing 'verified not sensitive' from 'verified PII for proto
  column.' A single `stripProtoFields` function removes all `_PROTO_*` keys before events
  reach general-access backends." PII management in the analytics pipeline is enforced
  at the type system level, not just policy.
- **§4**: "Use `/doctor`, `/context`, and `/cost` to inspect the machine around the task
  before rewriting the request." Observability is not just for engineers — it is a
  first-class user capability. The inspection tools expose runtime state so users can
  debug behavior, not just observe outputs.

What this tells us beyond v1: v1 covers evaluation as test suites and benchmarks. This
chapter covers production observability: post-turn hook economies, PII-typed analytics
pipelines, and inspection-first debugging patterns.

---

### Ch 18 (was 20) — Extension and Integration
**Verdict: EARNS IT — absorbs Knowledge Retrieval (RAG)**

An agent runtime becomes an integration platform when it exposes clean extension points
for external systems, domain-specific capabilities, and knowledge sources. The extension
architecture determines how much of the agent's capability is fixed vs. composable.

Key production observations grounding this chapter:
- **§18**: The `moreright` directory contains a single no-op stub. "In Anthropic's
  internal build, this hook can block or transform queries and render visible UI. The
  interface shape — it receives `setMessages`, `inputValue`, `setInputValue`,
  `setToolJSX` — hints at pre-query input transformation or side-panel capability." The
  public/internal extension split reveals the principle: extension points should be
  designed as first-class architecture, with public no-ops for external users and full
  implementations internally. This prevents the extension point from being added as an
  afterthought.
- **§5**: "Claude Code becomes more valuable as it sees more of the systems that matter.
  MCP, skills, plugins, and LSP integrations exist because the product is meant to be
  connected to real tooling, not kept in a sealed prompt box." Extension is not a feature
  — it is a design principle. The question shifts from "what should the agent do?" to
  "what should the agent be able to reach?"
- **RAG as a sub-pattern**: Knowledge retrieval (RAG) is one kind of integration:
  connecting the agent to a vector index or document store as a tool. The same extension
  architecture that enables MCP tool connections enables retrieval-augmented generation.
  RAG earns a section within this chapter, not a standalone chapter.

What this tells us beyond v1: v1 covers MCP and tool integrations. This chapter adds the
extension architecture perspective: public stub / internal implementation patterns, the
"what can the agent reach" framing, and RAG as an integration pattern rather than a
standalone retrieval system.

---

### Ch 19 (was 21) — Operating an Agent Runtime
**Verdict: STRONG — synthesizing final chapter**

This is the culminating chapter, synthesizing the entire book into the central argument:
effective use of an agent system is environment engineering, not prompt engineering. The
agent is infrastructure. You operate it the way you operate a distributed system.

Key production observations grounding this chapter:
- **§32**: "The bridge has two coexisting transport versions. V2 fixed a subtle bug:
  events were left at `received` status forever in daemon paths, causing phantom re-queued
  prompts after restarts." Production agent runtimes evolve their protocols over time, and
  versioning those protocols is a first-class concern. Operating a runtime means
  understanding its transport layer, not just its model.
- **§16**: "The directory name suggests Node native bindings. It contains the exact
  opposite: pure TypeScript ports replacing former Rust and C++ dependencies." The
  implementation of a runtime is not its interface. Operating a runtime means understanding
  the gap between what it looks like and what it is — especially when dependencies change
  silently.
- **§1/§8 thesis**: "The best users treat Claude Code as an operating environment for
  software work. They shape context, tools, permissions, memory, verification, and
  integrations so the model can act well inside a well-designed system." The shift from
  "what should I prompt?" to "what operating environment would make success the default?"
  is the central argument of the entire book.

What this tells us beyond v1: v1 doesn't have a synthesizing "how to operate this in
production" chapter. This chapter is the payoff: bringing together session lifecycle,
context economics, permission pipelines, extension architecture, and multi-agent
coordination into a coherent operating model.

---

## Final Chapter Structure

After applying merges and cuts:

| # | Chapter | Verdict | Source Sections |
|---|---------|---------|----------------|
| 1 | The Agent Loop | EARNS IT | §1, §2, §10 |
| 2 | Prompt Assembly | STRONG | §1, §9, §10 |
| 3 | Tool Use | STRONG | §12, §22, §2 |
| 4 | Routing | EARNS IT | §15, §7, §4 |
| 5 | Prompt Chaining | EARNS IT | §2, §6, §8 |
| 6 | Parallelization | STRONG | §12, §22, §2 |
| 7 | Planning and Decomposition | STRONG | §24, §2, §29 |
| 8 | Reflection and Self-Correction | EARNS IT | §24, §31, codex-17 |
| 9 | Session Lifecycle | STRONG | §9, §23, §8 |
| 10 | Memory Management | STRONG | §13, §31, §7 |
| 11 | Context Economics | STRONG | §9, §11, §22, §24 |
| ~~12~~ | ~~Knowledge Retrieval~~ | **MERGED -> Ch 18** | — |
| 12 | Permission Pipelines | STRONG | §21 ×3 |
| 13 | Human-in-the-Loop | EARNS IT | §6, §4, §2 |
| 14 | Guardrails and Safety | EARNS IT | §27, §30, §14 |
| 15 | Sandboxing and Isolation | EARNS IT | §19 ×3 |
| ~~18~~ | ~~Inter-Agent Communication~~ | **MERGED -> Ch 16** | — |
| 16 | Multi-Agent Coordination | STRONG | §10, §22, §28 |
| 17 | Observability and Evaluation | STRONG | §23, §25, §4 |
| 18 | Extension and Integration | EARNS IT | §18, §5, RAG |
| 19 | Operating an Agent Runtime | STRONG | §32, §16, §1/§8 |

**Final count: 19 chapters.**

Chapters marked STRONG: 11 of 19. These are the load-bearing chapters. Each one
introduces multiple genuinely novel production patterns absent from v1.

Chapters marked EARNS IT: 8 of 19. These contain at least one production insight not in
v1, though some overlap with well-covered v1 territory.

No chapters that needed to be cut entirely (the two merges absorbed content cleanly
rather than discarding it).

---

## What This Book Adds That V1 Doesn't Cover

To be explicit about the value proposition:

**Entirely new chapters (not in v1 at all):**
- Ch 9: Session Lifecycle (boot, latch, stop hooks, resumability)
- Ch 11: Context Economics (cache stability, prefix sharing, diminishing returns)
- Ch 12: Permission Pipelines (eight-layer security, HackerOne-shaped design)
- Ch 15: Sandboxing and Isolation (LLM-specific threat model, heap-only tokens)

**Substantially upgraded from v1:**
- Ch 2: Prompt Assembly (layered assembly, cache implications — not just "write good prompts")
- Ch 3: Tool Use (failure semantics, tool pool as cache surface)
- Ch 7: Planning (budget-aware, diminishing-returns stop signal)
- Ch 10: Memory (accumulate-then-distill, mutual exclusion, rollback)
- Ch 16: Multi-Agent (model-as-protocol, cache-aware fork, bounded coordination)
- Ch 17: Observability (stop-hook economy, PII-typed analytics)
- Ch 19: Operating an Agent Runtime (the synthesizing chapter v1 is missing)
