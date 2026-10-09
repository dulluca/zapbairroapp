# Planilhas -> lojistas.json (via csvjson.com)

O `lojistas.json` NAO e uma lista so: ele guarda **tres listas** (`lojistas`,
`emergencia`, `avisos`). O csvjson.com converte **um CSV = uma lista**, entao
existe **um CSV para cada lista**:

| Arquivo          | Vira a lista  | Colunas (a ordem nao importa, o nome sim)                                             |
|------------------|---------------|---------------------------------------------------------------------------------------|
| `lojistas.csv`   | `"lojistas"`  | categoria, subcategoria, nome, descricao, endereco, localizacao, horario, seg, ter, qua, qui, sex, sab, dom, entrega, telefone, telefone2 |
| `emergencia.csv` | `"emergencia"`| secao, nome, descricao, telefone, ordem                                               |
| `avisos.csv`     | `"avisos"`    | secao, titulo, mensagem, data, ordem                                                  |

Os tres arquivos ja vem preenchidos com **tudo o que esta hoje no
lojistas.json** (182 lojistas, 9 emergencias, 13 avisos, conferidos com o Firestore em 2026-10-09). Edite a planilha,
converta e cole de volta.

## Regras das colunas

- **A primeira linha e o cabecalho** e tem que ser exatamente esses nomes:
  minusculos, sem acento, sem espaco. E o nome da coluna que vira a chave do JSON.
- **Nao invente coluna nova.** Coluna que o app nao conhece e ignorada no app,
  mas vai parar no Firestore a toa.
- **`ordem`** (emergencia e avisos): so numero inteiro (1, 2, 3...). O app le esse
  campo como numero — se vier texto, a tela quebra. Pode ficar vazio (vai para o fim).
- **`data`** (avisos): formato `AAAA-MM-DD` (ex.: `2026-08-31`). Pode ficar vazia.
  Cuidado: o Excel/Sheets adora reformatar data para `31/08/2026` — formate a
  coluna como **Texto** antes de digitar.
- **`telefone` / `telefone2`**: so os digitos, com DDI e DDD (`5591987440555`).
  Vazio = o botao de ligar/WhatsApp nao aparece.
- **Campo vazio**: deixe a celula em branco (vira `""`). Nao escreva "null" nem "-".
- **Virgula, aspas ou quebra de linha dentro do texto**: pode usar. Ao salvar como
  CSV a planilha ja poe as aspas sozinha — nao mexa nelas na mao.

## Localizacao e horario das lojas (versao 1.1 do app)

Sao essas colunas que fazem funcionar o **"Perto de mim"** (lista do mais
perto para o mais longe, com a distancia), o **"Aberto agora"** e o **Mapa do
bairro**. Loja sem essas colunas continua aparecendo normalmente, so que sem
distancia, sem pino no mapa e com "Horario nao informado".

- **`localizacao`**: a coordenada da loja, do jeito que o Google Maps copia:
  `-1.33186, -48.44317` (latitude, longitude, com ponto).
  Como pegar: no Google Maps, **segure o dedo em cima da loja** (no computador,
  clique com o botao direito) -> aparecem os numeros no topo -> toque neles
  para copiar -> cole na celula. Vazio = loja fora do mapa e sem distancia.
- **`seg`, `ter`, `qua`, `qui`, `sex`, `sab`, `dom`**: o horario de cada dia,
  no formato `08:00-18:00`. Dois turnos: `08:00-12:00 e 14:00-18:00`.
  - Fechado no dia: deixe a celula **vazia**.
  - Aberto o dia todo: `24h`.
  - Passa da meia-noite: `19:00-01:00` (fecha a 1h do dia seguinte).
  - Ate meia-noite: `18:00-24:00`.
  - **Todos os sete dias vazios** = o app mostra "Horario nao informado".
  - Formate essas colunas como **Texto** antes de digitar, para o Excel nao
    transformar `08:00` em hora/numero.
