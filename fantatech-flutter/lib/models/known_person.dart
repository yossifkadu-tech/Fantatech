// ─────────────────────────────────────────────────────────────────────────────
// KnownPerson — locally enrolled person for face recognition
// ─────────────────────────────────────────────────────────────────────────────

class KnownPerson {
  final String id;           // local UUID
  String name;
  String? azurePersonId;     // Azure person GUID (after enrollment)
  String? localImagePath;    // path to local reference photo
  DateTime enrolledAt;
  bool isEnrolledInAzure;    // successfully synced to Azure

  KnownPerson({
    required this.id,
    required this.name,
    this.azurePersonId,
    this.localImagePath,
    required this.enrolledAt,
    this.isEnrolledInAzure = false,
  });

  Map<String, dynamic> toJson() => {
    'id':               id,
    'name':             name,
    'azurePersonId':    azurePersonId,
    'localImagePath':   localImagePath,
    'enrolledAt':       enrolledAt.toIso8601String(),
    'isEnrolledInAzure': isEnrolledInAzure,
  };

  factory KnownPerson.fromJson(Map<String, dynamic> j) => KnownPerson(
    id:               j['id'] as String,
    name:             j['name'] as String,
    azurePersonId:    j['azurePersonId'] as String?,
    localImagePath:   j['localImagePath'] as String?,
    enrolledAt:       DateTime.parse(j['enrolledAt'] as String),
    isEnrolledInAzure: j['isEnrolledInAzure'] as bool? ?? false,
  );
}

/// Result of identifying one face against the known-person database
class FaceIdentityResult {
  final String? personId;       // Azure personId
  final String? personName;     // matched name
  final double confidence;      // 0.0 – 1.0
  final bool identified;        // was anyone matched?

  const FaceIdentityResult({
    this.personId,
    this.personName,
    required this.confidence,
    required this.identified,
  });

  static const unknown = FaceIdentityResult(
    confidence: 0, identified: false,
  );

  String get displayName => identified
      ? '$personName (${(confidence * 100).toStringAsFixed(0)}%)'
      : 'לא מזוהה';
}
