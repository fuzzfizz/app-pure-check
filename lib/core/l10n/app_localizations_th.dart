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
  String get hello => 'สวัสดีครับ!';

  @override
  String helloUser(String username) {
    return 'สวัสดีคุณ $username 👋';
  }

  @override
  String skinProfileLabel(String skinType) {
    return 'โปรไฟล์ผิวของคุณ: ผิว$skinType';
  }

  @override
  String get notSpecified => 'ไม่ระบุ';

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
  String get ok => 'ตกลง';

  @override
  String get add => 'เพิ่ม';

  @override
  String get tryAgain => 'ลองอีกครั้ง';

  @override
  String get back => 'กลับ';

  @override
  String get searchHint => 'ค้นหาผลิตภัณฑ์หรือส่วนผสม...';

  @override
  String get safe => 'ปลอดภัย';

  @override
  String get caution => 'ควรระวัง';

  @override
  String get danger => 'พบสารที่แพ้';

  @override
  String errorGeneric(String error) {
    return 'เกิดข้อผิดพลาด: $error';
  }

  @override
  String get quickAnalysis => 'วิเคราะห์ส่วนผสมด่วน';

  @override
  String get scanBarcodeHint =>
      'สแกนบาร์โค้ดข้างกล่องเครื่องสำอางเพื่อเริ่มต้น';

  @override
  String get openCameraScanner => 'เปิดกล้องสแกน';

  @override
  String get recentScanHistory => 'ประวัติการสแกนล่าสุด';

  @override
  String get viewAll => 'ดูทั้งหมด';

  @override
  String get noScanHistory =>
      'ยังไม่มีประวัติการสแกน\nกดปุ่มสแกนด้านบนเพื่อเริ่มตรวจสอบส่วนผสมผลิตภัณฑ์';

  @override
  String errorLoadingData(String error) {
    return 'เกิดข้อผิดพลาดในการโหลดข้อมูล: $error';
  }

  @override
  String get enterBarcodeManually => 'ป้อนบาร์โค้ดด้วยตัวเอง';

  @override
  String get enterBarcodeNumber => 'ป้อนหมายเลขบาร์โค้ด';

  @override
  String get barcodeHintExample => 'เช่น 8851234567890';

  @override
  String get cameraPermissionRequired => 'ต้องการสิทธิ์เข้าถึงกล้อง';

  @override
  String get cameraPermissionDeniedPermanent =>
      'คุณได้ปฏิเสธสิทธิ์กล้องแล้ว กรุณาเปิดสิทธิ์ในการตั้งค่าแอปเพื่อใช้งานสแกนบาร์โค้ด';

  @override
  String get cameraPermissionNeeded =>
      'แอปต้องการเข้าถึงกล้องเพื่อสแกนบาร์โค้ดของผลิตภัณฑ์';

  @override
  String get openSettings => 'เปิดการตั้งค่า';

  @override
  String get requestPermissionAgain => 'ขอสิทธิ์อีกครั้ง';

  @override
  String get checkingCameraPermission => 'กำลังตรวจสอบสิทธิ์กล้อง...';

  @override
  String get cameraError => 'ไม่สามารถเปิดกล้องได้ หรืออุปกรณ์ไม่รองรับการสแกน';

  @override
  String get cameraFallbackHint =>
      'คุณยังคงสามารถใช้ฟังก์ชันสแกนได้โดยการกรอกหมายเลขบาร์โค้ดด้วยตัวเอง';

  @override
  String get pointCameraAtBarcode =>
      'จ่อกล้องตรงกับบาร์โค้ดผลิตภัณฑ์เพื่อเริ่มสแกน';

  @override
  String get searchingProduct => 'กำลังค้นหาข้อมูลผลิตภัณฑ์...';

  @override
  String get analysisError => 'เกิดข้อผิดพลาดในการวิเคราะห์';

  @override
  String get cannotScanNow => 'ไม่สามารถดำเนินการสแกนได้ในขณะนี้';

  @override
  String get verifyProductInfo => 'ตรวจสอบข้อมูลผลิตภัณฑ์';

  @override
  String get confirmBeforeAnalysis => 'ยืนยันข้อมูลก่อนทำการวิเคราะห์';

  @override
  String get verifyIngredientsHint =>
      'ตรวจสอบความถูกต้องของส่วนผสม เพื่อผลลัพธ์ที่แม่นยำที่สุด';

  @override
  String get productNameRequired => 'ชื่อผลิตภัณฑ์ (จำเป็น)';

  @override
  String get productNameHint => 'เช่น UV Water Serum';

  @override
  String get brandOptional => 'แบรนด์ (ไม่จำเป็น)';

  @override
  String get brandHint => 'เช่น MizuMi';

  @override
  String ingredientListCount(int count) {
    return 'รายชื่อส่วนผสม ($count)';
  }

  @override
  String get addIngredientHint => 'พิมพ์ชื่อส่วนผสมเพื่อเพิ่ม เช่น Niacinamide';

  @override
  String get noIngredientsYet =>
      'ยังไม่มีส่วนผสมในรายการ\nกรุณาเพิ่มส่วนผสมเพื่อการวิเคราะห์โดย AI';

  @override
  String get pleaseEnterProductName => 'กรุณากรอกชื่อผลิตภัณฑ์';

  @override
  String get analyzeWithAI => 'วิเคราะห์ความเหมาะสมด้วย AI';

  @override
  String get productNotFound => 'ไม่พบข้อมูลผลิตภัณฑ์';

  @override
  String barcodeNotFoundMessage(String barcode) {
    return 'ไม่พบรหัสบาร์โค้ด: $barcode ในระบบ ท่านสามารถร่วมกรอกส่วนผสมเองเพื่อเริ่มวิเคราะห์ความเหมาะสม';
  }

  @override
  String get allIngredientsSeparated =>
      'ส่วนผสมทั้งหมด (แยกด้วยเครื่องหมายจุลภาค ,)';

  @override
  String get ingredientsPlaceholder =>
      'Water, Niacinamide, Glycerin, Phenoxyethanol...';

  @override
  String get pleaseEnterIngredients => 'กรุณากรอกส่วนผสม';

  @override
  String get doneAndContinue => 'เสร็จสิ้นและไปขั้นตอนถัดไป';

  @override
  String get loadingCopy1 => 'ดึงข้อมูลส่วนผสมของผลิตภัณฑ์...';

  @override
  String get loadingCopy2 => 'กำลังวิเคราะห์ส่วนผสมเทียบกับสภาพผิวของคุณ...';

  @override
  String get loadingCopy3 => 'ตรวจสอบประวัติภูมิแพ้ของคุณ...';

  @override
  String get loadingCopy4 => 'วิเคราะห์ความเหมาะสมเฉพาะโปรไฟล์ของคุณ...';

  @override
  String get aiAnalyzing => 'AI กำลังทำการวิเคราะห์';

  @override
  String referenceProfile(String skinType) {
    return 'ข้อมูลอ้างอิง: โปรไฟล์ผิว$skinType';
  }

  @override
  String get analysisResults => 'ผลลัพธ์การวิเคราะห์';

  @override
  String get noAnalysisResults => 'ไม่พบข้อมูลผลลัพธ์การวิเคราะห์';

  @override
  String get suitableForSkin => 'เหมาะสมกับผิวคุณ';

  @override
  String get useWithCaution => 'ควรระมัดระวัง';

  @override
  String get avoidProduct => 'หลีกเลี่ยงผลิตภัณฑ์นี้';

  @override
  String get flaggedChemicals => 'สารเคมีที่ควรระวังเป็นพิเศษ';

  @override
  String get markAsAllergen => 'ระบุว่าฉันแพ้สารตัวนี้';

  @override
  String get aiSummary => 'สรุปผลลัพธ์โดย AI';

  @override
  String get analyzedByGemini => 'วิเคราะห์โดย Gemini AI';

  @override
  String get detailedBreakdown => 'การวิเคราะห์รายละเอียดสารแยกตามตัว';

  @override
  String get noIngredientData => 'ไม่พบข้อมูลส่วนผสมในสารระบบ';

  @override
  String get highRiskIngredients => 'สารที่มีความเสี่ยงสูง (Danger)';

  @override
  String get cautionIngredients => 'สารที่ควรระวัง (Caution)';

  @override
  String get safeIngredients => 'สารที่ปลอดภัย (Safe)';

  @override
  String get helpCommunity => 'ช่วยชุมชน: ยืนยันส่งข้อมูล';

  @override
  String get thankYouCommunity =>
      'ขอบคุณที่ร่วมยืนยันข้อมูลผลิตภัณฑ์สำหรับชุมชน!';

  @override
  String addedAllergen(String name) {
    return 'เพิ่ม $name ลงในประวัติการแพ้ของคุณแล้ว';
  }

  @override
  String functionProperty(String value) {
    return 'หน้าที่/คุณสมบัติ: $value';
  }

  @override
  String get backToHome => 'กลับหน้าหลัก';

  @override
  String get searchBrandsHint => 'ค้นหาชื่อแบรนด์ ผลิตภัณฑ์ หรือสารเคมี...';

  @override
  String get tabProducts => 'ผลิตภัณฑ์';

  @override
  String get tabIngredients => 'สารเคมี';

  @override
  String get typeToSearchProducts => 'พิมพ์ข้อความด้านบนเพื่อค้นหาผลิตภัณฑ์';

  @override
  String get noProductsFound => 'ไม่พบผลิตภัณฑ์ที่ค้นหา';

  @override
  String get unknownBrand => 'ไม่ระบุแบรนด์';

  @override
  String get typeIngredientToCheck =>
      'พิมพ์ชื่อสารเคมีด้านบนเพื่อตรวจสอบประวัติการแพ้';

  @override
  String get language => 'ภาษา (Language)';

  @override
  String get displayLanguage => 'ภาษาแสดงผล';

  @override
  String get helpAndSupport => 'ความช่วยเหลือ';

  @override
  String get aboutPureCheck => 'เกี่ยวกับ PureCheck';

  @override
  String get signOut => 'ออกจากระบบ (Sign Out)';

  @override
  String signOutFailed(String error) {
    return 'ออกจากระบบล้มเหลว: $error';
  }

  @override
  String get aboutDescription =>
      'แอปวิเคราะห์ความปลอดภัยของส่วนผสมในสกินแคร์และเครื่องสำอาง เพื่อความปลอดภัยเฉพาะสภาพผิวของคุณด้วยพลัง AI';

  @override
  String get skinProfileAndAllergy => 'โปรไฟล์ผิว & ประวัติการแพ้';

  @override
  String get skinType => 'ประเภทผิว';

  @override
  String get skinConditions => 'ภาวะโรคผิวหนัง/ข้อควรระวัง';

  @override
  String get skinConcerns => 'ความกังวลผิว';

  @override
  String get yourAllergens => 'สารที่แพ้ของคุณ';

  @override
  String get noAllergensRecorded => 'ไม่มีสารที่ระบุประวัติการแพ้';

  @override
  String get addAllergen => 'เพิ่มสารที่แพ้';

  @override
  String get allergenNameHint => 'ชื่อสาร เช่น Fragrance, Alcohol';

  @override
  String get profileNotFound => 'ไม่พบข้อมูลโปรไฟล์ผิว';

  @override
  String get skinTypePrefix => 'ผิว';

  @override
  String get skinOily => 'มัน';

  @override
  String get skinDry => 'แห้ง';

  @override
  String get skinCombination => 'ผสม';

  @override
  String get skinNormal => 'ธรรมดา';

  @override
  String get skinSensitive => 'แพ้ง่าย';

  @override
  String get conditionAcneProne => 'เป็นสิวง่าย / ผิวมันเป็นสิว';

  @override
  String get conditionEczema => 'โรคผื่นภูมิแพ้ผิวหนัง (Eczema)';

  @override
  String get conditionRosacea => 'โรคผิวหนังอักเสบโรซาเชีย (Rosacea)';

  @override
  String get conditionPsoriasis => 'โรคสะเก็ดเงิน (Psoriasis)';

  @override
  String get concernAcne => 'สิว';

  @override
  String get concernDarkSpots => 'ฝ้า/จุดด่างดำ';

  @override
  String get concernWrinkles => 'ริ้วรอย';

  @override
  String get concernPores => 'รูขุมขนกว้าง';

  @override
  String get concernDullness => 'ผิวหมองคล้ำ';

  @override
  String get concernRedness => 'ผิวแดงระคายเคืองง่าย';

  @override
  String get concernDehydrated => 'ผิวขาดน้ำ';

  @override
  String get allScanHistory => 'ประวัติการสแกนทั้งหมด';

  @override
  String get noScanHistoryYet => 'คุณยังไม่มีประวัติการสแกนผลิตภัณฑ์';

  @override
  String allIngredientsCount(int count) {
    return 'ส่วนผสมทั้งหมด ($count)';
  }

  @override
  String get noIngredientInfo => 'ไม่มีข้อมูลส่วนผสมผลิตภัณฑ์นี้';

  @override
  String get analyzeForMySkin => 'วิเคราะห์ความเหมาะสมเฉพาะผิวฉัน';

  @override
  String get analyzingAgainstProfile =>
      'กำลังวิเคราะห์ส่วนผสมเทียบกับโปรไฟล์ของคุณ...';

  @override
  String get allergyHistoryYes => 'มีประวัติแพ้ส่วนผสมนี้';

  @override
  String get allergyHistoryNo => 'ปลอดภัยสำหรับคุณ (ไม่มีประวัติการแพ้)';

  @override
  String get aboutIngredient => 'ข้อมูลเกี่ยวกับส่วนผสม';

  @override
  String get ingredientGenericInfo =>
      'สารเคมีชนิดนี้มักใช้ในการเป็นสารทำละลาย สารทำความสะอาด หรือสารออกฤทธิ์ในเครื่องสำอาง ทั้งนี้ควรสังเกตการระคายเคืองผิวทุกครั้งที่เริ่มใช้ผลิตภัณฑ์ใหม่';

  @override
  String get login => 'เข้าสู่ระบบ';

  @override
  String get register => 'สมัครสมาชิก';

  @override
  String get email => 'อีเมล';

  @override
  String get password => 'รหัสผ่าน';

  @override
  String get confirmPassword => 'ยืนยันรหัสผ่าน';

  @override
  String get forgotPassword => 'ลืมรหัสผ่าน?';

  @override
  String get noAccount => 'ยังไม่มีบัญชี?';

  @override
  String get alreadyHaveAccount => 'มีบัญชีอยู่แล้ว?';

  @override
  String get registerHere => 'สมัครที่นี่';

  @override
  String get loginHere => 'เข้าสู่ระบบที่นี่';

  @override
  String loginFailed(String error) {
    return 'เข้าสู่ระบบล้มเหลว: $error';
  }

  @override
  String registerFailed(String error) {
    return 'สมัครสมาชิกล้มเหลว: $error';
  }

  @override
  String get passwordMismatch => 'รหัสผ่านไม่ตรงกัน';

  @override
  String get introTitle => 'PureCheck';

  @override
  String get introSubtitle => 'วิเคราะห์ส่วนผสมเครื่องสำอางด้วย AI';

  @override
  String get introDescription => 'ตรวจสอบความปลอดภัยเฉพาะสภาพผิวของคุณ';

  @override
  String get getStarted => 'เริ่มต้นใช้งาน';

  @override
  String get onboardingNext => 'ถัดไป';

  @override
  String get onboardingBack => 'ย้อนกลับ';

  @override
  String get onboardingSkip => 'ข้าม';

  @override
  String get onboardingDone => 'เสร็จสิ้น';

  @override
  String onboardingStepOf(int current, int total) {
    return 'ขั้นตอน $current/$total';
  }

  @override
  String get skinTypeQuestion => 'ผิวของคุณเป็นประเภทไหน?';

  @override
  String get skinTypeHint => 'เลือกประเภทผิวที่ตรงกับคุณมากที่สุด';

  @override
  String get skinConditionsQuestion => 'คุณมีภาวะผิวหนังใดเป็นพิเศษ?';

  @override
  String get skinConditionsHint => 'เลือกทั้งหมดที่ตรงกับคุณ (หรือข้ามได้)';

  @override
  String get skinConcernsQuestion => 'คุณกังวลเรื่องผิวด้านไหน?';

  @override
  String get skinConcernsHint => 'เลือกทั้งหมดที่คุณสนใจ';

  @override
  String get allergensQuestion =>
      'คุณมีประวัติแพ้สารเคมีในเครื่องสำอางหรือไม่?';

  @override
  String get allergensHint => 'เพิ่มสารที่คุณเคยแพ้ หรือข้ามขั้นตอนนี้ได้';

  @override
  String get onboardingCompleteTitle => 'พร้อมใช้งานแล้ว!';

  @override
  String get onboardingCompleteMessage =>
      'โปรไฟล์ของคุณถูกบันทึกเรียบร้อยแล้ว สามารถเริ่มสแกนผลิตภัณฑ์ได้เลย';

  @override
  String get startUsing => 'เริ่มใช้งาน PureCheck';

  @override
  String get pleaseEnterEmail => 'กรุณากรอกอีเมล';

  @override
  String get pleaseEnterPassword => 'กรุณากรอกรหัสผ่าน';

  @override
  String get pleaseConfirmPassword => 'กรุณายืนยันรหัสผ่าน';

  @override
  String get healthDisclaimer =>
      'ผลการวิเคราะห์จาก AI เป็นเพียงข้อมูลประกอบการตัดสินใจเบื้องต้น ไม่สามารถทดแทนคำแนะนำทางการแพทย์หรือแพทย์ผิวหนังได้';

  @override
  String get didYouMeanTitle => 'คุณหมายถึงส่วนผสมเหล่านี้ใช่หรือไม่?';

  @override
  String get didYouMeanSubtitle =>
      'เราพบชื่อส่วนผสมที่อาจสะกดผิด คุณต้องการใช้ชื่อมาตรฐาน INCI ที่แนะนำหรือไม่?';

  @override
  String get acceptSuggestions => 'ใช้ชื่อที่แนะนำ';

  @override
  String get keepOriginal => 'คงชื่อเดิมไว้';

  @override
  String get adminReviewTitle => 'การอนุมัติผลิตภัณฑ์สำหรับแอดมิน';

  @override
  String get pendingQueue => 'รายการรอตรวจสอบ';

  @override
  String get autoApproveSafe => 'อนุมัติอัตโนมัติรายการที่ปลอดภัย';

  @override
  String get approve => 'อนุมัติ';

  @override
  String get reject => 'ปฏิเสธ';

  @override
  String get confidenceScore => 'คะแนนความเชื่อมั่น';

  @override
  String get noPendingProducts => 'ไม่มีรายการผลิตภัณฑ์ที่รอตรวจสอบ';

  @override
  String get username => 'ชื่อผู้ใช้';

  @override
  String get emailOrUsername => 'อีเมล หรือ ชื่อผู้ใช้';

  @override
  String get enterEmailOrUsername => 'กรุณากรอกอีเมลหรือชื่อผู้ใช้';

  @override
  String get usernameHint => 'เช่น user123 หรือ example@gmail.com';

  @override
  String get invalidUsername =>
      'ชื่อผู้ใช้ต้องมี 3-20 ตัวอักษร (A-Z, a-z, 0-9, _, -)';

  @override
  String get passwordRuleMinLength => 'ความยาวอย่างน้อย 8 ตัวอักษร';

  @override
  String get passwordRuleUppercase => 'มีตัวอักษรพิมพ์ใหญ่ (A-Z)';

  @override
  String get passwordRuleLowercase => 'มีตัวอักษรพิมพ์เล็ก (a-z)';

  @override
  String get passwordRuleNumber => 'มีตัวเลข (0-9)';

  @override
  String get passwordRuleSpecialChar => 'มีอักขระพิเศษ (เช่น !@#\$%)';

  @override
  String get userNotFound => 'ไม่พบบัญชีผู้ใช้นี้ หรือข้อมูลไม่ถูกต้อง';

  @override
  String get invalidPasswordRequirements =>
      'รหัสผ่านไม่ตรงตามเงื่อนไขความปลอดภัย';
}
