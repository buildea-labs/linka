---
name: garantir-iphone-real
description: Valida o Linka em iPhone, iPad e Mac reais e registra evidência verificável.
---

# Skill: garantir-iphone-real

Use esta skill para validar que a implementação funciona no ecossistema Apple real. A auditoria usa o mesmo roteiro para verificar o que foi ou não validado.

Simulador ajuda em layout e navegação, mas não prova medição real, permissões, ciclo de vida ou rede móvel.

## Quando aparelho real é obrigatório

Mudanças que tocam medição, rede, permissões, background, App Intents/Widgets, resultado ou comportamento dependente da plataforma devem ser validadas em dispositivo real antes de serem consideradas totalmente verificadas.

## Verificar

### iPhone

- safe area / notch / Dynamic Island;
- Dynamic Type;
- Wi‑Fi e rede móvel;
- troca/perda de rede;
- background/foreground;
- cancelamento;
- light/dark;
- Reduce Motion e VoiceOver quando aplicável.

### iPad

- adaptação de layout;
- portrait/landscape conforme suporte;
- Split View/Stage Manager quando relevante.

### Mac

- janela redimensionável;
- tamanhos mínimos razoáveis;
- comportamento full screen quando aplicável.

## Permissões

Permissão nova é mudança material. Deve ter finalidade clara, descrição coerente e caminho de recuperação quando negada. Se a necessidade de produto não estiver definida, o Codex consulta a definição de produto/Luiz antes de adicionar a capability.

## Resultado parcial e erro

Rede desligada, timeout ou fase incompleta não podem produzir sucesso visual nem zero inventado. O dispositivo real deve refletir o mesmo contrato do motor.

## Relatório

Registre:

- dispositivo usado;
- tipo de rede;
- cenários executados;
- resultado;
- cenários não executados.

“Não testado em aparelho real” é informação válida. Omitir isso não é.
