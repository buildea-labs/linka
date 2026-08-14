# Visão do Produto — Linka SpeedTest

## O que é o Linka

**Linka é um SpeedTest minimalista, rápido, preciso e visualmente refinado, criado com foco no ecossistema Apple.**

Ele existe para fazer uma única coisa muito bem:

> **medir a qualidade da conexão de internet e apresentar o resultado de forma imediata, clara e bonita.**

O Linka não é uma central de ferramentas de rede.

Não é um aplicativo de diagnóstico.

Não é um monitor de Wi-Fi.

Não é um substituto do SignallQ.

É um medidor.

E justamente por ter um propósito pequeno, precisa executá-lo excepcionalmente bem.

---

## A proposta

Usar o Linka deve exigir praticamente nenhuma decisão.

O usuário abre.

O teste começa.

A velocidade aparece.

O resultado termina de se formar.

Fim.

```text
ABRIR
  ↓
LATÊNCIA
  ↓
DOWNLOAD
  ↓
UPLOAD
  ↓
RESULTADO
```

Nenhuma escolha de modo antes do teste.

Nenhum formulário.

Nenhum dashboard esperando o usuário.

Nenhuma tela tentando ensinar telecom antes de medir a internet.

O produto deve parecer instantâneo.

---

# Minimalista, não simplório

Minimalismo no Linka não significa medir menos ou fazer uma medição tecnicamente pobre.

É justamente o contrário.

A complexidade deve existir **por baixo da interface**, não na frente do usuário.

Enquanto a tela mostra algo tão simples quanto:

```text
184,3
Mbps

DOWNLOAD
```

o motor pode estar realizando:

* múltiplas amostras;
* tratamento estatístico;
* medição de latência;
* jitter;
* download;
* upload;
* latência sob carga;
* detecção de falhas;
* adaptação à capacidade da conexão;
* tratamento específico para redes móveis;
* controle de duração e amostragem;
* resultados parciais quando necessário.

O usuário não precisa conhecer a engenharia que existe por trás daquele número.

Mas deve poder confiar nele.

---

# O resultado é o produto

No Linka, o número precisa ser o elemento visual mais importante da interface.

Não a logo.

Não o menu.

Não um card.

Não um diagnóstico.

Não uma propaganda.

A medição.

Durante o download:

```text
        184,3

         Mbps

       DOWNLOAD
```

Durante o upload:

```text
         42,8

         Mbps

        UPLOAD
```

Ao terminar:

```text
DOWNLOAD            UPLOAD
184,3 Mbps          42,8 Mbps

Ping  11 ms
Jitter  3 ms
```

Os detalhes existem, mas aparecem em segundo plano.

A interface deve possuir hierarquia suficiente para que uma pessoa consiga olhar para a tela por dois segundos e entender o resultado.

---

# Bonito sem tentar chamar atenção

O Linka deve ter aparência premium.

Mas não deve parecer um produto tentando desesperadamente parecer premium.

Nada de:

* gradientes gratuitos;
* sombras excessivas;
* dezenas de cards;
* glassmorphism em tudo;
* animações chamativas;
* velocímetros cheios de ponteiros;
* gráficos sem utilidade;
* textos enormes explicando coisas óbvias.

A beleza deve vir de:

* tipografia;
* espaço;
* alinhamento;
* proporção;
* movimento;
* hierarquia;
* precisão visual.

A interface deve transmitir calma.

A conexão pode estar ruim.

O aplicativo não precisa parecer desesperado junto com ela.

---

# Apple-first

O Linka deve ser pensado prioritariamente para:

**iPhone
iPad
Mac**

Não apenas funcionar nesses aparelhos.

Precisa parecer que pertence a eles.

Isso significa respeitar princípios naturais do ecossistema Apple:

