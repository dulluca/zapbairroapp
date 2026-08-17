import 'package:flutter/material.dart';
// import 'splash_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:url_launcher/url_launcher.dart';
import 'servicos.dart';

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
class TelaCategorias extends StatefulWidget {
  const TelaCategorias({super.key});

  @override
  State<TelaCategorias> createState() => _TelaCategoriasState();
}

class _TelaCategoriasState extends State<TelaCategorias> {
  @override
  void initState() {
    super.initState();
    // DESATIVADO: cadastro de nome + WhatsApp no primeiro acesso.
    // Para reabilitar, descomente a linha abaixo e o metodo _verificarCadastro,
    // junto com a funcao mostrarCadastroMorador() mais abaixo neste arquivo.
    // WidgetsBinding.instance.addPostFrameCallback((_) => _verificarCadastro());
  }

  // DESATIVADO junto com o dialogo de cadastro do morador.
  // Future<void> _verificarCadastro() async {
  //   final cadastrado = await MoradorService.estaCadastrado();
  //   if (!cadastrado && mounted) {
  //     await mostrarCadastroMorador(context);
  //   }
  // }

  // Botão CONTATO: abre o WhatsApp oficial do ZapBairro.
  void _abrirContato() {
    abrirWhatsAppNumeroCompleto(
      kZapBairroWhats,
      mensagem: "Olá, ZapBairro! Falo com vocês pelo aplicativo.",
    );
  }

  // Botão AVALIAÇÃO: morador escolhe uma loja recente e avalia.
  void _abrirAvaliacao() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TelaAvaliacao()),
    );
  }

  // Botão FAVORITOS: lojas guardadas pelo morador.
  void _abrirFavoritos() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TelaFavoritos()),
    );
  }

  // Linha com os 3 botões de ação (acima da barra de busca).
  Widget _barraDeAcoes() {
    return Row(
      children: [
        _botaoAcao(Icons.headset_mic, 'CONTATO', Colors.green[700]!,
            _abrirContato),
        const SizedBox(width: 10),
        _botaoAcao(Icons.star_rate, 'AVALIAÇÃO', Colors.amber[800]!,
            _abrirAvaliacao),
        const SizedBox(width: 10),
        _botaoAcao(Icons.favorite, 'FAVORITOS', Colors.red[600]!,
            _abrirFavoritos),
      ],
    );
  }

  Widget _botaoAcao(
    IconData icone,
    String label,
    Color cor,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
            child: Column(
              children: [
                Icon(icone, color: cor, size: 26),
                const SizedBox(height: 6),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

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
            _barraDeAcoes(),
            const SizedBox(height: 14),
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
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.3,
                ),
                itemCount: subcategorias.length,
                itemBuilder: (context, index) {
                  final subcat = subcategorias[index];
                  final visual = iconeParaEspecialidade(subcat, index);
                  return Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(15),
                      onTap: () {
                        // Registra o acesso à especialidade (histórico).
                        EspecialidadeService.registrarAcesso(
                          especialidade: subcat,
                          categoria: categoriaNome,
                        );
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
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(visual.icone, size: 40, color: visual.cor),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                            ),
                            child: Text(
                              subcat,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
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
              final loja = {...dados, 'id': listaComercios[index].id};

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
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      BotaoFavorito(loja: loja),
                      const Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.green,
                        size: 18,
                      ),
                    ],
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
    // Guarda como "loja recente" para o fluxo de avaliação.
    RecentesService.registrar({
      ...widget.dadosComercio,
      'id': widget.comercioId ?? '',
    });
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
        actions: [
          BotaoFavorito(
            loja: {...dadosComercio, 'id': widget.comercioId ?? ''},
            corInativo: Colors.white,
          ),
        ],
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
        actions: [
          IconButton(
            tooltip: 'Avaliações dos moradores',
            icon: const Icon(Icons.rate_review, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const TelaAvaliacoesAdmin(),
                ),
              );
            },
          ),
          IconButton(
            tooltip: 'Acessos por especialidade',
            icon: const Icon(Icons.insights, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const TelaHistoricoEspecialidades(),
                ),
              );
            },
          ),
        ],
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

