// Contador de visitas das lojas na hora de reimportar o lojistas.json.
//
// O app soma +1 no campo 'visitas' do comércio cada vez que alguém abre a
// loja. O importar.dart apaga e regrava a coleção 'comercios', então sem isto
// todas as lojas voltavam a zero visitas a cada importação. Aqui as visitas
// antigas são devolvidas às lojas novas:
//   1. mesma loja = mesmo nome + categoria + subcategoria;
//   2. o que sobrar (loja que mudou de categoria) vai para a primeira loja de
//      mesmo nome;
//   3. loja que saiu do JSON perde o contador (fica só no backup).
//
// Dart puro (sem Flutter) para o importar.dart usar.

class VisitasDevolvidas {
  /// Cópias das lojas do JSON, com 'visitas' preenchido quando havia contador.
  final List<Map<String, dynamic>> lojas;
  final int totalAntes;
  final int totalDevolvido;

  /// Nome da loja -> visitas que não acharam loja no JSON novo.
  final Map<String, int> perdidas;

  const VisitasDevolvidas(
    this.lojas,
    this.totalAntes,
    this.totalDevolvido,
    this.perdidas,
  );
}

String _texto(Object? valor) => (valor ?? '').toString().trim().toLowerCase();

int _inteiro(Object? valor) =>
    valor is num ? valor.toInt() : int.tryParse('${valor ?? ''}') ?? 0;

String _chave(Map<String, dynamic> loja) =>
    '${_texto(loja['nome'])}|${_texto(loja['categoria'])}|'
    '${_texto(loja['subcategoria'])}';

VisitasDevolvidas devolverVisitas(
  Iterable<Map<String, dynamic>> antigos,
  List<Map<String, dynamic>> novos,
) {
  final porChave = <String, int>{};
  final nomeDaChave = <String, String>{};
  var totalAntes = 0;
  for (final antigo in antigos) {
    final visitas = _inteiro(antigo['visitas']);
    if (visitas <= 0) continue;
    totalAntes += visitas;
    final chave = _chave(antigo);
    porChave.update(chave, (v) => v + visitas, ifAbsent: () => visitas);
    nomeDaChave[chave] = _texto(antigo['nome']);
  }

  // O JSON nunca manda no contador: ele só vem do Firestore.
  final lojas = [
    for (final novo in novos) Map<String, dynamic>.from(novo)..remove('visitas'),
  ];

  // 1. Mesma loja: a primeira ocorrência leva o contador.
  for (final loja in lojas) {
    final visitas = porChave.remove(_chave(loja));
    if (visitas != null) loja['visitas'] = visitas;
  }

  // 2. Sobrou: vai para a primeira loja de mesmo nome.
  final sobraPorNome = <String, int>{};
  porChave.forEach((chave, visitas) {
    sobraPorNome.update(
      nomeDaChave[chave]!,
      (v) => v + visitas,
      ifAbsent: () => visitas,
    );
  });
  final perdidas = <String, int>{};
  sobraPorNome.forEach((nome, visitas) {
    final destino = lojas.where((l) => _texto(l['nome']) == nome).firstOrNull;
    if (destino == null) {
      perdidas[nome] = visitas;
    } else {
      destino['visitas'] = _inteiro(destino['visitas']) + visitas;
    }
  });

  final totalDevolvido = lojas.fold<int>(
    0,
    (soma, l) => soma + _inteiro(l['visitas']),
  );
  return VisitasDevolvidas(lojas, totalAntes, totalDevolvido, perdidas);
}
