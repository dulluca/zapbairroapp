// Coordenada das lojas e distância até o morador.
//
// No lojistas.json a coluna "localizacao" recebe a coordenada do jeito que o
// Google Maps copia: "-1.33186, -48.44317" (latitude, longitude).
//
// Dart puro (sem Flutter) para o importar.dart validar o arquivo.
import 'dart:math' as math;

class Coordenada {
  final double latitude;
  final double longitude;

  const Coordenada(this.latitude, this.longitude);

  @override
  bool operator ==(Object other) =>
      other is Coordenada &&
      other.latitude == latitude &&
      other.longitude == longitude;

  @override
  int get hashCode => Object.hash(latitude, longitude);

  @override
  String toString() => '$latitude, $longitude';
}

/// Centro do Conjunto Maguari (Belém/PA): onde o mapa abre quando não há a
/// posição do morador nem lojas com coordenada.
const Coordenada kCentroDoBairro = Coordenada(-1.33186, -48.44317);

final RegExp _comPonto = RegExp(
  r'^\s*\(?\s*(-?\d{1,3}(?:\.\d+)?)\s*[,;\s]\s*(-?\d{1,3}(?:\.\d+)?)\s*\)?\s*$',
);
final RegExp _comVirgula = RegExp(
  r'^\s*(-?\d{1,3}(?:,\d+)?)\s*[;\s]\s*(-?\d{1,3}(?:,\d+)?)\s*$',
);

/// Lê "lat, lng". Aceita também "lat lng", "lat;lng" e decimal com vírgula
/// separado por espaço ou ponto e vírgula ("-1,33 -48,44"). Vazio ou fora do
/// mundo devolve null.
Coordenada? lerCoordenada(Object? valor) {
  final texto = (valor ?? '').toString().trim();
  if (texto.isEmpty) return null;

  double? lat;
  double? lng;
  final ponto = _comPonto.firstMatch(texto);
  if (ponto != null) {
    lat = double.tryParse(ponto.group(1)!);
    lng = double.tryParse(ponto.group(2)!);
  } else {
    final virgula = _comVirgula.firstMatch(texto);
    if (virgula != null) {
      lat = double.tryParse(virgula.group(1)!.replaceAll(',', '.'));
      lng = double.tryParse(virgula.group(2)!.replaceAll(',', '.'));
    }
  }

  if (lat == null || lng == null) return null;
  if (lat.abs() > 90 || lng.abs() > 180) return null;
  if (lat == 0 && lng == 0) return null;
  return Coordenada(lat, lng);
}

/// Distância em linha reta (fórmula de haversine), em metros.
double distanciaMetros(Coordenada a, Coordenada b) {
  const raioDaTerra = 6371000.0;
  double rad(double graus) => graus * math.pi / 180;

  final dLat = rad(b.latitude - a.latitude);
  final dLng = rad(b.longitude - a.longitude);
  final h =
      math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(rad(a.latitude)) *
          math.cos(rad(b.latitude)) *
          math.sin(dLng / 2) *
          math.sin(dLng / 2);
  return 2 * raioDaTerra * math.asin(math.sqrt(h));
}

/// "350 m", "1,2 km", "15 km".
String formatarDistancia(double metros) {
  if (metros < 1000) {
    final arredondado = (metros / 10).round() * 10;
    return '${arredondado < 10 ? 10 : arredondado} m';
  }
  final km = metros / 1000;
  if (km < 10) return '${km.toStringAsFixed(1).replaceAll('.', ',')} km';
  return '${km.round()} km';
}
