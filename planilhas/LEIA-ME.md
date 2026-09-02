# Planilhas -> lojistas.json (via csvjson.com)

O `lojistas.json` NAO e uma lista so: ele guarda **tres listas** (`lojistas`,
`emergencia`, `avisos`). O csvjson.com converte **um CSV = uma lista**, entao
existe **um CSV para cada lista**:

| Arquivo          | Vira a lista  | Colunas (a ordem nao importa, o nome sim)                                             |
|------------------|---------------|---------------------------------------------------------------------------------------|
| `lojistas.csv`   | `"lojistas"`  | categoria, subcategoria, nome, descricao, endereco, horario, entrega, telefone, telefone2 |
| `emergencia.csv` | `"emergencia"`| secao, nome, descricao, telefone, ordem                                               |
| `avisos.csv`     | `"avisos"`    | secao, titulo, mensagem, data, ordem                                                  |

Os tres arquivos ja vem preenchidos com **tudo o que esta hoje no
lojistas.json** (228 lojistas, 26 emergencias, 14 avisos). Edite a planilha,
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
