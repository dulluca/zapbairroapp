// Driver do `flutter drive`: grava em screenshots/ cada imagem que o teste
// integration_test/capturas_test.dart pedir via binding.takeScreenshot().
import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() async {
  await integrationDriver(
    onScreenshot: (String nome, List<int> bytes, [Map<String, Object?>? args]) async {
      final pasta = Directory('screenshots');
      if (!pasta.existsSync()) {
        pasta.createSync(recursive: true);
      }
      File('${pasta.path}/$nome.png').writeAsBytesSync(bytes);
      stdout.writeln('captura salva: ${pasta.path}/$nome.png');
      return true;
    },
  );
}
