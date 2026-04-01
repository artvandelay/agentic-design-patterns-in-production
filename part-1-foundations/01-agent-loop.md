# Chapter 1: The Agent Loop

## The Pattern

An agent receives input, reasons about what to do, takes action through tools, observes the result, and decides whether to continue or stop. This loop — input, reason, act, observe — is the fundamental unit of agentic behavior.

A chatbot takes a prompt and returns a response. An agent takes a goal and runs a loop until the goal is met or the budget is exhausted.

## The Problem

Without a loop, you get **prompt sprawl** (exploration, planning, implementation, and verification packed into one request) or **tool soup** (tools called in unpredictable order with no mechanism for course-correcting on failure). Both break down on multi-step tasks.

## How It Works

```
┌─────────────────────────────────────┐
│                                     │
│   Input ──► Reason ──► Act ──► Observe
│     ▲                          │    │
│     └──────────────────────────┘    │
│         (continue or stop)          │
└─────────────────────────────────────┘
```

**Input**: The user's request plus all assembled context — system prompt, project instructions, memory, conversation history, tool definitions.

**Reason**: The model decides what to do next — a tool call, a text response, or a decision to stop.

**Act**: The runtime executes the model's decision. Tool calls run and produce output. Text responses render to the user.

**Observe**: The result feeds back into the loop as new context. The model reasons about it on the next iteration.

The loop terminates when: the model responds without requesting further tool calls, the system hits a budget limit, or the user interrupts.

### The Query Engine

In production, the agent loop is implemented as a **query engine** managing the full lifecycle of a turn:

1. Assemble the prompt from all context sources
2. Call the model API
3. Stream the response
4. If the response includes tool calls, execute them (respecting permissions)
5. Feed tool results back as new messages
6. Repeat from step 2 until the model stops requesting tools

Everything else — memory, permissions, planning, multi-agent coordination — is either input to the query engine or post-processing after it completes.

### Reads vs. Writes

Read operations (searching files, fetching docs, inspecting state) are idempotent and safe to run concurrently. Write operations (editing files, running state-modifying commands) must be serialized — two concurrent writes to the same file produce corruption.

This is a correctness constraint, not a performance optimization. Loops that serialize everything are slow. Loops that parallelize everything are unsafe. The read/write distinction is how production systems get both correctness and speed.

### Tool Pools and Capability Scoping

Not every agent needs every tool. A worker exploring files might get three tools: read, search, shell. A coordinator might get tools for spawning sub-agents but no file-editing tools.

The tool pool is a capability boundary. Scoping it per agent role serves safety (the agent can't do what it shouldn't), focus (smaller option space improves tool selection), and cost (fewer definitions means a smaller prompt).

## Production Considerations

The production loop adds layers on top of the basic cycle:

**Permissions**: Before a tool executes, the runtime checks allow/deny rules, may prompt the user for approval, or short-circuit based on execution mode. (Ch 12)

**Budget tracking**: The runtime tracks token consumption and may stop the loop if it hits a limit or detects diminishing returns — consecutive iterations consuming under 500 tokens each. (Ch 11)

**Stop hooks**: When the loop terminates, post-turn hooks fire in parallel: cache snapshots, memory extraction, session classification, consolidation checks. The loop doesn't simply stop — it hands off to structured post-processing. (Ch 17)

**Asymmetric error handling**: A failed shell command (environment broken) cancels concurrent sibling tool calls. A missing file (informative data) does not. Error classification is per-tool. (Ch 3)

## Composability

Every subsequent chapter refines a specific aspect of this loop:

- **Prompt Assembly** (Ch 2): how input is constructed
- **Tool Use** (Ch 3): how the act phase works
- **Prompt Chaining** (Ch 5): how multiple loops are sequenced
- **Parallelization** (Ch 6): how the act phase fans out
- **Planning** (Ch 7): how the reason phase becomes explicit and checkpointable
- **Session Lifecycle** (Ch 9): the lifecycle *around* the loop — boot, run, interrupt, resume

## Common Mistakes

**Packing everything into one prompt.** Multi-step work needs a loop. If the entire workflow is in one request, there is no mechanism for observation, correction, or verification between steps.

**Ignoring the read/write distinction.** Batch reads first, then mutate. Mixing them in an undifferentiated stream is slower and less reliable.

**Assuming the loop runs forever.** Production loops have budgets and diminishing-returns detection. Structure work so each iteration makes forward progress.

**Micromanaging intermediate steps.** Give the loop a goal, constraints, and a stop condition. Inspect outcomes, not individual tool calls.
