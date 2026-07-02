import 'package:firedart/firedart.dart';
import 'dart:convert';
import 'dart:io';

void main() async {
  print('🚀 Abrindo arquivos de dados...');

  // 1. Abre o arquivo da chave para pegar o ID do projeto
  final chaveTexto = await File('chave-firebase.json').readAsString();
  final Map<String, dynamic> chaveJson = jsonDecode(chaveTexto);
  final String projetoId = chaveJson['project_id'];

  // 2. Inicializa o banco de dados
  Firestore.initialize(projetoId);
  print('✅ Conectado ao projeto Firebase: $projetoId');

  // 🔥 [NOVO] FAZENDO A FAXINA AUTOMÁTICA PARA EVITAR DUPLICADOS
  print(
    '🧹 Limpando dados antigos da coleção "comercios" para evitar duplicados...',
  );
  try {
    final documentosAntigos = await Firestore.instance
        .collection('comercios')
        .get();
    for (var doc in documentosAntigos) {
      await Firestore.instance
          .collection('comercios')
          .document(doc.id)
          .delete();
    }
    print('✨ Coleção limpa com sucesso!');
  } catch (e) {
    print('⚠️ Aviso ao limpar banco (pode estar vazio): $e');
  }

  // 3. Abre o arquivo com os lojistas
  final dadosTexto = await File('lojistas.json').readAsString();
  final List<dynamic> lojistas = jsonDecode(dadosTexto);

  print('📦 Encontrados ${lojistas.length} lojistas para upload.');

  // 4. Envia cada um para a coleção 'comercios'
  for (var lojista in lojistas) {
    try {
      Map<String, dynamic> dadosLojista = Map<String, dynamic>.from(lojista);
      await Firestore.instance.collection('comercios').add(dadosLojista);
      print('✅ Sucesso: ${dadosLojista['nome']} cadastrado!');
    } catch (e) {
      print('❌ Erro ao cadastrar lojista: $e');
    }
  }

  print('🎉 Todo o comércio local foi importado com sucesso!');
  exit(0);
}
