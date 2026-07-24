import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fil.dart';

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
    Locale('fil')
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'IRMS'**
  String get appName;

  /// No description provided for @appSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Incident Reporting & Management'**
  String get appSubtitle;

  /// No description provided for @loginWelcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get loginWelcomeBack;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to your account'**
  String get loginSubtitle;

  /// No description provided for @btnSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get btnSignIn;

  /// No description provided for @btnCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get btnCreateAccount;

  /// No description provided for @errorLoginFailed.
  ///
  /// In en, this message translates to:
  /// **'Login failed'**
  String get errorLoginFailed;

  /// No description provided for @registerGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get registerGetStarted;

  /// No description provided for @registerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create your account'**
  String get registerSubtitle;

  /// No description provided for @registerHeading.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get registerHeading;

  /// No description provided for @registerSubHeading.
  ///
  /// In en, this message translates to:
  /// **'Fill in your details'**
  String get registerSubHeading;

  /// No description provided for @errorRegistrationFailed.
  ///
  /// In en, this message translates to:
  /// **'Registration failed'**
  String get errorRegistrationFailed;

  /// No description provided for @fieldEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get fieldEmail;

  /// No description provided for @fieldPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get fieldPassword;

  /// No description provided for @fieldFullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fieldFullName;

  /// No description provided for @fieldPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get fieldPhoneNumber;

  /// No description provided for @fieldAddressOptional.
  ///
  /// In en, this message translates to:
  /// **'Address (Optional)'**
  String get fieldAddressOptional;

  /// No description provided for @fieldInviteCodeOptional.
  ///
  /// In en, this message translates to:
  /// **'Invite Code (optional)'**
  String get fieldInviteCodeOptional;

  /// No description provided for @hintInviteCode.
  ///
  /// In en, this message translates to:
  /// **'Use an invite code for dispatcher access'**
  String get hintInviteCode;

  /// No description provided for @hintYourName.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get hintYourName;

  /// No description provided for @validationInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Invalid email'**
  String get validationInvalidEmail;

  /// No description provided for @validationMin8Chars.
  ///
  /// In en, this message translates to:
  /// **'Min 8 characters'**
  String get validationMin8Chars;

  /// No description provided for @validationRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get validationRequired;

  /// No description provided for @profileAppBarTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileAppBarTitle;

  /// No description provided for @profileAccountDetails.
  ///
  /// In en, this message translates to:
  /// **'Account Details'**
  String get profileAccountDetails;

  /// No description provided for @profileAccountId.
  ///
  /// In en, this message translates to:
  /// **'Account ID'**
  String get profileAccountId;

  /// No description provided for @profileFullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get profileFullName;

  /// No description provided for @profileEmailAddress.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get profileEmailAddress;

  /// No description provided for @profilePhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get profilePhoneNumber;

  /// No description provided for @profileAddress.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get profileAddress;

  /// No description provided for @profileLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get profileLanguage;

  /// No description provided for @profileAnonymousMode.
  ///
  /// In en, this message translates to:
  /// **'Anonymous Mode'**
  String get profileAnonymousMode;

  /// No description provided for @profileAnonymousDescription.
  ///
  /// In en, this message translates to:
  /// **'Log in or register to view your profile and submit verified reports.'**
  String get profileAnonymousDescription;

  /// No description provided for @btnLoginToAccount.
  ///
  /// In en, this message translates to:
  /// **'Login to Account'**
  String get btnLoginToAccount;

  /// No description provided for @btnSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get btnSignOut;

  /// No description provided for @btnChangePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get btnChangePassword;

  /// No description provided for @dialogChangePasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get dialogChangePasswordTitle;

  /// No description provided for @fieldCurrentPassword.
  ///
  /// In en, this message translates to:
  /// **'Current Password'**
  String get fieldCurrentPassword;

  /// No description provided for @fieldNewPassword.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get fieldNewPassword;

  /// No description provided for @fieldConfirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm New Password'**
  String get fieldConfirmPassword;

  /// No description provided for @validationPasswordMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get validationPasswordMismatch;

  /// No description provided for @snackbarPasswordChanged.
  ///
  /// In en, this message translates to:
  /// **'Password changed successfully'**
  String get snackbarPasswordChanged;

  /// No description provided for @fallbackUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get fallbackUnknown;

  /// No description provided for @fallbackNoEmail.
  ///
  /// In en, this message translates to:
  /// **'No email'**
  String get fallbackNoEmail;

  /// No description provided for @fallbackNotProvided.
  ///
  /// In en, this message translates to:
  /// **'Not provided'**
  String get fallbackNotProvided;

  /// No description provided for @submitAppBarTitle.
  ///
  /// In en, this message translates to:
  /// **'Report Incident'**
  String get submitAppBarTitle;

  /// No description provided for @tooltipLogout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get tooltipLogout;

  /// No description provided for @btnLogin.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get btnLogin;

  /// No description provided for @sectionWhatType.
  ///
  /// In en, this message translates to:
  /// **'What type?'**
  String get sectionWhatType;

  /// No description provided for @sectionWhatTypeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Select the incident category'**
  String get sectionWhatTypeSubtitle;

  /// No description provided for @typeFire.
  ///
  /// In en, this message translates to:
  /// **'Fire'**
  String get typeFire;

  /// No description provided for @typeAccident.
  ///
  /// In en, this message translates to:
  /// **'Accident'**
  String get typeAccident;

  /// No description provided for @typeCrime.
  ///
  /// In en, this message translates to:
  /// **'Crime'**
  String get typeCrime;

  /// No description provided for @typeMedical.
  ///
  /// In en, this message translates to:
  /// **'Medical'**
  String get typeMedical;

  /// No description provided for @typeDisaster.
  ///
  /// In en, this message translates to:
  /// **'Disaster'**
  String get typeDisaster;

  /// No description provided for @typeInfra.
  ///
  /// In en, this message translates to:
  /// **'Infra'**
  String get typeInfra;

  /// No description provided for @infoOptionalDetails.
  ///
  /// In en, this message translates to:
  /// **'The details below are optional. Only fill them out if you are in a safe location.'**
  String get infoOptionalDetails;

  /// No description provided for @sectionDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get sectionDetails;

  /// No description provided for @sectionDetailsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Describe what you see'**
  String get sectionDetailsSubtitle;

  /// No description provided for @fieldAdditionalDetails.
  ///
  /// In en, this message translates to:
  /// **'Additional Details (optional)'**
  String get fieldAdditionalDetails;

  /// No description provided for @hintWhatDoYouSee.
  ///
  /// In en, this message translates to:
  /// **'What do you see?'**
  String get hintWhatDoYouSee;

  /// No description provided for @sectionLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get sectionLocation;

  /// No description provided for @sectionLocationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Where is this happening?'**
  String get sectionLocationSubtitle;

  /// No description provided for @fieldBarangayOptional.
  ///
  /// In en, this message translates to:
  /// **'Barangay (optional)'**
  String get fieldBarangayOptional;

  /// No description provided for @dropdownSelectBarangay.
  ///
  /// In en, this message translates to:
  /// **'Select barangay'**
  String get dropdownSelectBarangay;

  /// No description provided for @fieldPhoneOptional.
  ///
  /// In en, this message translates to:
  /// **'Phone Number (optional)'**
  String get fieldPhoneOptional;

  /// No description provided for @hintEnterPhone.
  ///
  /// In en, this message translates to:
  /// **'Enter your phone number'**
  String get hintEnterPhone;

  /// No description provided for @sectionPhoto.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get sectionPhoto;

  /// No description provided for @sectionPhotoSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Optional visual evidence'**
  String get sectionPhotoSubtitle;

  /// No description provided for @sectionFireDetails.
  ///
  /// In en, this message translates to:
  /// **'Fire-specific details'**
  String get sectionFireDetails;

  /// No description provided for @fieldBuildingType.
  ///
  /// In en, this message translates to:
  /// **'Building type'**
  String get fieldBuildingType;

  /// No description provided for @dropdownResidential.
  ///
  /// In en, this message translates to:
  /// **'Residential'**
  String get dropdownResidential;

  /// No description provided for @dropdownCommercial.
  ///
  /// In en, this message translates to:
  /// **'Commercial'**
  String get dropdownCommercial;

  /// No description provided for @dropdownIndustrial.
  ///
  /// In en, this message translates to:
  /// **'Industrial'**
  String get dropdownIndustrial;

  /// No description provided for @dropdownVehicle.
  ///
  /// In en, this message translates to:
  /// **'Vehicle'**
  String get dropdownVehicle;

  /// No description provided for @dropdownOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get dropdownOther;

  /// No description provided for @sectionAccidentDetails.
  ///
  /// In en, this message translates to:
  /// **'Accident-specific details'**
  String get sectionAccidentDetails;

  /// No description provided for @fieldVehiclesInvolved.
  ///
  /// In en, this message translates to:
  /// **'Vehicles involved'**
  String get fieldVehiclesInvolved;

  /// No description provided for @labelInjuries.
  ///
  /// In en, this message translates to:
  /// **'Injuries'**
  String get labelInjuries;

  /// No description provided for @sectionCrimeDetails.
  ///
  /// In en, this message translates to:
  /// **'Crime-specific details'**
  String get sectionCrimeDetails;

  /// No description provided for @fieldCrimeType.
  ///
  /// In en, this message translates to:
  /// **'Crime type'**
  String get fieldCrimeType;

  /// No description provided for @dropdownTheft.
  ///
  /// In en, this message translates to:
  /// **'Theft'**
  String get dropdownTheft;

  /// No description provided for @dropdownAssault.
  ///
  /// In en, this message translates to:
  /// **'Assault'**
  String get dropdownAssault;

  /// No description provided for @dropdownVandalism.
  ///
  /// In en, this message translates to:
  /// **'Vandalism'**
  String get dropdownVandalism;

  /// No description provided for @dropdownBurglary.
  ///
  /// In en, this message translates to:
  /// **'Burglary'**
  String get dropdownBurglary;

  /// No description provided for @dropdownRobbery.
  ///
  /// In en, this message translates to:
  /// **'Robbery'**
  String get dropdownRobbery;

  /// No description provided for @dropdownSuspiciousActivity.
  ///
  /// In en, this message translates to:
  /// **'Suspicious Activity'**
  String get dropdownSuspiciousActivity;

  /// No description provided for @fieldSuspectDescription.
  ///
  /// In en, this message translates to:
  /// **'Suspect description (optional)'**
  String get fieldSuspectDescription;

  /// No description provided for @hintSuspectDescription.
  ///
  /// In en, this message translates to:
  /// **'Clothing, direction, features...'**
  String get hintSuspectDescription;

  /// No description provided for @sectionMedicalDetails.
  ///
  /// In en, this message translates to:
  /// **'Medical-specific details'**
  String get sectionMedicalDetails;

  /// No description provided for @fieldPatients.
  ///
  /// In en, this message translates to:
  /// **'Patients'**
  String get fieldPatients;

  /// No description provided for @fieldCondition.
  ///
  /// In en, this message translates to:
  /// **'Condition'**
  String get fieldCondition;

  /// No description provided for @hintMedicalCondition.
  ///
  /// In en, this message translates to:
  /// **'e.g. unconscious'**
  String get hintMedicalCondition;

  /// No description provided for @sectionDisasterDetails.
  ///
  /// In en, this message translates to:
  /// **'Disaster-specific details'**
  String get sectionDisasterDetails;

  /// No description provided for @fieldDisasterType.
  ///
  /// In en, this message translates to:
  /// **'Disaster type'**
  String get fieldDisasterType;

  /// No description provided for @dropdownFlood.
  ///
  /// In en, this message translates to:
  /// **'Flood'**
  String get dropdownFlood;

  /// No description provided for @dropdownEarthquake.
  ///
  /// In en, this message translates to:
  /// **'Earthquake'**
  String get dropdownEarthquake;

  /// No description provided for @dropdownHurricane.
  ///
  /// In en, this message translates to:
  /// **'Hurricane'**
  String get dropdownHurricane;

  /// No description provided for @dropdownTornado.
  ///
  /// In en, this message translates to:
  /// **'Tornado'**
  String get dropdownTornado;

  /// No description provided for @dropdownLandslide.
  ///
  /// In en, this message translates to:
  /// **'Landslide'**
  String get dropdownLandslide;

  /// No description provided for @dropdownWildfire.
  ///
  /// In en, this message translates to:
  /// **'Wildfire'**
  String get dropdownWildfire;

  /// No description provided for @sectionInfraDetails.
  ///
  /// In en, this message translates to:
  /// **'Infrastructure-specific details'**
  String get sectionInfraDetails;

  /// No description provided for @fieldInfraType.
  ///
  /// In en, this message translates to:
  /// **'Infrastructure type'**
  String get fieldInfraType;

  /// No description provided for @dropdownRoad.
  ///
  /// In en, this message translates to:
  /// **'Road'**
  String get dropdownRoad;

  /// No description provided for @dropdownBridge.
  ///
  /// In en, this message translates to:
  /// **'Bridge'**
  String get dropdownBridge;

  /// No description provided for @dropdownPowerLine.
  ///
  /// In en, this message translates to:
  /// **'Power Line'**
  String get dropdownPowerLine;

  /// No description provided for @dropdownWaterMain.
  ///
  /// In en, this message translates to:
  /// **'Water Main'**
  String get dropdownWaterMain;

  /// No description provided for @dropdownBuilding.
  ///
  /// In en, this message translates to:
  /// **'Building'**
  String get dropdownBuilding;

  /// No description provided for @fieldDamageSeverity.
  ///
  /// In en, this message translates to:
  /// **'Damage severity'**
  String get fieldDamageSeverity;

  /// No description provided for @dropdownSeverityMinor.
  ///
  /// In en, this message translates to:
  /// **'Minor'**
  String get dropdownSeverityMinor;

  /// No description provided for @dropdownSeverityModerate.
  ///
  /// In en, this message translates to:
  /// **'Moderate'**
  String get dropdownSeverityModerate;

  /// No description provided for @dropdownSeveritySevere.
  ///
  /// In en, this message translates to:
  /// **'Severe'**
  String get dropdownSeveritySevere;

  /// No description provided for @labelPhotoAdded.
  ///
  /// In en, this message translates to:
  /// **'Photo added'**
  String get labelPhotoAdded;

  /// No description provided for @labelTapToAddPhoto.
  ///
  /// In en, this message translates to:
  /// **'Tap to add photo'**
  String get labelTapToAddPhoto;

  /// No description provided for @btnSubmitReport.
  ///
  /// In en, this message translates to:
  /// **'Submit Report'**
  String get btnSubmitReport;

  /// No description provided for @errorPleaseRegister.
  ///
  /// In en, this message translates to:
  /// **'Please create an account to submit a report'**
  String get errorPleaseRegister;

  /// No description provided for @titleEmergencySuffix.
  ///
  /// In en, this message translates to:
  /// **'Emergency'**
  String get titleEmergencySuffix;

  /// No description provided for @dialogReportSubmittedTitle.
  ///
  /// In en, this message translates to:
  /// **'Report Submitted'**
  String get dialogReportSubmittedTitle;

  /// No description provided for @dialogTrackingCodeDescription.
  ///
  /// In en, this message translates to:
  /// **'Save this tracking code to check your report status:'**
  String get dialogTrackingCodeDescription;

  /// No description provided for @snackbarTrackingCodeCopied.
  ///
  /// In en, this message translates to:
  /// **'Tracking code copied to clipboard'**
  String get snackbarTrackingCodeCopied;

  /// No description provided for @btnDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get btnDone;

  /// No description provided for @myReportsAppBarTitle.
  ///
  /// In en, this message translates to:
  /// **'My Reports'**
  String get myReportsAppBarTitle;

  /// No description provided for @errorFailedToLoadReports.
  ///
  /// In en, this message translates to:
  /// **'Failed to load reports'**
  String get errorFailedToLoadReports;

  /// No description provided for @btnRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get btnRetry;

  /// No description provided for @emptyNoReports.
  ///
  /// In en, this message translates to:
  /// **'No reports yet'**
  String get emptyNoReports;

  /// No description provided for @emptyNoReportsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your submitted reports will appear here'**
  String get emptyNoReportsSubtitle;

  /// No description provided for @statusSubmitted.
  ///
  /// In en, this message translates to:
  /// **'SUBMITTED'**
  String get statusSubmitted;

  /// No description provided for @statusReviewing.
  ///
  /// In en, this message translates to:
  /// **'REVIEWING'**
  String get statusReviewing;

  /// No description provided for @statusVerified.
  ///
  /// In en, this message translates to:
  /// **'VERIFIED'**
  String get statusVerified;

  /// No description provided for @statusRejected.
  ///
  /// In en, this message translates to:
  /// **'REJECTED'**
  String get statusRejected;

  /// No description provided for @statusResolved.
  ///
  /// In en, this message translates to:
  /// **'RESOLVED'**
  String get statusResolved;

  /// No description provided for @reportDetailAppBarTitle.
  ///
  /// In en, this message translates to:
  /// **'Report Detail'**
  String get reportDetailAppBarTitle;

  /// No description provided for @errorFailedToLoad.
  ///
  /// In en, this message translates to:
  /// **'Failed to load'**
  String get errorFailedToLoad;

  /// No description provided for @labelDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get labelDescription;

  /// No description provided for @labelPhotos.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get labelPhotos;

  /// No description provided for @labelDispatcherNote.
  ///
  /// In en, this message translates to:
  /// **'Dispatcher Note'**
  String get labelDispatcherNote;

  /// No description provided for @metaCreated.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get metaCreated;

  /// No description provided for @metaAddress.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get metaAddress;

  /// No description provided for @metaCoordinatesTapDirections.
  ///
  /// In en, this message translates to:
  /// **'Coordinates (Tap for Directions)'**
  String get metaCoordinatesTapDirections;

  /// No description provided for @callAppBarTitle.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get callAppBarTitle;

  /// No description provided for @hintSearchContacts.
  ///
  /// In en, this message translates to:
  /// **'Search contacts or enter number...'**
  String get hintSearchContacts;

  /// No description provided for @labelEmergency.
  ///
  /// In en, this message translates to:
  /// **'Emergency'**
  String get labelEmergency;

  /// No description provided for @labelTapToCall911.
  ///
  /// In en, this message translates to:
  /// **'Tap to call 911'**
  String get labelTapToCall911;

  /// No description provided for @emptyNoContactsFound.
  ///
  /// In en, this message translates to:
  /// **'No contacts found'**
  String get emptyNoContactsFound;

  /// No description provided for @errorFailedToLoadContacts.
  ///
  /// In en, this message translates to:
  /// **'Failed to load contacts'**
  String get errorFailedToLoadContacts;

  /// No description provided for @labelCallThisNumber.
  ///
  /// In en, this message translates to:
  /// **'Call this number?'**
  String get labelCallThisNumber;

  /// No description provided for @emptyNoContactsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No contacts available'**
  String get emptyNoContactsAvailable;

  /// No description provided for @emptyNoEmergencyContacts.
  ///
  /// In en, this message translates to:
  /// **'No emergency contacts found.'**
  String get emptyNoEmergencyContacts;

  /// No description provided for @trackAppBarTitle.
  ///
  /// In en, this message translates to:
  /// **'Track Report'**
  String get trackAppBarTitle;

  /// No description provided for @trackHeading.
  ///
  /// In en, this message translates to:
  /// **'Enter your tracking code'**
  String get trackHeading;

  /// No description provided for @trackSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The code you received after submitting a report'**
  String get trackSubtitle;

  /// No description provided for @fieldTrackingCode.
  ///
  /// In en, this message translates to:
  /// **'Tracking Code'**
  String get fieldTrackingCode;

  /// No description provided for @hintTrackingCode.
  ///
  /// In en, this message translates to:
  /// **'XXXX-XXXX'**
  String get hintTrackingCode;

  /// No description provided for @validationEnterTrackingCode.
  ///
  /// In en, this message translates to:
  /// **'Enter tracking code'**
  String get validationEnterTrackingCode;

  /// No description provided for @btnTrack.
  ///
  /// In en, this message translates to:
  /// **'Track'**
  String get btnTrack;

  /// No description provided for @btnTrackAnother.
  ///
  /// In en, this message translates to:
  /// **'Track Another'**
  String get btnTrackAnother;

  /// No description provided for @dashboardAppBarTitle.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboardAppBarTitle;

  /// No description provided for @errorFailedToLoadDashboard.
  ///
  /// In en, this message translates to:
  /// **'Failed to load dashboard'**
  String get errorFailedToLoadDashboard;

  /// No description provided for @greetingMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get greetingMorning;

  /// No description provided for @greetingAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get greetingAfternoon;

  /// No description provided for @greetingEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get greetingEvening;

  /// No description provided for @greetingSuffix.
  ///
  /// In en, this message translates to:
  /// **', Dispatcher'**
  String get greetingSuffix;

  /// No description provided for @statTotalIncidents.
  ///
  /// In en, this message translates to:
  /// **'Total Incidents'**
  String get statTotalIncidents;

  /// No description provided for @statPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get statPending;

  /// No description provided for @statVerifiedToday.
  ///
  /// In en, this message translates to:
  /// **'Verified Today'**
  String get statVerifiedToday;

  /// No description provided for @statCritical.
  ///
  /// In en, this message translates to:
  /// **'Critical'**
  String get statCritical;

  /// No description provided for @emptyNoIncidentsInQueue.
  ///
  /// In en, this message translates to:
  /// **'No incidents in queue'**
  String get emptyNoIncidentsInQueue;

  /// No description provided for @labelStatusPipeline.
  ///
  /// In en, this message translates to:
  /// **'Status Pipeline'**
  String get labelStatusPipeline;

  /// No description provided for @pipelineSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Submitted'**
  String get pipelineSubmitted;

  /// No description provided for @pipelineReview.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get pipelineReview;

  /// No description provided for @pipelineVerified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get pipelineVerified;

  /// No description provided for @pipelineRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get pipelineRejected;

  /// No description provided for @pipelineResolved.
  ///
  /// In en, this message translates to:
  /// **'Resolved'**
  String get pipelineResolved;

  /// No description provided for @labelCriticalIncidents.
  ///
  /// In en, this message translates to:
  /// **'Critical Incidents'**
  String get labelCriticalIncidents;

  /// No description provided for @labelUrgent.
  ///
  /// In en, this message translates to:
  /// **'urgent'**
  String get labelUrgent;

  /// No description provided for @emptyAllClear.
  ///
  /// In en, this message translates to:
  /// **'All clear — no critical incidents right now'**
  String get emptyAllClear;

  /// No description provided for @queueAppBarTitle.
  ///
  /// In en, this message translates to:
  /// **'Incident Queue'**
  String get queueAppBarTitle;

  /// No description provided for @hintSearchQueue.
  ///
  /// In en, this message translates to:
  /// **'Search by title, tracking code...'**
  String get hintSearchQueue;

  /// No description provided for @filterType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get filterType;

  /// No description provided for @filterAllTypes.
  ///
  /// In en, this message translates to:
  /// **'All Types'**
  String get filterAllTypes;

  /// No description provided for @filterBarangay.
  ///
  /// In en, this message translates to:
  /// **'Barangay'**
  String get filterBarangay;

  /// No description provided for @filterAllBarangays.
  ///
  /// In en, this message translates to:
  /// **'All Barangays'**
  String get filterAllBarangays;

  /// No description provided for @btnClearFilter.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get btnClearFilter;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @emptyQueueTitle.
  ///
  /// In en, this message translates to:
  /// **'Queue is empty'**
  String get emptyQueueTitle;

  /// No description provided for @emptyQueueSubtitle.
  ///
  /// In en, this message translates to:
  /// **'You\'re all caught up! Great job.'**
  String get emptyQueueSubtitle;

  /// No description provided for @errorFailedToLoadQueue.
  ///
  /// In en, this message translates to:
  /// **'Failed to load queue'**
  String get errorFailedToLoadQueue;

  /// No description provided for @dialogVerifyTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify Incident'**
  String get dialogVerifyTitle;

  /// No description provided for @fieldOverrideSeverity.
  ///
  /// In en, this message translates to:
  /// **'Override severity (optional)'**
  String get fieldOverrideSeverity;

  /// No description provided for @severityLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get severityLow;

  /// No description provided for @severityMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get severityMedium;

  /// No description provided for @severityHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get severityHigh;

  /// No description provided for @severityCritical.
  ///
  /// In en, this message translates to:
  /// **'Critical'**
  String get severityCritical;

  /// No description provided for @fieldDispatcherNote.
  ///
  /// In en, this message translates to:
  /// **'Dispatcher note (optional)'**
  String get fieldDispatcherNote;

  /// No description provided for @hintDispatcherNote.
  ///
  /// In en, this message translates to:
  /// **'Add context or instructions...'**
  String get hintDispatcherNote;

  /// No description provided for @btnCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get btnCancel;

  /// No description provided for @btnVerify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get btnVerify;

  /// No description provided for @dialogRejectTitle.
  ///
  /// In en, this message translates to:
  /// **'Reject Incident'**
  String get dialogRejectTitle;

  /// No description provided for @fieldRejectionReason.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get fieldRejectionReason;

  /// No description provided for @hintRejectionReason.
  ///
  /// In en, this message translates to:
  /// **'Why is this being rejected?'**
  String get hintRejectionReason;

  /// No description provided for @btnReject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get btnReject;

  /// No description provided for @sheetUpdateStatus.
  ///
  /// In en, this message translates to:
  /// **'Update Status'**
  String get sheetUpdateStatus;

  /// No description provided for @statusUnderReview.
  ///
  /// In en, this message translates to:
  /// **'Under Review'**
  String get statusUnderReview;

  /// No description provided for @labelClaimed.
  ///
  /// In en, this message translates to:
  /// **'Claimed'**
  String get labelClaimed;

  /// No description provided for @labelViewDetails.
  ///
  /// In en, this message translates to:
  /// **'View Details →'**
  String get labelViewDetails;

  /// No description provided for @incidentDetailAppBarTitle.
  ///
  /// In en, this message translates to:
  /// **'Incident Details'**
  String get incidentDetailAppBarTitle;

  /// No description provided for @labelLockedByOther.
  ///
  /// In en, this message translates to:
  /// **'LOCKED - Being handled by another dispatcher.'**
  String get labelLockedByOther;

  /// No description provided for @fallbackNoTitle.
  ///
  /// In en, this message translates to:
  /// **'No Title'**
  String get fallbackNoTitle;

  /// No description provided for @detailReported.
  ///
  /// In en, this message translates to:
  /// **'Reported'**
  String get detailReported;

  /// No description provided for @detailSeverity.
  ///
  /// In en, this message translates to:
  /// **'Severity'**
  String get detailSeverity;

  /// No description provided for @detailBarangay.
  ///
  /// In en, this message translates to:
  /// **'Barangay'**
  String get detailBarangay;

  /// No description provided for @detailLocationTapDirections.
  ///
  /// In en, this message translates to:
  /// **'Location (Tap for Directions)'**
  String get detailLocationTapDirections;

  /// No description provided for @detailLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get detailLocation;

  /// No description provided for @labelCoordinates.
  ///
  /// In en, this message translates to:
  /// **'Coordinates: '**
  String get labelCoordinates;

  /// No description provided for @fallbackNoLocation.
  ///
  /// In en, this message translates to:
  /// **'No location provided'**
  String get fallbackNoLocation;

  /// No description provided for @detailReporter.
  ///
  /// In en, this message translates to:
  /// **'Reporter'**
  String get detailReporter;

  /// No description provided for @fallbackAnonymous.
  ///
  /// In en, this message translates to:
  /// **'Anonymous'**
  String get fallbackAnonymous;

  /// No description provided for @detailPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get detailPhone;

  /// No description provided for @detailAssignedDispatcher.
  ///
  /// In en, this message translates to:
  /// **'Assigned Dispatcher'**
  String get detailAssignedDispatcher;

  /// No description provided for @detailTrackingCode.
  ///
  /// In en, this message translates to:
  /// **'Tracking Code'**
  String get detailTrackingCode;

  /// No description provided for @detailDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get detailDescription;

  /// No description provided for @fallbackNoDescription.
  ///
  /// In en, this message translates to:
  /// **'No description provided.'**
  String get fallbackNoDescription;

  /// No description provided for @labelActivityTimeline.
  ///
  /// In en, this message translates to:
  /// **'Activity Timeline'**
  String get labelActivityTimeline;

  /// No description provided for @timelineIncidentReported.
  ///
  /// In en, this message translates to:
  /// **'Incident Reported'**
  String get timelineIncidentReported;

  /// No description provided for @timelineIncidentVerified.
  ///
  /// In en, this message translates to:
  /// **'Incident Verified'**
  String get timelineIncidentVerified;

  /// No description provided for @timelineIncidentRejected.
  ///
  /// In en, this message translates to:
  /// **'Incident Rejected'**
  String get timelineIncidentRejected;

  /// No description provided for @timelineIncidentResolved.
  ///
  /// In en, this message translates to:
  /// **'Incident Resolved'**
  String get timelineIncidentResolved;

  /// No description provided for @timelineIncidentClaimed.
  ///
  /// In en, this message translates to:
  /// **'Incident Claimed'**
  String get timelineIncidentClaimed;

  /// No description provided for @labelConfirmSeverity.
  ///
  /// In en, this message translates to:
  /// **'Confirm Severity'**
  String get labelConfirmSeverity;

  /// No description provided for @severityLowUppercase.
  ///
  /// In en, this message translates to:
  /// **'LOW'**
  String get severityLowUppercase;

  /// No description provided for @severityMediumUppercase.
  ///
  /// In en, this message translates to:
  /// **'MEDIUM'**
  String get severityMediumUppercase;

  /// No description provided for @severityHighUppercase.
  ///
  /// In en, this message translates to:
  /// **'HIGH'**
  String get severityHighUppercase;

  /// No description provided for @severityCriticalUppercase.
  ///
  /// In en, this message translates to:
  /// **'CRITICAL'**
  String get severityCriticalUppercase;

  /// No description provided for @labelDispatcherNotesOptional.
  ///
  /// In en, this message translates to:
  /// **'Dispatcher Notes (Optional)'**
  String get labelDispatcherNotesOptional;

  /// No description provided for @hintDispatcherNotes.
  ///
  /// In en, this message translates to:
  /// **'e.g., Firetruck dispatched to location'**
  String get hintDispatcherNotes;

  /// No description provided for @btnConfirmVerify.
  ///
  /// In en, this message translates to:
  /// **'Confirm & Verify'**
  String get btnConfirmVerify;

  /// No description provided for @sheetRejectSubtitle.
  ///
  /// In en, this message translates to:
  /// **'This will close the incident.'**
  String get sheetRejectSubtitle;

  /// No description provided for @hintRejectionReasonDetail.
  ///
  /// In en, this message translates to:
  /// **'Reason for rejection (e.g., Prank call, duplicate)'**
  String get hintRejectionReasonDetail;

  /// No description provided for @btnRejectIncident.
  ///
  /// In en, this message translates to:
  /// **'Reject Incident'**
  String get btnRejectIncident;

  /// No description provided for @labelError.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get labelError;

  /// No description provided for @btnVerifyAndAssign.
  ///
  /// In en, this message translates to:
  /// **'Verify & Assign'**
  String get btnVerifyAndAssign;

  /// No description provided for @btnClaimIncident.
  ///
  /// In en, this message translates to:
  /// **'Claim Incident'**
  String get btnClaimIncident;

  /// No description provided for @timelineActorPrefix.
  ///
  /// In en, this message translates to:
  /// **'by '**
  String get timelineActorPrefix;

  /// No description provided for @adminAppBarTitle.
  ///
  /// In en, this message translates to:
  /// **'Command Center'**
  String get adminAppBarTitle;

  /// No description provided for @tabAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get tabAnalytics;

  /// No description provided for @tabUsers.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get tabUsers;

  /// No description provided for @tabContacts.
  ///
  /// In en, this message translates to:
  /// **'Contacts'**
  String get tabContacts;

  /// No description provided for @tabCodes.
  ///
  /// In en, this message translates to:
  /// **'Codes'**
  String get tabCodes;

  /// No description provided for @tabBarangays.
  ///
  /// In en, this message translates to:
  /// **'Barangays'**
  String get tabBarangays;

  /// No description provided for @emptyNoAnalytics.
  ///
  /// In en, this message translates to:
  /// **'No analytics data.'**
  String get emptyNoAnalytics;

  /// No description provided for @emptyNoUsers.
  ///
  /// In en, this message translates to:
  /// **'No users found.'**
  String get emptyNoUsers;

  /// No description provided for @errorLoadingData.
  ///
  /// In en, this message translates to:
  /// **'Error loading data'**
  String get errorLoadingData;

  /// No description provided for @fabAddContact.
  ///
  /// In en, this message translates to:
  /// **'Add Contact'**
  String get fabAddContact;

  /// No description provided for @fabNewCode.
  ///
  /// In en, this message translates to:
  /// **'New Code'**
  String get fabNewCode;

  /// No description provided for @fabAddBarangay.
  ///
  /// In en, this message translates to:
  /// **'Add Barangay'**
  String get fabAddBarangay;

  /// No description provided for @fabBroadcast.
  ///
  /// In en, this message translates to:
  /// **'Broadcast'**
  String get fabBroadcast;

  /// No description provided for @sheetBroadcastTitle.
  ///
  /// In en, this message translates to:
  /// **'Send Global Broadcast'**
  String get sheetBroadcastTitle;

  /// No description provided for @sheetBroadcastSubtitle.
  ///
  /// In en, this message translates to:
  /// **'This will immediately alert all active users across the platform.'**
  String get sheetBroadcastSubtitle;

  /// No description provided for @hintBroadcastMessage.
  ///
  /// In en, this message translates to:
  /// **'Enter emergency alert or system message...'**
  String get hintBroadcastMessage;

  /// No description provided for @btnSendAlertNow.
  ///
  /// In en, this message translates to:
  /// **'Send Alert Now'**
  String get btnSendAlertNow;

  /// No description provided for @sheetExportTitle.
  ///
  /// In en, this message translates to:
  /// **'Export Incidents'**
  String get sheetExportTitle;

  /// No description provided for @sheetExportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Download a CSV file of incidents with optional filters.'**
  String get sheetExportSubtitle;

  /// No description provided for @fieldStatusOptional.
  ///
  /// In en, this message translates to:
  /// **'Status (optional)'**
  String get fieldStatusOptional;

  /// No description provided for @dropdownAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get dropdownAll;

  /// No description provided for @fieldTypeOptional.
  ///
  /// In en, this message translates to:
  /// **'Type (optional)'**
  String get fieldTypeOptional;

  /// No description provided for @snackbarExportSuccess.
  ///
  /// In en, this message translates to:
  /// **'Exported {count} incidents. CSV copied to clipboard.'**
  String snackbarExportSuccess(int count);

  /// No description provided for @btnExportCsv.
  ///
  /// In en, this message translates to:
  /// **'Export CSV'**
  String get btnExportCsv;

  /// No description provided for @statTotalUsers.
  ///
  /// In en, this message translates to:
  /// **'Total Users'**
  String get statTotalUsers;

  /// No description provided for @btnExportIncidentsCsv.
  ///
  /// In en, this message translates to:
  /// **'Export Incidents as CSV'**
  String get btnExportIncidentsCsv;

  /// No description provided for @labelIncidentsByStatus.
  ///
  /// In en, this message translates to:
  /// **'Incidents by Status'**
  String get labelIncidentsByStatus;

  /// No description provided for @labelIncidentsByType.
  ///
  /// In en, this message translates to:
  /// **'Incidents by Type'**
  String get labelIncidentsByType;

  /// No description provided for @labelIncidentsByBarangay.
  ///
  /// In en, this message translates to:
  /// **'Incidents by Barangay'**
  String get labelIncidentsByBarangay;

  /// No description provided for @emptyNoData.
  ///
  /// In en, this message translates to:
  /// **'No data available'**
  String get emptyNoData;

  /// No description provided for @emptyNoIncidentsRecorded.
  ///
  /// In en, this message translates to:
  /// **'No incidents recorded yet'**
  String get emptyNoIncidentsRecorded;

  /// No description provided for @sheetGenerateCodeTitle.
  ///
  /// In en, this message translates to:
  /// **'Generate Invite Code'**
  String get sheetGenerateCodeTitle;

  /// No description provided for @sheetGenerateCodeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'This code will let a new user register with the selected role.'**
  String get sheetGenerateCodeSubtitle;

  /// No description provided for @roleDispatcher.
  ///
  /// In en, this message translates to:
  /// **'Dispatcher'**
  String get roleDispatcher;

  /// No description provided for @roleAdmin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get roleAdmin;

  /// No description provided for @btnGenerateCode.
  ///
  /// In en, this message translates to:
  /// **'Generate Code'**
  String get btnGenerateCode;

  /// No description provided for @sheetAddBarangayTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Barangay'**
  String get sheetAddBarangayTitle;

  /// No description provided for @fieldBarangayName.
  ///
  /// In en, this message translates to:
  /// **'Barangay Name'**
  String get fieldBarangayName;

  /// No description provided for @fieldPsgcCode.
  ///
  /// In en, this message translates to:
  /// **'PSGC Code (optional)'**
  String get fieldPsgcCode;

  /// No description provided for @labelUrbanBarangay.
  ///
  /// In en, this message translates to:
  /// **'Urban Barangay'**
  String get labelUrbanBarangay;

  /// No description provided for @hintSearchUsers.
  ///
  /// In en, this message translates to:
  /// **'Search by name or email...'**
  String get hintSearchUsers;

  /// No description provided for @emptyNoUserMatch.
  ///
  /// In en, this message translates to:
  /// **'No users match \"{query}\"'**
  String emptyNoUserMatch(String query);

  /// No description provided for @roleGroupAdmins.
  ///
  /// In en, this message translates to:
  /// **'Admins'**
  String get roleGroupAdmins;

  /// No description provided for @roleGroupDispatchers.
  ///
  /// In en, this message translates to:
  /// **'Dispatchers'**
  String get roleGroupDispatchers;

  /// No description provided for @roleGroupReporters.
  ///
  /// In en, this message translates to:
  /// **'Reporters'**
  String get roleGroupReporters;

  /// No description provided for @fallbackUnknownUser.
  ///
  /// In en, this message translates to:
  /// **'Unknown User'**
  String get fallbackUnknownUser;

  /// No description provided for @sheetChangeRoleTitle.
  ///
  /// In en, this message translates to:
  /// **'Change User Role'**
  String get sheetChangeRoleTitle;

  /// No description provided for @sheetChangeRoleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Update privileges for {name}'**
  String sheetChangeRoleSubtitle(String name);

  /// No description provided for @roleReporter.
  ///
  /// In en, this message translates to:
  /// **'Reporter'**
  String get roleReporter;

  /// No description provided for @roleReporterDescription.
  ///
  /// In en, this message translates to:
  /// **'Can only submit and view their own reports.'**
  String get roleReporterDescription;

  /// No description provided for @roleDispatcherDescription.
  ///
  /// In en, this message translates to:
  /// **'Can view and manage all incoming reports.'**
  String get roleDispatcherDescription;

  /// No description provided for @roleAdminDescription.
  ///
  /// In en, this message translates to:
  /// **'Full system access, can manage users.'**
  String get roleAdminDescription;

  /// No description provided for @emptyNoInviteCodes.
  ///
  /// In en, this message translates to:
  /// **'No invite codes yet'**
  String get emptyNoInviteCodes;

  /// No description provided for @emptyNoInviteCodesHint.
  ///
  /// In en, this message translates to:
  /// **'Tap \"New Code\" to generate one'**
  String get emptyNoInviteCodesHint;

  /// No description provided for @labelAvailableCount.
  ///
  /// In en, this message translates to:
  /// **'Available ({count})'**
  String labelAvailableCount(int count);

  /// No description provided for @labelUsedCount.
  ///
  /// In en, this message translates to:
  /// **'Used ({count})'**
  String labelUsedCount(int count);

  /// No description provided for @badgeUsed.
  ///
  /// In en, this message translates to:
  /// **'USED'**
  String get badgeUsed;

  /// No description provided for @badgeActive.
  ///
  /// In en, this message translates to:
  /// **'ACTIVE'**
  String get badgeActive;

  /// No description provided for @snackbarCodeCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied: {code}'**
  String snackbarCodeCopied(String code);

  /// No description provided for @dialogDeleteCodeTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete code?'**
  String get dialogDeleteCodeTitle;

  /// No description provided for @dialogDeleteCodeContent.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete {code}.'**
  String dialogDeleteCodeContent(String code);

  /// No description provided for @btnDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get btnDelete;

  /// No description provided for @dialogDeleteBarangayTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete barangay?'**
  String get dialogDeleteBarangayTitle;

  /// No description provided for @dialogDeleteBarangayContent.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete \"{name}\".'**
  String dialogDeleteBarangayContent(String name);

  /// No description provided for @labelUrban.
  ///
  /// In en, this message translates to:
  /// **'Urban'**
  String get labelUrban;

  /// No description provided for @labelRural.
  ///
  /// In en, this message translates to:
  /// **'Rural'**
  String get labelRural;

  /// No description provided for @labelPsgc.
  ///
  /// In en, this message translates to:
  /// **'PSGC: {code}'**
  String labelPsgc(String code);

  /// No description provided for @labelUsedBy.
  ///
  /// In en, this message translates to:
  /// **'Used by {name}'**
  String labelUsedBy(String name);

  /// No description provided for @fieldFilterByCategory.
  ///
  /// In en, this message translates to:
  /// **'Filter by Category'**
  String get fieldFilterByCategory;

  /// No description provided for @dropdownAllCategories.
  ///
  /// In en, this message translates to:
  /// **'All Categories'**
  String get dropdownAllCategories;

  /// No description provided for @tooltipManageCategories.
  ///
  /// In en, this message translates to:
  /// **'Manage Categories'**
  String get tooltipManageCategories;

  /// No description provided for @tooltipImportCsvJson.
  ///
  /// In en, this message translates to:
  /// **'Import CSV/JSON'**
  String get tooltipImportCsvJson;

  /// No description provided for @errorCouldNotReadFile.
  ///
  /// In en, this message translates to:
  /// **'Could not read file'**
  String get errorCouldNotReadFile;

  /// No description provided for @errorParseError.
  ///
  /// In en, this message translates to:
  /// **'Parse error: {error}'**
  String errorParseError(String error);

  /// No description provided for @errorNoValidContacts.
  ///
  /// In en, this message translates to:
  /// **'No valid contacts found in file'**
  String get errorNoValidContacts;

  /// No description provided for @snackbarImportSuccess.
  ///
  /// In en, this message translates to:
  /// **'Imported {count} contacts, {errors} errors'**
  String snackbarImportSuccess(int count, int errors);

  /// No description provided for @errorImportFailed.
  ///
  /// In en, this message translates to:
  /// **'Import failed: {error}'**
  String errorImportFailed(String error);

  /// No description provided for @sheetEditCategory.
  ///
  /// In en, this message translates to:
  /// **'Edit Category'**
  String get sheetEditCategory;

  /// No description provided for @sheetAddCategory.
  ///
  /// In en, this message translates to:
  /// **'Add Category'**
  String get sheetAddCategory;

  /// No description provided for @fieldCategoryName.
  ///
  /// In en, this message translates to:
  /// **'Category Name'**
  String get fieldCategoryName;

  /// No description provided for @hintCategoryName.
  ///
  /// In en, this message translates to:
  /// **'e.g. Police Station'**
  String get hintCategoryName;

  /// No description provided for @fieldColorHex.
  ///
  /// In en, this message translates to:
  /// **'Color (hex)'**
  String get fieldColorHex;

  /// No description provided for @hintColorHex.
  ///
  /// In en, this message translates to:
  /// **'#2563EB'**
  String get hintColorHex;

  /// No description provided for @fieldSortOrder.
  ///
  /// In en, this message translates to:
  /// **'Sort Order'**
  String get fieldSortOrder;

  /// No description provided for @btnSaveCategory.
  ///
  /// In en, this message translates to:
  /// **'Save Category'**
  String get btnSaveCategory;

  /// No description provided for @dialogDeleteCategoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Category'**
  String get dialogDeleteCategoryTitle;

  /// No description provided for @dialogDeleteCategoryContent.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{name}\"? Contacts using it will lose their category.'**
  String dialogDeleteCategoryContent(String name);

  /// No description provided for @sheetEditContact.
  ///
  /// In en, this message translates to:
  /// **'Edit Contact'**
  String get sheetEditContact;

  /// No description provided for @sheetAddContact.
  ///
  /// In en, this message translates to:
  /// **'Add Emergency Contact'**
  String get sheetAddContact;

  /// No description provided for @fieldName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get fieldName;

  /// No description provided for @fieldDepartment.
  ///
  /// In en, this message translates to:
  /// **'Department (e.g. Police, Fire, Medical)'**
  String get fieldDepartment;

  /// No description provided for @fieldCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get fieldCategory;

  /// No description provided for @btnSaveContact.
  ///
  /// In en, this message translates to:
  /// **'Save Contact'**
  String get btnSaveContact;

  /// No description provided for @mapTitle.
  ///
  /// In en, this message translates to:
  /// **'Incidents Map ({count})'**
  String mapTitle(int count);

  /// No description provided for @btnGetDirections.
  ///
  /// In en, this message translates to:
  /// **'Get Directions'**
  String get btnGetDirections;

  /// No description provided for @trackPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Track Report'**
  String get trackPageTitle;

  /// No description provided for @trackEnterCodeHeading.
  ///
  /// In en, this message translates to:
  /// **'Enter your tracking code'**
  String get trackEnterCodeHeading;

  /// No description provided for @myReportsTitle.
  ///
  /// In en, this message translates to:
  /// **'My Reports'**
  String get myReportsTitle;
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
      <String>['en', 'fil'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fil':
      return AppLocalizationsFil();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
