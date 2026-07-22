import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../core/theme/app_theme.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    try {
      await Supabase.instance.client.auth.signOut();
      if (context.mounted) {
        context.go('/login');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ออกจากระบบล้มเหลว: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('การตั้งค่า'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Language section
          _buildSectionHeader('ภาษา (Language)'),
          ListTile(
            leading: const Icon(Icons.language_rounded, color: AppColors.primary),
            title: const Text('ภาษาแสดงผล'),
            trailing: DropdownButton<String>(
              value: ref.watch(localeProvider).languageCode,
              underline: const SizedBox(),
              onChanged: (val) {
                if (val != null) {
                  ref.read(localeProvider.notifier).setLocale(val);
                }
              },
              items: const [
                DropdownMenuItem(value: 'th', child: Text('ภาษาไทย')),
                DropdownMenuItem(value: 'en', child: Text('English')),
              ],
            ),
          ),
          const Divider(),

          // Help / Support
          _buildSectionHeader('ความช่วยเหลือ'),
          ListTile(
            leading: const Icon(Icons.info_outline_rounded, color: AppColors.primary),
            title: const Text('เกี่ยวกับ PureCheck'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'PureCheck',
                applicationVersion: '1.0.0',
                applicationIcon: const Icon(Icons.spa, color: AppColors.primary, size: 40),
                children: const [
                  Text('แอปวิเคราะห์ความปลอดภัยของส่วนผสมในสกินแคร์และเครื่องสำอาง เพื่อความปลอดภัยเฉพาะสภาพผิวของคุณด้วยพลัง AI'),
                ],
              );
            },
          ),
          const Divider(),

          // Logout Action
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => _logout(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: AppColors.white,
            ),
            child: const Text('ออกจากระบบ (Sign Out)'),
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
