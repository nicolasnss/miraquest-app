import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/questao_model.dart';
import '../services/api_service.dart';
import '../theme/mira_cores.dart';

const int _kQuestoesPorLicao = 5;

/// Lacuna no texto: sequência de dois ou mais underscores.
final RegExp _lacunaRegex = RegExp(r'_{2,}');

class LicaoScreen extends StatefulWidget {
  const LicaoScreen({
    super.key,
    required this.materia,
    this.usuarioId = 1,
    this.vidasInicial = 3,
    this.apiService,
  });

  final String materia;

  /// ID do usuário logado (alinhado ao backend Java).
  final int usuarioId;
  final int vidasInicial;
  final ApiService? apiService;

  @override
  State<LicaoScreen> createState() => _LicaoScreenState();
}

class _LicaoScreenState extends State<LicaoScreen> {
  late final ApiService _api = widget.apiService ?? ApiService();
  late final PageController _pageController = PageController();
  late final Future<List<QuestaoModel>> _licaoFuture = _api.getLicao(
    widget.materia,
  );

  int _vidas = 0;
  int _indiceAtual = 0;
  int _xpSessao = 0;
  bool _missaoConcluida = false;
  bool _enviando = false;

  @override
  void initState() {
    super.initState();
    _vidas = widget.vidasInicial;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  bool _isCertoErrado(QuestaoModel q) {
    return q.tipo == TipoQuestao.certoErrado ||
        q.tipo == TipoQuestao.verdadeiroFalso;
  }

  bool _isCloze(QuestaoModel q) {
    return q.tipo == TipoQuestao.cloze || q.tipo == TipoQuestao.lacuna;
  }

  Future<void> _processarResposta({
    required QuestaoModel questao,
    required String resposta,
    required int totalQuestoes,
  }) async {
    if (_enviando) return;
    setState(() => _enviando = true);

    try {
      final resultado = await _api.verificarResposta(
        usuarioId: widget.usuarioId,
        questaoId: questao.id,
        resposta: resposta,
        materia: widget.materia,
      );

      if (!mounted) return;

      if (resultado.sucesso) {
        HapticFeedback.lightImpact();
        if (resultado.xpGanho > 0) {
          setState(() => _xpSessao += resultado.xpGanho);
        }
        await _mostrarFeedbackAcerto(resultado.pegadinha);
      } else {
        HapticFeedback.heavyImpact();
        setState(() {
          _vidas = (_vidas - 1).clamp(0, 999);
        });
        await _mostrarFeedbackErro(resultado.explicacao, resultado.pegadinha);
      }

      if (!mounted) return;

      final ultima = _indiceAtual >= totalQuestoes - 1;
      if (ultima) {
        setState(() {
          _missaoConcluida = true;
          _enviando = false;
        });
      } else {
        await _pageController.nextPage(
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
        );
        if (mounted) setState(() => _enviando = false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _enviando = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro: $e')));
    }
  }

  Future<void> _mostrarFeedbackAcerto(String? pegadinha) {
    final primary = Theme.of(context).colorScheme.primary;

    return showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Material(
            color: MiraCores.acertoFundo,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: MiraCores.acerto,
                    size: 56,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Muito bem!',
                    style: GoogleFonts.roboto(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: primary,
                    ),
                  ),
                  if (pegadinha != null) ...[
                    const SizedBox(height: 16),
                    _NotaPegadinha(texto: pegadinha),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      style: FilledButton.styleFrom(
                        backgroundColor: MiraCores.acerto,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'CONTINUAR',
                        style: GoogleFonts.roboto(
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _mostrarFeedbackErro(String explicacao, String? pegadinha) {
    final primary = Theme.of(context).colorScheme.primary;

    return showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Material(
            color: MiraCores.erroFundo,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.cancel_rounded,
                        color: MiraCores.erro,
                        size: 40,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Resposta incorreta',
                          style: GoogleFonts.roboto(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (explicacao.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      explicacao,
                      style: GoogleFonts.roboto(
                        fontSize: 15,
                        height: 1.45,
                        color: MiraCores.texto,
                      ),
                    ),
                  ],
                  if (pegadinha != null) ...[
                    const SizedBox(height: 16),
                    _NotaPegadinha(texto: pegadinha),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      style: FilledButton.styleFrom(
                        backgroundColor: MiraCores.erro,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'CONTINUAR',
                        style: GoogleFonts.roboto(
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final accent = theme.colorScheme.secondary;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Lição: ${widget.materia}',
          style: GoogleFonts.roboto(fontWeight: FontWeight.w600),
        ),
      ),
      body: FutureBuilder<List<QuestaoModel>>(
        future: _licaoFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Não foi possível carregar a lição.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.roboto(color: theme.colorScheme.error),
                ),
              ),
            );
          }

          final todas = snapshot.data ?? [];
          if (todas.isEmpty) {
            return Center(
              child: Text(
                'Nenhuma questão disponível para esta matéria.',
                style: GoogleFonts.roboto(
                  fontSize: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            );
          }

          final questoes = todas.length > _kQuestoesPorLicao
              ? todas.sublist(0, _kQuestoesPorLicao)
              : todas;

          if (_missaoConcluida) {
            return _MissaoCumpridaView(
              xpTotal: _xpSessao,
              primary: primary,
              accent: accent,
              onVoltar: () => Navigator.of(context).pop(),
            );
          }

          return Column(
            children: [
              _BarraProgressoELives(
                indice: _indiceAtual,
                total: questoes.length,
                vidas: _vidas,
                primary: primary,
                accent: accent,
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: questoes.length,
                  onPageChanged: (i) => setState(() => _indiceAtual = i),
                  itemBuilder: (context, index) {
                    final q = questoes[index];
                    return SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                      child: _PainelQuestao(
                        questao: q,
                        bloqueado: _enviando,
                        isCertoErrado: _isCertoErrado(q),
                        isCloze: _isCloze(q),
                        primary: primary,
                        accent: accent,
                        onResponder: (texto) => _processarResposta(
                          questao: q,
                          resposta: texto,
                          totalQuestoes: questoes.length,
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

class _BarraProgressoELives extends StatelessWidget {
  const _BarraProgressoELives({
    required this.indice,
    required this.total,
    required this.vidas,
    required this.primary,
    required this.accent,
  });

  final int indice;
  final int total;
  final int vidas;
  final Color primary;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final progresso = total == 0 ? 0.0 : (indice + 1) / total;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.favorite_rounded, color: MiraCores.erro, size: 22),
              const SizedBox(width: 6),
              Text(
                '$vidas',
                style: GoogleFonts.roboto(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: primary,
                ),
              ),
              const Spacer(),
              Text(
                '${indice + 1}/$total',
                style: GoogleFonts.roboto(
                  fontWeight: FontWeight.w600,
                  color: primary.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progresso.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: primary.withValues(alpha: 0.12),
              color: accent,
            ),
          ),
        ],
      ),
    );
  }
}

/// Aviso de "pegadinha" exibido após responder (a API só a revela depois).
class _NotaPegadinha extends StatelessWidget {
  const _NotaPegadinha({required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: MiraCores.explicacao,
        borderRadius: BorderRadius.circular(12),
        border: const Border(
          left: BorderSide(color: MiraCores.destaque, width: 6),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: MiraCores.destaque),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Pegadinha: $texto',
              style: GoogleFonts.roboto(
                fontSize: 14,
                height: 1.4,
                color: MiraCores.texto,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PainelQuestao extends StatelessWidget {
  const _PainelQuestao({
    required this.questao,
    required this.bloqueado,
    required this.isCertoErrado,
    required this.isCloze,
    required this.primary,
    required this.accent,
    required this.onResponder,
  });

  final QuestaoModel questao;
  final bool bloqueado;
  final bool isCertoErrado;
  final bool isCloze;
  final Color primary;
  final Color accent;
  final void Function(String resposta) onResponder;

  @override
  Widget build(BuildContext context) {
    final opcoesCloze = isCloze ? questao.opcoes : const <String>[];

    if (isCloze && opcoesCloze.isEmpty) {
      debugPrint(
        '[MIRAQuest Cloze] Lista de opções vazia — '
        'questaoId=${questao.id} tipo=${questao.tipo} '
        'opcoes=${questao.opcoes}',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (questao.banca != null) ...[
          Align(
            alignment: Alignment.centerLeft,
            child: Chip(
              label: Text(
                questao.banca!,
                style: GoogleFonts.roboto(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: MiraCores.destaque,
                ),
              ),
              visualDensity: VisualDensity.compact,
              backgroundColor: MiraCores.pergunta,
              side: BorderSide.none,
            ),
          ),
          const SizedBox(height: 8),
        ],
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: MiraCores.pergunta,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: MiraCores.perguntaBorda),
            boxShadow: [
              BoxShadow(
                color: primary.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: isCloze
              ? _EnunciadoCloze(
                  enunciado: questao.enunciado,
                  primary: primary,
                  accent: accent,
                )
              : Text(
                  questao.enunciado,
                  style: GoogleFonts.roboto(
                    fontSize: 17,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                    color: primary,
                  ),
                ),
        ),
        const SizedBox(height: 24),
        if (isCertoErrado)
          _BotoesCertoErrado(
            bloqueado: bloqueado,
            primary: primary,
            onTap: onResponder,
          )
        else if (isCloze)
          _OpcoesCloze(
            opcoes: opcoesCloze,
            bloqueado: bloqueado,
            primary: primary,
            accent: accent,
            onTap: onResponder,
          )
        else
          _FallbackTipo(
            questao: questao,
            bloqueado: bloqueado,
            primary: primary,
            accent: accent,
            onTap: onResponder,
          ),
      ],
    );
  }
}

class _EnunciadoCloze extends StatelessWidget {
  const _EnunciadoCloze({
    required this.enunciado,
    required this.primary,
    required this.accent,
  });

  final String enunciado;
  final Color primary;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    if (!_lacunaRegex.hasMatch(enunciado)) {
      return Text(
        enunciado,
        style: GoogleFonts.roboto(
          fontSize: 17,
          height: 1.5,
          fontWeight: FontWeight.w500,
          color: primary,
        ),
      );
    }

    final spans = <InlineSpan>[];
    var start = 0;
    for (final m in _lacunaRegex.allMatches(enunciado)) {
      if (m.start > start) {
        spans.add(
          TextSpan(
            text: enunciado.substring(start, m.start),
            style: GoogleFonts.roboto(
              fontSize: 17,
              height: 1.5,
              fontWeight: FontWeight.w500,
              color: primary,
            ),
          ),
        );
      }
      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.baseline,
          baseline: TextBaseline.alphabetic,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: accent, width: 1.5),
            ),
            child: Text(
              '···',
              style: GoogleFonts.roboto(
                fontWeight: FontWeight.w800,
                color: primary,
                letterSpacing: 2,
              ),
            ),
          ),
        ),
      );
      start = m.end;
    }
    if (start < enunciado.length) {
      spans.add(
        TextSpan(
          text: enunciado.substring(start),
          style: GoogleFonts.roboto(
            fontSize: 17,
            height: 1.5,
            fontWeight: FontWeight.w500,
            color: primary,
          ),
        ),
      );
    }

    return RichText(text: TextSpan(children: spans));
  }
}

class _BotoesCertoErrado extends StatelessWidget {
  const _BotoesCertoErrado({
    required this.bloqueado,
    required this.primary,
    required this.onTap,
  });

  final bool bloqueado;
  final Color primary;
  final void Function(String) onTap;

  @override
  Widget build(BuildContext context) {
    Widget cebraspeButton({required String label, required bool filled}) {
      return SizedBox(
        width: double.infinity,
        height: 64,
        child: filled
            ? FilledButton(
                onPressed: bloqueado ? null : () => onTap(label),
                style: FilledButton.styleFrom(
                  backgroundColor: MiraCores.destaque,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: MiraCores.destaque.withValues(
                    alpha: 0.4,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  label,
                  style: GoogleFonts.roboto(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              )
            : OutlinedButton(
                onPressed: bloqueado ? null : () => onTap(label),
                style: OutlinedButton.styleFrom(
                  foregroundColor: MiraCores.texto,
                  backgroundColor: MiraCores.botao,
                  side: const BorderSide(
                    color: MiraCores.botaoBorda,
                    width: 2.5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  label,
                  style: GoogleFonts.roboto(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        cebraspeButton(label: 'CERTO', filled: true),
        const SizedBox(height: 14),
        cebraspeButton(label: 'ERRADO', filled: false),
      ],
    );
  }
}

class _OpcoesCloze extends StatelessWidget {
  const _OpcoesCloze({
    required this.opcoes,
    required this.bloqueado,
    required this.primary,
    required this.accent,
    required this.onTap,
  });

  final List<String> opcoes;
  final bool bloqueado;
  final Color primary;
  final Color accent;
  final void Function(String) onTap;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: WrapAlignment.start,
      children: opcoes.map((op) {
        return OutlinedButton(
          onPressed: bloqueado ? null : () => onTap(op),
          style: OutlinedButton.styleFrom(
            foregroundColor: MiraCores.texto,
            side: const BorderSide(color: MiraCores.botaoBorda, width: 2),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            backgroundColor: MiraCores.botao,
          ),
          child: Text(
            op,
            style: GoogleFonts.roboto(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _FallbackTipo extends StatelessWidget {
  const _FallbackTipo({
    required this.questao,
    required this.bloqueado,
    required this.primary,
    required this.accent,
    required this.onTap,
  });

  final QuestaoModel questao;
  final bool bloqueado;
  final Color primary;
  final Color accent;
  final void Function(String) onTap;

  @override
  Widget build(BuildContext context) {
    final opts = questao.opcoes;
    if (opts.isEmpty) {
      return Text(
        'Questão sem opções configuradas.',
        style: GoogleFonts.roboto(color: primary.withValues(alpha: 0.7)),
      );
    }
    return _OpcoesCloze(
      opcoes: opts,
      bloqueado: bloqueado,
      primary: primary,
      accent: accent,
      onTap: onTap,
    );
  }
}

class _MissaoCumpridaView extends StatelessWidget {
  const _MissaoCumpridaView({
    required this.xpTotal,
    required this.primary,
    required this.accent,
    required this.onVoltar,
  });

  final int xpTotal;
  final Color primary;
  final Color accent;
  final VoidCallback onVoltar;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.emoji_events_rounded, size: 88, color: accent),
            const SizedBox(height: 24),
            Text(
              'Missão cumprida!',
              textAlign: TextAlign.center,
              style: GoogleFonts.roboto(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: primary,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: accent, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: primary.withValues(alpha: 0.1),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    'XP ganho nesta lição',
                    style: GoogleFonts.roboto(
                      fontSize: 14,
                      color: primary.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '+$xpTotal XP',
                    style: GoogleFonts.roboto(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      color: accent,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onVoltar,
                style: FilledButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Voltar para a Home',
                  style: GoogleFonts.roboto(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
