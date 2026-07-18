import 'package:flutter/material.dart';
// import 'splash_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:url_launcher/url_launcher.dart';

// Senha de acesso ao painel administrativo (área oculta).
// >>> TROQUE por uma senha sua. <<<
// Observação: por ficar dentro do app, é uma proteção simples (não use dados
// sensíveis aqui). Serve para esconder o painel de visitas de usuários comuns.
const String kAdminSenha = "zapadmin2024";

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // if (Firebase.apps.isEmpty) {
  //   await Firebase.initializeApp(
  //     options: const FirebaseOptions(
  //       apiKey: "AIzaSyCDmvUzz9-_N_1c3iwdOkpKBnyAy-WxcGo",
  //       authDomain: "zapbairro-bc003.firebaseapp.com",
  //       projectId: "zapbairro-bc003",
  //       storageBucket: "zapbairro-bc003.firebasestorage.app",
  //       messagingSenderId: "959449010935",
  //       appId: "1:959449010935:web:a00ab6214320fb94f279f2",
  //     ),
  //   );
  // }

  try {
    await Firebase.initializeApp();
  } on FirebaseException catch (e) {
    if (e.code != 'duplicate-app') rethrow;
  }
  runApp(const ZapBairroApp());
}

class ZapBairroApp extends StatelessWidget {
  const ZapBairroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ZapBairro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: Colors.grey[50],
      ),
      home: const TelaCategorias(),
    );
  }
}

// --- TELA 1: CATEGORIAS (COM BARRA DE BUSCA) ---
class TelaCategorias extends StatelessWidget {
  const TelaCategorias({super.key});

  // Gesto oculto: toque longo no título abre o portão do painel admin.
  void _abrirPortaoAdmin(BuildContext context) {
    final senhaController = TextEditingController();

    void validar(BuildContext dialogContext) {
      if (senhaController.text == kAdminSenha) {
        Navigator.pop(dialogContext); // fecha o diálogo
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TelaAdmin()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Senha incorreta'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Área Restrita'),
        content: TextField(
          controller: senhaController,
          obscureText: true,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Senha de administrador',
            prefixIcon: Icon(Icons.lock),
          ),
          onSubmitted: (_) => validar(dialogContext),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => validar(dialogContext),
            child: const Text('Entrar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> categories = [
      {'nome': 'Alimentação', 'icone': Icons.fastfood, 'cor': Colors.orange},
      {'nome': 'Serviços', 'icone': Icons.build, 'cor': Colors.blue},
      {
        'nome': 'Beleza & Estética',
        'icone': Icons.content_cut,
        'cor': Colors.pink,
      },
      {'nome': 'Comércio', 'icone': Icons.shopping_bag, 'cor': Colors.purple},
      {
        'nome': 'Saúde & Bem-estar',
        'icone': Icons.local_hospital,
        'cor': Colors.red,
      },
      {'nome': 'Educação', 'icone': Icons.school, 'cor': Colors.teal},
      {'nome': 'Pet Shop', 'icone': Icons.pets, 'cor': Colors.brown},
      {
        'nome': 'Automotivo',
        'icone': Icons.directions_car,
        'cor': Colors.amber,
      },
      {
        'nome': 'Moda & Acessórios',
        'icone': Icons.checkroom,
        'cor': Colors.deepOrange,
      },
      {'nome': 'Construção', 'icone': Icons.home, 'cor': Colors.blueGrey},
      {
        'nome': 'Lazer & Eventos',
        'icone': Icons.celebration,
        'cor': Colors.indigo,
      },
      {'nome': 'Imobiliárias', 'icone': Icons.apartment, 'cor': Colors.green},
    ];

    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onLongPress: () => _abrirPortaoAdmin(context),
          child: const Text(
            'ZapBairro',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
        backgroundColor: Colors.green[700],
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              textInputAction: TextInputAction.search,
              onSubmitted: (textoDigitado) {
                if (textoDigitado.trim().isNotEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TelaComercios(
                        categoriaNome: '',
                        termoBusca: textoDigitado.trim(),
                      ),
                    ),
                  );
                }
              },
              decoration: InputDecoration(
                hintText: 'O que você procura no bairro hoje?',
                prefixIcon: const Icon(Icons.search, color: Colors.green),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                  borderSide: const BorderSide(color: Colors.green, width: 2),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Explore por Categorias',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.3,
                ),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final catNome = categories[index]['nome'];
                  return Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: InkWell(
                      onTap: () async {
                        var snapshot = await FirebaseFirestore.instance
                            .collection('comercios')
                            .where('categoria', isEqualTo: catNome)
                            .get();

                        List<String> subcats = snapshot.docs
                            .map(
                              (doc) => (doc.data()['subcategoria'] ?? '')
                                  .toString()
                                  .trim(),
                            )
                            .where((s) => s.isNotEmpty)
                            .toSet()
                            .toList();

                        if (context.mounted) {
                          if (subcats.isEmpty) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    TelaComercios(categoriaNome: catNome),
                              ),
                            );
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TelaSubcategorias(
                                  categoriaNome: catNome,
                                  subcategorias: subcats,
                                ),
                              ),
                            );
                          }
                        }
                      },
                      borderRadius: BorderRadius.circular(15),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            categories[index]['icone'],
                            size: 40,
                            color: categories[index]['cor'],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            catNome,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- TELA INTERMEDIÁRIA: LISTA SUB-CATEGORIAS ---
