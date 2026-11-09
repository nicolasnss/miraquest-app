import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/questao_model.dart';
import '../services/api_service.dart';
import '../theme/mira_tema.dart';

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

/// Resposta já verificada pela API para a questão atual.
class _Resultado {
  const _Resultado({
    required this.resposta,
    required this.sucesso,
    required this.explicacao,
    this.pegadinha,
  });

  final String resposta;
  final bool sucesso;
  final String explicacao;
  final String? pegadinha;
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

  /// Resultado da questão atual; `null` enquanto o usuário não respondeu.
  _Resultado? _resultado;

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
  }) async {
    if (_enviando || _resultado != null) return;
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
      } else {
        HapticFeedback.heavyImpact();
        setState(() {
          _vidas = (_vidas - 1).clamp(0, 999);
        });
      }

      setState(() {
        _resultado = _Resultado(
          resposta: resposta,
          sucesso: resultado.sucesso,
          explicacao: resultado.explicacao,
          pegadinha: resultado.pegadinha,
        );
        _enviando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _enviando = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro: $e')));
    }
  }

  Future<void> _continuar(int totalQuestoes) async {
    final ultima = _indiceAtual >= totalQuestoes - 1;
    if (ultima) {
      setState(() {
        _missaoConcluida = true;
        _resultado = null;
      });
      return;
    }
    setState(() {
      _resultado = null;
      _enviando = true;
    });
    await _pageController.nextPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
    if (mounted) setState(() => _enviando = false);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(title: Text('Lição: ${widget.materia}')),
      body: DecoratedBox(
        decoration: MiraEstilo.fundoCeu,
        child: SizedBox.expand(
          child: SafeArea(
            child: FutureBuilder<List<QuestaoModel>>(
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
                        style: MiraEstilo.feedbackErro,
                      ),
                    ),
                  );
                }

                final todas = snapshot.data ?? [];
                if (todas.isEmpty) {
                  return Center(
                    child: Text(
                      'Nenhuma questão disponível para esta matéria.',
                      style: textTheme.titleMedium,
                    ),
                  );
                }

                final questoes = todas.length > _kQuestoesPorLicao
                    ? todas.sublist(0, _kQuestoesPorLicao)
                    : todas;

                if (_missaoConcluida) {
                  return _MissaoCumpridaView(
                    xpTotal: _xpSessao,
                    onVoltar: () => Navigator.of(context).pop(),
                  );
                }

                return Column(
                  children: [
                    _BarraProgressoELives(
                      indice: _indiceAtual,
                      total: questoes.length,
                      vidas: _vidas,
                    ),
                    Expanded(
                      child: PageView.builder(
                        controller: _pageController,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: questoes.length,
                        onPageChanged: (i) => setState(() => _indiceAtual = i),
                        itemBuilder: (context, index) {
                          final q = questoes[index];
                          final atual = index == _indiceAtual;
                          return SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                            child: _CardQuestao(
                              questao: q,
                              resultado: atual ? _resultado : null,
                              bloqueado: _enviando,
                              isCertoErrado: _isCertoErrado(q),
                              isCloze: _isCloze(q),
                              onResponder: (texto) => _processarResposta(
                                questao: q,
                                resposta: texto,
                              ),
                              onContinuar: () => _continuar(questoes.length),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _BarraProgressoELives extends StatelessWidget {
  const _BarraProgressoELives({
    required this.indice,
    required this.total,
    required this.vidas,
  });

  final int indice;
  final int total;
  final int vidas;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final progresso = total == 0 ? 0.0 : (indice + 1) / total;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 56, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.favorite_rounded, color: MiraCores.vidas),
              const SizedBox(width: 6),
              Text(
                '$vidas',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Text(
                '${indice + 1}/$total',
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
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
              backgroundColor: MiraCores.card.withValues(alpha: 0.6),
              color: MiraCores.xp,
            ),
          ),
        ],
      ),
    );
  }
}

/// Card central: matéria, pergunta, opções, feedback e explicação.
class _CardQuestao extends StatelessWidget {
  const _CardQuestao({
    required this.questao,
    required this.resultado,
    required this.bloqueado,
    required this.isCertoErrado,
    required this.isCloze,
    required this.onResponder,
    required this.onContinuar,
  });

  final QuestaoModel questao;
  final _Resultado? resultado;
  final bool bloqueado;
  final bool isCertoErrado;
  final bool isCloze;
  final void Function(String resposta) onResponder;
  final VoidCallback onContinuar;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final opcoes = isCertoErrado ? const ['CERTO', 'ERRADO'] : questao.opcoes;

    if (isCloze && opcoes.isEmpty) {
      debugPrint(
        '[MIRAQuest Cloze] Lista de opções vazia — '
        'questaoId=${questao.id} tipo=${questao.tipo} '
        'opcoes=${questao.opcoes}',
      );
    }

    final r = resultado;
    final acertou = r?.sucesso == true;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Container(
          decoration: MiraEstilo.card,
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 15, 10, 10),
                child: Column(
                  children: [
                    Text(
                      questao.materia.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: MiraEstilo.materia,
                    ),
                    if (questao.banca != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Banca ${questao.banca}',
                        textAlign: TextAlign.center,
                        style: textTheme.bodySmall?.copyWith(
                          color: MiraCores.textoSuave,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                decoration: MiraEstilo.faixaPergunta,
                constraints: const BoxConstraints(minHeight: 80),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 25,
                ),
                alignment: Alignment.center,
                child: isCloze
                    ? _TextoCloze(
                        enunciado: questao.enunciado,
                        revelada: acertou ? r!.resposta : null,
                      )
                    : Text(
                        questao.enunciado,
                        textAlign: TextAlign.center,
                        style: MiraEstilo.pergunta,
                      ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 15, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (opcoes.isEmpty)
                      Text(
                        'Questão sem opções configuradas.',
                        textAlign: TextAlign.center,
                        style: textTheme.bodyMedium,
                      )
                    else
                      _GradeOpcoes(
                        opcoes: opcoes,
                        resultado: r,
                        bloqueado: bloqueado || r != null,
                        onTap: onResponder,
                      ),
                    const SizedBox(height: 15),
                    SizedBox(
                      height: 22,
                      child: r == null
                          ? null
                          : Text(
                              acertou
                                  ? 'Excelente!'
                                  : 'Humm, não foi dessa vez...',
                              textAlign: TextAlign.center,
                              style: acertou
                                  ? MiraEstilo.feedbackAcerto
                                  : MiraEstilo.feedbackErro,
                            ),
                    ),
                    if (r != null && r.explicacao.isNotEmpty) ...[
                      const SizedBox(height: 15),
                      _CaixaTexto(
                        rotulo: 'EXPLICAÇÃO TÉCNICA',
                        texto: r.explicacao,
                      ),
                    ],
                    if (r?.pegadinha != null) ...[
                      const SizedBox(height: 12),
                      _CaixaTexto(rotulo: 'PEGADINHA', texto: r!.pegadinha!),
                    ],
                    if (r != null) ...[
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: onContinuar,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('CONTINUAR'),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Enunciado com a lacuna destacada; após acertar, mostra a resposta no lugar.
class _TextoCloze extends StatelessWidget {
  const _TextoCloze({required this.enunciado, required this.revelada});

  final String enunciado;
  final String? revelada;

  @override
  Widget build(BuildContext context) {
    final base = revelada != null
        ? MiraEstilo.pergunta.copyWith(color: MiraCores.acerto)
        : MiraEstilo.pergunta;

    if (!_lacunaRegex.hasMatch(enunciado)) {
      return Text(enunciado, textAlign: TextAlign.center, style: base);
    }

    final lacuna = revelada != null
        ? MiraEstilo.lacuna.copyWith(decoration: TextDecoration.none)
        : MiraEstilo.lacuna;

    final spans = <InlineSpan>[];
    var start = 0;
    for (final m in _lacunaRegex.allMatches(enunciado)) {
      if (m.start > start) {
        spans.add(TextSpan(text: enunciado.substring(start, m.start)));
      }
      spans.add(TextSpan(text: revelada ?? '[...]', style: lacuna));
      start = m.end;
    }
    if (start < enunciado.length) {
      spans.add(TextSpan(text: enunciado.substring(start)));
    }

    return Text.rich(
      TextSpan(style: base, children: spans),
      textAlign: TextAlign.center,
    );
  }
}

/// Opções em grade de 2 colunas.
class _GradeOpcoes extends StatelessWidget {
  const _GradeOpcoes({
    required this.opcoes,
    required this.resultado,
    required this.bloqueado,
    required this.onTap,
  });

  final List<String> opcoes;
  final _Resultado? resultado;
  final bool bloqueado;
  final void Function(String) onTap;

  EstadoOpcao _estado(String opcao) {
    final r = resultado;
    if (r == null || r.resposta != opcao) return EstadoOpcao.normal;
    return r.sucesso ? EstadoOpcao.correta : EstadoOpcao.errada;
  }

  @override
  Widget build(BuildContext context) {
    final linhas = <Widget>[];
    for (var i = 0; i < opcoes.length; i += 2) {
      final a = opcoes[i];
      final b = i + 1 < opcoes.length ? opcoes[i + 1] : null;
      linhas.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _BotaoOpcao(
                  rotulo: a,
                  estado: _estado(a),
                  onTap: bloqueado ? null : () => onTap(a),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: b == null
                    ? const SizedBox.shrink()
                    : _BotaoOpcao(
                        rotulo: b,
                        estado: _estado(b),
                        onTap: bloqueado ? null : () => onTap(b),
                      ),
              ),
            ],
          ),
        ),
      );
      if (i + 2 < opcoes.length) linhas.add(const SizedBox(height: 10));
    }
    return Column(children: linhas);
  }
}

class _BotaoOpcao extends StatelessWidget {
  const _BotaoOpcao({
    required this.rotulo,
    required this.estado,
    required this.onTap,
  });

  final String rotulo;
  final EstadoOpcao estado;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: MiraEstilo.botaoOpcao(estado),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
            child: Center(
              child: Text(
                rotulo,
                textAlign: TextAlign.center,
                style: MiraEstilo.opcao.copyWith(
                  color: MiraEstilo.textoOpcao(estado),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Caixa com faixa laranja à esquerda (explicação técnica / pegadinha).
class _CaixaTexto extends StatelessWidget {
  const _CaixaTexto({required this.rotulo, required this.texto});

  final String rotulo;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: MiraEstilo.explicacao,
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(
              width: MiraEstilo.larguraFaixaExplicacao,
              child: ColoredBox(color: MiraEstilo.faixaExplicacao),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(rotulo, style: MiraEstilo.rotuloExplicacao),
                    const SizedBox(height: 12),
                    Text(texto, style: MiraEstilo.textoExplicacao),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MissaoCumpridaView extends StatelessWidget {
  const _MissaoCumpridaView({required this.xpTotal, required this.onVoltar});

  final int xpTotal;
  final VoidCallback onVoltar;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.emoji_events_rounded,
                size: 88,
                color: MiraCores.xp,
              ),
              const SizedBox(height: 24),
              Text(
                'Missão cumprida!',
                textAlign: TextAlign.center,
                style: textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 18,
                ),
                decoration: MiraEstilo.card,
                child: Column(
                  children: [
                    Text(
                      'XP ganho nesta lição',
                      style: textTheme.bodyMedium?.copyWith(
                        color: MiraCores.texto.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '+$xpTotal XP',
                      style: textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: MiraCores.xp,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onVoltar,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Voltar para a Home'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
