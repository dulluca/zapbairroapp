// Posição do morador (para o "perto de mim" e o mapa) e o "como chegar".
//
// A localização só é usada no aparelho, para calcular a distância até as
// lojas: não é salva nem enviada para lugar nenhum.
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'coordenadas.dart';

enum EstadoLocalizacao { ok, semPermissao, negadaParaSempre, gpsDesligado, erro }

class ResultadoLocalizacao {
  final EstadoLocalizacao estado;
  final Coordenada? posicao;

  const ResultadoLocalizacao(this.estado, [this.posicao]);

  bool get ok => estado == EstadoLocalizacao.ok && posicao != null;
}

class LocalizacaoService {
  static const _kJaPediu = 'localizacao_ja_pediu';
  static Coordenada? _ultima;

  /// Última posição conhecida nesta sessão do app (null se ainda não pegou).
  static Coordenada? get ultima => _ultima;

  /// Pega a posição atual. Com [pedirPermissao] mostra o pedido do sistema
  /// quando o morador ainda não respondeu; sem ele, só usa a permissão que já
  /// existe (nunca abre pedido sozinho).
  static Future<ResultadoLocalizacao> posicaoAtual({
    bool pedirPermissao = false,
  }) async {
    try {
      var permissao = await Geolocator.checkPermission();
      if (permissao == LocationPermission.denied && pedirPermissao) {
        permissao = await Geolocator.requestPermission();
        await _marcarQueJaPediu();
      }
      if (permissao == LocationPermission.deniedForever) {
        return const ResultadoLocalizacao(EstadoLocalizacao.negadaParaSempre);
      }
      if (permissao != LocationPermission.whileInUse &&
          permissao != LocationPermission.always) {
        return const ResultadoLocalizacao(EstadoLocalizacao.semPermissao);
      }
      if (!await Geolocator.isLocationServiceEnabled()) {
        return const ResultadoLocalizacao(EstadoLocalizacao.gpsDesligado);
      }

      Position? pos;
      try {
        pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 12),
          ),
        );
      } catch (e) {
        debugPrint('GPS sem resposta, usando a última posição: $e');
        pos = await Geolocator.getLastKnownPosition();
      }
      if (pos == null) return const ResultadoLocalizacao(EstadoLocalizacao.erro);

      _ultima = Coordenada(pos.latitude, pos.longitude);
      return ResultadoLocalizacao(EstadoLocalizacao.ok, _ultima);
    } catch (e) {
      debugPrint('Não foi possível pegar a localização: $e');
      return const ResultadoLocalizacao(EstadoLocalizacao.erro);
    }
  }

  /// O app só abre o pedido de localização sozinho uma vez (na primeira lista
  /// de categoria). Depois disso, só quando o morador toca em "Perto de mim".
  static Future<bool> jaPediu() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_kJaPediu) ?? false;
    } catch (_) {
      return true;
    }
  }

  static Future<void> _marcarQueJaPediu() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kJaPediu, true);
    } catch (_) {}
  }

  static Future<void> abrirAjustes(EstadoLocalizacao estado) async {
    if (estado == EstadoLocalizacao.gpsDesligado) {
      await Geolocator.openLocationSettings();
    } else {
      await Geolocator.openAppSettings();
    }
  }

  /// Frase curta para explicar ao morador por que a distância não apareceu.
  static String explicar(EstadoLocalizacao estado) {
    switch (estado) {
      case EstadoLocalizacao.gpsDesligado:
        return 'A localização do celular está desligada.';
      case EstadoLocalizacao.negadaParaSempre:
        return 'O ZapBairro não tem permissão de localização. '
            'Libere nos ajustes para ver o que está perto.';
      case EstadoLocalizacao.semPermissao:
        return 'Sem permissão de localização, a lista fica na ordem normal.';
      case EstadoLocalizacao.erro:
      case EstadoLocalizacao.ok:
        return 'Não foi possível encontrar sua localização agora.';
    }
  }
}

/// Abre o app de mapas do aparelho com a rota até a loja.
Future<void> abrirComoChegar(Coordenada destino) async {
  final destinoTexto = '${destino.latitude},${destino.longitude}';
  final Uri url = defaultTargetPlatform == TargetPlatform.iOS
      ? Uri.https('maps.apple.com', '/', {'daddr': destinoTexto})
      : Uri.https('www.google.com', '/maps/dir/', {
          'api': '1',
          'destination': destinoTexto,
        });
  try {
    await launchUrl(url, mode: LaunchMode.externalApplication);
  } catch (e) {
    debugPrint('Não foi possível abrir o mapa: $e');
  }
}
