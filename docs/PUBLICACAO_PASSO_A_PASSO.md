# ZapBairro na App Store — passo a passo do que fazer fora do código

Este e o roteiro operacional: cada coisa que voce precisa fazer clicando em
site, na ordem certa, com o valor exato de cada campo.

O lado do codigo ja esta pronto. Para entender **como** o pipeline funciona por
dentro, veja [IOS_DEPLOY.md](IOS_DEPLOY.md) — aqui a gente so executa.

Reserve uns **90 minutos** para as Partes 1 a 9. A Parte 10 em diante depende da
Apple responder, entao nao da para cronometrar.

---

## Mapa geral

```
Parte 1  Apple Developer        conta paga ativa
Parte 2  Apple Developer        registrar o Bundle ID
Parte 3  App Store Connect      gerar a API Key
Parte 4  Apple Developer        anotar o Team ID
Parte 5  Firebase               registrar o app iOS
Parte 6  GitHub                 cadastrar 6 secrets
Parte 7  GitHub                 juntar o branch na main
Parte 8  GitHub Actions         rodar o bootstrap (1x) + 1 secret
Parte 9  GitHub Actions         rodar o build -> sai o .ipa
Parte 10 App Store Connect      criar o app e preencher a ficha
Parte 11 App Store Connect      enviar o build
Parte 12 App Store Connect      submeter para revisao
```

Valores que vao se repetir o tempo todo:

| O que | Valor |
| --- | --- |
| Bundle ID (iOS) | `com.zapbairro.zapbairro` |
| Nome do app | `ZapBairro` |
| Projeto Firebase | `zapbairro-bc003` |
| Repositorio | `dulluca/zapbairroapp` |

---

## Parte 1 — Conta Apple Developer

**Onde:** <https://developer.apple.com/account>

- [ ] Fazer login e confirmar que a assinatura do **Apple Developer Program**
      esta ativa (US$ 99/ano)

Se aparecer aviso de renovacao pendente ou de contrato nao aceito, resolva agora
— com a conta irregular, a API Key falha com erro generico de permissao e voce
perde tempo procurando o problema no lugar errado.

> Se a conta for de **empresa (Organization)**, confirme tambem que voce tem o
> papel de *Account Holder* ou *Admin*. Papel de *Developer* nao consegue criar
> certificado de distribuicao, e o workflow de bootstrap vai falhar.

---

## Parte 2 — Registrar o Bundle ID

**Onde:** <https://developer.apple.com/account/resources/identifiers/list>

- [ ] Clicar no **+** azul ao lado de *Identifiers*
- [ ] Escolher **App IDs** → *Continue*
- [ ] Escolher o tipo **App** → *Continue*
- [ ] Preencher:

| Campo | Valor |
| --- | --- |
| Description | `ZapBairro` |
| Bundle ID | selecionar **Explicit** e digitar `com.zapbairro.zapbairro` |

- [ ] Em *Capabilities*, **nao marcar nada** (o app so conversa com o Firestore
      por HTTPS, nao usa push, login Apple, nem compra no app)
- [ ] *Continue* → conferir a tela de resumo → **Register**

> O Bundle ID precisa ser exatamente `com.zapbairro.zapbairro`. Ele ja esta
> gravado no projeto Xcode, e o workflow tem uma verificacao que falha de
> proposito se houver divergencia — melhor errar aqui do que descobrir depois
> de 15 minutos de build.

> **Isso e permanente.** Depois que o app for publicado com esse identificador,
> ele nao muda mais. Se quiser outro, e agora.

---

## Parte 3 — Gerar a API Key do App Store Connect

E ela que deixa o GitHub Actions falar com a Apple sem sua senha e sem 2FA.

**Onde:** <https://appstoreconnect.apple.com/access/integrations/api>

- [ ] Confirmar que esta na aba **Team Keys** (nao *Individual Keys*)
- [ ] Clicar no **+**
- [ ] Preencher:

| Campo | Valor |
| --- | --- |
| Name | `github-actions` |
| Access | **App Manager** |

- [ ] *Generate*
- [ ] Clicar em **Download** na linha da chave criada

Voce vai baixar um arquivo chamado `AuthKey_XXXXXXXXXX.p8`.

> ⚠️ **So da para baixar uma vez.** Se perder, nao tem recuperacao — o jeito e
> revogar a chave e criar outra. Guarde numa pasta que voce lembre; vamos usar
> na Parte 6.

Anote os tres valores desta tela:

