# Publicar o ZapBairro na App Store via GitHub Actions

Este guia cobre o caminho completo: da conta Apple ate o `.ipa` assinado saindo
como artefato do GitHub Actions. Tudo roda na nuvem — **voce nao precisa de um Mac**.

---

## Visao geral

| Workflow | Quando rodar | O que faz |
| --- | --- | --- |
| `iOS - Bootstrap de assinatura` | **uma unica vez** | Cria o certificado Apple Distribution e devolve o `.p12` |
| `iOS - Build IPA (App Store)` | a cada release | Compila, assina e publica o `.ipa` como artefato |

O bootstrap e separado de proposito: a Apple limita a **poucos certificados de
distribuicao por conta**. Se o build criasse um certificado novo a cada execucao,
a conta travaria depois de tres builds. Por isso o certificado e criado uma vez,
guardado como secret, e reutilizado sempre.

---

## Parte 1 — O que preparar no portal da Apple

### 1.1 Registrar o Bundle ID

1. Acesse <https://developer.apple.com/account/resources/identifiers/list>
2. **+** → *App IDs* → *App*
3. Description: `ZapBairro`
4. Bundle ID: **Explicit** → `com.zapbairro.zapbairro`
5. Capabilities: nao marque nada (o app so usa Firestore por HTTPS)
6. *Continue* → *Register*

> O Bundle ID precisa ser exatamente `com.zapbairro.zapbairro`. Ele ja esta
> gravado no `ios/Runner.xcodeproj` e o workflow falha de proposito se houver
> divergencia.

### 1.2 Criar o app no App Store Connect

1. Acesse <https://appstoreconnect.apple.com/apps>
2. **+** → *Novo app*
3. Plataforma: iOS · Nome: `ZapBairro` · Idioma primario: Portugues (Brasil)
4. Bundle ID: selecione `com.zapbairro.zapbairro`
5. SKU: `zapbairro-001` (qualquer identificador interno serve)

### 1.3 Gerar a App Store Connect API Key

1. Acesse <https://appstoreconnect.apple.com/access/integrations/api>
2. Aba *Integrations* → *Team Keys* → **+**
3. Nome: `github-actions` · Access: **App Manager**
4. Baixe o arquivo `AuthKey_XXXXXXXXXX.p8` — **so da para baixar uma vez**
5. Anote o **Key ID** (o `XXXXXXXXXX` do nome) e o **Issuer ID** (no topo da pagina)

### 1.4 Anotar o Team ID

Em <https://developer.apple.com/account> → *Membership details* → **Team ID**
(10 caracteres, ex.: `A1B2C3D4E5`).

---

## Parte 2 — Firebase para iOS

O app chama `Firebase.initializeApp()` **sem parametros**, o que no iOS significa
"leia tudo do `GoogleService-Info.plist`". Sem esse arquivo o app compila normal
e **crasha ao abrir** — reprovacao certa na revisao da Apple.

1. Acesse <https://console.firebase.google.com/project/zapbairro-bc003/settings/general>
2. *Seus apps* → **Adicionar app** → icone da Apple
3. ID do pacote iOS: `com.zapbairro.zapbairro`
4. Apelido: `ZapBairro iOS`
5. Baixe o `GoogleService-Info.plist`

Voce pode usar o arquivo de duas formas:

- **Como secret (recomendado):** converta para base64 e guarde em
  `GOOGLE_SERVICE_INFO_PLIST` (instrucoes na Parte 3).
- **Versionado:** salve como `ios/Runner/GoogleService-Info.plist` e commite.
  E o mesmo criterio ja usado no Android com o `google-services.json`.

O workflow aceita as duas; se o secret existir, ele vence.

---

## Parte 3 — Cadastrar os secrets no GitHub

Em `https://github.com/dulluca/zapbairroapp/settings/secrets/actions` →
**New repository secret**, crie:

