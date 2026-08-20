# Resposta à App Review — submissão 438c4949 (rejeitada em 13/08/2026)

A build 1.0.0 (5) foi rejeitada em três diretrizes. Este documento tem o texto
pronto para copiar e onde colar cada parte.

> **Confira antes de enviar:** o texto afirma que o app cobre o Conjunto Maguari,
> em Belém (PA), com 228 comércios. O número vem de `lojistas.json` e o bairro
> saiu dos endereços cadastrados. Se o alcance for outro, corrija as duas frases
> antes de enviar — dado errado numa resposta à App Review custa caro.
>
> Conferido em 20/08/2026: `lojistas.json` tem 228 itens, a tela inicial tem 12
> categorias, `kAdminSenha` continua `zapadmin2024` e a chamada da tela de
> cadastro segue comentada em `lib/main.dart`. Os quatro números que a carta
> afirma batem com o código.

---

## 0. O build que vai junto

A carta descreve a busca reescrita e as avaliações da vizinhança como novidades
desta build. **A build 6, que está no TestFlight, não tem nenhuma das duas.**
Ela saiu do commit `9ee033c`, anterior ao `3f96548` ("Corrige a busca e torna as
avaliacoes visiveis aos moradores"). Tem só a remoção do cadastro.

Submeter a build 6 com esta carta é entregar ao revisor um texto que não
corresponde ao app — o caminho mais curto para a terceira rejeição, agora com a
credibilidade queimada.

Antes de qualquer coisa, rode **"iOS - Build IPA (App Store)"** na `main` com os
dois campos vazios. O número da build sai do número do run (será 7, maior que a
6 e que a 5, que é o que a Apple exige) e a versão sai do `pubspec.yaml`
(`1.0.0`, a mesma que está rejeitada e que aceita build nova).

---

## 1. Onde colar

**a) Resposta ao revisor** — App Store Connect → ZapBairro → **Distribuição** →
**Revisão de apps** → abrir o envio de 5 de agosto → seção **Mensagens** →
responder. Use o texto da seção 2 abaixo.

**b) Notas para a revisão** — ao criar a versão nova, em *Informações da versão*
→ **Notas para a revisão do app**. Use o texto da seção 3 (versão curta).

**c) Capturas de tela** — *Prévias e Capturas de Tela*. Rode o workflow
**"iOS - Capturas de tela (App Store)"** no GitHub Actions, baixe o artefato
`capturas-ios` e substitua **todas** as imagens antigas.

---

## 2. Texto da resposta ao revisor (copiar inteiro)

```
Hello,

Thank you for the detailed review of build 1.0.0 (5). We have addressed all
three items. Below is what changed and how to verify each one.


GUIDELINE 5.1.1(v) - REGISTRATION REMOVED

Build 5 opened with a mandatory form asking for the user's name and WhatsApp
number before anything else could be reached. That screen has been removed
entirely. The new build opens directly on the business directory. There is no
registration, no login, and no user account anywhere in the app. Every feature
is available immediately on first launch.

We believe this screen is also the reason the app appeared to have limited
functionality: the reviewer had to pass a registration wall before reaching any
content, and all of the interactive features listed below sit behind it.


GUIDELINE 4.2.2 - INTERACTIVE FUNCTIONALITY

ZapBairro is a searchable directory of the small businesses of one specific
neighborhood - Conjunto Maguari, in Belem, Brazil. It currently covers 228
local businesses, most of which have no website and do not appear in general
map or delivery apps. We do not sell anything and we have no service of our own
to advertise: the app exists so that a resident can find a nearby business and
so that residents can rate the ones they used.

Features you can test, in this order:

1. FULL-TEXT SEARCH
   On the first screen, type "acai" into the search field and tap the magnifier
   icon. The app searches business names, descriptions, categories and
   addresses at once, ignores accents and capitalization, accepts multiple
   words, and ranks the results by where the match was found (name first, then
   category, then description).

2. COMMUNITY RATINGS - NEW IN THIS BUILD
   Open any business from the list. The star average and the number of ratings
   appear under its name, and the same average appears next to every business
   in the directory list. At the bottom of the detail screen, the section
   "Avaliacoes da vizinhanca" (neighborhood reviews) lists each review with its
   star rating, comment and date.

   The directory is new, so most businesses still read "Ainda sem avaliacoes -
   seja o primeiro a avaliar" (no ratings yet - be the first to rate). Step 3
   shows the feature working end to end: a rating you submit appears in that
   section immediately and changes the average shown next to the business in
   the directory list.

3. SUBMIT A RATING - NEW IN THIS BUILD
   On the same detail screen, tap "Avaliar esta loja" (rate this business),
   choose 1 to 5 stars, optionally write a comment, and tap "Enviar" (send).
   Your rating is saved and appears immediately in the list below it, and it
   changes the average shown next to that business in the directory. No account
   or registration is required at any point.

4. FAVORITES
   Tap the heart icon next to any business, either in the list or on the detail
   screen. Then tap "FAVORITOS" on the home screen to see everything you saved,
   and remove entries from there. Favorites are stored on the device.

5. BROWSE BY CATEGORY
   The home screen has 12 categories. Each one opens its subcategories, and
   each subcategory opens the businesses it contains.

The contact buttons that open WhatsApp are the last step of a flow, not the
purpose of the app. A resident searches, compares by the community rating,
saves what they liked, and only then gets in touch.


GUIDELINE 2.3.10 - SCREENSHOTS

You are correct: the previous screenshots were captured on an Android device
and showed the Android status bar. Every screenshot has been replaced with
captures taken on an iPhone 16 Pro Max simulator running this build, showing
the iOS status bar. In order, they show: the directory home screen with the
search field and the categories, the results of a search for "acai", the
detail screen of one business, the saved-favorites screen, the rating dialog,
and the subcategories inside one category.


HIDDEN ADMIN PANEL - FULL DISCLOSURE

Per guideline 2.3.1 we want to declare one non-obvious screen rather than leave
it undocumented.

On the first screen, press and hold the title "ZapBairro" in the navigation bar
for about one second. A password prompt appears. The password is:

    zapadmin2024

It opens an internal panel that we, the publisher, use to see how the directory
is being used: a visit counter per business, a ranking of the most opened
categories, and the list of ratings residents have submitted. It has no
user-facing feature, it collects nothing on its own, and it only displays data
the app already stores. It is not advertised anywhere in the app because it is
not meant for residents.

If you would prefer that this panel not ship in the public build, we will
remove it and submit again.


We are happy to provide any further detail. Thank you for your time.
```

