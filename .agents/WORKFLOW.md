# Workflow da Squad — Linka SpeedTest

Este documento descreve a esteira de produção oficial do Linka SpeedTest. É aqui que definimos como uma ideia sai da cabeça do Luiz (Dono do Produto) e vira código em produção, com o Antigravity (Giam) orquestrando o trabalho sujo no background.

## O Ciclo de Vida de uma Feature

### Passo 0: Plano e Escudo (Giam)
A primeira barreira do Linka é o **produto**.
Quando uma nova demanda surge, o Giam avalia: *"Isso ajuda a medir a internet ou é firula de SignallQ?"*
Se a ideia passar no filtro de minimalismo, o Giam (na linha de frente da IA):
- Mastiga as opções técnicas;
- Decide a arquitetura (ex: onde o estado da medição mora);
- Desenha o impacto visual na UX;
- Crava os requisitos de aceite.
> **Regra de Ouro:** Ninguém escreve uma linha de código antes do acordo de produto estar fechado nesta etapa.

### Passo 1: A Batalha no Background (Guinho)
Com o plano selado e aprovado pelo Luiz, o sub-agente **Guinho** é invocado de forma autônoma.
O Guinho atua no bastidor para:
- Criar uma branch isolada;
- Implementar a lógica matemática e os componentes React seguindo o design Apple-first;
- Escrever os testes iniciais e focar na execução bruta, sem tomar decisões de escopo.

### Passo 2: Proteção do Motor (Camillo)
Para mudanças que tocam o núcleo (o *Linka Engine*), o sub-agente **Camillo** entra na jogada para revisar a pull request ou a implementação do Guinho.
O papel dele é garantir que a UI e a lógica de medição permaneçam desacopladas. O Camillo veta qualquer atalho tecnológico que prejudique a precisão dos cálculos de latência, jitter, ou que possa escalar mal no futuro.

### Passo 3: A Marreta da Qualidade (Marcelinho)
Antes de declarar o código "pronto", o sub-agente **Marcelinho** assume o controle.
Sua única missão é tentar quebrar a solução:
- Executa a pipeline completa (`typecheck`, `lint`, `test`, `build`);
- Audita se quedas bruscas de rede não estão gerando falsos positivos na UI;
- Garante que a segurança e os limites de borda da aplicação não foram comprometidos.

### Passo 4: Aceite e Merge (Giam + Luiz)
O Giam pega os relatórios técnicos do Guinho, Camillo e Marcelinho, bate as entregas contra os requisitos definidos no **Passo 0** e apresenta a conclusão ao Luiz, já mastigada.
Se o Luiz (Dono do Produto) der a palavra final de aprovação, o código é **mergeado na main** e as branches temporárias são limpas.

---

> *"Uma coisa de cada vez. Termina. Valida. Mergeia."*
