// Servicos de apoio do ZapBairro: persistencia local (SharedPreferences),
// registro no Firestore e utilitarios compartilhados entre as telas.
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

// WhatsApp oficial do ZapBairro (com DDI 55). Usado no botao CONTATO.
const String kZapBairroWhats = "5591985554004";

// --- Utilitario: abrir uma conversa no WhatsApp por numero completo (com DDI) ---
Future<void> abrirWhatsAppNumeroCompleto(
  String numeroComDdi, {
  String mensagem = "Olá! Vim pelo aplicativo ZapBairro.",
}) async {
  final numeroLimpo = numeroComDdi.replaceAll(RegExp(r'[^0-9]'), '');
  final url = Uri.https("wa.me", "/$numeroLimpo", {"text": mensagem});
  if (await canLaunchUrl(url)) {
    await launchUrl(url, mode: LaunchMode.externalApplication);
  } else {
    debugPrint("Não foi possível abrir o WhatsApp");
  }
}

// Gera uma chave estavel para uma loja (usa o id do documento quando existir,
// senao cai para o nome normalizado). Serve para favoritos e recentes.
String chaveLoja(Map<String, dynamic> loja) {
  final id = (loja['id'] ?? '').toString().trim();
  if (id.isNotEmpty) return 'id:$id';
  final nome = (loja['nome'] ?? '').toString().trim().toLowerCase();
  return 'nome:$nome';
}

// Reduz uma loja aos campos que as telas precisam para exibir/reabrir detalhes.
Map<String, dynamic> resumoLoja(Map<String, dynamic> dados, {String? id}) {
  return {
    'id': id ?? dados['id'] ?? '',
    'nome': dados['nome'] ?? 'Sem nome',
    'descricao': dados['descricao'] ?? '',
    'endereco': dados['endereco'] ?? '',
    'horario': dados['horario'] ?? '',
    'entrega': dados['entrega'] ?? '',
    'telefone': dados['telefone'] ?? '',
    'telefone2': dados['telefone2'] ?? '',
    'categoria': dados['categoria'] ?? '',
    'subcategoria': dados['subcategoria'] ?? '',
  };
}

// =====================================================================
// MORADOR: cadastro capturado no primeiro acesso (nome + WhatsApp).
// Fica salvo localmente e tambem no Firestore (colecao 'moradores').
//
// ATENCAO: o dialogo de cadastro esta DESATIVADO (ver mostrarCadastroMorador
// em main.dart), portanto nada e coletado e dados() devolve strings vazias.
// O servico continua aqui para quando/se voltarmos a pedir nome + WhatsApp.
// =====================================================================
class MoradorService {
  static const _kNome = 'morador_nome';
  static const _kTelefone = 'morador_telefone';

  static Future<bool> estaCadastrado() async {
    final prefs = await SharedPreferences.getInstance();
    final tel = prefs.getString(_kTelefone) ?? '';
    return tel.trim().isNotEmpty;
  }

  static Future<Map<String, String>> dados() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'nome': prefs.getString(_kNome) ?? '',
      'telefone': prefs.getString(_kTelefone) ?? '',
    };
  }

  // Telefone so com digitos, usado como id do morador no Firestore.
  static String telefoneDigitos(String telefone) =>
      telefone.replaceAll(RegExp(r'[^0-9]'), '');

  static Future<void> salvar(String nome, String telefone) async {
    final prefs = await SharedPreferences.getInstance();
    final tel = telefoneDigitos(telefone);
    await prefs.setString(_kNome, nome.trim());
    await prefs.setString(_kTelefone, tel);

    try {
      await FirebaseFirestore.instance.collection('moradores').doc(tel).set({
        'nome': nome.trim(),
        'telefone': tel,
        'criadoEm': FieldValue.serverTimestamp(),
        'plataforma': 'android',
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Não foi possível salvar o morador no Firestore: $e');
    }
  }
}

// =====================================================================
// RECENTES: ultimas lojas que o morador abriu. Alimenta a tela de
// avaliacao (ele escolhe qual das lojas recentes quer avaliar).
// =====================================================================
class RecentesService {
  static const _kRecentes = 'lojas_recentes';
  static const _limite = 12;

  static Future<List<Map<String, dynamic>>> listar() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_kRecentes) ?? [];
    return raw
        .map((s) => jsonDecode(s) as Map<String, dynamic>)
        .toList(growable: false);
  }

  static Future<void> registrar(Map<String, dynamic> loja) async {
    final prefs = await SharedPreferences.getInstance();
    final resumo = resumoLoja(loja);
    final chave = chaveLoja(resumo);

    final atuais = prefs.getStringList(_kRecentes) ?? [];
    // Remove ocorrencia anterior da mesma loja e coloca no topo.
    atuais.removeWhere((s) {
      final m = jsonDecode(s) as Map<String, dynamic>;
      return chaveLoja(m) == chave;
    });
    atuais.insert(0, jsonEncode(resumo));
    if (atuais.length > _limite) {
      atuais.removeRange(_limite, atuais.length);
    }
    await prefs.setStringList(_kRecentes, atuais);
  }
}

