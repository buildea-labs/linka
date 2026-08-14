// Gera public/og-image.jpg a partir de public/wordmark.svg.
// Rodar a partir da raiz do aplicacao-web/: `node scripts/generate-og.cjs`.
// .cjs porque o package.json declara "type": "module".

const sharp = require('sharp');
const fs = require('fs');
const path = require('path');

async function createOgImage() {
  const publicDir = path.resolve(__dirname, '..', 'public');
  const svgPath = path.join(publicDir, 'wordmark.svg');
  const outPath = path.join(publicDir, 'og-image.jpg');

  let svgString = fs.readFileSync(svgPath, 'utf8');
  // Força as cores do modo escuro para o render do sharp.
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
    .toFile(outPath);

  console.log('OG image created at', outPath);
}

createOgImage().catch((err) => {
  console.error(err);
  process.exit(1);
});
