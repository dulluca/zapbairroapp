// Testes do leitor de lojistas.json — o arquivo passou a guardar, alem dos
// comercios, os telefones de emergencia e os avisos do bairro.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:zapbairro/conteudo_json.dart';

void main() {
  test('le as tres listas do arquivo real', () {
    final conteudo = lerConteudoZapBairro(
      File('lojistas.json').readAsStringSync(),
    );

    expect(conteudo.lojistas, isNotEmpty);
    expect(conteudo.emergencia, isNotEmpty);
    expect(conteudo.avisos, isNotEmpty);
  });

  test('todo contato de emergência tem nome e seção', () {
    final conteudo = lerConteudoZapBairro(
      File('lojistas.json').readAsStringSync(),
    );

    for (final contato in conteudo.emergencia) {
      expect((contato['nome'] ?? '').toString().trim(), isNotEmpty);
      // 'telefone' pode estar vazio (número ainda não levantado); a tela
      // mostra o contato sem o botão de ligar.
      expect((contato['secao'] ?? '').toString().trim(), isNotEmpty);
    }
  });

  test('todo aviso tem título e seção', () {
    final conteudo = lerConteudoZapBairro(
      File('lojistas.json').readAsStringSync(),
    );

    for (final aviso in conteudo.avisos) {
      expect((aviso['titulo'] ?? '').toString().trim(), isNotEmpty);
      expect((aviso['secao'] ?? '').toString().trim(), isNotEmpty);
    }
  });

  test('a ordem dos contatos de emergência não se repete', () {
    final conteudo = lerConteudoZapBairro(
      File('lojistas.json').readAsStringSync(),
    );
    final ordens = conteudo.emergencia.map((c) => c['ordem']).toList();

    expect(ordens.toSet().length, ordens.length);
  });

  test('aceita o formato antigo (lista solta de lojistas)', () {
    final conteudo = lerConteudoZapBairro('[{"nome": "Padaria do Zé"}]');

    expect(conteudo.lojistas.single['nome'], 'Padaria do Zé');
    expect(conteudo.emergencia, isEmpty);
    expect(conteudo.avisos, isEmpty);
  });

  test('chaves ausentes viram listas vazias, sem quebrar', () {
    final conteudo = lerConteudoZapBairro('{"lojistas": []}');

    expect(conteudo.lojistas, isEmpty);
    expect(conteudo.emergencia, isEmpty);
    expect(conteudo.avisos, isEmpty);
  });

  test('raiz de tipo inesperado é recusada com mensagem clara', () {
    expect(() => lerConteudoZapBairro('"texto solto"'), throwsFormatException);
  });
}
