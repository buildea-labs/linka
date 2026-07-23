import js from '@eslint/js'
import globals from 'globals'
import reactHooks from 'eslint-plugin-react-hooks'
import reactRefresh from 'eslint-plugin-react-refresh'
import tseslint from 'typescript-eslint'
import { defineConfig, globalIgnores } from 'eslint/config'

export default defineConfig([
  // webapp/ é o ex-repo linka-webapp, consolidado aqui em 2026-07-23 — app
  // standalone com seu próprio tsconfig/eslint. Ignorado aqui pra não colidir
  // com o parser do root (dois tsconfigRootDir candidatos = erro de parsing).
  globalIgnores(['dist', 'android/app/build', 'builds', '_android-toolchain', 'webapp']),
  {
    files: ['**/*.{ts,tsx}'],
    extends: [
      js.configs.recommended,
      tseslint.configs.recommended,
      reactHooks.configs.flat.recommended,
      reactRefresh.configs.vite,
    ],
    languageOptions: {
      globals: globals.browser,
    },
    rules: {
      // Convenção do projeto: prefixo `_` marca destructuring intencionalmente
      // não usado (ex.: props de interface compartilhada que a tela ignora).
      '@typescript-eslint/no-unused-vars': ['error', { argsIgnorePattern: '^_', varsIgnorePattern: '^_' }],
    },
  },
])
