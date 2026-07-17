import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/product.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/loading_overlay.dart';
import '../../scan/providers/scan_provider.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final Product product;

  const ProductDetailScreen({
    super.key,
    required this.product,
  });

  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  bool _loading = false;

  Future<void> _analyzeProduct() async {
    setState(() => _loading = true);
    try {
      final scanNotifier = ref.read(scanNotifierProvider.notifier);
      final result = await scanNotifier.analyzeAndSave(widget.product);
      
      if (result != null && mounted) {
        context.go('/result', extra: {
          'product': widget.product,
          'analysis': result,
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: Text(widget.product.name),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (widget.product.imageUrl != null) ...[
                  Center(
                    child: Container(
                      height: 180,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: AppColors.white,
                      ),
                      child: Image.network(
                        widget.product.imageUrl!,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_rounded, size: 64),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                Text(
                  widget.product.name,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                if (widget.product.brand != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    widget.product.brand!,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
                  ),
                ],
                const SizedBox(height: 28),
                Text(
                  'ส่วนผสมทั้งหมด (${widget.product.ingredients.length})',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                if (widget.product.ingredients.isEmpty)
                  Text(
                    'ไม่มีข้อมูลส่วนผสมผลิตภัณฑ์นี้',
                    style: TextStyle(color: AppColors.textHint, fontStyle: FontStyle.italic),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: widget.product.ingredients.map((ing) {
                      return Chip(
                        label: Text(ing),
                        backgroundColor: AppColors.mintBg,
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: ElevatedButton(
                onPressed: _analyzeProduct,
                child: const Text('วิเคราะห์ความเหมาะสมเฉพาะผิวฉัน'),
              ),
            ),
          ),
        ),
        if (_loading)
          const LoadingOverlay(message: 'กำลังวิเคราะห์ส่วนผสมเทียบกับโปรไฟล์ของคุณ...'),
      ],
    );
  }
}
