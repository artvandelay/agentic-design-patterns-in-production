# Chapter 10: Memory Management

## The Pattern

Memory in an agent runtime is a multi-layer system with distinct phases: **accumulation** (recording what happened) and **consolidation** (distilling what matters). These phases have different writers, different failure modes, and different timing. The production challenge is not storing memories — it is coordinating who writes, when they write, and what happens when a write fails mid-way.

## The Problem

The naive approach to memory is a single mutable document that the agent updates in place. After each session, the agent rewrites its memory file to reflect what it learned. This breaks in three ways:

- **Partial writes corrupt state.** If the agent is interrupted while rewriting the memory file, the result is a half-updated document — worse than no update at all.
- **Concurrent writers conflict.** When a main agent and a background process both try to update memory for the same turn, one overwrites the other. The result is lost information, duplicated entries, or inconsistent state.
- **Signal degrades over time.** A living document that is continuously edited accumulates noise. Important early decisions get buried under recent trivia. The agent has no mechanism for distinguishing what to keep from what to forget.

These are not theoretical problems. They are the failure modes that drove production systems from mutable memory files to an accumulate-then-consolidate architecture.

## How It Works

### Accumulation: Append-Only Logs

The accumulation phase is deliberately simple: append new observations to a daily log file. No editing, no rewriting, no deduplication. Each session's learnings are appended with a timestamp. The log grows monotonically.

This design has two properties that matter:

1. **Crash safety.** An interrupted append leaves a log with all previous entries intact plus a potentially truncated final entry. The worst case is losing the last observation. Compare this to an interrupted rewrite, which can corrupt the entire file.

2. **No coordination required.** Multiple sessions can append to the log without conflict. Append is naturally atomic at the file-system level. There is no risk of one writer stomping another's changes.

The daily log boundary (one file per day) keeps individual files manageable and provides a natural unit for the consolidation phase to process.

A subtle detail: the date boundary comes from a metadata attachment rather than being embedded in the prompt text. This keeps the prompt prefix byte-stable across midnight, preserving cache hits for sessions that span the date change.

### Consolidation: The Dream Task

Accumulation without consolidation produces a growing pile of daily logs that eventually becomes too large to include in the prompt. The consolidation phase — called the "Dream" task — is a background sub-agent that reviews accumulated logs and distills them into structured memory.

The Dream task:

1. Reads all daily logs since the last consolidation
2. Identifies themes, decisions, and recurring patterns
3. Produces topic-organized memory files and a fresh summary document
4. Replaces the old summary with the new one

The Dream task is bounded (a hard turn cap prevents it from running indefinitely) and has a **rollback mechanism**: if it is killed mid-run, partial changes are reverted. This is critical because the consolidation phase is rewriting the very files that the system depends on for context. A half-finished consolidation is worse than no consolidation.

The trigger for consolidation is session count, not time. The system checks whether enough sessions have accumulated since the last Dream run. This prevents consolidation from running when there is nothing meaningful to consolidate, and ensures it runs when there is.

### Mutual Exclusion Between Writers

Two agents can write memory: the **main agent** (during a turn, in response to explicit user instructions or its own judgment) and the **extraction fork** (a background agent that runs as a stop hook after each turn to distill memories from the conversation).

These writers have explicit mutual exclusion:

- If the main agent wrote to memory paths during the turn, the extraction fork **skips entirely** and advances its cursor past that turn. It does not attempt to extract memories that the main agent already handled.
- Only one extraction fork runs at a time. If a new extraction is triggered while a previous one is still running, the calls coalesce — the running extraction continues, and the new one picks up whatever context accumulated in the meantime.

Without this coordination, the system would produce duplicate entries (both writers extracting the same insight) or conflicts (both writers updating the same file with different content).

### The Extraction Fork

The extraction fork deserves specific attention because it is where most automatic memory creation happens. After each turn, the stop hook system (Ch 9) launches a separate agent with the sole task of reviewing the conversation and writing any memories worth preserving.

Key constraints on the extraction fork:

- **Same tool list and cache key as the main agent.** Changing the tool list would break cache sharing, increasing cost.
- **Hard turn cap** (e.g., 5 turns). This prevents the extraction agent from entering a verification loop — endlessly refining its memory entries.
- **Shutdown safety.** The extraction fork races its in-flight work against an unref'd timeout. It cannot block process exit. If the process shuts down, the extraction fork dies silently rather than holding the session open.

This is why memory sometimes updates immediately (the main agent wrote it during the turn) and sometimes appears after a brief delay (the extraction fork ran as a stop hook). Both paths produce the same kind of output; the timing and trigger differ.

### From Volatile to Durable

The broader design principle: anything that matters for more than one turn should not live only in the conversation. Chat is volatile. Memory files, project instructions, test suites, scripts, and configuration are durable.

The memory system exists to automate this externalization. The extraction fork converts volatile conversation content into durable memory entries. The Dream task consolidates those entries into structured, maintainable knowledge. The user can also do this manually — moving an important decision into project instructions rather than relying on memory extraction to capture it.

The hierarchy of durability, from most volatile to most stable:

1. Current conversation (gone when the session ends)
2. Extracted memories (persist across sessions, subject to consolidation)
3. Project instructions (persist indefinitely, manually maintained)
4. Tests and scripts (executable, version-controlled, highest durability)

## Production Considerations

**Append-only accumulation is safer than mutable memory.** If your memory system rewrites files in place, every write is a potential corruption event. Append-only logs with separate consolidation are more crash-safe and require less coordination.

**Bound the consolidation process.** The Dream task has a turn cap for a reason. Unbounded consolidation can enter a polishing loop, endlessly refining memory files. Set a hard ceiling on consolidation turns.

**Mutual exclusion is not optional.** If two processes can both write memory, they need explicit coordination. The simplest mechanism: if one writer acted, the other skips. Without this, duplicate and conflicting entries are inevitable.

**Rollback on failed consolidation.** If the consolidation process dies mid-run, partial results must be reverted. A half-consolidated memory file — some topics updated, some stale — is harder to reason about than a fully stale one.

## Composability

- **Session Lifecycle** (Ch 9): Memory extraction runs as a stop hook. The session lifecycle determines when extraction fires and how it interacts with shutdown.
- **Context Economics** (Ch 11): Memory files become part of the prompt prefix. Their size directly affects cache economics and per-turn cost.
- **Prompt Assembly** (Ch 2): Extracted memories are one layer of the assembled prompt. The memory system feeds the prompt assembly pipeline.
- **Reflection** (Ch 8): The extraction fork is a form of automated reflection — the system reviewing its own conversation and deciding what to preserve. The turn cap prevents the same pathology as unbounded reflection.
- **Multi-Agent Coordination** (Ch 16): In multi-agent settings, memory systems that expect a single shared document (like team memory sync) are mutually exclusive with accumulate-then-consolidate systems. The coordination model must be chosen at the architecture level.

## Common Mistakes

**Mutable memory without crash safety.** Rewriting a memory file in place without atomicity guarantees. If the process dies mid-write, the file is corrupt.

**No mutual exclusion.** Letting the main agent and background processes both write memory without coordination. The result is duplicates, conflicts, or lost entries.

**Unbounded consolidation.** Running the Dream task without a turn cap. The consolidation agent can enter a verification loop, endlessly refining topic files.

**Relying on memory for critical context.** Memory extraction is best-effort. If a decision is critical, it should be in project instructions or code — not dependent on the extraction fork having run successfully.

**Never consolidating.** Letting daily logs accumulate indefinitely without running consolidation. The logs grow too large to include in the prompt, and the system loses access to its own accumulated knowledge.
