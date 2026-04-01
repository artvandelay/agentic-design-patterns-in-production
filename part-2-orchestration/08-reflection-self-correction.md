# Chapter 8: Reflection and Self-Correction

## The Pattern

Reflection is the agent evaluating its own output and deciding whether to revise. The model generates a result, examines it against some criterion (tests pass, output matches expectations, diff looks correct), and either accepts it or loops back to try again.

The production constraint: reflection has a cost, and unconstrained reflection becomes a compute sink. The system needs mechanisms to detect when reflection is producing returns versus spinning in place.

## The Problem

Without reflection, the agent produces its first attempt and moves on. For many tasks, the first attempt is good enough. For complex tasks — multi-file changes, nuanced reasoning, code that must pass tests — the first attempt often has errors that a second pass would catch.

Without *bounded* reflection, the agent can enter a verification loop: check output, find a minor issue, revise, check again, find another minor issue, revise, check again. Each cycle consumes tokens. The improvements shrink. The agent is perfecting details while burning budget that could be spent on the next task.

The challenge is getting both: reflection that catches real errors, and bounds that prevent runaway self-correction.

## How It Works

### The Reflection Cycle

```
Generate output
    │
    ▼
Evaluate against criterion
    │
    ├── Passes → accept, move on
    │
    └── Fails → diagnose, revise, re-evaluate
                    │
                    └── (bounded: max iterations or diminishing-returns check)
```

The criterion can be:

- **Test results**: Run the test suite. If tests fail, the output needs revision.
- **Diff review**: Examine the changes made. Do they match the intent? Are there unintended side effects?
- **Constraint checking**: Does the output satisfy the specified constraints (type-checks, lint, schema validation)?
- **Self-critique**: The model reviews its own output and identifies weaknesses. This is the weakest criterion because it relies on the same reasoning that produced the original output.

Test results and diff review are the strongest reflection signals because they provide external evidence. Self-critique is useful but should not be the sole mechanism.

### Diminishing-Returns Detection

Production systems detect when reflection is stalling. The mechanism: after several iterations, track the delta of tokens consumed per iteration. If two consecutive iterations each consume fewer than a threshold (~500 tokens), the system stops the reflection loop.

The logic: small token deltas mean the agent is making small changes — tweaking wording, adjusting minor details, adding qualifications. The large, structural improvements happened in earlier iterations. Continued iteration is producing diminishing returns.

This is an automated circuit breaker for the verification rabbit hole. Without it, an agent asked to "make this code perfect" could loop indefinitely, each iteration making a smaller improvement at the same per-iteration cost.

### Turn Caps

A complementary bound: hard limits on the number of reflection iterations. Even if diminishing-returns detection hasn't triggered, the system stops after N turns.

This appears in practice in sub-agents that perform a form of self-correction (like memory extraction — distilling a conversation into persistent memories). These sub-agents have explicit turn caps (e.g., 5 turns) that prevent them from entering verification loops, regardless of whether they believe they could improve their output with another pass.

The turn cap is a blunt instrument compared to diminishing-returns detection, but it provides a hard ceiling. The two mechanisms work together: diminishing-returns detection handles the typical case (smooth convergence), and the turn cap handles the pathological case (the agent believes every iteration is making meaningful progress when it isn't).

### Evidence-Based Reflection

The strongest reflection loops are evidence-based rather than judgment-based. The difference:

**Judgment-based**: "Review the code and see if it could be improved." The model applies its own judgment to its own output. This catches some errors but tends to produce style preferences rather than correctness improvements.

**Evidence-based**: "Run the tests and show me which ones fail." or "Show me the diff of what changed." The feedback signal is concrete and external. The model can reason about specific failures rather than general impressions.

Diff tracking — comparing the state before and after a change — converts reflection from "did it get better?" (subjective) to "what changed?" (objective). When the agent can see exactly which lines were added, removed, or modified, it can reason about whether those specific changes are correct rather than evaluating the whole output holistically.

## Production Considerations

**Default to bounded reflection.** Unbounded reflection loops are the most common source of unexpectedly high token consumption. Set both diminishing-returns detection and turn caps on any reflection loop.

**Use external criteria when possible.** Test results, type-checker output, lint results, and diffs are stronger feedback signals than self-critique. Self-critique is useful for tasks that lack testable criteria, but it should be supplemented with concrete evidence wherever available.

**Reflection cost scales with context size.** Each reflection iteration sends the full context (including previous iterations) to the model. As the conversation grows, each iteration costs more. Reflection on a 50,000-token context is 10x more expensive than reflection on a 5,000-token context, even if the revision itself is small.

## Composability

- **Prompt Chaining** (Ch 5): Reflection is the verify phase of the four-phase chain. It evaluates whether the execute phase produced correct results.
- **Planning** (Ch 7): Diminishing-returns detection applies to both planning and reflection — both are iterative processes that can stall.
- **Context Economics** (Ch 11): Reflection cost scales with context size. Compacting before a reflection phase can reduce per-iteration cost.
- **Observability** (Ch 17): Reflection loops should be observable — how many iterations, what triggered each revision, what the diminishing-returns detector measured.

## Common Mistakes

**Unbounded reflection.** "Keep improving until it's perfect" has no stopping condition. Set a turn cap and diminishing-returns threshold.

**Relying only on self-critique.** The model reviewing its own output catches some errors but misses others (it has the same blind spots that produced the original error). Use external criteria: tests, diffs, type-checkers.

**Reflecting on every output.** Not every task benefits from reflection. A simple file read doesn't need a verification pass. Reserve reflection for tasks where errors are costly or the first attempt is unreliable.

**Ignoring the cost of each iteration.** Each reflection iteration is a full API call with full context. Five iterations on a large context can cost more than the original generation. Budget accordingly.