// =====================================================================
// FAVORITOS: lojas que o morador guardou (armazenamento local).
// =====================================================================
class FavoritosService {
  static const _kFavoritos = 'favoritos';

  static Future<List<Map<String, dynamic>>> listar() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_kFavoritos) ?? [];
    return raw
        .map((s) => jsonDecode(s) as Map<String, dynamic>)
        .toList(growable: false);
  }

  static Future<bool> ehFavorito(Map<String, dynamic> loja) async {
    final chave = chaveLoja(resumoLoja(loja));
    final lista = await listar();
    return lista.any((m) => chaveLoja(m) == chave);
  }

  // Alterna favorito e devolve o novo estado (true = agora e favorito).
  static Future<bool> alternar(Map<String, dynamic> loja) async {
    final prefs = await SharedPreferences.getInstance();
    final resumo = resumoLoja(loja);
    final chave = chaveLoja(resumo);
    final atuais = prefs.getStringList(_kFavoritos) ?? [];

    final tinha = atuais.any((s) {
      final m = jsonDecode(s) as Map<String, dynamic>;
      return chaveLoja(m) == chave;
    });

    if (tinha) {
      atuais.removeWhere((s) {
        final m = jsonDecode(s) as Map<String, dynamic>;
        return chaveLoja(m) == chave;
      });
      await prefs.setStringList(_kFavoritos, atuais);
      return false;
    } else {
      atuais.insert(0, jsonEncode(resumo));
      await prefs.setStringList(_kFavoritos, atuais);
      return true;
    }
  }

  static Future<void> remover(Map<String, dynamic> loja) async {
    final prefs = await SharedPreferences.getInstance();
    final chave = chaveLoja(resumoLoja(loja));
    final atuais = prefs.getStringList(_kFavoritos) ?? [];
    atuais.removeWhere((s) {
      final m = jsonDecode(s) as Map<String, dynamic>;
      return chaveLoja(m) == chave;
    });
    await prefs.setStringList(_kFavoritos, atuais);
  }
}

// =====================================================================
// AVALIACOES: nota (1..5) + comentario de uma loja, salvos no Firestore.
// =====================================================================
class AvaliacaoService {
  static Future<void> enviar({
    required Map<String, dynamic> loja,
    required int nota,
    String comentario = '',
  }) async {
    final morador = await MoradorService.dados();
    await FirebaseFirestore.instance.collection('avaliacoes').add({
      'comercioId': (loja['id'] ?? '').toString(),
      'comercioNome': (loja['nome'] ?? '').toString(),
      'nota': nota,
      'comentario': comentario.trim(),
      'moradorTelefone': morador['telefone'] ?? '',
      'moradorNome': morador['nome'] ?? '',
      'criadoEm': FieldValue.serverTimestamp(),
    });
  }
}

