# App Store — envio da versão 1.1.0 (build 9)

Versão que responde à diretriz **4.2.2 (Minimum Functionality)** com três
recursos nativos: mapa do bairro, "perto de mim" e "aberto agora". As
correções das rejeições anteriores (5.1.1, 2.3.10) continuam valendo; o
histórico está em `APPLE_RESPOSTA_REVISAO.md`.

Números conferidos em 2026-10-09 no `lojistas.json` (igual ao Firestore):
157 comércios na tela (182 registros; as telas juntam o mesmo nome), 150 com
localização, 154 com horário, 12 categorias. Se mudarem muito até o envio,
corrija a carta.

---

## 1. Passo a passo

1. **Build 9 no GitHub Actions.** Actions → "iOS - Build IPA (App Store)" →
   Run workflow na `main`, com os campos vazios (versão 1.1.0 e build 9 saem do
   `pubspec.yaml`). A build 8 gerada antes não tem a correção do fuso do
   "aberto agora" (seção 5): não envie a 8.
2. **Capturas.** Actions → "iOS - Capturas de tela (App Store)" → Run
   workflow, **entre 9h e 17h de Brasília** (o "aberto agora" das fotos segue a
   hora de Belém). Baixe o artefato `capturas-ios`: são 10 imagens, de
   `01-inicio` a `10-avisos-comunitarios`. Confira se `02-mapa` mostra o mapa
   com os pinos e se nenhuma foto tem alerta do iOS.
3. **App Store Connect → ZapBairro → iOS.** Se a versão rejeitada (1.0.0)
   ainda estiver aberta, troque o número dela para **1.1.0** (o app nunca foi
   publicado, então dá para editar); senão, crie a versão 1.1.0 pelo "+".
4. **Build:** na seção "Build", remova a antiga e escolha a **1.1.0 (9)**
   quando ela aparecer (o processamento leva de 10 a 30 min depois do upload).
5. **Capturas:** em "Pré-visualizações e capturas de tela", apague **todas** as
   antigas (inclusive em "Ver todos os tamanhos no Gerenciador de Mídia") e
   suba as 10 novas no tamanho 6,9".
6. **Textos da página** (seção 2): texto promocional, descrição e
   palavras-chave.
7. **Privacidade do app** (seção 4): o questionário mudou por causa do SDK do
   Google Maps.
8. **Informações para a revisão:** cole as **Notas** (seção 3.2). Login não é
   necessário.
9. **Categoria** (Informações do app): primária **Estilo de vida**,
   secundária **Utilidades**.
10. Salvar → "Adicionar para revisão" → "Enviar para revisão".
11. **Mensagem ao revisor:** se a conversa da rejeição anterior ainda existir
    em "Revisão de apps", responda nela com a carta da seção 3.1.

---

## 2. Textos da página (português)

**Texto promocional** (até 170 caracteres; pode ser trocado sem nova revisão):

```
Novo: mapa do bairro, lojas perto de você e quem está aberto agora. Ache o comércio do Maguari e região e fale direto com a loja.
```

**Descrição** (até 4.000 caracteres):

```
ZapBairro é o guia do comércio do Conjunto Maguari e região, em Belém (PA): mais de 150 lojas e serviços do bairro em 12 categorias, a maioria sem site e fora dos aplicativos de entrega.

MAPA DO BAIRRO
Veja as lojas no mapa, com a sua posição. O pino verde é loja aberta agora, o vermelho é fechada. Toque no pino para ver a loja, a distância e traçar a rota em "Como chegar".

PERTO DE MIM
Escolha uma categoria e veja as lojas da mais perto para a mais longe, com a distância até cada uma.

ABERTO AGORA
Cada loja mostra se está aberta e quando fecha ou abre, e a semana inteira de horários. Use o filtro "Aberto agora" para ver só quem está atendendo.

E MAIS
- Busca por nome, produto ou serviço, sem se preocupar com acento.
- Avaliações da vizinhança por estrelas, sem precisar de conta.
- Favoritos para guardar as lojas que você mais usa.
- Utilidades e emergências: telefones úteis do bairro em um toque.
- Avisos comunitários: vacinação, mutirões e recados do bairro.

Sem cadastro e sem login: tudo funciona desde a primeira abertura. A sua localização é usada só no celular, para calcular a distância até as lojas, e não é salva nem enviada.
```

**Palavras-chave** (até 100 caracteres, separadas por vírgula, sem espaço):

```
bairro,maguari,belém,comércio local,lojas,perto de mim,aberto agora,mapa,serviços,guia
```

**Novidades desta versão** (o campo só aparece depois que o app tiver uma
versão publicada; guarde para a próxima):

```
Mapa do bairro, lojas perto de você com a distância, selo e filtro "Aberto agora" com o horário de cada dia, e "Como chegar" até a loja.
```

---

## 3. Texto para a revisão (inglês)

### 3.1 Resposta ao revisor (até 4.000 caracteres; este tem ~2.500)

