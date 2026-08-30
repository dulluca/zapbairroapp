# Resposta à App Review — submissão 438c4949 (rejeitada em 13/08/2026)

A build 1.0.0 (5) foi rejeitada em três diretrizes. Este documento tem o texto
pronto para copiar, onde colar cada parte e o que conferir antes de reenviar.

> **Confira o número de comércios antes de enviar.** O texto abaixo diz "cerca
> de 140". Esse número veio de `lojistas.json`: são 228 registros, mas só 138
> **nomes distintos** — e as telas do app deduplicam pelo nome, então o morador
> vê ~138, não 228. A fonte de verdade é a coleção `comercios` no Firestore, não
> o arquivo. Confira lá e ajuste a frase se estiver diferente. Número errado numa
> resposta à App Review custa caro.

---

## 1. O que mudou no app desde a build 5

| Diretriz | O que foi feito |
|---|---|
| 5.1.1(v) | A tela de cadastro (nome + WhatsApp) saiu. O código dela foi **apagado**, não só desligado: `MoradorService` e `mostrarCadastroMorador` não existem mais. Não há login, conta nem cadastro em lugar nenhum. |
| 5.1.1 (dado pessoal) | As avaliações e o log de acessos deixaram de gravar `moradorNome` e `moradorTelefone`. Hoje o app **não coleta nenhum dado pessoal**. |
| 4.2.2 | Avaliação por estrelas: média e total em cada loja da lista, distribuição das notas (quantas de 5, de 4, …) e as últimas notas recebidas na tela de detalhes. Qualquer pessoa avalia, sem conta. |
| 4.2.2 | A tela AVALIAÇÃO ganhou busca própria — antes ela só funcionava para quem já tinha aberto alguma loja, e num app recém-instalado era um beco sem saída bem na hora em que o revisor tocava nela. |
| 1.2 (UGC) | O campo de comentário livre saiu da avaliação. A nota é só a estrela: **não há conteúdo escrito por usuário no app**, então as obrigações de moderação da diretriz 1.2 não se aplicam. |
| 2.3.10 | Capturas refeitas no Simulador do iOS. Os botões de contato deixaram de trazer o nome da plataforma de terceiros no rótulo: agora são "Falar com a loja" e "Pedidos e suporte". |

---

## 2. Onde colar cada coisa

**a) Resposta ao revisor** — App Store Connect → ZapBairro → **Distribuição** →
**Revisão de apps** → abrir o envio rejeitado → seção **Mensagens** → responder.
Use o texto da seção 3.

**b) Notas para a revisão** — na versão nova, em *Informações da versão* →
**Notas para a revisão do app**. Use o texto da seção 4.

**c) Capturas de tela** — *Prévias e Capturas de Tela*. Rode o workflow
**"iOS - Capturas de tela (App Store)"**, baixe o artefato `capturas-ios` e
substitua **todas** as imagens antigas, inclusive as que só aparecem em
"Ver todos os tamanhos no Gerenciador de Mídia".

---

## 3. Texto da resposta ao revisor (copiar inteiro)

> O campo de mensagem da App Review aceita **no maximo 4.000 caracteres**.
> O texto abaixo tem 3.241 — se voce editar alguma frase, confira o total
> antes de colar. A primeira versao deste texto tinha 5.064 e nao cabia.

