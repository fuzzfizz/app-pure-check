import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_th.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('th'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In th, this message translates to:
  /// **'PureCheck'**
  String get appTitle;

  /// No description provided for @welcome.
  ///
  /// In th, this message translates to:
  /// **'ยินดีต้อนรับ'**
  String get welcome;

  /// No description provided for @hello.
  ///
  /// In th, this message translates to:
  /// **'สวัสดีครับ!'**
  String get hello;

  /// No description provided for @helloUser.
  ///
  /// In th, this message translates to:
  /// **'สวัสดีคุณ {username} 👋'**
  String helloUser(String username);

  /// No description provided for @skinProfileLabel.
  ///
  /// In th, this message translates to:
  /// **'โปรไฟล์ผิวของคุณ: ผิว{skinType}'**
  String skinProfileLabel(String skinType);

  /// No description provided for @notSpecified.
  ///
  /// In th, this message translates to:
  /// **'ไม่ระบุ'**
  String get notSpecified;

  /// No description provided for @scanBarcode.
  ///
  /// In th, this message translates to:
  /// **'สแกนบาร์โค้ด'**
  String get scanBarcode;

  /// No description provided for @verifyProduct.
  ///
  /// In th, this message translates to:
  /// **'ตรวจสอบผลิตภัณฑ์'**
  String get verifyProduct;

  /// No description provided for @ingredients.
  ///
  /// In th, this message translates to:
  /// **'ส่วนผสม'**
  String get ingredients;

  /// No description provided for @mySkinProfile.
  ///
  /// In th, this message translates to:
  /// **'โปรไฟล์ผิวของฉัน'**
  String get mySkinProfile;

  /// No description provided for @scanHistory.
  ///
  /// In th, this message translates to:
  /// **'ประวัติการสแกน'**
  String get scanHistory;

  /// No description provided for @settings.
  ///
  /// In th, this message translates to:
  /// **'การตั้งค่า'**
  String get settings;

  /// No description provided for @logout.
  ///
  /// In th, this message translates to:
  /// **'ออกจากระบบ'**
  String get logout;

  /// No description provided for @save.
  ///
  /// In th, this message translates to:
  /// **'บันทึก'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In th, this message translates to:
  /// **'ยกเลิก'**
  String get cancel;

  /// No description provided for @ok.
  ///
  /// In th, this message translates to:
  /// **'ตกลง'**
  String get ok;

  /// No description provided for @add.
  ///
  /// In th, this message translates to:
  /// **'เพิ่ม'**
  String get add;

  /// No description provided for @tryAgain.
  ///
  /// In th, this message translates to:
  /// **'ลองอีกครั้ง'**
  String get tryAgain;

  /// No description provided for @back.
  ///
  /// In th, this message translates to:
  /// **'กลับ'**
  String get back;

  /// No description provided for @searchHint.
  ///
  /// In th, this message translates to:
  /// **'ค้นหาผลิตภัณฑ์หรือส่วนผสม...'**
  String get searchHint;

  /// No description provided for @safe.
  ///
  /// In th, this message translates to:
  /// **'ปลอดภัย'**
  String get safe;

  /// No description provided for @caution.
  ///
  /// In th, this message translates to:
  /// **'ควรระวัง'**
  String get caution;

  /// No description provided for @danger.
  ///
  /// In th, this message translates to:
  /// **'พบสารที่แพ้'**
  String get danger;

  /// No description provided for @errorGeneric.
  ///
  /// In th, this message translates to:
  /// **'เกิดข้อผิดพลาด: {error}'**
  String errorGeneric(String error);

  /// No description provided for @quickAnalysis.
  ///
  /// In th, this message translates to:
  /// **'วิเคราะห์ส่วนผสมด่วน'**
  String get quickAnalysis;

  /// No description provided for @scanBarcodeHint.
  ///
  /// In th, this message translates to:
  /// **'สแกนบาร์โค้ดข้างกล่องเครื่องสำอางเพื่อเริ่มต้น'**
  String get scanBarcodeHint;

  /// No description provided for @openCameraScanner.
  ///
  /// In th, this message translates to:
  /// **'เปิดกล้องสแกน'**
  String get openCameraScanner;

  /// No description provided for @recentScanHistory.
  ///
  /// In th, this message translates to:
  /// **'ประวัติการสแกนล่าสุด'**
  String get recentScanHistory;

  /// No description provided for @viewAll.
  ///
  /// In th, this message translates to:
  /// **'ดูทั้งหมด'**
  String get viewAll;

  /// No description provided for @noScanHistory.
  ///
  /// In th, this message translates to:
  /// **'ยังไม่มีประวัติการสแกน\nกดปุ่มสแกนด้านบนเพื่อเริ่มตรวจสอบส่วนผสมผลิตภัณฑ์'**
  String get noScanHistory;

  /// No description provided for @errorLoadingData.
  ///
  /// In th, this message translates to:
  /// **'เกิดข้อผิดพลาดในการโหลดข้อมูล: {error}'**
  String errorLoadingData(String error);

  /// No description provided for @enterBarcodeManually.
  ///
  /// In th, this message translates to:
  /// **'ป้อนบาร์โค้ดด้วยตัวเอง'**
  String get enterBarcodeManually;

  /// No description provided for @enterBarcodeNumber.
  ///
  /// In th, this message translates to:
  /// **'ป้อนหมายเลขบาร์โค้ด'**
  String get enterBarcodeNumber;

  /// No description provided for @barcodeHintExample.
  ///
  /// In th, this message translates to:
  /// **'เช่น 8851234567890'**
  String get barcodeHintExample;

  /// No description provided for @cameraPermissionRequired.
  ///
  /// In th, this message translates to:
  /// **'ต้องการสิทธิ์เข้าถึงกล้อง'**
  String get cameraPermissionRequired;

  /// No description provided for @cameraPermissionDeniedPermanent.
  ///
  /// In th, this message translates to:
  /// **'คุณได้ปฏิเสธสิทธิ์กล้องแล้ว กรุณาเปิดสิทธิ์ในการตั้งค่าแอปเพื่อใช้งานสแกนบาร์โค้ด'**
  String get cameraPermissionDeniedPermanent;

  /// No description provided for @cameraPermissionNeeded.
  ///
  /// In th, this message translates to:
  /// **'แอปต้องการเข้าถึงกล้องเพื่อสแกนบาร์โค้ดของผลิตภัณฑ์'**
  String get cameraPermissionNeeded;

  /// No description provided for @openSettings.
  ///
  /// In th, this message translates to:
  /// **'เปิดการตั้งค่า'**
  String get openSettings;

  /// No description provided for @requestPermissionAgain.
  ///
  /// In th, this message translates to:
  /// **'ขอสิทธิ์อีกครั้ง'**
  String get requestPermissionAgain;

  /// No description provided for @checkingCameraPermission.
  ///
  /// In th, this message translates to:
  /// **'กำลังตรวจสอบสิทธิ์กล้อง...'**
  String get checkingCameraPermission;

  /// No description provided for @cameraError.
  ///
  /// In th, this message translates to:
  /// **'ไม่สามารถเปิดกล้องได้ หรืออุปกรณ์ไม่รองรับการสแกน'**
  String get cameraError;

  /// No description provided for @cameraFallbackHint.
  ///
  /// In th, this message translates to:
  /// **'คุณยังคงสามารถใช้ฟังก์ชันสแกนได้โดยการกรอกหมายเลขบาร์โค้ดด้วยตัวเอง'**
  String get cameraFallbackHint;

  /// No description provided for @pointCameraAtBarcode.
  ///
  /// In th, this message translates to:
  /// **'จ่อกล้องตรงกับบาร์โค้ดผลิตภัณฑ์เพื่อเริ่มสแกน'**
  String get pointCameraAtBarcode;

  /// No description provided for @searchingProduct.
  ///
  /// In th, this message translates to:
  /// **'กำลังค้นหาข้อมูลผลิตภัณฑ์...'**
  String get searchingProduct;

  /// No description provided for @analysisError.
  ///
  /// In th, this message translates to:
  /// **'เกิดข้อผิดพลาดในการวิเคราะห์'**
  String get analysisError;

  /// No description provided for @cannotScanNow.
  ///
  /// In th, this message translates to:
  /// **'ไม่สามารถดำเนินการสแกนได้ในขณะนี้'**
  String get cannotScanNow;

  /// No description provided for @verifyProductInfo.
  ///
  /// In th, this message translates to:
  /// **'ตรวจสอบข้อมูลผลิตภัณฑ์'**
  String get verifyProductInfo;

  /// No description provided for @confirmBeforeAnalysis.
  ///
  /// In th, this message translates to:
  /// **'ยืนยันข้อมูลก่อนทำการวิเคราะห์'**
  String get confirmBeforeAnalysis;

  /// No description provided for @verifyIngredientsHint.
  ///
  /// In th, this message translates to:
  /// **'ตรวจสอบความถูกต้องของส่วนผสม เพื่อผลลัพธ์ที่แม่นยำที่สุด'**
  String get verifyIngredientsHint;

  /// No description provided for @productNameRequired.
  ///
  /// In th, this message translates to:
  /// **'ชื่อผลิตภัณฑ์ (จำเป็น)'**
  String get productNameRequired;

  /// No description provided for @productNameHint.
  ///
  /// In th, this message translates to:
  /// **'เช่น UV Water Serum'**
  String get productNameHint;

  /// No description provided for @brandOptional.
  ///
  /// In th, this message translates to:
  /// **'แบรนด์ (ไม่จำเป็น)'**
  String get brandOptional;

  /// No description provided for @brandHint.
  ///
  /// In th, this message translates to:
  /// **'เช่น MizuMi'**
  String get brandHint;

  /// No description provided for @ingredientListCount.
  ///
  /// In th, this message translates to:
  /// **'รายชื่อส่วนผสม ({count})'**
  String ingredientListCount(int count);

  /// No description provided for @addIngredientHint.
  ///
  /// In th, this message translates to:
  /// **'พิมพ์ชื่อส่วนผสมเพื่อเพิ่ม เช่น Niacinamide'**
  String get addIngredientHint;

  /// No description provided for @noIngredientsYet.
  ///
  /// In th, this message translates to:
  /// **'ยังไม่มีส่วนผสมในรายการ\nกรุณาเพิ่มส่วนผสมเพื่อการวิเคราะห์โดย AI'**
  String get noIngredientsYet;

  /// No description provided for @pleaseEnterProductName.
  ///
  /// In th, this message translates to:
  /// **'กรุณากรอกชื่อผลิตภัณฑ์'**
  String get pleaseEnterProductName;

  /// No description provided for @analyzeWithAI.
  ///
  /// In th, this message translates to:
  /// **'วิเคราะห์ความเหมาะสมด้วย AI'**
  String get analyzeWithAI;

  /// No description provided for @productNotFound.
  ///
  /// In th, this message translates to:
  /// **'ไม่พบข้อมูลผลิตภัณฑ์'**
  String get productNotFound;

  /// No description provided for @barcodeNotFoundMessage.
  ///
  /// In th, this message translates to:
  /// **'ไม่พบรหัสบาร์โค้ด: {barcode} ในระบบ ท่านสามารถร่วมกรอกส่วนผสมเองเพื่อเริ่มวิเคราะห์ความเหมาะสม'**
  String barcodeNotFoundMessage(String barcode);

  /// No description provided for @allIngredientsSeparated.
  ///
  /// In th, this message translates to:
  /// **'ส่วนผสมทั้งหมด (แยกด้วยเครื่องหมายจุลภาค ,)'**
  String get allIngredientsSeparated;

  /// No description provided for @ingredientsPlaceholder.
  ///
  /// In th, this message translates to:
  /// **'Water, Niacinamide, Glycerin, Phenoxyethanol...'**
  String get ingredientsPlaceholder;

  /// No description provided for @pleaseEnterIngredients.
  ///
  /// In th, this message translates to:
  /// **'กรุณากรอกส่วนผสม'**
  String get pleaseEnterIngredients;

  /// No description provided for @doneAndContinue.
  ///
  /// In th, this message translates to:
  /// **'เสร็จสิ้นและไปขั้นตอนถัดไป'**
  String get doneAndContinue;

  /// No description provided for @loadingCopy1.
  ///
  /// In th, this message translates to:
  /// **'ดึงข้อมูลส่วนผสมของผลิตภัณฑ์...'**
  String get loadingCopy1;

  /// No description provided for @loadingCopy2.
  ///
  /// In th, this message translates to:
  /// **'กำลังวิเคราะห์ส่วนผสมเทียบกับสภาพผิวของคุณ...'**
  String get loadingCopy2;

  /// No description provided for @loadingCopy3.
  ///
  /// In th, this message translates to:
  /// **'ตรวจสอบประวัติภูมิแพ้ของคุณ...'**
  String get loadingCopy3;

  /// No description provided for @loadingCopy4.
  ///
  /// In th, this message translates to:
  /// **'วิเคราะห์ความเหมาะสมเฉพาะโปรไฟล์ของคุณ...'**
  String get loadingCopy4;

  /// No description provided for @aiAnalyzing.
  ///
  /// In th, this message translates to:
  /// **'AI กำลังทำการวิเคราะห์'**
  String get aiAnalyzing;

  /// No description provided for @referenceProfile.
  ///
  /// In th, this message translates to:
  /// **'ข้อมูลอ้างอิง: โปรไฟล์ผิว{skinType}'**
  String referenceProfile(String skinType);

  /// No description provided for @analysisResults.
  ///
  /// In th, this message translates to:
  /// **'ผลลัพธ์การวิเคราะห์'**
  String get analysisResults;

  /// No description provided for @noAnalysisResults.
  ///
  /// In th, this message translates to:
  /// **'ไม่พบข้อมูลผลลัพธ์การวิเคราะห์'**
  String get noAnalysisResults;

  /// No description provided for @suitableForSkin.
  ///
  /// In th, this message translates to:
  /// **'เหมาะสมกับผิวคุณ'**
  String get suitableForSkin;

  /// No description provided for @useWithCaution.
  ///
  /// In th, this message translates to:
  /// **'ควรระมัดระวัง'**
  String get useWithCaution;

  /// No description provided for @avoidProduct.
  ///
  /// In th, this message translates to:
  /// **'หลีกเลี่ยงผลิตภัณฑ์นี้'**
  String get avoidProduct;

  /// No description provided for @flaggedChemicals.
  ///
  /// In th, this message translates to:
  /// **'สารเคมีที่ควรระวังเป็นพิเศษ'**
  String get flaggedChemicals;

  /// No description provided for @markAsAllergen.
  ///
  /// In th, this message translates to:
  /// **'ระบุว่าฉันแพ้สารตัวนี้'**
  String get markAsAllergen;

  /// No description provided for @aiSummary.
  ///
  /// In th, this message translates to:
  /// **'สรุปผลลัพธ์โดย AI'**
  String get aiSummary;

  /// No description provided for @analyzedByGemini.
  ///
  /// In th, this message translates to:
  /// **'วิเคราะห์โดย Gemini AI'**
  String get analyzedByGemini;

  /// No description provided for @detailedBreakdown.
  ///
  /// In th, this message translates to:
  /// **'การวิเคราะห์รายละเอียดสารแยกตามตัว'**
  String get detailedBreakdown;

  /// No description provided for @noIngredientData.
  ///
  /// In th, this message translates to:
  /// **'ไม่พบข้อมูลส่วนผสมในสารระบบ'**
  String get noIngredientData;

  /// No description provided for @highRiskIngredients.
  ///
  /// In th, this message translates to:
  /// **'สารที่มีความเสี่ยงสูง (Danger)'**
  String get highRiskIngredients;

  /// No description provided for @cautionIngredients.
  ///
  /// In th, this message translates to:
  /// **'สารที่ควรระวัง (Caution)'**
  String get cautionIngredients;

  /// No description provided for @safeIngredients.
  ///
  /// In th, this message translates to:
  /// **'สารที่ปลอดภัย (Safe)'**
  String get safeIngredients;

  /// No description provided for @helpCommunity.
  ///
  /// In th, this message translates to:
  /// **'ช่วยชุมชน: ยืนยันส่งข้อมูล'**
  String get helpCommunity;

  /// No description provided for @thankYouCommunity.
  ///
  /// In th, this message translates to:
  /// **'ขอบคุณที่ร่วมยืนยันข้อมูลผลิตภัณฑ์สำหรับชุมชน!'**
  String get thankYouCommunity;

  /// No description provided for @addedAllergen.
  ///
  /// In th, this message translates to:
  /// **'เพิ่ม {name} ลงในประวัติการแพ้ของคุณแล้ว'**
  String addedAllergen(String name);

  /// No description provided for @functionProperty.
  ///
  /// In th, this message translates to:
  /// **'หน้าที่/คุณสมบัติ: {value}'**
  String functionProperty(String value);

  /// No description provided for @backToHome.
  ///
  /// In th, this message translates to:
  /// **'กลับหน้าหลัก'**
  String get backToHome;

  /// No description provided for @searchBrandsHint.
  ///
  /// In th, this message translates to:
  /// **'ค้นหาชื่อแบรนด์ ผลิตภัณฑ์ หรือสารเคมี...'**
  String get searchBrandsHint;

  /// No description provided for @tabProducts.
  ///
  /// In th, this message translates to:
  /// **'ผลิตภัณฑ์'**
  String get tabProducts;

  /// No description provided for @tabIngredients.
  ///
  /// In th, this message translates to:
  /// **'สารเคมี'**
  String get tabIngredients;

  /// No description provided for @typeToSearchProducts.
  ///
  /// In th, this message translates to:
  /// **'พิมพ์ข้อความด้านบนเพื่อค้นหาผลิตภัณฑ์'**
  String get typeToSearchProducts;

  /// No description provided for @noProductsFound.
  ///
  /// In th, this message translates to:
  /// **'ไม่พบผลิตภัณฑ์ที่ค้นหา'**
  String get noProductsFound;

  /// No description provided for @unknownBrand.
  ///
  /// In th, this message translates to:
  /// **'ไม่ระบุแบรนด์'**
  String get unknownBrand;

  /// No description provided for @typeIngredientToCheck.
  ///
  /// In th, this message translates to:
  /// **'พิมพ์ชื่อสารเคมีด้านบนเพื่อตรวจสอบประวัติการแพ้'**
  String get typeIngredientToCheck;

  /// No description provided for @language.
  ///
  /// In th, this message translates to:
  /// **'ภาษา (Language)'**
  String get language;

  /// No description provided for @displayLanguage.
  ///
  /// In th, this message translates to:
  /// **'ภาษาแสดงผล'**
  String get displayLanguage;

  /// No description provided for @helpAndSupport.
  ///
  /// In th, this message translates to:
  /// **'ความช่วยเหลือ'**
  String get helpAndSupport;

  /// No description provided for @aboutPureCheck.
  ///
  /// In th, this message translates to:
  /// **'เกี่ยวกับ PureCheck'**
  String get aboutPureCheck;

  /// No description provided for @signOut.
  ///
  /// In th, this message translates to:
  /// **'ออกจากระบบ (Sign Out)'**
  String get signOut;

  /// No description provided for @signOutFailed.
  ///
  /// In th, this message translates to:
  /// **'ออกจากระบบล้มเหลว: {error}'**
  String signOutFailed(String error);

  /// No description provided for @aboutDescription.
  ///
  /// In th, this message translates to:
  /// **'แอปวิเคราะห์ความปลอดภัยของส่วนผสมในสกินแคร์และเครื่องสำอาง เพื่อความปลอดภัยเฉพาะสภาพผิวของคุณด้วยพลัง AI'**
  String get aboutDescription;

  /// No description provided for @skinProfileAndAllergy.
  ///
  /// In th, this message translates to:
  /// **'โปรไฟล์ผิว & ประวัติการแพ้'**
  String get skinProfileAndAllergy;

  /// No description provided for @skinType.
  ///
  /// In th, this message translates to:
  /// **'ประเภทผิว'**
  String get skinType;

  /// No description provided for @skinConditions.
  ///
  /// In th, this message translates to:
  /// **'ภาวะโรคผิวหนัง/ข้อควรระวัง'**
  String get skinConditions;

  /// No description provided for @skinConcerns.
  ///
  /// In th, this message translates to:
  /// **'ความกังวลผิว'**
  String get skinConcerns;

  /// No description provided for @yourAllergens.
  ///
  /// In th, this message translates to:
  /// **'สารที่แพ้ของคุณ'**
  String get yourAllergens;

  /// No description provided for @noAllergensRecorded.
  ///
  /// In th, this message translates to:
  /// **'ไม่มีสารที่ระบุประวัติการแพ้'**
  String get noAllergensRecorded;

  /// No description provided for @addAllergen.
  ///
  /// In th, this message translates to:
  /// **'เพิ่มสารที่แพ้'**
  String get addAllergen;

  /// No description provided for @allergenNameHint.
  ///
  /// In th, this message translates to:
  /// **'ชื่อสาร เช่น Fragrance, Alcohol'**
  String get allergenNameHint;

  /// No description provided for @profileNotFound.
  ///
  /// In th, this message translates to:
  /// **'ไม่พบข้อมูลโปรไฟล์ผิว'**
  String get profileNotFound;

  /// No description provided for @skinTypePrefix.
  ///
  /// In th, this message translates to:
  /// **'ผิว'**
  String get skinTypePrefix;

  /// No description provided for @skinOily.
  ///
  /// In th, this message translates to:
  /// **'มัน'**
  String get skinOily;

  /// No description provided for @skinDry.
  ///
  /// In th, this message translates to:
  /// **'แห้ง'**
  String get skinDry;

  /// No description provided for @skinCombination.
  ///
  /// In th, this message translates to:
  /// **'ผสม'**
  String get skinCombination;

  /// No description provided for @skinNormal.
  ///
  /// In th, this message translates to:
  /// **'ธรรมดา'**
  String get skinNormal;

  /// No description provided for @skinSensitive.
  ///
  /// In th, this message translates to:
  /// **'แพ้ง่าย'**
  String get skinSensitive;

  /// No description provided for @conditionAcneProne.
  ///
  /// In th, this message translates to:
  /// **'เป็นสิวง่าย / ผิวมันเป็นสิว'**
  String get conditionAcneProne;

  /// No description provided for @conditionEczema.
  ///
  /// In th, this message translates to:
  /// **'โรคผื่นภูมิแพ้ผิวหนัง (Eczema)'**
  String get conditionEczema;

  /// No description provided for @conditionRosacea.
  ///
  /// In th, this message translates to:
  /// **'โรคผิวหนังอักเสบโรซาเชีย (Rosacea)'**
  String get conditionRosacea;

  /// No description provided for @conditionPsoriasis.
  ///
  /// In th, this message translates to:
  /// **'โรคสะเก็ดเงิน (Psoriasis)'**
  String get conditionPsoriasis;

  /// No description provided for @concernAcne.
  ///
  /// In th, this message translates to:
  /// **'สิว'**
  String get concernAcne;

  /// No description provided for @concernDarkSpots.
  ///
  /// In th, this message translates to:
  /// **'ฝ้า/จุดด่างดำ'**
  String get concernDarkSpots;

  /// No description provided for @concernWrinkles.
  ///
  /// In th, this message translates to:
  /// **'ริ้วรอย'**
  String get concernWrinkles;

  /// No description provided for @concernPores.
  ///
  /// In th, this message translates to:
  /// **'รูขุมขนกว้าง'**
  String get concernPores;

  /// No description provided for @concernDullness.
  ///
  /// In th, this message translates to:
  /// **'ผิวหมองคล้ำ'**
  String get concernDullness;

  /// No description provided for @concernRedness.
  ///
  /// In th, this message translates to:
  /// **'ผิวแดงระคายเคืองง่าย'**
  String get concernRedness;

  /// No description provided for @concernDehydrated.
  ///
  /// In th, this message translates to:
  /// **'ผิวขาดน้ำ'**
  String get concernDehydrated;

  /// No description provided for @allScanHistory.
  ///
  /// In th, this message translates to:
  /// **'ประวัติการสแกนทั้งหมด'**
  String get allScanHistory;

  /// No description provided for @noScanHistoryYet.
  ///
  /// In th, this message translates to:
  /// **'คุณยังไม่มีประวัติการสแกนผลิตภัณฑ์'**
  String get noScanHistoryYet;

  /// No description provided for @allIngredientsCount.
  ///
  /// In th, this message translates to:
  /// **'ส่วนผสมทั้งหมด ({count})'**
  String allIngredientsCount(int count);

  /// No description provided for @noIngredientInfo.
  ///
  /// In th, this message translates to:
  /// **'ไม่มีข้อมูลส่วนผสมผลิตภัณฑ์นี้'**
  String get noIngredientInfo;

  /// No description provided for @analyzeForMySkin.
  ///
  /// In th, this message translates to:
  /// **'วิเคราะห์ความเหมาะสมเฉพาะผิวฉัน'**
  String get analyzeForMySkin;

  /// No description provided for @analyzingAgainstProfile.
  ///
  /// In th, this message translates to:
  /// **'กำลังวิเคราะห์ส่วนผสมเทียบกับโปรไฟล์ของคุณ...'**
  String get analyzingAgainstProfile;

  /// No description provided for @allergyHistoryYes.
  ///
  /// In th, this message translates to:
  /// **'มีประวัติแพ้ส่วนผสมนี้'**
  String get allergyHistoryYes;

  /// No description provided for @allergyHistoryNo.
  ///
  /// In th, this message translates to:
  /// **'ปลอดภัยสำหรับคุณ (ไม่มีประวัติการแพ้)'**
  String get allergyHistoryNo;

  /// No description provided for @aboutIngredient.
  ///
  /// In th, this message translates to:
  /// **'ข้อมูลเกี่ยวกับส่วนผสม'**
  String get aboutIngredient;

  /// No description provided for @ingredientGenericInfo.
  ///
  /// In th, this message translates to:
  /// **'สารเคมีชนิดนี้มักใช้ในการเป็นสารทำละลาย สารทำความสะอาด หรือสารออกฤทธิ์ในเครื่องสำอาง ทั้งนี้ควรสังเกตการระคายเคืองผิวทุกครั้งที่เริ่มใช้ผลิตภัณฑ์ใหม่'**
  String get ingredientGenericInfo;

  /// No description provided for @login.
  ///
  /// In th, this message translates to:
  /// **'เข้าสู่ระบบ'**
  String get login;

  /// No description provided for @register.
  ///
  /// In th, this message translates to:
  /// **'สมัครสมาชิก'**
  String get register;

  /// No description provided for @email.
  ///
  /// In th, this message translates to:
  /// **'อีเมล'**
  String get email;

  /// No description provided for @password.
  ///
  /// In th, this message translates to:
  /// **'รหัสผ่าน'**
  String get password;

  /// No description provided for @confirmPassword.
  ///
  /// In th, this message translates to:
  /// **'ยืนยันรหัสผ่าน'**
  String get confirmPassword;

  /// No description provided for @forgotPassword.
  ///
  /// In th, this message translates to:
  /// **'ลืมรหัสผ่าน?'**
  String get forgotPassword;

  /// No description provided for @noAccount.
  ///
  /// In th, this message translates to:
  /// **'ยังไม่มีบัญชี?'**
  String get noAccount;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In th, this message translates to:
  /// **'มีบัญชีอยู่แล้ว?'**
  String get alreadyHaveAccount;

  /// No description provided for @registerHere.
  ///
  /// In th, this message translates to:
  /// **'สมัครที่นี่'**
  String get registerHere;

  /// No description provided for @loginHere.
  ///
  /// In th, this message translates to:
  /// **'เข้าสู่ระบบที่นี่'**
  String get loginHere;

  /// No description provided for @loginFailed.
  ///
  /// In th, this message translates to:
  /// **'เข้าสู่ระบบล้มเหลว: {error}'**
  String loginFailed(String error);

  /// No description provided for @registerFailed.
  ///
  /// In th, this message translates to:
  /// **'สมัครสมาชิกล้มเหลว: {error}'**
  String registerFailed(String error);

  /// No description provided for @passwordMismatch.
  ///
  /// In th, this message translates to:
  /// **'รหัสผ่านไม่ตรงกัน'**
  String get passwordMismatch;

  /// No description provided for @introTitle.
  ///
  /// In th, this message translates to:
  /// **'PureCheck'**
  String get introTitle;

  /// No description provided for @introSubtitle.
  ///
  /// In th, this message translates to:
  /// **'วิเคราะห์ส่วนผสมเครื่องสำอางด้วย AI'**
  String get introSubtitle;

  /// No description provided for @introDescription.
  ///
  /// In th, this message translates to:
  /// **'ตรวจสอบความปลอดภัยเฉพาะสภาพผิวของคุณ'**
  String get introDescription;

  /// No description provided for @getStarted.
  ///
  /// In th, this message translates to:
  /// **'เริ่มต้นใช้งาน'**
  String get getStarted;

  /// No description provided for @onboardingNext.
  ///
  /// In th, this message translates to:
  /// **'ถัดไป'**
  String get onboardingNext;

  /// No description provided for @onboardingBack.
  ///
  /// In th, this message translates to:
  /// **'ย้อนกลับ'**
  String get onboardingBack;

  /// No description provided for @onboardingSkip.
  ///
  /// In th, this message translates to:
  /// **'ข้าม'**
  String get onboardingSkip;

  /// No description provided for @onboardingDone.
  ///
  /// In th, this message translates to:
  /// **'เสร็จสิ้น'**
  String get onboardingDone;

  /// No description provided for @onboardingStepOf.
  ///
  /// In th, this message translates to:
  /// **'ขั้นตอน {current}/{total}'**
  String onboardingStepOf(int current, int total);

  /// No description provided for @skinTypeQuestion.
  ///
  /// In th, this message translates to:
  /// **'ผิวของคุณเป็นประเภทไหน?'**
  String get skinTypeQuestion;

  /// No description provided for @skinTypeHint.
  ///
  /// In th, this message translates to:
  /// **'เลือกประเภทผิวที่ตรงกับคุณมากที่สุด'**
  String get skinTypeHint;

  /// No description provided for @skinConditionsQuestion.
  ///
  /// In th, this message translates to:
  /// **'คุณมีภาวะผิวหนังใดเป็นพิเศษ?'**
  String get skinConditionsQuestion;

  /// No description provided for @skinConditionsHint.
  ///
  /// In th, this message translates to:
  /// **'เลือกทั้งหมดที่ตรงกับคุณ (หรือข้ามได้)'**
  String get skinConditionsHint;

  /// No description provided for @skinConcernsQuestion.
  ///
  /// In th, this message translates to:
  /// **'คุณกังวลเรื่องผิวด้านไหน?'**
  String get skinConcernsQuestion;

  /// No description provided for @skinConcernsHint.
  ///
  /// In th, this message translates to:
  /// **'เลือกทั้งหมดที่คุณสนใจ'**
  String get skinConcernsHint;

  /// No description provided for @allergensQuestion.
  ///
  /// In th, this message translates to:
  /// **'คุณมีประวัติแพ้สารเคมีในเครื่องสำอางหรือไม่?'**
  String get allergensQuestion;

  /// No description provided for @allergensHint.
  ///
  /// In th, this message translates to:
  /// **'เพิ่มสารที่คุณเคยแพ้ หรือข้ามขั้นตอนนี้ได้'**
  String get allergensHint;

  /// No description provided for @onboardingCompleteTitle.
  ///
  /// In th, this message translates to:
  /// **'พร้อมใช้งานแล้ว!'**
  String get onboardingCompleteTitle;

  /// No description provided for @onboardingCompleteMessage.
  ///
  /// In th, this message translates to:
  /// **'โปรไฟล์ของคุณถูกบันทึกเรียบร้อยแล้ว สามารถเริ่มสแกนผลิตภัณฑ์ได้เลย'**
  String get onboardingCompleteMessage;

  /// No description provided for @startUsing.
  ///
  /// In th, this message translates to:
  /// **'เริ่มใช้งาน PureCheck'**
  String get startUsing;

  /// No description provided for @pleaseEnterEmail.
  ///
  /// In th, this message translates to:
  /// **'กรุณากรอกอีเมล'**
  String get pleaseEnterEmail;

  /// No description provided for @pleaseEnterPassword.
  ///
  /// In th, this message translates to:
  /// **'กรุณากรอกรหัสผ่าน'**
  String get pleaseEnterPassword;

  /// No description provided for @pleaseConfirmPassword.
  ///
  /// In th, this message translates to:
  /// **'กรุณายืนยันรหัสผ่าน'**
  String get pleaseConfirmPassword;

  /// No description provided for @healthDisclaimer.
  ///
  /// In th, this message translates to:
  /// **'ผลการวิเคราะห์จาก AI เป็นเพียงข้อมูลประกอบการตัดสินใจเบื้องต้น ไม่สามารถทดแทนคำแนะนำทางการแพทย์หรือแพทย์ผิวหนังได้'**
  String get healthDisclaimer;

  /// No description provided for @didYouMeanTitle.
  ///
  /// In th, this message translates to:
  /// **'คุณหมายถึงส่วนผสมเหล่านี้ใช่หรือไม่?'**
  String get didYouMeanTitle;

  /// No description provided for @didYouMeanSubtitle.
  ///
  /// In th, this message translates to:
  /// **'เราพบชื่อส่วนผสมที่อาจสะกดผิด คุณต้องการใช้ชื่อมาตรฐาน INCI ที่แนะนำหรือไม่?'**
  String get didYouMeanSubtitle;

  /// No description provided for @acceptSuggestions.
  ///
  /// In th, this message translates to:
  /// **'ใช้ชื่อที่แนะนำ'**
  String get acceptSuggestions;

  /// No description provided for @keepOriginal.
  ///
  /// In th, this message translates to:
  /// **'คงชื่อเดิมไว้'**
  String get keepOriginal;

  /// No description provided for @adminReviewTitle.
  ///
  /// In th, this message translates to:
  /// **'การอนุมัติผลิตภัณฑ์สำหรับแอดมิน'**
  String get adminReviewTitle;

  /// No description provided for @pendingQueue.
  ///
  /// In th, this message translates to:
  /// **'รายการรอตรวจสอบ'**
  String get pendingQueue;

  /// No description provided for @autoApproveSafe.
  ///
  /// In th, this message translates to:
  /// **'อนุมัติอัตโนมัติรายการที่ปลอดภัย'**
  String get autoApproveSafe;

  /// No description provided for @approve.
  ///
  /// In th, this message translates to:
  /// **'อนุมัติ'**
  String get approve;

  /// No description provided for @reject.
  ///
  /// In th, this message translates to:
  /// **'ปฏิเสธ'**
  String get reject;

  /// No description provided for @confidenceScore.
  ///
  /// In th, this message translates to:
  /// **'คะแนนความเชื่อมั่น'**
  String get confidenceScore;

  /// No description provided for @noPendingProducts.
  ///
  /// In th, this message translates to:
  /// **'ไม่มีรายการผลิตภัณฑ์ที่รอตรวจสอบ'**
  String get noPendingProducts;

  /// No description provided for @username.
  ///
  /// In th, this message translates to:
  /// **'ชื่อผู้ใช้'**
  String get username;

  /// No description provided for @emailOrUsername.
  ///
  /// In th, this message translates to:
  /// **'อีเมล หรือ ชื่อผู้ใช้'**
  String get emailOrUsername;

  /// No description provided for @enterEmailOrUsername.
  ///
  /// In th, this message translates to:
  /// **'กรุณากรอกอีเมลหรือชื่อผู้ใช้'**
  String get enterEmailOrUsername;

  /// No description provided for @usernameHint.
  ///
  /// In th, this message translates to:
  /// **'เช่น user123 หรือ example@gmail.com'**
  String get usernameHint;

  /// No description provided for @invalidUsername.
  ///
  /// In th, this message translates to:
  /// **'ชื่อผู้ใช้ต้องมี 3-20 ตัวอักษร (A-Z, a-z, 0-9, _, -)'**
  String get invalidUsername;

  /// No description provided for @passwordRuleMinLength.
  ///
  /// In th, this message translates to:
  /// **'ความยาวอย่างน้อย 8 ตัวอักษร'**
  String get passwordRuleMinLength;

  /// No description provided for @passwordRuleUppercase.
  ///
  /// In th, this message translates to:
  /// **'มีตัวอักษรพิมพ์ใหญ่ (A-Z)'**
  String get passwordRuleUppercase;

  /// No description provided for @passwordRuleLowercase.
  ///
  /// In th, this message translates to:
  /// **'มีตัวอักษรพิมพ์เล็ก (a-z)'**
  String get passwordRuleLowercase;

  /// No description provided for @passwordRuleNumber.
  ///
  /// In th, this message translates to:
  /// **'มีตัวเลข (0-9)'**
  String get passwordRuleNumber;

  /// No description provided for @passwordRuleSpecialChar.
  ///
  /// In th, this message translates to:
  /// **'มีอักขระพิเศษ (เช่น !@#\$%)'**
  String get passwordRuleSpecialChar;

  /// No description provided for @userNotFound.
  ///
  /// In th, this message translates to:
  /// **'ไม่พบบัญชีผู้ใช้นี้ หรือข้อมูลไม่ถูกต้อง'**
  String get userNotFound;

  /// No description provided for @invalidPasswordRequirements.
  ///
  /// In th, this message translates to:
  /// **'รหัสผ่านไม่ตรงตามเงื่อนไขความปลอดภัย'**
  String get invalidPasswordRequirements;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'th'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'th':
      return AppLocalizationsTh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
