# Chave do Google Maps (mapa do bairro)

O mapa do app (tela "Mapa do bairro", mapa pequeno na tela da loja) usa o
Google Maps. A chave fica no **projeto Firebase do ZapBairro**
(`zapbairro-bc003`), que e um projeto do Google Cloud.

**Custo:** mostrar o mapa dentro do app nao e cobrado (o Google libera o uso
dos SDKs de Android e iOS sem limite). O "Como chegar" abre o app de mapas do
celular por link, tambem sem custo. Mesmo assim o Google **exige o faturamento
ativo** no projeto para a chave funcionar.

## Passo a passo

1. Entre em <https://console.cloud.google.com> com a conta dona do Firebase e
   selecione o projeto **zapbairro-bc003**.
2. **Faturamento**: confira em "Faturamento" que o projeto esta vinculado a
   uma conta de faturamento.
3. **APIs e servicos > Biblioteca**: ative **Maps SDK for Android** e
   **Maps SDK for iOS**.
4. **APIs e servicos > Credenciais > Criar credenciais > Chave de API**.
   Em "Restricoes de API", marque so **Maps SDK for Android** e
   **Maps SDK for iOS**. (Uma chave so aceita restricao de um tipo de app;
   como a mesma chave serve aos dois sistemas e o uso no app e gratuito,
   basta a restricao de API.)
5. Cole a chave nos dois lugares, no lugar de `COLE_AQUI_A_CHAVE_DO_GOOGLE_MAPS`:
   - `android/app/src/main/AndroidManifest.xml` (`com.google.android.geo.API_KEY`)
   - `ios/Runner/AppDelegate.swift` (`GMSServices.provideAPIKey`)
6. Gere o app de novo (`flutter build apk --release` / workflow do iOS).

Sem a chave o app funciona, mas o mapa aparece em branco (so os pinos e o
logo do Google).

Identificadores do app: Android `com.zapbairro.app`, iOS `com.zapbairro.zapbairro`.
