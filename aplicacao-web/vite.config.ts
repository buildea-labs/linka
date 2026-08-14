import { defaultExclude, defineConfig } from 'vitest/config';
import react from '@vitejs/plugin-react';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';

// Versão do app lida do package.json no build (sem import-attribute para
// não depender de Node 21+). Exposta como `__APP_VERSION__` via Vite
// `define`. Consumida pelo accordion "Avançado" da ResultScreen.
const pkgPath = fileURLToPath(new URL('./package.json', import.meta.url));
const pkgVersion = JSON.parse(readFileSync(pkgPath, 'utf-8')).version as string;

export default defineConfig({
  define: {
    __APP_VERSION__: JSON.stringify(pkgVersion),
  },
  test: {
    environment: 'node',
    // webapp/ é o ex-repo linka-webapp (consolidado em 2026-07-23), app
    // standalone com sua própria suíte de testes — não roda junto da raiz.
    exclude: [...defaultExclude, 'webapp/**'],
  },
  plugins: [
    react()
  ],
});
