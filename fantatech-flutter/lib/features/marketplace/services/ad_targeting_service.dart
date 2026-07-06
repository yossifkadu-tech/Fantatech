/// Privacy-first, on-device targeting. Derives an anonymous profile from the
/// categories of devices the user already owns — never sends PII to the cloud.
class AdTargetingService {
  /// Categories present in the home (e.g. {'camera','light'}).
  final Set<String> ownedCategories;

  const AdTargetingService(this.ownedCategories);

  /// Build from a list of device type names.
  factory AdTargetingService.fromDeviceTypes(Iterable<String> deviceTypeNames) {
    return AdTargetingService(_mapTypesToCategories(deviceTypeNames).toSet());
  }

  /// Security-relevant categories every home "should" have. Gaps drive
  /// the strongest (highest-value) recommendations.
  static const _securityBaseline = {'camera', 'sensor', 'lock', 'alarm', 'gateway'};

  /// Categories the user lacks → recommendation opportunities.
  Set<String> get categoryGaps =>
      _securityBaseline.difference(ownedCategories);

  bool owns(String category) => ownedCategories.contains(category);

  static Iterable<String> _mapTypesToCategories(Iterable<String> types) {
    return types.map((t) {
      switch (t) {
        case 'camera':
          return 'camera';
        case 'light':
          return 'light';
        case 'smartLock':
          return 'lock';
        case 'motionSensor':
        case 'doorSensor':
        case 'windowSensor':
        case 'smokeSensor':
        case 'waterLeakSensor':
          return 'sensor';
        case 'gateway':
        case 'router':
          return 'gateway';
        case 'airConditioner':
          return 'climate';
        case 'smartPlug':
        case 'smartSwitch':
          return 'plug';
        default:
          return 'other';
      }
    });
  }
}