---

## 3. Notas para a revisão do app (versão curta)

```
What changed since build 1.0.0 (5):

1. Removed the mandatory name + WhatsApp registration screen. The app now opens
   straight into the directory and nothing is gated (guideline 5.1.1).
2. Added community ratings: every business now shows its star average and the
   reviews written by residents, and any user can submit a rating with no
   account (guideline 4.2.2).
3. Rewrote the search so it matches names, descriptions, categories and
   addresses, ignoring accents and capitalization.
4. Replaced all screenshots with captures taken on an iPhone simulator
   (guideline 2.3.10).

How to test in one minute:
- Type "acai" in the search field on the first screen and tap the magnifier.
- Open any result: the star average is under the name, the neighborhood
  reviews are at the bottom. The directory is new, so most businesses read
  "Ainda sem avaliacoes" (no ratings yet) until you add one.
- Tap "Avaliar esta loja", pick stars, tap "Enviar" - the review shows up
  immediately and the average updates.
- Tap the heart on a business, then "FAVORITOS" on the home screen.

No login is required for any of the above.

Declared per guideline 2.3.1 - hidden admin panel: on the first screen, press
and hold the title "ZapBairro" for about one second and enter the password
zapadmin2024. It opens an internal usage-statistics panel for us, the
publisher. It has no user-facing feature and collects nothing on its own. We
will remove it from the build if you prefer.
```

---

## 4. Por que o texto está assim

A carta original tinha argumentos como "Sistema Operacional do Bairro",
"economia de baixo carbono" e "sentimento de pertencimento". É boa prosa, mas é
exatamente o registro que a diretriz 4.2.2 mira: o revisor lê linguagem de
marketing e conclui que o app é material de marketing.

O revisor decide em minutos e quer instruções que ele possa executar. Por isso o
texto acima é uma lista numerada de *toque aqui → veja isso acontecer*, com os
rótulos dos botões em português entre parênteses, do jeito que ele vai
encontrar na tela.

Também foi retirada a afirmação de que o app tem serviços "verificados pela
comunidade" no sentido de curadoria/moderação: o app mostra as notas que os
moradores dão, e é isso que o texto diz. Prometer à App Review algo que o app
não faz é o caminho mais rápido para uma terceira rejeição.

---

## 5. A área administrativa oculta

O app tem um painel escondido: toque longo no título "ZapBairro" na tela
inicial abre um pedido de senha (`zapadmin2024`, definida em `lib/main.dart`).
Dentro dele ficam o contador de visitas por comércio, o ranking de categorias
mais abertas e a lista de avaliações dos moradores.

**Isso precisa ser declarado.** A diretriz 2.3.1 diz, literalmente, que o app
não pode conter recursos ocultos ou não documentados. Se o revisor descobrir o
painel por conta própria — e eles testam gestos — a rejeição vem por 2.3.1, e
ainda por cima com a credibilidade das outras respostas abalada. Declarado, é
um painel interno comum, coisa que a App Review aprova todo dia.

Por isso a declaração entrou nos dois textos acima, com a senha e o passo a
passo, e junto o oferecimento de remover o painel caso eles prefiram.

### Um aviso sobre essa senha

`kAdminSenha` é uma constante de texto compilada dentro do app. Qualquer pessoa
com o `.ipa` ou o `.apk` extrai a senha em segundos — não é proteção, é só uma
forma de esconder o painel do usuário comum. Está bom para estatística de
acesso.

Deixa de estar bom no dia em que o cadastro de morador for reativado: a tela de
avaliações do painel mostra `moradorNome` e `moradorTelefone`. Hoje esses
campos vão vazios porque o cadastro está desativado, mas se voltarem a ser
preenchidos, o painel passa a expor nome e telefone de moradores atrás de uma
senha que está escrita no binário. Aí vira problema de privacidade de verdade,
e risco nas diretrizes 5.1.1 e 5.1.2. Se for reativar o cadastro, o painel
precisa sair do app e virar uma página web com autenticação de verdade.
