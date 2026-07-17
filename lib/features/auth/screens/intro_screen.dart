import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';

class _Slide {
  final String title;
  final String subtitle;
  final IconData icon;
  const _Slide(this.title, this.subtitle, this.icon);
}

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});
  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  final _controller = PageController();
  int _page = 0;

  final _slides = const [
    _Slide('สแกนแล้วรู้ว่าแพ้ไหม', 'สแกนบาร์โค้ดผลิตภัณฑ์ รู้ส่วนผสมทันที', Icons.qr_code_scanner_rounded),
    _Slide('AI วิเคราะห์เฉพาะคุณ', 'ผลวิเคราะห์ปรับตามโปรไฟล์ผิวและประวัติการแพ้ของคุณ', Icons.auto_awesome_rounded),
    _Slide('ส่วนผสมครบ ตรงไปตรงมา', 'ข้อมูลส่วนผสมชัดเจน พร้อมคำอธิบายเข้าใจง่าย', Icons.science_rounded),
  ];

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, i) {
                  final s = _slides[i];
                  return Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 120, height: 120,
                          decoration: BoxDecoration(
                            color: AppColors.mintBg,
                            borderRadius: BorderRadius.circular(32),
                          ),
                          child: Icon(s.icon, size: 64, color: AppColors.primary),
                        ),
                        const SizedBox(height: 40),
                        Text(s.title,
                          style: Theme.of(context).textTheme.displayLarge,
                          textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        Text(s.subtitle,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
                          textAlign: TextAlign.center),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_slides.length, (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.all(4),
                width: i == _page ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: i == _page ? AppColors.primary : AppColors.textHint,
                  borderRadius: BorderRadius.circular(4),
                ),
              )),
            ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ElevatedButton(
                onPressed: () => context.go('/register'),
                child: const Text('เริ่มต้นใช้งาน'),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => context.go('/login'),
              child: const Text('มีบัญชีแล้ว? เข้าสู่ระบบ'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
