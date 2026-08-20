// Percorre o app e captura as telas usadas nas capturas da App Store.
//
// Roda no Simulador do iOS pelo workflow .github/workflows/ios-screenshots.yml,
// que salva os PNGs em screenshots/ e publica como artefato do run.
//
// Local:
//   flutter drive --driver=test_driver/integration_test.dart \
//     --target=integration_test/capturas_test.dart -d <id-do-simulador>
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
  // Bombeamos por um tempo fixo, folgado para a rede do runner.
  Future<void> esperar(WidgetTester tester, {int segundos = 6}) async {
    for (var i = 0; i < segundos * 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  testWidgets('captura as telas principais', (tester) async {
    // Cada etapa e isolada: se uma falhar, as outras capturas ainda saem e o
    // log diz exatamente qual passo quebrou.
    Future<void> etapa(String nome, Future<void> Function() acao) async {
      try {
        await acao();
      } catch (e) {
        debugPrint('### FALHOU a etapa "$nome": $e');
      }
    }

    // A foto nao e tirada aqui. Esta linha e o sinal para o workflow disparar
    // um `xcrun simctl io screenshot` enquanto a tela ainda esta de pe -- e o
    // unico jeito de sair a tela certa, ja que o integration_test so entrega
    // as imagens ao driver depois que o teste inteiro acaba.
    //
    // A espera logo depois do sinal e a janela do host para fotografar. O
    // takeScreenshot no fim fica como rede de seguranca, caso o simctl falhe.
    Future<void> capturar(String nome) async {
      debugPrint('###CAPTURA:$nome');
      await esperar(tester, segundos: 3);
      await binding.takeScreenshot(nome);
    }

    await tester.pumpWidget(const ZapBairroApp());
    await esperar(tester);

    // 1) Tela inicial: busca + grade de categorias.
    await capturar('01-inicio');

    // 2) Resultado de busca por texto. O termo vai sem acento de proposito,
    //    para a captura mostrar que "acai" encontra "Acai".
    await etapa('busca', () async {
      await tester.enterText(find.byType(TextField).first, 'acai');
      await esperar(tester, segundos: 1);
      // O tooltip e o jeito mais estavel de achar a lupa: e a acao que o
      // morador faz, e nao depende de qual icone repete na tela.
      await tester.tap(find.byTooltip('Buscar'));
      await esperar(tester);
      await capturar('02-busca');
    });

    // 3) Detalhes da loja: nota da vizinhanca, endereco, horario e contato.
    var abriuLoja = false;
    await etapa('detalhes', () async {
      final lojas = find.byType(ListTile);
      if (lojas.evaluate().isEmpty) {
        debugPrint('### nenhuma loja na lista, pulando os detalhes');
        return;
      }
      await tester.tap(lojas.first);
      await esperar(tester);
      abriuLoja = true;
      await capturar('03-detalhes');
    });

    // 4) Rodape dos detalhes: avaliacoes da vizinhanca e o botao de avaliar.
    await etapa('avaliar', () async {
      if (!abriuLoja) return;
      final botaoAvaliar = find.text('Avaliar esta loja');
      if (botaoAvaliar.evaluate().isEmpty) {
        debugPrint('### botao "Avaliar esta loja" nao encontrado');
        return;
      }
      await tester.ensureVisible(botaoAvaliar);
      await esperar(tester, segundos: 2);
      await capturar('04-avaliacoes');

      await tester.tap(botaoAvaliar);
      await esperar(tester, segundos: 3);
      await capturar('05-avaliar');

      final cancelar = find.text('Cancelar');
      if (cancelar.evaluate().isNotEmpty) {
        await tester.tap(cancelar);
        await esperar(tester, segundos: 2);
      }
    });

    // 5) Navegacao por categoria, a partir da tela inicial.
    await etapa('categorias', () async {
      if (abriuLoja) {
        await tester.pageBack();
        await esperar(tester, segundos: 3);
        await tester.pageBack();
        await esperar(tester, segundos: 3);
      }

      final categoria = find.text('Alimentação');
      if (categoria.evaluate().isEmpty) {
        debugPrint('### categoria "Alimentação" nao encontrada');
        return;
      }
      await tester.tap(categoria.first);
      await esperar(tester);
      await capturar('06-categorias');
    });
  });
}
