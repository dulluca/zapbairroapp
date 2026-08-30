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

// Medidas dos dois botões da barra do topo (Utilidades/Emergências e Avisos
// Comunitários). Ficam aqui porque a barra reserva o espaco do 'leading' a
// partir delas: e o que mantem os dois botoes do mesmo tamanho e a mesma
// distancia das bordas da tela.
const double kLarguraBotaoBarra = 92;
const double kMargemBotaoBarra = 12;

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
  final TextEditingController _controladorBusca = TextEditingController();

  @override
  void dispose() {
    _controladorBusca.dispose();
    super.dispose();
  }

  // Abre a lista de resultados para o que o morador digitou.
  void _executarBusca() {
    final termo = _controladorBusca.text.trim();
    if (termo.isEmpty) return;
    FocusScope.of(context).unfocus();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            TelaComercios(categoriaNome: '', termoBusca: termo),
      ),
    );
  }

  // O app abre direto no diretorio: nao ha cadastro, login nem conta em
  // lugar nenhum, e toda funcao esta disponivel no primeiro toque.

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

  // Botão EMERGÊNCIA (canto esquerdo da barra): telefones de urgência.
  void _abrirEmergencia() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TelaEmergencia()),
    );
  }

  // Botão AVISOS (canto direito da barra): recados do bairro.
  void _abrirAvisos() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TelaAvisos()),
    );
  }

  // Botão quadrado da barra do topo (ícone colorido + rótulo embaixo).
  Widget _botaoDaBarra({
    required IconData icone,
    required String label,
    required Color cor,
    required VoidCallback onTap,
  }) {
    // O Center é obrigatório: o AppBar estica os widgets de 'actions' na
    // altura toda da barra (CrossAxisAlignment.stretch) mas centraliza o
    // 'leading'. Sem ele, o botão da direita nasce colado no topo e fica
    // desalinhado com o da esquerda.
    //
    // Semantics(button): o leitor de tela já lê o rótulo pelo Text; aqui só
    // avisamos que aquilo é um botão, e não um texto solto na barra.
    return Center(
      child: Semantics(
        button: true,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 34,
                decoration: BoxDecoration(
                  color: cor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: Icon(icone, color: Colors.white, size: 20),
              ),
              const SizedBox(height: 3),
              // Os rótulos são compridos para o canto da barra, então vêm com
              // a quebra de linha já marcada no texto ('\n'). A largura fixa
              // (a mesma dos dois botões) deixa os dois com o mesmo tamanho e
              // impede que um nome grande empurre o título ZapBairro do meio.
              SizedBox(
                width: kLarguraBotaoBarra,
                child: Text(
                  label,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8.5,
                    height: 1.15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Linha com os 3 botões de ação (acima da barra de busca).
  Widget _barraDeAcoes() {
    return Row(
      children: [
        _botaoAcao(
          Icons.headset_mic,
          'CONTATO',
          Colors.green[700]!,
          _abrirContato,
        ),
        const SizedBox(width: 10),
        _botaoAcao(
          Icons.star_rate,
          'AVALIAÇÃO',
          Colors.amber[800]!,
          _abrirAvaliacao,
        ),
        const SizedBox(width: 10),
        _botaoAcao(
          Icons.favorite,
          'FAVORITOS',
          Colors.red[600]!,
          _abrirFavoritos,
        ),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
        toolbarHeight: 72,
        title: GestureDetector(
          onLongPress: () => _abrirPortaoAdmin(context),
          child: const Text(
            'ZapBairro',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
        backgroundColor: Colors.green[700],
        centerTitle: true,
        // O 'leading' e centralizado dentro da largura reservada, entao ela
        // precisa ser a largura do botao mais margem dos DOIS lados; so assim
        // a folga da esquerda fica igual ao SizedBox que fecha o 'actions'.
        leadingWidth: kLarguraBotaoBarra + kMargemBotaoBarra * 2,
        leading: _botaoDaBarra(
          icone: Icons.health_and_safety,
          label: 'UTILIDADES/\nEMERGÊNCIAS',
          cor: Colors.red[600]!,
          onTap: _abrirEmergencia,
        ),
        actions: [
          _botaoDaBarra(
            icone: Icons.campaign,
            label: 'AVISOS\nCOMUNITÁRIOS',
            cor: Colors.green[900]!,
            onTap: _abrirAvisos,
          ),
          const SizedBox(width: kMargemBotaoBarra),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _barraDeAcoes(),
            const SizedBox(height: 14),
            TextField(
              controller: _controladorBusca,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _executarBusca(),
              decoration: InputDecoration(
                hintText: 'O que você procura no bairro hoje?',
                prefixIcon: IconButton(
                  icon: const Icon(Icons.search, color: Colors.green),
                  tooltip: 'Buscar',
                  onPressed: _executarBusca,
                ),
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
                            padding: const EdgeInsets.symmetric(horizontal: 8),
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

// --- BUSCA: comparação de texto sem depender de acento ou maiúscula ---
const Map<String, String> _acentos = {
  'á': 'a',
  'à': 'a',
  'ã': 'a',
  'â': 'a',
  'ä': 'a',
  'é': 'e',
  'è': 'e',
  'ê': 'e',
  'ë': 'e',
  'í': 'i',
  'ì': 'i',
  'î': 'i',
  'ï': 'i',
  'ó': 'o',
  'ò': 'o',
  'õ': 'o',
  'ô': 'o',
  'ö': 'o',
  'ú': 'u',
  'ù': 'u',
  'û': 'u',
  'ü': 'u',
  'ç': 'c',
  'ñ': 'n',
};

/// Deixa o texto em minúsculas e sem acentos, para "Açaí" casar com "acai".
String normalizarTexto(String texto) {
  final buffer = StringBuffer();
  for (final letra in texto.toLowerCase().split('')) {
    buffer.write(_acentos[letra] ?? letra);
  }
  return buffer.toString();
}

/// Quebra o que o morador digitou em palavras normalizadas.
List<String> palavrasDaBusca(String termo) => normalizarTexto(
  termo,
).split(RegExp(r'[\s,]+')).where((palavra) => palavra.isNotEmpty).toList();

/// Relevância do comércio para a busca: 0 = não casa, 3 = casa pelo nome.
/// Todas as palavras digitadas precisam aparecer em algum campo do comércio.
int relevanciaBusca(Map<String, dynamic> dados, List<String> palavras) {
  if (palavras.isEmpty) return 1;

  String campo(String chave) =>
      normalizarTexto((dados[chave] ?? '').toString());

  final nome = campo('nome');
  final tipo = '${campo('categoria')} ${campo('subcategoria')}';
  final resto = '${campo('descricao')} ${campo('endereco')}';
  final tudo = '$nome $tipo $resto';

  if (!palavras.every(tudo.contains)) return 0;
  if (palavras.every(nome.contains)) return 3;
  if (palavras.every(tipo.contains)) return 2;
  return 1;
}

// --- AVALIAÇÕES: widgets de exibição da nota dada pela comunidade ---

/// Cinco estrelas preenchidas conforme a nota (0 a 5). Só exibe, não recebe toque.
class EstrelasNota extends StatelessWidget {
  final double nota;
  final double tamanho;

  const EstrelasNota({super.key, required this.nota, this.tamanho = 16});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final posicao = i + 1;
        final IconData icone;
        if (nota >= posicao) {
          icone = Icons.star;
        } else if (nota >= posicao - 0.5) {
          icone = Icons.star_half;
        } else {
          icone = Icons.star_border;
        }
        return Icon(icone, color: Colors.amber[700], size: tamanho);
      }),
    );
  }
}

/// Linha compacta com as estrelas, a media e quantas pessoas avaliaram.
class LinhaAvaliacao extends StatelessWidget {
  final ResumoAvaliacoes resumo;
  final double tamanho;

  const LinhaAvaliacao({super.key, required this.resumo, this.tamanho = 16});

  @override
  Widget build(BuildContext context) {
    if (!resumo.temAvaliacao) {
      return Text(
        'Ainda sem avaliações — seja o primeiro a avaliar',
        style: TextStyle(fontSize: tamanho - 3, color: Colors.grey[600]),
      );
    }

    final media = resumo.media.toStringAsFixed(1).replaceAll('.', ',');
    final plural = resumo.total == 1 ? 'avaliação' : 'avaliações';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        EstrelasNota(nota: resumo.media, tamanho: tamanho),
        const SizedBox(width: 6),
        Text(
          '$media  (${resumo.total} $plural)',
          style: TextStyle(
            fontSize: tamanho - 2,
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
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
    final termo = (termoBusca ?? '').trim();
    final buscando = termo.isNotEmpty;
    final palavras = palavrasDaBusca(termo);

    Query query = FirebaseFirestore.instance.collection('comercios');

    // Na busca por texto lemos a coleção inteira e filtramos aqui no app.
    // O Firestore só sabe casar prefixo exato do campo 'nome' (com acento e
    // maiúscula iguais), então quem digitava "acai" ou "pizza" nunca achava
    // nada: os nomes começam com o conjunto ("MAGUARI - ...") e o termo que
    // interessa costuma estar na descrição ou na subcategoria.
    if (!buscando) {
      query = query.where('categoria', isEqualTo: categoriaNome);
      if (subcategoriaNome != null) {
        query = query.where('subcategoria', isEqualTo: subcategoriaNome);
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          buscando
              ? 'Resultados para: "$termo"'
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
          // --- FILTRO DA BUSCA + ANTI-DUPLICADOS PELO NOME DO COMÉRCIO ---
          final docsBrutos = snapshot.data?.docs ?? [];
          final nomesVistos = <String>{};
          final relevancias = <String, int>{};
          final listaComercios = <QueryDocumentSnapshot>[];

          for (final doc in docsBrutos) {
            final dados = doc.data() as Map<String, dynamic>;
            final nomeLoja = (dados['nome'] ?? '')
                .toString()
                .trim()
                .toLowerCase();

            if (nomeLoja.isEmpty) continue;
            if (!nomesVistos.add(nomeLoja)) continue;

            final relevancia = relevanciaBusca(dados, palavras);
            if (relevancia == 0) continue;

            relevancias[doc.id] = relevancia;
            listaComercios.add(doc);
          }

          if (buscando) {
            // Quem casa pelo nome vem primeiro, depois por tipo; dentro da
            // mesma relevância, ordem alfabética.
            listaComercios.sort((a, b) {
              final diferenca =
                  (relevancias[b.id] ?? 0) - (relevancias[a.id] ?? 0);
              if (diferenca != 0) return diferenca;

              final nomeA = ((a.data() as Map<String, dynamic>)['nome'] ?? '')
                  .toString();
              final nomeB = ((b.data() as Map<String, dynamic>)['nome'] ?? '')
                  .toString();
              return normalizarTexto(nomeA).compareTo(normalizarTexto(nomeB));
            });
          }

          if (listaComercios.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  buscando
                      ? 'Nenhum comércio encontrado para "$termo".'
                      : (subcategoriaNome != null
                            ? 'Nenhum comércio em $subcategoriaNome.'
                            : 'Nenhum comércio em $categoriaNome.'),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          // Notas da comunidade, para mostrar a média de cada loja na lista.
          return StreamBuilder<Map<String, ResumoAvaliacoes>>(
            stream: AvaliacaoService.resumoPorLoja(),
            builder: (context, snapNotas) {
              final resumos =
                  snapNotas.data ?? const <String, ResumoAvaliacoes>{};

              return ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: listaComercios.length,
                itemBuilder: (context, index) {
                  final dados =
                      listaComercios[index].data() as Map<String, dynamic>;
                  final loja = {...dados, 'id': listaComercios[index].id};
                  final resumo =
                      resumos[AvaliacaoService.chaveLojaAvaliada(
                        dados['nome'],
                      )] ??
                      ResumoAvaliacoes.vazio;

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
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            dados['descricao'] ?? 'Sem descrição',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          LinhaAvaliacao(resumo: resumo, tamanho: 15),
                        ],
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
  const TelaDetalhes({super.key, required this.dadosComercio, this.comercioId});

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
      await FirebaseFirestore.instance.collection('comercios').doc(id).update({
        'visitas': FieldValue.increment(1),
      });
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
            const SizedBox(height: 8),
            _blocoNota(nome),

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
                  'Falar com a loja',
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
                  'Pedidos e suporte',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                onPressed: () => abrirWhatsApp(tel2.toString()),
              ),

            const Divider(height: 40, thickness: 1),
            _secaoAvaliacoes(nome),
          ],
        ),
      ),
    );
  }

  // Estrelas + media da loja, alimentadas pelas avaliações dos moradores.
  Widget _blocoNota(String nome) {
    return StreamBuilder<Map<String, ResumoAvaliacoes>>(
      stream: AvaliacaoService.resumoPorLoja(),
      builder: (context, snapshot) {
        final resumo =
            (snapshot.data ??
                const <
                  String,
                  ResumoAvaliacoes
                >{})[AvaliacaoService.chaveLojaAvaliada(nome)] ??
            ResumoAvaliacoes.vazio;
        return LinhaAvaliacao(resumo: resumo, tamanho: 20);
      },
    );
  }

  // Abre o mesmo diálogo de estrelas usado na tela de Avaliacao.
  Future<void> _avaliarEstaLoja() async {
    final loja = {...widget.dadosComercio, 'id': widget.comercioId ?? ''};
    final enviou = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => _DialogoAvaliacao(loja: loja),
    );
    if (enviou == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Obrigado pela sua avaliação!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  // Botão de avaliar + o retrato das notas que a loja recebeu da vizinhança.
  Widget _secaoAvaliacoes(String nome) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Avaliações da vizinhança',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.green[800],
            side: BorderSide(color: Colors.green[700]!, width: 1.5),
            minimumSize: const Size(double.infinity, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: const Icon(Icons.star_rate),
          label: const Text(
            'Avaliar esta loja',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          onPressed: _avaliarEstaLoja,
        ),
        const SizedBox(height: 16),
        StreamBuilder<Map<String, ResumoAvaliacoes>>(
          stream: AvaliacaoService.resumoPorLoja(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final resumo =
                (snapshot.data ??
                    const <
                      String,
                      ResumoAvaliacoes
                    >{})[AvaliacaoService.chaveLojaAvaliada(nome)] ??
                ResumoAvaliacoes.vazio;

            if (!resumo.temAvaliacao) {
              return Text(
                'Nenhum morador avaliou esta loja ainda. '
                'Se você já foi atendido aqui, deixe sua nota para ajudar a vizinhança.',
                style: TextStyle(color: Colors.grey[600], height: 1.4),
              );
            }

            return _distribuicaoNotas(resumo);
          },
        ),
        const SizedBox(height: 20),
        const Text(
          'Últimas notas recebidas',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        StreamBuilder<List<Map<String, dynamic>>>(
          stream: AvaliacaoService.daLoja(nome),
          builder: (context, snapshot) {
            final avaliacoes = snapshot.data ?? const [];
            if (avaliacoes.isEmpty) {
              return Text(
                'A primeira nota desta loja pode ser a sua.',
                style: TextStyle(color: Colors.grey[600]),
              );
            }
            // So as mais recentes: a lista inteira nao acrescenta nada e
            // deixaria a tela de detalhes rolando sem fim.
            return Column(
              children: avaliacoes.take(5).map(_cartaoAvaliacao).toList(),
            );
          },
        ),
      ],
    );
  }

  // Quantas notas de cada estrela a loja recebeu, em barras proporcionais.
  Widget _distribuicaoNotas(ResumoAvaliacoes resumo) {
    final maior = [
      for (var nota = 1; nota <= 5; nota++) resumo.quantidadeDaNota(nota),
    ].reduce((a, b) => a > b ? a : b);

    return Column(
      children: [
        for (var nota = 5; nota >= 1; nota--)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                SizedBox(
                  width: 34,
                  child: Row(
                    children: [
                      Text(
                        '$nota',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 2),
                      Icon(Icons.star, size: 14, color: Colors.amber[700]),
                    ],
                  ),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: maior == 0
                          ? 0
                          : resumo.quantidadeDaNota(nota) / maior,
                      minHeight: 10,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.amber[700]!,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: 30,
                  child: Text(
                    '${resumo.quantidadeDaNota(nota)}',
                    textAlign: TextAlign.end,
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _cartaoAvaliacao(Map<String, dynamic> avaliacao) {
    final nota = (avaliacao['nota'] as num?)?.toDouble() ?? 0;
    final quando = _formatarData(avaliacao['criadoEm']);

    return Card(
      elevation: 0,
      color: Colors.grey[100],
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            EstrelasNota(nota: nota, tamanho: 18),
            const Spacer(),
            if (quando.isNotEmpty)
              Text(
                quando,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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
                MaterialPageRoute(builder: (_) => const TelaAvaliacoesAdmin()),
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
// TELA AVALIAÇÃO: morador busca ou escolhe uma loja recente e dá a nota.
// =====================================================================
class TelaAvaliacao extends StatefulWidget {
  const TelaAvaliacao({super.key});

  @override
  State<TelaAvaliacao> createState() => _TelaAvaliacaoState();
}

class _TelaAvaliacaoState extends State<TelaAvaliacao> {
  late Future<List<Map<String, dynamic>>> _futuro;
  final _controladorBusca = TextEditingController();

  @override
  void initState() {
    super.initState();
    _futuro = RecentesService.listar();
  }

  @override
  void dispose() {
    _controladorBusca.dispose();
    super.dispose();
  }

  // Sem esta busca a tela so servia a quem ja tinha aberto alguma loja: quem
  // instalou agora caia num aviso de lista vazia e nao tinha o que fazer aqui.
  void _buscarLoja() {
    final termo = _controladorBusca.text.trim();
    if (termo.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TelaComercios(categoriaNome: '', termoBusca: termo),
      ),
    );
  }

  Widget _campoBusca() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: TextField(
        controller: _controladorBusca,
        textInputAction: TextInputAction.search,
        onSubmitted: (_) => _buscarLoja(),
        decoration: InputDecoration(
          hintText: 'Procure a loja que você quer avaliar',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: IconButton(
            tooltip: 'Buscar loja',
            icon: Icon(Icons.arrow_forward, color: Colors.green[700]),
            onPressed: _buscarLoja,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 4),
        ),
      ),
    );
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
            return Column(
              children: [
                _campoBusca(),
                const Expanded(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.store_mall_directory_outlined,
                            size: 60,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Busque a loja acima para dar sua nota.\nAs lojas que você abrir também aparecem aqui.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          }
          return Column(
            children: [
              _campoBusca(),
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Ou escolha uma das lojas que você abriu:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
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
      await AvaliacaoService.enviar(loja: widget.loja, nota: _nota);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _enviando = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Não foi possível enviar: $e')));
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
          const SizedBox(height: 8),
          Text(
            'Sua nota entra na média da loja e aparece para toda a vizinhança.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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
            return const Center(child: Text('Nenhum acesso registrado ainda.'));
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
                    final nome = (dados['especialidade'] ?? 'Sem nome')
                        .toString();
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
// Data legível de um Timestamp do Firestore. Usada na tela de detalhes
// (avaliações da vizinhanca) e no painel administrativo.
String _formatarData(dynamic criadoEm) {
  if (criadoEm is! Timestamp) return '';
  final d = criadoEm.toDate();
  String dois(int n) => n.toString().padLeft(2, '0');
  return '${dois(d.day)}/${dois(d.month)}/${d.year} ${dois(d.hour)}:${dois(d.minute)}';
}

class TelaAvaliacoesAdmin extends StatelessWidget {
  const TelaAvaliacoesAdmin({super.key});

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

// Cabeçalho de uma seção (ex.: "Serviços públicos") dentro das listas de
// Utilidades/Emergências e Avisos Comunitários.
class _TituloSecao extends StatelessWidget {
  final String texto;
  final Color cor;

  const _TituloSecao(this.texto, this.cor);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 10),
      child: Row(
        children: [
          Container(width: 4, height: 20, color: cor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              texto.toUpperCase(),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.4,
                color: cor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Aviso de lista vazia, igual nas duas telas.
class _ListaVazia extends StatelessWidget {
  final IconData icone;
  final String texto;

  const _ListaVazia(this.icone, this.texto);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icone, size: 60, color: Colors.grey),
            const SizedBox(height: 12),
            Text(
              texto,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

// =====================================================================
// TELA UTILIDADES / EMERGÊNCIAS: telefones úteis do bairro agrupados por
// seção (emergências 24h, serviços públicos, apoio social, concessionárias),
// com um toque para ligar. A lista sai de lojistas.json ("emergencia") e
// chega aqui pela coleção 'emergencias' do Firestore.
// =====================================================================
class TelaEmergencia extends StatelessWidget {
  const TelaEmergencia({super.key});

  Future<void> _ligar(BuildContext context, String numero) async {
    final abriu = await abrirDiscador(numero);
    if (!abriu && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Não foi possível ligar. Disque $numero.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _cartao(BuildContext context, Map<String, dynamic> contato) {
    final nome = (contato['nome'] ?? '').toString();
    final descricao = (contato['descricao'] ?? '').toString();
    final telefone = (contato['telefone'] ?? '').toString().trim();
    // Sem telefone cadastrado o cartão continua na lista (o morador ainda vê
    // que o serviço existe), só não oferece o botão de ligar.
    final temTelefone = telefone.isNotEmpty;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: temTelefone ? Colors.red[600] : Colors.grey[400],
          child: const Icon(Icons.emergency, color: Colors.white),
        ),
        title: Text(
          nome.isEmpty ? 'Sem nome' : nome,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (descricao.isNotEmpty) Text(descricao),
            const SizedBox(height: 4),
            Text(
              temTelefone ? telefone : 'Telefone ainda não cadastrado',
              style: TextStyle(
                fontSize: temTelefone ? 16 : 13,
                fontWeight: temTelefone ? FontWeight.bold : FontWeight.normal,
                color: temTelefone ? Colors.red[700] : Colors.grey,
              ),
            ),
          ],
        ),
        trailing: temTelefone
            ? IconButton(
                icon: Icon(Icons.call, color: Colors.red[700], size: 30),
                tooltip: 'Ligar para $nome',
                onPressed: () => _ligar(context, telefone),
              )
            : null,
        onTap: temTelefone ? () => _ligar(context, telefone) : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Utilidades / Emergências',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.red[700],
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: ConteudoBairroService.emergencias(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final contatos = snapshot.data ?? [];
          if (contatos.isEmpty) {
            return const _ListaVazia(
              Icons.health_and_safety_outlined,
              'Nenhum telefone cadastrado ainda.',
            );
          }

          final secoes = agruparPorSecao(contatos);
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            itemCount: secoes.length,
            itemBuilder: (context, index) {
              final secao = secoes[index];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (secao.key.isNotEmpty)
                    _TituloSecao(secao.key, Colors.red[700]!),
                  ...secao.value.map((c) => _cartao(context, c)),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

// =====================================================================
// TELA AVISOS COMUNITÁRIOS: o mural do bairro (achados e perdidos, alertas
// da vizinhança, doações, classificados), agrupado por seção. A lista sai de
// lojistas.json ("avisos") e chega aqui pela coleção 'avisos' do Firestore.
// =====================================================================
class TelaAvisos extends StatelessWidget {
  const TelaAvisos({super.key});

  Widget _cartao(Map<String, dynamic> aviso) {
    final titulo = (aviso['titulo'] ?? '').toString();
    final mensagem = (aviso['mensagem'] ?? '').toString();
    final data = dataParaExibicao(aviso['data']);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.campaign, color: Colors.green[700]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    titulo.isEmpty ? 'Aviso' : titulo,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            if (data.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                data,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
            if (mensagem.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(mensagem, style: const TextStyle(fontSize: 15)),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Avisos Comunitários',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.green[700],
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: ConteudoBairroService.avisos(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final avisos = snapshot.data ?? [];
          if (avisos.isEmpty) {
            return const _ListaVazia(
              Icons.campaign_outlined,
              'Nenhum aviso no bairro por enquanto.',
            );
          }

          final secoes = agruparPorSecao(avisos);
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            itemCount: secoes.length,
            itemBuilder: (context, index) {
              final secao = secoes[index];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (secao.key.isNotEmpty)
                    _TituloSecao(secao.key, Colors.green[800]!),
                  ...secao.value.map(_cartao),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
