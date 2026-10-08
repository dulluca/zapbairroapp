// Sobe para o Firestore o que esta em lojistas.json:
//   "lojistas"   -> colecao 'comercios'
//   "emergencia" -> colecao 'emergencias'
//   "avisos"     -> colecao 'avisos'
//
// Sem argumentos importa as tres listas:
//   dart run importar.dart
//
// Com argumentos importa so as listas pedidas, sem encostar nas outras:
//   dart run importar.dart emergencia avisos
//
// Cada lista importada e apagada e regravada, entao o arquivo e sempre a
// verdade: o que voce tirar dele some do app. As listas que voce NAO pedir
// ficam intactas no Firestore.
//
// Comercios: antes de apagar, o contador de visitas de cada loja e lido e
// devolvido a ela depois (lib/visitas_importacao.dart), e a colecao inteira
// vai para backups/comercios-<data>.json.
//
// Para ver o que vai acontecer sem gravar nada:
//   dart run importar.dart lojistas --simular
import 'package:firedart/firedart.dart';
import 'package:zapbairro/conteudo_json.dart';
import 'package:zapbairro/visitas_importacao.dart';
import 'dart:convert';
import 'dart:io';

/// Uma lista do JSON e a colecao do Firestore onde ela mora.
class _Bloco {
  final String chave;
  final String colecao;
  final String rotulo;
  final List<Map<String, dynamic>> Function(ConteudoZapBairro) itens;

  const _Bloco(this.chave, this.colecao, this.rotulo, this.itens);
}

const List<_Bloco> _blocos = [
  _Bloco('lojistas', 'comercios', 'nome', _pegarLojistas),
  _Bloco('emergencia', 'emergencias', 'nome', _pegarEmergencia),
  _Bloco('avisos', 'avisos', 'titulo', _pegarAvisos),
];

List<Map<String, dynamic>> _pegarLojistas(ConteudoZapBairro c) => c.lojistas;
List<Map<String, dynamic>> _pegarEmergencia(ConteudoZapBairro c) => c.emergencia;
List<Map<String, dynamic>> _pegarAvisos(ConteudoZapBairro c) => c.avisos;

Future<void> _limpar(String colecao) async {
  print('🧹 Limpando a coleção "$colecao"...');
  try {
    final antigos = await Firestore.instance.collection(colecao).get();
    for (var doc in antigos) {
      await Firestore.instance.collection(colecao).document(doc.id).delete();
    }
    print('✨ Coleção "$colecao" limpa!');
  } catch (e) {
    print('⚠️ Aviso ao limpar "$colecao" (pode estar vazia): $e');
  }
}

Future<void> _enviar(_Bloco bloco, List<Map<String, dynamic>> itens) async {
  await _limpar(bloco.colecao);
  print('📦 Enviando ${itens.length} registro(s) para "${bloco.colecao}".');
  for (var item in itens) {
    try {
      await Firestore.instance.collection(bloco.colecao).add(item);
      print('✅ Sucesso: ${item[bloco.rotulo]}');
    } catch (e) {
      print('❌ Erro ao enviar ${item[bloco.rotulo]}: $e');
    }
  }
}

// Guarda a colecao como esta hoje, antes de qualquer gravacao.
Future<String> _salvarBackup(String colecao, List<Document> docs) async {
  final carimbo = DateTime.now()
      .toIso8601String()
      .split('.')
      .first
      .replaceAll(':', '-');
  await Directory('backups').create(recursive: true);
  final arquivo = File('backups/$colecao-$carimbo.json');
  final dados = [
    for (final doc in docs) {'id': doc.id, ...doc.map},
  ];
  await arquivo.writeAsString(
    JsonEncoder.withIndent('  ', (valor) => valor.toString()).convert(dados),
  );
  return arquivo.path;
}

Future<void> _importarLojistas(
  _Bloco bloco,
  List<Map<String, dynamic>> itens, {
  required bool simular,
}) async {
  // Sem try: se a leitura falhar, a importacao para aqui, antes de apagar.
  final antigos = await Firestore.instance.collection(bloco.colecao).get();
  final backup = await _salvarBackup(bloco.colecao, antigos);
  print('💾 Backup de ${antigos.length} comércio(s) em $backup');

  final resultado = devolverVisitas(antigos.map((d) => d.map), itens);
  print(
    '👣 Visitas: ${resultado.totalAntes} no Firestore, '
    '${resultado.totalDevolvido} devolvidas às lojas.',
  );
  resultado.perdidas.forEach((nome, visitas) {
    print(
      '⚠️ $visitas visita(s) de "$nome" ficam só no backup: '
      'a loja não está mais no lojistas.json.',
    );
  });

  if (simular) {
    print('🔎 Simulação: nada foi gravado em "${bloco.colecao}".');
    return;
  }
  await _enviar(bloco, resultado.lojas);
}

void main(List<String> argumentos) async {
  final opcoes = argumentos.where((a) => a.startsWith('--')).toSet();
  final args = argumentos.where((a) => !a.startsWith('--')).toList();
  final simular = opcoes.remove('--simular');
  if (opcoes.isNotEmpty) {
    print('❌ Opção desconhecida: ${opcoes.join(", ")} (só existe --simular)');
    exit(1);
  }

  // Sem argumento = tudo. Com argumento = so as listas pedidas.
  final pedidas = args.map((a) => a.trim().toLowerCase()).toSet();
  final desconhecidas = pedidas.difference(
    _blocos.map((b) => b.chave).toSet(),
  );
  if (desconhecidas.isNotEmpty) {
    print('❌ Lista(s) que não existem: ${desconhecidas.join(", ")}');
    print(
      '   Use: dart run importar.dart [lojistas] [emergencia] [avisos] '
      '[--simular]',
    );
    exit(1);
  }
  final aImportar = pedidas.isEmpty
      ? _blocos
      : _blocos.where((b) => pedidas.contains(b.chave)).toList();

  print('🚀 Abrindo arquivos de dados...');
  print('📋 Vou importar: ${aImportar.map((b) => b.chave).join(", ")}');

  // 1. Abre o arquivo da chave para pegar o ID do projeto
  final chaveTexto = await File('chave-firebase.json').readAsString();
  final Map<String, dynamic> chaveJson = jsonDecode(chaveTexto);
  final String projetoId = chaveJson['project_id'];

  // 2. Inicializa o banco de dados
  Firestore.initialize(projetoId);
  print('✅ Conectado ao projeto Firebase: $projetoId');

  // 3. Abre o arquivo de conteudo (lojistas + emergencia + avisos)
  final conteudo = lerConteudoZapBairro(
    await File('lojistas.json').readAsString(),
  );

  // 4. Envia so os blocos pedidos
  for (final bloco in aImportar) {
    // Lista vazia nunca apaga a colecao: o lojistas.json no formato antigo
    // (lista solta de lojistas) nao tem emergencia nem avisos, e importar
    // sem argumento apagava os dois do app.
    if (bloco.itens(conteudo).isEmpty) {
      print(
        '⏭️ "${bloco.chave}" está vazia no lojistas.json: '
        '"${bloco.colecao}" fica como está no Firestore.',
      );
      continue;
    }
    if (bloco.chave == 'lojistas') {
      await _importarLojistas(bloco, bloco.itens(conteudo), simular: simular);
    } else if (simular) {
      print(
        '🔎 Simulação: ${bloco.itens(conteudo).length} registro(s) iriam '
        'para "${bloco.colecao}".',
      );
    } else {
      await _enviar(bloco, bloco.itens(conteudo));
    }
  }

  print(simular ? '🔎 Simulação concluída.' : '🎉 Importação concluída!');
  exit(0);
}