class TelaSubcategorias extends StatelessWidget {
  final String categoriaNome;
  final List<String> subcategorias;

  const TelaSubcategorias({
    super.key,
    required this.categoriaNome,
    required this.subcategorias,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(categoriaNome, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.green[700],
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Escolha uma especialidade:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: subcategorias.length,
                itemBuilder: (context, index) {
                  final subcat = subcategorias[index];
                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      title: Text(
                        subcat,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.green,
                        size: 18,
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TelaComercios(
                              categoriaNome: categoriaNome,
                              subcategoriaNome: subcat,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- TELA 2: LISTA DE COMÉRCIOS (FILTRANDO DUPLICADOS PELO NOME) ---
class TelaComercios extends StatelessWidget {
  final String categoriaNome;
  final String? subcategoriaNome;
  final String? termoBusca;

  const TelaComercios({
    super.key,
    required this.categoriaNome,
    this.subcategoriaNome,
    this.termoBusca,
  });

  @override
  Widget build(BuildContext context) {
    Query query = FirebaseFirestore.instance.collection('comercios');

    if (termoBusca != null && termoBusca!.isNotEmpty) {
      query = query
          .where('nome', isGreaterThanOrEqualTo: termoBusca)
          .where('nome', isLessThanOrEqualTo: '$termoBusca\uf8ff');
    } else {
      query = query.where('categoria', isEqualTo: categoriaNome);
      if (subcategoriaNome != null) {
        query = query.where('subcategoria', isEqualTo: subcategoriaNome);
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          termoBusca != null
              ? 'Resultados para: "$termoBusca"'
              : (subcategoriaNome ?? categoriaNome),
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.green[700],
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: query.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                termoBusca != null
                    ? 'Nenhum comércio encontrado para "$termoBusca".'
                    : (subcategoriaNome != null
                          ? 'Nenhum comércio em $subcategoriaNome.'
                          : 'Nenhum comércio em $categoriaNome.'),
              ),
            );
          }

          // --- FILTRO ANTI-DUPLICADOS PELO NOME DO COMÉRCIO ---
          final docsBrutos = snapshot.data!.docs;
          final nomesVistos = <String>{};
          final listaComercios = docsBrutos.where((doc) {
            final dados = doc.data() as Map<String, dynamic>;
            final nomeLoja = (dados['nome'] ?? '')
                .toString()
                .trim()
                .toLowerCase();

            if (nomeLoja.isEmpty) return false;

            if (nomesVistos.contains(nomeLoja)) {
              return false;
            } else {
              nomesVistos.add(nomeLoja);
              return true;
            }
          }).toList();

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: listaComercios.length,
            itemBuilder: (context, index) {
              final dados =
                  listaComercios[index].data() as Map<String, dynamic>;

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  title: Text(
                    dados['nome'] ?? 'Sem nome',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    dados['descricao'] ?? 'Sem descrição',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.green,
                    size: 18,
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TelaDetalhes(
                          dadosComercio: dados,
                          comercioId: listaComercios[index].id,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// --- TELA 3: DETALHES DO COMÉRCIO ---
class TelaDetalhes extends StatefulWidget {
  final Map<String, dynamic> dadosComercio;
  final String? comercioId;
  const TelaDetalhes({
    super.key,
    required this.dadosComercio,
    this.comercioId,
  });

  @override
  State<TelaDetalhes> createState() => _TelaDetalhesState();
}

class _TelaDetalhesState extends State<TelaDetalhes> {
  @override
  void initState() {
    super.initState();
    _registrarVisita();
  }

  // Conta +1 visita neste estabelecimento sempre que os detalhes são abertos.
  void _registrarVisita() async {
    final id = widget.comercioId;
    if (id == null || id.isEmpty) return;
    try {
      await FirebaseFirestore.instance
          .collection('comercios')
          .doc(id)
          .update({'visitas': FieldValue.increment(1)});
    } catch (e) {
      debugPrint('Não foi possível registrar a visita: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final dadosComercio = widget.dadosComercio;
    final nome = dadosComercio['nome'] ?? 'Sem nome';
    final descricao = dadosComercio['descricao'] ?? 'Sem descrição';
    final endereco = dadosComercio['endereco'] ?? 'Endereço não informado';
    final horario = dadosComercio['horario'] ?? 'Horário não informado';
    final entrega = dadosComercio['entrega'] ?? 'Não informado';
    final tel1 = dadosComercio['telefone'] ?? '';
    final tel2 = dadosComercio['telefone2'] ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Detalhes do Estabelecimento',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.green[700],
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              nome,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const Divider(height: 30, thickness: 1),

            buildInfoRow(Icons.location_on, 'Endereço', endereco),
            buildInfoRow(Icons.access_time, 'Horário de Atendimento', horario),
            buildInfoRow(Icons.delivery_dining, 'Taxa de Entrega', entrega),

            const SizedBox(height: 10),
            const Text(
              'Sobre o Serviço:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              descricao,
              style: const TextStyle(
                fontSize: 15,
                color: Colors.black54,
                height: 1.4,
              ),
            ),

            const Divider(height: 40, thickness: 1),
            const Text(
              'Falar com o Atendimento:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),

            if (tel1.toString().isNotEmpty)
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.chat),
                label: const Text(
                  'WhatsApp - Atendimento Geral',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                onPressed: () => abrirWhatsApp(tel1.toString()),
              ),

            const SizedBox(height: 12),

            if (tel2.toString().isNotEmpty)
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.chat),
                label: const Text(
                  'WhatsApp - Pedidos / Suporte',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                onPressed: () => abrirWhatsApp(tel2.toString()),
              ),
          ],
        ),
      ),
    );
  }

  Widget buildInfoRow(IconData icone, String titulo, String valor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icone, color: Colors.green[700], size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  valor,
                  style: const TextStyle(fontSize: 16, color: Colors.black87),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

void abrirWhatsApp(String telefone) async {
  String numeroLimpo = telefone.replaceAll(RegExp(r'[^0-9]'), '');
  const String mensagem = "Olá! Vim pelo aplicativo ZapBairro.";
  Uri whatsappUrl = Uri.https("wa.me", "/55$numeroLimpo", {"text": mensagem});

  if (await canLaunchUrl(whatsappUrl)) {
    await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
  } else {
    debugPrint("Não foi possível abrir o WhatsApp");
  }
}

// --- TELA ADMIN: CONTADOR DE VISITAS (ACESSO RESTRITO) ---
class TelaAdmin extends StatelessWidget {
  const TelaAdmin({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Painel Admin • Visitas',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.green[900],
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('comercios').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('Nenhum estabelecimento cadastrado.'),
            );
          }

          // Agrega visitas por nome (soma documentos duplicados com o mesmo nome).
          final Map<String, int> visitasPorNome = {};
          for (final doc in snapshot.data!.docs) {
            final dados = doc.data() as Map<String, dynamic>;
            final nome = (dados['nome'] ?? 'Sem nome').toString().trim();
            if (nome.isEmpty) continue;
            final rawVisitas = dados['visitas'];
            final int visitas = rawVisitas is num ? rawVisitas.toInt() : 0;
            visitasPorNome[nome] = (visitasPorNome[nome] ?? 0) + visitas;
          }

          final ranking = visitasPorNome.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));

          final totalVisitas = ranking.fold<int>(
            0,
            (soma, e) => soma + e.value,
          );

          return Column(
            children: [
              Container(
                width: double.infinity,
                color: Colors.green[50],
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  children: [
                    Text(
                      '$totalVisitas',
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[900],
                      ),
                    ),
                    const Text('Total de visitas registradas'),
                    const SizedBox(height: 4),
                    Text(
                      '${ranking.length} estabelecimentos',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  itemCount: ranking.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = ranking[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: index < 3
                            ? Colors.green[700]
                            : Colors.grey[400],
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        item.key,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.visibility,
                            size: 18,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${item.value}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
