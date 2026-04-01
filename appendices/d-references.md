# Appendix D: References and Further Reading

## Primary Sources

**Agentic Design Patterns Complete** — Alessandro Gulli. The foundational taxonomy of 21 agentic patterns. Defines the vocabulary this book builds on: chaining, routing, parallelization, tool use, reflection, memory, planning, multi-agent coordination, and more.

**Codex Agentic Patterns** — [github.com/artvandelay/codex-agentic-patterns](https://github.com/artvandelay/codex-agentic-patterns). The predecessor project that applied the same method to OpenAI's Codex CLI. 8 fully implemented patterns in Python, 21 analyzed from source. Proved the approach of grounding design patterns in production code.

**Claude Code source snapshot** (March 2026). ~500,000 lines of TypeScript comprising a full agent runtime. The production observations in this book are derived from analysis of this codebase. See `CHAPTER-MAP.md` for the specific mappings between source sections and chapters.

## Background Reading

**ReAct: Synergizing Reasoning and Acting in Language Models** — Yao et al., 2023. The foundational paper on interleaving reasoning and action in LLM agents. The agent loop (Ch 1) is a production implementation of the ReAct pattern.

**Toolformer: Language Models Can Teach Themselves to Use Tools** — Schick et al., 2023. Early work on training models to use tools. The tool use contract (Ch 3) is the runtime-side engineering that makes tool use work in production.

**Chain-of-Thought Prompting Elicits Reasoning in Large Language Models** — Wei et al., 2022. The reasoning step in the agent loop. Planning (Ch 7) and reflection (Ch 8) are structured applications of chain-of-thought at the system level.

**Retrieval-Augmented Generation for Knowledge-Intensive NLP Tasks** — Lewis et al., 2020. The original RAG paper. Ch 18 treats RAG as an integration pattern within the broader extension architecture.

**Model Context Protocol (MCP)** — Anthropic, 2024. The protocol standard for connecting agents to external tools and resources. Ch 18 covers MCP as the primary extension mechanism.

## Related Work

**LangChain** — [langchain.com](https://langchain.com). Framework for building LLM applications with chains, agents, and tool use. Implements many of the patterns in Parts 1 and 2 at the framework level.

**LangGraph** — [langchain-ai.github.io/langgraph](https://langchain-ai.github.io/langgraph/). Graph-based orchestration for agent workflows. Relevant to chaining (Ch 5), parallelization (Ch 6), and planning (Ch 7).

**CrewAI** — [crewai.com](https://crewai.com). Multi-agent framework implementing coordinator/worker patterns. Relevant to Ch 16.

**AutoGen** — Microsoft. Multi-agent conversation framework. Relevant to conversation-as-protocol coordination (Ch 16).

**OpenAI Agents SDK** — [github.com/openai/openai-agents-python](https://github.com/openai/openai-agents-python). OpenAI's agent framework with tool use, handoffs, and guardrails.

## On Agent Security

**OWASP Top 10 for LLM Applications** — OWASP, 2025. Covers prompt injection, insecure output handling, and other LLM-specific vulnerabilities. Relevant to Chs 12, 14, and 15.

**HackerOne Bug Bounty Reports** — Referenced indirectly throughout Ch 12. Real vulnerability reports shape production permission systems more than theoretical threat models.

## On Operating AI Systems

**Building LLM Applications for Production** — Chip Huyen, 2023. Practical engineering concerns for LLM-powered systems. Relevant to Part 5.

**Prompt Caching** — Anthropic, 2024. Documentation on prompt cache mechanics. The economic foundation for context economics (Ch 11), prefix sharing (Ch 6, 16), and latch patterns (Ch 9).