| Secret | Conteudo |
| --- | --- |
| `APPLE_TEAM_ID` | O Team ID de 10 caracteres (passo 1.4) |
| `APPSTORE_ISSUER_ID` | Issuer ID da API Key (passo 1.3) |
| `APPSTORE_KEY_ID` | Key ID da API Key (passo 1.3) |
| `APPSTORE_PRIVATE_KEY` | O `.p8` **em base64** |
| `IOS_DIST_CERT_PASSWORD` | Uma senha forte inventada por voce (protege o `.p12`) |
| `GOOGLE_SERVICE_INFO_PLIST` | O `GoogleService-Info.plist` **em base64** |
| `IOS_DIST_CERT_P12` | Preenchido depois, na Parte 4 |

### Como gerar o base64 no Windows

Abra o **PowerShell** na pasta onde estao os arquivos:

```powershell
# .p8 da API Key  ->  secret APPSTORE_PRIVATE_KEY
[Convert]::ToBase64String([IO.File]::ReadAllBytes("AuthKey_XXXXXXXXXX.p8")) | Set-Clipboard

# GoogleService-Info.plist  ->  secret GOOGLE_SERVICE_INFO_PLIST
[Convert]::ToBase64String([IO.File]::ReadAllBytes("GoogleService-Info.plist")) | Set-Clipboard
```

O valor ja fica na area de transferencia: e so colar no campo do secret.
Cole **sem quebras de linha e sem espacos** no inicio ou fim.

---

## Parte 4 — Criar o certificado (uma vez so)

1. Confirme que os secrets da Parte 3 ja existem (menos o `IOS_DIST_CERT_P12`).
2. No GitHub: aba **Actions** → **iOS - Bootstrap de assinatura (rodar uma vez)**
   → *Run workflow*.
3. No campo de confirmacao digite `CRIAR` e execute.
4. Quando terminar, baixe o artefato **ios-signing-bootstrap** no rodape do run.
5. Abra `IOS_DIST_CERT_P12.base64.txt`, copie todo o conteudo e crie o secret
   **`IOS_DIST_CERT_P12`** com ele.
6. Guarde o `distribution.p12` num lugar seguro (gerenciador de senhas, drive
   privado). Ele **nao** vai para o repositorio.

> Nao rode este workflow de novo. Cada execucao gasta uma vaga de certificado da
> conta Apple. Se precisar recriar, revogue o antigo primeiro em
> <https://developer.apple.com/account/resources/certificates/list>.

---

## Parte 5 — Gerar o .ipa

Aba **Actions** → **iOS - Build IPA (App Store)** → *Run workflow*.

| Campo | Se deixar vazio |
| --- | --- |
| `version` | usa o `version:` do `pubspec.yaml` (hoje `1.0.0`) |
| `build_number` | usa o numero do run, que sempre cresce |

O workflow tambem dispara sozinho ao criar uma tag `v*`:

```powershell
git tag v1.0.0
git push origin v1.0.0
```

Nesse caso o `version` sai da propria tag (`v1.0.0` → `1.0.0`).

Ao final, o artefato **`ZapBairro-ios-<build>`** contem o `.ipa` assinado e os
symbols (`.dSYM.zip`, uteis para ler crashes depois).

### Enviar para a App Store

1. Baixe e descompacte o artefato.
2. Abra o **Transporter** (app gratuito da Apple, so para macOS) ou peca a
   alguem com Mac. Alternativa sem Mac: mudar o workflow para fazer upload
   automatico — veja a secao "Automatizar o upload" abaixo.
3. Arraste o `.ipa`, clique em *Deliver*.
4. O build aparece em App Store Connect → *TestFlight* apos alguns minutos de
   processamento.

---

## Automatizar o upload (opcional)

Como a API Key ja esta configurada, ativar o envio automatico e barato. Basta
acrescentar ao final da lane `build_ipa` no [ios/fastlane/Fastfile](../ios/fastlane/Fastfile):

```ruby
upload_to_testflight(
  api_key: chave,
  skip_waiting_for_build_processing: true,
  distribute_external: false
)
```

