import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/data/inci_core_dataset.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/models/analysis_result.dart';
import '../../../core/models/product.dart';
import '../../../core/models/allergen.dart';
import '../../../core/services/admin_moderation_service.dart';
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

  Future<void> _reportAllergen(String name, AppLocalizations l10n) async {
    setState(() => _reporting = true);
    try {
      final user = ref.read(currentUserProvider);
      if (user == null) throw Exception('User not logged in');

      final supabaseService = ref.read(supabaseServiceProvider);

      final allergen = Allergen(
        id: '',
        userId: user.id,
        ingredientName: name,
        reactionSymptoms: const ['คัน', 'แดง'],
        severity: AllergenSeverity.moderate,
        source: AllergenSource.suspected,
      );

      await supabaseService.addAllergen(allergen);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.addedAllergen(name))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorGeneric(e.toString()))),
        );
      }
    } finally {
      if (mounted) setState(() => _reporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // Parse extra params
    final params = widget.extra as Map<String, dynamic>? ?? {};
    final rawProduct = params['product'];
    final rawAnalysis = params['analysis'];

    if (rawProduct == null || rawAnalysis == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.analysisResults)),
        body: Center(
          child: Text(l10n.noAnalysisResults),
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
        verdictTitle = l10n.suitableForSkin;
        verdictIcon = Icons.check_circle_outline_rounded;
        break;
      case SafetyLevel.caution:
        bannerBg = AppColors.caution;
        verdictTitle = l10n.useWithCaution;
        verdictIcon = Icons.warning_amber_rounded;
        break;
      case SafetyLevel.danger:
        bannerBg = AppColors.danger;
        verdictTitle = l10n.avoidProduct;
        verdictIcon = Icons.dangerous_rounded;
        break;
    }

    // Group ingredients
    final dangerList = analysis.ingredientBreakdown.where((e) => e.riskLevel == SafetyLevel.danger).toList();
    final cautionList = analysis.ingredientBreakdown.where((e) => e.riskLevel == SafetyLevel.caution).toList();
    final safeList = analysis.ingredientBreakdown.where((e) => e.riskLevel == SafetyLevel.safe).toList();

    // Select summary based on language
    final summaryText = l10n.localeName == 'en' && analysis.summaryEn.isNotEmpty
        ? analysis.summaryEn
        : analysis.summaryTh;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.analysisResults),
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

            // Health Disclaimer Banner
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Card(
                key: const Key('health_disclaimer_card'),
                color: AppColors.mintBg.withAlpha(120),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: AppColors.primary.withAlpha(80),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        size: 20,
                        color: AppColors.primaryDark,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          l10n.healthDisclaimer,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                                height: 1.4,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Ingredients Safety Summary Stats Bar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatPill(l10n.safe, safeList.length, AppColors.safe, Icons.check_circle_outline, l10n.localeName == 'th'),
                        Container(width: 1, height: 24, color: Colors.grey.shade300),
                        _buildStatPill(l10n.caution, cautionList.length, AppColors.caution, Icons.warning_amber_rounded, l10n.localeName == 'th'),
                        Container(width: 1, height: 24, color: Colors.grey.shade300),
                        _buildStatPill(l10n.danger, dangerList.length, AppColors.danger, Icons.error_outline, l10n.localeName == 'th'),
                      ],
                    ),
                  ),

                  // Flagged Allergens Section (Only if danger/caution)
                  if (analysis.flaggedIngredients.isNotEmpty) ...[
                    Text(
                      l10n.flaggedChemicals,
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
                                  onPressed: _reporting ? null : () => _reportAllergen(flagged.name, l10n),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.danger,
                                    side: const BorderSide(color: AppColors.danger),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  ),
                                  child: Text(l10n.markAsAllergen),
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
                    l10n.aiSummary,
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
                                l10n.analyzedByGemini,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            summaryText,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Ingredients Breakdown Header
                  Text(
                    l10n.detailedBreakdown,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 18),
                  ),
                  const SizedBox(height: 16),

                  // List ingredients
                  if (analysis.ingredientBreakdown.isEmpty)
                    Text(l10n.noIngredientData)
                  else ...[
                    if (dangerList.isNotEmpty) ...[
                      _buildCategorySection(l10n.highRiskIngredients, dangerList, AppColors.danger, l10n),
                      const SizedBox(height: 20),
                    ],
                    if (cautionList.isNotEmpty) ...[
                      _buildCategorySection(l10n.cautionIngredients, cautionList, AppColors.caution, l10n),
                      const SizedBox(height: 20),
                    ],
                    if (safeList.isNotEmpty) ...[
                      _buildCategorySection(l10n.safeIngredients, safeList, AppColors.safe, l10n),
                      const SizedBox(height: 20),
                    ],
                  ],
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () async {
                      try {
                        final user = ref.read(currentUserProvider);
                        final supabaseService = ref.read(supabaseServiceProvider);
                        final moderationService = ref.read(adminModerationServiceProvider);
                        final evaluation = await moderationService.evaluateProduct(product);

                        final updatedProduct = product.copyWith(
                          status: 'pending',
                          isVerified: false,
                          submittedBy: user?.id,
                          verifiedCount: product.verifiedCount + 1,
                          confidenceScore: evaluation.confidenceScore,
                          aiFlags: evaluation.flags,
                        );
                        await supabaseService.upsertProduct(updatedProduct);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l10n.thankYouCommunity)),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l10n.errorGeneric(e.toString()))),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.people_outline_rounded),
                    label: Text(l10n.helpCommunity),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                    ),
                  ),
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
            child: Text(l10n.backToHome),
          ),
        ),
      ),
    );
  }

  Widget _buildStatPill(String label, int count, Color color, IconData icon, bool isTh) {
    final countText = isTh ? '$count รายการ' : '$count ${count == 1 ? "item" : "items"}';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              countText,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCategorySection(
    String title,
    List<IngredientBreakdown> list,
    Color color,
    AppLocalizations l10n,
  ) {
    final isTh = l10n.localeName == 'th';
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
          final inciInfo = InciCoreDataset.find(ing.name);
          final functionText = inciInfo?.category ?? ing.function;
          final descTh = inciInfo?.descriptionTh;

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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ing.name,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              if (functionText != null && functionText.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  functionText,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        SafetyBadge(level: ing.riskLevel),
                      ],
                    ),
                    if (isExpanded) ...[
                      const SizedBox(height: 8),
                      const Divider(),
                      const SizedBox(height: 4),
                      if (descTh != null && descTh.isNotEmpty && isTh) ...[
                        Text(
                          'หน้าที่ & สรรพคุณ: $descTh',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.textPrimary,
                                fontSize: 13,
                              ),
                        ),
                        const SizedBox(height: 4),
                      ] else if (ing.function != null) ...[
                        Text(
                          l10n.functionProperty(ing.function!),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                        ),
                      ] else if (descTh != null && descTh.isNotEmpty) ...[
                        Text(
                          'Function & Benefits: $descTh',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.textPrimary,
                                fontSize: 13,
                              ),
                        ),
                      ],
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
