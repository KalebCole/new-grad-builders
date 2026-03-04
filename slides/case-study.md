---
marp: true
theme: default
paginate: true
style: |
  /* "Windows XP Luna MAX" — Bliss wallpaper + XP chrome */
  section {
    font-family: 'Tahoma', 'Segoe UI', Geneva, Verdana, sans-serif;
    color: #000000;
    padding: 20px;
    border: 18px solid transparent;
    background:
      linear-gradient(#ece9d8, #ece9d8) padding-box,
      linear-gradient(180deg, 
        #1a5bcc 0%, #2e7ae6 6%, #4a99f5 12%, 
        #78b9f2 18%, #87ceeb 25%, #9dd5ec 32%,
        #6db86b 45%, #4da84a 55%, #3d8c3a 65%, 
        #358032 75%, #2d7029 90%, #256524 100%) border-box;
    box-shadow:
      inset 2px 2px 0 #ffffff,
      inset -2px -2px 0 #808080,
      3px 3px 10px rgba(0,0,0,0.4);
  }
  section > * {
    margin-left: 10px;
    margin-right: 10px;
  }
  h1 {
    font-size: 1.8em;
    font-weight: 700;
    color: #ffffff;
    background: linear-gradient(180deg, 
      #0997ff 0%, #0763e3 15%, #0654d4 30%, 
      #044ec0 50%, #0654d4 70%, #0763e3 85%, #0997ff 100%);
    margin: -20px -20px 16px -20px;
    padding: 8px 20px 8px 20px;
    border-radius: 9px 9px 0 0;
    text-shadow: 1px 1px 3px rgba(0,0,0,0.6);
    border-bottom: 2px solid #003399;
  }
  h2 {
    font-size: 1.5em;
    font-weight: 700;
    color: #ffffff;
    background: linear-gradient(180deg, 
      #0997ff 0%, #0763e3 15%, #0654d4 30%, 
      #044ec0 50%, #0654d4 70%, #0763e3 85%, #0997ff 100%);
    margin: -20px -20px 16px -20px;
    padding: 8px 20px;
    border-radius: 9px 9px 0 0;
    text-shadow: 1px 1px 3px rgba(0,0,0,0.6);
    border-bottom: 2px solid #003399;
  }
  h3 {
    color: #003399;
    font-size: 1.15em;
    font-weight: 700;
  }
  code {
    background-color: #ffffff;
    color: #003399;
    padding: 2px 6px;
    border-radius: 0;
    font-family: 'Lucida Console', 'Consolas', monospace;
    font-size: 0.8em;
    border: 2px inset #aca899;
  }
  pre {
    background-color: #ffffff;
    border: 2px inset #aca899;
    border-radius: 0;
    padding: 10px;
    margin: 8px 0;
  }
  pre code {
    background-color: transparent;
    border: none;
    color: #000000;
  }
  a { color: #0066cc; text-decoration: underline; }
  strong { color: #003399; font-weight: 700; }
  blockquote {
    border: none;
    padding: 10px 14px;
    color: #003399;
    background: linear-gradient(180deg, #d6e5f5 0%, #c1d9f1 50%, #b0cde8 100%);
    border-radius: 6px;
    border-left: 4px solid #0054e3;
    font-style: normal;
    font-size: 0.9em;
    box-shadow: 1px 1px 3px rgba(0,0,0,0.15);
    margin: 10px 0;
  }
  table { 
    font-size: 0.82em; 
    width: 100%; 
    border-collapse: collapse;
    border: 2px inset #aca899;
  }
  table th {
    background: linear-gradient(180deg, #ffffff 0%, #ece9d8 50%, #d6d2c2 100%);
    color: #000000;
    padding: 6px 10px;
    text-align: left;
    font-weight: 700;
    border-right: 1px solid #aca899;
    border-bottom: 2px solid #aca899;
  }
  table td {
    background-color: #ffffff;
    color: #000000;
    border-bottom: 1px solid #ece9d8;
    border-right: 1px solid #f0ede4;
    padding: 5px 10px;
  }
  table tr:nth-child(even) td {
    background-color: #f0f0f0;
  }
  ul, ol { 
    line-height: 1.7; 
    color: #000000;
    font-size: 0.95em;
  }
  li::marker { color: #0054e3; }
  section::after {
    color: #ffffff;
    font-size: 0.65em;
    z-index: 2;
    text-shadow: 1px 1px 1px rgba(0,0,0,0.5);
  }
  em { color: #333333; }
  section footer {
    position: absolute;
    bottom: 24px;
    right: 24px;
    left: auto !important;
    z-index: 10;
    font-size: 0;
    background: transparent;
    border: none;
    padding: 0;
    margin: 0;
    color: transparent;
    width: auto;
  }
  section footer img {
    height: 120px;
    width: auto;
    filter: drop-shadow(2px 2px 4px rgba(0,0,0,0.3));
  }
  .emoji-big { font-size: 1.4em; }
  .failure-item { margin-bottom: 4px; }
---

<!-- footer: '<img src="clippy.png" alt="Clippy">' -->

# 🚗 Case Study: OpenClaw Bought Me a Car

**How an AI agent automated car hunting — inventory scanning, insurance quoting, dealer outreach, and email negotiation**

Kaleb Cole | New Grad Builders Session 1

<!--
Set the stage: "So earlier I showed you the stack — the VM, Copilot, OpenClaw. Now let me show you what I actually BUILT with it. This is a real case study, not a demo. Warts and all."

Timing: ~30 seconds for the title. Let it land.
-->

---

## The Problem

### New grad + Seattle + no car = pain

- 💸 Burning money on a rental car every week
- 📱 Hours scrolling Cars.com, CarMax, Carvana — hundreds of listings
- 💬 **8 active dealer threads** going simultaneously
- 📋 Insurance quotes needed for every candidate car
- 🧮 Out-the-door prices, total cost of ownership, comparing 15+ candidates
- 💼 All while working full-time at Microsoft

> *Classic analysis paralysis. Too many threads, too much research, not enough hours.*

<!-- 📸 TODO: Add screenshot of Cars.com search results / browser tabs chaos -->

<!--
"So here's the problem. I'm a new grad, I just moved to Seattle, and I need a car. Sounds simple, right?

Except here's what that actually looks like — I'm burning money on a rental, I've got 8 dealer threads going, I need insurance quotes for every candidate, and I'm trying to compare 15 cars on total cost of ownership. All while working full-time.

I was overwhelmed. Too many threads, too much research. Classic analysis paralysis."

Timing: ~1 minute
-->

---

## The Solution — OpenClaw Does It

### AI agent running 24/7 on a $10/month Azure VM

**1. Automated Inventory Scanning**
- Searches Cars.com, CarMax, Carvana on a cron job (AWD, <50k mi, <$30k)
- Needed a **headed browser** — headless got blocked by car sites
- **Captcha bypass** via open-source solver ([capsolver](https://github.com/AIO-SUSPENDED/FunCaptcha-Solver))

**2. Automatic Insurance Quotes**
- Navigates Progressive's website, fills the entire quote form
- Self-healing selectors — adapts when the DOM changes

**3. Dealer Outreach & Email Negotiation**
- Submits inquiry forms on Cars.com for approved listings
- Monitors Gmail → drafts replies with strategy:
  - 15% lowball · distance leverage for Oregon cars
  - 15-min response delay · business hours only · always reply in-thread
- **Everything requires my approval** before sending

<!-- 📸 TODO: Add Telegram screenshot showing agent notifications -->
<!-- 📸 TODO: Add email screenshot showing negotiation thread -->

<!--
"I built an AI agent — OpenClaw — running 24/7 on a $10/month Azure VM.

It does five things. First, automated inventory scanning. It searches Cars.com, CarMax, and Carvana on a cron job. Here's the first lesson — headless browsers don't work. Car sites block them. You need a headed browser. And then they throw CAPTCHAs at you, so I had to find an open-source CAPTCHA solver.

Second, automatic insurance quotes. It navigates Progressive's website and fills out the entire quote form. Self-healing selectors so it adapts when the DOM changes.

Third — and this is the fun one — dealer outreach and email negotiation. It submits inquiry forms, monitors my Gmail, and drafts replies with a strategy. 15% lowball, leverage distance for Oregon cars, 15-minute response delay so I don't look desperate, business hours only, and always reply in the same thread. Everything requires my approval before sending."

Timing: ~1.5 minutes. This is the meat — take your time here.
-->

---

## The Honest Part — It Doesn't Work That Well

### Nothing works out of the box. You have to test everything.

| ❌ Failure | 💡 What I Learned |
|-----------|-------------------|
| Reached out to 3 dealers about "hybrids" that weren't hybrids | Don't trust search filters — add a visual verification gate |
| **Sent fresh emails instead of in-thread** — lost leads because dealers ignored them | Email threading is harder than it sounds — test with real recipients |
| Misread dealer email — quote was in PDF attachment, agent only read the body | Parse attachments, not just body text |
| Headless browser got blocked by every car site | Use a headed browser + CAPTCHA solver |
| Reported timestamps in UTC instead of Pacific | Small bugs erode trust fast |

### Key Takeaways
1. **AI agents need guardrails** — mandatory verification gate before any outreach
2. **LESSONS.md is the most important file** in the whole repo
3. **Agent is best at tedious stuff** (scanning, quoting, drafting) — worst at judgment calls
4. **Human in the loop** for decisions that matter — goal isn't full autonomy, it's making the boring parts disappear

<!-- 📸 TODO: Add screenshot of the email threading fail -->
<!-- 📸 TODO: Add screenshot of the "hybrid" that wasn't a hybrid -->

<!--
"Okay here's the honest part. It doesn't work that well. And I think this is the most important slide.

Nothing works out of the box. You have to test everything. Let me give you the highlight reel of failures.

I reached out to 3 dealers about hybrids that weren't hybrids. The agent trusted search filters without checking the listing photos.

The email one was funny — and painful. It sent FRESH emails instead of replying in-thread. Dealers just ignored them. I lost actual leads because of that. Email threading is harder than you think.

It misread a dealer email because the quote was in a PDF attachment and the agent only read the body. Asked them to resend. Embarrassing.

Headless browser got blocked by every car site. Had to switch to a headed browser AND add a CAPTCHA solver.

And my favorite: it reported all timestamps in UTC instead of Pacific time. The agent told me a dealer responded at 3 AM. They didn't. Small bugs erode trust fast.

Key takeaway: the most important file in the whole repo is LESSONS.md. Every failure goes in there. The agent reads it every time it starts. That's how it gets less dumb over time."

Timing: ~1 minute. The failures are the engaging part — lean into them.
-->

---

## The Numbers

### Was it worth it? Yeah.

| Metric | Result |
|--------|--------|
| Candidates scanned | **15+** narrowed to 3 finalists |
| Active dealer leads | **8** managed simultaneously |
| Automated insurance quotes | **6** via Progressive |
| Hours saved | **20+** in scrolling, emailing, comparing |
| Compute cost | **$10/month** |
| Current status | Negotiating **Kia EV6 Wind at $22k**, $155/mo insurance |

> *Agent found it, quoted it, and started negotiating — before I woke up.*

### The pitch

AI agents aren't just for work. They can run your life.
**And you can build one this afternoon.**

<!-- 📸 TODO: Add screenshot of the final car listing or Telegram notification -->

<!--
"So was it worth it? Here are the numbers.

15+ candidates narrowed to 3 finalists. 8 active dealer leads managed simultaneously — I could not have done that manually. 6 automated insurance quotes. Over 20 hours saved in scrolling, emailing, and comparing. All for $10 a month in compute.

Right now I'm negotiating a Kia EV6 Wind at $22k with $155/month insurance. The agent found it, quoted it, and started negotiating before I woke up.

That's the pitch. AI agents aren't just for work. They can run your life. And you can build one this afternoon."

Timing: ~30 seconds. End strong. Let the last line hang.
-->
