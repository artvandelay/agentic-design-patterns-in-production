# Chapter 17: Observability and Evaluation

## The Pattern

Observability in agent systems is not logging. It is a structured economy of post-turn work — cache snapshots, memory extraction, job classification, analytics routing, and PII management — all running in parallel after every turn, with their own timeouts and failure semantics. Evaluation is not a test suite run after deployment. It is inspection built into the runtime so users and operators can debug behavior in real time.

## The Problem

Without structured observability, agent behavior is a black box. The user sees inputs and outputs but not:

- Why a turn was expensive (cache miss? large context? reflection loop?)
- What the agent classified the session as (bug fix? feature? refactor?)
- Whether memory extraction ran or was skipped
- Whether the analytics pipeline is healthy or silently dropping events

And without evaluation built into the runtime, debugging means re-running the session and hoping the problem reproduces. Production agents need inspection tools that expose runtime state *during* the session, not just post-mortem.

## How It Works

### The Stop Hook Economy

At the end of every turn, a set of stop hooks fires in parallel (introduced in Ch 9). These are not cleanup routines — they are a parallel economy with distinct processes:

- **Cache snapshot**: Saves conversation state so side-channel operations reuse the cached prefix. Main-thread only — sub-agents must not overwrite the coordinator's snapshot.
- **Memory extraction**: Forks a separate agent (bounded to ~5 turns) to distill the conversation into persistent memory. Skips if the main agent already wrote memory during the turn (Ch 10).
- **Job classification**: Categorizes the session (bug fix, feature, refactor, exploration) for the timeline UI. Runs with a 60-second timeout and is detached from the process — it cannot block shutdown.
- **Consolidation check**: Determines whether enough sessions have accumulated to trigger the Dream task (Ch 10).
- **Resource cleanup**: Process-wide locks and connection handles are released. Runs only on the main thread because these resources are process-scoped.

Each hook has its own failure mode. The classifier timing out does not affect memory extraction. A failed cache snapshot does not block cleanup. The hooks are independent, parallel, and designed so that one failure does not cascade.

In scripted or forked sessions, most hooks are skipped. Sub-agents should not fight shutdown or compete for process-wide resources.

### The Analytics Pipeline

Agent analytics is not `console.log`. Production pipelines have three properties that distinguish them from application logging:

**PII typing at the type system level.** Events carry compile-time markers distinguishing "verified not sensitive" from "verified PII for privileged storage." A single stripping function removes all PII-marked fields before events reach general-access backends (like Datadog), while preserving them for privileged backends (like restricted BigQuery columns). This is enforced by the type system, not by policy — a developer cannot accidentally send a PII field to a general backend because the types prevent it.

**Runtime killswitches.** Individual analytics sinks can be disabled at runtime through a configuration flag — deliberately obfuscated to prevent accidental toggling. The killswitch has a recursion guard because the configuration system's own health-check would otherwise call back into the analytics pipeline, creating an infinite loop.

**Queue-then-attach initialization.** Analytics events can fire before the pipeline is fully initialized. Events are queued and attached to sinks once initialization completes. This avoids circular import dependencies between the analytics system and the systems it observes.

### Inspection-First Debugging

Production agent runtimes expose inspection tools as first-class user capabilities, not just operator dashboards:

- **Environment health**: Diagnose whether tools are working, connections are stable, and the runtime is in a healthy state. This catches problems that look like model failures but are actually environment failures — wrong model routed due to a fallback, stale context from failed compaction, broken tool that will fail during execution.
- **Context inspection**: See what the model's actual context contains — which memory layers are active, what project instructions are loaded, how large the conversation is.
- **Cost inspection**: See the session's token consumption, cache hit rate, and estimated cost. This surfaces whether the session's economic posture is healthy or degraded.

The design principle: **inspect the machine before you reprompt.** When quality drops, the cause is more often environmental (feature gating, routing fallback, degraded cache) than intellectual (the model doesn't understand the task). Inspection tools let users distinguish between these causes.

### Evaluation in Production

Evaluation is not a separate phase. It is embedded in the runtime:

- **Diminishing-returns detection** (Ch 11) is continuous evaluation of productivity per token.
- **Job classification** is evaluation of what kind of work the session performed.
- **Memory extraction** is evaluation of what was worth remembering.
- **Stop hook duration tracking** is evaluation of the runtime's own overhead.

Each of these produces signals that can be aggregated across sessions to understand system-level behavior: which task types consume the most tokens, which sessions trigger the most reflection loops, which configurations produce the best cache hit rates.

## Production Considerations

**Stop hooks are load-bearing infrastructure.** They are not optional cleanup. Cache snapshots, memory extraction, and classification all depend on hooks completing. Abrupt process termination skips them, leaving state inconsistent.

**PII management is a type-system problem.** Policy-based PII controls ("don't log sensitive fields") fail at scale. Type-level enforcement prevents the mistake at compile time.

**Expose inspection to users.** Operators are not the only audience for observability. Users who can inspect runtime state debug their own problems faster and file better bug reports.

**Track post-turn overhead.** Stop hooks have real cost. Monitor their duration and failure rates. A classifier that consistently times out is wasting 60 seconds of compute per turn.

## Composability

- **Session Lifecycle** (Ch 9): Stop hooks are the observability mechanism. Session lifecycle determines when they fire and what they can access.
- **Memory Management** (Ch 10): Memory extraction is both a memory operation and an observability signal — it records what the system deemed worth remembering.
- **Context Economics** (Ch 11): Cost inspection and diminishing-returns detection are observability applied to the economic layer.
- **Reflection** (Ch 8): Reflection loops should be observable — how many iterations, what triggered each revision, when diminishing returns were detected.
- **Operating an Agent Runtime** (Ch 19): Observability data feeds the operating model. You cannot operate what you cannot observe.

## Common Mistakes

**Logging instead of structured observability.** Unstructured log lines that cannot be queried, aggregated, or typed for PII sensitivity.

**Blocking shutdown on observability.** Analytics or classification that can hold the process open. Detach non-critical hooks so they cannot block exit.

**No user-facing inspection.** Observability only for operators, not users. Users who cannot inspect runtime state blame the model for environmental problems.

**Ignoring stop hook failures.** Treating hook failures as silent no-ops. A consistently failing memory extraction hook means the system is not learning from sessions.