* interface limpa;
* transições suaves;
* feedback tátil discreto;
* excelente tipografia;
* áreas de toque confortáveis;
* respeito a Safe Areas;
* adaptação natural entre iPhone e iPad;
* excelente comportamento em diferentes tamanhos de janela no Mac;
* acessibilidade desde o início;
* Dark Mode quando fizer sentido;
* integração com recursos nativos sem transformar o app em uma árvore de configurações.

A experiência não deve parecer um site colocado dentro de um aplicativo.

O aplicativo Apple deve ser realmente nativo.

---

# O produto é Apple-only

O Linka é distribuído **exclusivamente para o ecossistema Apple** (iPhone, iPad, Mac).

Não haverá versão Web nem Android do produto.

A Web continua existindo, mas apenas como **site institucional e de marketing**: apresenta o Linka, comunica a marca e direciona para o app Apple. A linguagem visual e os tokens do design system são compartilhados para que o site pareça parte do mesmo produto — mas o site não mede, não é uma "versão Web do Linka" e não é caminho de evolução do produto.

---

# Uma interface que desaparece

Uma das melhores experiências possíveis para o Linka é aquela em que o usuário quase esquece que está usando um aplicativo.

Ele abriu porque queria saber:

> “Quanto está dando minha internet?”

Poucos segundos depois tem a resposta.

Não deveria existir nenhuma barreira entre essas duas coisas.

Isso implica:

### Sem onboarding obrigatório

Não existe motivo para três telas dizendo como um SpeedTest funciona.

### Sem cadastro

Medir internet não deveria exigir conta.

### Sem configuração antes da primeira medição

Preferências avançadas podem existir posteriormente, mas nunca bloquear a ação principal.

### Sem seleção de servidor para usuário comum

O motor deve escolher a melhor estratégia automaticamente.

### Sem escolher “Rápido”, “Completo” ou “Avançado”

Esses são conceitos internos.

O usuário pediu um teste.

O Linka deve saber como executá-lo.

---

# Detalhes para quem quiser detalhes

Minimalismo também não significa esconder informação útil.

Depois do resultado, o usuário pode acessar detalhes como:

* latência;
* jitter;
* latência durante download;
* latência durante upload;
* servidor utilizado;
* localização aproximada do servidor;
* duração da medição;
* informações sobre a metodologia.

Mas isso deve funcionar por **divulgação progressiva**.

Primeiro:

```text
184 Mbps
```

Depois, se quiser:

```text
Ver detalhes
```

E só então aparece a parte técnica.

Nunca ao contrário.

---

# Movimento

As animações fazem parte da identidade do Linka.

Mas precisam transmitir precisão, não espetáculo.

Ao abrir o aplicativo, os iniciam surgir de maneira suave.

Ao iniciar a medição, o número começa praticamente do zero e acompanha a conexão em tempo real.

Na troca entre download e upload, a interface muda de estado sem uma tela desaparecer bruscamente e outra aparecer.

Ao terminar, o resultado se estabiliza.

O movimento deve transmitir:

> **estamos medindo.**

Não:

> **olha quanta animação conseguimos fazer.**

---

# Performance

O Linka não pode ser um SpeedTest pesado.

A aplicação precisa abrir rápido mesmo em uma conexão ruim.

Isso é especialmente importante porque frequentemente alguém abre um SpeedTest justamente quando suspeita que a internet está uma merda.

O produto precisa:

* carregar rapidamente;
* depender de poucos recursos externos;
* iniciar a medição rapidamente;
* permanecer responsivo durante o teste;
* consumir memória de forma controlada;
* evitar componentes e bibliotecas desnecessárias.

Um SpeedTest que demora para carregar em internet ruim já começa falhando no próprio propósito.

---

# Precisão antes de velocidade

O Linka deve parecer rápido.

Mas não deve sacrificar confiabilidade apenas para terminar alguns segundos antes.

O motor deve coletar amostras suficientes para produzir um resultado representativo.

Medições precisam considerar:

