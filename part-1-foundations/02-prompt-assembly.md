# Chapter 2: Prompt Assembly

## The Pattern

The system prompt is **assembled at runtime** from multiple sources — project instructions, user preferences, extracted memories, team conventions, session state, tool definitions, and protocol schemas — then frozen for the session to protect cache economics.

Prompt engineering optimizes the content of instructions. Prompt *architecture* — the layers, their precedence, their stability, and their cache behavior — determines whether the system works at scale.

## The Problem

**Context amnesia.** Without persistent layers, every session starts blank. The user re-explains project conventions each time.

**Prompt bloat.** Context grows without structure. Important instructions get buried. Attention dilutes.

**Cache instability.** Any prompt change invalidates the cache. If the prompt changes every turn, every turn pays full cost.

**No separation of concerns.** Project conventions, user preferences, and session context compete for the same space with no priority ordering.

## How It Works

A production assembly pipeline has distinct layers ordered by stability (most stable first):

```
┌─────────────────────────────────────────┐
│  System Prompt (assembled at runtime)   │
├─────────────────────────────────────────┤
│  Layer 1: Base system instructions      │  ← Defined by the runtime
│  Layer 2: Tool definitions              │  ← Derived from the tool pool
│  Layer 3: Project instructions          │  ← From project config files
│  Layer 4: User preferences              │  ← From user-level config
│  Layer 5: Team/org conventions          │  ← From shared config
│  Layer 6: Extracted memories            │  ← From previous sessions
│  Layer 7: Session-specific context      │  ← From the current session
│  Layer 8: Protocol schemas              │  ← For multi-agent communication
└─────────────────────────────────────────┘
```

**Layer 1 — Base system instructions.** The runtime's own rules: behavioral guidelines, output formatting, safety constraints, tool-use rules. Often tens of thousands of tokens. Because it rarely changes, it anchors the cache prefix.

**Layer 2 — Tool definitions.** Structured definitions (name, description, parameter schema) for every available tool. These are part of the prompt's byte representation — adding or removing a tool invalidates the cache. Production systems sometimes keep unused tools in the definition to preserve cache sharing across agent variants.

**Layer 3 — Project instructions.** Coding conventions, directory structure, testing rules. Best written as short operational rules: "Use TypeScript strict mode." "Tests go next to source files." "Never modify the schema without a migration." Decision rules, not narrative.

**Layer 4 — User preferences.** Per-user defaults that apply across projects. Lower priority than project instructions.

**Layer 5 — Team/org conventions.** Shared standards (security policies, architectural patterns) for consistency across a team.

**Layer 6 — Extracted memories.** Context distilled from previous sessions and injected into the prompt. Covered in Ch 10. The key point: memories are prompt input, not a database the model queries at runtime.

**Layer 7 — Session-specific context.** Current task state, edited files, recent decisions. The most volatile layer and the most likely to cause cache instability.

**Layer 8 — Protocol schemas.** In multi-agent systems, the prompt defines the communication schema between agents. A coordinator's prompt documents the XML format workers use to report results. The prompt *is* the protocol layer — agents communicate through the conversational channel the model already understands. Changing the schema mid-session can break inter-agent communication.

### The Latch Pattern

Some assembly decisions are made once and frozen for the session, even if the underlying setting changes afterward. Re-evaluating a setting could change the prompt's byte representation, invalidating tens of thousands of cached tokens.

Latches reset only on explicit session-reset operations (clearing context or compacting). These are not cleanup commands — they are the mechanism for re-evaluating cached decisions.

The ordering principle follows: most stable content first (base instructions, tool definitions), most volatile content last (session context). This maximizes the cacheable prefix.

## Production Considerations

**Full prompt overrides replace, not extend.** Some systems let users supply a custom system prompt. This silently removes all default instructions, safety constraints, and behavioral guidelines. It is a replacement, not an addition.

**Not everything visible is model-visible.** Shell hints, UI decorations, and status indicators may be stripped before the model sees the prompt. What the user sees and what the model receives are not always the same.

**Prompt size dilutes attention.** Instructions buried in the middle of a 50,000-token prompt are more likely to be missed than the same instructions in a 5,000-token prompt. Position matters: beginning (positional attention) and end (recency) are strongest.

## Composability

- **Tool Use** (Ch 3): Tool definitions are assembled into the prompt. Changing the tool pool changes the prompt.
- **Session Lifecycle** (Ch 9): Latches tie prompt stability to session lifecycle.
- **Context Economics** (Ch 11): Prompt stability has direct cost implications.
- **Multi-Agent Coordination** (Ch 16): The prompt defines the inter-agent protocol. Prompt stability is a correctness concern, not just a cost concern.

## Common Mistakes

**Dumping volatile context into the system prompt.** The system prompt should be stable within a session. Use conversation messages (appended, not rewritten) for changing context.

**Changing the prompt frequently within a session.** Each change invalidates the cache. If context changes every turn, the cache hit rate drops to zero.

**Writing narrative instead of rules.** "This project is a web application built with React..." is less useful than "React 18, TypeScript strict, server in `src/server/`, tests use vitest."

**Ignoring assembly-cache interaction.** Unexpectedly high costs usually trace back to prompt instability. Understanding cache implications is a prerequisite for running agents economically.
