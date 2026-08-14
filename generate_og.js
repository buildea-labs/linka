const sharp = require('sharp');
const fs = require('fs');

async function createOgImage() {
  let svgString = fs.readFileSync('aplicacao-web/public/wordmark.svg', 'utf8');
  // Força as cores do modo escuro para o render do sharp
  svgString = svgString.replace('.wordmark-stroke { stroke: #102245; }', '.wordmark-stroke { stroke: #FFFFFF; }');
  svgString = svgString.replace('.wordmark-dot { fill: #E0701F; }', '.wordmark-dot { fill: #FF9552; }');
  
  await sharp({
    create: {
      width: 1200,
      height: 630,
      channels: 4,
      background: { r: 0, g: 0, b: 0, alpha: 1 }
    }
  })
  .composite([
    {
      input: await sharp(Buffer.from(svgString)).resize({ width: 600 }).toBuffer(),
      gravity: 'center'
    }
  ])
  .jpeg({ quality: 95 })
  .toFile('aplicacao-web/public/og-image.jpg');
  
  // Copia pro scratch pra mostrar pro usuario
  fs.copyFileSync('aplicacao-web/public/og-image.jpg', '/Users/giammattey/.gemini/antigravity/brain/d6431033-4616-463e-a82a-3f13f91e178f/scratch/og-image.jpg');
  console.log('OG image created!');
}

createOgImage().catch(console.error);
