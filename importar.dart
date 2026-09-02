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
import 'package:firedart/firedart.dart';
import 'package:zapbairro/conteudo_json.dart';
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

void main(List<String> args) async {
  // Sem argumento = tudo. Com argumento = so as listas pedidas.
  final pedidas = args.map((a) => a.trim().toLowerCase()).toSet();
  final desconhecidas = pedidas.difference(
    _blocos.map((b) => b.chave).toSet(),
  );
  if (desconhecidas.isNotEmpty) {
    print('❌ Lista(s) que não existem: ${desconhecidas.join(", ")}');
    print('   Use: dart run importar.dart [lojistas] [emergencia] [avisos]');
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
    await _enviar(bloco, bloco.itens(conteudo));
  }

  print('🎉 Importação concluída!');
  exit(0);
}