| O que anotar | Onde aparece |
| --- | --- |
| **Issuer ID** | no topo da pagina, formato `69a6de70-xxxx-xxxx-xxxx-xxxxxxxxxxxx` |
| **Key ID** | na coluna *KEY ID* da linha da chave (10 caracteres) |
| Arquivo `.p8` | o download que voce acabou de fazer |

---

## Parte 4 — Anotar o Team ID

**Onde:** <https://developer.apple.com/account>

- [ ] Rolar ate o painel **Membership details**
- [ ] Copiar o valor de **Team ID** — 10 caracteres, algo como `A1B2C3D4E5`

---

## Parte 5 — Registrar o app iOS no Firebase

Sem isso o app **abre e fecha na hora**. O codigo chama `Firebase.initializeApp()`
sem parametros, o que no iOS significa "leia a configuracao do
`GoogleService-Info.plist`". Se o arquivo nao existir, o app crasha na abertura —
reprovacao imediata na revisao da Apple.

**Onde:** <https://console.firebase.google.com/project/zapbairro-bc003/settings/general>

- [ ] Rolar ate a secao **Seus apps**
- [ ] Clicar em **Adicionar app** → escolher o icone da **Apple** (iOS+)
- [ ] Preencher:

| Campo | Valor |
| --- | --- |
| ID do pacote da Apple | `com.zapbairro.zapbairro` |
| Apelido do app (opcional) | `ZapBairro iOS` |
| ID da App Store (opcional) | deixar vazio |

- [ ] **Registrar app**
- [ ] **Fazer o download de GoogleService-Info.plist**
- [ ] Nas telas seguintes (adicionar SDK, código de inicialização), clicar
      **Próxima** até o fim e depois **Continuar no console** — o Flutter já
      cuida de tudo isso, nao precisa fazer nada ali

> O app Android (`com.zapbairro.app`) continua registrado do lado dele, no mesmo
> projeto. Os dois compartilham o mesmo Firestore, entao a lista de lojistas e
> identica nas duas plataformas. Identificadores diferentes por plataforma e o
> comportamento normal e esperado.

Ao final desta parte voce tem **dois arquivos** na maquina:

```
AuthKey_XXXXXXXXXX.p8        (Parte 3)
GoogleService-Info.plist     (Parte 5)
```

---

## Parte 6 — Cadastrar os secrets no GitHub

### 6.1 Converter os dois arquivos para base64

Secrets do GitHub guardam texto, e esses dois arquivos precisam chegar
intactos. Base64 resolve isso.

- [ ] Abrir o **PowerShell** e ir ate a pasta onde estao os arquivos baixados
      (troque `Downloads` se salvou em outro lugar):

```powershell
cd $HOME\Downloads
```

- [ ] Gerar o base64 do `.p8` (ajuste o nome do arquivo para o seu):

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("AuthKey_XXXXXXXXXX.p8")) | Set-Clipboard
```

O valor ja fica na area de transferencia — va direto para o passo 6.2 e cole.
Depois volte aqui e rode o segundo:

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("GoogleService-Info.plist")) | Set-Clipboard
```

> Se der erro de "arquivo nao encontrado", rode `dir` para conferir o nome exato.
> O `.p8` tem um nome comprido com o Key ID no meio.

### 6.2 Criar os secrets

**Onde:** <https://github.com/dulluca/zapbairroapp/settings/secrets/actions>

Para cada linha: clicar em **New repository secret**, preencher *Name* e
*Secret*, e clicar em **Add secret**.

| # | Name (copie exatamente) | Secret (o valor) |
| --- | --- | --- |
| 1 | `APPLE_TEAM_ID` | o Team ID da Parte 4 |
| 2 | `APPSTORE_ISSUER_ID` | o Issuer ID da Parte 3 |
| 3 | `APPSTORE_KEY_ID` | o Key ID da Parte 3 |
| 4 | `APPSTORE_PRIVATE_KEY` | o base64 do `.p8` |
| 5 | `GOOGLE_SERVICE_INFO_PLIST` | o base64 do `GoogleService-Info.plist` |
| 6 | `IOS_DIST_CERT_PASSWORD` | uma senha forte que **voce inventa agora** |

Sobre o item 6: nao e senha de nenhuma conta. E so a senha que vai proteger o
arquivo do certificado. Invente algo longo (ex.: `ZapB@irro-Cert-2026-xK9m`),
guarde no seu gerenciador de senhas e siga em frente.

- [ ] Conferir que a lista mostra **6 secrets**

> Nomes com erro de digitacao sao a causa numero 1 de falha aqui. `APPSTORE_KEY_ID`
> e diferente de `APPSTORE_KEYID`. Confira letra por letra.

