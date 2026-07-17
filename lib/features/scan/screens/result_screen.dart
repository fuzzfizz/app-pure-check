import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/analysis_result.dart';
import '../../../core/models/product.dart';
import '../../../core/models/allergen.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/safety_badge.dart';
import '../../auth/providers/auth_provider.dart';

class ResultScreen extends ConsumerStatefulWidget {
  final Object? extra;

  const ResultScreen({
    super.key,
    required this.extra,
  });

  @override
  ConsumerState<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends ConsumerState<ResultScreen> {
  String? _expandedIngredient;
  bool _reporting = false;

  Future<void> _reportAllergen(String name) async {
    setState(() => _reporting = true);
    try {
      final user = ref.read(currentUserProvider);
      if (user == null) throw Exception('User not logged in');

      final supabaseService = ref.read(supabaseServiceProvider);

      final allergen = Allergen(
        id: '',
        userId: user.id,
        ingredientName: name,
        reactionSymptoms: ['คัน', 'แดง'],
        severity: AllergenSeverity.moderate,
        source: AllergenSource.suspected,
      );

      await supabaseService.addAllergen(allergen);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เพิ่ม $name ลงในประวัติการแพ้ของคุณแล้ว')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _reporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Parse extra params
    final params = widget.extra as Map<String, dynamic>? ?? {};
    final rawProduct = params['product'];
    final rawAnalysis = params['analysis'];

    if (rawProduct == null || rawAnalysis == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('ผลการวิเคราะห์')),
        body: const Center(
          child: Text('ไม่พบข้อมูลผลลัพธ์การวิเคราะห์'),
        ),
      );
    }

    final Product product = rawProduct is Product ? rawProduct : Product.fromJson(Map<String, dynamic>.from(rawProduct));
    final AnalysisResult analysis = rawAnalysis is AnalysisResult ? rawAnalysis : AnalysisResult.fromJson(Map<String, dynamic>.from(rawAnalysis));

    Color bannerBg;
    Color bannerText = AppColors.white;
    String verdictTitle;
    IconData verdictIcon;

    switch (analysis.overallSafety) {
      case SafetyLevel.safe:
        bannerBg = AppColors.safe;
        verdictTitle = 'เหมาะสมกับผิวคุณ';
        verdictIcon = Icons.check_circle_outline_rounded;
        break;
      case SafetyLevel.caution:
        bannerBg = AppColors.caution;
        verdictTitle = 'ควรระมัดระวัง';
        verdictIcon = Icons.warning_amber_rounded;
        break;
      case SafetyLevel.danger:
        bannerBg = AppColors.danger;
        verdictTitle = 'หลีกเลี่ยงผลิตภัณฑ์นี้';
        verdictIcon = Icons.dangerous_rounded;
        break;
    }

    // Group ingredients
    final dangerList = analysis.ingredientBreakdown.where((e) => e.riskLevel == SafetyLevel.danger).toList();
    final cautionList = analysis.ingredientBreakdown.where((e) => e.riskLevel == SafetyLevel.caution).toList();
    final safeList = analysis.ingredientBreakdown.where((e) => e.riskLevel == SafetyLevel.safe).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('ผลลัพธ์การวิเคราะห์'),
        leading: IconButton(
          icon: const Icon(Icons.home_outlined),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Safety Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              color: bannerBg,
              child: Row(
                children: [
                  Icon(verdictIcon, size: 48, color: bannerText),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          verdictTitle,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: bannerText,
                                fontWeight: FontWeight.bold,
                                fontSize: 22,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          product.brand != null ? '${product.brand} — ${product.name}' : product.name,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: bannerText.withAlpha(220),
                              ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Flagged Allergens Section (Only if danger/caution)
                  if (analysis.flaggedIngredients.isNotEmpty) ...[
                    Text(
                      'สารเคมีที่ควรระวังเป็นพิเศษ',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 18),
                    ),
                    const SizedBox(height: 12),
                    ...analysis.flaggedIngredients.map((flagged) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        color: flagged.riskLevel == SafetyLevel.danger
                            ? AppColors.danger.withAlpha(15)
                            : AppColors.caution.withAlpha(15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: flagged.riskLevel == SafetyLevel.danger
                                ? AppColors.danger.withAlpha(100)
                                : AppColors.caution.withAlpha(100),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    flagged.riskLevel == SafetyLevel.danger
                                        ? Icons.error_outline_rounded
                                        : Icons.warning_amber_rounded,
                                    color: flagged.riskLevel == SafetyLevel.danger
                                        ? AppColors.danger
                                        : AppColors.caution,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    flagged.name,
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: flagged.riskLevel == SafetyLevel.danger
                                              ? AppColors.danger
                                              : AppColors.textPrimary,
                                        ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                flagged.reason,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              if (flagged.riskLevel != SafetyLevel.danger) ...[
                                const SizedBox(height: 12),
                                OutlinedButton(
                                  onPressed: _reporting ? null : () => _reportAllergen(flagged.name),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.danger,
                                    side: const BorderSide(color: AppColors.danger),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  ),
                                  child: const Text('ระบุว่าฉันแพ้สารตัวนี้'),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 24),
                  ],

                  // AI Analysis Summary Card
                  Text(
                    'สรุปผลลัพธ์โดย AI',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 18),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.auto_awesome, color: AppColors.primaryDark),
                              const SizedBox(width: 12),
                              Text(
                                'วิเคราะห์โดย Gemini AI',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            analysis.summaryTh,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Ingredients Breakdown Header
                  Text(
                    'การวิเคราะห์รายละเอียดสารแยกตามตัว',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 18),
                  ),
                  const SizedBox(height: 16),

                  // List ingredients
                  if (analysis.ingredientBreakdown.isEmpty)
                    const Text('ไม่พบข้อมูลส่วนผสมในสารระบบ')
                  else ...[
                    if (dangerList.isNotEmpty) ...[
                      _buildCategorySection('สารที่มีความเสี่ยงสูง (Danger)', dangerList, AppColors.danger),
                      const SizedBox(height: 20),
                    ],
                    if (cautionList.isNotEmpty) ...[
                      _buildCategorySection('สารที่ควรระวัง (Caution)', cautionList, AppColors.caution),
                      const SizedBox(height: 20),
                    ],
                    if (safeList.isNotEmpty) ...[
                      _buildCategorySection('สารที่ปลอดภัย (Safe)', safeList, AppColors.safe),
                      const SizedBox(height: 20),
                    ],
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: OutlinedButton(
            onPressed: () => context.go('/home'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              foregroundColor: AppColors.primaryDark,
            ),
            child: const Text('กลับหน้าหลัก'),
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySection(
    String title,
    List<IngredientBreakdown> list,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(width: 4, height: 16, color: color),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...list.map((ing) {
          final isExpanded = _expandedIngredient == ing.name;
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              onTap: () {
                setState(() {
                  _expandedIngredient = isExpanded ? null : ing.name;
                });
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            ing.name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        SafetyBadge(level: ing.riskLevel),
                      ],
                    ),
                    if (isExpanded && ing.function != null) ...[
                      const SizedBox(height: 8),
                      const Divider(),
                      const SizedBox(height: 4),
                      Text(
                        'หน้าที่/คุณสมบัติ: ${ing.function}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
