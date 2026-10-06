// Horario de funcionamento das lojas e o "aberto agora".
//
// O lojistas.json traz uma coluna por dia da semana (seg, ter, qua, qui, sex,
// sab, dom) com os intervalos do dia, por exemplo:
//   "08:00-12:00 e 14:00-18:00"   dois turnos
//   "19:00-01:00"                 vira a meia-noite (fecha 1h do dia seguinte)
//   "24h"                         aberto o dia inteiro
//   ""                            fechado nesse dia
// Se os sete dias vierem vazios, a loja fica com "Horario nao informado".
//
// Dart puro (sem Flutter) para o importar.dart validar o arquivo antes de
// subir para o Firestore.

const List<String> kChavesDias = ['seg', 'ter', 'qua', 'qui', 'sex', 'sab', 'dom'];
const List<String> kNomesDias = [
  'Segunda',
  'Terça',
  'Quarta',
  'Quinta',
  'Sexta',
  'Sábado',
  'Domingo',
];

const int _minutosNoDia = 24 * 60;

/// Um turno do dia, em minutos desde 00:00. Quando [fim] <= [inicio] o turno
/// atravessa a meia-noite e termina no dia seguinte.
class Intervalo {
  final int inicio;
  final int fim;

  const Intervalo(this.inicio, this.fim);

  bool get viraODia => fim <= inicio;
  bool get diaInteiro => inicio == 0 && fim == _minutosNoDia;

  @override
  bool operator ==(Object other) =>
      other is Intervalo && other.inicio == inicio && other.fim == fim;

  @override
  int get hashCode => Object.hash(inicio, fim);

  @override
  String toString() => '${formatarHora(inicio)}-${formatarHora(fim)}';
}

/// "08:00", "18:30". 24:00 continua 24:00 para o texto da tabela.
String formatarHora(int minutos) {
  final h = (minutos ~/ 60).toString().padLeft(2, '0');
  final m = (minutos % 60).toString().padLeft(2, '0');
  return '$h:$m';
}

/// "8h", "18h30", "meia-noite": o jeito de falar a hora no selo da loja.
String falarHora(int minutos) {
  if (minutos == 0 || minutos == _minutosNoDia) return 'meia-noite';
  final h = minutos ~/ 60;
  final m = minutos % 60;
  return m == 0 ? '${h}h' : '${h}h${m.toString().padLeft(2, '0')}';
}

/// "às 8h" ou "à meia-noite".
String _asHora(int minutos) {
  final hora = falarHora(minutos);
  return hora == 'meia-noite' ? 'à $hora' : 'às $hora';
}

final RegExp _hora = RegExp(r'(\d{1,2})(?:\s*[:hH]\s*(\d{2})|\s*[hH])?');

/// Lê a célula de um dia. Devolve a lista de turnos (vazia = fechado) ou
/// null quando o texto não dá para entender.
List<Intervalo>? lerDia(Object? valor) {
  final texto = (valor ?? '').toString().trim().toLowerCase();
  if (texto.isEmpty || texto == 'fechado') return const [];
  if (texto == '24h' || texto.contains('24 horas')) {
    return const [Intervalo(0, _minutosNoDia)];
  }

  final minutos = <int>[];
  for (final m in _hora.allMatches(texto)) {
    final h = int.parse(m.group(1)!);
    final min = int.parse(m.group(2) ?? '0');
    if (h > 24 || min > 59 || (h == 24 && min > 0)) return null;
    minutos.add(h * 60 + min);
  }
  if (minutos.isEmpty || minutos.length.isOdd) return null;

  final turnos = <Intervalo>[];
  for (var i = 0; i < minutos.length; i += 2) {
    final inicio = minutos[i] == _minutosNoDia ? 0 : minutos[i];
    final fim = minutos[i + 1];
    if (inicio == fim) return null;
    turnos.add(Intervalo(inicio, fim));
  }
  return turnos;
}

/// Situação da loja num momento: aberta ou fechada, com o texto do selo.
class StatusFuncionamento {
  final bool aberto;
  final String texto;

  const StatusFuncionamento(this.aberto, this.texto);
}

class HorarioSemana {
  /// Sete listas de turnos, de segunda (0) a domingo (6).
  final List<List<Intervalo>> dias;

  const HorarioSemana(this.dias);

  /// Horário da loja a partir das colunas seg..dom. Devolve null quando
  /// nenhum dia foi preenchido ou quando algum dia está escrito errado
  /// (melhor "não informado" do que dizer "fechado" sem ter certeza).
  static HorarioSemana? doComercio(Map<String, dynamic> dados) {
    final dias = <List<Intervalo>>[];
    for (final chave in kChavesDias) {
      final turnos = lerDia(dados[chave]);
      if (turnos == null) return null;
      dias.add(turnos);
    }
    if (dias.every((d) => d.isEmpty)) return null;
    return HorarioSemana(dias);
  }

  /// Texto da tabela da loja para um dia: "08:00 às 12:00, 14:00 às 18:00".
  String textoDoDia(int indice) {
    final turnos = dias[indice];
    if (turnos.isEmpty) return 'Fechado';
    if (turnos.length == 1 && turnos.first.diaInteiro) return '24 horas';
    return turnos
        .map((t) => '${formatarHora(t.inicio)} às ${formatarHora(t.fim)}')
        .join(', ');
  }

  StatusFuncionamento statusEm(DateTime agora) {
    final hoje = agora.weekday - 1;
    final ontem = (hoje + 6) % 7;
    final minuto = agora.hour * 60 + agora.minute;

    if (dias.every((d) => d.length == 1 && d.first.diaInteiro)) {
      return const StatusFuncionamento(true, 'Aberto 24 horas');
    }

    // Turno de ontem que atravessou a meia-noite e ainda não acabou.
    for (final t in dias[ontem]) {
      if (t.viraODia && minuto < t.fim) {
        return StatusFuncionamento(true, 'Aberto · fecha ${_asHora(t.fim)}');
      }
    }

    for (final t in dias[hoje]) {
      final dentro = t.viraODia
          ? minuto >= t.inicio
          : minuto >= t.inicio && minuto < t.fim;
      if (dentro) {
        if (t.diaInteiro) {
          return const StatusFuncionamento(true, 'Aberto até meia-noite');
        }
        return StatusFuncionamento(true, 'Aberto · fecha ${_asHora(t.fim)}');
      }
    }

    // Fechado: procura a próxima abertura, hoje mais tarde ou nos próximos dias.
    final maisTarde = dias[hoje].where((t) => t.inicio > minuto).toList()
      ..sort((a, b) => a.inicio.compareTo(b.inicio));
    if (maisTarde.isNotEmpty) {
      return StatusFuncionamento(
        false,
        'Fechado · abre ${_asHora(maisTarde.first.inicio)}',
      );
    }
    for (var salto = 1; salto <= 7; salto++) {
      final dia = (hoje + salto) % 7;
      if (dias[dia].isEmpty) continue;
      final primeiro = dias[dia]
          .map((t) => t.inicio)
          .reduce((a, b) => a < b ? a : b);
      final quando = salto == 1 ? 'amanhã' : kNomesDias[dia].toLowerCase();
      return StatusFuncionamento(
        false,
        'Fechado · abre $quando ${_asHora(primeiro)}',
      );
    }
    return const StatusFuncionamento(false, 'Fechado');
  }
}
