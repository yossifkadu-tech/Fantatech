import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_he.dart';

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
    Locale('ar'),
    Locale('en'),
    Locale('he')
  ];

  /// No description provided for @appName.
  ///
  /// In he, this message translates to:
  /// **'FantaTech'**
  String get appName;

  /// No description provided for @dashboard.
  ///
  /// In he, this message translates to:
  /// **'לוח בקרה'**
  String get dashboard;

  /// No description provided for @security.
  ///
  /// In he, this message translates to:
  /// **'אבטחה'**
  String get security;

  /// No description provided for @cameras.
  ///
  /// In he, this message translates to:
  /// **'מצלמות'**
  String get cameras;

  /// No description provided for @smartHome.
  ///
  /// In he, this message translates to:
  /// **'בית חכם'**
  String get smartHome;

  /// No description provided for @automations.
  ///
  /// In he, this message translates to:
  /// **'אוטומציות'**
  String get automations;

  /// No description provided for @profile.
  ///
  /// In he, this message translates to:
  /// **'פרופיל'**
  String get profile;

  /// No description provided for @homeSecured.
  ///
  /// In he, this message translates to:
  /// **'הבית מאובטח'**
  String get homeSecured;

  /// No description provided for @homeUnsecured.
  ///
  /// In he, this message translates to:
  /// **'הבית לא מאובטח'**
  String get homeUnsecured;

  /// No description provided for @arm.
  ///
  /// In he, this message translates to:
  /// **'הפעל'**
  String get arm;

  /// No description provided for @disarm.
  ///
  /// In he, this message translates to:
  /// **'כבה'**
  String get disarm;

  /// No description provided for @devices.
  ///
  /// In he, this message translates to:
  /// **'מכשירים'**
  String get devices;

  /// No description provided for @online.
  ///
  /// In he, this message translates to:
  /// **'מחובר'**
  String get online;

  /// No description provided for @offline.
  ///
  /// In he, this message translates to:
  /// **'מנותק'**
  String get offline;

  /// No description provided for @lights.
  ///
  /// In he, this message translates to:
  /// **'תאורה'**
  String get lights;

  /// No description provided for @blinds.
  ///
  /// In he, this message translates to:
  /// **'תריסים'**
  String get blinds;

  /// No description provided for @airConditioner.
  ///
  /// In he, this message translates to:
  /// **'מזגן'**
  String get airConditioner;

  /// No description provided for @smartPlug.
  ///
  /// In he, this message translates to:
  /// **'שקע חכם'**
  String get smartPlug;

  /// No description provided for @smartSwitch.
  ///
  /// In he, this message translates to:
  /// **'מפסק חכם'**
  String get smartSwitch;

  /// No description provided for @sensors.
  ///
  /// In he, this message translates to:
  /// **'חיישנים'**
  String get sensors;

  /// No description provided for @motionSensor.
  ///
  /// In he, this message translates to:
  /// **'חיישן תנועה'**
  String get motionSensor;

  /// No description provided for @doorSensor.
  ///
  /// In he, this message translates to:
  /// **'חיישן דלת'**
  String get doorSensor;

  /// No description provided for @windowSensor.
  ///
  /// In he, this message translates to:
  /// **'חיישן חלון'**
  String get windowSensor;

  /// No description provided for @liveView.
  ///
  /// In he, this message translates to:
  /// **'שידור חי'**
  String get liveView;

  /// No description provided for @recordings.
  ///
  /// In he, this message translates to:
  /// **'הקלטות'**
  String get recordings;

  /// No description provided for @motionDetection.
  ///
  /// In he, this message translates to:
  /// **'זיהוי תנועה'**
  String get motionDetection;

  /// No description provided for @eventHistory.
  ///
  /// In he, this message translates to:
  /// **'היסטוריית אירועים'**
  String get eventHistory;

  /// No description provided for @realTimeAlerts.
  ///
  /// In he, this message translates to:
  /// **'התראות בזמן אמת'**
  String get realTimeAlerts;

  /// No description provided for @addAutomation.
  ///
  /// In he, this message translates to:
  /// **'הוסף אוטומציה'**
  String get addAutomation;

  /// No description provided for @users.
  ///
  /// In he, this message translates to:
  /// **'משתמשים'**
  String get users;

  /// No description provided for @permissions.
  ///
  /// In he, this message translates to:
  /// **'הרשאות'**
  String get permissions;

  /// No description provided for @deviceConnection.
  ///
  /// In he, this message translates to:
  /// **'חיבור מכשירים'**
  String get deviceConnection;

  /// No description provided for @gateway.
  ///
  /// In he, this message translates to:
  /// **'שרת / Gateway'**
  String get gateway;

  /// No description provided for @on.
  ///
  /// In he, this message translates to:
  /// **'פועל'**
  String get on;

  /// No description provided for @off.
  ///
  /// In he, this message translates to:
  /// **'כבוי'**
  String get off;

  /// No description provided for @temperature.
  ///
  /// In he, this message translates to:
  /// **'טמפרטורה'**
  String get temperature;

  /// No description provided for @humidity.
  ///
  /// In he, this message translates to:
  /// **'לחות'**
  String get humidity;

  /// No description provided for @battery.
  ///
  /// In he, this message translates to:
  /// **'סוללה'**
  String get battery;

  /// No description provided for @lastSeen.
  ///
  /// In he, this message translates to:
  /// **'נראה לאחרונה'**
  String get lastSeen;

  /// No description provided for @noDevices.
  ///
  /// In he, this message translates to:
  /// **'אין מכשירים'**
  String get noDevices;

  /// No description provided for @addDevice.
  ///
  /// In he, this message translates to:
  /// **'הוסף מכשיר'**
  String get addDevice;

  /// No description provided for @allDevices.
  ///
  /// In he, this message translates to:
  /// **'כל המכשירים'**
  String get allDevices;

  /// No description provided for @activeAlerts.
  ///
  /// In he, this message translates to:
  /// **'התראות פעילות'**
  String get activeAlerts;

  /// No description provided for @noAlerts.
  ///
  /// In he, this message translates to:
  /// **'אין התראות'**
  String get noAlerts;

  /// No description provided for @emergencyMode.
  ///
  /// In he, this message translates to:
  /// **'מצב חירום'**
  String get emergencyMode;

  /// No description provided for @quietMode.
  ///
  /// In he, this message translates to:
  /// **'מצב שקט'**
  String get quietMode;

  /// No description provided for @settings.
  ///
  /// In he, this message translates to:
  /// **'הגדרות'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In he, this message translates to:
  /// **'שפה'**
  String get language;

  /// No description provided for @theme.
  ///
  /// In he, this message translates to:
  /// **'ערכת נושא'**
  String get theme;

  /// No description provided for @notifications.
  ///
  /// In he, this message translates to:
  /// **'התראות'**
  String get notifications;

  /// No description provided for @about.
  ///
  /// In he, this message translates to:
  /// **'אודות'**
  String get about;

  /// No description provided for @version.
  ///
  /// In he, this message translates to:
  /// **'גרסה'**
  String get version;

  /// No description provided for @signOut.
  ///
  /// In he, this message translates to:
  /// **'התנתק'**
  String get signOut;

  /// No description provided for @welcomeBack.
  ///
  /// In he, this message translates to:
  /// **'ברוך השב'**
  String get welcomeBack;

  /// No description provided for @goodMorning.
  ///
  /// In he, this message translates to:
  /// **'בוקר טוב'**
  String get goodMorning;

  /// No description provided for @goodAfternoon.
  ///
  /// In he, this message translates to:
  /// **'צהריים טובים'**
  String get goodAfternoon;

  /// No description provided for @goodEvening.
  ///
  /// In he, this message translates to:
  /// **'ערב טוב'**
  String get goodEvening;

  /// No description provided for @devicesOnline.
  ///
  /// In he, this message translates to:
  /// **'{count} מכשירים מחוברים'**
  String devicesOnline(int count);

  /// No description provided for @automationActive.
  ///
  /// In he, this message translates to:
  /// **'{count} אוטומציות פעילות'**
  String automationActive(int count);

  /// No description provided for @ifCondition.
  ///
  /// In he, this message translates to:
  /// **'אם'**
  String get ifCondition;

  /// No description provided for @thenAction.
  ///
  /// In he, this message translates to:
  /// **'אז'**
  String get thenAction;

  /// No description provided for @enabled.
  ///
  /// In he, this message translates to:
  /// **'פעיל'**
  String get enabled;

  /// No description provided for @disabled.
  ///
  /// In he, this message translates to:
  /// **'לא פעיל'**
  String get disabled;

  /// No description provided for @cancel.
  ///
  /// In he, this message translates to:
  /// **'ביטול'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In he, this message translates to:
  /// **'שמור'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In he, this message translates to:
  /// **'מחק'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In he, this message translates to:
  /// **'ערוך'**
  String get edit;

  /// No description provided for @confirm.
  ///
  /// In he, this message translates to:
  /// **'אישור'**
  String get confirm;
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
      <String>['ar', 'en', 'he'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
    case 'he':
      return AppLocalizationsHe();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
