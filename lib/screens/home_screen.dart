import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';

import '../models/materia_model.dart';
import '../models/usuario_model.dart';
import '../services/api_service.dart';
import '../theme/mira_tema.dart';
import 'licao_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    this.apiService,
    this.usuarioId = 1,
    this.onLogout,
  });

  final ApiService? apiService;
  final int usuarioId;

  /// Quando informado, exibe o botão de sair e é chamado se a sessão expirar.
  final Future<void> Function()? onLogout;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final ApiService _api = widget.apiService ?? ApiService();
  late final Future<UsuarioModel> _usuarioFuture = _api.getUsuarioProgresso(
    widget.usuarioId,
  );
  late final Future<List<MateriaModel>> _materiasFuture = _api.getMaterias();

  /// Progresso visual do XP em ciclo de 1000 pontos (ajustável quando houver nível na API).
  static double _xpPercent(int xpTotal) {
    const meta = 1000;
    final resto = xpTotal % meta;
    return (resto / meta).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: MiraEstilo.fundoCeu,
        child: SizedBox.expand(
          child: SafeArea(
            child: Column(
              children: [
                if (widget.onLogout != null)
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      tooltip: 'Sair',
                      icon: const Icon(Icons.logout),
                      onPressed: widget.onLogout,
                    ),
                  ),
                Expanded(child: _conteudo(context)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _conteudo(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return FutureBuilder<UsuarioModel>(
      future: _usuarioFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          if (snapshot.error is NaoAutorizadoException &&
              widget.onLogout != null) {
            // Sessão expirada: volta para o login.
            WidgetsBinding.instance.addPostFrameCallback(
              (_) => widget.onLogout!(),
            );
          }
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.cloud_off, size: 48, color: MiraCores.texto),
                  const SizedBox(height: 16),
                  Text(
                    'Não foi possível carregar seu progresso.',
                    textAlign: TextAlign.center,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: textTheme.bodySmall?.copyWith(
                      color: MiraCores.texto.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final usuario = snapshot.data!;
        final xpPct = _xpPercent(usuario.xpTotal);

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: _HeaderStats(
                  vidas: usuario.vidas,
                  streakDias: usuario.streakDias,
                  xpTotal: usuario.xpTotal,
                  xpPercent: xpPct,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                child: Text(
                  'ESCOLHA UMA MATÉRIA',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),
            FutureBuilder<List<MateriaModel>>(
              future: _materiasFuture,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  );
                }
                if (snap.hasError) {
                  if (snap.error is NaoAutorizadoException &&
                      widget.onLogout != null) {
                    WidgetsBinding.instance.addPostFrameCallback(
                      (_) => widget.onLogout!(),
                    );
                  }
                  return const SliverToBoxAdapter(
                    child: _AvisoMaterias(
                      icone: Icons.cloud_off,
                      texto: 'Não foi possível carregar as matérias.',
                    ),
                  );
                }
                final materias = snap.data ?? const <MateriaModel>[];
                if (materias.isEmpty) {
                  return const SliverToBoxAdapter(
                    child: _AvisoMaterias(
                      icone: Icons.inbox_outlined,
                      texto: 'Nenhuma matéria disponível ainda.',
                    ),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                  sliver: SliverList.separated(
                    itemCount: materias.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final m = materias[i];
                      return _MateriaCard(
                        titulo: m.nome.toUpperCase(),
                        subtitulo: m.totalQuestoes == 1
                            ? '1 questão'
                            : '${m.totalQuestoes} questões',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (context) => LicaoScreen(
                                materia: m.nome,
                                usuarioId: usuario.id,
                                vidasInicial: usuario.vidas,
                                apiService: _api,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

/// Vidas, sequência de dias e XP, num card sobre o degradê.
class _HeaderStats extends StatelessWidget {
  const _HeaderStats({
    required this.vidas,
    required this.streakDias,
    required this.xpTotal,
    required this.xpPercent,
  });

  final int vidas;
  final int streakDias;
  final int xpTotal;
  final double xpPercent;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: MiraEstilo.card,
      child: Row(
        children: [
          Expanded(
            child: _StatChip(
              icon: Icons.favorite_rounded,
              iconColor: MiraCores.vidas,
              label: '$vidas',
              subtitle: 'Vidas',
            ),
          ),
          Expanded(
            child: _StatChip(
              icon: Icons.local_fire_department_rounded,
              iconColor: MiraCores.sequencia,
              label: '$streakDias',
              subtitle: 'Streak',
            ),
          ),
          CircularPercentIndicator(
            radius: 44,
            lineWidth: 6,
            percent: xpPercent,
            center: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'XP',
                  style: textTheme.labelSmall?.copyWith(
                    color: MiraCores.xp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '$xpTotal',
                  style: textTheme.titleMedium?.copyWith(
                    color: MiraCores.xp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            progressColor: MiraCores.xp,
            backgroundColor: MiraCores.botaoBorda,
            circularStrokeCap: CircularStrokeCap.round,
            animation: true,
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.subtitle,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 26),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: iconColor,
              ),
            ),
            Text(
              subtitle,
              style: textTheme.bodySmall?.copyWith(
                color: MiraCores.texto.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MateriaCard extends StatelessWidget {
  const _MateriaCard({
    required this.titulo,
    required this.subtitulo,
    required this.onTap,
  });

  final String titulo;
  final String subtitulo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: MiraEstilo.card,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: MiraCores.destaque.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.menu_book_rounded,
                    size: 32,
                    color: MiraCores.destaque,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titulo,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitulo,
                        style: textTheme.bodyMedium?.copyWith(
                          color: MiraCores.texto.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: MiraCores.texto.withValues(alpha: 0.6),
                  size: 28,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AvisoMaterias extends StatelessWidget {
  const _AvisoMaterias({required this.icone, required this.texto});

  final IconData icone;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(icone, size: 40, color: MiraCores.texto),
          const SizedBox(height: 12),
          Text(
            texto,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}
