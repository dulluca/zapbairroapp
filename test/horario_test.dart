import 'package:flutter_test/flutter_test.dart';
import 'package:zapbairro/horario.dart';

// 2026-10-05 é uma segunda-feira.
DateTime seg(int h, [int m = 0]) => DateTime(2026, 10, 5, h, m);
DateTime dia(int deslocamento, int h, [int m = 0]) =>
    DateTime(2026, 10, 5 + deslocamento, h, m);

Map<String, dynamic> semana(String todos, {Map<String, String> exceto = const {}}) => {
  for (final chave in kChavesDias) chave: exceto[chave] ?? todos,
};

void main() {
  group('lerDia', () {
    test('formato da planilha', () {
      expect(lerDia('08:00-12:00 e 14:00-18:00'), const [
        Intervalo(480, 720),
        Intervalo(840, 1080),
      ]);
    });

    test('jeito falado também funciona', () {
      expect(lerDia('8h às 12h e 14h30 às 18h'), const [
        Intervalo(480, 720),
        Intervalo(870, 1080),
      ]);
    });

    test('vazio e "fechado" = fechado no dia', () {
      expect(lerDia(''), isEmpty);
      expect(lerDia(null), isEmpty);
      expect(lerDia('Fechado'), isEmpty);
    });

    test('24h', () {
      expect(lerDia('24h'), const [Intervalo(0, 1440)]);
    });

    test('texto que não dá para entender devolve null', () {
      expect(lerDia('08:00-'), isNull);
      expect(lerDia('25:00-26:00'), isNull);
      expect(lerDia('manhã e tarde'), isNull);
      expect(lerDia('08:00-08:00'), isNull);
    });
  });

  group('HorarioSemana.doComercio', () {
    test('sem nenhum dia preenchido = não informado', () {
      expect(HorarioSemana.doComercio(semana('')), isNull);
      expect(HorarioSemana.doComercio({'nome': 'Loja sem colunas'}), isNull);
    });

    test('um dia escrito errado = não informado (não arrisca "fechado")', () {
      expect(
        HorarioSemana.doComercio(semana('08:00-18:00', exceto: {'ter': 'xx'})),
        isNull,
      );
    });
  });

  group('statusEm', () {
    final comercial = HorarioSemana.doComercio(
      semana('08:00-12:00 e 14:00-18:00', exceto: {'sab': '08:00-12:00', 'dom': ''}),
    )!;

    test('aberto no turno da manhã', () {
      final s = comercial.statusEm(seg(9, 30));
      expect(s.aberto, isTrue);
      expect(s.texto, 'Aberto · fecha às 12h');
    });

    test('fechado no almoço, abre mais tarde', () {
      final s = comercial.statusEm(seg(12, 30));
      expect(s.aberto, isFalse);
      expect(s.texto, 'Fechado · abre às 14h');
    });

    test('fechado à noite, abre amanhã', () {
      expect(comercial.statusEm(seg(19)).texto, 'Fechado · abre amanhã às 8h');
    });

    test('sábado à tarde pula o domingo fechado', () {
      expect(
        comercial.statusEm(dia(5, 15)).texto,
        'Fechado · abre segunda às 8h',
      );
    });

    test('o horário de fechar já conta como fechado', () {
      expect(comercial.statusEm(seg(18)).aberto, isFalse);
    });

    test('turno que vira a meia-noite', () {
      final bar = HorarioSemana.doComercio(semana('19:00-01:00'))!;
      expect(bar.statusEm(seg(23)).texto, 'Aberto · fecha às 1h');
      // 0h30 de terça ainda é o turno de segunda.
      expect(bar.statusEm(dia(1, 0, 30)).aberto, isTrue);
      expect(bar.statusEm(dia(1, 2)).texto, 'Fechado · abre às 19h');
    });

    test('até meia-noite', () {
      final lanche = HorarioSemana.doComercio(semana('15:00-24:00'))!;
      expect(lanche.statusEm(seg(23, 59)).texto, 'Aberto · fecha à meia-noite');
      expect(lanche.statusEm(seg(10)).aberto, isFalse);
    });

    test('24 horas todos os dias', () {
      final farmacia = HorarioSemana.doComercio(semana('24h'))!;
      expect(farmacia.statusEm(seg(3)).texto, 'Aberto 24 horas');
    });

    test('meio da semana: abre quarta', () {
      final h = HorarioSemana.doComercio(
        semana('', exceto: {'qua': '09:00-17:00'}),
      )!;
      expect(h.statusEm(seg(10)).texto, 'Fechado · abre quarta às 9h');
    });
  });

  test('textoDoDia', () {
    final h = HorarioSemana.doComercio(
      semana('08:00-12:00 e 14:00-18:00', exceto: {'dom': ''}),
    )!;
    expect(h.textoDoDia(0), '08:00 às 12:00, 14:00 às 18:00');
    expect(h.textoDoDia(6), 'Fechado');
  });
}
