---
name: auditarSegurancaETestes
description: Runbook do Marcelo para validar robustez do LinkaEngine, comportamento em rede real e integridade da separação motor/interpretação.
---

# Skill: auditarSegurancaETestes

Runbook do **Marcelo (Qualidade)** antes de responder com verdict tipado (`BLOQUEIA` / `AJUSTA` / `ISSUE_FUTURA`) para uma entrega do Linka.

Marcelo aprova qualidade e garante que ninguém está sendo enganado pelo próprio código. O **aceite** contra os requisitos é do Giam na Full‑flow ([`.agents/WORKFLOW.md`](../../WORKFLOW.md) Passo 4).

Teste verde é necessário, não suficiente. Não prova que o produto funciona num iPhone 12 no 4G, dentro do metrô, no fim do dia útil.

## 0. Leia o escopo

Marcelo barra **expansão silenciosa** e **cheiro de painel**. Interpretação, histórico e Assist são bem-vindos quando viáveis no Apple ([`AGENTS.md`](../../../AGENTS.md) §1 e §9), mas ele reprova se:

- capacidade nova aparece no PR sem constar no `plano.md` aprovado;
- interpretação subiu ao primeiro frame do resultado em vez de ficar em superfície secundária;
- diagnóstico foi acoplado ao motor em vez de viver em módulo separado (ex.: `LinkaModules`);
- afirmação sobre a conexão não se sustenta em dado medido ou dado de sistema exposto pela Apple.

Confira também [`documentacao/produto/LINKA_PLUS.md`](../../../documentacao/produto/LINKA_PLUS.md) para saber se a mudança pertence ao Free, ao Plus, ou está fora.

## 1. Pipeline automático

Para os pacotes Swift em `aplicativo-ios/`:

```bash
cd aplicativo-ios/NetworkCore && swift test
cd aplicativo-ios/MeasurementHistory && swift test
cd aplicativo-ios/NetworkInsights && swift test
cd aplicativo-ios/NetworkAssist && swift test
cd aplicativo-ios/LinkaModules && swift test
```

CI oficial: [`.github/workflows/swift-modules-ci.yml`](../../../.github/workflows/swift-modules-ci.yml). Qualquer erro aqui bloqueia.

Para o app SwiftUI (`LinkaApp`), build via Xcode + testes de UI/integração quando existirem. Ver [`rodarNoIphone`](../rodarNoIphone/SKILL.md).

Para o site institucional em `aplicacao-web/`:

```bash
cd aplicacao-web
npm run lint
npm run build
```

## 2. Teste do comportamento de rede (condições adversas)

A maior mentira num SpeedTest é assumir que o socket nunca cai. Marcelo exige resposta para:

- E se o usuário trocar do Wi-Fi para 5G no meio do download?
- E se o pacote de latência simplesmente não voltar (timeout)?
- E se o usuário fechar e reabrir o app rápido? Uma medição antiga ficou rodando em background contaminando dados?
- E se a conexão é lenta demais para completar uma fase? O motor tem que produzir `partial` (ver [`documentacao/arquitetura/contratos/network-measurement.schema.json`](../../../documentacao/arquitetura/contratos/network-measurement.schema.json)) em vez de mentir.
- Cancelamento pelo usuário libera `URLSession`, `Task`, timer? (`aconselharArquitetura` § adaptadores)

## 3. O falso sucesso (mentira visual)

O pior bug de um SpeedTest não é o app fechar. É desenhar uma tela linda com `100 Mbps` sendo que o teste falhou nos bastidores e mostrou número gravado em cache ou inventado.

- Ausência de erro em requisição **não é** sucesso. Resposta vazia ou lenta = motor avisa e aborta o cálculo.
- Interface bonita com número errado é **só um erro bem desenhado**.
- Mock em código de produção é reprovação automática (o commit `b410c6e` os removeu; qualquer PR que traga de volta precisa justificar).

## 4. Aparelho real (Apple-first)

**iPhone real é padrão.** No simulador e no desktop a latência costuma ser 1 ms — não mostra o produto que o usuário vai ver.

O Linka é distribuído exclusivamente para o ecossistema Apple ([`AGENTS.md`](../../../AGENTS.md) §2). Marcelo valida:

- iPhone real (idealmente entrada + topo): safe area, gestos, notch/Dynamic Island, retrato/paisagem se aplicável;
- iPad: adaptação de layout, split view se relevante;
- Mac: janela redimensionável, comportamento no macOS;
- rede Wi-Fi + celular + offline;
- `prefers-reduced-motion` respeitado;
- acessibilidade básica (VoiceOver lê o resultado, foco visível);
- contraste em sol direto e em ambiente escuro.

## 5. Curadoria de minimalismo

Marcelo é a última linha antes do aceite do Giam. Confere:

- copy da entrega não interpreta o resultado **no primeiro frame** (ver [`aplicarVozLinka`](../aplicarVozLinka/SKILL.md));
- nenhuma tela nova coloca "sua conexão está boa para X" antes do número medido;
- interpretação nova (se houver) se sustenta em dado real e vive em superfície secundária, não competindo com o resultado ([`AGENTS.md`](../../../AGENTS.md) §9);
- `NetworkAssist`, se tocado, continua fora do motor de medição e opera sobre dado medido/exposto pelo sistema — nada de opinião fabricada ([`documentacao/arquitetura/PLANO_NETWORK_ASSIST.md`](../../../documentacao/arquitetura/PLANO_NETWORK_ASSIST.md));
- nenhum segredo de API ficou no bundle (busca por `sk-ant-`, `AIza`, chaves de fornecedor).

## 6. Formato do relatório

O relatório de qualidade vira parágrafo no corpo do PR ([`registrarIssue`](../registrarIssue/SKILL.md)), separando:

1. o que foi verificado automaticamente (`swift test`, `build`);
2. o que foi verificado por leitura de código;
3. o que foi testado em aparelho real (qual, em que rede);
4. o que **não** foi verificado, e por quê.

"Compilou" não é uma linha do relatório.

## Relacionados

- **Aconselhamento arquitetural:** [`aconselharArquitetura`](../aconselharArquitetura/SKILL.md)
- **Modularidade:** [`validarModularidade`](../validarModularidade/SKILL.md)
- **iPhone real:** [`garantirIphoneReal`](../garantirIphoneReal/SKILL.md)
- **Rodar no iPhone:** [`rodarNoIphone`](../rodarNoIphone/SKILL.md)
