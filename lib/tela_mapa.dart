// MAPA DO BAIRRO: as lojas com localização num mapa (pino verde = aberta,
// vermelho = fechada, azul = horário não informado), a posição do morador,
// o filtro "aberto agora" e o "como chegar".
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'coordenadas.dart';
import 'horario.dart';
import 'localizacao.dart';
import 'loja.dart';
import 'main.dart' show TelaDetalhes;

/// Até essa distância do centro do bairro o mapa abre na posição do morador;
/// mais longe que isso (outra cidade) ele abre enquadrando as lojas.
const double _raioDoBairroMetros = 30000;

class TelaMapa extends StatefulWidget {
  /// Só as lojas desta categoria (null = o bairro inteiro).
  final String? categoriaNome;

  /// Lojas já carregadas pela lista ou pela busca. Quando vêm, o mapa mostra
  /// exatamente essas e não lê o Firestore de novo.
  final List<LojaInfo>? lojas;

  final String? titulo;

  const TelaMapa({super.key, this.categoriaNome, this.lojas, this.titulo});

  @override
  State<TelaMapa> createState() => _TelaMapaState();
}

class _TelaMapaState extends State<TelaMapa> {
  Stream<List<LojaInfo>>? _lojasDoFirestore;
  GoogleMapController? _mapa;
  Coordenada? _posicao = LocalizacaoService.ultima;
  bool _temPermissao = LocalizacaoService.ultima != null;
  bool _soAbertos = false;
  LojaInfo? _selecionada;

  @override
  void initState() {
    super.initState();
    if (widget.lojas == null) {
      Query query = FirebaseFirestore.instance.collection('comercios');
      if (widget.categoriaNome != null) {
        query = query.where('categoria', isEqualTo: widget.categoriaNome);
      }
      _lojasDoFirestore = query.snapshots().map(_semRepetir);
    }
    _pegarPosicao(pedir: true);
  }

  @override
  void dispose() {
    _mapa?.dispose();
    super.dispose();
  }

  // Mesma regra da lista: a loja que aparece duas vezes na planilha (uma por
  // categoria) vira um pino só.
  static List<LojaInfo> _semRepetir(QuerySnapshot snapshot) {
    final vistos = <String>{};
    final lojas = <LojaInfo>[];
    for (final doc in snapshot.docs) {
      final dados = doc.data() as Map<String, dynamic>;
      final nome = (dados['nome'] ?? '').toString().trim().toLowerCase();
      if (nome.isEmpty || !vistos.add(nome)) continue;
      lojas.add(LojaInfo(doc.id, dados));
    }
    return lojas;
  }

