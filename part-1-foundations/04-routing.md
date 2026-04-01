# Chapter 4: Routing

## The Pattern

Routing dispatches work to the right compute surface: the right model, execution environment, agent variant, or workflow mode. It answers "where should this run?" before the agent loop starts processing.

Production routing has four dimensions: model routing (which model), surface routing (local vs. remote), capability routing (which features are enabled), and mode routing (planning vs. execution vs. review).

## The Problem

**One-size-fits-all.** Every request goes to the same model on the same surface. Simple tasks overpay. Complex tasks get insufficient capability.

**Implicit routing via prompt hacks.** Users learn to rephrase requests ("think step by step," "be brief") to get different behavior. The routing logic lives in the user's head rather than in the architecture.

## How It Works

### Model Routing

```
Incoming request
    │
    ├── Simple task → fast, cheap model
    ├── Standard task → default model
    └── Complex task → most capable model
```

Model routing can be static (configured per agent role), dynamic (a classifier estimates complexity), or user-directed (a command escalates to a higher-capability model).

### Surface Routing

Some operations run locally (low latency, local file access). Others require remote execution (more powerful compute, larger models, GPU resources).

The production-grade version is **teleportation**: serializing the entire session context, transmitting it to a remote environment, executing there, and synchronizing results back. A routing decision that looks like "use a bigger model" may actually mean "move to a remote server with different capabilities, permissions, and resource limits."

### Capability Routing (Feature Flags)

Production systems use feature flags to gate capabilities — experimental features for a subset of users, internal-only features, gradual rollouts, tier-based access. Two users running the same version may get meaningfully different behavior.

This creates a requirement: **routing state must be observable.** If the system routes differently based on hidden state, users need a way to see that state. Diagnostic commands that report routing state are part of the system's contract with users, not debugging tools. Without them, users experiencing different behavior have no way to understand why.

### Mode Routing

Distinct modes change the agent's constraints:

- **Planning mode**: Read-only tools, output is a plan, approval required before execution
- **Execution mode**: Full tool pool, mutations allowed
- **Review mode**: Structured feedback output, different workflow

A mode switch changes the tool pool, the system prompt, and the output format. It is a routing decision with cache implications, not a UI preference.

## Production Considerations

**Routing should be inspectable.** Implicit routing that silently picks a model or mode creates unpredictable behavior. Make routing decisions visible.

**Fallback routing matters.** When the preferred route fails (model unavailable, remote unreachable, rate-limited), the system needs an explicit fallback path. Design it before you need it.

**Routing and caching interact.** Different routes produce different prompt prefixes. Stable routing within a session preserves the cache. Dynamic per-turn routing defeats it.

**Routing doesn't fix bad task structure.** A task that fails with a fast model usually also fails with a slow model — just more eloquently. Fix the task (Ch 5, Ch 7), then optimize the route.

## Composability

Routing sits between the user's request and the agent loop (Ch 1). It determines which loop runs.

- **Prompt Assembly** (Ch 2): Different routes may assemble different prompts.
- **Tool Use** (Ch 3): The tool pool may change based on the route. Planning mode restricts to read-only tools.
- **Session Lifecycle** (Ch 9): Routing decisions may be latched at session start.
- **Multi-Agent Coordination** (Ch 16): The coordinator routes work to workers, selecting model, tool pool, and execution surface per sub-task.

## Common Mistakes

**Defaulting to the most capable model for everything.** If 80% of tasks work fine with a cheaper model, defaulting to the expensive one is a 5-10x cost premium for no benefit on those tasks.

**Hiding routing state from users.** When behavior varies and the user can't see why, they blame the model. Exposing routing state lets users debug their own experience.

**Treating mode switches as free.** A mode switch may change the tool pool, system prompt, and interaction constraints — each with cache implications.
