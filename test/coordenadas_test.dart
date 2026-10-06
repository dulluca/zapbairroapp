import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:zapbairro/conteudo_json.dart';
import 'package:zapbairro/coordenadas.dart';
import 'package:zapbairro/horario.dart';

void main() {
  group('lerCoordenada', () {
    test('do jeito que o Google Maps copia', () {
      expect(
        lerCoordenada('-1.33186, -48.44317'),
        const Coordenada(-1.33186, -48.44317),
      );
    });

    test('outros separadores', () {
      expect(lerCoordenada('-1.33186 -48.44317'), isNotNull);
      expect(lerCoordenada('-1.33186;-48.44317'), isNotNull);
      expect(lerCoordenada('(-1.33186, -48.44317)'), isNotNull);
      expect(
        lerCoordenada('-1,33186 -48,44317'),
        const Coordenada(-1.33186, -48.44317),
      );
    });

    test('vazio ou inválido devolve null', () {
      expect(lerCoordenada(''), isNull);
      expect(lerCoordenada(null), isNull);
      expect(lerCoordenada('Conj. Maguari'), isNull);
      expect(lerCoordenada('0, 0'), isNull);
      expect(lerCoordenada('95.0, -48.0'), isNull);
    });
  });

  test('distância entre dois pontos do bairro', () {
    // ~1,1 km para o norte (0,01 grau de latitude).
    final d = distanciaMetros(
      kCentroDoBairro,
      Coordenada(kCentroDoBairro.latitude + 0.01, kCentroDoBairro.longitude),
    );
    expect(d, closeTo(1112, 5));
  });

  test('formatarDistancia', () {
    expect(formatarDistancia(3), '10 m');
    expect(formatarDistancia(347), '350 m');
    expect(formatarDistancia(1234), '1,2 km');
    expect(formatarDistancia(15400), '15 km');
  });

  // Rede de segurança do arquivo que o José edita: toda loja com horário ou
  // localização preenchidos precisa estar num formato que o app entende.
  test('lojistas.json: horários e localizações válidos', () {
    final conteudo = lerConteudoZapBairro(
      File('lojistas.json').readAsStringSync(),
    );
    final erros = <String>[];
    for (final loja in conteudo.lojistas) {
      for (final chave in kChavesDias) {
        if (lerDia(loja[chave]) == null) {
          erros.add('${loja['nome']}: $chave = ${jsonEncode(loja[chave])}');
        }
      }
      final local = (loja['localizacao'] ?? '').toString().trim();
      if (local.isNotEmpty && lerCoordenada(local) == null) {
        erros.add('${loja['nome']}: localizacao = "$local"');
      }
    }
    expect(erros, isEmpty, reason: erros.join('\n'));
  });
}
