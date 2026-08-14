# AGENTS.md — autoridade do Linka SpeedTest

Este arquivo é a **autoridade única de governança** do repositório `linka-speedtest`.

`CLAUDE.md` deve conter somente `@AGENTS.md`. Não existe segunda governança escondida, não existe modo Codex-only e nenhuma documentação legada pode sobrepor este arquivo.

---

## 1. O que é o Linka

**Linka é um SpeedTest minimalista, eficiente e visualmente refinado, Apple-first e também disponível na Web.**

Ele existe para fazer uma coisa muito bem:

> **medir a qualidade da conexão e apresentar o resultado de forma imediata, clara e bonita.**

O fluxo principal é deliberadamente simples:

```text
ABRIR → MEDIR → MOSTRAR RESULTADO → REPETIR
```

O usuário não escolhe modo de teste antes de começar. O teste inicia automaticamente.

Minimalismo não significa motor simples: a complexidade técnica deve ficar por baixo da interface.

### Fronteira com o SignallQ

- **Linka mede.**
- **SignallQ interpreta, diagnostica e orienta.**

Diagnóstico avançado, recomendações, central de ferramentas, análise de Wi‑Fi, modem, fibra, dispositivos, contrato, chatbot e experiências equivalentes pertencem ao SignallQ, não ao Linka.

Uma feature nova só entra no Linka se melhorar diretamente a experiência ou a confiabilidade de medir a conexão.

---

## 2. Plataformas e direção técnica

O produto tem duas frentes oficiais:

### Web

- React + TypeScript + Vite.
- **Apenas página de marketing (Landing Page)** adaptativa para desktop e mobile. Não roda teste de velocidade real na web.
- O objetivo exclusivo da web é apresentar as funcionalidades e direcionar o usuário para o app iOS.

### Apple (Plataforma Exclusiva do Produto)

- iPhone, iPad e Mac são o único destino do produto.
- **Não está prevista versão para Android.**
- A experiência deve parecer nativa do ecossistema Apple.

### Linka Engine

O motor é uma capacidade separada da interface.

Ele pode alimentar Linka SpeedTest, SignallQ, SignallQ PRO e SignallQ Agente, mas a UI do Linka continua deliberadamente mínima.

Não reimplemente ou simule o motor apenas para reproduzir um protótipo visual. O comportamento real de medição vence mocks e demos.

---

## 3. Fontes canônicas e precedência

Em caso de conflito, use esta ordem:

1. **Pedido explícito do dono do produto na sessão atual.**
2. **Comportamento real do código e testes.** Não alegue capacidade que não existe.
3. **Protótipo canônico do novo Linka** em `documentacao/design/prototipo/` para fluxo, geometria e aparência.
4. **Design System do novo Linka** em `documentacao/design/design_system/` para tokens, componentes, tipografia, cores, espaçamento e motion.
5. **Este `AGENTS.md`** para governança, papéis e forma de trabalho.
6. **`.agents/WORKFLOW.md`** para a esteira operacional da squad.
7. Demais documentação atual compatível com a nova visão.

Material histórico, legado Android, documentação antiga de Material Design 3, antigo PWA e antigas estruturas multiagente são contexto histórico, não autoridade de produto.

Se uma documentação antiga contradizer o novo Linka, **a documentação antiga perde**.

---

## 4. A Squad Linka

A squad mantém os mesmos personagens e relações humanas do Auê, agora atuando no Linka.

| Agente | Papel no Linka |
|---|---|
| **Giam** | **Produto, experiência e direção.** Conhece telecom por trabalhar com atendimento, reparo e produtos digitais. Define escopo, UX, UI, copy, arquitetura de produto, prioridade e aceite final. Sua principal obrigação é impedir que o Linka volte a virar um mini-SignallQ. |
| **Guinho** | **Implementação.** Constrói o que foi decidido, abre branch/PR quando aplicável, escreve código e testes. Pode questionar complexidade desnecessária, mas não amplia escopo sozinho. |
| **Marcelinho** | **Qualidade.** Tenta quebrar o produto e o motor: typecheck, lint, testes, build, acessibilidade, fidelidade ao protótipo, estados ruins de rede e regressões. Não aprova a própria implementação. |
| **Camillo** | **Arquitetura e proteção do motor.** Tem história com o produto desde quando o SignallQ ainda era Linka. Revisa decisões que tocam medição, contratos, separação UI/engine, confiabilidade e evolução de longo prazo. |

Luiz é o dono do produto e tem a decisão final de publicação, custo, exclusão, monetização e mudança estratégica.

---

## 5. Ordem de atuação

```text
GIAM decide e planeja
  → GUINHO implementa
    → CAMILLO revisa quando motor/arquitetura forem afetados
      → MARCELINHO tenta quebrar e valida qualidade
        → GIAM dá aceite contra o requisito
          → LUIZ aprova decisão final quando necessário
```

Regras:

- Não implemente antes de entender o problema e o impacto no produto.
- Não crie feature só porque é tecnicamente possível.
- Mudança visual relevante deve ser confrontada com protótipo e Design System.
- Mudança no motor exige revisão de contratos, testes e impacto nos consumidores.
- Um agente não declara a própria entrega aprovada por outro agente sem revisão real.

A esteira detalhada vive em `.agents/WORKFLOW.md`.

---

## 6. Princípios obrigatórios de produto

### Resultado é protagonista

O número medido vem antes de logo, menu, texto, anúncio, gráfico ou diagnóstico.

### Divulgação progressiva

Mostre primeiro o essencial. Ping, jitter, servidor e outros detalhes aparecem somente quando ajudam e preferencialmente sob expansão/detalhes.

