import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../core/providers/gemini_api_key_provider.dart';
import '../../../core/providers/deepseek_api_key_provider.dart';
import '../../../core/services/gemini_service.dart';
import '../../../core/services/deepseek_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';

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
    final geminiService = GeminiService();

    bool isValidating = false;
    String? validationMessage;
    bool? isSuccess;
    List<String>? availableModels;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(isTh ? 'ตั้งค่า Gemini API Key' : 'Gemini API Key Settings'),
              content: SingleChildScrollView(
                child: Column(
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
                    if (isValidating) ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isTh ? 'กำลังทดสอบคีย์...' : 'Testing key...',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ] else if (validationMessage != null) ...[
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            isSuccess == true
                                ? Icons.check_circle_outline_rounded
                                : Icons.error_outline_rounded,
                            color: isSuccess == true ? AppColors.safe : AppColors.danger,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              validationMessage!,
                              style: TextStyle(
                                fontSize: 12,
                                color: isSuccess == true ? AppColors.safe : AppColors.danger,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (availableModels != null && availableModels!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        isTh ? 'โมเดลที่สามารถใช้งานได้ (Available Models):' : 'Available Models:',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        constraints: const BoxConstraints(maxHeight: 120),
                        width: double.maxFinite,
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.textSecondary.withValues(alpha: 0.2)),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: ListView.builder(
                          shrinkWrap: true,
                          padding: const EdgeInsets.all(8),
                          itemCount: availableModels!.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Text(
                                '• ${availableModels![index]}',
                                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(isTh ? 'ยกเลิก' : 'Cancel'),
                ),
                TextButton(
                  onPressed: isValidating
                      ? null
                      : () async {
                          final key = controller.text.trim();
                          if (key.isEmpty) {
                            setState(() {
                              validationMessage = isTh
                                  ? 'กรุณากรอก API Key ก่อนทดสอบ'
                                  : 'Please enter an API Key to test';
                              isSuccess = false;
                              availableModels = null;
                            });
                            return;
                          }

                          setState(() {
                            isValidating = true;
                            validationMessage = null;
                            isSuccess = null;
                            availableModels = null;
                          });

                          final error = await geminiService.validateApiKey(key);
                          final models = await geminiService.getAvailableModels(key);

                          setState(() {
                            isValidating = false;
                            availableModels = models;
                            if (error == null) {
                              validationMessage = isTh
                                  ? 'คีย์ใช้งานได้ปกติ (โมเดล Gemini 3.5 Flash พร้อม)'
                                  : 'Key is valid (Gemini 3.5 Flash ready)';
                              isSuccess = true;
                            } else {
                              validationMessage = error;
                              isSuccess = false;
                            }
                          });
                        },
                  child: Text(isTh ? 'ทดสอบคีย์' : 'Test Key'),
                ),
                ElevatedButton(
                  onPressed: isValidating
                      ? null
                      : () async {
                          final newKey = controller.text.trim();
                          await ref.read(geminiApiKeyProvider.notifier).setKey(newKey.isEmpty ? null : newKey);
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  isTh
                                      ? (newKey.isEmpty ? 'รีเซ็ตเป็นคีย์ระบบเรียบร้อย' : 'บันทึก Gemini API Key สำเร็จ')
                                      : (newKey.isEmpty ? 'Reset to system key' : 'Gemini API Key saved successfully'),
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
      },
    );
  }

  void _showDeepSeekApiKeyDialog(BuildContext context, WidgetRef ref, String? currentKey) {
    final controller = TextEditingController(text: currentKey ?? '');
    final isTh = ref.read(localeProvider).languageCode == 'th';
    final deepSeekService = DeepSeekService();

    bool isValidating = false;
    String? validationMessage;
    bool? isSuccess;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(isTh ? 'ตั้งค่า DeepSeek / OpenRouter API Key (สำรอง)' : 'DeepSeek / OpenRouter API Key Settings'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isTh
                          ? 'ใส่ API Key ของ DeepSeek (sk-...) หรือ OpenRouter (sk-or-v1-...) เพื่อใช้สำรองเมื่อ Gemini หมดโควต้า (ระบบจะสลับใช้ให้อัตโนมัติ)'
                          : 'Enter a DeepSeek (sk-...) or OpenRouter (sk-or-v1-...) API Key as fallback when Gemini API limit is reached (Auto-routed).',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: controller,
                      decoration: InputDecoration(
                        labelText: 'DeepSeek / OpenRouter API Key',
                        hintText: 'sk-... หรือ sk-or-v1-...',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () => controller.clear(),
                        ),
                      ),
                    ),
                    if (isValidating) ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isTh ? 'กำลังทดสอบคีย์...' : 'Testing key...',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ] else if (validationMessage != null) ...[
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            isSuccess == true
                                ? Icons.check_circle_outline_rounded
                                : Icons.error_outline_rounded,
                            color: isSuccess == true ? AppColors.safe : AppColors.danger,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              validationMessage!,
                              style: TextStyle(
                                fontSize: 12,
                                color: isSuccess == true ? AppColors.safe : AppColors.danger,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(isTh ? 'ยกเลิก' : 'Cancel'),
                ),
                TextButton(
                  onPressed: isValidating
                      ? null
                      : () async {
                          final key = controller.text.trim();
                          if (key.isEmpty) {
                            setState(() {
                              validationMessage = isTh
                                  ? 'กรุณากรอก API Key ก่อนทดสอบ'
                                  : 'Please enter an API Key to test';
                              isSuccess = false;
                            });
                            return;
                          }

                          setState(() {
                            isValidating = true;
                            validationMessage = null;
                            isSuccess = null;
                          });

                          final error = await deepSeekService.validateApiKey(key);
                          final isOpenRouter = deepSeekService.isOpenRouterKey(key);

                          setState(() {
                            isValidating = false;
                            if (error == null) {
                              validationMessage = isTh
                                  ? (isOpenRouter
                                      ? 'คีย์ OpenRouter ใช้งานได้ปกติ (Model: deepseek/deepseek-chat)'
                                      : 'คีย์ DeepSeek ใช้งานได้ปกติ (Model: deepseek-chat)')
                                  : (isOpenRouter
                                      ? 'OpenRouter key valid (Model: deepseek/deepseek-chat)'
                                      : 'DeepSeek key valid (Model: deepseek-chat)');
                              isSuccess = true;
                            } else {
                              validationMessage = error;
                              isSuccess = false;
                            }
                          });
                        },
                  child: Text(isTh ? 'ทดสอบคีย์' : 'Test Key'),
                ),
                ElevatedButton(
                  onPressed: isValidating
                      ? null
                      : () async {
                          final newKey = controller.text.trim();
                          await ref.read(deepSeekApiKeyProvider.notifier).setKey(newKey.isEmpty ? null : newKey);
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  isTh
                                      ? (newKey.isEmpty ? 'รีเซ็ตเป็นคีย์ DeepSeek ระบบเรียบร้อย' : 'บันทึก DeepSeek API Key สำเร็จ')
                                      : (newKey.isEmpty ? 'Reset to system key' : 'DeepSeek API Key saved successfully'),
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
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final geminiApiKey = ref.watch(geminiApiKeyProvider);
    final deepSeekApiKey = ref.watch(deepSeekApiKeyProvider);
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

          // API Key section - Gemini
          _buildSectionHeader(isTh ? 'ตั้งค่า AI API Key หลัก & สำรอง (Optional)' : 'Primary & Fallback AI API Keys'),
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
              if (val && (geminiApiKey == null || geminiApiKey.trim().isEmpty)) {
                if (context.mounted) {
                  _showApiKeyDialog(context, ref, geminiApiKey);
                }
              }
            },
          ),
          ListTile(
            enabled: ref.watch(useCustomGeminiKeyProvider),
            leading: const Icon(Icons.vpn_key_rounded, color: AppColors.primary),
            title: Text(isTh ? 'กรอก Gemini API Key' : 'Enter Gemini API Key'),
            subtitle: Text(
              geminiApiKey != null && geminiApiKey.isNotEmpty
                  ? (isTh
                      ? 'คีย์ส่วนตัว: ${geminiApiKey.length >= 8 ? "${geminiApiKey.substring(0, 4)}...${geminiApiKey.substring(geminiApiKey.length - 4)}" : geminiApiKey}'
                      : 'Custom Key: ${geminiApiKey.length >= 8 ? "${geminiApiKey.substring(0, 4)}...${geminiApiKey.substring(geminiApiKey.length - 4)}" : geminiApiKey}')
                  : (isTh ? 'ยังไม่ได้ตั้งค่าคีย์' : 'No key set'),
            ),
            trailing: const Icon(Icons.edit_rounded, size: 20),
            onTap: ref.watch(useCustomGeminiKeyProvider)
                ? () => _showApiKeyDialog(context, ref, geminiApiKey)
                : null,
          ),
          const SizedBox(height: 8),

          // API Key section - DeepSeek Fallback
          SwitchListTile(
            title: Text(isTh ? 'ใช้ DeepSeek API Key ส่วนตัว (สำรอง)' : 'Use Custom DeepSeek API Key (Fallback)'),
            subtitle: Text(
              isTh
                  ? 'ใช้สำรองอัตโนมัติเมื่อ Gemini API หมดโควต้า'
                  : 'Used automatically when Gemini API quota runs out',
            ),
            value: ref.watch(useCustomDeepSeekKeyProvider),
            activeThumbColor: AppColors.primaryDark,
            onChanged: (val) async {
              await ref.read(useCustomDeepSeekKeyProvider.notifier).setUseCustomKey(val);
              if (val && (deepSeekApiKey == null || deepSeekApiKey.trim().isEmpty)) {
                if (context.mounted) {
                  _showDeepSeekApiKeyDialog(context, ref, deepSeekApiKey);
                }
              }
            },
          ),
          ListTile(
            enabled: ref.watch(useCustomDeepSeekKeyProvider),
            leading: const Icon(Icons.psychology_outlined, color: AppColors.primaryDark),
            title: Text(isTh ? 'กรอก DeepSeek API Key' : 'Enter DeepSeek API Key'),
            subtitle: Text(
              deepSeekApiKey != null && deepSeekApiKey.isNotEmpty
                  ? (isTh
                      ? 'คีย์สำรอง: ${deepSeekApiKey.length >= 8 ? "${deepSeekApiKey.substring(0, 4)}...${deepSeekApiKey.substring(deepSeekApiKey.length - 4)}" : deepSeekApiKey}'
                      : 'Fallback Key: ${deepSeekApiKey.length >= 8 ? "${deepSeekApiKey.substring(0, 4)}...${deepSeekApiKey.substring(deepSeekApiKey.length - 4)}" : deepSeekApiKey}')
                  : (isTh ? 'ยังไม่ได้ตั้งค่าคีย์สำรอง' : 'No fallback key set'),
            ),
            trailing: const Icon(Icons.edit_rounded, size: 20),
            onTap: ref.watch(useCustomDeepSeekKeyProvider)
                ? () => _showDeepSeekApiKeyDialog(context, ref, deepSeekApiKey)
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
