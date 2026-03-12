import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isRegisterMode = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final success = _isRegisterMode
        ? await authProvider.register(
            username: _usernameController.text.trim(),
            email: _emailController.text.trim(),
            password: _passwordController.text,
          )
        : await authProvider.login(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );

    if (!mounted || success) {
      return;
    }

    final errorText =
        authProvider.errorMessage ??
        (_isRegisterMode
            ? 'Registrierung konnte nicht abgeschlossen werden.'
            : 'Login konnte nicht abgeschlossen werden.');
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(errorText)));
  }

  void _toggleMode() {
    setState(() {
      _isRegisterMode = !_isRegisterMode;
      _formKey.currentState?.reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colorScheme.primary.withValues(alpha: 0.22),
              theme.scaffoldBackgroundColor,
              colorScheme.secondary.withValues(alpha: 0.16),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  const SizedBox(height: 28),
                  Text(
                    'FlutterFlex',
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Premium Fitness Tracking fuer Training, Fortschritt und Fokus.',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Container(
                    height: 244,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(32),
                      gradient: LinearGradient(
                        colors: [colorScheme.primary, colorScheme.secondary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          top: -28,
                          right: -24,
                          child: CircleAvatar(
                            radius: 74,
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.12,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.16),
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: const Text(
                                  'Track. Lift. Recover.',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Melde dich an und starte dein naechstes Workout.',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isRegisterMode ? 'Account erstellen' : 'Login',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 20),
                            if (_isRegisterMode) ...[
                              TextFormField(
                                controller: _usernameController,
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                  labelText: 'Benutzername',
                                  prefixIcon: Icon(Icons.person_outline_rounded),
                                ),
                                validator: (value) {
                                  if (!_isRegisterMode) {
                                    return null;
                                  }
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Bitte Benutzernamen eingeben.';
                                  }
                                  if (value.trim().length < 3) {
                                    return 'Benutzername muss mindestens 3 Zeichen haben.';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                            ],
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: 'E-Mail',
                                prefixIcon: Icon(Icons.mail_outline_rounded),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Bitte E-Mail eingeben.';
                                }
                                if (!value.contains('@')) {
                                  return 'Bitte eine gueltige E-Mail eingeben.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: true,
                              textInputAction: _isRegisterMode
                                  ? TextInputAction.next
                                  : TextInputAction.done,
                              decoration: const InputDecoration(
                                labelText: 'Passwort',
                                prefixIcon: Icon(Icons.lock_outline_rounded),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Bitte Passwort eingeben.';
                                }
                                if (_isRegisterMode && value.length < 6) {
                                  return 'Passwort muss mindestens 6 Zeichen haben.';
                                }
                                return null;
                              },
                            ),
                            if (_isRegisterMode) ...[
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _confirmPasswordController,
                                obscureText: true,
                                textInputAction: TextInputAction.done,
                                decoration: const InputDecoration(
                                  labelText: 'Passwort wiederholen',
                                  prefixIcon: Icon(Icons.verified_user_outlined),
                                ),
                                validator: (value) {
                                  if (!_isRegisterMode) {
                                    return null;
                                  }
                                  if (value == null || value.isEmpty) {
                                    return 'Bitte Passwort bestaetigen.';
                                  }
                                  if (value != _passwordController.text) {
                                    return 'Passwoerter stimmen nicht ueberein.';
                                  }
                                  return null;
                                },
                                onFieldSubmitted: (_) {
                                  if (!authProvider.isLoading) {
                                    _submit();
                                  }
                                },
                              ),
                            ],
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: authProvider.isLoading
                                  ? null
                                  : _submit,
                              child: authProvider.isLoading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.4,
                                      ),
                                    )
                                  : Text(
                                      _isRegisterMode
                                          ? 'Account erstellen'
                                          : 'Login',
                                    ),
                            ),
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton(
                                onPressed: authProvider.isLoading
                                    ? null
                                    : _toggleMode,
                                child: Text(
                                  _isRegisterMode
                                      ? 'Ich habe schon einen Account'
                                      : 'Neuen Account erstellen',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
