import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';

class IngredientDetailScreen extends ConsumerWidget {
  final String ingredientName;

  const IngredientDetailScreen({
    super.key,
    required this.ingredientName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Check if user is allergic to this ingredient
    final supabaseService = ref.read(supabaseServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(ingredientName),
      ),
      body: FutureBuilder(
        future: ref.read(currentUserProvider) != null
            ? supabaseService.getAllergens(ref.read(currentUserProvider)!.id)
            : Future.value([]),
        builder: (context, snapshot) {
          final allergens = snapshot.data ?? [];
          final isAllergic = allergens.any(
            (a) => a.ingredientName.toLowerCase() == ingredientName.toLowerCase()
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isAllergic ? AppColors.danger.withAlpha(20) : AppColors.mintBg,
                    border: Border.all(
                      color: isAllergic ? AppColors.danger.withAlpha(100) : AppColors.primary,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        isAllergic ? Icons.error_outline_rounded : Icons.science_rounded,
                        size: 56,
                        color: isAllergic ? AppColors.danger : AppColors.primaryDark,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        ingredientName,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isAllergic ? 'มีประวัติแพ้ส่วนผสมนี้' : 'ปลอดภัยสำหรับคุณ (ไม่มีประวัติการแพ้)',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: isAllergic ? AppColors.danger : AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  'ข้อมูลเกี่ยวกับส่วนผสม',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Text(
                  'สารเคมีชนิดนี้มักใช้ในการเป็นสารทำละลาย สารทำความสะอาด หรือสารออกฤทธิ์ในเครื่องสำอาง ทั้งนี้ควรสังเกตการระคายเคืองผิวทุกครั้งที่เริ่มใช้ผลิตภัณฑ์ใหม่',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
