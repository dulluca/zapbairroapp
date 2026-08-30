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

// --- Utilitario: abrir o discador do celular com um numero ja preenchido ---
// Usado nos telefones de emergencia, onde o morador precisa ligar (nao mandar
// mensagem) e muitas vezes o numero e curto (192, 193, 190...).
Future<bool> abrirDiscador(String numero) async {
  final numeroLimpo = numero.replaceAll(RegExp(r'[^0-9+]'), '');
  if (numeroLimpo.isEmpty) return false;
  final url = Uri(scheme: 'tel', path: numeroLimpo);
  try {
    return await launchUrl(url, mode: LaunchMode.externalApplication);
  } catch (e) {
    debugPrint('Não foi possível abrir o discador: $e');
    return false;
  }
}

// =====================================================================
// EMERGENCIA e AVISOS: as duas listas que o ZapBairro publica para o
// bairro. Sao editadas em lojistas.json e sobem para o Firestore pelo
// importar.dart, junto com os comercios.
// =====================================================================
class ConteudoBairroService {
  /// Telefones de emergencia, na ordem definida no JSON (campo 'ordem').
  ///
  /// Ordenamos no app para nao depender de indice do Firestore: registros
  /// sem 'ordem' vao para o fim, e ai vale a ordem alfabetica do nome.
  static Stream<List<Map<String, dynamic>>> emergencias() {
    return FirebaseFirestore.instance
        .collection('emergencias')
        .snapshots()
        .map((snapshot) {
          final lista = snapshot.docs.map((d) => d.data()).toList();
          lista.sort((a, b) {
            final ordemA = (a['ordem'] as num?)?.toInt() ?? 9999;
            final ordemB = (b['ordem'] as num?)?.toInt() ?? 9999;
            if (ordemA != ordemB) return ordemA.compareTo(ordemB);
            return (a['nome'] ?? '').toString().compareTo(
              (b['nome'] ?? '').toString(),
            );
          });
          return lista;
        });
  }

  /// Avisos do bairro, na ordem do JSON. Entre avisos de mesma 'ordem' vale
  /// a data mais nova primeiro (campo 'data', no formato AAAA-MM-DD, que
  /// ordena certo como texto). Aviso sem data fica no fim do proprio grupo.
  static Stream<List<Map<String, dynamic>>> avisos() {
    return FirebaseFirestore.instance.collection('avisos').snapshots().map((
      snapshot,
    ) {
      final lista = snapshot.docs.map((d) => d.data()).toList();
      lista.sort((a, b) {
        final ordemA = (a['ordem'] as num?)?.toInt() ?? 9999;
        final ordemB = (b['ordem'] as num?)?.toInt() ?? 9999;
        if (ordemA != ordemB) return ordemA.compareTo(ordemB);
        return (b['data'] ?? '').toString().compareTo(
          (a['data'] ?? '').toString(),
        );
      });
      return lista;
    });
  }
}

/// Quebra uma lista ja ordenada em blocos por 'secao', preservando a ordem de
/// aparicao das secoes. As telas de emergencia e avisos desenham um titulo
/// por bloco; quem nao tem secao cai num bloco de titulo vazio.
List<MapEntry<String, List<Map<String, dynamic>>>> agruparPorSecao(
  List<Map<String, dynamic>> itens,
) {
  final grupos = <String, List<Map<String, dynamic>>>{};
  for (final item in itens) {
    final secao = (item['secao'] ?? '').toString().trim();
    grupos.putIfAbsent(secao, () => []).add(item);
  }
  return grupos.entries.toList();
}

