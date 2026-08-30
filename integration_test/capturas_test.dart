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
//    Agora cada captura exige uma PROVA -- um widget que so existe na tela
//    pronta -- e e pulada (com log) se a prova nao aparecer no prazo.
//    Captura pulada e melhor que captura errada: o artefato nunca traz uma
//    imagem mentindo o nome que carrega.
//
// 3. As provas apontam para dentro da tela nova (find.descendant). As rotas
//    anteriores do Navigator continuam montadas na arvore, entao um finder
//    solto acharia, por exemplo, o botao AVISOS da tela inicial embaixo da
//    tela de avisos, e a captura sairia cedo demais.
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:zapbairro/main.dart';

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

    // So captura quando todas as provas estao na tela e nenhum spinner
    // continua girando. Se algo nao chegar no prazo, pula com log.
    Future<void> capturar(String nome, {required List<Finder> provas}) async {
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
      // Um ultimo suspiro para a moldura terminar de desenhar (imagens,
      // estrelas de avaliacao) antes do print.
      await respirar(tester);
      await binding.takeScreenshot(nome);
      debugPrint('>>> captura ok: $nome');
    }

    // Recomeca o app na tela inicial, sem rota nenhuma empilhada.
    Future<void> abrirDoZero() async {
      await tester.pumpWidget(const ZapBairroApp());
      final pronto = await esperarAte(
        tester,
        () => find.text('Explore por Categorias').evaluate().isNotEmpty,
      );
      if (!pronto) debugPrint('### tela inicial nao terminou de abrir');
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
    // Tela inicial: acoes, busca e a grade de categorias.
    await grupo('inicio', () async {
      await abrirDoZero();
      await capturar('01-inicio', provas: [find.text('Explore por Categorias')]);
    });

    // ---------------------------------------------------------------- 2
    // Busca por texto e, na mesma corrida, os detalhes de um resultado.
    // O termo vai sem acento de proposito: a captura mostra que "acai"
    // encontra "Acai".
    await grupo('busca e detalhes', () async {
      await abrirDoZero();
      await buscar('acai');
      await capturar('02-busca', provas: [resultadoDaBusca]);

      if (resultadoDaBusca.evaluate().isEmpty) {
        debugPrint('### nenhuma loja no resultado, pulando detalhes');
        return;
      }
      await tester.tap(resultadoDaBusca.first);
      await capturar(
        '03-detalhes',
        provas: [find.byType(TelaDetalhes)],
      );

      // Rodape dos detalhes: distribuicao das notas e ultimas avaliacoes.
      final avaliar = find.text('Avaliar esta loja');
      if (avaliar.evaluate().isEmpty) {
        debugPrint('### botao "Avaliar esta loja" nao encontrado');
        return;
      }
      await tester.ensureVisible(avaliar);
      await capturar('04-avaliacoes', provas: [avaliar]);

      await tester.tap(avaliar);
      await capturar('05-avaliar', provas: [find.byType(AlertDialog)]);
    });

    // ---------------------------------------------------------------- 3
    // Navegacao por categoria: as especialidades de Alimentacao.
    await grupo('especialidades', () async {
      await abrirDoZero();
      final categoria = find.text('Alimentação');
      if (categoria.evaluate().isEmpty) {
        debugPrint('### categoria "Alimentação" nao encontrada');
        return;
      }
      await tester.tap(categoria.first);
      // Com subcategorias no banco abre TelaSubcategorias; sem, cai direto
      // na lista de comercios. Qualquer uma das duas e a tela certa.
      await capturar(
        '06-especialidades',
        provas: [
          find.byWidgetPredicate(
            (w) => w is TelaSubcategorias || w is TelaComercios,
          ),
        ],
      );
    });

    // ---------------------------------------------------------------- 4
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
      await respirar(tester, decimos: 10);

      await abrirDoZero();
      final botaoFavoritos = find.text('FAVORITOS');
      if (botaoFavoritos.evaluate().isEmpty) {
        debugPrint('### botao FAVORITOS nao encontrado');
        return;
      }
      await tester.tap(botaoFavoritos);
      await capturar(
        '07-favoritos',
        provas: [
          find.descendant(
            of: find.byType(TelaFavoritos),
            matching: find.byType(ListTile),
          ),
        ],
      );
    });

    // ---------------------------------------------------------------- 5
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
        '08-utilidades-emergencias',
        provas: [
          find.descendant(
            of: find.byType(TelaEmergencia),
            matching: find.byType(ListTile),
          ),
        ],
      );
    });

    // ---------------------------------------------------------------- 6
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
        '09-avisos-comunitarios',
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
