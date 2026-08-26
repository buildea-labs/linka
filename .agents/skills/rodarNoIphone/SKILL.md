---
name: rodar-no-iphone
description: Procedimento do Guinho para construir, assinar e instalar o Linka num iPhone/iPad/Mac de verdade, com os portões do Xcode que travam o caminho.
---

# Skill: rodarNoIphone

Procedimento do **Guinho** para pôr o Linka rodando **no aparelho de verdade** — iPhone, iPad ou Mac.

O que decide se o produto funciona não é o build. É o comportamento em rede real, a permissão iOS, o ciclo de vida do app. Simulador não prova medição ([`garantirIphoneReal`](../garantirIphoneReal/SKILL.md)).

Projeto Xcode: [`aplicativo-ios/LinkaApp.xcodeproj`](../../../aplicativo-ios/LinkaApp.xcodeproj). Pacotes Swift: `NetworkCore`, `MeasurementHistory`, `NetworkInsights`, `NetworkAssist`, `LinkaEngine`, `LinkaModules`, `LinkaAppIntents`, `LinkaEntitlements`. CI: [`.github/workflows/swift-modules-ci.yml`](../../../.github/workflows/swift-modules-ci.yml).

---

## 1. O básico

Rodar pacotes Swift isoladamente (rápido, sem UI):

```bash
cd aplicativo-ios/NetworkCore && swift test
cd aplicativo-ios/MeasurementHistory && swift test
cd aplicativo-ios/NetworkInsights && swift test
cd aplicativo-ios/NetworkAssist && swift test
cd aplicativo-ios/LinkaModules && swift test
```

Abrir o app no Xcode:

```bash
open aplicativo-ios/LinkaApp.xcodeproj
```

Ou usar XcodeGen se o `project.yml` foi modificado:

```bash
cd aplicativo-ios && xcodegen
```

## 2. Os portões da máquina, na ordem em que eles aparecem

Todos já morderam alguém. Alguns exigem senha do dono do Mac.

| Sintoma | O que é | Quem resolve |
|---|---|---|
| Qualquer comando de build responde "you have not agreed to the Xcode license" | licença do Xcode nunca aceita | dono do Mac: `sudo xcodebuild -license accept` |
| "Found no destinations" / "iOS X.Y is not installed" | Xcode instalado, plataforma iOS não baixada (~8 GB) | `xcodebuild -downloadPlatform iOS` |
| "Signing for App requires a development team" | nenhuma conta Apple registrada no Xcode | dono do Mac: Xcode → Settings → Accounts → **+** |
| "Developer Mode disabled" | trava do iOS 16+ no aparelho | dono do aparelho: Ajustes → Privacidade e Segurança → Modo de Desenvolvedor, e **reinicia** |
| `errSecInternalComponent` no `codesign` | chaveiro recusou a chave para processo sem tela | rodar uma vez pelo Xcode (▶) e responder **Sempre Permitir** |
| "Invalid trust settings ... restore system default" | alguém mexeu na confiança do certificado no chaveiro | Acesso às Chaves → aba **Certificados** → o certificado → Confiar → **Usar Padrões do Sistema** |
| App instala e não abre | conta gratuita: o aparelho ainda não confia no desenvolvedor | Ajustes → Geral → VPN e Gerenciamento de Dispositivo → Confiar |

**Não mande o dono do Mac mexer em "Chaves" quando o problema é "Certificados".** São abas diferentes do Acesso às Chaves e trocar uma pela outra quebra assinatura.

## 3. Simulador (para layout, não para medição)

```bash
# lista simulators
xcrun simctl list devices available

# boot
xcrun simctl boot "iPhone 16 Pro"

# build para simulator
xcodebuild -project aplicativo-ios/LinkaApp.xcodeproj -scheme LinkaApp \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  -configuration Debug \
  CODE_SIGNING_ALLOWED=NO build

# install + launch
xcrun simctl install "iPhone 16 Pro" /path/to/build/Debug-iphonesimulator/LinkaApp.app
xcrun simctl launch "iPhone 16 Pro" com.linka.speedtest

# screenshot
xcrun simctl io "iPhone 16 Pro" screenshot /tmp/tela.png
```

Simulador serve para conferir layout em várias tamanhos Apple (iPhone SE, iPhone 16 Pro Max, iPad Pro, Mac). **Não serve para medição real** — a rede é a do Mac.

## 4. iPhone/iPad real

Aparelho **plugado e desbloqueado**:

```bash
# lista aparelhos conectados
xcrun devicectl list devices

# build + install
xcodebuild -project aplicativo-ios/LinkaApp.xcodeproj -scheme LinkaApp \
  -destination 'id=<device-id>' \
  -configuration Debug \
  -allowProvisioningUpdates build

xcrun devicectl device install app --device <device-id> \
  /path/to/build/Debug-iphoneos/LinkaApp.app
```

Depois, no aparelho: rodar em rede real (Wi-Fi + celular), observar o comportamento — não só o layout.

## 5. Mac

O Linka roda em Mac (Apple-only inclui iPhone/iPad/Mac). No Xcode, selecione o esquema `LinkaApp` com destino "My Mac (Designed for iPad)" ou destino nativo Mac se o target Catalyst/Mac estiver configurado. Testar janela redimensionável e Full Screen.

## 6. O time de assinatura não vai para o repositório

`DEVELOPMENT_TEAM` fica fora do controle de versão: cada dev tem sua conta. Se aparecer no `git status` depois de um build, é ruído — não commite.

## 7. O que só o aparelho responde

Build verde não é entrega. No aparelho, com o Linka na mão:

- [ ] medição inicia sozinha ao abrir
- [ ] fluxo Preparando → Download → Upload → Finalizando → Resultado sem trancar
- [ ] "Testar novamente" reinicia limpo
- [ ] cancelar durante a medição libera task, não deixa órfão
- [ ] mandar app para background durante medição não corrompe estado
- [ ] rede desligada: erro tratado, não fica rodando em vão
- [ ] rede lenta (Network Link Conditioner ou 3G real): gera `partial` honesto
- [ ] retrato + paisagem, se permitido
- [ ] `Reduce Motion` ligado: informação completa

O que não foi testado **vai escrito como não testado** no relatório do PR ([`registrarIssue`](../registrarIssue/SKILL.md) §5, [`.agents/WORKFLOW.md`](../../WORKFLOW.md) Passo 2).

## 8. O que esta skill NÃO autoriza

- publicar em App Store, TestFlight ou distribuir fora sem autorização do Luiz;
- adicionar entitlement ou capability nova sem discutir escopo com o Giam;
- mudar `Info.plist` de forma que exija permissão sensível nova sem alinhamento;
- desabilitar teste ou pipeline "para o build passar".

## Relacionados

- **iPhone real:** [`garantirIphoneReal`](../garantirIphoneReal/SKILL.md)
- **Adapter entre motor e UI:** [`escreverAdaptadorNativo`](../escreverAdaptadorNativo/SKILL.md)
- **Auditoria final:** [`auditarSegurancaETestes`](../auditarSegurancaETestes/SKILL.md)
- **Testes automatizados:** [`escreverTestes`](../escreverTestes/SKILL.md)
