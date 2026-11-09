import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/api_service.dart';
import '../services/session_store.dart';

/// Tela de entrada: alterna entre login e criação de conta.
class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.api,
    required this.onAutenticado,
  });

  final ApiService api;
  final Future<void> Function(Sessao sessao) onAutenticado;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _senha = TextEditingController();
  bool _criarConta = false;
  bool _carregando = false;
  bool _ocultarSenha = true;
  String? _erro;

  @override
  void dispose() {
    _email.dispose();
    _senha.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final email = _email.text.trim();
      final sessao = _criarConta
          ? await widget.api.registrar(email, _senha.text)
          : await widget.api.login(email, _senha.text);
      await widget.onAutenticado(sessao);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _erro = e.toString().replaceFirst('Exception: ', '');
        _carregando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'MIRAQuest',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.roboto(
                        fontSize: 34,
                        fontWeight: FontWeight.w700,
                        color: primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _criarConta ? 'Crie sua conta' : 'Entre para continuar',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.roboto(fontSize: 16),
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      decoration: const InputDecoration(
                        labelText: 'E-mail',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) {
                        final t = v?.trim() ?? '';
                        return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(t)
                            ? null
                            : 'Informe um e-mail válido';
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _senha,
                      obscureText: _ocultarSenha,
                      autofillHints: [
                        _criarConta
                            ? AutofillHints.newPassword
                            : AutofillHints.password,
                      ],
                      onFieldSubmitted: (_) => _carregando ? null : _enviar(),
                      decoration: InputDecoration(
                        labelText: 'Senha',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _ocultarSenha
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () =>
                              setState(() => _ocultarSenha = !_ocultarSenha),
                        ),
                      ),
                      validator: (v) {
                        final t = v ?? '';
                        if (t.isEmpty) return 'Informe a senha';
                        if (_criarConta && (t.length < 8 || t.length > 72)) {
                          return 'A senha deve ter de 8 a 72 caracteres';
                        }
                        return null;
                      },
                    ),
                    if (_erro != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        _erro!,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    ],
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _carregando ? null : _enviar,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _carregando
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(_criarConta ? 'Criar conta' : 'Entrar'),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _carregando
                          ? null
                          : () => setState(() {
                              _criarConta = !_criarConta;
                              _erro = null;
                            }),
                      child: Text(
                        _criarConta
                            ? 'Já tenho conta'
                            : 'Não tenho conta — criar agora',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
