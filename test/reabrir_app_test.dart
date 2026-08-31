// Regressão do bug que perdeu as capturas 05-08 no run #9 do workflow de
// capturas: `const ZapBairroApp()` é sempre a MESMA instância (canonicalização
// de const), e pumpWidget com um widget idêntico ao anterior não reconstrói
// nada — a pilha de rotas velha fica de pé e o "app novo" continua na tela em
// que estava. O teste de capturas recomeça o app entre grupos com
// `ZapBairroApp(key: UniqueKey())`; estes testes garantem que esse jeito
// funciona e documentam por que o jeito antigo não funcionava.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zapbairro/main.dart';

void main() {
  Future<void> empilharRota(WidgetTester tester) async {
    final navegador = tester.state<NavigatorState>(find.byType(Navigator));
    navegador.push(
      MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('OUTRA TELA')),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('re-pump com UniqueKey volta para a tela inicial', (
    tester,
  ) async {
    await tester.pumpWidget(ZapBairroApp(key: UniqueKey()));
    expect(find.text('Explore por Categorias'), findsOneWidget);

    await empilharRota(tester);
    expect(find.text('OUTRA TELA'), findsOneWidget);
    expect(find.text('Explore por Categorias'), findsNothing);

    // O que o abrirDoZero do teste de capturas faz entre grupos.
    await tester.pumpWidget(ZapBairroApp(key: UniqueKey()));
    expect(find.text('Explore por Categorias'), findsOneWidget);
    expect(find.text('OUTRA TELA'), findsNothing);
  });

  testWidgets('re-pump de const é inofensivo e NÃO recomeça o app', (
    tester,
  ) async {
    // Não é o comportamento desejado — é o comportamento real do Flutter,
    // preso aqui para ninguém "simplificar" o abrirDoZero de volta para o
    // const e reintroduzir o bug sem perceber.
    await tester.pumpWidget(const ZapBairroApp());
    await empilharRota(tester);

    await tester.pumpWidget(const ZapBairroApp());
    await tester.pump();

    expect(find.text('OUTRA TELA'), findsOneWidget);
    expect(find.text('Explore por Categorias'), findsNothing);
  });
}
