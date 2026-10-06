// A loja como as telas usam: dados do Firestore + coordenada + horário já
// interpretados, e os selos de "aberto agora" e de distância.
import 'package:flutter/material.dart';

import 'coordenadas.dart';
import 'horario.dart';

class LojaInfo {
  final String id;
  final Map<String, dynamic> dados;
  final Coordenada? coordenada;
  final HorarioSemana? horario;

  LojaInfo(this.id, this.dados)
    : coordenada = lerCoordenada(dados['localizacao']),
      horario = HorarioSemana.doComercio(dados);

  String get nome => (dados['nome'] ?? 'Sem nome').toString();

  /// null = horário não informado.
  StatusFuncionamento? statusEm(DateTime agora) => horario?.statusEm(agora);

  bool abertaEm(DateTime agora) => statusEm(agora)?.aberto ?? false;

  /// null quando falta a posição do morador ou a coordenada da loja.
  double? distanciaDe(Coordenada? origem) {
    final destino = coordenada;
    if (origem == null || destino == null) return null;
    return distanciaMetros(origem, destino);
  }
}

/// Comparador do mais perto para o mais longe; quem não tem coordenada vai
/// para o fim. Devolve 0 no empate para quem chama desempatar (o sort do Dart
/// não é estável).
int compararPorDistancia(LojaInfo a, LojaInfo b, Coordenada origem) {
  final da = a.distanciaDe(origem);
  final db = b.distanciaDe(origem);
  if (da == null && db == null) return 0;
  if (da == null) return 1;
  if (db == null) return -1;
  return da.compareTo(db);
}

/// "● Aberto · fecha às 18h" em verde ou "● Fechado · abre às 8h" em vermelho.
class SeloFuncionamento extends StatelessWidget {
  final StatusFuncionamento? status;
  final double tamanho;

  const SeloFuncionamento({super.key, required this.status, this.tamanho = 13});

  @override
  Widget build(BuildContext context) {
    final s = status;
    final cor = s == null
        ? Colors.grey[600]!
        : (s.aberto ? Colors.green[800]! : Colors.red[700]!);
    final texto = s?.texto ?? 'Horário não informado';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.circle, size: tamanho - 4, color: cor),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            texto,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: tamanho,
              color: cor,
              fontWeight: s == null ? FontWeight.normal : FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

/// Distância até a loja, com o ícone de "perto de mim".
class SeloDistancia extends StatelessWidget {
  final double metros;
  final double tamanho;

  const SeloDistancia({super.key, required this.metros, this.tamanho = 13});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.near_me, size: tamanho + 1, color: Colors.blue[700]),
        const SizedBox(width: 3),
        Text(
          formatarDistancia(metros),
          style: TextStyle(
            fontSize: tamanho,
            color: Colors.blue[800],
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
