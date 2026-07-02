import 'package:flutter/material.dart';
// import 'splash_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:url_launcher/url_launcher.dart';

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
        title: const Text(
          'ZapBairro',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
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
                        builder: (context) =>
                            TelaDetalhes(dadosComercio: dados),
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
class TelaDetalhes extends StatelessWidget {
  final Map<String, dynamic> dadosComercio;
  const TelaDetalhes({super.key, required this.dadosComercio});

  @override
  Widget build(BuildContext context) {
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
  Uri whatsappUrl = Uri.parse("https://wa.me/55$numeroLimpo");

  if (await canLaunchUrl(whatsappUrl)) {
    await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
  } else {
    debugPrint("Não foi possível abrir o WhatsApp");
  }
}
