import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/models/user_api_key.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../core/providers/user_api_keys_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../widgets/api_key_manager_dialog.dart';

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

  void _showAddApiKeyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AddApiKeyDialog(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isTh = ref.watch(localeProvider).languageCode == 'th';
    final profileAsync = ref.watch(currentProfileProvider);
    final profile = profileAsync.asData?.value;
    final isAdmin = profile?.isAdmin ?? false;

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

          // Custom AI API Keys Section (Max 3 keys with Auto-detection & Quota testing)
          _buildSectionHeader(isTh ? 'จัดการ AI API Key ส่วนตัว (สูงสุด 3 คีย์)' : 'Custom AI API Keys (Max 3)'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              isTh
                  ? 'คุณสามารถเพิ่มคีย์ของคุณเองได้สูงสุด 3 คีย์ ระบบจะตรวจจับค่ายและโควต้าให้อัตโนมัติ (หากคีย์หมดโควต้า ระบบจะสลับไปใช้คีย์กลางของระบบให้อัตโนมัติ)'
                  : 'Add up to 3 custom API keys. The app auto-detects the provider and checks quota limits (falls back to system pool if exhausted).',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(height: 12),
          _buildUserKeysList(context, ref, isTh),
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

          if (isAdmin) ...[
            _buildSectionHeader(isTh ? 'การจัดการระบบ (Admin Tools)' : 'Admin Tools'),
            ListTile(
              leading: const Icon(Icons.admin_panel_settings_outlined, color: AppColors.primary),
              title: const Text('Admin Product Review'),
              subtitle: Text(
                isTh
                    ? 'ตรวจสอบและอนุมัติสินค้าที่ผู้ใช้ส่งเข้ามา'
                    : 'Review & approve user-submitted products',
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 14),
              onTap: () => context.push('/admin/review'),
            ),
            const Divider(),
          ],

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

  Widget _buildUserKeysList(BuildContext context, WidgetRef ref, bool isTh) {
    final userKeys = ref.watch(userApiKeysProvider);
    final notifier = ref.read(userApiKeysProvider.notifier);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.textSecondary.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.key_rounded, color: AppColors.primary, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      isTh ? 'คีย์ที่บันทึกไว้' : 'Saved Keys',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: userKeys.length >= 3
                        ? AppColors.danger.withValues(alpha: 0.1)
                        : AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${userKeys.length} / 3',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: userKeys.length >= 3 ? AppColors.danger : AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (userKeys.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  isTh
                      ? 'ยังไม่มีคีย์ส่วนตัว (ระบบจะใช้ AI Pool กลางของแอปในการวิเคราะห์)'
                      : 'No custom keys added (App will use system AI pool automatically).',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontStyle: FontStyle.italic),
                  textAlign: TextAlign.center,
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: userKeys.length,
                separatorBuilder: (_, __) => const Divider(height: 16),
                itemBuilder: (context, index) {
                  final keyItem = userKeys[index];
                  return Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  keyItem.providerName,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                const SizedBox(width: 6),
                                _buildStatusChip(keyItem.status, isTh),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${keyItem.maskedKey} (${keyItem.defaultModel})',
                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            ),
                            if (keyItem.statusMessage != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                keyItem.statusMessage!,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: keyItem.status == KeyStatus.valid
                                      ? AppColors.safe
                                      : (keyItem.status == KeyStatus.quotaExceeded
                                          ? Colors.amber.shade800
                                          : AppColors.danger),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        tooltip: isTh ? 'ทดสอบโควต้าอีกครั้ง' : 'Recheck Quota',
                        onPressed: () => notifier.recheckKey(keyItem.id),
                      ),
                      Switch(
                        value: keyItem.isEnabled,
                        activeThumbColor: AppColors.primary,
                        onChanged: (val) => notifier.toggleKey(keyItem.id, val),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.danger),
                        tooltip: isTh ? 'ลบคีย์' : 'Delete',
                        onPressed: () => notifier.removeKey(keyItem.id),
                      ),
                    ],
                  );
                },
              ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(
                userKeys.length >= 3
                    ? (isTh ? 'บันทึกครบ 3 คีย์แล้ว' : 'Max 3 Keys Reached')
                    : (isTh ? 'เพิ่ม AI API Key' : 'Add AI API Key'),
              ),
              onPressed: userKeys.length >= 3 ? null : () => _showAddApiKeyDialog(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(KeyStatus status, bool isTh) {
    Color color;
    String text;
    switch (status) {
      case KeyStatus.valid:
        color = AppColors.safe;
        text = isTh ? 'พร้อมใช้' : 'Ready';
        break;
      case KeyStatus.quotaExceeded:
        color = Colors.amber.shade700;
        text = isTh ? 'โควต้าเต็ม' : 'Limit';
        break;
      case KeyStatus.invalid:
        color = AppColors.danger;
        text = isTh ? 'ไม่ถูกต้อง' : 'Invalid';
        break;
      default:
        color = AppColors.textSecondary;
        text = isTh ? 'รอตรวจ' : 'Pending';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold),
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
