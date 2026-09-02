// A barra do topo ganhou dois botões (Utilidades/Emergências e Avisos
// Comunitários) dentro de um espaço apertado: estes testes garantem que eles
// aparecem, que ficam alinhados entre si e que nada estoura o layout.
//
// O alinhamento tem teste porque já quebrou uma vez: o AppBar estica os
// widgets de 'actions' na altura toda da barra mas centraliza o 'leading',
// e sem um Center o botão da direita nasce mais alto que o da esquerda.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zapbairro/main.dart';

void main() {
  const rotuloEmergencia = 'UTILIDADES/\nEMERGÊNCIAS';
  const rotuloAvisos = 'AVISOS\nCOMUNITÁRIOS';

  // Tela de celular estreito: é onde a barra aperta de verdade.
  Future<void> abrirTelaInicial(WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 690);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: TelaCategorias()));
  }

  testWidgets('mostra os dois botões sem estourar o layout', (tester) async {
    await abrirTelaInicial(tester);

    expect(find.text(rotuloEmergencia), findsOneWidget);
    expect(find.text(rotuloAvisos), findsOneWidget);
    expect(find.byIcon(Icons.health_and_safety), findsOneWidget);
    expect(find.byIcon(Icons.campaign), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('os dois botões ficam na mesma altura', (tester) async {
    await abrirTelaInicial(tester);

    final esquerda = tester.getRect(find.byIcon(Icons.health_and_safety));
    final direita = tester.getRect(find.byIcon(Icons.campaign));

    expect(esquerda.top, direita.top);
    expect(esquerda.size, direita.size);
  });

  testWidgets('cada rótulo fica centralizado embaixo do seu ícone', (
    tester,
  ) async {
    await abrirTelaInicial(tester);

    for (final par in {
      Icons.health_and_safety: rotuloEmergencia,
      Icons.campaign: rotuloAvisos,
    }.entries) {
      final icone = tester.getRect(find.byIcon(par.key));
      final rotulo = tester.getRect(find.text(par.value));

      expect((icone.center.dx - rotulo.center.dx).abs(), lessThan(1));
      expect(rotulo.top, greaterThan(icone.bottom));
    }
  });

  testWidgets('os dois botões ficam à mesma distância das bordas', (
    tester,
  ) async {
    await abrirTelaInicial(tester);

    final largura = tester.view.physicalSize.width / tester.view.devicePixelRatio;
    final esquerda = tester.getRect(find.text(rotuloEmergencia));
    final direita = tester.getRect(find.text(rotuloAvisos));

    expect(esquerda.left, largura - direita.right);
    expect(esquerda.width, direita.width);
  });

  testWidgets('os botões não invadem o título ZapBairro', (tester) async {
    await abrirTelaInicial(tester);

    final titulo = tester.getRect(find.text('ZapBairro'));
    final esquerda = tester.getRect(find.text(rotuloEmergencia));
    final direita = tester.getRect(find.text(rotuloAvisos));

    expect(esquerda.right, lessThanOrEqualTo(titulo.left));
    expect(direita.left, greaterThanOrEqualTo(titulo.right));
  });
}
