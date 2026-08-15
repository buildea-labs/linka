# plano.md — ProviderNormalizer global

**Trilha:** Full‑flow.
**Branch:** `feat/provider-normalizer`.
**Autor do plano:** Giam. Aprovado por Luiz na sessão de 2026-08-15.

---

## Objetivo

Exibir o nome comercial do provedor de acesso na UI do Linka em qualquer país onde o app for distribuído, no lugar da razão social crua vinda do registro do ASN.

Exemplo: `TELEFÔNICA BRASIL S.A` → `Vivo`. `DEUTSCHE TELEKOM AG` → `Telekom`. `COMCAST CABLE COMMUNICATIONS, LLC` → `Xfinity`.

## Contexto

Hoje o `SpeedTestCore` consulta `ipinfo.io/json`, pega o campo `org` (formato `"AS27699 TELEFÔNICA BRASIL S.A"`), tira o número de AS e mostra o restante. Isso vaza razão social e nome corporativo pro usuário. Já existe um mapeamento inline de ~10 operadoras brasileiras (fix da fast‑lane anterior), mas é frágil e não cobre nada fora do BR.

## Mudança arquitetural

- Novo tipo `ProviderNormalizer` dentro de `LinkaEngine` — isolado, testável, sem I/O.
- Dataset curado `providers.json` bundlado no target do LinkaEngine, versionado no repo.
- Chave primária de lookup: **número de AS** (extraído do `org` do ipinfo).
- Cascata de fallback:
  1. Match por ASN exato no dataset.
  2. Match por padrão de substring (ex.: `TELEFONICA` → Vivo) por região.
  3. Heurística: strip de sufixos legais (`S.A.`, `S/A`, `LLC`, `Ltd`, `Inc`, `GmbH`, `AG`, `PLC`, `Comunicações`, `Telecomunicações`, `Cable Communications`, etc.) + title‑case.
  4. Se nada resolver, mantém o raw limpo do prefixo `AS<n>`.
- `SpeedTestCore` passa a delegar a normalização ao novo tipo, entregando o `org` inteiro (não mais o split manual).
- Contrato do `MeasurementState.provider` permanece `String?` — sem quebra pra consumidores.

## Escopo de cobertura na v1

Curadoria manual de ~150 ASNs cobrindo top ISPs residencial + operadoras móveis:

- BR: Vivo, Claro, TIM, Oi, Algar, Sercomtel, NET, GVT, TIM Live, Vivo Fibra, Brisanet, Vero.
- EUA: Comcast/Xfinity, Verizon, AT&T, T‑Mobile, Spectrum/Charter, Cox, CenturyLink/Lumen, Google Fi.
- UK: BT, Sky, Virgin Media, EE, Vodafone UK, TalkTalk, Three.
- PT: MEO, NOS, Vodafone PT, NOWO.
- ES: Movistar, Vodafone ES, Orange ES, Yoigo, MásMóvil.
- FR: Orange, Free, SFR, Bouygues.
- DE: Telekom, Vodafone DE, O2 (Telefónica), 1&1.
- IT: TIM Italia, Vodafone IT, Fastweb, WindTre.
- MX: Telcex/Telmex, Izzi, Megacable, AT&T MX, Movistar MX.
- AR, CO, CL: principais.
- JP: NTT, SoftBank, KDDI.
- IN: Jio, Airtel, BSNL, Vi.
- AU/CA: principais.

Total alvo: ~150 entradas, dá pra crescer por PR sem tocar código.

## Requisito de aceite

- Vivo, Claro, TIM, Oi resolvidos corretamente no BR (móvel e fibra).
- Pelo menos ~150 ASNs cobertos entre os países listados.
- Zero regressão funcional: se dataset falhar de carregar, motor continua funcionando com fallback heurístico.
- Testes unitários com fixtures reais de `org` string cobrindo os quatro caminhos da cascata.
- Comando `swift test` do LinkaEngine passa.
- Sem chamada de rede adicional em runtime.

## Não‑objetivo

- Chamada externa em runtime pra enriquecer ASN (PeeringDB API, etc.).
- Atualização remota do dataset (remote config).
- Geo‑IP sofisticado ou detecção de país client‑side.
- MVNO exaustivo — só as principais.
- Suporte a IPv6‑only edge cases.
- UI nova.

## Riscos

- Dataset envelhece: operadoras mudam de nome (Oi → V.tal, etc.). Mitigação: nomenclatura ativa no momento da curadoria + PR para atualizações.
- ipinfo pode devolver `org` em formato diferente (região sem AS number). Mitigação: fallback heurístico já cobre.
- Bundle cresce ~10‑15 KB. Aceitável.

## Notas do Guinho pra Marcelo

- Testes devem incluir edge cases: `org` vazio, sem prefixo AS, ASN desconhecido, string com múltiplos espaços, caracteres com acento.
- Verificar que `commercialProviderName` inline anterior sai completo — dataset é a única fonte.