  Future<void> _pegarPosicao({required bool pedir, bool avisar = false}) async {
    final resultado = await LocalizacaoService.posicaoAtual(
      pedirPermissao: pedir,
    );
    if (!mounted) return;
    if (!resultado.ok) {
      if (avisar) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(LocalizacaoService.explicar(resultado.estado))),
        );
      }
      return;
    }
    final posicao = resultado.posicao!;
    setState(() {
      _posicao = posicao;
      _temPermissao = true;
    });
    if (_pertoDoBairro(posicao) && _selecionada == null) {
      _mapa?.animateCamera(
        CameraUpdate.newLatLngZoom(_latLng(posicao), 15),
      );
    }
  }

  static LatLng _latLng(Coordenada c) => LatLng(c.latitude, c.longitude);

  static bool _pertoDoBairro(Coordenada c) =>
      distanciaMetros(c, kCentroDoBairro) <= _raioDoBairroMetros;

  CameraPosition _cameraInicial(List<LojaInfo> lojas) {
    final posicao = _posicao;
    if (posicao != null && _pertoDoBairro(posicao)) {
      return CameraPosition(target: _latLng(posicao), zoom: 15);
    }
    if (lojas.isEmpty) {
      return CameraPosition(target: _latLng(kCentroDoBairro), zoom: 14);
    }
    final lat =
        lojas.map((l) => l.coordenada!.latitude).reduce((a, b) => a + b) /
        lojas.length;
    final lng =
        lojas.map((l) => l.coordenada!.longitude).reduce((a, b) => a + b) /
        lojas.length;
    return CameraPosition(target: LatLng(lat, lng), zoom: 14);
  }

  // Sem a posição do morador no bairro, enquadra todas as lojas na tela.
  void _enquadrar(List<LojaInfo> lojas) {
    final posicao = _posicao;
    if (_mapa == null || lojas.length < 2) return;
    if (posicao != null && _pertoDoBairro(posicao)) return;

    var sul = lojas.first.coordenada!.latitude;
    var norte = sul;
    var oeste = lojas.first.coordenada!.longitude;
    var leste = oeste;
    for (final loja in lojas) {
      final c = loja.coordenada!;
      if (c.latitude < sul) sul = c.latitude;
      if (c.latitude > norte) norte = c.latitude;
      if (c.longitude < oeste) oeste = c.longitude;
      if (c.longitude > leste) leste = c.longitude;
    }
    _mapa!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(sul, oeste),
          northeast: LatLng(norte, leste),
        ),
        60,
      ),
    );
  }

  static double _corDoPino(LojaInfo loja, DateTime agora) {
    final status = loja.statusEm(agora);
    if (status == null) return BitmapDescriptor.hueAzure;
    return status.aberto ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueRed;
  }

  @override
  Widget build(BuildContext context) {
    final lojasProntas = widget.lojas;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.titulo ?? widget.categoriaNome ?? 'Mapa do bairro',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.green[700],
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: lojasProntas != null
          ? _conteudo(lojasProntas)
          : StreamBuilder<List<LojaInfo>>(
              stream: _lojasDoFirestore,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                return _conteudo(snapshot.data!);
              },
            ),
    );
  }

  Widget _conteudo(List<LojaInfo> todas) {
    final agora = agoraNoBairro();
    final comLugar = todas.where((l) => l.coordenada != null).toList();
    final visiveis = _soAbertos
        ? comLugar.where((l) => l.abertaEm(agora)).toList()
        : comLugar;

    final pinos = {
      for (final loja in visiveis)
        Marker(
          markerId: MarkerId(loja.id),
          position: _latLng(loja.coordenada!),
          icon: BitmapDescriptor.defaultMarkerWithHue(_corDoPino(loja, agora)),
          infoWindow: InfoWindow(
            title: loja.nome,
            snippet: loja.statusEm(agora)?.texto,
          ),
          onTap: () => setState(() => _selecionada = loja),
        ),
    };

    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: _cameraInicial(comLugar),
          markers: pinos,
          myLocationEnabled: _temPermissao,
          myLocationButtonEnabled: _temPermissao,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
          padding: EdgeInsets.only(
            top: 56,
            bottom: _selecionada == null ? 0 : 190,
          ),
          onMapCreated: (controlador) {
            _mapa = controlador;
            _enquadrar(comLugar);
          },
          onTap: (_) => setState(() => _selecionada = null),
        ),
        Positioned(top: 8, left: 0, right: 0, child: _barraDoMapa(visiveis)),
        if (comLugar.isEmpty)
          Center(
            child: Card(
              margin: const EdgeInsets.all(32),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'As lojas desta lista ainda não têm a localização '
                  'cadastrada no ZapBairro.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, color: Colors.grey[800]),
                ),
              ),
            ),
          ),
        if (_selecionada != null)
          Positioned(
            left: 12,
            right: 12,
            bottom: 16,
            child: _cartaoDaLoja(_selecionada!, agora),
          ),
      ],
    );
  }

  Widget _barraDoMapa(List<LojaInfo> visiveis) {
    final plural = visiveis.length == 1 ? 'loja' : 'lojas';
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          FilterChip(
            elevation: 3,
            avatar: Icon(
              Icons.schedule,
              size: 18,
              color: _soAbertos ? Colors.white : Colors.green[800],
            ),
            showCheckmark: false,
            label: const Text('Aberto agora'),
            labelStyle: TextStyle(
              color: _soAbertos ? Colors.white : Colors.black87,
              fontWeight: FontWeight.w600,
            ),
            backgroundColor: Colors.white,
            selectedColor: Colors.green[700],
            selected: _soAbertos,
            onSelected: (valor) => setState(() {
              _soAbertos = valor;
              _selecionada = null;
            }),
          ),
          const SizedBox(width: 8),
          if (!_temPermissao) ...[
            ActionChip(
              elevation: 3,
              backgroundColor: Colors.white,
              avatar: Icon(Icons.near_me, size: 18, color: Colors.blue[700]),
              label: const Text(
                'Perto de mim',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              onPressed: () => _pegarPosicao(pedir: true, avisar: true),
            ),
            const SizedBox(width: 8),
          ],
          Chip(
            elevation: 3,
            backgroundColor: Colors.white,
            label: Text('${visiveis.length} $plural no mapa'),
          ),
        ],
      ),
    );
  }

  Widget _cartaoDaLoja(LojaInfo loja, DateTime agora) {
    final distancia = loja.distanciaDe(_posicao);
    final endereco = (loja.dados['endereco'] ?? '').toString();

    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              loja.nome,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Flexible(
                  child: SeloFuncionamento(status: loja.statusEm(agora)),
                ),
                if (distancia != null) ...[
                  const SizedBox(width: 10),
                  SeloDistancia(metros: distancia),
                ],
              ],
            ),
            if (endereco.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                endereco,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey[700]),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[700],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TelaDetalhes(
                          dadosComercio: loja.dados,
                          comercioId: loja.id,
                        ),
                      ),
                    ),
                    child: const Text(
                      'Ver loja',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue[800],
                      side: BorderSide(color: Colors.blue[700]!),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.directions),
                    label: const Text(
                      'Como chegar',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onPressed: () => abrirComoChegar(loja.coordenada!),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
