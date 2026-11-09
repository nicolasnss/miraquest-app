import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'services/api_service.dart';
import 'services/session_store.dart';
import 'theme/mira_cores.dart';

void main() {
  runApp(const MiraQuestApp());
}

class MiraQuestApp extends StatelessWidget {
  const MiraQuestApp({super.key, this.store});

  final SessionStore? store;

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.light(
      primary: MiraCores.texto,
      onPrimary: Colors.white,
      secondary: MiraCores.destaque,
      onSecondary: Colors.white,
      surface: MiraCores.superficie,
      onSurface: MiraCores.texto,
      onSurfaceVariant: MiraCores.texto.withValues(alpha: 0.7),
      error: MiraCores.erro,
    );

    return MaterialApp(
      title: 'MIRAQuest',
      debugShowCheckedModeBanner: false,
      // Degradê "Pôr do sol" atrás de todas as telas (Scaffold transparente).
      builder: (context, child) => DecoratedBox(
        decoration: const BoxDecoration(gradient: MiraCores.fundo),
        child: child,
      ),
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: MiraCores.texto,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: Colors.transparent,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: MiraCores.texto,
          elevation: 0,
          scrolledUnderElevation: 0,
          titleTextStyle: GoogleFonts.roboto(
            color: MiraCores.texto,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        textTheme: GoogleFonts.robotoTextTheme().apply(
          bodyColor: MiraCores.texto,
          displayColor: MiraCores.texto,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: MiraCores.destaque,
          foregroundColor: Colors.white,
        ),
      ),
      home: AuthGate(store: store ?? SecureSessionStore()),
    );
  }
}

/// Decide entre login e home conforme a sessão guardada; trata logout/expiração.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key, required this.store, this.api});

  final SessionStore store;
  final ApiService? api;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final ApiService _api = widget.api ?? ApiService();
  late final Future<Sessao?> _inicial = widget.store.ler();
  Sessao? _sessao;
  bool _carregou = false;

  Future<void> _entrar(Sessao sessao) async {
    await widget.store.salvar(sessao);
    _api.token = sessao.token;
    if (mounted) setState(() => _sessao = sessao);
  }

  Future<void> _sair() async {
    await widget.store.limpar();
    _api.token = null;
    if (mounted) {
      setState(() {
        _sessao = null;
        _carregou = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_carregou) {
      return FutureBuilder<Sessao?>(
        future: _inicial,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          // Consome o resultado uma única vez.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted || _carregou) return;
            final s = snap.data;
            if (s != null) _api.token = s.token;
            setState(() {
              _sessao = s;
              _carregou = true;
            });
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        },
      );
    }

    final sessao = _sessao;
    if (sessao == null) {
      return LoginScreen(api: _api, onAutenticado: _entrar);
    }
    return HomeScreen(
      key: ValueKey(sessao.usuarioId),
      apiService: _api,
      usuarioId: sessao.usuarioId,
      onLogout: _sair,
    );
  }
}
