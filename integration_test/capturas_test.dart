// Percorre o app e captura as telas usadas nas capturas da App Store.
//
// Roda no Simulador do iOS pelo workflow .github/workflows/ios-screenshots.yml,
// que salva os PNGs em screenshots/ e publica como artefato do run. As imagens
// saem com a barra de status do iOS, que e o que a diretriz 2.3.10 exige.
//
// Local:
//   flutter drive --driver=test_driver/integration_test.dart \
//     --target=integration_test/capturas_test.dart -d <id-do-simulador>
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:zapbairro/main.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // As telas leem do Firestore, entao pumpAndSettle nao serve: o
  // CircularProgressIndicator gira para sempre e o settle estoura o prazo.
  // Bombeamos por um tempo fixo, que e o suficiente para a rede responder.
  Future<void> esperar(WidgetTester tester, {int segundos = 4}) async {
    final fim = segundos * 10;
    for (var i = 0; i < fim; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  testWidgets('captura as telas principais', (tester) async {
    await tester.pumpWidget(const ZapBairroApp());
    await esperar(tester);

    // 1) Tela inicial: busca + grade de categorias.
    await binding.takeScreenshot('01-inicio');

    // 2) Resultado de busca por texto (o termo vai sem acento de proposito,
    //    para a captura mostrar que a busca acha "Acai" digitando "acai").
    await tester.enterText(find.byType(TextField).first, 'acai');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await esperar(tester);
    await binding.takeScreenshot('02-busca');

    // 3) Detalhes da primeira loja: nota da vizinhanca, endereco, horario,
    //    botao de avaliar e contato por WhatsApp.
    final primeiraLoja = find.byType(ListTile).first;
    if (primeiraLoja.evaluate().isNotEmpty) {
      await tester.tap(primeiraLoja);
      await esperar(tester);
      await binding.takeScreenshot('03-detalhes');

      // 4) Dialogo de avaliacao aberto, mostrando as estrelas.
      final botaoAvaliar = find.text('Avaliar esta loja');
      if (botaoAvaliar.evaluate().isNotEmpty) {
        await tester.ensureVisible(botaoAvaliar);
        await esperar(tester, segundos: 1);
        await tester.tap(botaoAvaliar);
        await esperar(tester, segundos: 2);
        await binding.takeScreenshot('04-avaliar');

        final cancelar = find.text('Cancelar');
        if (cancelar.evaluate().isNotEmpty) {
          await tester.tap(cancelar);
          await esperar(tester, segundos: 1);
        }
      }

      // Volta para a lista e depois para a tela inicial.
      await tester.pageBack();
      await esperar(tester, segundos: 2);
      await tester.pageBack();
      await esperar(tester, segundos: 2);
    }

    // 5) Navegacao por categoria: subcategorias de Alimentacao.
    final categoria = find.text('Alimentação');
    if (categoria.evaluate().isNotEmpty) {
      await tester.tap(categoria.first);
      await esperar(tester);
      await binding.takeScreenshot('05-categorias');
    }
  });
}
