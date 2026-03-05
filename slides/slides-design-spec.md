# Case Study Slides — Design Spec

Design specification for the **OpenClaw Bought Me a Car** case study deck (`case-study.pptx`).

## Build Pipeline

```
slides/case-study/*.html  →  html2pptx.js  →  case-study.pptx
```

```powershell
cd C:\repos\new-grad-builders
$env:NODE_PATH = (Resolve-Path "node_modules").Path
node slides/build-case-study-pptx.js
```

**Dependencies:** `pptxgenjs`, `playwright`, `sharp` (installed in `node_modules/`)
**Converter:** `~/.agents/skills/powerpoint/scripts/html2pptx.js`

## Design System

### Colors

| Token          | Hex       | Usage                              |
|----------------|-----------|------------------------------------|
| Background     | `#111111` | HTML fallback (marble texture covers this in PPTX) |
| Surface        | `#1A1A1A` | Cards, rows, content panels        |
| Border         | `#333333` | Dividers, placeholder dashed borders |
| Text primary   | `#FFFFFF` | Titles, body text, stat numbers    |
| Text secondary | `#999999` | Subtitles, metadata, learnings, quotes |
| Accent line    | `#999999` | Border-left on quotes, decorative lines |

**No color.** Strictly monochrome — white + gray only. No blue, green, orange, or any accent colors.

### Typography

| Element      | Font                              | Size  | Weight | Color     |
|--------------|-----------------------------------|-------|--------|-----------|
| Title (h1)   | Georgia, 'Times New Roman', serif | 28–40pt | Bold   | `#FFFFFF` |
| Subtitle     | Georgia, 'Times New Roman', serif | 16–18pt | Normal | `#999999` |
| Body / list  | Georgia, 'Times New Roman', serif | 14–16pt | Normal | `#FFFFFF` |
| Small / meta | Georgia, 'Times New Roman', serif | 10–12pt | Normal | `#999999` |
| Stat numbers | Georgia, 'Times New Roman', serif | 36pt  | Bold   | `#FFFFFF` |

### Background

- **Marble texture PNG** (`slides/case-study/marble-bg.png`) applied via PptxGenJS `slide.background` at build time
- Generated via `slides/gen-marble.js` — dark fractal noise, 1920×1080px
- HTML slides use flat `#111111` fallback (texture applied in build script, not CSS)

### Layout

- **Slide dimensions:** 720pt × 405pt (16:9)
- **Margins:** 40pt horizontal, 25–40pt vertical
- **Content approach:** Generous whitespace, fewer elements per slide
- **Split layouts:** Text left (~400–420pt), image placeholder right (~240–260pt)
- **Image placeholders:** `border: 1pt dashed #333333`, centered `<p>` text `[ screenshot ]` in `#333333`

## HTML Constraints (html2pptx)

These are hard requirements from the converter:

1. Body MUST be `width: 720pt; height: 405pt`
2. ALL text in `<p>`, `<h1>`–`<h6>`, `<ul>`, or `<ol>` — bare text in `<div>` is **silently dropped**
3. No CSS gradients — rasterize to PNG instead
4. Body requires `display: flex`
5. Web-safe fonts only: Georgia, Arial, Tahoma, Verdana, Times New Roman
6. `<div>` with background/border → PowerPoint shapes. Text tags do NOT support background/border
7. Content must not overflow body (build will fail with exact overflow measurements)

## Slide Inventory

| # | File | Title | Layout | Image Placeholder |
|---|------|-------|--------|-------------------|
| 1 | `01-title.html` | Case Study: OpenClaw Bought Me a Car | Centered, corner metadata | No |
| 2 | `02-problem.html` | The Problem | Split — bullets left, placeholder right | Yes (right) |
| 3 | `03-spec.html` | The Solution — Step 1 | Split — spec list left, placeholder right | Yes (right) |
| 4 | `04-solution.html` | The Solution | Split — numbered list left, placeholder right | Yes (right) |
| 5 | `05-video.html` | Live Demo | Centered — large video placeholder | Yes (center) |
| 6 | `06-failures.html` | Doesn't work out of the box | 5 rows — failure (white) / learning (gray) | No |
| 7 | `07-examples.html` | The Evidence | Centered — large screenshot placeholder | Yes (center) |
| 8 | `08-numbers.html` | The Numbers | 2×2 stat card grid + quote | No |
| 9 | `09-closing.html` | Let's build an agent this afternoon. | Centered CTA + accent line | No |

## Speaker Notes

All slides include speaker notes with talking points and timing cues. Defined in `slides/build-case-study-pptx.js` in the `slideDefinitions` array.

## Adding / Editing Slides

1. Create or edit the HTML file in `slides/case-study/`
2. Follow the design system tokens above
3. Use the common CSS template:
   ```css
   html { background: #111111; }
   body {
     width: 720pt; height: 405pt; margin: 0; padding: 0;
     background: #111111;
     font-family: Georgia, 'Times New Roman', serif;
     display: flex; flex-direction: column;
     color: #FFFFFF;
   }
   ```
4. Add the slide to `slideDefinitions` in `slides/build-case-study-pptx.js`
5. Run the build command
6. If build fails with overflow, reduce margins or font sizes

## File Structure

```
slides/
├── build-case-study-pptx.js          # Build script — HTML → PPTX
├── gen-marble.js           # Marble texture generator
├── case-study.md           # Original Marp markdown (legacy)
├── case-study.pptx      # Generated output
├── clippy.png              # Clippy image (Session 1 deck)
├── slides.md               # Session 1 Marp deck
└── html/
    ├── marble-bg.png       # Dark marble background texture
    ├── 01-title.html
    ├── 02-problem.html
    ├── 03-spec.html
    ├── 04-solution.html
    ├── 05-video.html
    ├── 06-failures.html
    ├── 07-examples.html
    ├── 08-numbers.html
    └── 09-closing.html
```
