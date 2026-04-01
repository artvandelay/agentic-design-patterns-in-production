# Chapter 18: Extension and Integration

## The Pattern

An agent runtime becomes an integration platform when it exposes clean extension points for external systems, domain-specific capabilities, and knowledge sources. The design question shifts from "what should the agent do?" to "what should the agent be able to reach?" Extension architecture determines how much of the agent's capability is fixed versus composable.

## The Problem

A sealed agent — one that can only use its built-in tools — is limited to the capabilities its developers anticipated. Every new domain requires a new release. Every organization's internal tooling is invisible to the agent. The model may be capable of reasoning about a database schema or a deployment pipeline, but if it cannot reach those systems, the capability is theoretical.

The alternative is an agent that can be extended at runtime: connect it to a documentation system, an internal API, a design tool, a monitoring dashboard. The extension architecture makes this possible without modifying the agent's core.

## How It Works

### Extension Points as First-Class Architecture

The strongest extension architectures are designed from the start, not added after the fact. The pattern: define extension points as interfaces in the core architecture, ship public versions as no-ops, and implement full versions internally or through plugins.

A concrete example: a hook point in the query path that receives the current conversation state and can block, transform, or augment the query before it reaches the model. The public version returns "proceed" and renders nothing. The internal version can inject context, display UI, or redirect the query. The interface is identical — only the implementation differs.

This pattern has two properties:

1. **The extension point exists in the shipped binary.** It is not a hypothetical API that will be added later. The no-op stub proves the interface works and ensures the extension point is maintained across releases.
2. **External developers can implement the same interface.** The public no-op documents the contract. A plugin that implements the interface gets the same integration depth as the internal version.

### Protocol-Based Extension (MCP)

The Model Context Protocol (MCP) provides a standardized way to connect agents to external systems. An MCP server exposes tools, resources, and prompts through a defined protocol. The agent discovers available capabilities at runtime and can use them like built-in tools.

This is extension at the tool level: the agent's tool pool grows dynamically based on which MCP servers are connected. A documentation server adds search and retrieval tools. A database server adds query tools. A deployment server adds rollout and rollback tools.

The key property: the agent does not need to know about these systems at build time. The protocol handles discovery, capability negotiation, and invocation. The agent treats MCP tools the same as built-in tools — they appear in the tool definition block, are subject to the same permission pipeline (Ch 12), and participate in the same cache economics (Ch 11).

### Skills and Plugins

Skills are reusable instruction sets that teach the agent domain-specific behavior. Unlike tools (which provide capabilities), skills provide knowledge: how to use a particular framework, how to follow a team's conventions, how to interact with a specific API.

Skills are loaded into the prompt assembly pipeline (Ch 2) as additional context. They are not code — they are structured instructions that shape the agent's behavior for a specific domain. A skill for a testing framework teaches the agent the framework's conventions, common patterns, and pitfalls. A skill for an internal API teaches the agent the authentication flow, rate limits, and error handling.

Plugins extend the runtime itself — adding new tools, new UI elements, or new processing steps. The distinction from MCP: plugins run in-process and can modify the agent's behavior at a deeper level than tool-level extension.

### Knowledge Retrieval as Integration

Retrieval-augmented generation (RAG) is an integration pattern, not a standalone architecture. The agent connects to a knowledge source (vector index, document store, search API) through the same extension mechanism it uses for any other external system.

The retrieval tool:
1. Takes a query from the agent
2. Searches the external knowledge source
3. Returns relevant documents as tool output
4. The agent reasons about the retrieved documents in context

RAG earns a section here rather than a standalone chapter because the production insight is architectural: RAG is one kind of tool integration. The same extension architecture that enables database queries enables document retrieval. The same permission pipeline governs both. The same cache economics apply.

The production considerations specific to RAG: retrieval quality depends on the index (garbage in, garbage out), retrieved documents consume context tokens (Ch 11), and the agent must be able to distinguish between "the knowledge source doesn't have this information" and "the retrieval failed."

## Production Considerations

**Design extension points before you need them.** A no-op stub in the query path costs nothing and ensures the interface is maintained. Adding an extension point after the architecture has solidified is expensive.

**Treat MCP tools like built-in tools for security.** External tools are untrusted by default. They pass through the same permission pipeline and guardrails as built-in tools. An MCP server that provides a shell-execution tool should trigger the same permission checks as the built-in shell tool.

**Skills are prompt engineering at scale.** A well-written skill replaces dozens of per-session instructions. Invest in skills for domains the agent encounters repeatedly.

**RAG quality is index quality.** The agent's reasoning is only as good as the documents it retrieves. A poorly maintained index produces irrelevant context that wastes tokens and degrades output.

## Composability

- **Tool Use** (Ch 3): MCP tools extend the tool pool. They follow the same execution contract as built-in tools.
- **Prompt Assembly** (Ch 2): Skills and plugins feed into the prompt assembly pipeline as additional context layers.
- **Permission Pipelines** (Ch 12): External tools are subject to the same permission checks as internal tools.
- **Context Economics** (Ch 11): Every extension adds to the prompt. MCP tool definitions, skill instructions, and retrieved documents all consume tokens.
- **Guardrails** (Ch 14): External inputs from MCP servers, plugins, and retrieval systems are untrusted and must pass through input sanitization.

## Common Mistakes

**Extension as afterthought.** Adding extension points after the architecture is built. The interface is awkward, the integration is shallow, and the extension point is fragile across releases.

**Trusting external tools.** Treating MCP-provided tools as safe by default. External tools need the same permission and guardrail treatment as any untrusted input.

**Over-retrieving.** RAG that returns too many documents, consuming context tokens without improving output quality. Retrieve selectively and measure whether retrieved context actually improves results.

**Skills as documentation.** Writing skills that describe what a system does rather than instructing the agent how to use it. Skills should be operational — commands, patterns, constraints — not explanatory prose.
