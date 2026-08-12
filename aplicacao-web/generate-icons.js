const sharp = require('sharp');
const fs = require('fs');
const path = require('path');

const ROOT_DIR = '/Users/giammattey/GitHub Projects/gmmattey/linka-speedtest';
const MASTER_DIR = path.join(ROOT_DIR, 'documentacao/design/design_system/assets/icons');
const PUBLIC_DIR = path.join(ROOT_DIR, 'aplicacao-web/public');
const IOS_DIR = path.join(ROOT_DIR, 'aplicativo-ios/LinkaApp/Sources/Assets.xcassets/AppIcon.appiconset');

const jobs = [
  // Web App SVG - direct copy
  {
    type: 'copy',
    src: path.join(MASTER_DIR, 'app-icon-1024.svg'),
    dest: path.join(PUBLIC_DIR, 'icon.svg'),
  },
  // Web App PWA Standard Icons
  {
    type: 'resize',
    src: path.join(MASTER_DIR, 'app-icon-1024.svg'),
    dest: path.join(PUBLIC_DIR, 'icon-192.png'),
    size: 192,
  },
  {
    type: 'resize',
    src: path.join(MASTER_DIR, 'app-icon-1024.svg'),
    dest: path.join(PUBLIC_DIR, 'icon-512.png'),
    size: 512,
  },
  // Web App PWA Maskable Icons
  {
    type: 'resize',
    src: path.join(MASTER_DIR, 'maskable-512.svg'),
    dest: path.join(PUBLIC_DIR, 'icon-maskable-192.png'),
    size: 192,
  },
  {
    type: 'resize',
    src: path.join(MASTER_DIR, 'maskable-512.svg'),
    dest: path.join(PUBLIC_DIR, 'icon-maskable-512.png'),
    size: 512,
  },
  // Apple Touch Icons
  {
    type: 'resize',
    src: path.join(MASTER_DIR, 'apple-touch-icon-180.svg'),
    dest: path.join(PUBLIC_DIR, 'apple-touch-icon.png'),
    size: 180,
  },
  {
    type: 'resize',
    src: path.join(MASTER_DIR, 'apple-touch-icon-180.svg'),
    dest: path.join(PUBLIC_DIR, 'touch-icon/ios/AppIcon@2x.png'),
    size: 120,
  },
  {
    type: 'resize',
    src: path.join(MASTER_DIR, 'apple-touch-icon-180.svg'),
    dest: path.join(PUBLIC_DIR, 'touch-icon/ios/AppIcon@2x~ipad.png'),
    size: 152,
  },
  {
    type: 'resize',
    src: path.join(MASTER_DIR, 'apple-touch-icon-180.svg'),
    dest: path.join(PUBLIC_DIR, 'touch-icon/ios/AppIcon-83.5@2x~ipad.png'),
    size: 167,
  },
  // Favicon (Web) - Fallback to 32x32 PNG but saved as .ico to fulfill index.html expectations
  {
    type: 'resize',
    src: path.join(MASTER_DIR, 'app-icon-1024.svg'),
    dest: path.join(PUBLIC_DIR, 'favicon.ico'),
    size: 32,
  },
  // iOS/macOS App Icons
  {
    type: 'resize',
    src: path.join(MASTER_DIR, 'app-icon-1024.svg'),
    dest: path.join(IOS_DIR, 'AppIcon-iOS.png'),
    size: 1024,
  },
  {
    type: 'resize',
    src: path.join(MASTER_DIR, 'macos-icon-1024.svg'),
    dest: path.join(IOS_DIR, 'AppIcon-Mac.png'),
    size: 1024,
  }
];

async function run() {
  for (const job of jobs) {
    if (job.type === 'copy') {
      console.log(`Copying ${job.dest}`);
      fs.copyFileSync(job.src, job.dest);
    } else if (job.type === 'resize') {
      console.log(`Resizing to ${job.size}x${job.size}: ${job.dest}`);
      const dir = path.dirname(job.dest);
      if (!fs.existsSync(dir)) {
        fs.mkdirSync(dir, { recursive: true });
      }
      await sharp(job.src)
        .resize(job.size, job.size)
        .png()
        .toFile(job.dest);
    }
  }
  console.log('All icons generated successfully!');
}

run().catch(err => {
  console.error(err);
  process.exit(1);
});
