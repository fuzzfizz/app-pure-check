import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../core/theme/app_theme.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _logout(BuildContext context, AppLocalizations l10n) async {
    try {
      await Supabase.instance.client.auth.signOut();
      if (context.mounted) {
        context.go('/login');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.signOutFailed(e.toString()))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Language section
          _buildSectionHeader(l10n.language),
          ListTile(
            leading: const Icon(Icons.language_rounded, color: AppColors.primary),
            title: Text(l10n.displayLanguage),
            trailing: DropdownButton<String>(
              value: ref.watch(localeProvider).languageCode,
              underline: const SizedBox(),
              onChanged: (val) {
                if (val != null) {
                  ref.read(localeProvider.notifier).setLocale(val);
                }
              },
              items: const [
                DropdownMenuItem(value: 'th', child: Text('ภาษาไทย (Thai)')),
                DropdownMenuItem(value: 'en', child: Text('English')),
              ],
            ),
          ),
          const Divider(),

          // Help / Support
          _buildSectionHeader(l10n.helpAndSupport),
          ListTile(
            leading: const Icon(Icons.info_outline_rounded, color: AppColors.primary),
            title: Text(l10n.aboutPureCheck),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'PureCheck',
                applicationVersion: '1.0.0',
                applicationIcon: const Icon(Icons.spa, color: AppColors.primary, size: 40),
                children: [
                  Text(l10n.aboutDescription),
                ],
              );
            },
          ),
          const Divider(),

          // Logout Action
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => _logout(context, l10n),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: AppColors.white,
            ),
            child: Text(l10n.signOut),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}