// =====================================================================
// HISTORICO POR ESPECIALIDADE: registra cada acesso a uma especialidade
// (subcategoria) num log e mantem um contador agregado para o painel.
// =====================================================================
class EspecialidadeService {
  static Future<void> registrarAcesso({
    required String especialidade,
    required String categoria,
  }) async {
    final esp = especialidade.trim();
    if (esp.isEmpty) return;
    final morador = await MoradorService.dados();
    final fs = FirebaseFirestore.instance;
    try {
      // Log detalhado (um documento por acesso).
      await fs.collection('acessos_especialidade').add({
        'especialidade': esp,
        'categoria': categoria,
        'moradorTelefone': morador['telefone'] ?? '',
        'moradorNome': morador['nome'] ?? '',
        'criadoEm': FieldValue.serverTimestamp(),
      });
      // Contador agregado (facilita o ranking no painel).
      final id = esp.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
      await fs.collection('especialidades_contagem').doc(id).set({
        'especialidade': esp,
        'categoria': categoria,
        'acessos': FieldValue.increment(1),
        'ultimoAcesso': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Não foi possível registrar acesso à especialidade: $e');
    }
  }
}

// =====================================================================
// ICONES DAS ESPECIALIDADES: mapeia o nome da subcategoria para um icone
// e cor, deixando a tela de especialidades com a cara da tela inicial.
// =====================================================================
class _RegraIcone {
  final List<String> palavras;
  final IconData icone;
  const _RegraIcone(this.palavras, this.icone);
}

const List<_RegraIcone> _regrasIcone = [
  _RegraIcone(['pizza', 'pizzaria'], Icons.local_pizza),
  _RegraIcone(['lanche', 'hamburg', 'burger', 'x-'], Icons.lunch_dining),
  _RegraIcone(['açai', 'acai', 'sorvete', 'gelato'], Icons.icecream),
  _RegraIcone(['padaria', 'pão', 'pao', 'confeitaria'], Icons.bakery_dining),
  _RegraIcone(['bar', 'cerveja', 'boteco', 'drink'], Icons.local_bar),
  _RegraIcone(['café', 'cafe', 'cafeteria'], Icons.local_cafe),
  _RegraIcone(['restaurante', 'marmita', 'almoço', 'almoco'], Icons.restaurant),
  _RegraIcone(['doce', 'bolo', 'salgado'], Icons.cake),
  _RegraIcone(['farmácia', 'farmacia', 'remédio', 'remedio'],
      Icons.local_pharmacy),
  _RegraIcone(['médic', 'medic', 'clínica', 'clinica', 'saúde', 'saude'],
      Icons.local_hospital),
  _RegraIcone(['dentista', 'odonto'], Icons.medical_services),
  _RegraIcone(['barbe', 'cabelo', 'salão', 'salao', 'beleza'],
      Icons.content_cut),
  _RegraIcone(['unha', 'manicure', 'estética', 'estetica'], Icons.spa),
  _RegraIcone(['academia', 'fitness', 'personal'], Icons.fitness_center),
  _RegraIcone(['pet', 'veterin', 'animal'], Icons.pets),
  _RegraIcone(['mercado', 'mercearia', 'hortifruti', 'sacolão', 'sacolao'],
      Icons.local_grocery_store),
  _RegraIcone(['açougue', 'acougue', 'carne'], Icons.set_meal),
  _RegraIcone(['roupa', 'moda', 'boutique', 'calçado', 'calcado'],
      Icons.checkroom),
  _RegraIcone(['carro', 'auto', 'mecânic', 'mecanic', 'oficina', 'moto'],
      Icons.directions_car),
  _RegraIcone(['construç', 'construc', 'material', 'ferragem'],
      Icons.home_repair_service),
  _RegraIcone(['escola', 'curso', 'aula', 'educaç', 'educac'], Icons.school),
  _RegraIcone(['imóvel', 'imovel', 'imobiliár', 'imobiliar', 'aluguel'],
      Icons.apartment),
  _RegraIcone(['festa', 'evento', 'buffet'], Icons.celebration),
  _RegraIcone(['limpeza', 'faxina', 'diarista'], Icons.cleaning_services),
  _RegraIcone(['eletric', 'encanad', 'reforma', 'pintura', 'serviço',
      'servico'], Icons.build),
  _RegraIcone(['loja', 'comércio', 'comercio', 'presente'],
      Icons.shopping_bag),
];

const List<Color> _paletaIcones = [
  Colors.orange,
  Colors.blue,
  Colors.pink,
  Colors.purple,
  Colors.red,
  Colors.teal,
  Colors.brown,
  Colors.indigo,
  Colors.green,
  Colors.deepOrange,
];

class IconeEspecialidade {
  final IconData icone;
  final Color cor;
  const IconeEspecialidade(this.icone, this.cor);
}

IconeEspecialidade iconeParaEspecialidade(String nome, int index) {
  final n = nome.toLowerCase();
  IconData icone = Icons.storefront;
  for (final regra in _regrasIcone) {
    if (regra.palavras.any((p) => n.contains(p))) {
      icone = regra.icone;
      break;
    }
  }
  final cor = _paletaIcones[index % _paletaIcones.length];
  return IconeEspecialidade(icone, cor);
}