// =====================================================================
// BOTÃO DE FAVORITO (coração) reutilizável — reflete e alterna o estado.
// =====================================================================
class BotaoFavorito extends StatefulWidget {
  final Map<String, dynamic> loja;
  final Color corInativo;
  const BotaoFavorito({
    super.key,
    required this.loja,
    this.corInativo = Colors.grey,
  });

  @override
  State<BotaoFavorito> createState() => _BotaoFavoritoState();
}

class _BotaoFavoritoState extends State<BotaoFavorito> {
  bool _favorito = false;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    final f = await FavoritosService.ehFavorito(widget.loja);
    if (mounted) setState(() => _favorito = f);
  }

  Future<void> _alternar() async {
    final novo = await FavoritosService.alternar(widget.loja);
    if (!mounted) return;
    setState(() => _favorito = novo);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          novo ? 'Adicionado aos favoritos' : 'Removido dos favoritos',
        ),
        duration: const Duration(milliseconds: 900),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: _favorito ? 'Remover dos favoritos' : 'Guardar nos favoritos',
      icon: Icon(
        _favorito ? Icons.favorite : Icons.favorite_border,
        color: _favorito ? Colors.red : widget.corInativo,
      ),
      onPressed: _alternar,
    );
  }
}

// =====================================================================
// CADASTRO DO MORADOR (primeiro acesso): captura nome + WhatsApp.
//
// DESATIVADO: por enquanto nao coletamos nome nem WhatsApp do morador.
// O codigo abaixo fica comentado para podermos reabilitar depois; nesse
// caso, descomente tambem a chamada em _TelaCategoriasState.initState().
// =====================================================================
/*
Future<void> mostrarCadastroMorador(BuildContext context) async {
  final nomeCtrl = TextEditingController();
  final telCtrl = TextEditingController();
  final formKey = GlobalKey<FormState>();

  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      bool salvando = false;
      return StatefulBuilder(
        builder: (context, setDialogState) {
          Future<void> salvar() async {
            if (!formKey.currentState!.validate()) return;
            setDialogState(() => salvando = true);
            await MoradorService.salvar(nomeCtrl.text, telCtrl.text);
            if (dialogContext.mounted) Navigator.pop(dialogContext);
          }

          return AlertDialog(
            title: const Text('Bem-vindo ao ZapBairro!'),
            content: Form(
              key: formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Faça um cadastro rápido para começar a usar o app.',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: nomeCtrl,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Seu nome',
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Informe seu nome'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: telCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'WhatsApp (com DDD)',
                      hintText: 'Ex.: 91 98555 4004',
                      hintStyle: TextStyle(color: Colors.black26),
                      helperText: 'Digite DDD + número (só números)',
                      prefixIcon: Icon(Icons.phone),
                    ),
                    validator: (v) {
                      final digitos = (v ?? '').replaceAll(
                        RegExp(r'[^0-9]'),
                        '',
                      );
                      if (digitos.length < 10) {
                        return 'Informe um WhatsApp válido com DDD';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  foregroundColor: Colors.white,
                ),
                onPressed: salvando ? null : salvar,
                child: salvando
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Começar'),
              ),
            ],
          );
        },
      );
    },
  );
}
*/

// =====================================================================
// TELA FAVORITOS: lista as lojas que o morador guardou.
// =====================================================================
class TelaFavoritos extends StatefulWidget {
  const TelaFavoritos({super.key});

  @override
  State<TelaFavoritos> createState() => _TelaFavoritosState();
}

class _TelaFavoritosState extends State<TelaFavoritos> {
  late Future<List<Map<String, dynamic>>> _futuro;

  @override
  void initState() {
    super.initState();
    _recarregar();
  }

