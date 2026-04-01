# Chapter 11: Context Economics

## The Pattern

Context is not a convenience resource — it is the most expensive input to every agent turn. Every token in the prompt costs money, affects latency, and determines whether the system gets a cache hit or pays full price. Managing context is a first-class engineering discipline: cache stability, prefix sharing across parallel agents, compaction strategy, and productivity-per-token measurement.

The shift: context management is not about what the model "knows." It is about the cost structure of the session.

## The Problem

Without context economics, the system treats the prompt as a semantic concern (does the model have enough information?) and ignores the economic reality:

- **Cache misses are expensive.** A prompt prefix of 50,000–70,000 tokens, cached from the previous turn, costs a fraction of what it would cost assembled from scratch. Any change to the prefix — reordering tool definitions, toggling a setting, adding a system prompt override — invalidates the cache and the next turn pays full price.
- **Parallel agents duplicate cost.** If three sub-agents each assemble their own prompt independently, the system pays for three full prefixes. If they share a byte-identical prefix, the system pays for one prefix and three small suffixes.
- **Growing context raises per-turn cost.** As the conversation grows, every turn sends more tokens. Without compaction, a 200-turn session costs orders of magnitude more per turn than a 5-turn session — even if the later turns are trivial.
- **Diminishing returns go undetected.** Without measuring productivity per token, the system cannot distinguish between a turn that consumed 10,000 tokens making real progress and a turn that consumed 10,000 tokens polishing a comma.

These are not edge cases. They are the dominant cost factors in any sustained agent session.

## How It Works

### Cache Stability

The prompt prefix — system prompt, tool definitions, project instructions, memory, and the beginning of conversation history — forms a cache key. If this prefix is byte-identical to the previous turn's prefix, the system gets a cache hit: the provider serves the cached prefix at reduced cost and latency, and the system only pays full price for new tokens appended after the cache boundary.

Cache stability is therefore an engineering constraint, not an implementation detail. Design decisions that seem unrelated to caching have direct cache consequences:

