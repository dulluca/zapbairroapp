// Testes da busca do ZapBairro, rodando contra os dados reais de lojistas.json.
//
// Antes, a busca era um prefixo exato do Firestore sobre o campo 'nome' — como
// os nomes começam com o conjunto ("MAGUARI - ...") e vêm em maiúsculas com
// acento, praticamente nenhum termo digitado pelo morador achava resultado.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:zapbairro/conteudo_json.dart';
import 'package:zapbairro/main.dart';

void main() {
  final lojistas = lerConteudoZapBairro(
    File('lojistas.json').readAsStringSync(),
  ).lojistas;

  List<Map<String, dynamic>> buscar(String termo) {
    final palavras = palavrasDaBusca(termo);
    return lojistas
        .where((loja) => relevanciaBusca(loja, palavras) > 0)
        .toList();
  }

  test('normalizarTexto tira acento e maiúscula', () {
    expect(
      normalizarTexto('MAGUARI - Sabor do Açaí'),
      'maguari - sabor do acai',
    );
    expect(normalizarTexto('Alimentação'), 'alimentacao');
  });

  test('palavrasDaBusca quebra em palavras e ignora vazios', () {
    expect(palavrasDaBusca('  Açaí   Grosso '), ['acai', 'grosso']);
    expect(palavrasDaBusca('   '), isEmpty);
  });

  test('acha pelo miolo do nome, sem acento e em minúscula', () {
    final achados = buscar('acai');
    expect(achados, isNotEmpty);
    expect(achados.any((l) => l['nome'] == 'MAGUARI - Sabor do Açaí'), isTrue);
  });

  test('acha pela descrição e pela subcategoria, não só pelo nome', () {
    expect(buscar('farinha de tapioca'), isNotEmpty);
    expect(buscar('comidas tipicas'), isNotEmpty);
  });

  test('acha pela categoria', () {
    expect(buscar('alimentacao'), isNotEmpty);
  });

  test('todas as palavras digitadas precisam casar', () {
    expect(buscar('acai xilofone'), isEmpty);
  });

  test('termo inexistente devolve lista vazia', () {
    expect(buscar('zzzzqqqq'), isEmpty);
  });

  test('busca vazia não filtra nada (usada na navegação por categoria)', () {
    expect(
      relevanciaBusca(lojistas.first, palavrasDaBusca('')),
      greaterThan(0),
    );
  });

  test('nome > categoria/subcategoria > descrição na relevancia', () {
    final palavras = palavrasDaBusca('pizza');

    const porNome = {'nome': 'MAGUARI - Pizza da Esquina', 'descricao': ''};
    const porTipo = {'nome': 'MAGUARI - Cantina', 'subcategoria': 'Pizzaria'};
    const porDescricao = {
      'nome': 'MAGUARI - Cantina',
      'descricao': 'faz pizza',
    };

    expect(relevanciaBusca(porNome, palavras), 3);
    expect(relevanciaBusca(porTipo, palavras), 2);
    expect(relevanciaBusca(porDescricao, palavras), 1);
  });
}
