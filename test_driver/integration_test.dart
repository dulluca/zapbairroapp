// Driver do `flutter drive`: grava em screenshots/ uma imagem para cada
// binding.takeScreenshot() pedido por integration_test/capturas_test.dart.
//
// A captura NAO usa os bytes que o Flutter entrega. Eles contem so a superficie
// do Flutter, sem a barra de status do iOS -- e a rejeicao 2.3.10 foi
// justamente sobre barra de status. Em vez disso chamamos
// `xcrun simctl io booted screenshot`, que fotografa a tela inteira do
// simulador, ja com o relogio 9:41 fixado pelo workflow.
//
// Fora do macOS (ou se o simctl falhar) caimos nos bytes do Flutter, para o
// driver continuar utilizavel em qualquer maquina.
import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

Future<bool> _capturarPeloSimulador(String destino) async {
  if (!Platform.isMacOS) return false;
  try {
    final r = await Process.run('xcrun', [
      'simctl',
      'io',
      'booted',
      'screenshot',
      destino,
    ]);
    if (r.exitCode == 0 && File(destino).existsSync()) return true;
    stderr.writeln('simctl screenshot falhou (${r.exitCode}): ${r.stderr}');
  } catch (e) {
    stderr.writeln('nao foi possivel chamar o simctl: $e');
  }
  return false;
}

Future<void> main() async {
  await integrationDriver(
    onScreenshot:
        (String nome, List<int> bytes, [Map<String, Object?>? args]) async {
      final pasta = Directory('screenshots');
      if (!pasta.existsSync()) pasta.createSync(recursive: true);

      final destino = '${pasta.path}/$nome.png';
      final nativa = await _capturarPeloSimulador(destino);
      if (!nativa) {
        File(destino).writeAsBytesSync(bytes);
      }

      stdout.writeln(
        'captura salva: $destino (${nativa ? 'simulador' : 'superficie Flutter'})',
      );
      return true;
    },
  );
}
