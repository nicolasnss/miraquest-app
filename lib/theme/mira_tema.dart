// =====================================================================
// MiraQuest · tema visual "Pôr do sol"
// Mesma identidade dos Shorts (kit de vídeos) e do template do Anki.
// Use SEMPRE estas constantes nas telas: nada de Color(0x...) solto.
// =====================================================================
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Paleta oficial.
class MiraCores {
  MiraCores._();

  // Céu das 17h (fundo em degradê)
  static const Color ceuTopo = Color(0xFFFFD27A);
  static const Color ceuBase = Color(0xFFFF9466);

  // Card e superfícies
  static const Color card = Color(0xFFFFFDF8);
  static const Color cardBorda = Color(0xFFF3D6B0);

  // Texto
  static const Color texto = Color(0xFF14213D); // azul-marinho
  static const Color textoSuave = Color(0xFFB9A68C);

  // Destaque (matéria, lacuna, rótulos)
  static const Color destaque = Color(0xFFE8590C); // laranja do pôr do sol

  // Área da pergunta
  static const Color perguntaFundo = Color(0xFFFFF1DA);
  static const Color perguntaBorda = Color(0xFFFFD9A3);

  // Botões de opção
  static const Color botao = Color(0xFFFFF8EE);
  static const Color botaoBorda = Color(0xFFF1DDC2);

  // Feedback
  static const Color acerto = Color(0xFF1F9E89);
  static const Color acertoFundo = Color(0xFFD3F4EE);
  static const Color erro = Color(0xFFD62839);
  static const Color erroFundo = Color(0xFFFFE0E3);

  // Explicação técnica
  static const Color explicacaoFundo = Color(0xFFFFF6E8);
  static const Color explicacaoBorda = Color(0xFFFFDFB0);

  // Gamificação
  static const Color xp = Color(0xFFF59F00); // âmbar
  static const Color vidas = Color(0xFFD62839);
  static const Color sequencia = Color(0xFFE8590C);
}

/// Estados possíveis de um botão de opção.
enum EstadoOpcao { normal, correta, errada }

/// Estilos reutilizáveis.
class MiraEstilo {
  MiraEstilo._();

  /// Fundo de tela com o degradê do céu.
  static const BoxDecoration fundoCeu = BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [MiraCores.ceuTopo, MiraCores.ceuBase],
    ),
  );

  /// Card principal da questão.
  static BoxDecoration card = BoxDecoration(
    color: MiraCores.card,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: MiraCores.cardBorda),
    boxShadow: [
      BoxShadow(
        color: MiraCores.texto.withValues(alpha: 0.15),
        blurRadius: 20,
        offset: const Offset(0, 8),
      ),
    ],
  );

  /// Faixa da pergunta (fundo creme com bordas).
  static const BoxDecoration faixaPergunta = BoxDecoration(
    color: MiraCores.perguntaFundo,
    border: Border(
      top: BorderSide(color: MiraCores.explicacaoBorda),
      bottom: BorderSide(color: MiraCores.perguntaBorda, width: 2),
    ),
  );

  /// Caixa de "Explicação técnica". A faixa laranja da esquerda é desenhada
  /// à parte (veja [larguraFaixaExplicacao]/[faixaExplicacao]): o Flutter não
  /// aceita `borderRadius` com bordas de cores diferentes (lança erro ao pintar).
  static BoxDecoration explicacao = BoxDecoration(
    color: MiraCores.explicacaoFundo,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: MiraCores.explicacaoBorda, width: 2),
  );

  /// Faixa laranja (6px) colada à esquerda da caixa de explicação.
  static const double larguraFaixaExplicacao = 6;
  static const Color faixaExplicacao = MiraCores.destaque;

  /// Botão de opção no estilo "tecla" (borda inferior mais grossa).
  static BoxDecoration botaoOpcao(EstadoOpcao estado) {
    final (fundo, borda) = switch (estado) {
      EstadoOpcao.correta => (MiraCores.acertoFundo, MiraCores.acerto),
      EstadoOpcao.errada => (MiraCores.erroFundo, MiraCores.erro),
      EstadoOpcao.normal => (MiraCores.botao, MiraCores.botaoBorda),
    };
    return BoxDecoration(
      color: fundo,
      borderRadius: BorderRadius.circular(12),
      border: Border(
        top: BorderSide(color: borda, width: 2),
        left: BorderSide(color: borda, width: 2),
        right: BorderSide(color: borda, width: 2),
        bottom: BorderSide(color: borda, width: 4),
      ),
    );
  }

  static Color textoOpcao(EstadoOpcao estado) => switch (estado) {
    EstadoOpcao.correta => MiraCores.acerto,
    EstadoOpcao.errada => MiraCores.erro,
    EstadoOpcao.normal => MiraCores.texto,
  };

  // ---- Tipografia (Poppins, igual aos vídeos) ----
  static TextStyle materia = GoogleFonts.poppins(
    fontSize: 12,
    fontWeight: FontWeight.w800,
    letterSpacing: 1.5,
    color: MiraCores.destaque,
  );

  static TextStyle pergunta = GoogleFonts.poppins(
    fontSize: 19,
    fontWeight: FontWeight.w700,
    height: 1.4,
    color: MiraCores.texto,
  );

  /// Trecho da lacuna "[...]" ou da resposta revelada dentro da pergunta.
  static TextStyle lacuna = GoogleFonts.poppins(
    fontSize: 19,
    fontWeight: FontWeight.w800,
    height: 1.4,
    color: MiraCores.destaque,
    decoration: TextDecoration.underline,
    decorationStyle: TextDecorationStyle.dashed,
    decorationColor: MiraCores.destaque,
  );

  static TextStyle opcao = GoogleFonts.poppins(
    fontSize: 15,
    fontWeight: FontWeight.w700,
  );

  static TextStyle rotuloExplicacao = GoogleFonts.poppins(
    fontSize: 13,
    fontWeight: FontWeight.w800,
    letterSpacing: 2,
    color: MiraCores.destaque,
  );

  static TextStyle textoExplicacao = GoogleFonts.poppins(
    fontSize: 17,
    fontWeight: FontWeight.w500,
    height: 1.6,
    color: MiraCores.texto,
  );

  static TextStyle feedbackAcerto = GoogleFonts.poppins(
    fontSize: 15,
    fontWeight: FontWeight.w800,
    color: MiraCores.acerto,
  );

  static TextStyle feedbackErro = GoogleFonts.poppins(
    fontSize: 15,
    fontWeight: FontWeight.w800,
    color: MiraCores.erro,
  );
}

/// ThemeData do app. Em main.dart: `theme: MiraTema.claro,`
class MiraTema {
  MiraTema._();

  static ThemeData get claro {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: MiraCores.destaque,
        primary: MiraCores.destaque,
        secondary: MiraCores.xp,
        surface: MiraCores.card,
        error: MiraCores.erro,
      ),
      scaffoldBackgroundColor: MiraCores.ceuTopo,
    );
    return base.copyWith(
      textTheme: GoogleFonts.poppinsTextTheme(
        base.textTheme,
      ).apply(bodyColor: MiraCores.texto, displayColor: MiraCores.texto),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: MiraCores.texto,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: MiraCores.texto,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: MiraCores.destaque,
          foregroundColor: Colors.white,
          textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: MiraCores.xp,
        linearTrackColor: MiraCores.botaoBorda,
      ),
    );
  }
}
