# Kit de marketing — macOS — pt-BR

Estas são as imagens de vitrine para a página do Linka no Mac App Store. Ao
contrário das capturas cruas em `../../../../final/pt-BR/mac/`, cada peça conduz
uma única promessa e usa uma tela real do app como prova visual.

1. `01-measure-your-connection.jpg` — medir velocidade, latência e estabilidade.
2. `02-understand-what-is-happening.jpg` — Assist para começar a entender um problema.
3. `03-follow-your-network.jpg` — histórico para acompanhar mudanças na conexão.
4. `04-improve-what-matters.jpg` — oportunidades de otimização.

Todos os arquivos são JPEG 2880 × 1800 px, 16:10 e sem transparência. A sequência
prioriza a leitura no resultado de busca: medição primeiro; cada imagem seguinte
introduz só um benefício. As telas internas são capturas reais do Linka para Mac,
sem dados ou funções criados para marketing.

A copy usa a mesma família tipográfica nativa do app: SF Pro para títulos e
corpo. A tipografia arredondada permanece exclusiva das métricas mensuradas,
como download e upload.

## Referência de direção

- Speedtest by Ookla centra a oferta em teste rápido, histórico e relatórios; o
  Linka se diferencia ao transformar o resultado em entendimento e próximo passo.
- A Apple recomenda que as primeiras imagens comuniquem a essência e que cada
  imagem subsequente destaque um benefício principal. Por isso não incluímos DNS
  e status de serviços neste primeiro conjunto: eles são profundidade do produto,
  não a promessa que convence alguém a baixar o app.

Para regerar o kit após uma nova captura:

```sh
swift store/app-store/screenshots/scripts/generate_macos_marketing_kit.swift
```
