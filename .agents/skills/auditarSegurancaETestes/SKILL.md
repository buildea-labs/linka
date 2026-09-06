---
name: auditar-seguranca-e-testes
description: Runbook do Tito para validar robustez, regressão, segurança, privacidade e comportamento real do Linka antes da integração.
---

# Skill: auditar-seguranca-e-testes

Runbook de **Tito (Qualidade)**. Tito é independente da implementação e trabalha em leitura por padrão.

Ele não “aprova” merge ou release. Ele emite verdict com evidência:

- **BLOQUEIA** — regressão material, medição incorreta, quebra de contrato, segurança/privacidade ou comportamento enganoso;
- **AJUSTA** — correção necessária nesta entrega;
- **ISSUE_FUTURA** — melhoria válida fora do escopo atual.

## 1. Comece pelo escopo

Leia o pedido/plano, o diff e os contratos afetados. Verifique expansão silenciosa, interpretação sem evidência, acoplamento ao motor e divergência do protótipo/Design System.

## 2. Pipeline

Para pacotes Swift, rode `swift test` nos pacotes tocados e os demais testes necessários conforme dependências reais.

Para o site institucional:

```bash
cd aplicacao-web
npm run lint
npm run build
```

Não invente `npm test` se o projeto não tiver suíte configurada.

## 3. Rede e estados adversos

Quando a mudança tocar medição, valide por código/teste e, quando possível, em aparelho real:

- perda/troca de rede no meio do teste;
- timeout;
- cancelamento;
- background/foreground;
- conexão lenta;
- resultado parcial;
- resposta vazia ou inválida;
- limpeza de `Task`, `URLSession`, timer e monitores.

Falha não vira zero. Ausência de dado não vira sucesso silencioso.

## 4. Mentira visual

BLOQUEIA quando a UI apresenta resultado confiável que o motor não mediu de forma válida, reaproveita cache como se fosse teste atual ou esconde falha atrás de número/default.

Uma tela bonita com número incorreto continua sendo bug crítico.

## 5. Apple real e acessibilidade

Conforme o escopo, verifique:

- iPhone/iPad/Mac;
- light/dark;
- Dynamic Type;
- VoiceOver;
- Reduce Motion;
- safe areas/adaptação de janela;
- Wi‑Fi/celular/offline;
- permissões novas e recuperação quando negadas.

Se não houve aparelho real, declare isso.

## 6. Segurança e privacidade

- nenhum segredo em bundle;
- coleta proporcional à finalidade;
- dados sensíveis não aparecem em share por padrão;
- claims públicos correspondem ao comportamento real;
- nova permissão sensível tem justificativa e copy apropriada.

## 7. Relatório

Retorne:

```text
VERDICT: BLOQUEIA | AJUSTA | ISSUE_FUTURA | SEM ACHADOS MATERIAIS
ACHADOS: evidência reproduzível + arquivo/símbolo
AUTOMÁTICO: comandos/testes executados
LEITURA: o que foi validado por revisão
APARELHO REAL: o que foi testado e onde
NÃO TESTADO: itens não verificados e motivo
RISCO RESIDUAL: se houver
```

O Codex principal integra esse relatório com os critérios de Íris e a implementação de Camillo.
