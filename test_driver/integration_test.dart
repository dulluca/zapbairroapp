// Driver do `flutter drive`: grava em screenshots/ uma imagem para cada
// binding.takeScreenshot() pedido por integration_test/capturas_test.dart.
//
// POR QUE NAO USAMOS `xcrun simctl io booted screenshot` AQUI:
//
// O `integrationDriver` NAO chama onScreenshot no instante em que o teste pede
// a captura. Ele acumula {nome, bytes} em reportData e, quando o teste inteiro
// termina, percorre a lista chamando onScreenshot uma vez por imagem. Ou seja,
// as chamadas acontecem todas no fim, com o simulador parado na ultima tela --
// entao qualquer foto tirada aqui pelo simctl sai igual para todos os nomes.
// Foi exatamente isso que embaralhou as capturas: 01-inicio saiu com a tela de
// detalhes, 03-detalhes com o resultado da busca, e assim por diante.
//
// Os bytes que chegam neste callback, ao contrario, foram capturados DENTRO do
// teste, no momento certo, e viajam junto com o nome. Sao esses que valem.
//
// Eles contem a superficie do Flutter em tela cheia, sem a barra de status do
// iOS. Isso atende a rejeicao 2.3.10: o problema era a barra de status do
// ANDROID aparecendo nas capturas -- captura sem barra de status nenhuma e
// aceita pela App Store, e e o que a maioria das capturas promocionais usa.
import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

// Largura e altura de um PNG, lidas do cabecalho IHDR (bytes 16..23).
// Serve para o log dizer o tamanho de cada captura sem depender de ferramenta
// externa; a App Store recusa imagem fora das medidas dela.
String _dimensoesPng(List<int> bytes) {
  if (bytes.length < 24) return 'tamanho desconhecido';
  int inteiro(int i) =>
      (bytes[i] << 24) | (bytes[i + 1] << 16) | (bytes[i + 2] << 8) | bytes[i + 3];
  return '${inteiro(16)}x${inteiro(20)}px';
}

// Impressao digital dos bytes (FNV-1a de 64 bits). Duas capturas com a mesma
// digital sao a mesma imagem: sinal de que o teste fotografou a tela errada
// -- foi o sintoma original deste workflow, entao aqui fica o alarme.
String _digital(List<int> bytes) {
  var h = 0xcbf29ce484222325;
  for (final b in bytes) {
    h = ((h ^ b) * 0x100000001b3).toUnsigned(64);
  }
  return h.toRadixString(16).padLeft(16, '0');
}

Future<void> main() async {
  // digital -> nome da primeira captura que a produziu.
  final vistas = <String, String>{};

  await integrationDriver(
    onScreenshot:
        (String nome, List<int> bytes, [Map<String, Object?>? args]) async {
      final pasta = Directory('screenshots');
      if (!pasta.existsSync()) pasta.createSync(recursive: true);

      final destino = '${pasta.path}/$nome.png';
      File(destino).writeAsBytesSync(bytes);

      final digital = _digital(bytes);
      final repetida = vistas[digital];
      if (repetida != null) {
        // ::warning:: vira anotacao amarela no run do GitHub Actions.
        stdout.writeln(
          '::warning::Captura "$nome" e identica a "$repetida" -- '
          'a tela nao mudou antes do print. Veja o log do teste.',
        );
      } else {
        vistas[digital] = nome;
      }

      stdout.writeln('captura salva: $destino (${_dimensoesPng(bytes)})');
      return true;
    },
  );
}
