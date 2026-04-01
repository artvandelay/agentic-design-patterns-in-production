# Chapter 3: Tool Use

## The Pattern

The model produces a structured tool call (function name, arguments). The runtime executes it and returns the result. The model incorporates the result into its next reasoning step. This is how agents act on the world.

The production concerns are not about function-calling mechanics — those are well-documented. They are about the **contract between model and runtime**: how tools are scoped, how failures propagate, and how the tool pool interacts with caching.

## The Problem

**Undifferentiated failure handling.** A shell command that fails (environment broken) and a file read returning "not found" (informative data) require fundamentally different responses. Treating them the same produces either fragile systems that halt on every error or oblivious systems that ignore environment corruption.

**Tool pool bloat.** Each tool adds tokens to the prompt via its definition. More tools means higher cost, more selection ambiguity, and worse per-tool accuracy.

**Cache-unaware tool management.** Adding or removing a tool changes the prompt's byte representation and invalidates the cache. A single tool-pool change mid-session can invalidate tens of thousands of cached tokens.

## How It Works

### The Tool Call Cycle

```
Model produces response
    │
    ├── Text only → turn complete
    │
    └── Contains tool call(s)
            │
            ├── Check permissions (Ch 12)
            │       ├── Denied → return error as tool result
            │       └── Allowed → execute
            │
            ├── Execute tool(s)
            │       ├── Success → return result
            │       └── Failure → classify error, return result
            │
            └── Feed results back as messages → next iteration
```

### Tool Definitions as Cache Surface

Tool definitions are serialized into the prompt alongside system instructions. The prompt cache key includes their exact bytes. Changing a description, adding a parameter, or removing a tool invalidates the cache for that prefix.

This is why production systems sometimes keep tools in the definition that the agent cannot use. A forked sub-agent retains the parent's full tool list — including tools it will never call — because removing them would change the tool definition block and break cache sharing across all children. The cache savings of sharing one prefix across N agents outweigh the cost of a few unused definitions.

### Tool Pool Scoping

Scope the pool per agent role:

- **Full agent**: Read, write, search, execute, spawn sub-agents, manage memory.
- **Worker agent**: Read, search, limited commands. No write access, no sub-agent spawning.
- **Fork agent**: Read, edit, bash. Three tools.

The principle is least privilege. An agent without the write tool can't overwrite a file — a stronger guarantee than an instruction not to. Fewer tools also means a simpler selection problem for the model and a smaller prompt.

### Failure Semantics

Tool failures have **asymmetric semantics**:

**Environment failures** (shell errors): The execution environment is likely broken. Cancel concurrent sibling tool calls, inject synthetic error messages for cancelled calls, let the model reason from a clean state. The rationale: if the shell is broken, other concurrent shell operations will also produce unreliable results.

**Informational failures** (file not found, HTTP 404): Data the model should reason about. "That file doesn't exist" is useful information, not an emergency. Do not cancel sibling operations.

The classification is per-tool: **classify failures by blast radius.** Environment failures cascade. Informational failures don't.

### Read Tools vs. Write Tools

**Read tools** (file reads, searches, web fetches): Idempotent. Safe to run concurrently.

**Write tools** (file edits, state-modifying commands): Must be serialized when they affect the same state.

When the model requests multiple tool calls in one response, the runtime fans out reads in parallel and serializes writes. This is a correctness constraint — concurrent writes to the same resource produce corruption.

## Production Considerations

**Tool definitions should be stable within a session.** If you need different tool sets for different phases, use separate agents with scoped pools rather than modifying one agent's pool mid-session.

**Tool result size matters.** A tool returning 100,000 tokens of raw output consumes context that could be used for reasoning. Production tools truncate, summarize, or paginate large outputs.

**Tool timeouts are not optional.** A tool call that hangs stalls the entire agent loop. Every tool needs a timeout. When it fires, the tool returns an error result (classified as environmental or informational) and the loop continues.

**The tool description is a prompt.** The model reads it to decide when and how to use the tool. "Runs a command" is less effective than "Execute a shell command in the working directory. Returns stdout, stderr, and exit code. Commands modifying the filesystem require write permission."

## Composability

- **Prompt Assembly** (Ch 2): Tool definitions are part of the assembled prompt.
- **Parallelization** (Ch 6): Read/write distinction governs what can be parallelized. Failure semantics determine how parallel failures propagate.
- **Permission Pipelines** (Ch 12): Permission checks happen between the model's decision and the runtime's execution.
- **Multi-Agent Coordination** (Ch 16): Tool pool scoping defines agent capabilities.

## Common Mistakes

**Giving every agent every tool.** Scope to the role. No write access if no writes are needed.

**Treating all failures the same.** Shell error ≠ file not found. One cascades, the other doesn't.

**Changing the tool pool mid-session.** Plan the pool at session start. Mid-session changes invalidate the cache.

**Returning unstructured tool output.** A tool that dumps a whole file into context wastes tokens. Structured, bounded output respects the context budget.
