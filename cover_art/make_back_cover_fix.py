import os
from PIL import Image, ImageDraw, ImageFont

img_path = "/Users/jigar/LLM-apps/claude-code-copy/book/cover_art/Generated_image2.png"
img = Image.open(img_path)

width, height = img.size
target_w = 512
target_h = 768

# The attractor is on the left in Generated_image2.png.
# Let's crop the RIGHT side where it's mostly empty space so the text is legible.
crop_x = width - target_w - 50
img_cropped = img.crop((crop_x, 0, crop_x + target_w, target_h))

draw = ImageDraw.Draw(img_cropped)

try:
    font_body = ImageFont.truetype("/System/Library/Fonts/HelveticaNeue.ttc", 18)
    font_footer = ImageFont.truetype("/System/Library/Fonts/HelveticaNeue.ttc", 14)
except:
    font_body = ImageFont.load_default()
    font_footer = ImageFont.load_default()

charcoal = (44, 44, 44)
copper = (184, 115, 89)

text = """What happens when you read the source code 
of a production agent runtime and extract the 
patterns the textbook didn't cover.

19 patterns across 5 parts: from the agent loop 
to operating the runtime at scale. Session 
lifecycle. Cache economics. Permission pipelines 
shaped by real vulnerability reports. Memory 
systems with mutual exclusion. Multi-agent 
coordination through conversation. The 
engineering beneath the abstractions.

Three parents: Gulli's Agentic Design Patterns 
(the theory), Codex Agentic Patterns (the 
method), and a 500K-line source leak (the 
evidence)."""

margin_x = 50
margin_y = 250

# Draw the main text
draw.multiline_text((margin_x, margin_y), text, font=font_body, fill=charcoal, spacing=8)

# Calculate text height to place the line and footer properly
# A rough estimate for 15 lines of text at size 18 with spacing 8 is ~400px
# Let's use textbbox to get exact dimensions
bbox = draw.multiline_textbbox((margin_x, margin_y), text, font=font_body, spacing=8)
text_bottom = bbox[3]

line_y = text_bottom + 40
draw.line([(margin_x, line_y), (target_w - margin_x, line_y)], fill=copper, width=2)

footer = "github.com/artvandelay/agentic-design-patterns-in-production"
draw.text((margin_x, line_y + 20), footer, font=font_footer, fill=charcoal)

out_path = "/Users/jigar/LLM-apps/claude-code-copy/book/cover_art/back-cover-portrait.png"
img_cropped.save(out_path)
print(f"Saved to {out_path}")