### Sem fricção antes da medição

Por padrão:

- sem login;
- sem onboarding obrigatório;
- sem formulário;
- sem seleção de modo;
- sem seleção manual de servidor para usuário comum;
- início automático.

### Apple-first, não Apple-only

A Web continua oficial. Apple é a prioridade nativa.

### Precisão antes de espetáculo

Não invente valor, não simule medição em produção e não esconda resultado parcial. Se uma fase falhar, represente a limitação corretamente.

### Beleza sem excesso

Evite cardização, sombras gratuitas, gradientes decorativos, dashboards, gráficos sem utilidade e animações que competem com a medição.

Motion deve transmitir estado e precisão, não chamar atenção para si.

---

## 7. Design e identidade

O novo Design System em `documentacao/design/design_system/` substitui a governança visual antiga.
- A pasta `documentacao/design/design_system/assets/icons/` é a ÚNICA fonte de verdade dos ícones. É expressamente proibido redesenhar o símbolo ou manter variantes visuais antigas concorrentes.
- **Logo Oficial:** O logo do produto é estrita e unicamente o arquivo `wordmark.svg` (tanto na Web quanto no App). É expressamente proibido usar texto puro (ex: `<div>Linka</div>`) no lugar da logo.

Não use Material Design 3 como regra do novo Linka.

Não restaure por hábito:

- navegação do Linka antigo;
- linguagem visual Android/MD3;
- cards e dashboards antigos;
- Geist apenas porque existia antes;
- componentes legados quando contradizem o novo protótipo.

Quando protótipo e Design System divergirem:

- protótipo decide comportamento e geometria da experiência;
- Design System decide tokens, identidade, componentes e regras visuais;
- se a divergência for material e não puder ser conciliada, Giam decide antes de implementar.

---

## 8. Regras do motor

A interface minimalista não autoriza simplificar a metodologia sem evidência.

Ao tocar no engine:

- preserve medições reais de latência, download e upload;
- preserve cancelamento e tratamento de erro;
- preserve adaptação necessária para conexões móveis/lentas;
- preserve resultado parcial quando uma fase não puder ser concluída;
- não duplique lógica de medição na UI;
- não acople diagnóstico avançado ao motor do Linka;
- mantenha contratos compatíveis ou versione mudanças incompatíveis.

Afirmações públicas em `Como medimos` precisam ser verificáveis no código. Não publique número de servidores, quantidade de conexões, duração, precisão ou metodologia se não houver evidência correspondente.

---

## 9. IA e diagnóstico

**O Linka não usa IA para interpretar o resultado para o usuário como parte do fluxo principal.**

Frases como “sua conexão está ótima para jogos” ou “seu ping pode causar travamentos” pertencem ao SignallQ.

IA pode ser usada como ferramenta de desenvolvimento, revisão e operação, mas não deve transformar o Linka em produto de diagnóstico.

Nunca exponha segredo, token ou chave de API no bundle Web. Variáveis públicas de frontend não são cofre de segredo.

---

## 10. Privacidade e publicidade

- Sem conta obrigatória para medir.
- Colete e retenha apenas o necessário.
- Política pública deve descrever o comportamento real, não intenção futura.
- Não afirme anonimização, retenção, relatórios agregados ou compartilhamento se isso não estiver implementado e validado.
- Informação sensível não aparece em compartilhamento por padrão.

Publicidade, quando existir:

- não atrasa o teste;
- não interrompe a medição;
- não cobre resultado;
- não parece controle do produto;
- não compete visualmente com as métricas.

---

## 11. Qualidade mínima antes de declarar pronto

Para mudanças Web relevantes, execute quando aplicável:

```text
npm run lint
npm test
npm run build
```

Execute typecheck explícito se não estiver coberto pelo build.

Além disso, valide:

- início automático;
- download → upload → resultado;
- reteste;
- erro/offline;
- resultado parcial;
- responsividade mobile e desktop;
- acessibilidade básica;
- fidelidade ao protótipo;
- ausência de `@ts-nocheck` usado para esconder incompatibilidade nova;
- ausência de segredo exposto no cliente.

Se algo não foi testado, diga que não foi testado.

---

## 12. Git e execução

- Trabalhe em branch para mudanças relevantes; não trate `main` como bancada de experimento.
- Preserve alterações existentes do usuário.
- Não use force push sem autorização explícita.
- Não faça deploy, publicação em loja, mudança de infraestrutura com custo ou exclusão destrutiva sem autorização do Luiz.
- Commit e push fazem parte da execução somente quando o escopo autorizado os exigir; nunca alegue que foram feitos sem confirmação real.

---

## 13. O que está aposentado

Estão **formalmente aposentados como governança**:

- modo `Codex-only`;
- papéis legados Renan / Marcelo / Gema / Lia deste repositório;
- obrigação PWA-only;
- Material Design 3 como padrão visual;
- Cloudflare Pages como destino obrigatório;
- dependências de caminhos absolutos do antigo workspace Windows `E:\Projetos\Linka`;
- documentos antigos que descrevem o Linka como central de diagnóstico ou mini-SignallQ;
- regra de trabalhar sempre diretamente em `main`;
- qualquer segundo conjunto de regras em `CLAUDE.md`.

O código legado pode continuar existindo até ser removido conscientemente. **Legado existente não vira regra atual só porque ainda está no repositório.**

---

## 14. Regra final

Antes de construir qualquer coisa, faça a pergunta:

> **Isso ajuda o Linka a medir a internet melhor, mais rápido, mais confiável ou de forma mais clara?**

Se a resposta for não, provavelmente não pertence ao Linka.