- **Latches** (Ch 9) exist specifically to protect cache stability. A setting that affects the prompt is frozen at session boot so it cannot change mid-session and invalidate the cache.
- **Tool definitions are part of the cache key.** Removing a tool from the tool pool changes the prompt prefix. Production systems keep unused tools in the definition block specifically to preserve the cache — the semantic cost (a tool the agent won't use) is worth less than the economic cost (busting a 60,000-token cache).
- **Custom system prompts can replace default assembly.** A user who provides a full system prompt override may be unknowingly replacing a cache-optimized default with a prefix that has no cache history. Over-customization quietly raises cost.

The principle: **byte-identical prefix = cached prefix = reduced cost.** Anything that changes the prefix bytes — even whitespace, even a reordered tool list — resets the cache.

### Prefix Sharing Across Parallel Agents

When the system forks sub-agents for parallel exploration (Ch 6), the fork mechanism is engineered around cache economics:

1. The parent's prompt is cloned byte-for-byte as the child's prefix
2. Tool results from the parent are replaced with identical fixed placeholders across all children
3. Only the final directive text (the specific task for each child) varies
4. The system prompt for fork agents returns an empty string — the real prompt is the parent's rendered bytes, passed directly

The result: N parallel children share one cached prefix. The system pays for the prefix once and pays only for the divergent suffix of each child.

This is why unused tools are preserved in the fork agent's tool list. Removing a tool the fork agent cannot use would save a few hundred tokens of definition but would break the byte-identical prefix, forcing each child to pay full price for its own cache miss. The economics are not close.

### Cache Snapshots

At the end of every turn, the system saves a cache snapshot — a frozen copy of the conversation state that can be reused by side-channel operations without reassembling the prompt.

The primary consumer is the quick-question mechanism: a side question that reuses the snapshot gets a cache hit on the full prior conversation, rather than paying for fresh assembly. This is meaningfully cheaper than starting a new session for a quick follow-up.

Cache snapshots also enable the extraction fork (Ch 10) to share the main agent's cache. The extraction agent uses the same tool list and cache key as the main agent — not because it needs every tool, but because cache sharing is more valuable than a minimal tool pool.

### Compaction

As conversation history grows, per-turn cost rises. Compaction compresses the history: the runtime summarizes earlier turns into a compact representation and rebuilds the prompt with the summary replacing the full transcript.

After compaction:
- Conversation history is shorter, reducing per-turn cost
- All latches are re-evaluated from current values (Ch 9)
- The cache prefix is rebuilt from scratch (previous cache is invalidated)
- A new cache begins accumulating from the compacted prefix

Compaction is a trade-off: it busts the existing cache but establishes a shorter prefix that will be cheaper going forward. The right time to compact is before the conversation grows unwieldy — not after it already has.

Auto-compaction exists but can fail repeatedly if the session shape is pathological (e.g., enormous tool outputs that resist summarization). When auto-compaction keeps failing, the problem is usually the session structure, not the feature.

### Diminishing-Returns Detection

The budget system measures not just total tokens consumed but **productivity per token**. After several continuations, the system tracks the delta of tokens consumed since the last checkpoint. If two consecutive deltas are both below a threshold (~500 tokens), the system stops — even if the total budget has not been reached.

The logic: small token deltas mean the agent is making small changes. The large, structural work happened earlier. Continued execution is producing diminishing returns at the same per-turn cost.

This is an economic circuit breaker. Without it, an agent in autonomous mode could burn through its budget on polishing work that adds marginal value. With it, the system cuts losses when the cost-to-benefit ratio inverts.

Diminishing-returns detection applies to both the main agent and sub-agents, but the mechanisms differ: sub-agents get an immediate stop with no completion event, keeping budget logic on the main thread.

### Stable Framing

A meta-principle that follows from cache stability: **stable framing beats clever rephrasing.**

Constantly reshaping requests, swapping tools in and out, or restructuring the system prompt between turns degrades cache reuse and raises cost — even if each individual rephrasing is semantically better. The system rewards consistency. A slightly imperfect but stable prompt that maintains cache hits across 20 turns is cheaper and often more effective than a "perfect" prompt that busts the cache every turn.

This is counterintuitive for users accustomed to iterating on prompts. The economic model of agent sessions rewards a different discipline: get the framing right once, then keep it stable.

## Production Considerations

**Cache misses dominate cost.** A single prefix change can cost more than dozens of subsequent turns. Audit what changes the prompt prefix between turns and eliminate unnecessary variation.

**Keep unused tools in fork agents.** The cache savings from a shared prefix outweigh the marginal cost of extra tool definitions. Remove tools only when the prefix is not shared.

**Compact proactively.** Waiting until the session is bloated means paying inflated per-turn costs for every turn before compaction. Compact when the conversation crosses a reasonable length threshold.

**Measure productivity, not just consumption.** Total token count is a poor signal. Track tokens consumed per meaningful output unit (files changed, tests passed, tasks completed). This is what diminishing-returns detection does at the system level.

## Composability

- **Prompt Assembly** (Ch 2): The assembled prompt is the cache key. Prompt architecture is cache architecture.
- **Session Lifecycle** (Ch 9): Latches, compaction, and clear are session-level mechanisms for managing context economics.
- **Memory Management** (Ch 10): Memory files are part of the prompt prefix. Their size and stability directly affect cache hit rates.
- **Parallelization** (Ch 6): Fork parallelism works because of prefix sharing. Without cache-aware fork design, parallel agents would be N times more expensive than sequential.
- **Reflection** (Ch 8): Each reflection iteration sends the full context. Reflection cost scales with context size — compacting before a reflection phase can reduce per-iteration cost significantly.

## Common Mistakes

**Treating context as unlimited.** "Just add more context" works until the budget system cuts the session off or the per-turn cost becomes prohibitive.

**Changing the prompt prefix casually.** Reordering instructions, toggling tools, or adding system prompt overrides between turns. Each change busts the cache.

**Never compacting.** Running sessions until they hit the context limit, then starting over. Proactive compaction maintains a workable session at manageable cost.

**Optimizing prompt wording while ignoring cache.** Spending effort on marginally better phrasing that changes the prefix every turn. The cache cost of instability exceeds the quality gain from better wording.

**Building fork agents with minimal tool pools.** Removing tools from fork agents to "keep them focused" breaks prefix sharing and increases total cost. Focus is better achieved through the directive text, not the tool list.
