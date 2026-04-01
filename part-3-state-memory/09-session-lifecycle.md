# Chapter 9: Session Lifecycle

## The Pattern

A session is not a conversation. A session is a stateful execution context with a boot phase that assembles configuration, a run phase governed by economic constraints, and a shutdown sequence that runs background work. Understanding the lifecycle — boot, run, interrupt, resume, compact, clear — is prerequisite to understanding memory, context economics, and everything in Parts Four and Five.

## The Problem

Without a session model, each turn is independent. The system builds a prompt from scratch, calls the model, returns a response, and discards everything except the conversation transcript. This works for single-turn interactions but fails for sustained work:

- Configuration decisions made on turn one (which model, which cache strategy, which permission mode) must be re-evaluated every turn — or worse, silently drift mid-session.
- There is no mechanism to run post-turn work: saving cache snapshots, extracting memories, classifying the session for analytics.
- Interruption is catastrophic. If the process dies mid-turn, there is nothing to resume from. The user starts over.
- Cost is unpredictable because there is no concept of session-level economic posture — every turn pays full price for prompt assembly.

A session model solves these by making the execution context explicit and persistent across turns.

## How It Works

### Boot

When a session starts, the runtime assembles its initial state:

1. **Prompt assembly**: System prompt layers are gathered from project instructions, user memory, team memory, extracted memories, and tool definitions (Ch 2). This assembled prompt becomes the cache-stable prefix for the session.
2. **Configuration latching**: Certain settings are evaluated once and frozen for the session's lifetime. These are called **latches**. A latch is intentionally not changeable mid-session — toggling it would invalidate the prompt cache.
3. **Economic posture**: The cache TTL eligibility, token budget parameters, and billing configuration are set. These determine how much the session will cost per turn and how aggressively the runtime preserves cache hits.
4. **Tool pool binding**: The available tools are determined and their definitions are included in the prompt prefix. Changing the tool pool mid-session is expensive because tool definitions are part of the cache key (Ch 3).

Boot is not a formality. It establishes constraints that govern every subsequent turn. A session that boots with the wrong configuration pays the cost on every turn — either in degraded cache performance or in misconfigured behavior that compounds.

### Latches

A latch is a piece of session state that is set once and cannot be changed without resetting the session. The concept exists to protect cache economics.

Consider a setting that affects the prompt prefix — say, whether the system should use an extended context mode. If this setting is toggled mid-session, the new prefix differs from the cached one. The cache — potentially 50,000 to 70,000 tokens of prompt — is invalidated. The next turn pays full price for a prefix that was previously amortized.

Latches prevent this by design. The value is read at boot, frozen, and used for every subsequent API call. The user can toggle the setting in the UI, but the running session ignores the change.

The only operations that reset all latches are a full session clear and compaction. These are not cleanup commands — they are session reboot operations. After a clear or compact, the runtime re-evaluates all latched values from their current sources.

### Run Phase

During the run phase, the session processes turns through the agent loop (Ch 1). Each turn:

1. Assembles messages (conversation history plus any new input)
2. Calls the model with the session's cached prefix
3. Executes tool calls within the session's permission and budget constraints
4. Feeds results back for the next iteration

The session maintains state between turns: the conversation history, the cache snapshot, the latch values, and any accumulated metadata (token usage, turn count, session classification).

### Stop Hooks

When a turn completes, the session does not simply idle. A set of **stop hooks** fires in parallel:

- **Cache snapshot**: The conversation state is saved so that side-channel operations (like quick follow-up questions) can reuse the cached prefix without reassembling it.
- **Memory extraction**: A separate agent (bounded to a small number of turns) distills the conversation into persistent memory entries. This runs only if the main agent didn't already write to memory during the turn.
- **Session classification**: A classifier categorizes what kind of work the session performed (bug fix, feature, refactor, etc.) for analytics and timeline display. This runs with a timeout and is detached from the process — it cannot block session shutdown.
- **Consolidation check**: The system checks whether enough sessions have accumulated to trigger memory consolidation (the "Dream" process described in Ch 10).

These hooks have their own lifecycle constraints. They run in parallel with duration tracking. In scripted or forked sessions, most hooks are skipped — sub-agents should not fight shutdown. The hooks are a parallel economy of post-turn work, and their existence is why abrupt cancellation can leave state inconsistent.

### Interrupt and Resume

Sessions are designed to survive interruption. The mechanisms:

- **Resumption**: A session that was interrupted can be resumed from its last stable state. The conversation history, accumulated context, and session metadata are recoverable. The runtime can rebuild the prompt prefix and continue from where the interruption occurred.
- **Summary generation**: At session end, the system can generate a summary that captures enough context for a future session to pick up the work. This is not a transcript — it is a compressed representation of the work state, intended for cold-start recovery.
- **Reconnection**: For sessions bridging an IDE to a CLI (through a transport layer), the connection can drop and reconnect without losing session state. The transport handles epoch management and event delivery guarantees (Ch 19).

The design principle: the ideal session can be paused, recovered, audited, and continued. Work that depends on an unbroken session is fragile by construction.

### Compact

Compaction is a mid-session reset. It compresses the conversation history, re-evaluates all latched values, and rebuilds the prompt prefix. After compaction:

- The conversation is shorter (reducing per-turn cost)
- Latches are re-read from current values (the session's economic posture may change)
- The cache prefix is rebuilt (previous cache is invalidated, but the new prefix starts accumulating hits)

Compaction is not a panic button. It is a deliberate transition between session phases. Use it when the conversation has grown long enough that per-turn cost is climbing, or when a configuration change needs to take effect.

## Production Considerations

**Session boot is load-bearing.** A misconfigured boot — wrong model, wrong cache TTL, wrong tool pool — compounds across every turn. Invest in getting boot right rather than correcting mid-session.

**Latches are features, not bugs.** When a setting change doesn't seem to take effect, the likely explanation is that it was latched at boot. Compact or clear to re-evaluate.

**Stop hooks have real cost.** Post-turn work (memory extraction, classification, consolidation checks) consumes compute. In high-throughput scripted usage, consider bare-mode sessions that skip hooks.

**Design for interruption.** If your workflow assumes the session will complete without interruption, it is fragile. Checkpointing, summary generation, and resumable task structure are not luxuries — they are reliability requirements.

## Composability

- **Prompt Assembly** (Ch 2): The session's boot phase is where prompt assembly happens. Latches protect the assembled prompt's cache stability.
- **The Agent Loop** (Ch 1): The run phase is the agent loop operating within the session's constraints.
- **Memory Management** (Ch 10): Stop hooks drive memory extraction. The session lifecycle determines when and how memory is written.
- **Context Economics** (Ch 11): Latches, cache snapshots, and compaction are all mechanisms for managing the economic cost of context.
- **Human-in-the-Loop** (Ch 13): Session resumability is what makes human review practical — the human can leave and return without losing the work state.

## Common Mistakes

**Ignoring boot configuration.** Starting a session without reviewing project instructions, memory state, and permission configuration leads to a session that fights its own defaults for every turn.

**Fighting latches.** Toggling settings mid-session and being confused when nothing changes. The system is protecting the cache. Compact if you need the change to take effect.

**Skipping compaction.** Running a 200-turn session without compacting. Per-turn cost climbs with conversation length. Compaction resets this, but only if used before the session becomes unwieldy.

**Abrupt cancellation.** Killing the process mid-turn leaves stop hooks unfinished — cache snapshots unsaved, memory extraction incomplete, classification skipped. Let turns complete cleanly when possible.
