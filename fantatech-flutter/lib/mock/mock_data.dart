import '../models/device.dart';

class MockData {
  static List<Device> devices = [
    Device(
      id: 'd1',
      name: 'סלון - אור ראשי',
      type: DeviceType.light,
      isOn: true,
      room: 'סלון',
      attributes: {'brightness': 80, 'color': 'white'},
    ),
    Device(
      id: 'd2',
      name: 'חדר שינה - אור',
      type: DeviceType.light,
      isOn: false,
      room: 'חדר שינה',
      attributes: {'brightness': 50, 'color': 'warm'},
    ),
    Device(
      id: 'd3',
      name: 'סלון - תריס',
      type: DeviceType.blind,
      isOn: true,
      room: 'סלון',
      attributes: {'position': 60},
    ),
    Device(
      id: 'd4',
      name: 'מזגן סלון',
      type: DeviceType.airConditioner,
      isOn: false,
      room: 'סלון',
      attributes: {'temperature': 23, 'mode': 'cool', 'fan': 'auto'},
    ),
    Device(
      id: 'd5',
      name: 'שקע - מטבח',
      type: DeviceType.smartPlug,
      isOn: true,
      room: 'מטבח',
      attributes: {'power': 1200},
    ),
    Device(
      id: 'd6',
      name: 'דוד מים',
      type: DeviceType.waterHeater,
      isOn: false,
      room: 'מטבח',
      attributes: {'temperature': 60},
    ),
    Device(
      id: 'd7',
      name: 'חיישן תנועה - כניסה',
      type: DeviceType.motionSensor,
      isOn: true,
      room: 'כניסה',
      attributes: {'detected': false, 'battery': 85},
    ),
    Device(
      id: 'd8',
      name: 'חיישן דלת - כניסה ראשית',
      type: DeviceType.doorSensor,
      isOn: true,
      room: 'כניסה',
      attributes: {'open': false, 'battery': 92},
    ),
    Device(
      id: 'd9',
      name: 'חיישן חלון - סלון',
      type: DeviceType.windowSensor,
      status: DeviceStatus.offline,
      isOn: false,
      room: 'סלון',
      attributes: {'open': false, 'battery': 12},
    ),
    Device(
      id: 'd10',
      name: 'מפסק חכם - מסדרון',
      type: DeviceType.smartSwitch,
      isOn: true,
      room: 'מסדרון',
      attributes: {},
    ),
    Device(
      id: 'd11',
      name: 'דוד מים - ראשי',
      type: DeviceType.waterHeater,
      isOn: false,
      room: 'מטבח',
      attributes: {
        'temperature': 60,
        'targetTemp': 65,
        'protocol': 'wifi',
        'timer': 0,
        'mode': 'eco',
        'power': 2000,
      },
    ),
    Device(
      id: 'd12',
      name: 'דוד מים - חדר אמבטיה',
      type: DeviceType.waterHeater,
      isOn: true,
      room: 'חדר אמבטיה',
      attributes: {
        'temperature': 55,
        'targetTemp': 60,
        'protocol': 'zigbee',
        'timer': 30,
        'mode': 'full',
        'power': 1800,
      },
    ),
  ];

  static List<Camera> cameras = [
    Camera(id: 'c1', name: 'כניסה ראשית', room: 'outdoor', isOnline: true, motionDetection: true),
    Camera(id: 'c2', name: 'גינה אחורית', room: 'outdoor', isOnline: true, motionDetection: true),
    Camera(id: 'c3', name: 'סלון', room: 'indoor', isOnline: false, motionDetection: false),
    Camera(id: 'c4', name: 'מוסך', room: 'outdoor', isOnline: true, motionDetection: false),
  ];

  static List<SecurityEvent> events = [
    SecurityEvent(
      id: 'e1',
      description: 'תנועה זוהתה — כניסה',
      timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      deviceId: 'd7',
      isAlert: true,
    ),
    SecurityEvent(
      id: 'e2',
      description: 'דלת נפתחה — כניסה ראשית',
      timestamp: DateTime.now().subtract(const Duration(minutes: 22)),
      deviceId: 'd8',
      isAlert: false,
    ),
    SecurityEvent(
      id: 'e3',
      description: 'מערכת הופעלה',
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      deviceId: 'system',
      isAlert: false,
    ),
    SecurityEvent(
      id: 'e4',
      description: 'ניסיון כניסה לא מזוהה',
      timestamp: DateTime.now().subtract(const Duration(hours: 5)),
      deviceId: 'c1',
      isAlert: true,
    ),
  ];

  static List<Automation> automations = [
    Automation(
      id: 'a1',
      name: 'עזיבת הבית',
      condition: 'אם אין אף אחד בבית',
      action: 'הפעל אזעקה + כבה הכל',
      isEnabled: true,
    ),
    Automation(
      id: 'a2',
      name: 'כניסה לבית',
      condition: 'אם נכנסים לבית',
      action: 'הדלק אורות + כבה אזעקה',
      isEnabled: true,
    ),
    Automation(
      id: 'a3',
      name: 'לילה טוב',
      condition: 'שעה 23:00',
      action: 'כבה הכל + נעל דלתות',
      isEnabled: true,
    ),
    Automation(
      id: 'a4',
      name: 'בוקר טוב',
      condition: 'שעה 07:00 בימי חול',
      action: 'פתח תריסים + הדלק קפה',
      isEnabled: false,
    ),
    Automation(
      id: 'a5',
      name: 'חיסכון בחשמל',
      condition: 'אם אין תנועה 30 דקות',
      action: 'כבה אורות ומזגנים',
      isEnabled: true,
    ),
  ];
}
