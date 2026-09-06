---
name: escrever-testes
description: Procedimento do Camillo para escrever testes junto com mudanças de comportamento. Tito revisa cobertura e regressões no final.
---

# Skill: escrever-testes

Camillo escreve testes junto com a implementação quando eles protegem comportamento real. Tito revisa a suíte e os gaps depois.

## Comportamentos que normalmente exigem teste

- matemática e conversões de medição;
- invariantes de NetworkMeasurement;
- transições de estado do motor;
- cancelamento, timeout e falha de rede;
- resultado parcial;
- persistência, retenção e corrupção;
- estatísticas e insights;
- regras do Assist;
- adapters com estado ou ciclo de vida relevante.

## O que teste unitário não prova

Teste unitário não substitui validação de rede móvel, background/foreground, permissões, layout, Dynamic Type, VoiceOver ou comportamento em dispositivo real.

## Regras

- um comportamento por teste;
- nome descreve o comportamento esperado;
- prefira Arrange, Act, Assert quando couber;
- unidade não depende de rede externa real;
- use fixtures e doubles controlados para I/O;
- cálculo de domínio não deve exigir montar SwiftUI;
- não congele detalhe visual irrelevante em teste só para aumentar cobertura.

## Ferramentas

- pacotes Swift: `swift test`;
- app e adapters: XCTest/Xcode Test Plans conforme targets existentes;
- site institucional: use somente a suíte realmente configurada.

Ao devolver, Camillo informa testes criados ou alterados, comandos executados e o que não foi validado. Tito diferencia cobertura automatizada de validação real em aparelho.
