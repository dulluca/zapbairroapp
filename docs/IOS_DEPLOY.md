# Build iOS via GitHub Actions — referencia tecnica

Como o pipeline funciona por dentro, o que mudou no repositorio e o que fazer
quando algo quebra.

> 👉 **Procurando o passo a passo de configuracao?** Esta em
> **[PUBLICACAO_PASSO_A_PASSO.md](PUBLICACAO_PASSO_A_PASSO.md)** — conta Apple,
> Firebase, secrets e submissao, na ordem, com o valor de cada campo.

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
| `ios/Podfile` | **removido** | Os plugins deste app sao Swift Packages; um Podfile presente integra CocoaPods num projeto sem pods e quebra o build |
| `pubspec.yaml` | `remove_alpha_ios: true` + icones regerados | A Apple rejeita icone com canal alpha (`ITMS-90717`) |
| `logo.png` | trocado por uma arte 1024×1024 sem marca d'agua | O anterior era 512×512 com marca d'agua "turbologo", ampliado para 1024 |
| `.gitignore` | ignora `*.p12`, `*.p8`, `*.cer`, `*.mobileprovision` | Evita commit acidental de credencial |

### Como regerar os icones

Se um dia trocar o `logo.png` de novo (mantenha 1024×1024):

```powershell
D:\dev\flutter\bin\flutter.bat pub get
D:\dev\flutter\bin\dart.bat run flutter_launcher_icons
```

Isso regenera iOS e Android de uma vez, ja sem canal alpha no iOS.

---

## Pontos de atencao que sobraram

Nenhum impede a publicacao, mas vale conhecer:

### 1. O app esta configurado como universal (iPhone + iPad)

`TARGETED_DEVICE_FAMILY = "1,2"` no `project.pbxproj`. Consequencias: a App
Store passa a **exigir capturas de tela de iPad**, e o app e revisado num iPad —
onde nunca foi testado. Trocar para `"1"` publica so para iPhone e elimina os
dois riscos.

### 2. Senha do painel administrativo

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

**`The sandbox is not in sync with the Podfile.lock`**
Alguem recriou o `ios/Podfile`. Este projeto nao usa CocoaPods: os plugins entram
como Swift Packages (`packageReferences` no `Runner.xcodeproj`) e o `pod install`
disparado pelo Podfile injeta a fase `[CP] Check Pods Manifest.lock` num projeto
que nao tem pods. Apague o `ios/Podfile` — o workflow tem uma verificacao que
falha de proposito se ele reaparecer.

**Um plugin novo exige CocoaPods**
Se o `flutter build ios` reclamar que algum plugin nao tem Swift Package, o
projeto precisa voltar para CocoaPods **por inteiro**: recrie o `Podfile` com
`platform :ios, '15.0'` (igual ao `IPHONEOS_DEPLOYMENT_TARGET`), devolva
`gem "cocoapods"` ao `ios/Gemfile` e remova as `packageReferences` de Swift
Package do `project.pbxproj`. Meio-termo entre os dois nao funciona.

**Apple recusa o build por versao/numero repetido**
Cada envio precisa de um `build_number` maior que o anterior *para a mesma
version*. Por padrao o workflow usa o numero do run, que nunca repete.
