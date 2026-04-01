# Chapter 16: Multi-Agent Coordination

## The Pattern

Multi-agent coordination uses a coordinator/worker topology where the communication mechanism *is* the coordination mechanism: worker results arrive as conversation messages, not through a separate message bus. The model is the protocol layer. This collapses the traditional distinction between "coordination" and "communication" into a single design.

Three production constraints shape how this works: conversation-as-protocol, cache-aware fork design, and bounded coordination (agents cannot make commitments that outlive their session).

## The Problem

A single agent handling a large task hits limits: context grows, the token budget drains on exploration before reaching execution, and errors in one area contaminate reasoning about another. The natural response is to split the work across multiple agents — but this introduces coordination problems:

- How do workers report results to the coordinator?
- How do you avoid paying N times the prompt cost for N workers?
- What happens when a worker fails?
- Can agents make promises to each other about future work?

Naive multi-agent systems solve these with external infrastructure: message queues, shared databases, IPC channels. Production systems solve them with the model's existing capability — conversation.

## How It Works

### Conversation as Protocol

Worker results arrive as user-role conversation messages containing structured XML — task ID, status, summary, result, and usage. The coordinator understands this format because its system prompt documents the schema.

This is not a hack. It is a deliberate architecture choice: the model already understands conversation. Rather than building a separate protocol layer the model must learn to use, the system routes coordination through the channel the model is natively fluent in.

Workers are fully isolated. They cannot see the coordinator's conversation history. In constrained configurations, workers get only three tools (read, edit, shell) — enough to do focused work, not enough to spawn further agents or interfere with the coordinator's state.

### Cache-Aware Fork Design

When the system forks worker agents for parallel tasks, the fork mechanism is engineered around cache economics (Ch 11):

1. Clone the parent's prompt byte-for-byte as the child's prefix
2. Replace all tool results with identical fixed placeholders across children
3. Vary only the final directive text (the specific task assignment)
4. Return an empty string from the fork agent's system prompt — the real prompt is the parent's rendered bytes

The result: one cached prefix, N workers. Each worker pays only for its divergent suffix. This is why parallel exploration is cheaper than expected — the system amortizes the prompt cost across all children.

The fork agent keeps tools it cannot use (like the agent-spawning tool) in its tool list because removing them would change the tool definition block and bust the shared cache. A few hundred tokens of unused definitions cost less than N full cache misses.

Recursion prevention is not depth tracking — it is a scan of message history for a boilerplate tag that marks forked contexts. Simple, stateless, and immune to off-by-one errors in depth counters.

### Bounded Coordination

Agents cannot make commitments that outlive their session. This is a deliberate safety constraint:

- **No durable scheduling.** A coordinator cannot schedule a worker to run tomorrow because agent IDs do not survive restart. A scheduled task would reference an agent that no longer exists, creating an orphaned trigger.
- **Explicit communication channels only.** Workers are told in their system prompt that plain text output is invisible to the team — only explicit message-sending reaches other agents. Implicit side effects (stdout, file writes) do not propagate. The protocol must be designed, not assumed.
- **Session-scoped identity.** An agent's identity exists for the duration of its session. It cannot be referenced, resumed, or messaged after the session ends.

This bounds the coordination model: multi-agent systems can coordinate within a session but cannot create persistent inter-agent relationships. Long-lived coordination must be externalized into durable artifacts (files, databases, task queues) rather than agent-to-agent promises.

### Coordinator Lifecycle

The coordinator has its own lifecycle constraints. It skips certain stop hooks (like idle-ping notifications) to avoid messaging itself. Process-level resources (locks, cleanup handlers) run only on the coordinator thread because they are process-wide — workers running in the same process must not contend for them.

Worker creation is serialized with a lock and a startup delay to avoid racing the shell's initialization. This is a production detail that matters: spawning five workers simultaneously can corrupt their shell environments if the init scripts haven't finished.

## Production Considerations

**Use conversation as the protocol layer.** Building a separate message bus for agent coordination adds complexity without adding capability. The model already understands structured messages in conversation.

**Share the prompt prefix.** Fork design should maximize byte-identical prefixes across workers. The cache savings dominate the cost model for parallel work.

**Bound coordination to the session.** Do not allow agents to create persistent commitments to each other. Externalize long-lived coordination into artifacts the system can manage independently of agent identity.

**Isolate workers.** Workers should not see the coordinator's full context. Scoped tool pools and isolated conversation histories prevent workers from interfering with each other or with the coordinator.

## Composability

- **Parallelization** (Ch 6): Multi-agent coordination is parallelization applied at the agent level. The same read/write rules apply — read-only workers fan out, mutation workers serialize.
- **Context Economics** (Ch 11): Cache-aware fork design is the mechanism that makes multi-agent coordination economically viable.
- **Session Lifecycle** (Ch 9): Bounded coordination follows from session scoping — agents cannot outlive their session, so coordination cannot either.
- **Permission Pipelines** (Ch 12): Each worker operates within its own permission scope. The coordinator's permissions do not automatically propagate to workers.
- **Sandboxing** (Ch 15): Each worker needs its own sandbox boundary. Shared state between workers is a potential isolation violation.

## Common Mistakes

**Building external message infrastructure.** Adding a message queue or shared database for agent coordination when conversation messages would suffice.

**Independent prompt assembly per worker.** Each worker assembling its own prompt from scratch instead of sharing the parent's cached prefix. This multiplies cost by the number of workers.

**Unbounded coordination.** Allowing agents to schedule future work, reference each other by ID across sessions, or create persistent inter-agent state. These create orphaned references when sessions end.

**Unserialized worker creation.** Spawning workers in parallel without accounting for shell initialization races. Serialize creation with a startup delay.
