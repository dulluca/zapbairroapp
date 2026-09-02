// Leitura do arquivo de conteudo do ZapBairro (lojistas.json).
//
// O mesmo arquivo guarda tres listas editaveis a mao:
//   - "lojistas"   : os comercios do bairro (colecao 'comercios' no Firestore)
//   - "emergencia" : telefones uteis do botao EMERGENCIA
//   - "avisos"     : recados do bairro do botao AVISOS
//
// Formato antigo (uma lista solta de lojistas na raiz) continua funcionando:
// nesse caso emergencia e avisos ficam vazios.
import 'dart:convert';

class ConteudoZapBairro {
  final List<Map<String, dynamic>> lojistas;
  final List<Map<String, dynamic>> emergencia;
  final List<Map<String, dynamic>> avisos;

  const ConteudoZapBairro({
    required this.lojistas,
    required this.emergencia,
    required this.avisos,
  });
}

List<Map<String, dynamic>> _lista(Object? valor) {
  if (valor is! List) return const [];
  return valor
      .whereType<Map>()
      .map((m) => Map<String, dynamic>.from(m))
      .toList();
}

ConteudoZapBairro lerConteudoZapBairro(String textoJson) {
  final raiz = jsonDecode(textoJson);

  if (raiz is List) {
    // Formato antigo: o arquivo inteiro era a lista de lojistas.
    return ConteudoZapBairro(
      lojistas: _lista(raiz),
      emergencia: const [],
      avisos: const [],
    );
  }

  if (raiz is Map) {
    return ConteudoZapBairro(
      lojistas: _lista(raiz['lojistas']),
      emergencia: _lista(raiz['emergencia']),
      avisos: _lista(raiz['avisos']),
    );
  }

  throw const FormatException(
    'lojistas.json precisa ser um objeto com "lojistas"/"emergencia"/"avisos" '
    'ou uma lista de lojistas.',
  );
}
