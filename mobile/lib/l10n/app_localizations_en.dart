// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'IRMS';

  @override
  String get appSubtitle => 'Incident Reporting & Management';

  @override
  String get loginWelcomeBack => 'Welcome Back';

  @override
  String get loginSubtitle => 'Sign in to your account';

  @override
  String get btnSignIn => 'Sign In';

  @override
  String get btnCreateAccount => 'Create Account';

  @override
  String get errorLoginFailed => 'Login failed';

  @override
  String get registerGetStarted => 'Get Started';

  @override
  String get registerSubtitle => 'Create your account';

  @override
  String get registerHeading => 'Create Account';

  @override
  String get registerSubHeading => 'Fill in your details';

  @override
  String get errorRegistrationFailed => 'Registration failed';

  @override
  String get fieldEmail => 'Email';

  @override
  String get fieldPassword => 'Password';

  @override
  String get fieldFullName => 'Full Name';

  @override
  String get fieldPhoneNumber => 'Phone Number';

  @override
  String get fieldAddressOptional => 'Address (Optional)';

  @override
  String get fieldInviteCodeOptional => 'Invite Code (optional)';

  @override
  String get hintInviteCode => 'Use an invite code for dispatcher access';

  @override
  String get hintYourName => 'Your name';

  @override
  String get validationInvalidEmail => 'Invalid email';

  @override
  String get validationMin8Chars => 'Min 8 characters';

  @override
  String get validationRequired => 'Required';

  @override
  String get profileAppBarTitle => 'Profile';

  @override
  String get profileAccountDetails => 'Account Details';

  @override
  String get profileAccountId => 'Account ID';

  @override
  String get profileFullName => 'Full Name';

  @override
  String get profileEmailAddress => 'Email Address';

  @override
  String get profilePhoneNumber => 'Phone Number';

  @override
  String get profileAddress => 'Address';

  @override
  String get profileLanguage => 'Language';

  @override
  String get profileAnonymousMode => 'Anonymous Mode';

  @override
  String get profileAnonymousDescription =>
      'Log in or register to view your profile and submit verified reports.';

  @override
  String get btnLoginToAccount => 'Login to Account';

  @override
  String get btnSignOut => 'Sign Out';

  @override
  String get btnChangePassword => 'Change Password';

  @override
  String get dialogChangePasswordTitle => 'Change Password';

  @override
  String get fieldCurrentPassword => 'Current Password';

  @override
  String get fieldNewPassword => 'New Password';

  @override
  String get fieldConfirmPassword => 'Confirm New Password';

  @override
  String get validationPasswordMismatch => 'Passwords do not match';

  @override
  String get snackbarPasswordChanged => 'Password changed successfully';

  @override
  String get fallbackUnknown => 'Unknown';

  @override
  String get fallbackNoEmail => 'No email';

  @override
  String get fallbackNotProvided => 'Not provided';

  @override
  String get submitAppBarTitle => 'Report Incident';

  @override
  String get tooltipLogout => 'Logout';

  @override
  String get btnLogin => 'Login';

  @override
  String get sectionWhatType => 'What type?';

  @override
  String get sectionWhatTypeSubtitle => 'Select the incident category';

  @override
  String get typeFire => 'Fire';

  @override
  String get typeAccident => 'Accident';

  @override
  String get typeCrime => 'Crime';

  @override
  String get typeMedical => 'Medical';

  @override
  String get typeDisaster => 'Disaster';

  @override
  String get typeInfra => 'Infra';

  @override
  String get infoOptionalDetails =>
      'The details below are optional. Only fill them out if you are in a safe location.';

  @override
  String get sectionDetails => 'Details';

  @override
  String get sectionDetailsSubtitle => 'Describe what you see';

  @override
  String get fieldAdditionalDetails => 'Additional Details (optional)';

  @override
  String get hintWhatDoYouSee => 'What do you see?';

  @override
  String get sectionLocation => 'Location';

  @override
  String get sectionLocationSubtitle => 'Where is this happening?';

  @override
  String get fieldBarangayOptional => 'Barangay (optional)';

  @override
  String get dropdownSelectBarangay => 'Select barangay';

  @override
  String get fieldPhoneOptional => 'Phone Number (optional)';

  @override
  String get hintEnterPhone => 'Enter your phone number';

  @override
  String get sectionPhoto => 'Photo';

  @override
  String get sectionPhotoSubtitle => 'Optional visual evidence';

  @override
  String get sectionFireDetails => 'Fire-specific details';

  @override
  String get fieldBuildingType => 'Building type';

  @override
  String get dropdownResidential => 'Residential';

  @override
  String get dropdownCommercial => 'Commercial';

  @override
  String get dropdownIndustrial => 'Industrial';

  @override
  String get dropdownVehicle => 'Vehicle';

  @override
  String get dropdownOther => 'Other';

  @override
  String get sectionAccidentDetails => 'Accident-specific details';

  @override
  String get fieldVehiclesInvolved => 'Vehicles involved';

  @override
  String get labelInjuries => 'Injuries';

  @override
  String get sectionCrimeDetails => 'Crime-specific details';

  @override
  String get fieldCrimeType => 'Crime type';

  @override
  String get dropdownTheft => 'Theft';

  @override
  String get dropdownAssault => 'Assault';

  @override
  String get dropdownVandalism => 'Vandalism';

  @override
  String get dropdownBurglary => 'Burglary';

  @override
  String get dropdownRobbery => 'Robbery';

  @override
  String get dropdownSuspiciousActivity => 'Suspicious Activity';

  @override
  String get fieldSuspectDescription => 'Suspect description (optional)';

  @override
  String get hintSuspectDescription => 'Clothing, direction, features...';

  @override
  String get sectionMedicalDetails => 'Medical-specific details';

  @override
  String get fieldPatients => 'Patients';

  @override
  String get fieldCondition => 'Condition';

  @override
  String get hintMedicalCondition => 'e.g. unconscious';

  @override
  String get sectionDisasterDetails => 'Disaster-specific details';

  @override
  String get fieldDisasterType => 'Disaster type';

  @override
  String get dropdownFlood => 'Flood';

  @override
  String get dropdownEarthquake => 'Earthquake';

  @override
  String get dropdownHurricane => 'Hurricane';

  @override
  String get dropdownTornado => 'Tornado';

  @override
  String get dropdownLandslide => 'Landslide';

  @override
  String get dropdownWildfire => 'Wildfire';

  @override
  String get sectionInfraDetails => 'Infrastructure-specific details';

  @override
  String get fieldInfraType => 'Infrastructure type';

  @override
  String get dropdownRoad => 'Road';

  @override
  String get dropdownBridge => 'Bridge';

  @override
  String get dropdownPowerLine => 'Power Line';

  @override
  String get dropdownWaterMain => 'Water Main';

  @override
  String get dropdownBuilding => 'Building';

  @override
  String get fieldDamageSeverity => 'Damage severity';

  @override
  String get dropdownSeverityMinor => 'Minor';

  @override
  String get dropdownSeverityModerate => 'Moderate';

  @override
  String get dropdownSeveritySevere => 'Severe';

  @override
  String get labelPhotoAdded => 'Photo added';

  @override
  String get labelTapToAddPhoto => 'Tap to add photo';

  @override
  String get btnSubmitReport => 'Submit Report';

  @override
  String get errorPleaseRegister =>
      'Please create an account to submit a report';

  @override
  String get titleEmergencySuffix => 'Emergency';

  @override
  String get dialogReportSubmittedTitle => 'Report Submitted';

  @override
  String get dialogTrackingCodeDescription =>
      'Save this tracking code to check your report status:';

  @override
  String get snackbarTrackingCodeCopied => 'Tracking code copied to clipboard';

  @override
  String get btnDone => 'Done';

  @override
  String get myReportsAppBarTitle => 'My Reports';

  @override
  String get errorFailedToLoadReports => 'Failed to load reports';

  @override
  String get btnRetry => 'Retry';

  @override
  String get emptyNoReports => 'No reports yet';

  @override
  String get emptyNoReportsSubtitle =>
      'Your submitted reports will appear here';

  @override
  String get statusSubmitted => 'SUBMITTED';

  @override
  String get statusReviewing => 'REVIEWING';

  @override
  String get statusVerified => 'VERIFIED';

  @override
  String get statusRejected => 'REJECTED';

  @override
  String get statusResolved => 'RESOLVED';

  @override
  String get reportDetailAppBarTitle => 'Report Detail';

  @override
  String get errorFailedToLoad => 'Failed to load';

  @override
  String get labelDescription => 'Description';

  @override
  String get labelPhotos => 'Photos';

  @override
  String get labelDispatcherNote => 'Dispatcher Note';

  @override
  String get metaCreated => 'Created';

  @override
  String get metaAddress => 'Address';

  @override
  String get metaCoordinatesTapDirections => 'Coordinates (Tap for Directions)';

  @override
  String get callAppBarTitle => 'Call';

  @override
  String get hintSearchContacts => 'Search contacts or enter number...';

  @override
  String get labelEmergency => 'Emergency';

  @override
  String get labelTapToCall911 => 'Tap to call 911';

  @override
  String get emptyNoContactsFound => 'No contacts found';

  @override
  String get errorFailedToLoadContacts => 'Failed to load contacts';

  @override
  String get labelCallThisNumber => 'Call this number?';

  @override
  String get emptyNoContactsAvailable => 'No contacts available';

  @override
  String get emptyNoEmergencyContacts => 'No emergency contacts found.';

  @override
  String get trackAppBarTitle => 'Track Report';

  @override
  String get trackHeading => 'Enter your tracking code';

  @override
  String get trackSubtitle => 'The code you received after submitting a report';

  @override
  String get fieldTrackingCode => 'Tracking Code';

  @override
  String get hintTrackingCode => 'XXXX-XXXX';

  @override
  String get validationEnterTrackingCode => 'Enter tracking code';

  @override
  String get btnTrack => 'Track';

  @override
  String get btnTrackAnother => 'Track Another';

  @override
  String get dashboardAppBarTitle => 'Dashboard';

  @override
  String get errorFailedToLoadDashboard => 'Failed to load dashboard';

  @override
  String get greetingMorning => 'Good morning';

  @override
  String get greetingAfternoon => 'Good afternoon';

  @override
  String get greetingEvening => 'Good evening';

  @override
  String get greetingSuffix => ', Dispatcher';

  @override
  String get statTotalIncidents => 'Total Incidents';

  @override
  String get statPending => 'Pending';

  @override
  String get statVerifiedToday => 'Verified Today';

  @override
  String get statCritical => 'Critical';

  @override
  String get emptyNoIncidentsInQueue => 'No incidents in queue';

  @override
  String get labelStatusPipeline => 'Status Pipeline';

  @override
  String get pipelineSubmitted => 'Submitted';

  @override
  String get pipelineReview => 'Review';

  @override
  String get pipelineVerified => 'Verified';

  @override
  String get pipelineRejected => 'Rejected';

  @override
  String get pipelineResolved => 'Resolved';

  @override
  String get labelCriticalIncidents => 'Critical Incidents';

  @override
  String get labelUrgent => 'urgent';

  @override
  String get emptyAllClear => 'All clear — no critical incidents right now';

  @override
  String get queueAppBarTitle => 'Incident Queue';

  @override
  String get hintSearchQueue => 'Search by title, tracking code...';

  @override
  String get filterType => 'Type';

  @override
  String get filterAllTypes => 'All Types';

  @override
  String get filterBarangay => 'Barangay';

  @override
  String get filterAllBarangays => 'All Barangays';

  @override
  String get btnClearFilter => 'Clear';

  @override
  String get filterAll => 'All';

  @override
  String get emptyQueueTitle => 'Queue is empty';

  @override
  String get emptyQueueSubtitle => 'You\'re all caught up! Great job.';

  @override
  String get errorFailedToLoadQueue => 'Failed to load queue';

  @override
  String get dialogVerifyTitle => 'Verify Incident';

  @override
  String get fieldOverrideSeverity => 'Override severity (optional)';

  @override
  String get severityLow => 'Low';

  @override
  String get severityMedium => 'Medium';

  @override
  String get severityHigh => 'High';

  @override
  String get severityCritical => 'Critical';

  @override
  String get fieldDispatcherNote => 'Dispatcher note (optional)';

  @override
  String get hintDispatcherNote => 'Add context or instructions...';

  @override
  String get btnCancel => 'Cancel';

  @override
  String get btnVerify => 'Verify';

  @override
  String get dialogRejectTitle => 'Reject Incident';

  @override
  String get fieldRejectionReason => 'Reason';

  @override
  String get hintRejectionReason => 'Why is this being rejected?';

  @override
  String get btnReject => 'Reject';

  @override
  String get sheetUpdateStatus => 'Update Status';

  @override
  String get statusUnderReview => 'Under Review';

  @override
  String get labelClaimed => 'Claimed';

  @override
  String get labelViewDetails => 'View Details →';

  @override
  String get incidentDetailAppBarTitle => 'Incident Details';

  @override
  String get labelLockedByOther =>
      'LOCKED - Being handled by another dispatcher.';

  @override
  String get fallbackNoTitle => 'No Title';

  @override
  String get detailReported => 'Reported';

  @override
  String get detailSeverity => 'Severity';

  @override
  String get detailBarangay => 'Barangay';

  @override
  String get detailLocationTapDirections => 'Location (Tap for Directions)';

  @override
  String get detailLocation => 'Location';

  @override
  String get labelCoordinates => 'Coordinates: ';

  @override
  String get fallbackNoLocation => 'No location provided';

  @override
  String get detailReporter => 'Reporter';

  @override
  String get fallbackAnonymous => 'Anonymous';

  @override
  String get detailPhone => 'Phone';

  @override
  String get detailAssignedDispatcher => 'Assigned Dispatcher';

  @override
  String get detailTrackingCode => 'Tracking Code';

  @override
  String get detailDescription => 'Description';

  @override
  String get fallbackNoDescription => 'No description provided.';

  @override
  String get labelActivityTimeline => 'Activity Timeline';

  @override
  String get timelineIncidentReported => 'Incident Reported';

  @override
  String get timelineIncidentVerified => 'Incident Verified';

  @override
  String get timelineIncidentRejected => 'Incident Rejected';

  @override
  String get timelineIncidentResolved => 'Incident Resolved';

  @override
  String get timelineIncidentClaimed => 'Incident Claimed';

  @override
  String get labelConfirmSeverity => 'Confirm Severity';

  @override
  String get severityLowUppercase => 'LOW';

  @override
  String get severityMediumUppercase => 'MEDIUM';

  @override
  String get severityHighUppercase => 'HIGH';

  @override
  String get severityCriticalUppercase => 'CRITICAL';

  @override
  String get labelDispatcherNotesOptional => 'Dispatcher Notes (Optional)';

  @override
  String get hintDispatcherNotes => 'e.g., Firetruck dispatched to location';

  @override
  String get btnConfirmVerify => 'Confirm & Verify';

  @override
  String get sheetRejectSubtitle => 'This will close the incident.';

  @override
  String get hintRejectionReasonDetail =>
      'Reason for rejection (e.g., Prank call, duplicate)';

  @override
  String get btnRejectIncident => 'Reject Incident';

  @override
  String get labelError => 'Error';

  @override
  String get btnVerifyAndAssign => 'Verify & Assign';

  @override
  String get btnClaimIncident => 'Claim Incident';

  @override
  String get timelineActorPrefix => 'by ';

  @override
  String get adminAppBarTitle => 'Command Center';

  @override
  String get tabAnalytics => 'Analytics';

  @override
  String get tabUsers => 'Users';

  @override
  String get tabContacts => 'Contacts';

  @override
  String get tabCodes => 'Codes';

  @override
  String get tabBarangays => 'Barangays';

  @override
  String get emptyNoAnalytics => 'No analytics data.';

  @override
  String get emptyNoUsers => 'No users found.';

  @override
  String get errorLoadingData => 'Error loading data';

  @override
  String get fabAddContact => 'Add Contact';

  @override
  String get fabNewCode => 'New Code';

  @override
  String get fabAddBarangay => 'Add Barangay';

  @override
  String get fabBroadcast => 'Broadcast';

  @override
  String get sheetBroadcastTitle => 'Send Global Broadcast';

  @override
  String get sheetBroadcastSubtitle =>
      'This will immediately alert all active users across the platform.';

  @override
  String get hintBroadcastMessage =>
      'Enter emergency alert or system message...';

  @override
  String get btnSendAlertNow => 'Send Alert Now';

  @override
  String get sheetExportTitle => 'Export Incidents';

  @override
  String get sheetExportSubtitle =>
      'Download a CSV file of incidents with optional filters.';

  @override
  String get fieldStatusOptional => 'Status (optional)';

  @override
  String get dropdownAll => 'All';

  @override
  String get fieldTypeOptional => 'Type (optional)';

  @override
  String snackbarExportSuccess(int count) {
    return 'Exported $count incidents. CSV copied to clipboard.';
  }

  @override
  String get btnExportCsv => 'Export CSV';

  @override
  String get statTotalUsers => 'Total Users';

  @override
  String get btnExportIncidentsCsv => 'Export Incidents as CSV';

  @override
  String get labelIncidentsByStatus => 'Incidents by Status';

  @override
  String get labelIncidentsByType => 'Incidents by Type';

  @override
  String get labelIncidentsByBarangay => 'Incidents by Barangay';

  @override
  String get emptyNoData => 'No data available';

  @override
  String get emptyNoIncidentsRecorded => 'No incidents recorded yet';

  @override
  String get sheetGenerateCodeTitle => 'Generate Invite Code';

  @override
  String get sheetGenerateCodeSubtitle =>
      'This code will let a new user register with the selected role.';

  @override
  String get roleDispatcher => 'Dispatcher';

  @override
  String get roleAdmin => 'Admin';

  @override
  String get btnGenerateCode => 'Generate Code';

  @override
  String get sheetAddBarangayTitle => 'Add Barangay';

  @override
  String get fieldBarangayName => 'Barangay Name';

  @override
  String get fieldPsgcCode => 'PSGC Code (optional)';

  @override
  String get labelUrbanBarangay => 'Urban Barangay';

  @override
  String get hintSearchUsers => 'Search by name or email...';

  @override
  String emptyNoUserMatch(String query) {
    return 'No users match \"$query\"';
  }

  @override
  String get roleGroupAdmins => 'Admins';

  @override
  String get roleGroupDispatchers => 'Dispatchers';

  @override
  String get roleGroupReporters => 'Reporters';

  @override
  String get fallbackUnknownUser => 'Unknown User';

  @override
  String get sheetChangeRoleTitle => 'Change User Role';

  @override
  String sheetChangeRoleSubtitle(String name) {
    return 'Update privileges for $name';
  }

  @override
  String get roleReporter => 'Reporter';

  @override
  String get roleReporterDescription =>
      'Can only submit and view their own reports.';

  @override
  String get roleDispatcherDescription =>
      'Can view and manage all incoming reports.';

  @override
  String get roleAdminDescription => 'Full system access, can manage users.';

  @override
  String get emptyNoInviteCodes => 'No invite codes yet';

  @override
  String get emptyNoInviteCodesHint => 'Tap \"New Code\" to generate one';

  @override
  String labelAvailableCount(int count) {
    return 'Available ($count)';
  }

  @override
  String labelUsedCount(int count) {
    return 'Used ($count)';
  }

  @override
  String get badgeUsed => 'USED';

  @override
  String get badgeActive => 'ACTIVE';

  @override
  String snackbarCodeCopied(String code) {
    return 'Copied: $code';
  }

  @override
  String get dialogDeleteCodeTitle => 'Delete code?';

  @override
  String dialogDeleteCodeContent(String code) {
    return 'This will permanently delete $code.';
  }

  @override
  String get btnDelete => 'Delete';

  @override
  String get dialogDeleteBarangayTitle => 'Delete barangay?';

  @override
  String dialogDeleteBarangayContent(String name) {
    return 'This will permanently delete \"$name\".';
  }

  @override
  String get labelUrban => 'Urban';

  @override
  String get labelRural => 'Rural';

  @override
  String labelPsgc(String code) {
    return 'PSGC: $code';
  }

  @override
  String labelUsedBy(String name) {
    return 'Used by $name';
  }

  @override
  String get fieldFilterByCategory => 'Filter by Category';

  @override
  String get dropdownAllCategories => 'All Categories';

  @override
  String get tooltipManageCategories => 'Manage Categories';

  @override
  String get tooltipImportCsvJson => 'Import CSV/JSON';

  @override
  String get errorCouldNotReadFile => 'Could not read file';

  @override
  String errorParseError(String error) {
    return 'Parse error: $error';
  }

  @override
  String get errorNoValidContacts => 'No valid contacts found in file';

  @override
  String snackbarImportSuccess(int count, int errors) {
    return 'Imported $count contacts, $errors errors';
  }

  @override
  String errorImportFailed(String error) {
    return 'Import failed: $error';
  }

  @override
  String get sheetEditCategory => 'Edit Category';

  @override
  String get sheetAddCategory => 'Add Category';

  @override
  String get fieldCategoryName => 'Category Name';

  @override
  String get hintCategoryName => 'e.g. Police Station';

  @override
  String get fieldColorHex => 'Color (hex)';

  @override
  String get hintColorHex => '#2563EB';

  @override
  String get fieldSortOrder => 'Sort Order';

  @override
  String get btnSaveCategory => 'Save Category';

  @override
  String get dialogDeleteCategoryTitle => 'Delete Category';

  @override
  String dialogDeleteCategoryContent(String name) {
    return 'Delete \"$name\"? Contacts using it will lose their category.';
  }

  @override
  String get sheetEditContact => 'Edit Contact';

  @override
  String get sheetAddContact => 'Add Emergency Contact';

  @override
  String get fieldName => 'Name';

  @override
  String get fieldDepartment => 'Department (e.g. Police, Fire, Medical)';

  @override
  String get fieldCategory => 'Category';

  @override
  String get btnSaveContact => 'Save Contact';

  @override
  String mapTitle(int count) {
    return 'Incidents Map ($count)';
  }

  @override
  String get btnGetDirections => 'Get Directions';

  @override
  String get trackPageTitle => 'Track Report';

  @override
  String get trackEnterCodeHeading => 'Enter your tracking code';

  @override
  String get myReportsTitle => 'My Reports';
}
