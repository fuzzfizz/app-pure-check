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
  String get hello => 'Hello!';

  @override
  String skinProfileLabel(String skinType) {
    return 'Your Skin Profile: $skinType';
  }

  @override
  String get notSpecified => 'Not specified';

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
  String get ok => 'OK';

  @override
  String get add => 'Add';

  @override
  String get tryAgain => 'Try Again';

  @override
  String get back => 'Back';

  @override
  String get searchHint => 'Search products or ingredients...';

  @override
  String get safe => 'Safe';

  @override
  String get caution => 'Caution';

  @override
  String get danger => 'Allergen Found';

  @override
  String errorGeneric(String error) {
    return 'Error occurred: $error';
  }

  @override
  String get quickAnalysis => 'Quick Ingredient Analysis';

  @override
  String get scanBarcodeHint =>
      'Scan the barcode on the product packaging to start';

  @override
  String get openCameraScanner => 'Open Camera Scanner';

  @override
  String get recentScanHistory => 'Recent Scan History';

  @override
  String get viewAll => 'View All';

  @override
  String get noScanHistory =>
      'No scan history yet\nTap the scan button above to start verifying product ingredients';

  @override
  String errorLoadingData(String error) {
    return 'Error loading data: $error';
  }

  @override
  String get enterBarcodeManually => 'Enter Barcode Manually';

  @override
  String get enterBarcodeNumber => 'Enter Barcode Number';

  @override
  String get barcodeHintExample => 'e.g., 8851234567890';

  @override
  String get cameraPermissionRequired => 'Camera Permission Required';

  @override
  String get cameraPermissionDeniedPermanent =>
      'Camera permission was permanently denied. Please enable it in the app settings to use the barcode scanner.';

  @override
  String get cameraPermissionNeeded =>
      'The app needs camera access to scan product barcodes.';

  @override
  String get openSettings => 'Open Settings';

  @override
  String get requestPermissionAgain => 'Request Again';

  @override
  String get checkingCameraPermission => 'Checking camera permission...';

  @override
  String get cameraError =>
      'Unable to open camera or device is not supported for scanning';

  @override
  String get cameraFallbackHint =>
      'You can still use the scanning feature by entering the barcode number manually';

  @override
  String get pointCameraAtBarcode =>
      'Point the camera at the product barcode to start scanning';

  @override
  String get searchingProduct => 'Searching for product info...';

  @override
  String get analysisError => 'Analysis Error';

  @override
  String get cannotScanNow => 'Cannot perform scan at this moment';

  @override
  String get verifyProductInfo => 'Verify Product Info';

  @override
  String get confirmBeforeAnalysis => 'Confirm Info Before Analysis';

  @override
  String get verifyIngredientsHint =>
      'Verify ingredient accuracy for the most precise AI analysis';

  @override
  String get productNameRequired => 'Product Name (Required)';

  @override
  String get productNameHint => 'e.g., UV Water Serum';

  @override
  String get brandOptional => 'Brand (Optional)';

  @override
  String get brandHint => 'e.g., MizuMi';

  @override
  String ingredientListCount(int count) {
    return 'Ingredient List ($count)';
  }

  @override
  String get addIngredientHint =>
      'Type ingredient name to add, e.g., Niacinamide';

  @override
  String get noIngredientsYet =>
      'No ingredients in the list\nPlease add ingredients for AI analysis';

  @override
  String get pleaseEnterProductName => 'Please enter a product name';

  @override
  String get analyzeWithAI => 'Analyze Suitability with AI';

  @override
  String get productNotFound => 'Product Not Found';

  @override
  String barcodeNotFoundMessage(String barcode) {
    return 'Barcode: $barcode not found in the system. You can manually enter the ingredients to start suitability analysis.';
  }

  @override
  String get allIngredientsSeparated =>
      'All Ingredients (separated by comma ,)';

  @override
  String get ingredientsPlaceholder =>
      'Water, Niacinamide, Glycerin, Phenoxyethanol...';

  @override
  String get pleaseEnterIngredients => 'Please enter ingredients';

  @override
  String get doneAndContinue => 'Done & Proceed to Next Step';

  @override
  String get loadingCopy1 => 'Retrieving product ingredients...';

  @override
  String get loadingCopy2 => 'Analyzing ingredients against your skin type...';

  @override
  String get loadingCopy3 => 'Checking your allergy history...';

  @override
  String get loadingCopy4 => 'Analyzing suitability for your profile...';

  @override
  String get aiAnalyzing => 'AI is Analyzing';

  @override
  String referenceProfile(String skinType) {
    return 'Reference: $skinType Skin Profile';
  }

  @override
  String get analysisResults => 'Analysis Results';

  @override
  String get noAnalysisResults => 'No analysis result found';

  @override
  String get suitableForSkin => 'Suitable for your skin';

  @override
  String get useWithCaution => 'Use with caution';

  @override
  String get avoidProduct => 'Avoid this product';

  @override
  String get flaggedChemicals => 'Flagged Ingredients to Watch Out';

  @override
  String get markAsAllergen => 'Mark as allergic to this ingredient';

  @override
  String get aiSummary => 'AI Analysis Summary';

  @override
  String get analyzedByGemini => 'Analyzed by Gemini AI';

  @override
  String get detailedBreakdown => 'Individual Ingredient Breakdown Analysis';

  @override
  String get noIngredientData => 'No ingredient data found in the system';

  @override
  String get highRiskIngredients => 'High-Risk Ingredients (Danger)';

  @override
  String get cautionIngredients => 'Ingredients to Avoid/Caution';

  @override
  String get safeIngredients => 'Safe Ingredients';

  @override
  String get helpCommunity => 'Help Community: Confirm & Submit Info';

  @override
  String get thankYouCommunity =>
      'Thank you for confirming the product data for the community!';

  @override
  String addedAllergen(String name) {
    return 'Added $name to your allergy history';
  }

  @override
  String functionProperty(String value) {
    return 'Function/Property: $value';
  }

  @override
  String get backToHome => 'Back to Home';

  @override
  String get searchBrandsHint =>
      'Search brand name, product name, or chemical...';

  @override
  String get tabProducts => 'Products';

  @override
  String get tabIngredients => 'Ingredients';

  @override
  String get typeToSearchProducts => 'Type above to search for products';

  @override
  String get noProductsFound => 'No matching products found';

  @override
  String get unknownBrand => 'Unspecified Brand';

  @override
  String get typeIngredientToCheck =>
      'Type above to search ingredients and check allergy history';

  @override
  String get language => 'Language';

  @override
  String get displayLanguage => 'Display Language';

  @override
  String get helpAndSupport => 'Help & Support';

  @override
  String get aboutPureCheck => 'About PureCheck';

  @override
  String get signOut => 'Sign Out';

  @override
  String signOutFailed(String error) {
    return 'Sign out failed: $error';
  }

  @override
  String get aboutDescription =>
      'AI-powered skincare & cosmetic ingredient safety analysis customized to your skin profile.';

  @override
  String get skinProfileAndAllergy => 'Skin Profile & Allergy History';

  @override
  String get skinType => 'Skin Type';

  @override
  String get skinConditions => 'Skin Conditions / Health Precautions';

  @override
  String get skinConcerns => 'Skin Concerns';

  @override
  String get yourAllergens => 'Your Allergens';

  @override
  String get noAllergensRecorded => 'No allergens recorded yet';

  @override
  String get addAllergen => 'Add Allergen';

  @override
  String get allergenNameHint => 'Chemical name, e.g., Fragrance, Alcohol';

  @override
  String get profileNotFound => 'Skin profile not found';

  @override
  String get skinTypePrefix => 'Skin type: ';

  @override
  String get skinOily => 'Oily';

  @override
  String get skinDry => 'Dry';

  @override
  String get skinCombination => 'Combination';

  @override
  String get skinNormal => 'Normal';

  @override
  String get skinSensitive => 'Sensitive';

  @override
  String get conditionAcneProne => 'Acne-prone / Oily acne-prone';

  @override
  String get conditionEczema => 'Eczema (Atopic Dermatitis)';

  @override
  String get conditionRosacea => 'Rosacea';

  @override
  String get conditionPsoriasis => 'Psoriasis';

  @override
  String get concernAcne => 'Acne';

  @override
  String get concernDarkSpots => 'Dark Spots / Melasma';

  @override
  String get concernWrinkles => 'Wrinkles / Anti-aging';

  @override
  String get concernPores => 'Enlarged Pores';

  @override
  String get concernDullness => 'Dullness / Uneven Skin Tone';

  @override
  String get concernRedness => 'Redness / Easily Irritated';

  @override
  String get concernDehydrated => 'Dehydrated / Dry Skin';

  @override
  String get allScanHistory => 'All Scan History';

  @override
  String get noScanHistoryYet => 'You have no scan history';

  @override
  String allIngredientsCount(int count) {
    return 'All Ingredients ($count)';
  }

  @override
  String get noIngredientInfo => 'No ingredient information for this product';

  @override
  String get analyzeForMySkin => 'Analyze for my skin profile';

  @override
  String get analyzingAgainstProfile =>
      'Analyzing ingredients against your profile...';

  @override
  String get allergyHistoryYes => 'You are allergic to this ingredient';

  @override
  String get allergyHistoryNo => 'Safe for you (No allergy history)';

  @override
  String get aboutIngredient => 'Ingredient Information';

  @override
  String get ingredientGenericInfo =>
      'This chemical is commonly used as a solvent, cleanser, or active ingredient in cosmetics. Always check for skin irritation when starting any new product.';

  @override
  String get login => 'Login';

  @override
  String get register => 'Register';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get forgotPassword => 'Forgot Password?';

  @override
  String get noAccount => 'Don\'t have an account?';

  @override
  String get alreadyHaveAccount => 'Already have an account?';

  @override
  String get registerHere => 'Register here';

  @override
  String get loginHere => 'Login here';

  @override
  String loginFailed(String error) {
    return 'Login failed: $error';
  }

  @override
  String registerFailed(String error) {
    return 'Registration failed: $error';
  }

  @override
  String get passwordMismatch => 'Passwords do not match';

  @override
  String get introTitle => 'PureCheck';

  @override
  String get introSubtitle => 'AI cosmetic ingredient analysis';

  @override
  String get introDescription =>
      'Verify safety customized for your skin profile';

  @override
  String get getStarted => 'Get Started';

  @override
  String get onboardingNext => 'Next';

  @override
  String get onboardingBack => 'Back';

  @override
  String get onboardingSkip => 'Skip';

  @override
  String get onboardingDone => 'Done';

  @override
  String onboardingStepOf(int current, int total) {
    return 'Step $current of $total';
  }

  @override
  String get skinTypeQuestion => 'What is your skin type?';

  @override
  String get skinTypeHint => 'Select the skin type that matches you best';

  @override
  String get skinConditionsQuestion => 'Do you have any skin conditions?';

  @override
  String get skinConditionsHint => 'Select all that apply (or skip)';

  @override
  String get skinConcernsQuestion => 'What are your skin concerns?';

  @override
  String get skinConcernsHint => 'Select all that apply to you';

  @override
  String get allergensQuestion => 'Do you have any cosmetic allergy history?';

  @override
  String get allergensHint => 'Add chemicals you are allergic to (or skip)';

  @override
  String get onboardingCompleteTitle => 'All set!';

  @override
  String get onboardingCompleteMessage =>
      'Your profile is saved. You can now start scanning products.';

  @override
  String get startUsing => 'Start Using PureCheck';

  @override
  String get pleaseEnterEmail => 'Please enter an email';

  @override
  String get pleaseEnterPassword => 'Please enter a password';

  @override
  String get pleaseConfirmPassword => 'Please confirm your password';

  @override
  String get healthDisclaimer =>
      'Health Disclaimer: AI analysis is for informational purposes only and does not replace medical or dermatological advice.';
}
