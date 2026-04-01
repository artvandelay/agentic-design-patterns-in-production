# Chapter 5: Prompt Chaining

## The Pattern

Chaining sequences multiple agent-loop iterations where the output of step N feeds the input of step N+1, with a gate function between steps that decides whether to proceed, retry, or abort. It is the simplest orchestration pattern: a pipeline.

The production insight is that effective chains are not arbitrary sequences of steps. They are organized around **phases** that match how the runtime distinguishes types of work: explore, plan, execute, verify.

## The Problem

Without explicit phases, complex requests become monolithic prompts. The user asks for a change that requires understanding context, making a plan, editing files, and running tests — all in one instruction. The model attempts all four concurrently within a single reasoning pass, which produces:

- Edits based on incomplete understanding (exploration was skipped or shallow)
- No reviewable plan (the user sees results, not reasoning)
- Verification mixed into the same turn as mutation (no clean baseline)
- No recovery point if something goes wrong partway through

Phase-aligned chains solve this by making each phase an explicit step with a gate between them.

## How It Works

### The Four-Phase Chain

Most agent work follows a natural four-phase structure:

```
Explore ──► Plan ──► Execute ──► Verify
   │           │          │          │
   └── gate ───┘── gate ──┘── gate ──┘
```

**Explore**: Read files, search the codebase, gather context. Read-only operations. Safe to parallelize (Ch 6). The output is understanding, not artifacts.

**Plan**: Propose a course of action based on what was found. The output is a reviewable plan — a durable artifact the user (or the system) can approve, modify, or reject before any mutation occurs.

**Execute**: Make changes, run commands, create artifacts. Write operations. Must be serialized where they affect the same state (Ch 1). The plan constrains what happens here.

**Verify**: Run tests, check outputs, compare against expectations. Read-only again. Confirms the execute phase produced correct results.

This structure aligns with how production runtimes handle work internally. Read-heavy phases (explore, verify) can fan out. Write-heavy phases (execute) must serialize. The plan phase is the human-in-the-loop checkpoint (Ch 13). Mixing these phases into a single undifferentiated request fights the architecture rather than using it.

### Gate Functions

Gates sit between phases and decide whether to proceed. A gate can:

- **Pass**: The previous phase succeeded. Move to the next phase.
- **Retry**: The previous phase produced insufficient results. Run it again, possibly with different parameters.
- **Abort**: A precondition failed. Stop the chain and report why.
- **Redirect**: The output suggests a different path. Modify the remaining chain.

The production constraint on gates: **gate on outcomes, not intermediate steps.** A gate that checks "did the explore phase find the relevant files?" is useful. A gate that checks every individual file read within the explore phase is micromanagement that prevents the agent from adapting its search strategy.

### Chain Design and Interruption Resilience

Well-designed chains are naturally recoverable. Each phase produces an explicit output (gathered context, a plan document, a set of changes, a test report). If the chain is interrupted at any phase, the work completed so far is a usable artifact, and the chain can be resumed from the last completed phase rather than restarted from scratch.

This is not a separate concern from chain design — it is the same concern. A chain with explicit progress markers and phase boundaries is both more robust to interruption and more effective on the first pass, because each phase starts with a clear, bounded objective.

## Production Considerations

**Chains that cross the read/write boundary should have an explicit gate.** The transition from exploration to execution is the highest-risk point. Gating on a reviewable plan at this boundary catches errors when they are cheapest to fix.

**Long chains should checkpoint.** If a chain has more than three or four phases, intermediate outputs should be saved as artifacts (not just held in context). This enables resumption after interruption and provides an audit trail.

**Chain phases should align with tool pool boundaries.** If the explore phase needs only read tools and the execute phase needs write tools, consider running them as separate agents with scoped tool pools (Ch 3) rather than one agent that switches modes.

## Composability

- **The Agent Loop** (Ch 1): Each phase of a chain is one or more iterations of the agent loop.
- **Parallelization** (Ch 6): Read-only phases (explore, verify) can fan out in parallel. Write phases serialize.
- **Planning** (Ch 7): The plan phase of a chain is the planning pattern applied within a chaining context.
- **Human-in-the-Loop** (Ch 13): The gate between plan and execute is the natural HITL checkpoint.
- **Session Lifecycle** (Ch 9): Checkpoint artifacts enable resumption across session boundaries.

## Common Mistakes

**Skipping the explore phase.** Jumping straight to execution without gathering context produces edits based on assumptions rather than evidence.

**No gate between plan and execute.** The most common chain failure is executing an unreviewed plan. The plan phase exists to catch errors before they become mutations.

**Over-gating.** A gate after every tool call within a phase prevents the agent from iterating. Gate between phases, not within them.

**Chains that can't resume.** If interruption means restarting from scratch, the chain design is fragile. Each phase should produce a usable artifact even if subsequent phases never run.
