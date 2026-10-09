// Percorre o app e captura as telas usadas nas capturas da App Store.
//
// Roda no Simulador do iOS pelo workflow .github/workflows/ios-screenshots.yml,
// que salva os PNGs em screenshots/ e publica como artefato do run.
//
// Local:
//   flutter drive --driver=test_driver/integration_test.dart \
//     --target=integration_test/capturas_test.dart -d <id-do-simulador>
//
// REGRAS DESTE ARQUIVO:
//
// 1. Cada grupo de capturas comeca com um pumpWidget novo. Voltar de tela em
//    tela com pageBack() depende de quantas rotas estao empilhadas naquele
//    instante, e foi assim que uma etapa que falhou no meio deixou todas as
//    seguintes na tela errada. Um app novo sempre comeca na tela inicial.
//
// 2. Nenhuma captura sai por tempo. Esperar segundos fixos foi o que gerou
//    prints repetidos e fora de ordem: quando o Firestore do runner demorava
//    mais que a espera, a foto saia com a tela anterior ou com o spinner.
//    Cada captura exige uma PROVA -- um widget que so existe na tela pronta --
//    e e pulada (com log) se a prova nao aparecer no prazo. Captura pulada e
//    melhor que captura errada: o artefato nunca traz uma imagem mentindo o
//    nome que carrega.
//
// 3. A foto de verdade nao e tirada aqui. Confirmada a prova, o teste imprime
//    "###CAPTURA:<nome>" e o workflow dispara `xcrun simctl io screenshot`
//    naquele instante, com a tela de pe e com a barra de status do iOS. O
//    takeScreenshot no fim e so rede de seguranca (o driver ignora esses
//    bytes quando o simctl ja fotografou). O integration_test entrega os
//    bytes ao driver apenas quando o teste inteiro acaba -- confiar neles
//    como fonte principal foi o que ja rendeu seis capturas identicas.
//
//    Depois do sinal, o teste SEGURA A TELA ate o host confirmar a foto,
//    escrevendo um arquivo em Documents (simctl get_app_container permite ao
//    host escrever no container do app). Uma janela de tempo fixo nao basta:
//    o streaming de log do simulador ja atrasou segundos a entrega do sinal,
//    e no run #13 as capturas 03 e 04 sairam identicas a 05 porque a foto
//    so foi tirada quando o app ja estava na tela de favoritos.
//
// 4. As provas apontam para dentro da tela nova (find.descendant). As rotas
//    anteriores do Navigator continuam montadas na arvore, entao um finder
//    solto acharia, por exemplo, o botao AVISOS da tela inicial embaixo da
//    tela de avisos, e a captura sairia cedo demais.
//
// NAO existe captura do rodape dos detalhes: numa tela de 6,9 polegadas os
// detalhes cabem inteiros (avaliacoes e botao incluidos) e a foto saia
// identica a dos detalhes.
//
// 5. Versao 1.1 (mapa, perto de mim, aberto agora): o workflow instala o app,
//    concede a permissao de localizacao antes de abri-lo, poe o simulador no
//    centro do Conjunto Maguari e o relogio no fuso de Belem. Sem isso o
//    alerta de permissao do iOS sai na foto e fica por cima de TODAS as telas
//    seguintes (run de 2026-10-09: 9 de 10 capturas com o alerta, e a 03 nem
//    saiu, porque sem posicao nao ha distancia) e o "aberto agora" segue o UTC
//    do runner. Ao abrir, o teste confere a permissao; se ainda estiver
//    negada, pede ao host com "###PERMISSAO:" e espera a confirmacao, do mesmo
//    jeito que as capturas. As capturas do mapa esperam alguns segundos a mais: os blocos do
//    Google Maps chegam pela rede e nao ha widget Flutter que prove que
//    terminaram de desenhar.
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:integration_test/integration_test.dart';
import 'package:zapbairro/loja.dart';
import 'package:zapbairro/main.dart';
import 'package:zapbairro/tela_mapa.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // O Firebase e inicializado no main() do app, e o teste sobe a arvore de
    // widgets direto pelo ZapBairroApp -- sem isto aqui, toda tela que le do
    // Firestore quebra com "[core/no-app] No Firebase App '[DEFAULT]'".
    try {
      await Firebase.initializeApp();
    } on FirebaseException catch (e) {
      if (e.code != 'duplicate-app') rethrow;
    }
  });

  // As telas leem do Firestore, entao pumpAndSettle nao serve: o
  // CircularProgressIndicator gira para sempre e o settle estoura o prazo.
  // Bombeamos quadro a quadro ate a condicao valer ou o prazo acabar.
  Future<bool> esperarAte(
    WidgetTester tester,
    bool Function() condicao, {
    int timeoutSegundos = 30,
  }) async {
    for (var i = 0; i < timeoutSegundos * 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (condicao()) return true;
    }
    return false;
  }

  // Espera curta para animacoes (transicao de rota, snackbar, teclado).
  Future<void> respirar(WidgetTester tester, {int decimos = 5}) async {
    for (var i = 0; i < decimos; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  testWidgets('captura as telas principais', (tester) async {
    // Cada grupo e isolado: se um falhar, os outros ainda saem e o log diz
    // exatamente qual passo quebrou.
    Future<void> grupo(String nome, Future<void> Function() acao) async {
      try {
        await acao();
      } catch (e, pilha) {
        debugPrint('### FALHOU o grupo "$nome": $e\n$pilha');
      }
    }

    // So anuncia a captura quando todas as provas estao na tela e nenhum
    // spinner continua girando. Se algo nao chegar no prazo, pula com log e
    // o workflow avisa que a captura nao saiu.
    Future<void> capturar(
      String nome, {
      required List<Finder> provas,
      int esperaExtraDecimos = 0,
    }) async {
      for (final prova in provas) {
        final apareceu = await esperarAte(
          tester,
          () => prova.evaluate().isNotEmpty,
        );
        if (!apareceu) {
          debugPrint(
            '### captura "$nome" PULADA: nao apareceu '
            '${prova.describeMatch(Plurality.one)}',
          );
          return;
        }
      }
      final carregou = await esperarAte(
        tester,
        () => find.byType(CircularProgressIndicator).evaluate().isEmpty,
      );
      if (!carregou) {
        debugPrint('### captura "$nome" PULADA: um carregando nunca terminou');
        return;
      }
      // Um suspiro para a moldura terminar de desenhar (imagens, estrelas)
      // antes do sinal. Mapas pedem mais: os blocos vem pela rede.
      await respirar(tester, decimos: 5 + esperaExtraDecimos);

      // O workflow fotografa ao ver esta linha e confirma criando o arquivo
      // abaixo dentro do container do app. Seguramos a tela ate a confirmacao
      // chegar: o sinal viaja pelo log do simulador, que ja atrasou segundos,
      // e fotografar depois que a tela mudou e o que gera captura repetida.
      final confirmacao = File(
        '${Platform.environment['HOME']}/Documents/captura_confirmada_$nome',
      );
      debugPrint('###CAPTURA:$nome');
      final confirmou = await esperarAte(
        tester,
        confirmacao.existsSync,
      );
      if (!confirmou) {
        // Rodando local (sem o workflow) ninguem confirma; segue o fluxo e
        // vale a captura da superficie Flutter logo abaixo.
        debugPrint('### captura "$nome" sem confirmacao do host em 30s');
      }

      // Rede de seguranca, caso o simctl falhe no host.
      await binding.takeScreenshot(nome);
      debugPrint('>>> captura concluida: $nome');
    }

    // Recomeca o app na tela inicial, sem rota nenhuma empilhada.
    //
    // A UniqueKey e obrigatoria. `const ZapBairroApp()` e sempre a MESMA
    // instancia (canonicalizacao de const), e o pumpWidget com um widget
    // identico ao anterior nao reconstroi nada: a arvore velha fica de pe com
    // a pilha de rotas inteira. Foi assim que o run #9 perdeu as capturas 05
    // a 08 -- o "app novo" continuava nos detalhes com o dialogo aberto.
    // Com uma chave nova a cada chamada, o Flutter descarta a arvore velha e
    // o app realmente recomeca na tela inicial.
    Future<void> abrirDoZero() async {
      await tester.pumpWidget(ZapBairroApp(key: UniqueKey()));
      final pronto = await esperarAte(
        tester,
        () => find.text('Explore por Categorias').evaluate().isNotEmpty,
      );
      if (!pronto) {
        throw StateError('a tela inicial nao apareceu depois do pumpWidget');
      }
    }

    // A localizacao tem de estar liberada ANTES de o app pedir (o mapa e a
    // primeira lista de categoria pedem). O workflow ja concedeu com o app
    // instalado e fechado; aqui so conferimos e, se faltar, pedimos ao host.
    Future<void> garantirLocalizacao() async {
      bool liberada(LocationPermission p) =>
          p == LocationPermission.whileInUse || p == LocationPermission.always;
      var permissao = await Geolocator.checkPermission();
      debugPrint('### permissao de localizacao ao abrir: $permissao');
      if (liberada(permissao)) return;

      final confirmacao = File(
        '${Platform.environment['HOME']}/Documents/permissao_localizacao_confirmada',
      );
      debugPrint('###PERMISSAO:localizacao');
      await esperarAte(tester, confirmacao.existsSync);
      permissao = await Geolocator.checkPermission();
      debugPrint('### permissao de localizacao depois do host: $permissao');
      if (!liberada(permissao)) {
        debugPrint(
          '### ATENCAO: localizacao continua negada; o alerta do iOS vai '
          'aparecer nas capturas do mapa em diante',
        );
      }
    }

    // Digita o termo na busca da tela inicial e abre a lista de resultados.
    Future<void> buscar(String termo) async {
      await tester.enterText(find.byType(TextField).first, termo);
      await respirar(tester);
      // O tooltip e o jeito mais estavel de achar a lupa: e a acao que o
      // morador faz, e nao depende de qual icone repete na tela.
      await tester.tap(find.byTooltip('Buscar'));
      await respirar(tester);
    }

    // Resultados da busca ja carregados: um ListTile dentro da TelaComercios.
    final resultadoDaBusca = find.descendant(
      of: find.byType(TelaComercios),
      matching: find.byType(ListTile),
    );

    // ---------------------------------------------------------------- 1
    // Tela inicial: acoes, busca, o cartao do mapa e a grade de categorias.
    await grupo('inicio', () async {
      await abrirDoZero();
      await garantirLocalizacao();
      await capturar(
        '01-inicio',
        provas: [find.text('Explore por Categorias'), find.text('Mapa do bairro')],
      );
    });

    // ---------------------------------------------------------------- 2
    // Mapa do bairro: pinos das lojas (verde aberta, vermelho fechada) em
    // volta da posicao do morador.
    await grupo('mapa do bairro', () async {
      await abrirDoZero();
      await tester.tap(find.text('Mapa do bairro'));
      await capturar(
        '02-mapa',
        provas: [
          find.descendant(
            of: find.byType(TelaMapa),
            matching: find.byType(GoogleMap),
          ),
          find.descendant(
            of: find.byType(TelaMapa),
            matching: find.textContaining('no mapa'),
          ),
        ],
        esperaExtraDecimos: 60,
      );
    });

    // ---------------------------------------------------------------- 3
    // Categoria: as especialidades com os atalhos da categoria inteira, a
    // lista "perto de mim" com a distancia, o filtro "aberto agora" e os
    // detalhes da loja mais perto (horario da semana, mapa e como chegar).
    await grupo('perto de mim e aberto agora', () async {
      await abrirDoZero();
      final categoria = find.text('Alimentação');
      if (categoria.evaluate().isEmpty) {
        debugPrint('### categoria "Alimentação" nao encontrada');
        return;
      }
      await tester.tap(categoria.first);
      final pertoDeMim = find.descendant(
        of: find.byType(TelaSubcategorias),
        matching: find.text('Perto de mim'),
      );
      await capturar('06-especialidades', provas: [pertoDeMim]);
      if (pertoDeMim.evaluate().isEmpty) {
        debugPrint('### botao "Perto de mim" nao apareceu');
        return;
      }

      await tester.tap(pertoDeMim);
      final lojasDaLista = find.descendant(
        of: find.byType(TelaComercios),
        matching: find.byType(ListTile),
      );
      // A distancia so aparece com a posicao do morador e a coordenada da
      // loja: e a prova de que o "perto de mim" funcionou.
      await capturar(
        '03-perto-de-mim',
        provas: [lojasDaLista, find.byType(SeloDistancia)],
      );
      if (lojasDaLista.evaluate().isEmpty) return;

      // Detalhes da loja mais perto, que tem coordenada (por isso o "Como
      // chegar" e a prova).
      await tester.tap(lojasDaLista.first);
      await capturar(
        '05-detalhes',
        provas: [find.byType(TelaDetalhes), find.text('Como chegar')],
        esperaExtraDecimos: 40,
      );
      await tester.pageBack();
      await respirar(tester, decimos: 10);

      await tester.tap(
        find.descendant(
          of: find.byType(TelaComercios),
          matching: find.text('Aberto agora'),
        ),
      );
      await capturar('04-aberto-agora', provas: [lojasDaLista]);
    });

    // ---------------------------------------------------------------- 4
    // Busca por texto. O termo vai sem acento de proposito: a captura
    // mostra que "acai" encontra "Acai".
    await grupo('busca', () async {
      await abrirDoZero();
      await buscar('acai');
      await capturar('07-busca', provas: [resultadoDaBusca]);
    });

    // ---------------------------------------------------------------- 5
    // Favoritos: guarda uma loja e mostra a lista guardada.
    await grupo('favoritos', () async {
      await abrirDoZero();
      await buscar('acai');
      final achou = await esperarAte(
        tester,
        () => resultadoDaBusca.evaluate().isNotEmpty,
      );
      if (!achou) {
        debugPrint('### busca sem resultado, pulando favoritos');
        return;
      }

      final coracao = find.byIcon(Icons.favorite_border);
      if (coracao.evaluate().isEmpty) {
        debugPrint('### nenhum coracao vazio na lista, pulando favoritos');
        return;
      }
      await tester.tap(coracao.first);
      // A confirmacao some sozinha em ~900ms: esperamos ela sair para nao
      // aparecer atravessada na captura.
      await respirar(tester, decimos: 15);

      await abrirDoZero();
      final botaoFavoritos = find.text('FAVORITOS');
      if (botaoFavoritos.evaluate().isEmpty) {
        debugPrint('### botao FAVORITOS nao encontrado');
        return;
      }
      await tester.tap(botaoFavoritos);
      await capturar(
        '08-favoritos',
        provas: [
          find.descendant(
            of: find.byType(TelaFavoritos),
            matching: find.byType(ListTile),
          ),
        ],
      );
    });

    // ---------------------------------------------------------------- 6
    // Utilidades/Emergencias: telefones uteis agrupados por secao.
    await grupo('utilidades/emergencias', () async {
      await abrirDoZero();
      final botao = find.text('UTILIDADES/\nEMERGÊNCIAS');
      if (botao.evaluate().isEmpty) {
        debugPrint('### botao UTILIDADES/EMERGÊNCIAS nao encontrado');
        return;
      }
      await tester.tap(botao);
      await capturar(
        '09-utilidades-emergencias',
        provas: [
          find.descendant(
            of: find.byType(TelaEmergencia),
            matching: find.byType(ListTile),
          ),
        ],
      );
    });

    // ---------------------------------------------------------------- 7
    // Avisos Comunitarios: o mural do bairro, agrupado por secao.
    await grupo('avisos comunitarios', () async {
      await abrirDoZero();
      final botao = find.text('AVISOS\nCOMUNITÁRIOS');
      if (botao.evaluate().isEmpty) {
        debugPrint('### botao AVISOS COMUNITÁRIOS nao encontrado');
        return;
      }
      await tester.tap(botao);
      await capturar(
        '10-avisos-comunitarios',
        provas: [
          // Os cartoes de aviso usam o icone de megafone; procurar dentro da
          // TelaAvisos garante que nao e o botao da tela inicial por baixo.
          find.descendant(
            of: find.byType(TelaAvisos),
            matching: find.byIcon(Icons.campaign),
          ),
        ],
      );
    });
  });
}
