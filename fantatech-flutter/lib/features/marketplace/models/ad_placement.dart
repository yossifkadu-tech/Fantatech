/// Where a native recommendation may appear, and the hard UX rules guarding it.
class AdPlacement {
  final String key;
  final String screenRoute;
  final int maxPerSession;

  const AdPlacement({
    required this.key,
    required this.screenRoute,
    this.maxPerSession = 1,
  });

  /// Routes where advertising is NEVER allowed (security / emergency / auth).
  static const Set<String> blockedRoutes = {
    'security',
    'cyber',
    'panic',
    'camera_player',
    'breakers',
    'sos',
    'login',
    'biometric',
  };

  /// True when a recommendation may render on [route] given the global
  /// armed/emergency state.
  static bool isAllowedOn(String route, {bool emergencyActive = false}) {
    if (emergencyActive) return false;
    return !blockedRoutes.contains(route);
  }
}
