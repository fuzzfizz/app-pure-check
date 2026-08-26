import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/product.dart';
import '../../../core/services/admin_moderation_service.dart';
import '../../../features/auth/providers/auth_provider.dart';

enum EvaluationStatus {
  idle,
  analyzing,
  done,
}

class ProductWithEvaluation {
  final Product product;
  final ModerationEvaluation? evaluation;
  final EvaluationStatus status;

  const ProductWithEvaluation({
    required this.product,
    this.evaluation,
    this.status = EvaluationStatus.idle,
  });

  ProductWithEvaluation copyWith({
    Product? product,
    ModerationEvaluation? evaluation,
    EvaluationStatus? status,
  }) {
    return ProductWithEvaluation(
      product: product ?? this.product,
      evaluation: evaluation ?? this.evaluation,
      status: status ?? this.status,
    );
  }
}

class AdminReviewScreen extends ConsumerStatefulWidget {
  const AdminReviewScreen({super.key});

  @override
  ConsumerState<AdminReviewScreen> createState() => _AdminReviewScreenState();
}

class _AdminReviewScreenState extends ConsumerState<AdminReviewScreen> {
  bool _isLoading = true;
  bool _isBatchAnalyzing = false;
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
      _isBatchAnalyzing = false;
    });

    try {
      final supabaseService = ref.read(supabaseServiceProvider);
      final products = await supabaseService.getPendingProducts();

      final items = products
          .map((p) => ProductWithEvaluation(
                product: p,
                status: EvaluationStatus.idle,
              ))
          .toList();

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

  Future<void> _startSequentialAiAnalysis() async {
    if (_isBatchAnalyzing || _items.isEmpty) return;

    setState(() {
      _isBatchAnalyzing = true;
    });

    final moderationService = ref.read(adminModerationServiceProvider);

    for (int i = 0; i < _items.length; i++) {
      if (!mounted) break;
      if (_items[i].status == EvaluationStatus.done) continue;

      setState(() {
        _items[i] = _items[i].copyWith(status: EvaluationStatus.analyzing);
      });

      final eval = await moderationService.evaluateProduct(_items[i].product);

      if (mounted) {
        setState(() {
          _items[i] = _items[i].copyWith(
            evaluation: eval,
            status: EvaluationStatus.done,
          );
        });
      }
    }

    if (mounted) {
      setState(() {
        _isBatchAnalyzing = false;
      });
    }
  }

  Future<void> _analyzeSingleProduct(int index) async {
    if (index < 0 || index >= _items.length) return;
    if (_items[index].status == EvaluationStatus.analyzing) return;

    setState(() {
      _items[index] = _items[index].copyWith(status: EvaluationStatus.analyzing);
    });

    final moderationService = ref.read(adminModerationServiceProvider);
    final eval = await moderationService.evaluateProduct(_items[index].product);

    if (mounted) {
      setState(() {
        _items[index] = _items[index].copyWith(
          evaluation: eval,
          status: EvaluationStatus.done,
        );
      });
    }
  }

  Future<void> _autoApproveSafeBatch() async {
    final safeItems = _items
        .where((item) =>
            item.status == EvaluationStatus.done &&
            item.evaluation != null &&
            item.evaluation!.isHighConfidence)
        .toList();
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
        _items.removeWhere((item) =>
            item.status == EvaluationStatus.done &&
            item.evaluation != null &&
            item.evaluation!.isHighConfidence);
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
    final analyzedItems =
        _items.where((item) => item.status == EvaluationStatus.done).toList();
    final safeCount = analyzedItems
        .where((item) => item.evaluation?.isHighConfidence == true)
        .length;
    final unanalyzedCount = _items.length - analyzedItems.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Product Review'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isBatchAnalyzing ? null : _loadPendingProducts,
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
                      color:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
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
                          const SizedBox(height: 4),
                          Text(
                            'Analyzed: ${analyzedItems.length}/${_items.length}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: (_isBatchAnalyzing ||
                                          unanalyzedCount == 0)
                                      ? null
                                      : _startSequentialAiAnalysis,
                                  icon: _isBatchAnalyzing
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Icon(Icons.auto_awesome),
                                  label: Text(
                                    _isBatchAnalyzing
                                        ? 'Analyzing (${analyzedItems.length}/${_items.length})...'
                                        : unanalyzedCount > 0
                                            ? 'Start AI Analysis ($unanalyzedCount)'
                                            : 'All Analyzed',
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        Theme.of(context).colorScheme.primary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: (safeCount > 0 &&
                                          !_isBatchAnalyzing)
                                      ? _autoApproveSafeBatch
                                      : null,
                                  icon: const Icon(Icons.check_circle_outline),
                                  label: const Text('Auto-Approve Safe'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green.shade700,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (_isBatchAnalyzing) ...[
                            const SizedBox(height: 8),
                            LinearProgressIndicator(
                              value: _items.isNotEmpty
                                  ? analyzedItems.length / _items.length
                                  : null,
                            ),
                          ],
                        ],
                      ),
                    ),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _loadPendingProducts,
                        child: _items.isEmpty
                            ? ListView(
                                children: const [
                                  SizedBox(height: 120),
                                  Center(
                                    child: Column(
                                      children: [
                                        Icon(Icons.inbox_outlined,
                                            size: 48, color: Colors.grey),
                                        SizedBox(height: 12),
                                        Text(
                                          'No pending products to review',
                                          style: TextStyle(
                                              fontSize: 16, color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              )
                            : ListView.builder(
                                itemCount: _items.length,
                                padding: const EdgeInsets.all(12),
                                itemBuilder: (context, index) {
                                  final item = _items[index];
                                  return _buildProductCard(item, index);
                                },
                              ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildProductCard(ProductWithEvaluation item, int index) {
    final product = item.product;
    final eval = item.evaluation;
    final status = item.status;

    Color badgeColor;
    String label;
    IconData icon;

    if (status == EvaluationStatus.idle) {
      badgeColor = Colors.blueGrey;
      label = 'Pending AI';
      icon = Icons.hourglass_empty;
    } else if (status == EvaluationStatus.analyzing) {
      badgeColor = Colors.blue;
      label = 'Analyzing';
      icon = Icons.sync;
    } else if (eval != null && eval.isHighConfidence) {
      badgeColor = Colors.green.shade700;
      label = 'Green';
      icon = Icons.check_circle;
    } else if (eval != null && eval.needsInspection) {
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
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showProductDetailModal(context, item, index),
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
                        if (status == EvaluationStatus.analyzing)
                          SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: badgeColor,
                            ),
                          )
                        else
                          Icon(icon, color: badgeColor, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          label,
                          style: TextStyle(
                            color: badgeColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (eval != null && status == EvaluationStatus.done) ...[
                          const SizedBox(width: 4),
                          Text(
                            '(${eval.confidenceScore}%)',
                            style: TextStyle(
                              color: badgeColor,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              if (eval != null && status == EvaluationStatus.done) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: badgeColor.withAlpha(15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: badgeColor.withAlpha(50)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(icon, size: 15, color: badgeColor),
                          const SizedBox(width: 6),
                          Text(
                            'สรุปเหตุผลคะแนน (${eval.confidenceScore}%):',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: badgeColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ...eval.reasonSummaries.map(
                        (reason) => Padding(
                          padding: const EdgeInsets.only(bottom: 3),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '• ',
                                style: TextStyle(
                                  color: badgeColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  reason,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: Colors.black87,
                                        fontSize: 11.5,
                                        height: 1.3,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: () =>
                            _showProductDetailModal(context, item, index),
                        icon: const Icon(Icons.info_outline, size: 18),
                        label: const Text('View Details'),
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          foregroundColor:
                              Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      if (status == EvaluationStatus.idle) ...[
                        const SizedBox(width: 4),
                        OutlinedButton.icon(
                          onPressed: () => _analyzeSingleProduct(index),
                          icon: const Icon(Icons.auto_awesome, size: 16),
                          label: const Text('Analyze'),
                          style: OutlinedButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => _rejectItem(item),
                        icon: const Icon(Icons.close, color: Colors.red),
                        label: const Text('Reject',
                            style: TextStyle(color: Colors.red)),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () => _approveItem(item),
                        icon: const Icon(Icons.check),
                        label: const Text('Approve'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          foregroundColor:
                              Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showProductDetailModal(
      BuildContext context, ProductWithEvaluation item, int index) {
    final product = item.product;
    final eval = item.evaluation;
    final status = item.status;

    Color badgeColor;
    String label;
    IconData icon;

    if (status == EvaluationStatus.idle) {
      badgeColor = Colors.blueGrey;
      label = 'Pending AI';
      icon = Icons.hourglass_empty;
    } else if (status == EvaluationStatus.analyzing) {
      badgeColor = Colors.blue;
      label = 'Analyzing';
      icon = Icons.sync;
    } else if (eval != null && eval.isHighConfidence) {
      badgeColor = Colors.green.shade700;
      label = 'Green';
      icon = Icons.check_circle;
    } else if (eval != null && eval.needsInspection) {
      badgeColor = Colors.orange.shade800;
      label = 'Yellow';
      icon = Icons.warning;
    } else {
      badgeColor = Colors.red.shade700;
      label = 'Red';
      icon = Icons.error;
    }

    final unrecognizedSet = eval?.unrecognizedIngredients
            .map((e) => e.toLowerCase().trim())
            .toSet() ??
        {};

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (_, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 8),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Product Details & AI Moderation',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(ctx).pop(),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(20),
                      children: [
                        Text(
                          product.name,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        if (product.brand != null &&
                            product.brand!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Brand: ${product.brand}',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: Colors.grey.shade700,
                                ),
                          ),
                        ],
                        if (product.barcode != null &&
                            product.barcode!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.qr_code,
                                  size: 16, color: Colors.grey),
                              const SizedBox(width: 6),
                              Text(
                                'Barcode: ${product.barcode}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: Colors.grey.shade600,
                                    ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: badgeColor.withAlpha(20),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: badgeColor.withAlpha(80)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(icon, color: badgeColor, size: 24),
                                  const SizedBox(width: 8),
                                  Text(
                                    eval != null
                                        ? '$label (${eval.confidenceScore}%)'
                                        : label,
                                    style: TextStyle(
                                      color: badgeColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                  const Spacer(),
                                  if (eval != null)
                                    Text(
                                      eval.isHighConfidence
                                          ? 'High Confidence'
                                          : (eval.needsInspection
                                              ? 'Needs Inspection'
                                              : 'Low Confidence'),
                                      style: TextStyle(
                                        color: badgeColor,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                ],
                              ),
                              if (eval != null) ...[
                                const SizedBox(height: 12),
                                const Divider(height: 1),
                                const SizedBox(height: 12),
                                Text(
                                  'สรุปเหตุผลการให้คะแนน (${eval.confidenceScore}%):',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                const SizedBox(height: 6),
                                ...eval.reasonSummaries.map(
                                  (reason) => Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Icon(
                                          eval.isHighConfidence
                                              ? Icons.check_circle
                                              : Icons.info_outline,
                                          size: 16,
                                          color: badgeColor,
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            reason,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              height: 1.3,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                const Divider(height: 1),
                                const SizedBox(height: 10),
                                Text(
                                  'AI Evaluation Criteria Breakdown:',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                const SizedBox(height: 8),
                                _buildCriterionRow(
                                  label: 'Product Name Length',
                                  passed: product.name.trim().length >= 3,
                                  detail: product.name.trim().length >= 3
                                      ? 'Valid (${product.name.trim().length} chars)'
                                      : 'Too short (< 3 chars, -30 pts)',
                                ),
                                const SizedBox(height: 6),
                                _buildCriterionRow(
                                  label: 'Brand Information',
                                  passed: product.brand != null &&
                                      product.brand!.trim().isNotEmpty,
                                  detail: product.brand != null &&
                                          product.brand!.trim().isNotEmpty
                                      ? 'Provided (${product.brand})'
                                      : 'Missing brand (-15 pts)',
                                ),
                                const SizedBox(height: 6),
                                _buildCriterionRow(
                                  label: 'Spam Detection',
                                  passed:
                                      !eval.flags.contains('suspected_spam'),
                                  detail: !eval.flags.contains('suspected_spam')
                                      ? 'Clean (No URL or repeated patterns)'
                                      : 'Suspected Spam (-40 pts)',
                                ),
                                const SizedBox(height: 6),
                                _buildCriterionRow(
                                  label: 'INCI Recognition Rate',
                                  passed:
                                      eval.unrecognizedIngredients.isEmpty &&
                                          product.ingredients.isNotEmpty,
                                  detail: product.ingredients.isEmpty
                                      ? 'No ingredients (-20 pts)'
                                      : '${(eval.inciMatchRate * 100).toStringAsFixed(1)}% match (${product.ingredients.length - eval.unrecognizedIngredients.length}/${product.ingredients.length} recognized)',
                                ),
                                if (eval.flags.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: eval.flags
                                        .map(
                                          (f) => Chip(
                                            label: Text(
                                              f,
                                              style: const TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600),
                                            ),
                                            backgroundColor:
                                                Colors.amber.shade100,
                                            visualDensity:
                                                VisualDensity.compact,
                                          ),
                                        )
                                        .toList(),
                                  ),
                                ],
                              ] else ...[
                                const SizedBox(height: 8),
                                const Text(
                                  'This product has not been evaluated by AI yet. Click below to analyze.',
                                  style: TextStyle(
                                      fontSize: 13, color: Colors.black87),
                                ),
                                const SizedBox(height: 8),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.of(ctx).pop();
                                    _analyzeSingleProduct(index);
                                  },
                                  icon:
                                      const Icon(Icons.auto_awesome, size: 16),
                                  label: const Text('Analyze with AI Now'),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Ingredients (${product.ingredients.length})',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            if (eval != null &&
                                eval.unrecognizedIngredients.isNotEmpty)
                              Text(
                                '${eval.unrecognizedIngredients.length} unrecognized',
                                style: TextStyle(
                                  color: Colors.orange.shade800,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (product.ingredients.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              product.rawIngredientsText ??
                                  'No ingredients provided',
                              style: const TextStyle(
                                  fontStyle: FontStyle.italic,
                                  color: Colors.grey),
                            ),
                          )
                        else
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: product.ingredients.map((ing) {
                              final isUnrecognized = unrecognizedSet
                                  .contains(ing.toLowerCase().trim());
                              return Chip(
                                avatar: Icon(
                                  isUnrecognized
                                      ? Icons.warning_amber_rounded
                                      : Icons.check_circle_outline,
                                  size: 16,
                                  color: isUnrecognized
                                      ? Colors.orange.shade900
                                      : Colors.green.shade800,
                                ),
                                label: Text(
                                  ing,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isUnrecognized
                                        ? Colors.orange.shade900
                                        : Colors.black87,
                                    fontWeight: isUnrecognized
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                                backgroundColor: isUnrecognized
                                    ? Colors.amber.shade100
                                    : Colors.green.shade50,
                                side: BorderSide(
                                  color: isUnrecognized
                                      ? Colors.amber.shade400
                                      : Colors.green.shade200,
                                ),
                              );
                            }).toList(),
                          ),
                        if (product.rawIngredientsText != null &&
                            product.rawIngredientsText!.trim().isNotEmpty &&
                            product.ingredients.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Text(
                            'Raw Ingredients Text:',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Text(
                              product.rawIngredientsText!,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(10),
                          blurRadius: 10,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: SafeArea(
                      top: false,
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.of(ctx).pop();
                                _rejectItem(item);
                              },
                              icon: const Icon(Icons.close, color: Colors.red),
                              label: const Text('Reject',
                                  style: TextStyle(color: Colors.red)),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.red),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.of(ctx).pop();
                                _approveItem(item);
                              },
                              icon: const Icon(Icons.check),
                              label: const Text('Approve'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Theme.of(context).colorScheme.primary,
                                foregroundColor:
                                    Theme.of(context).colorScheme.onPrimary,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCriterionRow({
    required String label,
    required bool passed,
    required String detail,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          passed ? Icons.check_circle : Icons.error_outline,
          size: 16,
          color: passed ? Colors.green.shade700 : Colors.orange.shade800,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
              ),
              Text(
                detail,
                style: TextStyle(
                  fontSize: 11,
                  color:
                      passed ? Colors.grey.shade700 : Colors.orange.shade900,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

