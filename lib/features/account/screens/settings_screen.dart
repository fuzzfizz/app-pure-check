import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../core/providers/gemini_api_key_provider.dart';
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

  void _showApiKeyDialog(BuildContext context, WidgetRef ref, String? currentKey) {
    final controller = TextEditingController(text: currentKey ?? '');
    final isTh = ref.read(localeProvider).languageCode == 'th';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isTh ? 'ตั้งค่า Gemini API Key' : 'Gemini API Key Settings'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isTh
                    ? 'ใส่ API Key ส่วนตัวของคุณเพื่อใช้ในการวิเคราะห์ด้วย AI (สร้างฟรีได้ที่ Google AI Studio)'
                    : 'Enter your custom API Key for AI analysis (Get it free at Google AI Studio).',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: 'Gemini API Key',
                  hintText: 'AIzaSy... หรือ AQ...',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear_rounded),
                    onPressed: () => controller.clear(),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(isTh ? 'ยกเลิก' : 'Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newKey = controller.text.trim();
                await ref.read(geminiApiKeyProvider.notifier).setKey(newKey.isEmpty ? null : newKey);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isTh
                            ? (newKey.isEmpty ? 'รีเซ็ตเป็นคีย์ระบบเรียบร้อย' : 'บันทึก API Key สำเร็จ')
                            : (newKey.isEmpty ? 'Reset to system key' : 'API Key saved successfully'),
                      ),
                    ),
                  );
                }
              },
              child: Text(isTh ? 'บันทึก' : 'Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final apiKey = ref.watch(geminiApiKeyProvider);
    final isTh = ref.watch(localeProvider).languageCode == 'th';

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

          // API Key section
          _buildSectionHeader(isTh ? 'ตั้งค่า API Key (เสริม)' : 'API Key Settings (Optional)'),
          SwitchListTile(
            title: Text(isTh ? 'ใช้ Gemini API Key ส่วนตัว' : 'Use Custom Gemini API Key'),
            subtitle: Text(
              isTh
                  ? 'ปิดเพื่อใช้คีย์ของระบบเป็นค่าเริ่มต้น'
                  : 'Toggle to use your own API Key instead of the default',
            ),
            value: ref.watch(useCustomGeminiKeyProvider),
            activeThumbColor: AppColors.primary,
            onChanged: (val) async {
              await ref.read(useCustomGeminiKeyProvider.notifier).setUseCustomKey(val);
              if (val && (apiKey == null || apiKey.trim().isEmpty)) {
                if (context.mounted) {
                  _showApiKeyDialog(context, ref, apiKey);
                }
              }
            },
          ),
          ListTile(
            enabled: ref.watch(useCustomGeminiKeyProvider),
            leading: const Icon(Icons.vpn_key_rounded, color: AppColors.primary),
            title: Text(isTh ? 'กรอก Gemini API Key' : 'Enter Gemini API Key'),
            subtitle: Text(
              apiKey != null && apiKey.isNotEmpty
                  ? (isTh
                      ? 'คีย์ส่วนตัว: ${apiKey.substring(0, 4)}...${apiKey.substring(apiKey.length - 4)}'
                      : 'Custom Key: ${apiKey.substring(0, 4)}...${apiKey.substring(apiKey.length - 4)}')
                  : (isTh ? 'ยังไม่ได้ตั้งค่าคีย์' : 'No key set'),
            ),
            trailing: const Icon(Icons.edit_rounded, size: 20),
            onTap: ref.watch(useCustomGeminiKeyProvider)
                ? () => _showApiKeyDialog(context, ref, apiKey)
                : null,
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