```
Hello,

Thank you for the detailed review of build 1.0.0 (5). All three items are
addressed in build 1.0.0 (7). Here is what changed and how to verify it.


5.1.1(v) - REGISTRATION REMOVED

Build 5 opened with a mandatory form asking for the user's name and WhatsApp
number. That screen is gone - not hidden, but deleted from the source along
with the service that stored those fields. The app now opens directly on the
directory: no registration, no login, no account anywhere, and every feature
works on first launch.

We also removed the last two fields that could identify a person. Ratings and
usage records no longer carry a name or a phone number. As submitted, the app
collects no personal data at all.

That screen is likely also why the app looked limited: everything below sat
behind it.


4.2.2 - INTERACTIVE FUNCTIONALITY

ZapBairro is a searchable directory of around 140 small businesses in one
neighborhood - Conjunto Maguari, in Belem, Brazil - with community star
ratings. Most of them have no website and appear in no map or delivery app. We
sell nothing and advertise no service of our own.

Please test, in this order:

1. SEARCH. On the first screen type "acai" and tap the magnifier. The app
   searches names, categories, descriptions and addresses at once, ignoring
   accents and case (that is why "acai" finds "Acai"), and ranks results by
   where the match was found.

2. RATINGS (new). Every result shows its star average and how many residents
   rated it. Open one: the average sits under the name, and the section
   "Avaliacoes da vizinhanca" at the bottom shows the full breakdown - how many
   5-star, how many 4-star, and so on - plus the most recent ratings.

3. RATE IT (new). Tap "Avaliar esta loja", pick 1 to 5 stars, tap "Enviar".
   The breakdown and both averages update immediately. No account and no
   personal detail is requested. Ratings are stars only: there is no free-text
   field and no user-written content anywhere in the app.

4. FAVORITES. Tap the heart on any business, then "FAVORITOS" on the home
   screen to see and manage what you saved. Stored on the device.

5. CATEGORIES. The home screen has 12 categories, each opening its specialties
   and then the businesses inside them.

The contact buttons are the last step of that flow, not the purpose of the app.


2.3.10 - SCREENSHOTS

You are correct: the old screenshots came from an Android device and showed the
Android status bar. All of them were replaced with captures produced on an
iPhone simulator running this build. We also removed a third-party platform
name from the two contact buttons, which now read "Falar com a loja" (talk to
the business) and "Pedidos e suporte" (orders and support).


2.3.1 - HIDDEN PANEL, DISCLOSED

Rather than leave it undocumented: on the first screen, press and hold the
title "ZapBairro" for about a second. A password prompt appears, and the
password is zapadmin2024. It opens an internal panel we use as the publisher -
visit counts per business, most-opened specialties, and the ratings received.
It has no user-facing feature and shows no personal data. We will remove it
from the public build if you prefer.

Thank you for your time. We are happy to provide any further detail.
```

---

## 4. Notas para a revisão do app (versão curta)

> Mesmo limite de 4.000 caracteres. Este texto tem 1.747.

```
What changed since build 1.0.0 (5):

1. Removed the mandatory name + WhatsApp registration screen, and deleted the
   code behind it. The app opens straight into the directory and nothing is
   gated (guideline 5.1.1). No account exists in the app.
2. The app no longer stores any personal data. Ratings and usage records carry
   no name and no phone number.
3. Added community star ratings: every business shows its average and rating
   count, the detail screen shows the full breakdown by star and the most
   recent ratings, and anyone can rate with no account (guideline 4.2.2).
   Ratings are stars only - there is no free-text field anywhere in the app.
4. Rewrote the search so it matches names, categories, descriptions and
   addresses, ignoring accents and capitalization.
5. Replaced all screenshots with captures produced on an iPhone simulator
   (guideline 2.3.10), and removed the third-party platform name from the two
   contact buttons.

How to test in one minute:
- Type "acai" in the search field on the first screen and tap the magnifier.
- Open any result: the star average is under the name; scroll to the bottom for
  the rating breakdown and the latest ratings.
- Tap "Avaliar esta loja", pick stars, tap "Enviar" - the breakdown and the
  average update immediately.
- Tap the heart on a business, then "FAVORITOS" on the home screen.

No login is required for any of the above.

Declared per guideline 2.3.1 - hidden admin panel: on the first screen, press
and hold the title "ZapBairro" for about one second and enter the password
zapadmin2024. It opens an internal usage-statistics panel for us, the
publisher. It has no user-facing feature and shows no personal data. We will
remove it from the build if you prefer.
```

---

## 5. Checklist antes de apertar "Reenviar para Revisão do app"

- [ ] **Build number.** Já está em `pubspec.yaml` como `1.0.0+7` — a build
      rejeitada é a (5), e a (7) do run anterior foi compilada mas nunca chegou
      a ser aceita, então o número está livre. No dispatch do workflow
      "iOS - Build IPA (App Store)", deixe o campo `build_number` **vazio**: ele
      usa o valor do pubspec. Para o próximo envio, suba o pubspec para `+8`.
- [ ] **A build nova aparece no TestFlight** e foi selecionada na versão.
- [ ] **Todas as capturas antigas substituídas**, inclusive em "Ver todos os
      tamanhos no Gerenciador de Mídia". Sobrou uma do Android? Volta a 2.3.10.
