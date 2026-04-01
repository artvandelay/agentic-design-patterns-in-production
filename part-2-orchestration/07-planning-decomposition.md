# Chapter 7: Planning and Decomposition

## The Pattern

Planning separates "decide what to do" from "do it." The agent first produces a plan — a structured description of the work to be done — then executes against that plan. The plan is a durable artifact: reviewable, modifiable, checkpointable, and resumable.

Decomposition is the companion pattern: breaking a large task into smaller sub-tasks that can be assigned, tracked, and completed independently. Planning decides *what* to do. Decomposition decides *how to divide it*.

The production constraint missing from textbook treatments: planning consumes budget. A plan that takes too long to produce, or that produces diminishing returns as it elaborates, is a drain. Production planners are budget-aware.

## The Problem

Without explicit planning, the agent jumps from request to execution. This works for small tasks. For complex tasks — multi-file refactors, architectural changes, multi-step workflows — it produces:

- Edits that don't account for dependencies between files
- Missing steps discovered only after partial execution
- No way for the user to redirect before irreversible changes
- No recovery point if execution fails partway through

Without decomposition, the agent attempts the entire task as one unit. If any part fails, the whole effort is wasted. There is no way to parallelize sub-tasks or assign them to specialized agents.

## How It Works

### Plan-Then-Execute

The simplest planning pattern:

```
Request ──► Plan ──► [Review] ──► Execute ──► Verify
```

The plan phase produces a structured artifact: a list of steps, dependencies between them, expected outcomes, and success criteria. The review gate (Ch 13) lets the user or system approve, modify, or reject the plan before execution begins.

The key property: **the plan constrains execution.** The execute phase follows the plan rather than re-reasoning from scratch. This prevents scope drift, where the agent starts doing the right thing but gradually expands into unplanned work.

### Decomposition Strategies

How to divide a task depends on what the risks are:

**Decompose by independence.** If sub-tasks don't share state, they can run in parallel (Ch 6). "Update the API handler" and "update the documentation" are independent. "Update the schema" and "update the handler that reads the schema" are not.

**Decompose by isolation.** When the risk is shared mutable state rather than reasoning difficulty, give each sub-task its own workspace. Separate working directories, separate branches, separate file sets. The isolation eliminates interference between sub-tasks, regardless of whether they run sequentially or in parallel.

**Decompose by phase.** Align sub-tasks with the explore/plan/execute/verify phases (Ch 5). The explore sub-task gathers context. The plan sub-task proposes changes. The execute sub-task makes changes. The verify sub-task confirms correctness. Each sub-task has a clear boundary and a testable output.

### Budget-Aware Planning

Planning consumes tokens. Each turn of planning is an API call with a cost. Production systems enforce two constraints:

**Diminishing-returns detection.** After several planning iterations, the system tracks how many tokens each iteration consumed. If two consecutive iterations each consume fewer than ~500 tokens, the system stops — the planner is stalling rather than making progress. This prevents the planning phase from becoming an open-ended elaboration that refines details without converging on action.

The implication for plan structure: plans should produce meaningful forward progress on each iteration. A plan that front-loads its important decisions and leaves details for the execution phase will pass the diminishing-returns check. A plan that endlessly refines edge cases will be cut off.

**Cost-per-step awareness.** Each step in a plan has a cost: the API call, the tool executions, the context consumed. In autonomous or proactive modes, the system enforces this directly — an agent that wakes up on a timer must either do meaningful work or explicitly go back to sleep rather than producing empty "still thinking" responses. Each wake-up is a billable event.

### Plans as Durable Artifacts

A plan that lives only in the model's reasoning is lost when the session ends or the context is compacted. Production plans are externalized:

- Written to a file or structured output that persists beyond the current turn
- Checkpointed so that interrupted execution can resume from the last completed step
- Reviewable by the user before execution begins (Ch 13)
- Modifiable — the user can edit the plan directly, and the execute phase respects the modifications

The durability requirement connects directly to session lifecycle (Ch 9): a plan that can be resumed across sessions is a plan that survives interruption.

## Production Considerations

**Decomposition should match the agent's capability boundaries.** If a sub-task requires write access and the available worker agents have only read tools, the decomposition doesn't fit the system's capabilities. Decompose into sub-tasks that match the tool pools of available agents (Ch 3).

**Over-planning is a real failure mode.** A plan with fifty detailed steps for a task that needs five is not more thorough — it is a budget drain. The plan should be as detailed as necessary to constrain execution and no more detailed.

**The plan/execute boundary should be explicit.** The transition from planning to execution changes the agent's posture: from proposing to committing, from reading to writing, from reversible to irreversible. This boundary should be a visible gate, not an implicit transition buried in the middle of a turn.

## Composability

- **Prompt Chaining** (Ch 5): Planning is the second phase of the four-phase chain (explore, plan, execute, verify).
- **Parallelization** (Ch 6): Decomposition identifies independent sub-tasks that can be parallelized.
- **Reflection** (Ch 8): The verify phase is reflection applied to the plan's execution.
- **Session Lifecycle** (Ch 9): Durable plans enable cross-session resumption.
- **Context Economics** (Ch 11): Diminishing-returns detection applies to planning iterations.
- **Human-in-the-Loop** (Ch 13): The plan review gate is the primary HITL checkpoint.

## Common Mistakes

**Planning forever.** The plan should converge on action. If it keeps elaborating without converging, it will be cut off by the budget system — and it should be.

**Decomposing without considering state dependencies.** Two sub-tasks that share mutable state cannot run in parallel. Decompose so that shared state is either isolated or serialized.

**Plans that exist only in context.** If the plan isn't externalized, it is lost on compaction, interruption, or session end. Write it down.

**Ignoring the cost of each planning turn.** In autonomous modes, every iteration is a billable event. Structure plans to make progress per turn.