* conexões extremamente rápidas;
* conexões muito lentas;
* redes móveis instáveis;
* Wi-Fi degradado;
* upload muito inferior ao download;
* mudança de comportamento durante o teste;
* falhas parciais;
* perda temporária de conectividade.

É melhor apresentar:

> “Não foi possível medir o upload.”

do que inventar, aproximar ou descartar silenciosamente toda a medição.

---

# Transparência

O Linka não deve fingir precisão absoluta.

SpeedTests medem um caminho específico entre o dispositivo e uma infraestrutura de teste em determinado momento.

Portanto, o produto deve ser transparente sobre:

* como mede;
* o que mede;
* o que não mede;
* quais servidores utiliza;
* por que diferentes testes podem produzir resultados diferentes.

Essa explicação pertence à página **Como medimos**.

Não à tela principal.

---

# Privacidade

A experiência inicial deve funcionar sem conta.

O Linka deve coletar somente o necessário para operar e melhorar o serviço.

IP, informações da conexão, localização aproximada e telemetria precisam ser tratados como dados técnicos potencialmente sensíveis.

A regra deve ser simples:

> se não precisamos armazenar, não armazenamos.

E informações sensíveis não devem aparecer em compartilhamentos ou telas públicas por padrão.

---

# Publicidade

Se publicidade fizer parte do modelo de negócio, ela precisa respeitar a função principal.

O anúncio nunca pode:

* atrasar o início do teste;
* interromper a medição;
* cobrir o resultado;
* parecer botão do aplicativo;
* competir visualmente com a velocidade;
* transformá-lo numa página de anúncio com um SpeedTest no meio.

O espaço publicitário é secundário.

O teste sempre vem primeiro.

---

# Linka e SignallQ

A fronteira precisa permanecer clara.

## Linka

**Mede.**

```text
184 Mbps
11 ms
42 Mbps upload
```

## SignallQ

**Entende e orienta.**

```text
Sua velocidade está boa,
mas a latência aumenta muito durante uso intenso.

Isso pode explicar travamentos em chamadas e jogos.
```

Quando o Linka começar a responder a segunda pergunta, é sinal de que estamos novamente misturando os produtos.

---

# Linka Engine

Por baixo da experiência existe o **Linka Engine**.

Ele é a tecnologia de medição.

Pode alimentar:

```text
Linka SpeedTest
       │
       ├── Web
       ├── iPhone
       ├── iPad
       └── Mac

SignallQ
SignallQ PRO
SignallQ Agente
```

O SpeedTest é um produto.

O Engine é uma capacidade tecnológica.

Os dois compartilham o nome Linka, mas não devem ser confundidos.

---

# O teste para qualquer nova funcionalidade

Antes de adicionar alguma coisa ao Linka, devemos perguntar:

**Isso melhora diretamente a experiência de medir a conexão?**

Se sim, avaliar.

Se não, provavelmente não pertence ao Linka.

Exemplos:

**Melhorar precisão do upload:** sim.

**Melhorar animação durante a medição:** sim.

**Mostrar latência como detalhe:** sim.

**Criar scanner de dispositivos:** não.

**Diagnosticar canal Wi-Fi:** não.

**Criar chatbot de suporte:** não.

**Adicionar teste DNS completo:** provavelmente não.

**Criar feed de resultados:** definitivamente não.

Esse filtro é necessário porque a história do Linka já demonstrou como é fácil transformar uma ferramenta simples em um produto inchado.

---

# Princípios do produto

O Linka deve ser:

**Simples sem ser limitado.**

**Bonito sem ser decorativo.**

**Rápido sem ser impreciso.**

**Técnico por baixo e humano por cima.**

**Apple-first sem abandonar a Web.**

**Minimalista sem parecer vazio.**

**Confiável antes de ser cheio de funções.**

---

# Em uma frase

> **Linka é o SpeedTest que você abre, olha e entende — rápido, preciso e bonito o suficiente para parecer que sempre deveria ter sido assim.**
