import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/models/user_profile.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/password_validator.dart';
import '../providers/auth_provider.dart';
import '../widgets/password_requirements_view.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});
  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _register(AppLocalizations l10n) async {
    if (_usernameCtrl.text.trim().isEmpty || !PasswordValidator.isUsernameValid(_usernameCtrl.text)) {
      setState(() => _error = l10n.invalidUsername);
      return;
    }
    if (_emailCtrl.text.trim().isEmpty) {
      setState(() => _error = l10n.pleaseEnterEmail);
      return;
    }
    if (_passCtrl.text.isEmpty) {
      setState(() => _error = l10n.pleaseEnterPassword);
      return;
    }
    if (!PasswordValidator.isPasswordValid(_passCtrl.text)) {
      setState(() => _error = l10n.invalidPasswordRequirements);
      return;
    }
    if (_confirmCtrl.text.isEmpty) {
      setState(() => _error = l10n.pleaseConfirmPassword);
      return;
    }
    if (_passCtrl.text != _confirmCtrl.text) {
      setState(() => _error = l10n.passwordMismatch);
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final res = await Supabase.instance.client.auth.signUp(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
        data: {'username': _usernameCtrl.text.trim()},
      );
      if (mounted) {
        if (res.session == null && res.user != null) {
          setState(() {
            _error = l10n.localeName == 'th'
                ? 'สมัครสมาชิกสำเร็จ โปรดยืนยันอีเมลของคุณก่อนเข้าสู่ระบบ'
                : 'Registration successful! Please check your email to confirm.';
          });
        } else {
          final user = res.user ?? Supabase.instance.client.auth.currentUser;
          final username = _usernameCtrl.text.trim();
          ref.read(authNotifierProvider.notifier).setUserAndProfile(
            user,
            user != null ? UserProfile.empty(user.id, username: username) : null,
          );
          context.go('/onboarding');
        }
      }
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = l10n.registerFailed(e.toString()));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 48),
              Text(l10n.register, style: Theme.of(context).textTheme.displayLarge),
              const SizedBox(height: 8),
              Text(l10n.introSubtitle,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: 40),
              TextField(
                controller: _usernameCtrl,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: l10n.username,
                  hintText: l10n.usernameHint,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(labelText: l10n.email),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passCtrl,
                obscureText: true,
                textInputAction: TextInputAction.next,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(labelText: l10n.password),
              ),
              const SizedBox(height: 8),
              PasswordRequirementsView(password: _passCtrl.text),
              const SizedBox(height: 16),
              TextField(
                controller: _confirmCtrl,
                obscureText: true,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(labelText: l10n.confirmPassword),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: AppColors.danger)),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loading ? null : () => _register(l10n),
                child: _loading 
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                    : Text(l10n.register),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => context.go('/login'),
                child: Text('${l10n.alreadyHaveAccount} ${l10n.loginHere}'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
