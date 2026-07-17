// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'PureCheck';

  @override
  String get welcome => 'Welcome';

  @override
  String get scanBarcode => 'Scan Barcode';

  @override
  String get verifyProduct => 'Verify Product';

  @override
  String get ingredients => 'Ingredients';

  @override
  String get mySkinProfile => 'My Skin Profile';

  @override
  String get scanHistory => 'Scan History';

  @override
  String get settings => 'Settings';

  @override
  String get logout => 'Logout';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get searchHint => 'Search products or ingredients...';

  @override
  String get safe => 'Safe';

  @override
  String get caution => 'Caution';

  @override
  String get danger => 'Allergen Found';
}
