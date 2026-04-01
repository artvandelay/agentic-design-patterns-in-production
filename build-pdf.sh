#!/bin/bash
set -e

BOOK_DIR="$(cd "$(dirname "$0")" && pwd)"
OUTPUT="$BOOK_DIR/Agentic-Design-Patterns-in-Production.pdf"

FRONT_COVER="$BOOK_DIR/cover_art/front-cover-portrait.png"
BACK_COVER="$BOOK_DIR/cover_art/back-cover-portrait.png"

CHAPTERS=(
  "$BOOK_DIR/00-introduction.md"
  "$BOOK_DIR/part-1-foundations/01-agent-loop.md"
  "$BOOK_DIR/part-1-foundations/02-prompt-assembly.md"
  "$BOOK_DIR/part-1-foundations/03-tool-use.md"
  "$BOOK_DIR/part-1-foundations/04-routing.md"
  "$BOOK_DIR/part-2-orchestration/05-prompt-chaining.md"
  "$BOOK_DIR/part-2-orchestration/06-parallelization.md"
  "$BOOK_DIR/part-2-orchestration/07-planning-decomposition.md"
  "$BOOK_DIR/part-2-orchestration/08-reflection-self-correction.md"
  "$BOOK_DIR/part-3-state-memory/09-session-lifecycle.md"
  "$BOOK_DIR/part-3-state-memory/10-memory-management.md"
  "$BOOK_DIR/part-3-state-memory/11-context-economics.md"
  "$BOOK_DIR/part-4-safety/12-permission-pipelines.md"
  "$BOOK_DIR/part-4-safety/13-human-in-the-loop.md"
  "$BOOK_DIR/part-4-safety/14-guardrails-safety.md"
  "$BOOK_DIR/part-4-safety/15-sandboxing-isolation.md"
  "$BOOK_DIR/part-5-production/16-multi-agent-coordination.md"
  "$BOOK_DIR/part-5-production/17-observability-evaluation.md"
  "$BOOK_DIR/part-5-production/18-extension-integration.md"
  "$BOOK_DIR/part-5-production/19-operating-agent-runtime.md"
  "$BOOK_DIR/epilogue.md"
  "$BOOK_DIR/appendices/a-glossary.md"
  "$BOOK_DIR/appendices/b-pattern-reference.md"
  "$BOOK_DIR/appendices/c-v1-to-v2.md"
  "$BOOK_DIR/appendices/d-references.md"
)

TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

# Build front cover page as LaTeX
cat > "$TEMP_DIR/front-cover.tex" << 'LATEX'
\documentclass[letterpaper]{article}
\usepackage[margin=0pt]{geometry}
\usepackage{graphicx}
\pagestyle{empty}
\begin{document}
\noindent\includegraphics[width=\paperwidth,height=\paperheight,keepaspectratio]{FRONT_COVER_PATH}
\end{document}
LATEX
sed -i '' "s|FRONT_COVER_PATH|$FRONT_COVER|g" "$TEMP_DIR/front-cover.tex"

# Build back cover page as LaTeX
cat > "$TEMP_DIR/back-cover.tex" << 'LATEX'
\documentclass[letterpaper]{article}
\usepackage[margin=0pt]{geometry}
\usepackage{graphicx}
\pagestyle{empty}
\begin{document}
\noindent\includegraphics[width=\paperwidth,height=\paperheight,keepaspectratio]{BACK_COVER_PATH}
\end{document}
LATEX
sed -i '' "s|BACK_COVER_PATH|$BACK_COVER|g" "$TEMP_DIR/back-cover.tex"

echo "Building front cover PDF..."
(cd "$TEMP_DIR" && pdflatex -interaction=nonstopmode front-cover.tex > /dev/null 2>&1)

echo "Building back cover PDF..."
(cd "$TEMP_DIR" && pdflatex -interaction=nonstopmode back-cover.tex > /dev/null 2>&1)

echo "Building book body PDF..."
pandoc "${CHAPTERS[@]}" \
  -o "$TEMP_DIR/body.pdf" \
  --pdf-engine=xelatex \
  -V geometry:margin=1in \
  -V fontsize=11pt \
  -V mainfont="Helvetica Neue" \
  -V monofont="Menlo" \
  -V linkcolor=black \
  -V urlcolor=black \
  -V toccolor=black \
  --toc \
  --toc-depth=2 \
  -V toc-title="Contents" \
  --highlight-style=kate \
  -V pagestyle=plain \
  -V header-includes='\usepackage{titlesec}\titleformat{\chapter}[display]{\normalfont\huge\bfseries}{}{0pt}{\Huge}\titlespacing*{\chapter}{0pt}{-20pt}{20pt}'

echo "Combining front cover + body + back cover..."

if command -v python3 &> /dev/null; then
  python3 -c "
from pypdf import PdfWriter
try:
    merger = PdfWriter()
    for pdf in ['$TEMP_DIR/front-cover.pdf', '$TEMP_DIR/body.pdf', '$TEMP_DIR/back-cover.pdf']:
        merger.append(pdf)
    merger.write('$OUTPUT')
    merger.close()
except Exception as e:
    print('Failed to merge with pypdf:', e)
"
else
  echo "No Python found. Copying body only."
  cp "$TEMP_DIR/body.pdf" "$OUTPUT"
fi

if [ -f "$OUTPUT" ]; then
    echo "Done: $OUTPUT"
    ls -lh "$OUTPUT"
else
    echo "Failed to create output PDF."
fi
