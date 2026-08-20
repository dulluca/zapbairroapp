// Driver do `flutter drive`: garante que exista um PNG em screenshots/ para
// cada binding.takeScreenshot() pedido por integration_test/capturas_test.dart.
//
// O ponto delicado aqui e o MOMENTO da foto. O integration_test nao entrega as
// capturas uma a uma: ele guarda todas e so manda para o driver quando o teste
// inteiro termina. A versao anterior chamava `xcrun simctl io screenshot` aqui
// dentro, entao as seis fotos foram tiradas em sequencia depois do fim, com o
// app parado na ultima tela -- as seis sairam identicas.
//
// Quem fotografa na hora certa agora e o workflow: o teste imprime uma linha
// "###CAPTURA:<nome>" ao chegar em cada tela e o passo "Gerar as capturas"
// dispara o simctl ali, com a tela ainda de pe e com a barra de status do iOS.
// Este driver so cuida do que sobrar.
import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() async {
  await integrationDriver(
    onScreenshot:
        (String nome, List<int> bytes, [Map<String, Object?>? args]) async {
      final pasta = Directory('screenshots');
      if (!pasta.existsSync()) pasta.createSync(recursive: true);

      final destino = File('${pasta.path}/$nome.png');

      // Se o host ja fotografou, aquela imagem e melhor: e a tela inteira do
      // iOS, com relogio, sinal e bateria. Nao sobrescrever.
      if (destino.existsSync() && destino.lengthSync() > 0) {
        stdout.writeln('captura ja feita pelo simulador: ${destino.path}');
        return true;
      }

      // Rede de seguranca: os bytes do Flutter tem so a superficie do app,
      // sem a barra de status, mas garantem que a captura exista.
      destino.writeAsBytesSync(bytes);
      stdout.writeln(
        'captura salva pela superficie Flutter: ${destino.path} '
        '(${bytes.length} bytes)',
      );
      return true;
    },
  );
}
