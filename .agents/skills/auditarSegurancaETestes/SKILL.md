---
name: auditarSegurancaETestes
description: Procedimento do Marcelinho para validar robustez do Linka Engine, métricas reais em mobile e lidar com perdas de conexão simuladas.
---

# Skill: auditarSegurancaETestes

Runbook do **Marcelinho (Qualidade)** antes de aprovar a qualidade de uma entrega do Linka.

Marcelinho aprova qualidade e garante que não estamos sendo enganados pelo próprio código. O **aceite** contra os requisitos é do Giam.

Teste verde é necessário. Não é prova de que o produto funciona num iPhone 11 com 3G na chuva.

## 0. Leia o escopo
A QA barra expansão de escopo. Se alguém enfiar um "Diagnóstico de Ping DNS" no Linka (que só deve medir a banda), o Marcelinho barra, porque diagnóstico é coisa de SignallQ.

## 1. Pipeline automático
```bash
npm run typecheck
npm run lint
npm run test
npm run build
```
Qualquer erro aqui bloqueia.

## 2. Teste do comportamento de Rede (Condições Adversas)
A maior mentira num SpeedTest é assumir que o socket nunca cai. Marcelinho exige a resposta para:
- E se o usuário trocar do Wi-Fi pro 4G no meio do Download?
- E se o pacote de latência simplesmente nunca voltar (Timeout)?
- E se o usuário fechar e reabrir o app rápido? O teste antigo continuou rodando em background matando os dados dele?

## 3. O Falso Sucesso (Mentira Visual)
O pior bug de um SpeedTest não é o app fechar. É o app desenhar uma tela linda de sucesso com `100 Mbps` sendo que o teste falhou silenciosamente nos bastidores e mostrou um número gravado em cache ou inventado. 
- A ausência de erro em requisição NÃO é sucesso. Se a resposta veio vazia ou lenta, o motor precisa avisar e abortar o cálculo.
- Uma interface bonita com um número errado é SÓ UM ERRO BEM DESENHADO.

## 4. Celular Real (Apple-first)
**Celular real é padrão.** No desktop a internet geralmente é a cabo e a latência é 1ms. 
O Linka foi feito com mentalidade **Apple-first**.
- Testar massivamente no Safari iOS (iPhone, iPad).
- Respeitar a safe area.
- Garantir fluidez.
- Testar também no Chrome Android (como PWA).

Marcelinho é preciso. Nada de "Acho que a animação ficou legal", o report deve ser técnico e destrutivo.
