import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/models/analysis_result.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/safety_badge.dart';
import '../providers/profile_provider.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(scanHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ประวัติการสแกนทั้งหมด'),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(scanHistoryProvider.future),
        child: historyAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('เกิดข้อผิดพลาด: $err')),
          data: (historyList) {
            if (historyList.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history_rounded, size: 64, color: AppColors.primary),
                      SizedBox(height: 16),
                      Text(
                        'คุณยังไม่มีประวัติการสแกนผลิตภัณฑ์',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: historyList.length,
              itemBuilder: (context, i) {
                final item = historyList[i];
                final product = item['products'] as Map<String, dynamic>? ?? {};
                final name = product['name'] as String? ?? 'Unknown Product';
                final brand = product['brand'] as String? ?? 'ไม่ระบุแบรนด์';
                final safetyText = item['safety_level'] as String? ?? 'caution';
                final safety = SafetyLevel.values.firstWhere(
                  (e) => e.name == safetyText,
                  orElse: () => SafetyLevel.caution,
                );
                
                final scannedAt = DateTime.parse(item['scanned_at'] as String);
                final formattedDate = DateFormat('dd MMM yyyy HH:mm').format(scannedAt.toLocal());

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: const Icon(Icons.qr_code_2_rounded, color: AppColors.primary),
                    title: Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(brand),
                        const SizedBox(height: 4),
                        Text(
                          formattedDate,
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ],
                    ),
                    trailing: SafetyBadge(level: safety),
                    onTap: () {
                      context.push('/result', extra: {
                        'product': product,
                        'analysis': item['ai_analysis'],
                      });
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
