// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Thai (`th`).
class AppLocalizationsTh extends AppLocalizations {
  AppLocalizationsTh([String locale = 'th']) : super(locale);

  @override
  String get appTitle => 'PureCheck';

  @override
  String get welcome => 'ยินดีต้อนรับ';

  @override
  String get scanBarcode => 'สแกนบาร์โค้ด';

  @override
  String get verifyProduct => 'ตรวจสอบผลิตภัณฑ์';

  @override
  String get ingredients => 'ส่วนผสม';

  @override
  String get mySkinProfile => 'โปรไฟล์ผิวของฉัน';

  @override
  String get scanHistory => 'ประวัติการสแกน';

  @override
  String get settings => 'การตั้งค่า';

  @override
  String get logout => 'ออกจากระบบ';

  @override
  String get save => 'บันทึก';

  @override
  String get cancel => 'ยกเลิก';

  @override
  String get searchHint => 'ค้นหาผลิตภัณฑ์หรือส่วนผสม...';

  @override
  String get safe => 'ปลอดภัย';

  @override
  String get caution => 'ควรระวัง';

  @override
  String get danger => 'พบสารที่แพ้';
}
