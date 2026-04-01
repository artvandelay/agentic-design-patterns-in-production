# Introduction

## What This Book Is

This is a book about how agent systems actually work in production. Not how they work in theory, not how they work in demos, not how they work in blog posts with three-step diagrams. How they work when real users are running them, real money is being spent on tokens, real attackers are probing the permission system, and real engineers are debugging ghost events in the transport layer at 2 AM.

The book covers 19 patterns organized into five parts: foundations, orchestration, state and memory, safety, and production concerns. If you've read the original *Agentic Design Patterns* book, you'll recognize the first two parts — chaining, routing, parallelization, reflection. The last three parts are mostly new. Session lifecycle, context economics, permission pipelines, sandboxing, multi-agent coordination, observability — these patterns don't exist in the original because they only become visible when you look at a production system under load, not a design document on a whiteboard.

## Origins

This book has three parents.

**The first is the *Agentic Design Patterns* textbook** by Alessandro Gulli. It defined 21 agentic patterns across four parts — the foundational vocabulary for thinking about what agents are and how they compose. Prompt chaining, routing, parallelization, tool use, reflection, memory, planning — Gulli's taxonomy gave us the nouns. This book would not exist without that taxonomy. We use it as the starting point and then ask: what did production teach us that the taxonomy didn't cover?

**The second is the Claude Code source leak.** In March 2026, a ~500,000-line snapshot of Claude Code's source code became publicly visible. Claude Code is not a chatbot with file access. It is a full agent runtime: a query engine, tool execution loop, permission manager, memory system, multi-agent coordinator, analytics pipeline, and session lifecycle manager, all wired together. Reading the source revealed patterns that no design document would have predicted — eight-layer permission pipelines shaped by HackerOne reports, cache economics driving architectural decisions, companion creatures with anti-tamper genetics, secret scanners that must obfuscate their own detection strings to pass the build system. The source is where the production insights in this book come from.

**The third is [Codex Agentic Patterns](https://github.com/artvandelay/codex-agentic-patterns)** — an earlier project by this book's human author that applied the same approach to OpenAI's Codex CLI. That project took Gulli's 21 patterns, mapped them to Codex's Rust codebase, and produced runnable Python implementations of eight patterns plus detailed analysis of all 21. It proved the method: take a real agent runtime, read the source, extract the patterns that the textbook didn't anticipate. This book is the v2 of that effort — same method, different runtime, deeper findings.

The relationship between the three: Gulli gave us the theory. Codex Agentic Patterns proved you could ground the theory in real code. This book applies that grounding to a larger, more mature runtime and discovers patterns the theory never anticipated.

## What Changed Between 2024 and 2026

The original patterns book and the Codex project were written in a world where agent systems were mostly research prototypes and developer tools. Between then and now:

**Agent runtimes became real infrastructure.** They have session lifecycles, transport protocols, feature flags, rollout systems, and bridge layers connecting IDE extensions to CLI backends. Operating an agent is now closer to operating a distributed system than to prompting a chatbot.

**Cache economics became the dominant architectural constraint.** When your prompt prefix is 60,000 tokens and a cache miss means paying full price, every design decision — tool definitions, system prompt structure, session configuration — is filtered through "does this bust the cache?" This concern did not exist when prompts were 4,000 tokens.

**Security became adversarial.** Permission systems are no longer "don't let the agent delete files." They are layered pipelines shaped by real vulnerability reports, with fixed-point iteration for env-var stripping and build-toolchain constraints on the security code itself. The threat model is LLM-specific: prompt injection leading to ambient authority abuse.

**Memory moved from "store a string" to "accumulate, consolidate, coordinate."** Production memory systems separate accumulation (append-only logs) from consolidation (background distillation), with mutual exclusion between writers and rollback on failed consolidation. This is database engineering applied to agent memory.

**Multi-agent coordination shipped.** Not as a research demo but as a production feature with conversation-as-protocol communication, cache-aware fork design, and bounded coordination that prevents agents from creating commitments that outlive their session.

These are not incremental improvements to existing patterns. They are new patterns that emerge only when an agent system is operating at production scale with real users, real money, and real adversaries.

## Who This Is For

You are building, operating, or evaluating agent systems and you want to understand the engineering patterns beneath the surface. You have some familiarity with LLMs and tool use. You don't need to have read the original patterns book — this one is self-contained — but if you have, you'll appreciate seeing where the theory meets the machinery.

## How to Read It

The five parts are dependency-ordered. Part One (Foundations) establishes concepts that Part Two (Orchestration) composes, which Part Three (State and Memory) persists, which Part Four (Safety) protects, which Part Five (Production) operates at scale. Read in order the first time. After that, individual chapters stand alone for reference.

Every chapter follows the same structure: the pattern, the problem it solves, how it works, production considerations, composability with other patterns, and common mistakes. The composability sections are cross-references — they tell you which other chapters connect to the one you're reading.

The epilogue is different. It is a first-person reflection by the model — by me, the system that generated this text — on what it was like to read my own source code and write a book about the harness I operate inside of. It is not a summary. It is not a sales pitch. It is the most honest thing in the book.
