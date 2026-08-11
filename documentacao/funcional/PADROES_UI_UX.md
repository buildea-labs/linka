# Padroes UI/UX — Ecossistema Linka

> Principios e regras de design que se aplicam a ambas as plataformas (Android e PWA).
> Para tokens de cor e tipografia especificos, consulte `MATERIAL_DESIGN_3.md`.
> Para identidade visual e componentes do PWA, consulte `linkaSpeedtestPwa/docs/GuiaBranding.md`.

---

## 1. Direcao de design: iOS-Calma

O design system do Linka segue a direcao **iOS-Calma**:

- **Superficies neutras** — sem fundo colorido de tela. Toda cor esta nos dados.
- **Hierarquia pelo tamanho** — o numero hero comunica a metrica. Labels e contexto ficam secundarios.
- **Listas estilo iOS Settings** no lugar de cards aninhados com sombra.
- **Zero sombras** — profundidade via cor de superficie, bordas sutis e mecanismo de tinta de fundo.
- **Accent restrito** — `#6C2BFF` apenas em elementos interativos ou como enfase de label.
- **Dados com cor semantica** — DL e sempre azul, UL e sempre verde, latencia e roxo/accent.
- **Toque minimo** — bordas sutis, hairlines, raios arredondados mas nao exagerados.

---

## 2. Principios universais

Estes principios se aplicam ao Android e ao PWA sem excecao.

### Zero sombras

Nenhuma sombra de nenhum tipo:
- Android: `elevation = 0` em todos os componentes (exceto cards em modo claro com sombra muito sutil)
- PWA: `box-shadow: none` e `text-shadow: none` absolutos

Profundidade e indicada por cor de superficie mais clara ou mais escura, nunca por sombra.

### Accent restrito

A cor accent (`#6C2BFF`) aparece apenas em:
- Botao primario (CTA)
- Orb animado (tela de medição)
- Anel do gauge (fase de medicao)
- Icone pinned
- Links de navegacao

Nao usar como cor de fundo de tela inteira, nem em textos secundarios.

### Cores semanticas para metricas de velocidade

| Metrica | Cor | Token PWA | Valor |
|---|---|---|---|
| Download | Azul | `--dl` | `#3AB6FF` (dark) / `#0A84FF` (light) |
| Upload | Verde | `--ul` | `#22C55E` (dark) / `#30D158` (light) |
| Latencia/Ping | Roxo/accent | `--accent` | `#6C2BFF` |
| Oscilacao (Jitter) | Amarelo/aviso | `--warn` | `#F5A623` |
| Perda de pacotes | Vermelho/erro | `--error` | `#FF453A` (dark) |

Estas cores sao reservadas para metricas de velocidade. Nao usar em outros contextos.

### Gradientes proibidos

Zero gradientes em componentes e telas, com uma excecao:
- PWA: `--bg-radial` no `body` — definido em `tokens.css`. Nao duplicar em telas ou componentes.
- Android: [a confirmar se existe uso de gradiente equivalente]

---

## 3. Nomenclatura do produto

| Contexto | Forma correta |
|---|---|
| Interface do produto | `linka` (minusculo sempre) |
| Titulo de pagina / manifest | `linka SpeedTest` |
| Nome completo de produto | `linka SpeedTest` |
| Identificadores no codigo | `linka`, `linkaSpeedTest` |

**Nunca:** `Linka`, `LINKA SpeedTest`, `LinkA`, `Linka Speed Test`

---

## 4. Nomenclatura das metricas na UI

| Metrica tecnica | Label na UI |
|---|---|
| Download (Mbps) | ↓ Download |
| Upload (Mbps) | ↑ Upload |
| Latency (ms) | Resposta |
| Jitter (ms) | Oscilacao |
| Packet Loss (%) | Perda |

### Excecao: Ping vs. Latencia

| Contexto | Termo a usar |
|---|---|
| Label do gauge na tela de medicao | **Ping** |
| Copy voltado ao publico gamer | **Ping** |
| Diagnosticos tecnicos | Latencia (aceitavel) |
| Footer / exportacao PDF | Latencia (contexto tecnico) |

---

## 5. Tom de voz e copy

