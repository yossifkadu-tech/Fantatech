// ─────────────────────────────────────────────────────────────────────────────
// AzureFaceService — Microsoft Azure Face API wrapper
//
// Handles: enrollment (create person + add face), training, identification.
// Person Group ID: 'fantatech_home' (one per installation).
//
// Requires:
//   endpoint: https://{resource}.cognitiveservices.azure.com/
//   apiKey  : 32-char hex key from Azure portal
// ─────────────────────────────────────────────────────────────────────────────
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../../models/known_person.dart';

class AzureFaceService {
  final String endpoint;
  final String apiKey;

  static const String _groupId = 'fantatech_home';

  AzureFaceService({required this.endpoint, required this.apiKey});

  String get _base =>
      '${endpoint.endsWith('/') ? endpoint : '$endpoint/'}'
      'face/v1.0';

  Map<String, String> get _authHeader =>
      {'Ocp-Apim-Subscription-Key': apiKey};

  Map<String, String> get _jsonHeader => {
    ..._authHeader,
    'Content-Type': 'application/json',
  };

  Map<String, String> get _binaryHeader => {
    ..._authHeader,
    'Content-Type': 'application/octet-stream',
  };

  // ── Detect faces ────────────────────────────────────────────────────────────
  /// Detect faces in [imageBytes], return list of {faceId, faceRectangle}.
  Future<List<Map<String, dynamic>>> detectFaces(Uint8List imageBytes) async {
    try {
      final url = Uri.parse(
          '$_base/detect?returnFaceId=true&returnFaceLandmarks=false'
          '&recognitionModel=recognition_04&detectionModel=detection_01');
      final resp = await http
          .post(url, headers: _binaryHeader, body: imageBytes)
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) return [];
      final list = jsonDecode(resp.body) as List;
      return list.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  // ── Person Group ────────────────────────────────────────────────────────────
  /// Create person group (idempotent — safe to call every time).
  Future<bool> ensurePersonGroup() async {
    try {
      final url = Uri.parse('$_base/persongroups/$_groupId');
      final resp = await http
          .put(
            url,
            headers: _jsonHeader,
            body: jsonEncode({
              'name': 'FantaTech Home',
              'userData': 'smarthome',
              'recognitionModel': 'recognition_04',
            }),
          )
          .timeout(const Duration(seconds: 10));
      return resp.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ── Create person ────────────────────────────────────────────────────────────
  Future<String?> createPerson(String name) async {
    try {
      final url = Uri.parse('$_base/persongroups/$_groupId/persons');
      final resp = await http
          .post(url,
              headers: _jsonHeader,
              body: jsonEncode({'name': name, 'userData': name}))
          .timeout(const Duration(seconds: 10));
      if (resp.statusCode != 200) return null;
      return (jsonDecode(resp.body) as Map)['personId'] as String?;
    } catch (_) {
      return null;
    }
  }

  // ── Add face to person ───────────────────────────────────────────────────────
  Future<String?> addFaceToPerson(
      String personId, Uint8List imageBytes) async {
    try {
      final url = Uri.parse(
          '$_base/persongroups/$_groupId/persons/$personId/persistedFaces');
      final resp = await http
          .post(url, headers: _binaryHeader, body: imageBytes)
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) return null;
      return (jsonDecode(resp.body) as Map)['persistedFaceId'] as String?;
    } catch (_) {
      return null;
    }
  }

  // ── Train ────────────────────────────────────────────────────────────────────
  Future<bool> trainPersonGroup() async {
    try {
      final url = Uri.parse('$_base/persongroups/$_groupId/train');
      final resp = await http
          .post(url, headers: _authHeader)
          .timeout(const Duration(seconds: 10));
      return resp.statusCode == 202;
    } catch (_) {
      return false;
    }
  }

  /// Poll training status: 'running' | 'succeeded' | 'failed'
  Future<String> getTrainingStatus() async {
    try {
      final url = Uri.parse('$_base/persongroups/$_groupId/training');
      final resp = await http
          .get(url, headers: _authHeader)
          .timeout(const Duration(seconds: 10));
      if (resp.statusCode != 200) return 'failed';
      return (jsonDecode(resp.body) as Map)['status'] as String? ?? 'failed';
    } catch (_) {
      return 'failed';
    }
  }

  // ── Identify faces ───────────────────────────────────────────────────────────
  /// Identify [faceIds] against the person group.
  /// Returns list of {faceId, candidates: [{personId, confidence}]}.
  Future<List<Map<String, dynamic>>> identifyFaces(
      List<String> faceIds) async {
    if (faceIds.isEmpty) return [];
    try {
      final url = Uri.parse('$_base/identify');
      final resp = await http
          .post(url,
              headers: _jsonHeader,
              body: jsonEncode({
                'personGroupId': _groupId,
                'faceIds': faceIds,
                'maxNumOfCandidatesReturned': 1,
                'confidenceThreshold': 0.55,
              }))
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) return [];
      return (jsonDecode(resp.body) as List).cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  // ── Resolve faceIds → identities ─────────────────────────────────────────────
  /// Given a list of Azure faceIds and the local known persons,
  /// returns a map faceId → FaceIdentityResult.
  Future<Map<String, FaceIdentityResult>> resolveIdentities(
    List<String> faceIds,
    List<KnownPerson> knownPersons,
  ) async {
    final results = <String, FaceIdentityResult>{};
    if (faceIds.isEmpty) return results;

    final identifications = await identifyFaces(faceIds);

    for (final item in identifications) {
      final faceId    = item['faceId'] as String? ?? '';
      final candidates = item['candidates'] as List? ?? [];

      if (candidates.isEmpty) {
        results[faceId] = FaceIdentityResult.unknown;
      } else {
        final best      = candidates.first as Map;
        final personId  = best['personId'] as String? ?? '';
        final confidence = (best['confidence'] as num?)?.toDouble() ?? 0.0;

        // Look up local name
        final person = knownPersons
            .where((p) => p.azurePersonId == personId)
            .firstOrNull;

        results[faceId] = FaceIdentityResult(
          personId:   personId,
          personName: person?.name ?? personId.substring(0, 8),
          confidence: confidence,
          identified: confidence >= 0.55,
        );
      }
    }

    return results;
  }

  // ── Delete person ────────────────────────────────────────────────────────────
  Future<bool> deletePerson(String personId) async {
    try {
      final url = Uri.parse(
          '$_base/persongroups/$_groupId/persons/$personId');
      final resp = await http
          .delete(url, headers: _authHeader)
          .timeout(const Duration(seconds: 10));
      return resp.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ── Test connectivity ─────────────────────────────────────────────────────────
  Future<bool> testConnection() async {
    try {
      final url = Uri.parse('$_base/persongroups/$_groupId');
      final resp = await http
          .get(url, headers: _authHeader)
          .timeout(const Duration(seconds: 8));
      // 200 = group exists, 404 = doesn't exist yet, both mean API is reachable
      return resp.statusCode == 200 || resp.statusCode == 404;
    } catch (_) {
      return false;
    }
  }
}
