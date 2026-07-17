import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/user_profile.dart';
import '../../../core/models/analysis_result.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/safety_badge.dart';
import '../../auth/providers/auth_provider.dart';
import '../../account/providers/profile_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(scanHistoryProvider);
    final profileAsync = ref.watch(currentProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.mintBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.spa_rounded, color: AppColors.primary, size: 24),
            ),
            const SizedBox(width: 12),
            const Text('PureCheck'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle_outlined, size: 28),
            onPressed: () => context.push('/profile'),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, size: 26),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(scanHistoryProvider.future),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Welcome Card
                profileAsync.when(
                  data: (profile) {
                    final skinTypeLabel = profile?.skinType.labelTh ?? 'ไม่ระบุ';
                    return Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.mintBg,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'สวัสดีครับ!',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 22),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.face_rounded, color: AppColors.primaryDark, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                'โปรไฟล์ผิวของคุณ: ผิว$skinTypeLabel',
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                  loading: () => const SizedBox(height: 80, child: Center(child: CircularProgressIndicator())),
                  error: (_, __) => const SizedBox(),
                ),
                const SizedBox(height: 24),

                // Search Bar Trigger
                GestureDetector(
                  onTap: () => context.push('/search'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      border: Border.all(color: AppColors.mintBg),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(5),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search_rounded, color: AppColors.textSecondary),
                        const SizedBox(width: 12),
                        Text(
                          'ค้นหาผลิตภัณฑ์หรือส่วนผสม...',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.textHint,
                                fontSize: 16,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Scan Action Card (FAB Replacement for Hero Flow)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withAlpha(60),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.qr_code_scanner_rounded, size: 64, color: AppColors.white),
                      const SizedBox(height: 16),
                      Text(
                        'วิเคราะห์ส่วนผสมด่วน',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.white),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'สแกนบาร์โค้ดข้างกล่องเครื่องสำอางเพื่อเริ่มต้น',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.white.withAlpha(220)),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () => context.push('/scan'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.white,
                          foregroundColor: AppColors.primaryDark,
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.camera_alt_rounded),
                            SizedBox(width: 8),
                            Text('เปิดกล้องสแกน'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 36),

                // Recent Scans Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'ประวัติการสแกนล่าสุด',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 18),
                    ),
                    TextButton(
                      onPressed: () => context.push('/history'),
                      child: const Text('ดูทั้งหมด'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Scans List
                historyAsync.when(
                  data: (historyList) {
                    if (historyList.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: Column(
                          children: [
                            Icon(Icons.history_rounded, size: 48, color: AppColors.textHint),
                            const SizedBox(height: 12),
                            Text(
                              'ยังไม่มีประวัติการสแกน\nกดปุ่มสแกนด้านบนเพื่อเริ่มตรวจสอบส่วนผสมผลิตภัณฑ์',
                              style: TextStyle(color: AppColors.textSecondary),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    }
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: historyList.length > 5 ? 5 : historyList.length,
                      itemBuilder: (context, i) {
                        final item = historyList[i];
                        final product = item['products'] as Map<String, dynamic>? ?? {};
                        final name = product['name'] as String? ?? 'Unknown Product';
                        final brand = product['brand'] as String? ?? '';
                        final safetyText = item['safety_level'] as String? ?? 'caution';
                        final safety = SafetyLevel.values.firstWhere(
                          (e) => e.name == safetyText,
                          orElse: () => SafetyLevel.caution,
                        );

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.mintBg,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.bubble_chart_rounded, color: AppColors.primary),
                            ),
                            title: Text(
                              name,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(brand, maxLines: 1),
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
                  loading: () => const SizedBox(height: 100, child: Center(child: CircularProgressIndicator())),
                  error: (e, __) => Text('เกิดข้อผิดพลาดในการโหลดข้อมูล: $e'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
