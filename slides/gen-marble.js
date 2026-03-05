const sharp = require('sharp');
const path = require('path');

async function generateMarbleTexture() {
  const width = 1920;
  const height = 1080;
  
  // Create a dark marble-like SVG with organic veins
  const svg = `<svg xmlns="http://www.w3.org/2000/svg" width="${width}" height="${height}">
    <defs>
      <filter id="marble" x="0" y="0" width="100%" height="100%">
        <feTurbulence type="fractalNoise" baseFrequency="0.005 0.008" numOctaves="6" seed="42" result="noise"/>
        <feTurbulence type="fractalNoise" baseFrequency="0.02 0.015" numOctaves="4" seed="7" result="noise2"/>
        <feDisplacementMap in="noise" in2="noise2" scale="40" result="displaced"/>
        <feColorMatrix type="matrix" in="displaced" values="0.08 0 0 0 0.06  0 0.08 0 0 0.06  0 0 0.08 0 0.06  0 0 0 0.3 0" result="dark"/>
      </filter>
      <filter id="vein" x="0" y="0" width="100%" height="100%">
        <feTurbulence type="fractalNoise" baseFrequency="0.003 0.012" numOctaves="8" seed="15" result="veins"/>
        <feColorMatrix type="matrix" in="veins" values="0.15 0 0 0 0  0 0.15 0 0 0  0 0 0.15 0 0  0 0 0 0.6 0"/>
      </filter>
      <radialGradient id="vignette" cx="50%" cy="50%" r="70%">
        <stop offset="0%" stop-color="transparent"/>
        <stop offset="100%" stop-color="#000000" stop-opacity="0.4"/>
      </radialGradient>
    </defs>
    <!-- Base dark color -->
    <rect width="100%" height="100%" fill="#111111"/>
    <!-- Marble noise layer -->
    <rect width="100%" height="100%" filter="url(#marble)" opacity="1"/>
    <!-- Vein pattern -->
    <rect width="100%" height="100%" filter="url(#vein)" opacity="0.3"/>
    <!-- Subtle vignette -->
    <rect width="100%" height="100%" fill="url(#vignette)"/>
  </svg>`;

  const outputPath = path.join('C:\\repos\\new-grad-builders\\slides\\html', 'marble-bg.png');
  
  await sharp(Buffer.from(svg))
    .resize(width, height)
    .png({ quality: 90 })
    .toFile(outputPath);
  
  console.log('Generated marble texture:', outputPath);
  
  const stats = require('fs').statSync(outputPath);
  console.log('Size:', Math.round(stats.size / 1024), 'KB');
}

generateMarbleTexture().catch(console.error);