- **`horario`** (texto livre, ex.: "Segunda a sabado das 8h as 18h"): so a
  versao 1.0 do app, que ainda esta nas lojas, usa essa coluna. Pode manter
  como esta; quando todo mundo estiver na 1.1, ela pode sair.
- Em 2026-10-08 o `lojistas.json` foi refeito a partir do que estava no
  Firestore (242 lojas: o arquivo do repositorio estava velho, com 228) e os
  horarios em texto viraram as colunas dos dias (156 lojas). As que estavam
  vazias ou com "ENTRE EM CONTATO" ficaram sem horario, e nenhuma loja tem
  `localizacao` ainda. **Use este arquivo (ou `planilhas/lojistas.csv`) como
  base daqui para frente**: importar uma copia antiga apaga as lojas novas e
  os horarios.

## O importar.dart protege as visitas

- Antes de apagar `comercios`, ele le o contador de visitas de cada loja e
  devolve para a mesma loja (nome + categoria + subcategoria; se a loja mudou
  de categoria, vai pelo nome). Loja que saiu do JSON perde o contador e o
  importador avisa.
- Toda importacao de lojistas salva antes uma copia do Firestore em
  `backups/comercios-<data>.json` (fora do git).
- Para ver o que vai acontecer sem gravar nada:
  `dart run importar.dart lojistas --simular`. Se o numero de lojas do backup
  for maior que o do JSON, pare: o Firestore tem lojas que o arquivo nao tem.
- O teste `flutter test test/coordenadas_test.dart` confere se todo horario e
  toda localizacao do `lojistas.json` estao num formato que o app entende.

## Como converter no csvjson.com

1. Salve a planilha como **CSV UTF-8, separado por virgula**
   (Google Sheets: `Arquivo > Fazer download > .csv` — ja sai certo.
   Excel pt-BR: `Salvar como > CSV UTF-8 (delimitado por virgula)`).
2. Abra <https://csvjson.com/csv2json>, cole o conteudo do CSV no lado esquerdo.
3. Marque/ajuste as opcoes:
   - **Parse numbers: LIGADO**  <- obrigatorio, e o que faz `ordem` sair como `1`
     e nao como `"1"`.
   - Parse JSON: desligado.
   - Output: **Array** (nao "Hash"/"Dictionary").
   - Delimiter/Separator: **,** (virgula).
4. Clique em **Convert**. O lado direito sai assim:

```json
[
  { "secao": "Emergências principais (24h)", "nome": "Polícia Militar",
    "descricao": "Emergência policial", "telefone": 190, "ordem": 1 }
]
```

5. Copie esse resultado e cole no `lojistas.json` **substituindo o conteudo da
   lista correspondente** — ou seja, tudo o que esta entre os colchetes de
   `"emergencia": [ ... ]` (colchetes incluidos). Nao apague o `_leia_me`,
   o `_como_editar` nem as outras duas listas.
6. Rode a importacao:

```
dart run importar.dart emergencia
```

(sem argumento importa as tres listas; com argumento importa so a que voce
mudou — as outras ficam intactas no Firestore).

## Detalhes que confundem

- **Nao existe um CSV unico para o arquivo inteiro.** Se colocar as tres listas
  numa planilha so, o csvjson devolve uma lista misturada e o `importar.dart`
  nao acha `lojistas`/`emergencia`/`avisos`.
- **BOM**: se ao converter a primeira coluna aparecer como `"ï»¿categoria"`,
  o arquivo veio com BOM. Apague os caracteres invisiveis antes do `categoria`
  no csvjson, ou baixe o CSV pelo Google Sheets.
- **Ponto e virgula**: se o CSV sair separado por `;` (padrao do Excel em
  portugues), o csvjson devolve uma coluna so. Salve como
  "CSV UTF-8 (delimitado por virgula)" ou troque o separador no site.
- **`telefone` como numero e normal.** O app converte para texto na hora de
  exibir; `190` e `"190"` funcionam igual.