  void _recarregar() {
    _futuro = FavoritosService.listar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favoritos', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.green[700],
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _futuro,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final favoritos = snapshot.data ?? [];
          if (favoritos.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.favorite_border, size: 60, color: Colors.grey),
                    SizedBox(height: 12),
                    Text(
                      'Você ainda não tem lojas favoritas.\nToque no coração de uma loja para guardá-la aqui.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: favoritos.length,
            itemBuilder: (context, index) {
              final loja = favoritos[index];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  title: Text(
                    loja['nome'] ?? 'Sem nome',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    (loja['descricao'] ?? '').toString().isEmpty
                        ? 'Sem descrição'
                        : loja['descricao'],
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    tooltip: 'Remover',
                    onPressed: () async {
                      await FavoritosService.remover(loja);
                      setState(_recarregar);
                    },
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TelaDetalhes(
                          dadosComercio: loja,
                          comercioId: (loja['id'] ?? '').toString(),
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

// =====================================================================
// TELA AVALIAÇÃO: morador escolhe uma loja recente e dá nota + comentário.
// =====================================================================
class TelaAvaliacao extends StatefulWidget {
  const TelaAvaliacao({super.key});

  @override
  State<TelaAvaliacao> createState() => _TelaAvaliacaoState();
}

class _TelaAvaliacaoState extends State<TelaAvaliacao> {
  late Future<List<Map<String, dynamic>>> _futuro;

  @override
  void initState() {
    super.initState();
    _futuro = RecentesService.listar();
  }

  Future<void> _avaliar(Map<String, dynamic> loja) async {
    final resultado = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => _DialogoAvaliacao(loja: loja),
    );
    if (resultado == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Obrigado pela sua avaliação!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Avaliação', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.green[700],
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _futuro,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final recentes = snapshot.data ?? [];
          if (recentes.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.store_mall_directory_outlined,
                        size: 60, color: Colors.grey),
                    SizedBox(height: 12),
                    Text(
                      'Você ainda não visitou nenhuma loja.\nAbra uma loja para poder avaliá-la aqui.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            );
          }
          return Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Escolha a loja que você quer avaliar:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: recentes.length,
                  itemBuilder: (context, index) {
                    final loja = recentes[index];
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: Icon(
                          Icons.storefront,
                          color: Colors.green[700],
                        ),
                        title: Text(
                          loja['nome'] ?? 'Sem nome',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        trailing: const Icon(
                          Icons.star_rate,
                          color: Colors.amber,
                        ),
                        onTap: () => _avaliar(loja),
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

class _DialogoAvaliacao extends StatefulWidget {
  final Map<String, dynamic> loja;
  const _DialogoAvaliacao({required this.loja});

  @override
  State<_DialogoAvaliacao> createState() => _DialogoAvaliacaoState();
}

class _DialogoAvaliacaoState extends State<_DialogoAvaliacao> {
  int _nota = 0;
  final _comentarioCtrl = TextEditingController();
  bool _enviando = false;

  Future<void> _enviar() async {
    if (_nota == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escolha de 1 a 5 estrelas')),
      );
      return;
    }
    setState(() => _enviando = true);
    try {
      await AvaliacaoService.enviar(
        loja: widget.loja,
        nota: _nota,
        comentario: _comentarioCtrl.text,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _enviando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não foi possível enviar: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.loja['nome'] ?? 'Avaliar loja'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Como foi sua experiência?'),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final estrela = i + 1;
              return IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Icon(
                  estrela <= _nota ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 36,
                ),
                onPressed: () => setState(() => _nota = estrela),
              );
            }),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _comentarioCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Comentário (opcional)',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _enviando ? null : () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green[700],
            foregroundColor: Colors.white,
          ),
          onPressed: _enviando ? null : _enviar,
          child: _enviando
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Enviar'),
        ),
      ],
    );
  }
}

// =====================================================================
// TELA (ADMIN): histórico/ranking de acessos por especialidade.
// =====================================================================
class TelaHistoricoEspecialidades extends StatelessWidget {
  const TelaHistoricoEspecialidades({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Acessos por Especialidade',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.green[900],
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('especialidades_contagem')
            .orderBy('acessos', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('Nenhum acesso registrado ainda.'),
            );
          }
          final docs = snapshot.data!.docs;
          final total = docs.fold<int>(0, (soma, d) {
            final dados = d.data() as Map<String, dynamic>;
            final a = dados['acessos'];
            return soma + (a is num ? a.toInt() : 0);
          });

          return Column(
            children: [
              Container(
                width: double.infinity,
                color: Colors.green[50],
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  children: [
                    Text(
                      '$total',
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[900],
                      ),
                    ),
                    const Text('Total de acessos a especialidades'),
                    const SizedBox(height: 4),
                    Text(
                      '${docs.length} especialidades',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  itemCount: docs.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final dados = docs[index].data() as Map<String, dynamic>;
                    final nome =
                        (dados['especialidade'] ?? 'Sem nome').toString();
                    final categoria = (dados['categoria'] ?? '').toString();
                    final acessos = dados['acessos'];
                    final int qtd = acessos is num ? acessos.toInt() : 0;
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
                        nome,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: categoria.isEmpty ? null : Text(categoria),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.touch_app,
                            size: 18,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '$qtd',
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

// =====================================================================
// TELA (ADMIN): feedbacks / avaliações enviadas pelos moradores.
// =====================================================================
class TelaAvaliacoesAdmin extends StatelessWidget {
  const TelaAvaliacoesAdmin({super.key});

  String _formatarData(dynamic criadoEm) {
    if (criadoEm is! Timestamp) return '';
    final d = criadoEm.toDate();
    String dois(int n) => n.toString().padLeft(2, '0');
    return '${dois(d.day)}/${dois(d.month)}/${d.year} ${dois(d.hour)}:${dois(d.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Avaliações dos Moradores',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.green[900],
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('avaliacoes')
            .orderBy('criadoEm', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Não foi possível carregar as avaliações.\nVerifique as regras/índice do Firestore.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('Nenhuma avaliação recebida ainda.'),
            );
          }

          final docs = snapshot.data!.docs;

          // Média geral das notas.
          final notas = docs
              .map((d) {
                final dados = d.data() as Map<String, dynamic>;
                final n = dados['nota'];
                return n is num ? n.toDouble() : 0.0;
              })
              .where((n) => n > 0)
              .toList();
          final media = notas.isEmpty
              ? 0.0
              : notas.reduce((a, b) => a + b) / notas.length;

          return Column(
            children: [
              Container(
                width: double.infinity,
                color: Colors.green[50],
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 30),
                        const SizedBox(width: 6),
                        Text(
                          media.toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[900],
                          ),
                        ),
                      ],
                    ),
                    const Text('Média geral das avaliações'),
                    const SizedBox(height: 4),
                    Text(
                      '${docs.length} avaliações recebidas',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final dados = docs[index].data() as Map<String, dynamic>;
                    final loja = (dados['comercioNome'] ?? 'Loja').toString();
                    final notaRaw = dados['nota'];
                    final int nota = notaRaw is num ? notaRaw.toInt() : 0;
                    final comentario = (dados['comentario'] ?? '')
                        .toString()
                        .trim();
                    final moradorNome = (dados['moradorNome'] ?? '')
                        .toString()
                        .trim();
                    final moradorTel = (dados['moradorTelefone'] ?? '')
                        .toString()
                        .trim();
                    final data = _formatarData(dados['criadoEm']);

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    loja,
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                if (data.isNotEmpty)
                                  Text(
                                    data,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: List.generate(
                                5,
                                (i) => Icon(
                                  i < nota ? Icons.star : Icons.star_border,
                                  color: Colors.amber,
                                  size: 20,
                                ),
                              ),
                            ),
                            if (comentario.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                '"$comentario"',
                                style: const TextStyle(
                                  fontStyle: FontStyle.italic,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                            if (moradorNome.isNotEmpty ||
                                moradorTel.isNotEmpty) ...[
                              const Divider(height: 18),
                              Row(
                                children: [
                                  Icon(
                                    Icons.person,
                                    size: 16,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      [
                                        if (moradorNome.isNotEmpty) moradorNome,
                                        if (moradorTel.isNotEmpty) moradorTel,
                                      ].join(' • '),
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ),
                                  if (moradorTel.isNotEmpty)
                                    IconButton(
                                      tooltip: 'Falar no WhatsApp',
                                      icon: const Icon(
                                        Icons.chat,
                                        color: Colors.green,
                                        size: 20,
                                      ),
                                      onPressed: () =>
                                          abrirWhatsAppNumeroCompleto(
                                        moradorTel,
                                        mensagem:
                                            'Olá! Aqui é do ZapBairro, sobre sua avaliação.',
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ],
                        ),
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
