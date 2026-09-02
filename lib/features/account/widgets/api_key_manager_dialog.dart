import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/user_api_key.dart';
import '../../../core/providers/user_api_keys_provider.dart';
import '../../../core/services/ai_key_detector_service.dart';
import '../../../core/theme/app_theme.dart';

class AddApiKeyDialog extends ConsumerStatefulWidget {
  const AddApiKeyDialog({super.key});

  @override
  ConsumerState<AddApiKeyDialog> createState() => _AddApiKeyDialogState();
}

class _AddApiKeyDialogState extends ConsumerState<AddApiKeyDialog> {
  final _controller = TextEditingController();
  final _detector = AiKeyDetectorService();

  DetectedProviderInfo? _selectedProvider;
  bool _isAutoDetected = false;
  bool _isValidating = false;
  KeyValidationResult? _validationResult;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final text = _controller.text.trim();
    if (text.isNotEmpty && !_isAutoDetected) {
      final detected = _detector.detectProvider(text);
      setState(() {
        _selectedProvider = detected;
        _isAutoDetected = true;
      });
    } else if (text.isEmpty && _isAutoDetected) {
      setState(() {
        _selectedProvider = null;
        _isAutoDetected = false;
        _validationResult = null;
      });
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  Future<void> _testAndSave() async {
    final key = _controller.text.trim();
    if (key.isEmpty) {
      setState(() {
        _validationResult = const KeyValidationResult(
          status: KeyStatus.invalid,
          message: 'กรุณากรอก API Key ก่อนบันทึก',
        );
      });
      return;
    }

    final providerToUse = _selectedProvider ?? _detector.detectProvider(key);

    setState(() {
      _isValidating = true;
      _validationResult = null;
    });

    final result = await _detector.testKeyQuota(key, providerToUse);

    if (!mounted) return;

    setState(() {
      _isValidating = false;
      _validationResult = result;
    });

    if (result.status == KeyStatus.valid || result.status == KeyStatus.quotaExceeded) {
      final success = await ref.read(userApiKeysProvider.notifier).addKey(
            key,
            overrideProvider: providerToUse,
          );

      if (!mounted) return;

      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.safe,
            content: Text('บันทึกคีย์ ${providerToUse.providerName} เรียบร้อยแล้ว'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.danger,
            content: Text('ไม่สามารถเพิ่มได้เนื่องจากครบโควต้า 3 คีย์แล้ว'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentProvider = _selectedProvider ??
        (_controller.text.trim().isNotEmpty
            ? _detector.detectProvider(_controller.text.trim())
            : null);

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.vpn_key_rounded, color: AppColors.primary),
          SizedBox(width: 8),
          Text('เพิ่ม AI API Key ส่วนตัว', style: TextStyle(fontSize: 18)),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'วาง API Key ของคุณ ระบบจะตรวจจับค่ายและทดสอบโควต้าให้อัตโนมัติ (จำกัดสูงสุด 3 คีย์)',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: 'วาง API Key ที่นี่',
                hintText: 'AIzaSy..., gsk_..., sk-or-..., sk-...',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear_rounded),
                  onPressed: () {
                    _controller.clear();
                    setState(() {
                      _isAutoDetected = false;
                      _selectedProvider = null;
                      _validationResult = null;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Provider detection card
            if (currentProvider != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.auto_awesome, color: AppColors.primary, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'ค่ายที่ตรวจพบ: ${currentProvider.providerName}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'โมเดลที่ใช้: ${currentProvider.defaultModel}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    // Manual Override Dropdown
                    Row(
                      children: [
                        const Text('เปลี่ยนค่าย: ', style: TextStyle(fontSize: 12)),
                        DropdownButton<DetectedProviderInfo>(
                          value: AiKeyDetectorService.supportedProviders.any((p) => p.provider == currentProvider.provider)
                              ? AiKeyDetectorService.supportedProviders.firstWhere((p) => p.provider == currentProvider.provider)
                              : null,
                          isDense: true,
                          underline: const SizedBox(),
                          items: AiKeyDetectorService.supportedProviders.map((p) {
                            return DropdownMenuItem(
                              value: p,
                              child: Text(p.providerName, style: const TextStyle(fontSize: 12)),
                            );
                          }).toList(),
                          onChanged: (newVal) {
                            if (newVal != null) {
                              setState(() {
                                _selectedProvider = newVal;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            if (_isValidating) ...[
              const Row(
                children: [
                  SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                  SizedBox(width: 10),
                  Text('กำลังตรวจสอบคีย์และโควต้าโทเคน...', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ] else if (_validationResult != null) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    _validationResult!.status == KeyStatus.valid
                        ? Icons.check_circle_rounded
                        : (_validationResult!.status == KeyStatus.quotaExceeded
                            ? Icons.warning_amber_rounded
                            : Icons.error_rounded),
                    color: _validationResult!.status == KeyStatus.valid
                        ? AppColors.safe
                        : (_validationResult!.status == KeyStatus.quotaExceeded
                            ? Colors.amber.shade700
                            : AppColors.danger),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _validationResult!.message,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: _validationResult!.status == KeyStatus.valid
                            ? AppColors.safe
                            : (_validationResult!.status == KeyStatus.quotaExceeded
                                ? Colors.amber.shade800
                                : AppColors.danger),
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
          child: const Text('ยกเลิก'),
        ),
        ElevatedButton(
          onPressed: _isValidating ? null : _testAndSave,
          child: const Text('ทดสอบและบันทึก'),
        ),
      ],
    );
  }
}