> Ainda falta um setimo secret (`IOS_DIST_CERT_P12`), mas ele so existe depois
> da Parte 8 — o proprio GitHub vai gerar o conteudo dele.

---

## Parte 7 — Juntar o branch na main

Os arquivos do pipeline estao no branch `ios-appstore-pipeline`. **O GitHub so
mostra o botao "Run workflow" para workflows que estao na branch padrao**, entao
enquanto ficar no branch os workflows nem aparecem na aba Actions.

**Onde:** <https://github.com/dulluca/zapbairroapp/pull/new/ios-appstore-pipeline>

- [ ] Clicar em **Create pull request**
- [ ] Na tela seguinte, clicar em **Merge pull request** → **Confirm merge**

Ou, se preferir pelo terminal, sem passar por pull request:

```powershell
cd D:\dev\zapbairroapp
git checkout main
git merge ios-appstore-pipeline
git push origin main
```

- [ ] Confirmar em <https://github.com/dulluca/zapbairroapp/actions> que
      aparecem os dois workflows na coluna da esquerda

---

## Parte 8 — Criar o certificado (uma vez só na vida)

> ⚠️ **Se voce ja rodou este workflow e ele falhou**, faca a limpeza abaixo antes
> de rodar de novo — senao a nova execucao gasta uma segunda vaga de certificado
> na conta Apple e deixa a primeira ocupada para sempre.
>
> Um bootstrap que falha *depois* do passo "Criar certificado e provisioning
> profile" ja criou o certificado do lado da Apple. Mas a chave privada dele
> ficou no runner, que a Apple/GitHub destroi ao fim do job — ou seja, aquele
> certificado nasceu inutilizavel e so ocupa espaco.
>
> - [ ] Abrir <https://developer.apple.com/account/resources/certificates/list>
> - [ ] Localizar o certificado **Apple Distribution** criado na hora do run que
>       falhou (o ID aparece no log, na linha `Certificado gerado pelo fastlane`)
> - [ ] Clicar nele → **Revoke** → confirmar
> - [ ] So entao seguir com os passos abaixo

**Onde:** <https://github.com/dulluca/zapbairroapp/actions>

- [ ] Na lista da esquerda, clicar em **iOS - Bootstrap de assinatura (rodar uma vez)**
- [ ] Botao **Run workflow** (canto direito)
- [ ] No campo de confirmacao, digitar exatamente `CRIAR`
- [ ] Clicar no **Run workflow** verde
- [ ] Esperar terminar (~3 minutos) e confirmar o ✅ verde

