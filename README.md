# Agentic Design Patterns in Production

What happens when you read the source code of a production agent runtime and extract the patterns the textbook didn't cover.

## Origins

Three inputs produced this book:

1. **[Agentic Design Patterns](https://www.amazon.com/dp/B0F1YRMDQX)** by Alessandro Gulli — the foundational taxonomy of 21 agentic patterns
2. **The Claude Code source leak** (March 2026) — ~500K lines of a production agent runtime, revealing patterns that only emerge under real load, real money, and real adversaries
3. **[Codex Agentic Patterns](https://github.com/artvandelay/codex-agentic-patterns)** — an earlier project applying the same method to OpenAI's Codex CLI

## Reading Order

| # | File | Topic |
|---|------|-------|
| — | `00-introduction.md` | Origins, what changed, who this is for |
| **Part One: Foundations** | | |
| 1 | `part-1-foundations/01-agent-loop.md` | The minimal viable agent |
| 2 | `part-1-foundations/02-prompt-assembly.md` | Prompts as layered configuration |
| 3 | `part-1-foundations/03-tool-use.md` | The model-runtime contract |
| 4 | `part-1-foundations/04-routing.md` | Dispatching to the right place |
| **Part Two: Orchestration** | | |
| 5 | `part-2-orchestration/05-prompt-chaining.md` | Sequential multi-step workflows |
| 6 | `part-2-orchestration/06-parallelization.md` | Concurrent execution and fan-out |
| 7 | `part-2-orchestration/07-planning-decomposition.md` | Budget-aware plan-then-execute |
| 8 | `part-2-orchestration/08-reflection-self-correction.md` | Bounded self-correction |
| **Part Three: State and Memory** | | |
| 9 | `part-3-state-memory/09-session-lifecycle.md` | Sessions are not conversations |
| 10 | `part-3-state-memory/10-memory-management.md` | Accumulation and consolidation |
| 11 | `part-3-state-memory/11-context-economics.md` | Context as a scarce resource |
| **Part Four: Safety** | | |
| 12 | `part-4-safety/12-permission-pipelines.md` | Layered authorization |
| 13 | `part-4-safety/13-human-in-the-loop.md` | When to ask before acting |
| 14 | `part-4-safety/14-guardrails-safety.md` | Input/output integrity |
| 15 | `part-4-safety/15-sandboxing-isolation.md` | Execution boundaries |
| **Part Five: Production** | | |
| 16 | `part-5-production/16-multi-agent-coordination.md` | Coordinator/worker systems |
| 17 | `part-5-production/17-observability-evaluation.md` | The hidden economy after every turn |
| 18 | `part-5-production/18-extension-integration.md` | Connecting agents to real systems |
| 19 | `part-5-production/19-operating-agent-runtime.md` | The agent as infrastructure |
| — | `epilogue.md` | What I found when I read my own source code |

## Appendices

| | File | Topic |
|---|------|-------|
| A | `appendices/a-glossary.md` | Key terms |
| B | `appendices/b-pattern-reference.md` | All patterns, one line each |
| C | `appendices/c-v1-to-v2.md` | What changed and why |
| D | `appendices/d-references.md` | Sources and further reading |

## Principles

- **Tool-agnostic.** These patterns apply to any agent runtime. Examples use pseudocode.
- **Production-grounded.** Every chapter is anchored to real engineering observations, not theory.
- **Dependency-ordered.** Each Part builds on the one before it. Read in order the first time.
- **Three parents.** Theory (Gulli), method (Codex Agentic Patterns), source material (Claude Code).

## Chapter Map

See `CHAPTER-MAP.md` for the editorial backbone: each chapter mapped to the production observations that earned it a place in the book.
