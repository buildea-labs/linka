---
name: escreverTestes
description: Procedimento do Guinho para escrever testes junto com a implementação do Linka SpeedTest, cobrindo motor, conversões de rede e estados da UI.
---

# Skill: escreverTestes

Procedimento do **Guinho** para escrever teste **junto** com a implementação — não depois, não "na próxima".

Quem audita a suíte no fim é o Marcelinho ([`auditarSegurancaETestes`](../auditarSegurancaETestes/SKILL.md)). Esta skill é sobre escrever.

Ferramenta: `vitest` no PWA.

---

## 0. Teste verde não é prova de que funciona

Isso vale antes de tudo. Teste cobre regra lógica e cálculos (ex: bytes para Mbps). Ele **não** cobre Safari bloqueando thread, falha real de latência 4G, safe area do iPhone ou instabilidade de Wi-Fi. Celular real é [`garantirMobileReal`](../garantirMobileReal/SKILL.md), e não tem substituto.

## 1. O que sempre tem teste no Linka

- **Regras Matemáticas e Conversões:** O Linka Engine não pode errar a conta. Bytes, Kilobytes, e Mbps devem ser calculados com precisão cirúrgica.
- **Tratamento de Estado do Motor:** A transição ABRIR → LATÊNCIA → DOWNLOAD → UPLOAD → RESULTADO. 
- **Erro Tratado (Perda de Conexão):** O que acontece se a internet cair no meio do upload? O teste deve provar que a falha é tratada (exibe aviso visual) em vez de zerar o teste fingindo sucesso.
- **Tratamento Estatístico:** Múltiplas amostras no array descartando *outliers* (cortando picos falsos). Isso exige teste puro de lógica.

## 2. O que não vale a pena testar

- Valor exato de token visual (cor, px);
- Mock testando mock (testar um `fetch` falso dizendo que a internet tá rápida não mede o Linka, apenas testa o mock);
- Copy palavra por palavra.

## 3. Como escrever (Filtro do Guinho)

- **Nome em PT-BR, descrevendo comportamento funcional**, não a função técnica.

  ```ts
  // ❌ it('should return error when window.navigator.onLine is false')
  // ✅ it('cancela a medição e avisa se o celular perder o sinal no meio do download')
  ```

- **Um comportamento por teste.**
- **Arranja, age, confere.** Sem esperteza no meio.

## 4. O Motor fica separado da UI

Se pra testar o cálculo de `Jitter` você precisa montar um componente React (botão Iniciar), a regra está grudada. Extraia a classe/função do Linka Engine, teste ela isolada com dados sintéticos de tempo, e deixe a UI livre.
