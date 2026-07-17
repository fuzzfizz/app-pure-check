import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/product.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/scan_provider.dart';

class VerifyProductScreen extends ConsumerStatefulWidget {
  final Product product;
  final VoidCallback onBack;

  const VerifyProductScreen({
    super.key,
    required this.product,
    required this.onBack,
  });

  @override
  ConsumerState<VerifyProductScreen> createState() => _VerifyProductScreenState();
}

class _VerifyProductScreenState extends ConsumerState<VerifyProductScreen> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _brandCtrl;
  late final TextEditingController _ingredientInputCtrl;
  late List<String> _ingredients;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.product.name);
    _brandCtrl = TextEditingController(text: widget.product.brand);
    _ingredientInputCtrl = TextEditingController();
    _ingredients = List<String>.from(widget.product.ingredients);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _brandCtrl.dispose();
    _ingredientInputCtrl.dispose();
    super.dispose();
  }

  void _addIngredient() {
    final text = _ingredientInputCtrl.text.trim();
    if (text.isNotEmpty && !_ingredients.contains(text)) {
      setState(() {
        _ingredients.add(text);
        _ingredientInputCtrl.clear();
      });
    }
  }

  void _removeIngredient(String name) {
    setState(() {
      _ingredients.remove(name);
    });
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(scanNotifierProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ตรวจสอบข้อมูลผลิตภัณฑ์'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBack,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'ยืนยันข้อมูลก่อนทำการวิเคราะห์',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 20),
            ),
            const SizedBox(height: 8),
            Text(
              'ตรวจสอบความถูกต้องของส่วนผสม เพื่อผลลัพธ์ที่แม่นยำที่สุด',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'ชื่อผลิตภัณฑ์ (จำเป็น)',
                hintText: 'เช่น UV Water Serum',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _brandCtrl,
              decoration: const InputDecoration(
                labelText: 'แบรนด์ (ไม่จำเป็น)',
                hintText: 'เช่น MizuMi',
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'รายชื่อส่วนผสม (${_ingredients.length})',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _ingredientInputCtrl,
              decoration: InputDecoration(
                hintText: 'พิมพ์ชื่อส่วนผสมเพื่อเพิ่ม เช่น Niacinamide',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
                  onPressed: _addIngredient,
                ),
              ),
              onSubmitted: (_) => _addIngredient(),
            ),
            const SizedBox(height: 16),
            if (_ingredients.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 32),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.mintBg),
                ),
                child: Text(
                  'ยังไม่มีส่วนผสมในรายการ\nกรุณาเพิ่มส่วนผสมเพื่อการวิเคราะห์โดย AI',
                  style: TextStyle(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _ingredients.map((ing) {
                  return Chip(
                    label: Text(ing),
                    backgroundColor: AppColors.mintBg,
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () => _removeIngredient(ing),
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
            onPressed: () {
              final name = _nameCtrl.text.trim();
              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('กรุณากรอกชื่อผลิตภัณฑ์')),
                );
                return;
              }
              final finalProd = widget.product.copyWith(
                name: name,
                brand: _brandCtrl.text.trim(),
                ingredients: _ingredients,
              );
              notifier.analyzeAndSave(finalProd);
            },
            child: const Text('วิเคราะห์ความเหมาะสมด้วย AI'),
          ),
        ),
      ),
    );
  }
}