Se der ❌, pule para [Quando algo da errado](#quando-algo-da-errado) no fim.

### Pegar o certificado gerado

- [ ] Clicar no run que acabou de rodar
- [ ] Rolar ate o fim da pagina, secao **Artifacts**
- [ ] Baixar **ios-signing-bootstrap** (vem como `.zip`)
- [ ] Descompactar

Dentro tem:

| Arquivo | Para que serve |
| --- | --- |
| `IOS_DIST_CERT_P12.base64.txt` | o conteudo do proximo secret |
| `distribution.p12` | o certificado em si — **guarde num lugar seguro** |
| `*.mobileprovision` | so referencia, o build baixa sozinho |

### Criar o ultimo secret

- [ ] Abrir `IOS_DIST_CERT_P12.base64.txt` no **Bloco de Notas**
- [ ] Selecionar tudo (`Ctrl+A`) e copiar (`Ctrl+C`)
- [ ] Em <https://github.com/dulluca/zapbairroapp/settings/secrets/actions>,
      criar o secret:

| Name | Secret |
| --- | --- |
| `IOS_DIST_CERT_P12` | o conteudo copiado |

- [ ] Guardar o `distribution.p12` no seu gerenciador de senhas ou num drive
      privado. **Nao coloque no repositorio.**

> 🚫 **Nao rode este workflow de novo.** A Apple permite poucos certificados de
> distribuicao por conta, e cada execucao gasta uma vaga. Se um dia precisar
> recriar, primeiro revogue o antigo em
> <https://developer.apple.com/account/resources/certificates/list>.

---

## Parte 9 — Gerar o .ipa

**Onde:** <https://github.com/dulluca/zapbairroapp/actions>

- [ ] Clicar em **iOS - Build IPA (App Store)**
- [ ] **Run workflow**
- [ ] Deixar os dois campos vazios (usa `1.0.0` do pubspec e o numero do run
      como build number)
- [ ] **Run workflow** verde

Demora **15 a 25 minutos** na primeira vez (o Firestore e grande de compilar).
Nas proximas fica mais rapido por causa do cache.

- [ ] Terminou com ✅ → abrir o run → secao **Artifacts** → baixar
      **ZapBairro-ios-\<numero\>**

Dentro tem o `ZapBairro.ipa` (o app) e o `.dSYM.zip` (simbolos, uteis para
decifrar relatorios de crash mais tarde).

🎉 **A parte tecnica acabou aqui.** Da Parte 10 em diante e preenchimento de
ficha na Apple.

---

## Parte 10 — Criar o app no App Store Connect

**Onde:** <https://appstoreconnect.apple.com/apps>

- [ ] **+** → **Novo app**
- [ ] Preencher:

| Campo | Valor |
| --- | --- |
| Plataformas | marcar **iOS** |
| Nome | `ZapBairro` |
| Idioma principal | `Português (Brasil)` |
| Pacote | selecionar `com.zapbairro.zapbairro` na lista |
| SKU | `zapbairro-001` (codigo interno seu, ninguem ve) |
| Acesso de usuario | *Acesso total* |

- [ ] **Criar**

> Se o Bundle ID nao aparecer na lista, a Parte 2 nao foi concluida. Volte e
> registre o identificador.

### 10.1 Preencher a ficha da loja

Na pagina do app, aba **Distribuição da App Store** (ou *Informações do app*),
tudo isto e obrigatorio:

- [ ] **Subtítulo** — ate 30 caracteres. Ex.: `O comércio do seu bairro`
- [ ] **Categoria principal** — sugestao: `Compras`
- [ ] **Descrição** — o que o app faz, em portugues, sem prometer nada que ele
      nao faz
- [ ] **Palavras-chave** — separadas por virgula. Ex.:
      `bairro, comércio local, lojas, delivery, whatsapp`
- [ ] **URL de suporte** — obrigatorio, precisa ser uma pagina que abre
- [ ] **URL da política de privacidade** — obrigatorio (detalhes em 10.3)
- [ ] **Classificação etária** — responder o questionario; para este app tende
      a dar *4+*
- [ ] **Direitos autorais** — ex.: `2026 ZapBairro`

### 10.2 Capturas de tela

Este e o passo que mais trava gente, entao leia com atencao.

O app esta configurado como **universal** — roda em iPhone **e iPad**. Por causa
disso a Apple exige capturas das **duas** famílias de aparelho:

| Aparelho | Resolucao | Quantidade |
| --- | --- | --- |
| iPhone 6.9" | 1290 × 2796 | 1 a 10 |
| iPad 13" | 2064 × 2752 | 1 a 10 |

Como gerar sem ter os aparelhos: rode o app no Chrome com o modo de dispositivo
(`F12` → icone de celular) na resolucao certa, ou use um emulador Android com
essas dimensoes e recorte. Nao precisa ser bonito na primeira submissao, mas
precisa mostrar o app de verdade — a Apple reprova imagem generica ou so com
texto de marketing.

> 💡 **Quer evitar as capturas de iPad?** Da para publicar so para iPhone. E uma
> mudanca de uma linha no projeto (`TARGETED_DEVICE_FAMILY` de `"1,2"` para
> `"1"`). Alem de dispensar as capturas de iPad, evita que a Apple reprove por
> layout quebrado em tela grande — que e um risco real, porque o app nunca foi
> testado em iPad. **Me avise se quiser que eu faca essa mudanca.**

### 10.3 Política de privacidade

Obrigatoria para todo app, sem excecao. Precisa ser uma URL publica que abre num
navegador.

O texto precisa dizer, no minimo: que o app registra visitas as lojas no
Firebase Firestore, que nao pede cadastro nem login, e um e-mail de contato.

Se nao tiver site, da para hospedar de graca no GitHub Pages, no Google Sites ou
em qualquer gerador de politica de privacidade.

### 10.4 Questionário de privacidade do app

**Onde:** pagina do app → menu lateral → **Privacidade do app** → *Começar*

O app grava contagem de visitas por loja no Firestore. Responda com honestidade:

- [ ] "Você coleta dados deste app?" → **Sim**
- [ ] Marcar **Identificadores → ID do dispositivo** e/ou **Uso → Interação com
      o produto**, conforme o que o app registra
- [ ] Para cada item: marcar que **não** e vinculado a identidade do usuario e
      **não** e usado para rastreamento

> Responder errado aqui e motivo de rejeicao, e a Apple confere contra o
> comportamento real do app. Na duvida, declare a mais.

---

## Parte 11 — Enviar o build para a Apple

⚠️ **Leia antes de comecar:** o `.ipa` que voce baixou na Parte 9 precisa ser
enviado com o **Transporter**, que **só existe para macOS**. Como voce trabalha
no Windows, existem dois caminhos:

### Caminho A — Ligar o envio automatico (recomendado)

O proprio GitHub Actions manda o build direto para a Apple, e voce nunca precisa
de um Mac. E uma alteracao pequena no pipeline, e toda a autenticacao ja esta
configurada (a API Key da Parte 3 serve para isso tambem).

**Me peca para ativar o envio automatico** — depois disso, cada execucao do
workflow entrega o build no TestFlight sozinha, e a Parte 11 deixa de existir.

### Caminho B — Alguem com Mac envia por voce

- [ ] Passe o `.ipa` para alguem que tenha um Mac
- [ ] Essa pessoa instala o **Transporter** (gratis, na Mac App Store)
- [ ] Faz login com a sua conta Apple
- [ ] Arrasta o `.ipa` para a janela e clica em **Deliver**

### Depois do envio (nos dois caminhos)

- [ ] Esperar de 5 a 30 minutos — a Apple processa o build
- [ ] Conferir em App Store Connect → seu app → **TestFlight** se o build
      aparece com status *Pronto para testar*

Se chegar um e-mail da Apple apontando erro, o build foi recusado no
processamento e nao vai aparecer. O e-mail diz o motivo.

---

## Parte 12 — Submeter para revisão

**Onde:** pagina do app → **Distribuição da App Store** → versao `1.0.0`

- [ ] Na secao **Build**, clicar em **+** e selecionar o build enviado
- [ ] Preencher **Informações de revisão**:
  - Contato: seu nome, telefone e e-mail
  - Notas para a revisão: explique o app em duas linhas. Ex.:
    *"App gratuito de divulgação do comércio de bairro. Não exige cadastro nem
    login. Ao tocar em uma loja, abre uma conversa no WhatsApp."*
- [ ] **Versão da liberação**: escolher *Liberar automaticamente* ou
      *Liberar manualmente* (manual da mais controle na primeira vez)
- [ ] Clicar em **Adicionar para revisão** → **Enviar para revisão**

A revisao costuma levar de **24 a 72 horas**. Voce recebe e-mail a cada mudanca
de status.

> Se for reprovado, nao entre em panico — e comum na primeira submissao. A Apple
> manda o motivo especifico no *Centro de Resoluções*. Me mostre a mensagem que
> eu ajudo a corrigir.

---

## Quando algo da errado

### O workflow falha logo no comeco: "Secrets faltando: ..."

A mensagem lista exatamente quais. Confira o nome em
<https://github.com/dulluca/zapbairroapp/settings/secrets/actions> — quase sempre
e erro de digitacao ou um espaco sobrando.

### "GoogleService-Info.plist e do bundle 'X', mas o app e 'com.zapbairro.zapbairro'"

Na Parte 5 o app iOS foi registrado no Firebase com outro identificador.
Registre de novo com `com.zapbairro.zapbairro`, baixe o plist, refaca o base64 e
atualize o secret `GOOGLE_SERVICE_INFO_PLIST`.

### "No signing certificate found" ou erro ao importar o .p12

O secret `IOS_DIST_CERT_P12` veio truncado, ou o `IOS_DIST_CERT_PASSWORD` nao
confere. Abra o `IOS_DIST_CERT_P12.base64.txt` de novo, copie **tudo**
(`Ctrl+A`), e atualize o secret.

### "Nao foi possivel ler o .p12 gerado pelo fastlane"

Bug do pipeline, ja corrigido. O passo que empacotava o certificado assumia que o
arquivo `<ID>.p12` do fastlane era um PKCS#12, quando na verdade ele guarda so a
chave privada — o certificado sai separado, num `.cer`.

Se voce viu esse erro, o certificado **chegou a ser criado** na conta Apple.
Revogue ele antes de rodar de novo, seguindo o aviso no inicio da
[Parte 8](#parte-8--criar-o-certificado-uma-vez-só-na-vida). Depois puxe a
correcao para a `main` e rode o bootstrap outra vez.

### O bootstrap falha com erro de permissao

A conta Apple nao tem papel suficiente, ou a API Key foi criada com Access menor
que **App Manager**. Confira na Parte 3 — se estiver errado, revogue a chave e
crie outra.

### A Apple recusa o build por versao repetida

Cada envio precisa de um build number maior que o anterior. O workflow usa o
numero do run automaticamente, entao isso so acontece se voce preencher o campo
`build_number` na mao com um valor ja usado. Deixe vazio.

### Qualquer outro erro no workflow

Abra o run que falhou, clique no passo com ❌ e copie a mensagem. Se nao ficar
claro, o run tambem publica um artefato **ios-build-logs-\<numero\>** com o log
completo do Xcode.
