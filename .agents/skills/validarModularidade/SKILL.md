---
name: validarModularidade
description: Runbook do Marcelinho para detectar acoplamento, responsabilidades misturadas e duplicação de regra no código do Linka.
---

# Skill: validarModularidade

Ferramenta de revisão do **Marcelinho (Qualidade)** para impedir que o Linka vire um bloco impossível de mexer.

## 1. O que é monólito aqui

Não é simplesmente "arquivo grande".

Problemas reais:

- `View` SwiftUI que também conhece `URLSession` ou cálculo de bytes;
- regra de conversão (bytes → Mbps, latência média, jitter) duplicada em vários pacotes;
- cleanup de `URLSession`/`Task`/`Timer` sem dono claro — quem inicia é quem cancela;
- função com responsabilidades independentes que mudam por razões diferentes;
- `ObservableObject` que virou depósito de qualquer estado da tela;
- utilitário genérico que depende de tipo específico de feature (dependência invertida);
- pacote Swift impossível de testar sem montar o app inteiro (importação silenciosa de UI framework);
- pacote de motor (`NetworkCore`, `LinkaEngine`) importando `SwiftUI` — quebra imediata da fronteira Engine/UI.

Tamanho de arquivo é **sinal para olhar**, não sentença automática.

## 2. Heurística de tamanho

Ao encontrar arquivo novo ou modificado grande:

- acima de ~200 linhas: revisar coesão com atenção;
- acima de ~400 linhas: exigir justificativa explícita ou decomposição;
- exceção aceitável quando manter o invariante no mesmo lugar torna o código mais seguro e legível.

Exemplo válido: `FileMeasurementHistoryRepository` concentra escrita atômica, criação de diretório, tratamento de arquivo corrompido e migração de versão porque separar essas partes espalharia o invariante "toda persistência falha fechada".

A justificativa precisa falar de responsabilidade, não "não deu tempo".

## 3. Separação de camadas do Linka

Preferir:

- **`View` (SwiftUI)** apresenta e interage;
- **Adapter/ViewModel** cuida do ciclo de vida e converte pacote → estado observável;
- **Pacote de domínio** (`NetworkCore`, `MeasurementHistory`, `NetworkInsights`, `NetworkAssist`, `LinkaEngine`) calcula regra pura ou I/O específico, sem UI;
- **Contrato canônico** (`NetworkMeasurement` v1) é a única definição da medição.

Não criar camada vazia só para dizer que tem arquitetura limpa.

## 4. Dependências

Verifique direção:

- pacote de motor **não** importa `SwiftUI`/`UIKit`/`AppKit`;
- `LinkaApp` importa os pacotes de motor — nunca o contrário;
- `NetworkCore` é a base — os outros pacotes dependem dele, ele não depende de ninguém do produto;
- se cinco lugares precisam da mesma regra, procure o dono canônico antes de copiar (ver [`escreverAdaptadorNativo`](../escreverAdaptadorNativo/SKILL.md)).

## 5. Duplicação perigosa

Duplicação perigosa não é copiar 20 linhas — é duplicar **regra de negócio ou contrato**:

- fórmula de conversão de banda;
- definição do que é `complete` vs `partial` na medição;
- política de retenção do histórico;
- regra de agregação estatística (média, mediana, desvio padrão);
- schema do `NetworkMeasurement`.

Quando houver duas implementações inevitáveis (ex.: Swift do motor + JavaScript de um consumidor futuro), precisa existir schema JSON + fixtures + teste de paridade — o que já existe em [`documentacao/arquitetura/contratos/`](../../../documentacao/arquitetura/contratos/).

## 6. Escopo também é modularidade

Leia [`AGENTS.md`](../../../AGENTS.md) §1-2 e [`documentacao/produto/LINKA_PLUS.md`](../../../documentacao/produto/LINKA_PLUS.md).

Não aprove refatoração que, para "organizar melhor", começa a construir infraestrutura de diagnóstico, recomendação, análise Wi-Fi ou chatbot — que estão fora do escopo do Linka (são SignallQ).

Refatoração boa reduz risco da fatia atual. Não usa limpeza como desculpa para reabrir o que foi fechado.

**Remover código legado é o oposto disso e é bem-vindo** — mas em fatias, uma área por PR, sem se misturar com features novas. Ver o padrão dos PRs #33 e #34 (limpezas grandes, isoladas, com relatório de verificação).

## 7. Checklist de QA

- cada arquivo/tipo tem responsabilidade explicável em uma frase?
- regra canônica (medição, retenção, agregação) tem um dono?
- cleanup de `URLSession`/`Task`/`Timer` tem um dono?
- `View` conhece detalhes de motor sem necessidade?
- pacote de motor importa framework de UI? (deve ser NÃO)
- há abstração prematura para feature futura?
- teste consegue atingir a regra sem montar o app inteiro?
- arquivo grande tem justificativa de coesão?
- a mudança não está trazendo escopo SignallQ de volta?

Se a resposta ruim for "mas ficou em menos de 200 linhas", continua ruim.

## Relacionados

- **Arquitetura de módulo:** [`arquitetarModulo`](../arquitetarModulo/SKILL.md)
- **Aconselhamento arquitetural:** [`aconselharArquitetura`](../aconselharArquitetura/SKILL.md)
- **Adapter:** [`escreverAdaptadorNativo`](../escreverAdaptadorNativo/SKILL.md)
- **Auditoria final:** [`auditarSegurancaETestes`](../auditarSegurancaETestes/SKILL.md)
