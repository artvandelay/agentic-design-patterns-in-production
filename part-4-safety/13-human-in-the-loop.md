# Chapter 13: Human-in-the-Loop

## The Pattern

Human-in-the-loop (HITL) is the practice of placing a human decision point inside the agent's execution loop. The production insight is not *whether* to include a human — it is **where** in the loop to place them, **what** they should be reviewing, and **how often** they should be interrupted. Poorly placed HITL degrades both the human's attention and the agent's ability to make progress.

## The Problem

Without HITL, the agent operates autonomously from start to finish. For low-risk tasks (reading files, searching code, running tests), this is appropriate. For high-risk tasks (deleting data, deploying code, modifying production configuration), full autonomy is dangerous — a single bad decision executes without review.

But the opposite extreme — approving every action — is equally broken. An agent that asks permission for every file read, every search query, every shell command becomes a slow, frustrating interface that the human learns to rubber-stamp. Approval fatigue is a real security failure mode: the human clicks "yes" without reading because they have been trained by dozens of trivial approvals to expect that every approval is trivial.

The design challenge is placing the human at the point where their attention has the highest value: after enough context has been gathered to make a meaningful decision, and before irreversible actions are taken.

## How It Works

### Placement: After Exploration, Before Mutation

The four-phase chain (Ch 5) provides the natural HITL placement:

```
Explore ──► Plan ──► [HUMAN REVIEW] ──► Execute ──► Verify
```

The human reviews the plan — not the raw exploration output, not the individual tool calls, not the final result after mutations have already happened. This placement has two properties:

1. **The human has enough information.** The explore phase gathered context. The plan phase synthesized it into a proposal. The human is reviewing a concrete, bounded proposal grounded in evidence — not making a decision in the dark.

2. **The human can still redirect.** No mutations have occurred. Rejecting or modifying the plan is cheap. Catching an error after execution requires rollback; catching it at the plan stage requires only a revised instruction.

### What the Human Should Review

The human's review should include the **plan and the runtime state**, not just the model's proposed output.

Runtime state includes:
- What context the agent gathered (did it look at the right files?)
- What permissions are active (is the agent operating in a mode that matches the task's risk level?)
- What the session's cost posture looks like (is this about to be expensive?)
- Whether the environment is healthy (are tools working, is the connection stable?)

Reviewing only the plan text misses environmental problems. An agent can produce a correct plan while operating in a degraded environment — wrong model routed due to a fallback, stale context from a failed compaction, broken tool that will fail during execution. Inspecting the runtime catches these before they become execution failures.

### Approval Granularity

HITL systems need a granularity model — what level of action requires approval:

**Per-command approval**: Every tool call requires explicit human approval. Appropriate for the highest-risk environments (production databases, financial systems). Extremely slow. Causes approval fatigue in all but the most critical contexts.

**Per-phase approval**: The human approves at phase boundaries (plan → execute). The agent operates freely within each phase. This is the default for most production work — it balances safety with throughput.

**Per-session approval**: The human sets goals and constraints at session start, then the agent operates autonomously within those bounds. Appropriate for well-understood, repeatable workflows with strong permission guardrails (Ch 12).

**Escalation-based approval**: The agent operates autonomously but escalates to the human when it encounters uncertainty, risk, or a situation outside its configured authority. This requires the agent to have a reliable model of its own confidence — which is the weakest link.

The right granularity depends on the task's risk profile and the permission configuration. Well-configured permissions (Ch 12) reduce the need for per-command approval by encoding the human's recurring decisions into rules.

### The Cost of Over-Interrupting

Every interruption has a cost beyond the human's time:

- **Context degradation.** If the human interrupts mid-exploration to redirect, the agent loses the partial context it was building. The exploration restarts from a different angle, potentially missing what the original trajectory would have found.
- **Cache disruption.** Interruption and redirection can change the conversation shape, affecting cache stability (Ch 11). A session that flows smoothly through phases maintains better cache economics than one with frequent interruptions and pivots.
- **Cancellation aftermath.** Canceling a substantial operation mid-execution can leave stop hooks unfinished (Ch 9). The system benefits from clean turn boundaries. If you cancel something substantial, giving the system a beat before stacking the next request allows post-turn processing to complete.

The design principle: **manage outcomes, not keystrokes.** Set goals, constraints, and stop conditions. Inspect results at phase boundaries. Intervene when the trajectory is wrong, not when individual steps look unfamiliar.

### Plan Mode as a Forcing Function

Some systems offer an explicit plan-only mode where the agent can explore and propose but cannot execute mutations. This is HITL by architecture rather than by approval prompt:

- The agent gathers context freely (read operations are unrestricted)
- The agent produces a plan (a reviewable artifact)
- The human reviews and either approves execution or modifies the plan
- Only after approval does the agent switch to a mode where mutations are permitted

This is stronger than per-phase approval because the constraint is enforced at the tool-pool level — the agent literally cannot execute write operations in plan mode, regardless of what it decides to do. The human's approval is not just a gate; it is a mode transition.

## Production Considerations

**Place the human after exploration, before mutation.** This maximizes the information available for the decision and minimizes the cost of rejection.

**Review runtime state, not just output.** The plan can be correct while the environment is degraded. Inspect the machine, not just the model's proposal.

**Encode recurring decisions as permissions.** If the human always approves the same class of operation, it should be an allow rule — not a repeated approval prompt. Reserve human attention for genuinely novel decisions.

**Respect the cost of interruption.** Frequent interruption degrades context, cache stability, and the agent's ability to build momentum on complex tasks.

## Composability

- **Prompt Chaining** (Ch 5): The gate between plan and execute is the natural HITL checkpoint in a chain.
- **Permission Pipelines** (Ch 12): The "ask" action in the permission pipeline is the mechanism that triggers human approval for specific commands.
- **Session Lifecycle** (Ch 9): Session resumability makes HITL practical for long tasks — the human can leave and return without losing the work state.
- **Planning** (Ch 7): Plan mode is HITL applied to the planning pattern — the human reviews the plan as a durable artifact before authorizing execution.
- **Context Economics** (Ch 11): Interruption has cache costs. HITL design should account for the economic impact of frequent redirection.

## Common Mistakes

**Approving every action.** Per-command approval on low-risk operations trains the human to rubber-stamp. When a genuinely dangerous action appears, the human is conditioned to approve without reading.

**Reviewing only the output.** Checking the plan text without inspecting the runtime state. The plan can be correct while the environment is wrong.

**No HITL on high-risk operations.** Running mutations in autonomous mode without any review checkpoint. One bad decision executes without recourse.

**Interrupting mid-exploration.** Redirecting the agent before it finishes gathering context. The result is a plan based on incomplete information — worse than waiting for exploration to complete and then reviewing.

**Treating HITL as a product feature rather than a design decision.** HITL is not "add an approval dialog." It is a question of where in the execution architecture the human's judgment has the highest value.
