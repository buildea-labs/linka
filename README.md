# LINKA SpeedTest

PWA standalone para medir velocidade e qualidade da conexão de internet, com diagnóstico simples para o usuário final.

## Objetivo

O LINKA SpeedTest não mostra apenas Mbps. Ele ajuda a interpretar se a conexão atual é adequada para jogos online, streaming, videochamadas e trabalho remoto.

Aplicação pública:

```text
https://linkaSpeedtestPwa.pages.dev/
```

## Funcionalidades

- Medição de download e upload
- Indicadores de resposta, oscilação e estabilidade
- Diagnóstico por tipo de uso
- Histórico local
- Comparação com o teste anterior
- Exportação em PDF
- Compartilhamento via Web Share API
- Tema claro e escuro
- Instalação como PWA

## Stack

- React
- TypeScript
- Vite
- Vitest
- Recharts
- jsPDF e html2canvas
- vite-plugin-pwa
- Cloudflare Pages

## Estrutura principal

```text
src/components/   Componentes reutilizáveis
src/hooks/        Hooks de medição e detecção
src/screens/      Telas principais
src/types/        Tipagens globais
src/utils/        Speedtest, diagnóstico, histórico e exportação
docs/             Documentação técnica e funcional
webapp/           Ex-repo linka-webapp, consolidado aqui em 2026-07-23 — app
                  próprio (build/deploy independentes), ver webapp/README.md
```

## Desenvolvimento

```bash
npm install
npm run dev
```

Para testar em outro aparelho na mesma rede:

```bash
npm run dev -- --host 0.0.0.0 --port 5173
```

## Validação

Antes de publicar:

```bash
npm run lint
npm run test
npm run build
```

Valide também, manualmente:

- início, execução e resultado do teste;
- histórico e comparação;
- instalação e atualização da PWA;
- tema claro e escuro;
- exportação e compartilhamento;
- comportamento offline;
- uso em Wi-Fi e rede móvel.

## Limitações

O teste mede a conexão do navegador até a internet. Ele não mede diretamente a velocidade contratada, o sinal óptico da fibra, a qualidade de outros cômodos ou o tráfego de todos os dispositivos da rede.

Uma única medição não prova descumprimento da operadora. Resultados devem ser repetidos em horários e condições diferentes.

## Privacidade

O aplicativo não exige login. O histórico é salvo localmente no navegador. Informações como IP público não devem ser expostas por padrão em relatórios ou compartilhamentos.

## Deploy

Configuração recomendada no Cloudflare Pages:

```text
Framework preset: Vite
Build command: npm run build
Build output directory: dist
```

## Status

Projeto funcional em manutenção. Pendências técnicas e regras detalhadas devem permanecer em `docs/`, evitando transformar o README em um documento gigante e difícil de manter.

## Licença

Ainda não definida.