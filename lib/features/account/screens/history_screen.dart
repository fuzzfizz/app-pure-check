import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/models/analysis_result.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/safety_badge.dart';
import '../providers/profile_provider.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final historyAsync = ref.watch(scanHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.allScanHistory),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(scanHistoryProvider.future),
        child: historyAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text(l10n.errorGeneric(err.toString()))),
          data: (historyList) {
            if (historyList.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.history_rounded, size: 64, color: AppColors.primary),
                      const SizedBox(height: 16),
                      Text(
                        l10n.noScanHistoryYet,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
                final brand = product['brand'] as String? ?? l10n.unknownBrand;
                final imageUrl = product['image_url'] as String?;
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
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.mintBg),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: imageUrl != null && imageUrl.trim().isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: imageUrl,
                              fit: BoxFit.contain,
                              placeholder: (context, url) => const Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              ),
                              errorWidget: (context, url, error) => const Center(
                                child: Icon(
                                  Icons.image_not_supported_outlined,
                                  color: AppColors.textHint,
                                  size: 24,
                                ),
                              ),
                            )
                          : Container(
                              color: AppColors.mintBg,
                              child: const Icon(
                                Icons.spa_rounded,
                                color: AppColors.primary,
                                size: 26,
                              ),
                            ),
                    ),
                    title: Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 2),
                        Text(brand, maxLines: 1, overflow: TextOverflow.ellipsis),
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
