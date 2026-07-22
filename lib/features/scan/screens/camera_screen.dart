import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/scan_provider.dart';
import 'verify_product_screen.dart';
import 'manual_entry_screen.dart';
import 'analyzing_screen.dart';

class CameraScreen extends ConsumerStatefulWidget {
  const CameraScreen({super.key});
  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen> {
  final MobileScannerController _controller = MobileScannerController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(scanNotifierProvider.notifier).reset();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showManualBarcodeDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('ป้อนหมายเลขบาร์โค้ด'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              hintText: 'เช่น 8851234567890',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ยกเลิก'),
            ),
            TextButton(
              onPressed: () {
                final barcode = controller.text.trim();
                if (barcode.isNotEmpty) {
                  Navigator.pop(context);
                  ref.read(scanNotifierProvider.notifier).onBarcodeScanned(barcode);
                }
              },
              child: const Text('ตกลง'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scanState = ref.watch(scanNotifierProvider);
    final notifier = ref.read(scanNotifierProvider.notifier);

    // Navigation trigger when analysis completes
    ref.listen(scanNotifierProvider, (previous, next) {
      if (next.step == ScanStep.idle && next.analysisResult != null && next.product != null) {
        context.go('/result', extra: {
          'product': next.product,
          'analysis': next.analysisResult,
        });
      }
    });

    switch (scanState.step) {
      case ScanStep.idle:
      case ScanStep.scanning:
        return Scaffold(
          appBar: AppBar(
            title: const Text('สแกนบาร์โค้ด'),
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => context.pop(),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.keyboard_rounded),
                tooltip: 'ป้อนบาร์โค้ดด้วยตัวเอง',
                onPressed: () => _showManualBarcodeDialog(context),
              ),
            ],
          ),
          body: Stack(
            children: [
              MobileScanner(
                controller: _controller,
                errorBuilder: (context, error, child) {
                  return Container(
                    color: Colors.black87,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.videocam_off_rounded, color: AppColors.white, size: 64),
                            const SizedBox(height: 16),
                            const Text(
                              'ไม่สามารถเปิดกล้องได้ หรืออุปกรณ์ไม่รองรับการสแกน',
                              style: TextStyle(color: AppColors.white, fontSize: 16, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'คุณยังคงสามารถใช้ฟังก์ชันสแกนได้โดยการกรอกหมายเลขบาร์โค้ดด้วยตัวเอง',
                              style: TextStyle(color: Colors.white70, fontSize: 14),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: () => _showManualBarcodeDialog(context),
                              icon: const Icon(Icons.keyboard_rounded),
                              label: const Text('ป้อนบาร์โค้ดด้วยตัวเอง'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
                onDetect: (capture) {
                  final List<Barcode> barcodes = capture.barcodes;
                  for (final barcode in barcodes) {
                    if (barcode.rawValue != null) {
                      notifier.onBarcodeScanned(barcode.rawValue!);
                      break;
                    }
                  }
                },
              ),
              // Scanner Overlay Aiming Frame
              Center(
                child: Container(
                  width: 280,
                  height: 180,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.primary, width: 3),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              Positioned(
                bottom: 64,
                left: 24,
                right: 24,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(160),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'จ่อกล้องตรงกับบาร์โค้ดผลิตภัณฑ์เพื่อเริ่มสแกน',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.w600,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        );

      case ScanStep.fetching:
        return const Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('กำลังค้นหาข้อมูลผลิตภัณฑ์...'),
              ],
            ),
          ),
        );

      case ScanStep.verifying:
        return VerifyProductScreen(
          product: scanState.product!,
          onBack: () => notifier.reset(),
        );

      case ScanStep.manualEntry:
        return ManualEntryScreen(
          barcode: scanState.barcode ?? '',
          onBack: () => notifier.reset(),
        );

      case ScanStep.analyzing:
        return const AnalyzingScreen();

      case ScanStep.error:
        return Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.error_outline_rounded, size: 72, color: AppColors.danger),
                const SizedBox(height: 24),
                Text(
                  'เกิดข้อผิดพลาดในการวิเคราะห์',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  scanState.error ?? 'ไม่สามารถดำเนินการสแกนได้ในขณะนี้',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () => notifier.reset(),
                  child: const Text('ลองอีกครั้ง'),
                ),
              ],
            ),
          ),
        );
    }
  }
}