Feito isso, cada run manda o build direto para o TestFlight e o Transporter
deixa de ser necessario.

---

## Mudancas que ja foram feitas no projeto

Para o build iOS ser aceitavel pela Apple, o repositorio recebeu:

| Arquivo | Mudanca | Motivo |
| --- | --- | --- |
| `ios/Runner.xcodeproj/project.pbxproj` | Bundle ID `com.example.zapbairroFix` → `com.zapbairro.zapbairro` | A Apple rejeita qualquer `com.example.*` |
| `ios/Runner.xcodeproj/project.pbxproj` | `IPHONEOS_DEPLOYMENT_TARGET` 13.0 → 15.0 | Firebase iOS SDK 12.14 exige iOS 15 |
| `ios/Runner.xcodeproj/project.pbxproj` | `GoogleService-Info.plist` adicionado aos *Resources* do target Runner | Sem isso o arquivo nao entra no `.app` |
| `ios/Runner/Info.plist` | Nome de exibicao `Zapbairro Fix` → `ZapBairro` | E o nome que aparece embaixo do icone |
| `ios/Runner/Info.plist` | `ITSAppUsesNonExemptEncryption = false` | Evita o questionario de exportacao a cada envio |
| `ios/Podfile` | criado, com `platform :ios, '15.0'` | Alinha os pods com o deployment target |
| `pubspec.yaml` | `remove_alpha_ios: true` + icones regerados | A Apple rejeita icone com canal alpha (`ITMS-90717`) |
| `.gitignore` | ignora `*.p12`, `*.p8`, `*.cer`, `*.mobileprovision` | Evita commit acidental de credencial |

---

## Pendencias que dependem de voce

Estas nao dao para resolver no codigo:

### 1. O logo esta com marca d'agua

O `logo.png` (e portanto todos os icones gerados) tem a marca d'agua
**"turbologo"** repetida sobre a arte. Isso tende a ser reprovado na revisao da
Apple e e um problema de licenca de uso.

Providencie a versao limpa do logo, substitua o `logo.png` na raiz e rode:

```powershell
D:\dev\flutter\bin\flutter.bat pub get
D:\dev\flutter\bin\dart.bat run flutter_launcher_icons
```

### 2. Questionario de privacidade no App Store Connect

O app registra visitas no Firestore, entao voce precisa declarar isso em
App Store Connect → seu app → *Privacidade do app*. Sem esse preenchimento a
Apple nao libera a submissao (e um formulario no site, nao mexe no codigo).

### 3. Senha do painel administrativo

`kAdminSenha` em [lib/main.dart](../lib/main.dart) esta em texto puro dentro do
app (`zapadmin2024`). Qualquer pessoa consegue extrair isso de um `.ipa`. Nao
impede a publicacao, mas nao trate como uma protecao real.

---

## Problemas comuns

**`No signing certificate "iOS Distribution" found`**
O secret `IOS_DIST_CERT_P12` esta vazio, truncado ou com a senha errada em
`IOS_DIST_CERT_PASSWORD`. Recopie o base64 inteiro, sem quebras de linha.

**`GoogleService-Info.plist e do bundle 'X', mas o app e 'com.zapbairro.zapbairro'`**
Voce registrou o app iOS no Firebase com outro Bundle ID. Registre de novo com
`com.zapbairro.zapbairro` e baixe o plist novamente.

**`The provisioning profile does not include the signing certificate`**
Acontece se o certificado foi recriado depois do profile. Revogue o profile em
<https://developer.apple.com/account/resources/profiles/list> — o proximo build
gera um novo automaticamente.

**Build falha no CocoaPods com erro de deployment target**
Confira se `ios/Podfile` (`platform :ios, '15.0'`) e o `IPHONEOS_DEPLOYMENT_TARGET`
do `project.pbxproj` continuam iguais. Os dois precisam andar juntos.

**Apple recusa o build por versao/numero repetido**
Cada envio precisa de um `build_number` maior que o anterior *para a mesma
version*. Por padrao o workflow usa o numero do run, que nunca repete.
