# Documentacao Funcional do Sistema

## Objetivo

O linka WebApp mede a qualidade percebida da conexao do usuario e traduz o resultado em linguagem pratica.

## Fluxo Principal

1. Usuario inicia o teste.
2. App mede latencia, download, upload, jitter e perda estimada.
3. Resultado e classificado por perfis de uso.
4. Historico local e atualizado.
5. Usuario pode revisar detalhes, comparar tendencias e compartilhar/exportar resultado.

## Telas

- Home
- SpeedTest
- Running
- Result
- History
- Explore/Ajustes
- DNS Benchmark e guia DNS
- Local Wi-Fi
- Local Network
- Fibra
- Pulse
- Onboarding

## Limitacoes Web Explicitas

O PWA puro nao acessa dados nativos de radio, Wi-Fi, rede local ou modem. Nesses casos, a interface deve mostrar estado indisponivel, sem bloquear o speedtest.

## Persistencia

O historico e preferencias ficam em armazenamento local do navegador.

## Aceite Funcional

- Fluxo `inicio -> medicao -> resultado -> historico` funciona.
- Resultado apresenta diagnostico compreensivel.
- Recursos indisponiveis no navegador nao geram erro.
- PWA instala e atualiza corretamente.