```
Hello,

Thank you for your patience. Build 1.1.0 (9) answers guideline 4.2.2 with three
native, location-based features. The earlier fixes remain in place: no
registration, no login, no personal data, and screenshots taken on an iPhone
simulator.

ZapBairro is the neighborhood guide of Conjunto Maguari and nearby areas in
Belem, Brazil: 157 small businesses in 12 categories, most of them without a
website and absent from map and delivery apps.

NEW IN THIS BUILD

1. NEIGHBORHOOD MAP. On the first screen, tap "Mapa do bairro". A native map
   shows the 150 businesses that have a location, colored by whether they are
   open right now (green open, red closed, blue hours not informed), plus your
   position. Tap a pin for a card with the status and distance, then "Ver loja"
   (details) or "Como chegar" (directions in Apple Maps). The "Aberto agora"
   chip filters the map to the businesses open now.

2. NEAR ME. Tap a category, for example "Alimentacao", then "Perto de mim". The
   businesses are listed from nearest to farthest, each with its distance.
   Location permission is requested the first time a list or the map is
   opened, with a purpose string, and the location never leaves the device: it
   is used only to compute distances and is neither stored nor sent. Without
   permission the app keeps working with the regular list.

3. OPEN NOW. Every business shows a live status computed from its weekly
   schedule ("Aberto - fecha as 18h", "Fechado - abre amanha as 8h"), each list
   has an "Aberto agora" filter, and the detail screen shows the whole week with
   today in bold, a small map and the "Como chegar" button. The status follows
   the neighborhood's local time (Belem, UTC-3), so it is correct from any time
   zone.

TESTING FROM OUTSIDE BRAZIL

Distances from your location will read in thousands of kilometers, and the map
opens framing the neighborhood instead of your position. To see it as a
resident does, set the simulator location to -1.33186, -48.44317 (Features >
Location > Custom Location).

The previous features are still there: accent-insensitive search, community
star ratings with no account, favorites, emergency phone numbers and community
notices.

Hidden admin panel (guideline 2.3.1), disclosed as before: on the first screen,
press and hold the title "ZapBairro" for about one second and enter the
password zapadmin2024. It shows visit counts and ratings to us, the publisher,
and has no user-facing feature.

Thank you for your time.
```

### 3.2 Notas para a revisão (campo da versão)

```
Build 1.1.0 (9) adds three native, location-based features (guideline 4.2.2):

1. Neighborhood map: first screen > "Mapa do bairro". Pins colored by open/closed
   status, your position, tap a pin > "Como chegar" opens Apple Maps directions.
2. Near me: tap a category > "Perto de mim". Businesses sorted by distance, with
   the distance shown. Location is used only on the device and never stored or
   sent; the app works without it.
3. Open now: live status from each business's weekly hours (Belem time,
   UTC-3), an "Aberto agora" filter, and the weekly schedule on the detail
   screen.

Outside Brazil, distances read in thousands of km. Simulator location of the
neighborhood: -1.33186, -48.44317.

No login or account is needed for anything. Hidden admin panel (2.3.1): press
and hold the title "ZapBairro" ~1 s, password zapadmin2024 (internal visit and
rating statistics for the publisher).
```

---

## 4. Privacidade do app (questionário)

Até a 1.0 a resposta era "nenhum dado coletado". **A 1.1 usa o SDK do Google
Maps**, e a Apple exige declarar o que SDKs de terceiros coletam. O manifesto
de privacidade do Google Maps SDK for iOS 9.4.0
(`PrivacyInfo.xcprivacy` em github.com/googlemaps/ios-maps-sdk) declara:

| Tipo de dado (App Store Connect) | Vinculado ao usuário | Rastreamento | Finalidade |
|---|---|---|---|
| Identificadores → ID do dispositivo | Sim | Não | Análise; Funcionalidade do app |
| Diagnóstico → Dados de falha | Não | Não | Análise |
| Diagnóstico → Dados de desempenho | Não | Não | Análise |
| Uso → Interação com o produto | Não | Não | Análise |
| Outros dados → Outros tipos de dados | Sim | Não | Análise |

- **Localização: não declarar.** O app usa a posição só no aparelho (distância
  e o ponto azul no mapa) e o manifesto do Google Maps não declara localização.
- Respostas em App Store Connect → ZapBairro → **Privacidade do app** →
  Começar/Editar: "Sim, coletamos dados" → marcar os tipos da tabela →
  para cada um, as finalidades e "vinculado" como na tabela, e "não usado para
  rastreamento".
- O Xcode gera um "Privacy Report" do arquivo (.xcarchive) que junta os
  manifestos de todos os SDKs (inclusive Firebase). Se ele listar algo além da
  tabela, declare também.

---

## 5. Por que a build 9 e não a 8

A 8 calculava o "aberto agora" pelo relógio do celular. Para quem está em
Belém dá no mesmo, mas o revisor costuma estar nos EUA: às 21h dele (1h em
Belém) uma loja que fecha às 22h apareceria aberta. Na 9 o cálculo usa sempre a
hora de Belém (`agoraNoBairro()` em `lib/horario.dart`, com teste). A Play
Store recebeu a 8; a próxima atualização Android já sai com a correção.
