import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/l10n/app_localizations.dart';
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

enum _CameraPermissionStatus { checking, granted, denied, permanentlyDenied }

class _CameraScreenState extends ConsumerState<CameraScreen>
    with WidgetsBindingObserver {
  MobileScannerController? _controller;
  _CameraPermissionStatus _permissionStatus = _CameraPermissionStatus.checking;
  bool _isReturningFromSettings = false;
  bool _isTorchOn = false;


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkAndRequestPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // When returning from settings, re-check permission
    if (state == AppLifecycleState.resumed) {
      if (_isReturningFromSettings) {
        _isReturningFromSettings = false;
        _checkAndRequestPermission();
      } else if (_permissionStatus == _CameraPermissionStatus.granted) {
        _controller?.start();
      }
    } else if (state == AppLifecycleState.paused) {
      _controller?.stop();
    }
  }


  Future<void> _checkAndRequestPermission() async {
    if (!mounted) return;

    setState(() {
      _permissionStatus = _CameraPermissionStatus.checking;
    });

    final status = await Permission.camera.status;

    if (status.isGranted) {
      _onPermissionGranted();
      return;
    }

    if (status.isPermanentlyDenied) {
      if (mounted) {
        setState(() {
          _permissionStatus = _CameraPermissionStatus.permanentlyDenied;
        });
      }
      return;
    }

    // Request permission
    final result = await Permission.camera.request();

    if (!mounted) return;

    if (result.isGranted) {
      _onPermissionGranted();
    } else if (result.isPermanentlyDenied) {
      setState(() {
        _permissionStatus = _CameraPermissionStatus.permanentlyDenied;
      });
    } else {
      setState(() {
        _permissionStatus = _CameraPermissionStatus.denied;
      });
    }
  }

  void _onPermissionGranted() {
    if (!mounted) return;

    // Only create the controller once permission is granted
    _controller ??= MobileScannerController(
      autoStart: true,
      detectionSpeed: DetectionSpeed.normal,
    );

    setState(() {
      _permissionStatus = _CameraPermissionStatus.granted;
    });
  }

  Future<void> _openSettings() async {
    _isReturningFromSettings = true;
    await openAppSettings();
  }

  void _showManualBarcodeDialog(BuildContext context, AppLocalizations l10n) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.enterBarcodeNumber),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: l10n.barcodeHintExample,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () {
                final barcode = controller.text.trim();
                if (barcode.isNotEmpty) {
                  Navigator.pop(context);
                  ref.read(scanNotifierProvider.notifier).onBarcodeScanned(barcode);
                }
              },
              child: Text(l10n.ok),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPermissionDeniedUI({required bool isPermanent, required AppLocalizations l10n}) {
    return Container(
      color: Colors.black87,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(30),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.camera_alt_rounded,
                  color: AppColors.primary,
                  size: 64,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                l10n.cameraPermissionRequired,
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                isPermanent
                    ? l10n.cameraPermissionDeniedPermanent
                    : l10n.cameraPermissionNeeded,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              if (isPermanent)
                ElevatedButton.icon(
                  onPressed: _openSettings,
                  icon: const Icon(Icons.settings_rounded),
                  label: Text(l10n.openSettings),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                )
              else
                ElevatedButton.icon(
                  onPressed: _checkAndRequestPermission,
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(l10n.requestPermissionAgain),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => _showManualBarcodeDialog(context, l10n),
                icon: const Icon(Icons.keyboard_rounded),
                label: Text(l10n.enterBarcodeManually),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white54),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
            title: Text(l10n.scanBarcode),
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => context.pop(),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.keyboard_rounded),
                tooltip: l10n.enterBarcodeManually,
                onPressed: () => _showManualBarcodeDialog(context, l10n),
              ),
            ],
          ),
          body: _buildScannerBody(notifier, l10n),
        );

      case ScanStep.fetching:
        return Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(l10n.searchingProduct),
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
                  l10n.analysisError,
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  scanState.error ?? l10n.cannotScanNow,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () => notifier.reset(),
                  child: Text(l10n.tryAgain),
                ),
              ],
            ),
          ),
        );
    }
  }

  Widget _buildScannerBody(ScanNotifier notifier, AppLocalizations l10n) {
    switch (_permissionStatus) {
      case _CameraPermissionStatus.checking:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(l10n.checkingCameraPermission),
            ],
          ),
        );

      case _CameraPermissionStatus.denied:
        return _buildPermissionDeniedUI(isPermanent: false, l10n: l10n);

      case _CameraPermissionStatus.permanentlyDenied:
        return _buildPermissionDeniedUI(isPermanent: true, l10n: l10n);

      case _CameraPermissionStatus.granted:
        return Stack(
          children: [
            MobileScanner(
              controller: _controller!,
              errorBuilder: (context, error, child) {
                debugPrint('MobileScanner error: ${error.errorCode} - ${error.errorDetails?.message}');
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
                          Text(
                            l10n.cameraError,
                            style: const TextStyle(color: AppColors.white, fontSize: 16, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.cameraFallbackHint,
                            style: const TextStyle(color: Colors.white70, fontSize: 14),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              ElevatedButton.icon(
                                onPressed: () => _controller?.switchCamera(),
                                icon: const Icon(Icons.cameraswitch_rounded),
                                label: const Text('สลับกล้อง / Switch Camera'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                              OutlinedButton.icon(
                                onPressed: () => _showManualBarcodeDialog(context, l10n),
                                icon: const Icon(Icons.keyboard_rounded),
                                label: Text(l10n.enterBarcodeManually),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: const BorderSide(color: Colors.white54),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ],
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
            // Top Controls (Torch & Camera Switch)
            Positioned(
              top: 16,
              right: 16,
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      _isTorchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                      color: _isTorchOn ? Colors.amber : Colors.white,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black54,
                    ),
                    onPressed: () {
                      _controller?.toggleTorch();
                      setState(() {
                        _isTorchOn = !_isTorchOn;
                      });
                    },
                  ),

                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.cameraswitch_rounded, color: Colors.white),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black54,
                    ),
                    onPressed: () => _controller?.switchCamera(),
                  ),
                ],
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
                  l10n.pointCameraAtBarcode,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w600,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        );

    }
  }
}
