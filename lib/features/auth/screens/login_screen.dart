import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _identifierCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  bool _obscurePassword = true;
  String? _error;

  Future<void> _login(AppLocalizations l10n) async {
    if (_identifierCtrl.text.trim().isEmpty) {
      setState(() => _error = l10n.enterEmailOrUsername);
      return;
    }
    if (_passCtrl.text.isEmpty) {
      setState(() => _error = l10n.pleaseEnterPassword);
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final identifier = _identifierCtrl.text.trim();
      String emailToUse = identifier;
      if (!identifier.contains('@')) {
        // It's a username, resolve email via SupabaseService
        final resolvedEmail = await SupabaseService().getEmailByUsername(identifier);
        if (resolvedEmail == null || resolvedEmail.isEmpty) {
          if (mounted) {
            setState(() {
              _error = l10n.userNotFound;
              _loading = false;
            });
          }
          return;
        }
        emailToUse = resolvedEmail;
      }

      await Supabase.instance.client.auth.signInWithPassword(
        email: emailToUse,
        password: _passCtrl.text,
      );
      if (mounted) {
        await ref.read(authNotifierProvider.notifier).refreshProfile();
        if (!mounted) return;
        final status = ref.read(authNotifierProvider).status;
        if (status == AuthStatus.needsOnboarding) {
          context.go('/onboarding');
        } else {
          context.go('/home');
        }
      }
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = l10n.loginFailed(e.toString()));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _identifierCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 48),
              Text(l10n.welcome, style: Theme.of(context).textTheme.displayLarge),
              const SizedBox(height: 8),
              Text(l10n.introSubtitle,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: 40),
              TextField(
                controller: _identifierCtrl,
                keyboardType: TextInputType.text,
                decoration: InputDecoration(
                  labelText: l10n.emailOrUsername,
                  hintText: l10n.usernameHint,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passCtrl,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: l10n.password,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: AppColors.danger)),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loading ? null : () => _login(l10n),
                child: _loading 
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                    : Text(l10n.login),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => context.go('/register'),
                child: Text('${l10n.noAccount} ${l10n.registerHere}'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
