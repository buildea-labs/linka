# Hermes Agent POC — Linka Integration

## ✅ What's Been Created

### 1. **Hermes Installation** (Windows)
- Location: `C:\Users\luizg\AppData\Local\hermes\`
- Command: `hermes chat` (now available in PowerShell)
- Status: ✅ Ready

### 2. **Two Starter Skills** (in `~/.hermes/skills/linka/`)
- **`wifi-diagnostic`** — RSSI analysis, band detection, interference patterns, ANATEL thresholds
- **`release-checklist`** — Pre-release QA gate (versioning, tests, changelog, regressions)

### 3. **Project Memory** (in `~/.hermes/memories/`)
- **`MEMORY.md`** — Linka architecture, modules, team roles, constraints, workflows
- **`USER.md`** — Squad preferences, communication style, what works/doesn't work

### 4. **Context File** (`.hermes-context`)
- Points Hermes to CLAUDE.md, docs, CHANGELOG
- Auto-loads on startup

---

## 🚀 Quick Start

### Terminal: Start Hermes Chat

```powershell
# Open PowerShell and navigate to Linka root
cd E:\Projetos\Linka

# Start Hermes
hermes chat

# You'll see:
# > Hermes Agent v0.14.0 — Nous Research
# Ready for input...
```

### Try the First Skill

```
> /linka-wifi-diagnostic

Hermes: "I'll help you diagnose WiFi signal quality for Linka. Please provide:
1. Current RSSI in dBm (e.g., -65 dBm)
2. WiFi band (2.4 GHz, 5 GHz, or 6 GHz)
3. PHY standard (802.11n, 802.11ac, 802.11ax, etc.)

What's your signal reading?"
```

### Try the Release Checklist

```
> /linka-release-checklist

Hermes: "Running pre-release QA gate for Linka...
- Checking versioning (Android + PWA)
- Verifying tests
- Validating CHANGELOG
- Checking regressions...

Provide version numbers to proceed."
```

### View Project Context

```
> /codebase-map linka

Hermes: "Linka Project Structure:
├── linkaAndroidKotlin/ (Kotlin + Compose)
│   ├── :app
│   ├── :coreNetwork
│   ├── :corePermissions
│   ├── :coreDatabase
│   ├── :coreDatastore
│   ├── :coreTelephony
│   ├── :featureHome
│   ├── :featureWifi
│   ├── :featureDevices
│   ├── :featureDns
│   ├── :featureSpeedtest
│   ├── :featureDiagnostico
│   ├── :featureFibra
│   ├── :featureHistory
│   ├── :featureSettings
│   └── docs_ai/
├── linkaSpeedtestPwa/ (React + TypeScript)
├── CLAUDE.md (workspace rules)
├── CHANGELOG.md
└── HERMES_POC.md (this file)"
```

---

## 📚 What Hermes Can Do (Next Steps)

### ✅ Already Working
1. **Load and execute skills** — `/linka-wifi-diagnostic`, `/linka-release-checklist`
2. **Read context** — understands Linka architecture from MEMORY.md
3. **Remember preferences** — knows squad communication style (USER.md)
4. **Answer questions** — about WiFi, releases, Linka workflow

### 🔄 Next Phase (Implementation)
1. **Scheduled automations** — cron job to run release checklist daily
2. **Delegation** — spawn subagents for Android + PWA parallel work
3. **Multi-platform messaging** — Discord, Telegram, Slack notifications
4. **Skill evolution** — auto-create new skills from completed tasks

### 🎯 Longer Term
1. **Integration with `.claude/tasks/`** — Hermes orchestrates task queue
2. **Connected to squad agents** — Hermes delegates to Camilo, Renan, Gema
3. **Skills Hub** — publish Linka skills publicly for community use

---

## 🧠 How Hermes Learns

Every time you interact with Hermes:

1. **Hermes observes** your requests and corrections
2. **Hermes learns** patterns (e.g., "always check WiFi band before RSSI")
3. **Hermes creates skills** automatically (e.g., `/auto-wifi-check`)
4. **Skills improve over time** as the agent refines them

Example:
```
> Run WiFi diagnostic and if poor signal, recommend 5GHz band first

Hermes: "Done. I've created a new skill `/quick-wifi-fix` that
does exactly this. Next time you need quick WiFi remediation,
use /quick-wifi-fix <rssi> <band>"
```

---

## 📁 File Structure

```
C:\Users\luizg\.hermes/
├── skills/
│   └── linka/
│       ├── wifi-diagnostic/
│       │   └── SKILL.md
│       └── release-checklist/
│           └── SKILL.md
├── memories/
│   ├── MEMORY.md       (← Project context)
│   └── USER.md         (← Squad preferences)
├── config.yaml         (← Settings)
├── SOUL.md            (← Personality definition)
└── .env               (← API keys, if needed)

E:\Projetos\Linka/
├── CLAUDE.md
├── CHANGELOG.md
├── HERMES_POC.md      (← This file)
├── .hermes-context    (← Context file for Hermes)
└── linkaAndroidKotlin/
    └── docs_ai/
        ├── ANDROID_FUNCIONAL.md
        └── ANDROID_TECNICO.md
```

---

## ⚙️ Configuration (if needed)

Edit `~/.hermes/config.yaml` to:
- Change LLM provider (OpenAI, OpenRouter, Nous Portal)
- Set API keys in `~/.hermes/.env`
- Configure messaging gateways (Discord, Telegram, etc.)

For now, **defaults are fine** — Hermes will prompt for API key on first chat if needed.

---

## 🐛 Troubleshooting

### Command not found: `hermes`
```powershell
# Refresh PATH
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

# Try again
hermes chat
```

### Skills not showing up
```powershell
hermes skills list
# Should show: linka-wifi-diagnostic, linka-release-checklist

# If not, verify directory:
ls ~/.hermes/skills/linka/
```

### Memory not loading
```powershell
hermes memory status
# Should show MEMORY.md and USER.md sizes

# If empty, they were created at:
cat ~/.hermes/memories/MEMORY.md
cat ~/.hermes/memories/USER.md
```

---

## 🎓 Next Experiments

1. **Test with Discord:** Set up Discord gateway, have Hermes post results to squad channel
2. **Create a workflow skill:** Auto-release Android + PWA in parallel using `delegates`
3. **Scheduled checklist:** Cron job that runs `/linka-release-checklist` every Friday 2pm
4. **Ask for feedback:** Have squad use Hermes for a week, capture what they want to improve

---

## 📞 Questions?

For Hermes docs, see: https://hermes-agent.nousresearch.com/docs/

For Linka specifics, check: `CLAUDE.md` or ask Claudete (Claudete.md).

---

**Created:** 2026-05-22
**Status:** ✅ Ready to chat
**Next milestone:** Integrate with Discord + schedule automations
