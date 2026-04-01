# Cover Art & Brand Style Guide

This document outlines the visual identity and rendering guidelines for the *Agentic Patterns* book cover, particularly for digital presentation on GitHub, documentation sites, and social media.

## 1. The Core Aesthetic
The visual identity is inspired by classic, rigorous computer science and mathematics monographs (e.g., MIT Press, Cambridge University Press). It relies on **abstract geometry, vast negative space, and strict typography** rather than literal "AI" imagery.

## 2. Color Palette

*   **Background (Cream):** `#F9F8F6` — A warm, textured off-white that mimics high-quality academic paper.
*   **Primary Line Art & Text (Deep Charcoal):** `#2C2C2C` — Used for the main topological lines and all primary typography. Never use pure black (`#000000`).
*   **Secondary Line Art (Copper):** `#B87359` — Adds depth to the strange attractor visualization.
*   **Accent (Soft Coral/Peach):** `#E88D7D` — A subtle nod to Anthropic's brand palette. Used sparingly for the "golden thread" tracing the execution path, and can be used for hyperlinks or call-to-action buttons online.

## 3. Typography

The art does the heavy lifting, so the typography must be strictly structural and out of the way. Use **Swiss-style, grid-aligned typography**.

*   **Primary Typeface:** `Inter`, `Helvetica Neue`, or `Univers`.
*   **Title:** Left-aligned, top-left corner. Heavy/Bold weight, all caps with slight tracking (letter spacing).
*   **Subtitle:** Left-aligned, directly below the title. Regular or Italic weight, sentence case.
*   **Author Name:** Left-aligned, bottom-left (if not overlapping art) or top-left below the subtitle.

### Example Hierarchy:
**AGENTIC PATTERNS** (Inter Bold, 48pt, #2C2C2C)
*Engineering the LLM Runtime* (Inter Italic, 24pt, #2C2C2C)

## 4. GitHub & Web Rendering Guidelines

When displaying the cover art in a GitHub `README.md` or a documentation site, flat images on white backgrounds can look unfinished. 

Always render the cover with a **subtle drop shadow** and a **maximum width** to give it the physical presence of a book.

### Recommended HTML Snippet for GitHub README:

```html
<div align="center">
  <img src="./cover_art/front-cover.png" alt="Agentic Patterns Book Cover" width="400" style="box-shadow: 0 10px 30px rgba(0,0,0,0.15); border-radius: 2px;" />
  <br/>
  <em>Agentic Patterns: Engineering the LLM Runtime</em>
</div>
```

### Layout Rules:
1.  **Do not crop the image:** The asymmetrical negative space is intentional.
2.  **Do not overlay text in Markdown:** The text should be baked into the final image file using a design tool (Figma/Photoshop) before uploading the final asset. The provided `front-cover.png` is the *base artwork* ready for typography.
3.  **Pairing Front and Back:** If showing both covers side-by-side online, ensure the front cover is on the right and the back cover is on the left (as if the book is laid open face-down).

## 5. The Metaphor (For Marketing/Copy)
If you need to explain the cover art in a launch post:
> *The cover features a mathematical visualization of a strange attractor—a system of continuous feedback loops. It represents the core thesis of the book: modern AI agents are not magic brains; they are recursive systems of state, memory, and execution loops converging on a solution.*