/// Converte "2026-08-29" em "29/08/2026". Se vier em outro formato, devolve
/// o texto como esta (o JSON e editado a mao, entao nao vale quebrar a tela).
String dataParaExibicao(Object? data) {
  final texto = (data ?? '').toString().trim();
  final partes = texto.split('-');
  if (partes.length == 3 && partes[0].length == 4) {
    return '${partes[2]}/${partes[1]}/${partes[0]}';
  }
  return texto;
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
// AVALIACOES: nota de 1 a 5 estrelas de uma loja, salva no Firestore.
//
// So a nota. Nao ha campo de texto livre nem qualquer identificacao de quem
// avaliou, entao a colecao nao guarda conteudo escrito por usuario nem dado
// que identifique o morador.
// =====================================================================
/// Media, quantidade e distribuicao das avaliacoes de uma loja.
class ResumoAvaliacoes {
  final double media;
  final int total;

  /// Quantas avaliacoes cada nota recebeu. Chaves de 1 a 5.
  final Map<int, int> porNota;

  const ResumoAvaliacoes(this.media, this.total, [this.porNota = const {}]);

  static const ResumoAvaliacoes vazio = ResumoAvaliacoes(0, 0);

  bool get temAvaliacao => total > 0;

  int quantidadeDaNota(int nota) => porNota[nota] ?? 0;
}

class AvaliacaoService {
  static Future<void> enviar({
    required Map<String, dynamic> loja,
    required int nota,
  }) async {
    await FirebaseFirestore.instance.collection('avaliacoes').add({
      'comercioId': (loja['id'] ?? '').toString(),
      'comercioNome': (loja['nome'] ?? '').toString(),
      'nota': nota,
      'criadoEm': FieldValue.serverTimestamp(),
    });
  }

  // Agrupamos as avaliacoes pelo nome da loja, e nao pelo id do documento,
  // porque a colecao 'comercios' tem lojas repetidas com o mesmo nome; as
  // telas ja deduplicam desse jeito (trim + minusculas).
  static String chaveLojaAvaliada(Object? nomeLoja) =>
      (nomeLoja ?? '').toString().trim().toLowerCase();

  /// Media e total de avaliacoes de cada loja, para a lista de comercios.
  static Stream<Map<String, ResumoAvaliacoes>> resumoPorLoja() {
    return FirebaseFirestore.instance.collection('avaliacoes').snapshots().map((
      snapshot,
    ) {
      final somas = <String, int>{};
      final totais = <String, int>{};
      final distribuicoes = <String, Map<int, int>>{};

      for (final doc in snapshot.docs) {
        final dados = doc.data();
        final chave = chaveLojaAvaliada(dados['comercioNome']);
        final nota = (dados['nota'] as num?)?.toInt() ?? 0;
        if (chave.isEmpty || nota < 1 || nota > 5) continue;

        somas[chave] = (somas[chave] ?? 0) + nota;
        totais[chave] = (totais[chave] ?? 0) + 1;
        final distribuicao = distribuicoes.putIfAbsent(chave, () => <int, int>{});
        distribuicao[nota] = (distribuicao[nota] ?? 0) + 1;
      }

      return {
        for (final chave in totais.keys)
          chave: ResumoAvaliacoes(
            somas[chave]! / totais[chave]!,
            totais[chave]!,
            distribuicoes[chave] ?? const <int, int>{},
          ),
      };
    });
  }

  /// Avaliacoes de uma loja, da mais recente para a mais antiga.
  ///
  /// Filtramos e ordenamos no app de proposito: um where + orderBy em campos
  /// diferentes exigiria indice composto no Firestore, e sem esse indice a
  /// consulta falha em producao.
  static Stream<List<Map<String, dynamic>>> daLoja(String nomeLoja) {
    final alvo = chaveLojaAvaliada(nomeLoja);

    return FirebaseFirestore.instance.collection('avaliacoes').snapshots().map((
      snapshot,
    ) {
      final lista = snapshot.docs
          .map((doc) => doc.data())
          .where((d) => chaveLojaAvaliada(d['comercioNome']) == alvo)
          .toList();

      lista.sort((a, b) {
        final dataA = a['criadoEm'];
        final dataB = b['criadoEm'];
        if (dataA is Timestamp && dataB is Timestamp) {
          return dataB.compareTo(dataA);
        }
        // Avaliacao recem-enviada ainda nao tem o timestamp do servidor;
        // ela fica no topo, que e onde o morador espera ver a dele.
        if (dataA == null) return -1;
        if (dataB == null) return 1;
        return 0;
      });

      return lista;
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
    final fs = FirebaseFirestore.instance;
    try {
      // Log detalhado (um documento por acesso). Sem nada do morador: o
      // registro diz o que foi aberto, nunca por quem.
      await fs.collection('acessos_especialidade').add({
        'especialidade': esp,
        'categoria': categoria,
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
  _RegraIcone([
    'farmácia',
    'farmacia',
    'remédio',
    'remedio',
  ], Icons.local_pharmacy),
  _RegraIcone([
    'médic',
    'medic',
    'clínica',
    'clinica',
    'saúde',
    'saude',
  ], Icons.local_hospital),
  _RegraIcone(['dentista', 'odonto'], Icons.medical_services),
  _RegraIcone([
    'barbe',
    'cabelo',
    'salão',
    'salao',
    'beleza',
  ], Icons.content_cut),
  _RegraIcone(['unha', 'manicure', 'estética', 'estetica'], Icons.spa),
  _RegraIcone(['academia', 'fitness', 'personal'], Icons.fitness_center),
  _RegraIcone(['pet', 'veterin', 'animal'], Icons.pets),
  _RegraIcone([
    'mercado',
    'mercearia',
    'hortifruti',
    'sacolão',
    'sacolao',
  ], Icons.local_grocery_store),
  _RegraIcone(['açougue', 'acougue', 'carne'], Icons.set_meal),
  _RegraIcone([
    'roupa',
    'moda',
    'boutique',
    'calçado',
    'calcado',
  ], Icons.checkroom),
  _RegraIcone([
    'carro',
    'auto',
    'mecânic',
    'mecanic',
    'oficina',
    'moto',
  ], Icons.directions_car),
  _RegraIcone([
    'construç',
    'construc',
    'material',
    'ferragem',
  ], Icons.home_repair_service),
  _RegraIcone(['escola', 'curso', 'aula', 'educaç', 'educac'], Icons.school),
  _RegraIcone([
    'imóvel',
    'imovel',
    'imobiliár',
    'imobiliar',
    'aluguel',
  ], Icons.apartment),
  _RegraIcone(['festa', 'evento', 'buffet'], Icons.celebration),
  _RegraIcone(['limpeza', 'faxina', 'diarista'], Icons.cleaning_services),
  _RegraIcone([
    'eletric',
    'encanad',
    'reforma',
    'pintura',
    'serviço',
    'servico',
  ], Icons.build),
  _RegraIcone(['loja', 'comércio', 'comercio', 'presente'], Icons.shopping_bag),
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
