import 'package:flutter_test/flutter_test.dart';
import 'package:zapbairro/visitas_importacao.dart';

Map<String, dynamic> loja(String nome, String cat, String sub, [int? visitas]) => {
  'nome': nome,
  'categoria': cat,
  'subcategoria': sub,
  'visitas': ?visitas,
};

void main() {
  test('mesma loja recupera o contador', () {
    final r = devolverVisitas(
      [loja('Padaria', 'Alimentação', 'Pães', 7), loja('Farmácia', 'Saúde', 'Remédios', 3)],
      [loja('Padaria', 'Alimentação', 'Pães'), loja('Farmácia', 'Saúde', 'Remédios')],
    );
    expect(r.lojas[0]['visitas'], 7);
    expect(r.lojas[1]['visitas'], 3);
    expect(r.totalAntes, 10);
    expect(r.totalDevolvido, 10);
    expect(r.perdidas, isEmpty);
  });

  test('loja que mudou de categoria leva as visitas pelo nome', () {
    final r = devolverVisitas(
      [loja('Padaria', 'Alimentação', 'Pães', 7)],
      [loja('Padaria', 'Comércio', 'Diversos')],
    );
    expect(r.lojas.single['visitas'], 7);
  });

  test('nome com maiúscula e espaço diferentes é a mesma loja', () {
    final r = devolverVisitas(
      [loja('MAGUARI - Padaria ', 'Alimentação', 'Pães', 4)],
      [loja('maguari - padaria', 'Alimentação', 'Pães')],
    );
    expect(r.lojas.single['visitas'], 4);
  });

  test('loja que saiu do JSON aparece como perdida', () {
    final r = devolverVisitas(
      [loja('Fechou', 'Serviços', 'X', 5)],
      [loja('Nova', 'Serviços', 'X')],
    );
    expect(r.lojas.single.containsKey('visitas'), isFalse);
    expect(r.perdidas, {'fechou': 5});
    expect(r.totalDevolvido, 0);
  });

  test('loja repetida no JSON: a primeira fica com o contador, sem dobrar', () {
    final r = devolverVisitas(
      [loja('Padaria', 'Alimentação', 'Pães', 6)],
      [loja('Padaria', 'Alimentação', 'Pães'), loja('Padaria', 'Alimentação', 'Pães')],
    );
    expect(r.lojas[0]['visitas'], 6);
    expect(r.lojas[1].containsKey('visitas'), isFalse);
    expect(r.totalDevolvido, 6);
  });

  test('o JSON não consegue mexer no contador', () {
    final r = devolverVisitas(
      [loja('Padaria', 'Alimentação', 'Pães', 2)],
      [loja('Padaria', 'Alimentação', 'Pães', 999)],
    );
    expect(r.lojas.single['visitas'], 2);
  });

  test('não altera as listas originais', () {
    final novos = [loja('Padaria', 'Alimentação', 'Pães')];
    devolverVisitas([loja('Padaria', 'Alimentação', 'Pães', 2)], novos);
    expect(novos.single.containsKey('visitas'), isFalse);
  });
}
