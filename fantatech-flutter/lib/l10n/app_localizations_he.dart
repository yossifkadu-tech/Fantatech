// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hebrew (`he`).
class AppLocalizationsHe extends AppLocalizations {
  AppLocalizationsHe([String locale = 'he']) : super(locale);

  @override
  String get appName => 'FantaTech';

  @override
  String get dashboard => 'לוח בקרה';

  @override
  String get security => 'אבטחה';

  @override
  String get cameras => 'מצלמות';

  @override
  String get smartHome => 'בית חכם';

  @override
  String get automations => 'אוטומציות';

  @override
  String get profile => 'פרופיל';

  @override
  String get homeSecured => 'הבית מאובטח';

  @override
  String get homeUnsecured => 'הבית לא מאובטח';

  @override
  String get arm => 'הפעל';

  @override
  String get disarm => 'כבה';

  @override
  String get devices => 'מכשירים';

  @override
  String get online => 'מחובר';

  @override
  String get offline => 'מנותק';

  @override
  String get lights => 'תאורה';

  @override
  String get blinds => 'תריסים';

  @override
  String get airConditioner => 'מזגן';

  @override
  String get smartPlug => 'שקע חכם';

  @override
  String get smartSwitch => 'מפסק חכם';

  @override
  String get sensors => 'חיישנים';

  @override
  String get motionSensor => 'חיישן תנועה';

  @override
  String get doorSensor => 'חיישן דלת';

  @override
  String get windowSensor => 'חיישן חלון';

  @override
  String get liveView => 'שידור חי';

  @override
  String get recordings => 'הקלטות';

  @override
  String get motionDetection => 'זיהוי תנועה';

  @override
  String get eventHistory => 'היסטוריית אירועים';

  @override
  String get realTimeAlerts => 'התראות בזמן אמת';

  @override
  String get addAutomation => 'הוסף אוטומציה';

  @override
  String get users => 'משתמשים';

  @override
  String get permissions => 'הרשאות';

  @override
  String get deviceConnection => 'חיבור מכשירים';

  @override
  String get gateway => 'שרת / Gateway';

  @override
  String get on => 'פועל';

  @override
  String get off => 'כבוי';

  @override
  String get temperature => 'טמפרטורה';

  @override
  String get humidity => 'לחות';

  @override
  String get battery => 'סוללה';

  @override
  String get lastSeen => 'נראה לאחרונה';

  @override
  String get noDevices => 'אין מכשירים';

  @override
  String get addDevice => 'הוסף מכשיר';

  @override
  String get allDevices => 'כל המכשירים';

  @override
  String get activeAlerts => 'התראות פעילות';

  @override
  String get noAlerts => 'אין התראות';

  @override
  String get emergencyMode => 'מצב חירום';

  @override
  String get quietMode => 'מצב שקט';

  @override
  String get settings => 'הגדרות';

  @override
  String get language => 'שפה';

  @override
  String get theme => 'ערכת נושא';

  @override
  String get notifications => 'התראות';

  @override
  String get about => 'אודות';

  @override
  String get version => 'גרסה';

  @override
  String get signOut => 'התנתק';

  @override
  String get welcomeBack => 'ברוך השב';

  @override
  String get goodMorning => 'בוקר טוב';

  @override
  String get goodAfternoon => 'צהריים טובים';

  @override
  String get goodEvening => 'ערב טוב';

  @override
  String devicesOnline(int count) {
    return '$count מכשירים מחוברים';
  }

  @override
  String automationActive(int count) {
    return '$count אוטומציות פעילות';
  }

  @override
  String get ifCondition => 'אם';

  @override
  String get thenAction => 'אז';

  @override
  String get enabled => 'פעיל';

  @override
  String get disabled => 'לא פעיל';

  @override
  String get cancel => 'ביטול';

  @override
  String get save => 'שמור';

  @override
  String get delete => 'מחק';

  @override
  String get edit => 'ערוך';

  @override
  String get confirm => 'אישור';
}
