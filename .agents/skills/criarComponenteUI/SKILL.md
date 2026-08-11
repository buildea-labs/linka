---
name: criarComponenteUI
description: Diretrizes do Guinho para construir a UI do Linka SpeedTest com fidelidade ao minimalismo Apple-first e foco total na medição.
---

# Skill: criarComponenteUI

Procedimento do **Guinho** para construir componentes do Linka SpeedTest.

Pressupõe o plano do Giam ([`AGENTS.md`](../../../AGENTS.md) §3.1) já escrito,
**incluindo a especificação de UX e de UI**. Sem isso, não comece — devolva para o Giam.

Guinho constrói o que foi desenhado. Se durante a implementação aparecer decisão visual que a spec não cobre, **isso volta pro Giam** — não se resolve no componente tentando inventar padrão.

## 0. Não é um dashboard, é uma medição

A interface do Linka é **extremamente focada e minimalista**. Antes de criar componente novo, pergunte se aquilo realmente ajuda a mostrar a velocidade ou se é apenas uma firula para inchar a tela.

**Três coisas que não se quebram:**
1. O resultado da medição é o protagonista (tamanho, tipografia e destaque);
2. Nenhuma ação exige navegação profunda durante o teste;
3. A interface deve transmitir calma e precisão, nunca desespero.

## 1. Direção visual (Apple-first)

O Linka busca:
- Minimalismo premium;
- Foco em iOS/macOS (Apple-first);
- Tipografia forte e limpa;
- Espaço em branco usado como respiro;
- Transições suaves e precisas;
- O número (resultado) absoluto no centro.

**Nada de:** Glassmorphism gratuito, gradientes exagerados, sombras pesadas ou velocímetros de carro. A beleza vem do alinhamento, proporção e tipografia.

## 2. Design tokens

Antes de inventar valor ou colocar `px` fixo:
- procure tokens/variáveis já existentes no Tailwind/CSS;
- preserve espaçamento e tipografia;
- não crie uma segunda paleta de cores para uma "tela de detalhes".

## 3. Hierarquia

Componente precisa respeitar a hierarquia definida no UX.
- O botão INICIAR (se existir) ou o NÚMERO rodando é o topo.
- Detalhes técnicos (latência, jitter) são secundários (divulgação progressiva).

## 4. Responsividade

Prioridade: iPhone real e Safari.
- alvo de toque confortável (mínimo 44x44px na Apple);
- respeitar `safe-area-inset`;
- testar viewport de um iPhone pequeno e de um iPad.

## 5. Motion (Animação)

Animação no Linka transmite **precisão**, não espetáculo.
- O número não pode tremer desgovernado, deve rodar suave;
- As trocas de estado (download para upload) não piscam a tela;
- Respeite `prefers-reduced-motion`.

## 6. Acessibilidade

- Score e métricas devem ser legíveis por leitores de tela (`aria-live` para progresso);
- Foco visível.
- Contraste absurdo para uso no sol (alguém medindo 5G na rua).

## 7. Modularidade e Copy

- Se um componente só exibe o Ping, ele não deve conhecer como o socket de teste do Ping foi instanciado. O Linka Engine calcula, a UI exibe.
- Guinho atua como filtro anti-tecnês: se a UI precisar de 3 parágrafos para explicar "Bufferbloat", ele chama o Giam pra arrancar aquilo ou simplificar a copy.
