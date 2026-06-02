// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appName => 'FantaTech';

  @override
  String get dashboard => 'لوحة التحكم';

  @override
  String get security => 'الأمان';

  @override
  String get cameras => 'الكاميرات';

  @override
  String get smartHome => 'المنزل الذكي';

  @override
  String get automations => 'الأتمتة';

  @override
  String get profile => 'الملف الشخصي';

  @override
  String get homeSecured => 'المنزل آمن';

  @override
  String get homeUnsecured => 'المنزل غير آمن';

  @override
  String get arm => 'تفعيل';

  @override
  String get disarm => 'تعطيل';

  @override
  String get devices => 'الأجهزة';

  @override
  String get online => 'متصل';

  @override
  String get offline => 'غير متصل';

  @override
  String get lights => 'الإضاءة';

  @override
  String get blinds => 'الستائر';

  @override
  String get airConditioner => 'مكيف الهواء';

  @override
  String get smartPlug => 'مقبس ذكي';

  @override
  String get smartSwitch => 'مفتاح ذكي';

  @override
  String get sensors => 'المستشعرات';

  @override
  String get motionSensor => 'مستشعر الحركة';

  @override
  String get doorSensor => 'مستشعر الباب';

  @override
  String get windowSensor => 'مستشعر النافذة';

  @override
  String get liveView => 'بث مباشر';

  @override
  String get recordings => 'التسجيلات';

  @override
  String get motionDetection => 'اكتشاف الحركة';

  @override
  String get eventHistory => 'سجل الأحداث';

  @override
  String get realTimeAlerts => 'تنبيهات فورية';

  @override
  String get addAutomation => 'إضافة أتمتة';

  @override
  String get users => 'المستخدمون';

  @override
  String get permissions => 'الصلاحيات';

  @override
  String get deviceConnection => 'ربط الأجهزة';

  @override
  String get gateway => 'البوابة / الخادم';

  @override
  String get on => 'تشغيل';

  @override
  String get off => 'إيقاف';

  @override
  String get temperature => 'درجة الحرارة';

  @override
  String get humidity => 'الرطوبة';

  @override
  String get battery => 'البطارية';

  @override
  String get lastSeen => 'آخر ظهور';

  @override
  String get noDevices => 'لا توجد أجهزة';

  @override
  String get addDevice => 'إضافة جهاز';

  @override
  String get allDevices => 'جميع الأجهزة';

  @override
  String get activeAlerts => 'التنبيهات النشطة';

  @override
  String get noAlerts => 'لا توجد تنبيهات';

  @override
  String get emergencyMode => 'وضع الطوارئ';

  @override
  String get quietMode => 'الوضع الهادئ';

  @override
  String get settings => 'الإعدادات';

  @override
  String get language => 'اللغة';

  @override
  String get theme => 'المظهر';

  @override
  String get notifications => 'الإشعارات';

  @override
  String get about => 'حول التطبيق';

  @override
  String get version => 'الإصدار';

  @override
  String get signOut => 'تسجيل الخروج';

  @override
  String get welcomeBack => 'مرحباً بعودتك';

  @override
  String get goodMorning => 'صباح الخير';

  @override
  String get goodAfternoon => 'مساء الخير';

  @override
  String get goodEvening => 'مساء النور';

  @override
  String devicesOnline(int count) {
    return '$count أجهزة متصلة';
  }

  @override
  String automationActive(int count) {
    return '$count أتمتة نشطة';
  }

  @override
  String get ifCondition => 'إذا';

  @override
  String get thenAction => 'إذن';

  @override
  String get enabled => 'مفعّل';

  @override
  String get disabled => 'معطّل';

  @override
  String get cancel => 'إلغاء';

  @override
  String get save => 'حفظ';

  @override
  String get delete => 'حذف';

  @override
  String get edit => 'تعديل';

  @override
  String get confirm => 'تأكيد';
}
