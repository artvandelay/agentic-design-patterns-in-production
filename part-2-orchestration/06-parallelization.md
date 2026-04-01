# Chapter 6: Parallelization

## The Pattern

Parallelization fans out work across concurrent operations — multiple tool calls, multiple agents, or multiple branches of exploration — then collects and reconciles results. It is how agent systems turn wall-clock time into throughput.

The production constraints are: what is safe to parallelize, how failure in one branch affects the others, and how to structure parallel work so agents share computation rather than duplicate it.

## The Problem

Sequential execution is correct but slow. An agent that reads ten files one at a time takes ten round trips. An agent that reads them in parallel takes one.

Naive parallelization is fast but unsafe. An agent that edits ten files in parallel can produce conflicting changes or race conditions. An agent that runs ten shell commands in parallel can corrupt shared state.

The question is not "should we parallelize?" but "what are the rules?"

## How It Works

### The Read/Write Rule

The fundamental constraint (introduced in Ch 1, detailed here):

**Reads parallelize. Writes serialize.**

Read operations — file reads, searches, web fetches, status queries — are idempotent. Running N reads concurrently produces the same results as running them sequentially. They can always fan out.

Write operations — file edits, state-modifying commands, resource creation — are not idempotent. Two concurrent writes to the same file produce corruption. Writes that depend on each other's output must be ordered.

Mixed batches: when the model requests both reads and writes in a single response, the runtime fans out reads in parallel, waits for all reads to complete, then runs writes sequentially. This preserves correctness without unnecessarily serializing the reads.

### Asymmetric Failure Propagation

When multiple operations run concurrently and one fails, the system's response depends on the failure type (Ch 3):

**Environment failure** (shell command error): Cancel all concurrent sibling operations. The reasoning: a broken shell means other shell operations will also produce unreliable results. Inject synthetic error messages for cancelled siblings so the model knows they didn't run. Let the model reason about the failure from a clean state.

**Informational failure** (file not found, HTTP 404): Do not cancel siblings. The missing file is data, not a crisis. Other concurrent operations are unaffected. The model incorporates the failure into its reasoning alongside the results of sibling operations that succeeded.

This asymmetry is a design choice with specific consequences. Without it, a parallel batch of ten file reads where one file doesn't exist would cancel the other nine — wasting their work and requiring a retry. With it, nine results come back successfully and one comes back as "not found," which is exactly the information the model needs.

### Cache-Aware Fork Design

When an agent system forks sub-agents for parallel exploration, the naive approach is to create N independent agents, each with its own prompt. This works but is expensive — each agent pays the full cost of its prompt.

The production approach: **share the prompt prefix.** The parent agent's prompt (system instructions, tool definitions, conversation history up to the fork point) is reused byte-for-byte across all children. Each child varies only its final directive — the specific task it's been assigned.

This works because prompt caches key on byte-identical prefixes. If all children share the same prefix, the cache absorbs the cost of the shared portion. The system pays for one prompt and N small directive suffixes, rather than N full prompts.

The implication is non-obvious: the fork must not change anything in the shared prefix. Tool definitions, tool result placeholders, even unused tools must remain identical across children. Removing an unused tool from a child's definition would change the prompt bytes and break cache sharing — costing more than the few tokens the unused definition occupies.

### Fan-Out / Fan-In

The orchestration pattern for parallel work:

```
Coordinator
    │
    ├── Fork child 1 (directive: "search for X")
    ├── Fork child 2 (directive: "search for Y")
    └── Fork child 3 (directive: "search for Z")
            │
            ▼
    Collect results from all children
            │
            ▼
    Coordinator synthesizes
```

**Fan-out**: The coordinator spawns N children, each with a scoped task. Children are isolated — they cannot see each other's work or communicate directly.

**Fan-in**: When all children complete, their results flow back to the coordinator as messages. The coordinator synthesizes the results into a unified understanding.

Children typically run with a minimal tool pool (Ch 3) — read and search tools, no write access. This keeps the parallel phase safe: N concurrent readers can't corrupt state.

## Production Considerations

**Parallelization has a concurrency limit.** Spawning 50 concurrent agents produces 50 concurrent API calls, 50 concurrent tool executions, and 50 concurrent result streams. Production systems cap concurrency based on API rate limits, resource constraints, and the diminishing returns of extreme fan-out.

**Child isolation is a feature.** Children that can see each other's intermediate work create coordination complexity (who goes first? what if one child's result invalidates another's task?). Keeping children isolated and letting the coordinator synthesize is simpler and more reliable.

**Parallel failures should be collected, not short-circuited.** When three of five children fail, the coordinator should see all five results (three failures, two successes) and reason about the pattern. Short-circuiting on the first failure discards information.

## Composability

- **The Agent Loop** (Ch 1): Each parallel branch is an independent agent loop.
- **Tool Use** (Ch 3): Read/write classification determines what can be parallelized. Failure semantics determine how parallel failures propagate.
- **Prompt Chaining** (Ch 5): Read-only chain phases (explore, verify) are parallelizable. Write phases are not.
- **Context Economics** (Ch 11): Cache-aware fork design is a context economics pattern. Shared prefixes reduce cost.
- **Multi-Agent Coordination** (Ch 16): Fan-out/fan-in is the basic multi-agent pattern. This chapter covers the constraints; Ch 16 covers the coordination protocol.

## Common Mistakes

**Parallelizing writes.** Concurrent writes to shared state produce corruption. If two agents edit the same file in parallel, one edit overwrites the other. Writes serialize.

**Cancelling everything on any failure.** A missing file should not cancel nine successful file reads. Classify failures by blast radius (Ch 3) and propagate accordingly.

**Creating independent prompts for each child.** Each independent prompt pays full cache cost. Share the prefix, vary only the directive.

**Fan-out without fan-in.** Spawning parallel work without a coordinator to synthesize results produces N disconnected outputs. The coordinator's synthesis step is where the value of parallelization is realized.
