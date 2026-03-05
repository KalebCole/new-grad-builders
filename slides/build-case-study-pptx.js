/**
 * Build script: Convert HTML slides to PowerPoint (.pptx)
 * Uses the html2pptx.js skill from the powerpoint agent skill.
 *
 * Usage: node slides/build-pptx.js
 * Output: slides/case-study.pptx
 */

const pptxgen = require('pptxgenjs');
const path = require('path');
const fs = require('fs');

const html2pptxPath = path.join(
  process.env.USERPROFILE,
  '.agents', 'skills', 'powerpoint', 'scripts', 'html2pptx.js'
);
const html2pptx = require(html2pptxPath);

const htmlDir = path.join(__dirname, 'case-study');
const outputFile = path.join(__dirname, 'case-study.pptx');

const slideDefinitions = [
  {
    file: '01-title.html',
    notes: 'Set the stage: "So earlier I showed you the stack — the VM, Copilot, OpenClaw. Now let me show you what I actually BUILT with it. This is a real case study, not a demo. Warts and all."\n\nTiming: ~30 seconds for the title. Let it land.'
  },
  {
    file: '02-problem.html',
    notes: '"So here\'s the problem. I\'m a new grad, I just moved to Seattle, and I need a car. Sounds simple, right?\n\nExcept here\'s what that actually looks like — I\'m burning money on a rental, I\'ve got 8 dealer threads going, I need insurance quotes for every candidate, and I\'m trying to compare 15 cars on total cost of ownership. All while working full-time.\n\nI was overwhelmed. Too many threads, too much research. Classic analysis paralysis."\n\nTiming: ~1 minute'
  },
  {
    file: '03-spec.html',
    notes: '"First thing: I wrote a detailed spec. Here\'s what I\'m looking for — AWD, under 50k miles, under $30k, sedan or SUV. The agent uses this as its search criteria across every platform."\n\nTiming: ~20 seconds. Quick slide.'
  },
  {
    file: '04-solution.html',
    notes: '"I built an AI agent — OpenClaw — running 24/7 on an Azure VM.\n\nIt periodically scans Cars.com, CarMax, and Carvana for new listings matching my spec. When it finds candidates, it extracts the VIN and fills out insurance quotes on Progressive automatically.\n\nThen it submits inquiry forms on the car sites. It monitors my inbox for dealer replies and drafts negotiation responses — enforcing my max budget and lowballing 15% on the OTD price right out of the gate.\n\nAnd it pings me when something needs my attention — a dealer won\'t budge, or it\'s time to schedule a test drive."\n\nTiming: ~1.5 minutes.'
  },
  {
    file: '05-video.html',
    notes: 'Live demo: Show the Gmail negotiation thread. Walk through the back-and-forth with a dealer — the lowball, the counter, the response delay strategy.\n\nTiming: ~1 minute.'
  },
  {
    file: '06-failures.html',
    notes: '"Okay here\'s the honest part. It doesn\'t work that well. And I think this is the most important slide.\n\nNothing works out of the box. You have to test everything."\n\nTiming: ~1 minute. The failures are the engaging part — lean into them.'
  },
  {
    file: '07-examples.html',
    notes: 'Show specific screenshots of failures — the email threading fail, the hybrid that wasn\'t a hybrid, the UTC timestamp issue. Let the evidence speak for itself.\n\nTiming: ~30 seconds.'
  },
  {
    file: '08-numbers.html',
    notes: '"So was it worth it? Here are the numbers.\n\n15+ candidates narrowed to 3 finalists. 8 active dealer leads managed simultaneously. 6 automated insurance quotes. And infinite lowball offers.\n\nThe agent found the car, quoted it, and started negotiating — while I was at work."\n\nTiming: ~30 seconds.'
  },
  {
    file: '09-closing.html',
    notes: '"That\'s the pitch. AI agents aren\'t just for work. They can run your life. And you can build one this afternoon."\n\nTiming: ~15 seconds. End strong. Let the last line hang.'
  }
];

async function build() {
  console.log('Building case-study.pptx...\n');

  const pptx = new pptxgen();
  pptx.layout = 'LAYOUT_16x9';
  pptx.author = 'Kaleb Cole';
  pptx.company = 'New Grad Builders';
  pptx.title = 'Case Study: OpenClaw Bought Me a Car';

  for (const def of slideDefinitions) {
    const htmlPath = path.join(htmlDir, def.file);

    if (!fs.existsSync(htmlPath)) {
      console.error(`  MISSING: ${def.file}`);
      process.exit(1);
    }

    try {
      console.log(`  Converting ${def.file}...`);
      const { slide } = await html2pptx(htmlPath, pptx);

      // Apply marble texture as slide background
      const marblePath = path.join(htmlDir, 'marble-bg.png');
      if (fs.existsSync(marblePath)) {
        slide.background = { path: marblePath };
      }

      if (def.notes) {
        slide.addNotes(def.notes);
      }

      console.log(`  ✓ ${def.file}`);
    } catch (err) {
      console.error(`  ✗ ${def.file}: ${err.message}`);
      process.exit(1);
    }
  }

  await pptx.writeFile({ fileName: outputFile });
  console.log(`\nDone! Output: ${outputFile}`);
}

build().catch(err => {
  console.error('Build failed:', err);
  process.exit(1);
});
