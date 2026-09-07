# Kit de marketing App Store — rascunho

Quatro composições em pt-BR para a narrativa da página da App Store. Cada
peça combina tipografia desenhada programaticamente (portanto as frases são
exatas e legíveis) com uma captura real do Linka, preservada sem UI inventada.

| Ordem | Arquivo | Headline | Captura inserida |
| --- | --- | --- | --- |
| 1 | `01-meca-sua-conexao.jpg` | Meça sua conexão. | `../fontes/iphone/01-home.png` |
| 2 | `02-medicao-em-tempo-real.jpg` | A medição em tempo real. | `../fontes/iphone/02-resultado.png` |
| 3 | `03-entenda-o-resultado.jpg` | Entenda o resultado. | `../fontes/iphone/03-contexto.png` |
| 4 | `04-acompanhe-suas-medicoes.jpg` | Acompanhe suas medições. | `../fontes/iphone/Simulator Screenshot - iPhone 17 Pro - 2026-09-04 at 00.08.55.png` |

Todos os arquivos finais são JPEG, 1206 × 2622 px, sem canal alpha. Essa é
uma dimensão aceita para iPhone com tela de 6,3 polegadas. Eles são rascunhos:
não foram publicados e precisam ser recapturados em build atual antes de envio
ao App Store Connect. O kit não cobre as capturas obrigatórias para iPad ou,
caso o binário Mac seja distribuído separadamente, Mac.

## Direção visual

O cabeçalho usa somente o azul-marinho `#102245`, o laranja `#E0701F`, branco
e superfícies claras do Design System. A ambientação é plana: sem gradiente,
sombra, ilustração, número ou capacidade que a tela real não mostre. A captura
entra centralizada em uma moldura fina para deixar claro que é o produto, não
um mockup gerado.

## Validação manual

As quatro imagens foram abertas e inspecionadas após a exportação. Os títulos
e subtítulos foram desenhados por AppKit, não por geração de imagem, para
garantir acentos e grafia exatos. A conversão final para JPEG removeu alpha.
