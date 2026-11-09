import 'package:flutter/material.dart';

/// Paleta "Pôr do sol" do MIRAQuest (mesma do material no Anki: tipo de nota
/// `MIRAQuest-Cloze`). Valores copiados do CSS `.card`/`.mira-*`.
abstract final class MiraCores {
  // Fundo (degradê da tela).
  static const Color solTopo = Color(0xFFFFD27A);
  static const Color solBase = Color(0xFFFF9466);

  // Texto e destaque.
  static const Color texto = Color(0xFF14213D);
  static const Color destaque = Color(0xFFE8590C);
  static const Color mudo = Color(0xFFB9A68C);

  // Superfícies.
  static const Color superficie = Color(0xFFFFFDF8);
  static const Color superficieBorda = Color(0xFFF3D6B0);
  static const Color pergunta = Color(0xFFFFF1DA);
  static const Color perguntaBorda = Color(0xFFFFDFB0);
  static const Color explicacao = Color(0xFFFFF6E8);

  // Botões de opção.
  static const Color botao = Color(0xFFFFF8EE);
  static const Color botaoBorda = Color(0xFFF1DDC2);

  // Feedback.
  static const Color acerto = Color(0xFF1F9E89);
  static const Color acertoFundo = Color(0xFFD3F4EE);
  static const Color erro = Color(0xFFD62839);
  static const Color erroFundo = Color(0xFFFFE0E3);

  static const LinearGradient fundo = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [solTopo, solBase],
  );
}
