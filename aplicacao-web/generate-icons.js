import sharp from 'sharp';
import { copyFile, mkdir } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const WEB_DIR = path.dirname(fileURLToPath(import.meta.url));
const ROOT_DIR = path.resolve(WEB_DIR, '..');
const MASTER_DIR = path.join(ROOT_DIR, 'documentacao/design/design_system/assets/icons');
const PUBLIC_DIR = path.join(WEB_DIR, 'public');
const IOS_DIR = path.join(ROOT_DIR, 'aplicativo-ios/LinkaApp/Sources/Assets.xcassets/AppIcon.appiconset');
const IOS_TOUCH_DIR = path.join(PUBLIC_DIR, 'touch-icon/ios');

const iosTouchIcons = [
  ['AppIcon-20@2x.png', 40], ['AppIcon-20@3x.png', 60], ['AppIcon-20~ipad.png', 20], ['AppIcon-20@2x~ipad.png', 40],
  ['AppIcon-29.png', 29], ['AppIcon-29@2x.png', 58], ['AppIcon-29@3x.png', 87], ['AppIcon-29~ipad.png', 29], ['AppIcon-29@2x~ipad.png', 58],
  ['AppIcon-40@2x.png', 80], ['AppIcon-40@3x.png', 120], ['AppIcon-40~ipad.png', 40], ['AppIcon-40@2x~ipad.png', 80],
  ['AppIcon-60@2x~car.png', 120], ['AppIcon-60@3x~car.png', 180], ['AppIcon-83.5@2x~ipad.png', 167],
  ['AppIcon@2x.png', 120], ['AppIcon@3x.png', 180], ['AppIcon~ipad.png', 76], ['AppIcon@2x~ipad.png', 152],
  ['AppIcon~ios-marketing.png', 1024],
];

async function render(source, destination, size, { preserveTransparency = false } = {}) {
  await mkdir(path.dirname(destination), { recursive: true });
  const image = sharp(source).resize(size, size);
  if (!preserveTransparency) image.flatten({ background: '#050505' });
  await image.png().toFile(destination);
}

async function run() {
  const appIcon = path.join(MASTER_DIR, 'app-icon-1024.svg');
  const macIcon = path.join(MASTER_DIR, 'macos-icon-1024.svg');

  await copyFile(appIcon, path.join(PUBLIC_DIR, 'icon.svg'));
  await Promise.all([
    render(appIcon, path.join(PUBLIC_DIR, 'icon-192.png'), 192),
    render(appIcon, path.join(PUBLIC_DIR, 'icon-512.png'), 512),
    render(appIcon, path.join(PUBLIC_DIR, 'icon-maskable-192.png'), 192),
    render(appIcon, path.join(PUBLIC_DIR, 'icon-maskable-512.png'), 512),
    render(appIcon, path.join(PUBLIC_DIR, 'apple-touch-icon.png'), 180),
    render(appIcon, path.join(PUBLIC_DIR, 'favicon.ico'), 32),
    render(appIcon, path.join(IOS_DIR, 'AppIcon-iOS.png'), 1024),
    render(macIcon, path.join(IOS_DIR, 'AppIcon-Mac-1x.png'), 512, { preserveTransparency: true }),
    render(macIcon, path.join(IOS_DIR, 'AppIcon-Mac@2x.png'), 1024, { preserveTransparency: true }),
    ...iosTouchIcons.map(([name, size]) => render(appIcon, path.join(IOS_TOUCH_DIR, name), size)),
  ]);
}

run().catch((error) => {
  console.error(error);
  process.exit(1);
});
