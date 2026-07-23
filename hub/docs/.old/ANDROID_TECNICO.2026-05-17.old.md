# Documentação Técnica — Android Linka

**Público-alvo:** Desenvolvedor humano (dev novo ou colaborador)
**Plataforma:** Android exclusivo — Kotlin, Jetpack Compose, Material Design 3
**Última atualização:** 2026-05-17
**Mantido por:** Taisa

> Este documento descreve a arquitetura interna, módulos, camadas de dados, engines de diagnóstico e contratos do app Android Linka, ancorado no código real em `E:\Projetos\Linka\linkaAndroidKotlin\linka-android-kotlin\`.
> Para funcionalidades da perspectiva do usuário, consulte `ANDROID_FUNCIONAL.md`.
> Para documentação cross-platform (Android + PWA), consulte `TECNICO_CROSSPLATFORM.md`.

---

## 1. Stack e Versões

| Tecnologia | Função |
|---|---|
| Kotlin 2.2.20 | Linguagem principal |
| Jetpack Compose (plugin 2.2.20) | UI declarativa |
| Material Design 3 | Sistema de design |
| Room (versão 8 do schema) | Persistência local (SQLite) |
| DataStore (Preferences) | Preferências do usuário |
| Kotlin Coroutines | Operações assíncronas |
| WorkManager (CoroutineWorker) | Tarefas em background (monitoramento) |
| Android Gradle Plugin 8.11.1 | Build system |

**Injeção de dependência:** manual por construtor. Sem Hilt, sem Koin. Cada módulo expõe um objeto `*Modulo.kt` com funções fábrica estáticas (ex.: `CoreDatabaseModulo.criarBanco(context)`).

---

## 2. Estrutura de Módulos

O projeto tem **15 módulos** declarados em `settings.gradle.kts`:

```
:app
:coreNetwork
:corePermissions
:coreDatabase
:coreDatastore
:coreTelephony
:featureHome
:featureWifi
:featureDevices
:featureDns
:featureSpeedtest
:featureDiagnostico
:featureFibra
:featureHistory
:featureSettings
```

> Nota: o `CLAUDE.md` do workspace menciona 16 módulos, mas o `settings.gradle.kts` declara 15. O número correto é 15.

### Camadas por tipo de módulo

| Prefixo | Papel |
|---|---|
| `:core*` | Infraestrutura compartilhada — rede, banco, preferências, permissões, telefonia |
| `:feature*` | Features de produto — cada uma com sua lógica de domínio |
| `:app` | Entry point — `MainActivity`, `MainViewModel`, `AppNavGraph`, telas, componentes UI globais, orchestrators |

---

## 3. Arquitetura

### 3.1 Padrão MVVM

```
UI (Composables)
    ↑ StateFlow / collectAsStateWithLifecycle
MainViewModel (AndroidViewModel)
    ↑ fábrica de objetos (Modulo.kt)
Serviços / Repositórios / Engines
    ↑ Room / DataStore / APIs Android / HTTP
```

Fluxo unidirecional: eventos da UI disparam funções no ViewModel, que atualiza `StateFlow`, que recompõe a UI.

### 3.2 Entry Points

| Arquivo | Papel |
|---|---|
| `LinkaApplication.kt` | Application — inicialização do app |
| `MainActivity.kt` | Activity única — `setContent { LinkaTheme { AppShell(...) } }` |
| `MainViewModel.kt` | ViewModel raiz — instancia todos os serviços lazy |
| `LinkaTheme.kt` | Tema MD3 (`MaterialTheme` com `ColorScheme` customizado) |

### 3.3 Navegação

**Arquivo:** `AppNavGraph.kt`

Rotas declaradas (destinos de navegação profunda via `linka://screen/...`):

```kotlin
object AppNavGraph {
    const val rotaInicial = "home"
    const val home = "home"
    const val diagnostico = "diagnostico"
    const val dispositivos = "dispositivos"
    const val historico = "historico"
    const val ajustes = "ajustes"
}
```

**Navegação principal:** `AppShell.kt` implementa o shell do app com `BottomNavigationBar` de 5 abas. A navegação entre abas é por índice (`selectedTab: Int`). Telas secundárias (SpeedTest, Fibra, Sinal, Laudo, Chat) são sobrepostas via `AnimatedVisibility` com `slideInVertically` — não são rotas de navigation separadas.

**Estrutura de abas:**

| Índice | Label | Screen | Observação |
|---|---|---|---|
| 0 | Home | `HomeScreen` | Tela inicial com status de conexão |
| 1 | Diagnóstico | `ResultadoVelocidadeScreen` ou `OrbitScreen` | Se há resultado de speedtest, mostra `ResultadoVelocidadeScreen`; caso contrário, `OrbitScreen` |
| 2 | Dispositivos | `DispositivosScreen` | Scanner de dispositivos na rede |
| 3 | Histórico | `HistoricoScreen` | Histórico de medições com uptime |
| 4 | Ajustes | `AjustesScreen` | Configurações do app |

**Telas secundárias (sobrepostas, sem rota própria):**

| Tela | Trigger | Composable |
|---|---|---|
| SpeedTest (pré-execução) | Botão na HomeScreen ou Diagnóstico | `SpeedTestScreen` |
| Velocidade (durante execução) | Teste em andamento | `VelocidadeScreen` |
| Resultado de Velocidade | Teste concluído (fluxo manual) | `ResultadoVelocidadeScreen` |
| Chat / Orbit | Botão "Abrir chat" | `ChatScreen` |
| Fibra | Botão nos Ajustes | `FibraScreen` |
| Sinal | Botão na HomeScreen | `SinalScreen` |
| Laudo | Botão nos Ajustes | `LaudoScreen` |
| DNS Benchmark | Botão no SpeedTestScreen | `ModalBottomSheet` com `DnsComparisonSheetContent` |
| Perfil | Botão na HomeScreen | `ModalBottomSheet` com `PerfilEditSheet` |

---

[Conteúdo completo arquivado — documento movido para linkaAndroidKotlin/docs_ai/ANDROID_TECNICO.md]