- [ ] **URL da política de privacidade** preenchida (obrigatória).
- [ ] **URL de suporte** preenchida (obrigatória).
- [ ] **Privacidade do app** (o questionário): hoje a resposta honesta é
      *nenhum dado coletado*. O app grava no Firestore a nota dada e qual
      especialidade foi aberta, sem identificador de pessoa nem de dispositivo.
- [ ] **Classificação etária**: o questionário pergunta sobre conteúdo gerado
      por usuário. Como não há campo de texto, a resposta é não.
- [ ] **Notas para a revisão** coladas (seção 4), com a declaração do painel.
- [ ] **Resposta ao revisor** postada na thread da submissão (seção 3).

---

## 6. Duas coisas que dependem de vocês, não do código

### 6.1 As avaliações precisam ter dados de verdade

O revisor vai abrir a tela de detalhes. Se a coleção `avaliacoes` estiver vazia,
ele lê "Nenhum morador avaliou esta loja ainda" em toda loja que abrir — e a
resposta ao 4.2.2 vira uma promessa em vez de uma demonstração.

O jeito certo de resolver é dado real: peça a um punhado de moradores e à equipe
que avaliem pelo app Android nos próximos dias, espalhando por várias lojas.
Leva minutos e é honesto.

**Não semeie avaliações inventadas.** O texto acima diz à Apple que as notas vêm
dos moradores. Se as notas forem nossas, a afirmação é falsa — e é o tipo de
coisa que, descoberta, custa a conta de desenvolvedor, não só a submissão.

### 6.2 Regras do Firestore

A coleção `avaliacoes` recebe escrita anônima e não existe `firestore.rules` no
repositório — as regras estão só no console. Confira duas coisas lá:

1. Se o projeto ainda está em **modo de teste**, qualquer pessoa com o app na mão
   consegue apagar a base inteira. A regra mínima é: `comercios` só leitura;
   `avaliacoes`, `acessos_especialidade` e `especialidades_contagem` com escrita
   permitida mas sem `delete` nem `update`.
2. A data de expiração do modo de teste. Quando ela passa, o app para de ler o
   Firestore — e aí ele abre vazio na mão do revisor.

---

## 7. Por que o texto está escrito assim

A carta original tinha argumentos como "Sistema Operacional do Bairro",
"economia de baixo carbono" e "sentimento de pertencimento". É boa prosa, mas é
exatamente o registro que a diretriz 4.2.2 mira: o revisor lê linguagem de
marketing e conclui que o app é material de marketing.

Ele decide em minutos e quer instruções que possa executar. Por isso o texto é
uma lista numerada de *toque aqui → veja isso acontecer*, com os rótulos dos
botões em português entre parênteses, do jeito que ele vai encontrar na tela.

Também foi retirada a afirmação de que o app tem serviços "verificados pela
comunidade" no sentido de curadoria ou moderação: o app mostra as notas que os
moradores dão, e é isso que o texto diz. Prometer à App Review algo que o app não
faz é o caminho mais rápido para uma quarta rejeição.

---

## 8. A área administrativa oculta

Toque longo no título "ZapBairro" na tela inicial abre um pedido de senha
(`zapadmin2024`, definida em `lib/main.dart`). Dentro dele ficam o contador de
visitas por comércio, o ranking de especialidades mais abertas e a lista de
avaliações recebidas.

**Isso precisa ser declarado.** A diretriz 2.3.1 diz, literalmente, que o app não
pode conter recursos ocultos ou não documentados. Se o revisor descobrir o painel
por conta própria — e eles testam gestos — a rejeição vem por 2.3.1, e ainda com
a credibilidade das outras respostas abalada. Declarado, é um painel interno
comum, coisa que a App Review aprova todo dia.

### Um aviso sobre essa senha

`kAdminSenha` é uma constante de texto compilada dentro do app. Qualquer pessoa
com o `.ipa` ou o `.apk` extrai a senha em segundos — não é proteção, é só uma
forma de esconder o painel do usuário comum. Para estatística de acesso, está bom.

Deixa de estar bom no dia em que o cadastro de morador voltar. Se um dia vocês
reativarem a coleta de nome e telefone, o painel passa a expor dado de morador
atrás de uma senha que está escrita no binário — e aí vira problema de privacidade
de verdade, com risco nas diretrizes 5.1.1 e 5.1.2. Nesse dia o painel precisa
sair do app e virar uma página web com autenticação de verdade.