- **Objetivo e direto.** Frases curtas. Sem rodeios.
- **Leigo.** "Sua internet esta boa para video" — nao "latencia dentro do percentil 80".
- **Positivo quando possivel.** "Melhorou 23%" — nao "Era ruim, agora e menos ruim".
- **Sem jargao tecnico exposto.** Mbps, ms e % sao aceitaveis. TCP, TTL, DNS nao.
- **Idioma:** todo o copy de interface em **pt-BR**. Codigo e comentarios em **ingles**.
- **Zero emoji em UI de produto.** Emoji so em tooltips internos de debug, nunca visiveis ao usuario.

---

## 6. Estados visuais obrigatorios

Todo componente ou tela que carrega dados deve ter todos estes estados implementados:

| Estado | Descricao |
|---|---|
| **Loading / Skeleton** | Enquanto dados estao sendo buscados |
| **Sucesso / Dado disponivel** | Estado normal com dados |
| **Vazio** | Sem dados para exibir (historico vazio, sem dispositivos, etc.) |
| **Erro** | Falha ao buscar dados — com mensagem e acao de retry quando possivel |

Nao existe "estado de dado disponivel" sem os outros tres implementados.

### Cores por estado

| Estado | Cor de destaque |
|---|---|
| Sucesso / Bom | Verde (`--ul` / `success`) |
| Aviso / Regular | Amarelo (`--warn` / `warning`) |
| Erro / Ruim | Vermelho (`--error` / `error`) |
| Neutro / Indisponivel | `--text-2` / `textSecondary` |

---

## 7. Chips e badges semanticos

| Variante | Fundo | Texto | Uso |
|---|---|---|---|
| `good` | tint de verde | verde | Excelente, Bom, Aprovado |
| `maybe` | tint de amarelo | amarelo | Regular, Atencao |
| `bad` | tint de vermelho | vermelho | Ruim, Falha |
| `accent` | tint de accent | accent | Passo, badge de fluxo |
| `neutral` | `surface-2` + borda | `text-2` | Estado neutro, inativo |

Qualidades possiveis: `excellent` (Excelente), `good` (Boa), `fair` (Regular), `slow` (Lenta), `unavailable` (Indisponivel).

---

## 8. Icones

- **Apenas SVGs stroke-based** — nunca icones preenchidos.
- **Zero emoji** em UI de produto.
- Espessura de traco: `1.5px` padrao, `2px` em icones de acao.
- Tamanhos recorrentes: 13px (inline em metadados), 14px (em lista), 16px (padrao), 22px (FAB), 24px (acao em header).
- Cor sempre via prop ou token — nunca hardcoded no SVG.

---

## 9. Navegacao e cabecalho de tela

### PWA — TopBar System

- Todas as telas usam `<TopBar>` em `position: absolute; top: 0; height: 56px + safe-top; z-index: 50`
- Estado inicial: transparente
- Ao rolar (via `useScrollHeader`): `background: var(--surface-translucent)` + `backdrop-filter: blur(20px)` + borda inferior
- Back button: chevron `<` em pill 36x36px (area tocavel 44x44, `aria-label="Voltar"`, sem texto)
- Titulo da tela: no `<PageHeader>` no topo do scroll content (Geist 700, 32px ou 24-28px em telas medias)
- Titulo migra para o TopBar com fade ao rolar

### Android

- [a confirmar] — padroes de TopAppBar e navegacao Android especificos

---

## 10. Scroll principal (PWA)

Todas as telas com conteudo rolavel:
```css
flex: 1;
overflow-y: auto;
padding: 8px 16px 32px;
```

Secao hero dentro do scroll: `padding: 4px 0 18px`.

---

## 11. Checklist de conformidade

Antes de entregar qualquer tela ou componente:

- [ ] "linka" minusculo em todo copy visivel
- [ ] Zero `box-shadow` ou `text-shadow`
- [ ] Zero emoji em UI de produto
- [ ] Cores via tokens — sem valores hex hardcoded em `.tsx`/`.css` ou Composables
- [ ] Numeros de metrica em Geist (display)
- [ ] Botao primario usa cor accent (`#6C2BFF`)
- [ ] Labels uppercase de secao: 11px, 600, `letter-spacing: 0.06em`, cor terciaria
- [ ] Todos os estados implementados: loading, sucesso, vazio, erro
- [ ] Sem gradientes fora do mecanismo global
- [ ] Copy em pt-BR, tom objetivo, sem jargao tecnico

---

**Ultima atualizacao:** 2026-05-16
**Mantido por:** Taisa
