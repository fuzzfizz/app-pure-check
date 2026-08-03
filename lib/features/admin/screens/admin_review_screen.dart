import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/product.dart';
import '../../../core/services/admin_moderation_service.dart';
import '../../../features/auth/providers/auth_provider.dart';

class ProductWithEvaluation {
  final Product product;
  final ModerationEvaluation evaluation;

  const ProductWithEvaluation({
    required this.product,
    required this.evaluation,
  });
}

class AdminReviewScreen extends ConsumerStatefulWidget {
  const AdminReviewScreen({super.key});

  @override
  ConsumerState<AdminReviewScreen> createState() => _AdminReviewScreenState();
}

class _AdminReviewScreenState extends ConsumerState<AdminReviewScreen> {
  bool _isLoading = true;
  List<ProductWithEvaluation> _items = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPendingProducts();
  }

  Future<void> _loadPendingProducts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final supabaseService = ref.read(supabaseServiceProvider);
      final moderationService = ref.read(adminModerationServiceProvider);

      final products = await supabaseService.getPendingProducts();
      final items = <ProductWithEvaluation>[];

      for (final product in products) {
        final evaluation = await moderationService.evaluateProduct(product);
        items.add(ProductWithEvaluation(
          product: product,
          evaluation: evaluation,
        ));
      }

      if (mounted) {
        setState(() {
          _items = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _autoApproveSafeBatch() async {
    final safeItems =
        _items.where((item) => item.evaluation.isHighConfidence).toList();
    if (safeItems.isEmpty) return;

    final supabaseService = ref.read(supabaseServiceProvider);

    for (final item in safeItems) {
      await supabaseService.updateProductStatus(
        item.product.id,
        'approved',
        true,
      );
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Auto-approved ${safeItems.length} safe product(s)'),
        ),
      );
      setState(() {
        _items.removeWhere((item) => item.evaluation.isHighConfidence);
      });
    }
  }

  Future<void> _approveItem(ProductWithEvaluation item) async {
    final supabaseService = ref.read(supabaseServiceProvider);
    await supabaseService.updateProductStatus(
      item.product.id,
      'approved',
      true,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${item.product.name} approved')),
      );
      setState(() {
        _items.removeWhere((i) => i.product.id == item.product.id);
      });
    }
  }

  Future<void> _rejectItem(ProductWithEvaluation item) async {
    final supabaseService = ref.read(supabaseServiceProvider);
    await supabaseService.updateProductStatus(
      item.product.id,
      'rejected',
      false,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${item.product.name} rejected')),
      );
      setState(() {
        _items.removeWhere((i) => i.product.id == item.product.id);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final safeCount =
        _items.where((item) => item.evaluation.isHighConfidence).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Product Review'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPendingProducts,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Error: $_errorMessage',
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadPendingProducts,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Pending Review: ${_items.length}',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              Text(
                                'Safe (>= 80%): $safeCount',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: Colors.green.shade700,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed:
                                safeCount > 0 ? _autoApproveSafeBatch : null,
                            icon: const Icon(Icons.auto_awesome),
                            label: const Text('1-Click Auto-Approve Safe Batch'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade700,
                              foregroundColor: Colors.white,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _items.isEmpty
                          ? const Center(
                              child: Text(
                                'No pending products to review',
                                style: TextStyle(fontSize: 16),
                              ),
                            )
                          : ListView.builder(
                              itemCount: _items.length,
                              padding: const EdgeInsets.all(12),
                              itemBuilder: (context, index) {
                                final item = _items[index];
                                return _buildProductCard(item);
                              },
                            ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildProductCard(ProductWithEvaluation item) {
    final product = item.product;
    final eval = item.evaluation;

    Color badgeColor;
    String label;
    IconData icon;

    if (eval.isHighConfidence) {
      badgeColor = Colors.green.shade700;
      label = 'Green';
      icon = Icons.check_circle;
    } else if (eval.needsInspection) {
      badgeColor = Colors.orange.shade800;
      label = 'Yellow';
      icon = Icons.warning;
    } else {
      badgeColor = Colors.red.shade700;
      label = 'Red';
      icon = Icons.error;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      if (product.brand != null && product.brand!.isNotEmpty)
                        Text(
                          'Brand: ${product.brand}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      if (product.barcode != null)
                        Text(
                          'Barcode: ${product.barcode}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: badgeColor.withAlpha(30),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: badgeColor),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, color: badgeColor, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        label,
                        style: TextStyle(
                          color: badgeColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '(${eval.confidenceScore}%)',
                        style: TextStyle(
                          color: badgeColor,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (eval.flags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: eval.flags
                    .map(
                      (flag) => Chip(
                        label: Text(
                          flag,
                          style: const TextStyle(fontSize: 11),
                        ),
                        backgroundColor: Colors.amber.shade100,
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                      ),
                    )
                    .toList(),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              'Ingredients: ${product.ingredients.isEmpty ? (product.rawIngredientsText ?? "None") : product.ingredients.join(", ")}',
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _rejectItem(item),
                  icon: const Icon(Icons.close, color: Colors.red),
                  label: const Text('Reject', style: TextStyle(color: Colors.red)),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _approveItem(item),
                  icon: const Icon(Icons.check),
                  label: const Text('Approve'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
