# Chave do Google Maps (mapa do bairro)

O mapa do app (tela "Mapa do bairro", mapa pequeno na tela da loja) usa o
Google Maps.

## Onde a chave mora

- Conta Google: **zapbairro.marketplace@gmail.com**
- Projeto do Google Cloud: **zapbairro-maps**
- Chave: "Maps Platform API Key", restrita a **Maps SDK for Android** e
  **Maps SDK for iOS** (nenhuma outra API do Google funciona com ela).
- Colada em:
  - `android/app/src/main/AndroidManifest.xml` (`com.google.android.geo.API_KEY`)
  - `ios/Runner/AppDelegate.swift` (`GMSServices.provideAPIKey`)

## Custo e faturamento

- Mostrar o mapa dentro do app nao e cobrado (uso dos SDKs de Android e iOS
  sem limite). O "Como chegar" abre o app de mapas do celular por link, tambem
  sem custo.
- O Google exige faturamento ativo. No Brasil a conta so ativa depois de um
  **pagamento unico de R$ 200 (Pix)**, que fica como saldo na conta. Pago em
  2026-10-07.
- A conta de faturamento comecou como **avaliacao gratuita (90 dias)**. Antes
  de **2027-01-05** e preciso clicar em "Fazer upgrade" (ativar a conta
  completa) no console; sem isso o Google encerra o faturamento e o mapa para.

## Trocar a chave

1. <https://console.cloud.google.com/apis/credentials?project=zapbairro-maps>
   com a conta acima.
2. Criar uma chave nova (ou "Alternar chave") e restringir as APIs as duas
   acima.
3. Colar nos dois arquivos e gerar o app de novo.

Identificadores do app: Android `com.zapbairro.app`, iOS `com.zapbairro.zapbairro`.
