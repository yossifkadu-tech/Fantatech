// ─────────────────────────────────────────────────────────────────────────────
// Face Analysis Models
// ─────────────────────────────────────────────────────────────────────────────
import 'dart:typed_data';
import 'package:flutter/material.dart';

/// One detected face in a frame
class DetectedFace {
  final Rect boundingBox;
  final double? smileProbability;
  final double? leftEyeOpenProbability;
  final double? rightEyeOpenProbability;
  final double? headEulerAngleY; // negative = left, positive = right
  final double? headEulerAngleZ; // tilt

  const DetectedFace({
    required this.boundingBox,
    this.smileProbability,
    this.leftEyeOpenProbability,
    this.rightEyeOpenProbability,
    this.headEulerAngleY,
    this.headEulerAngleZ,
  });

  /// Where is the person looking?
  String get gazeDirection {
    final y = headEulerAngleY;
    if (y == null) return 'ישר';
    if (y > 20)  return 'ימין';
    if (y < -20) return 'שמאל';
    return 'ישר';
  }

  /// Is the person smiling?
  bool get isSmiling => (smileProbability ?? 0) > 0.7;

  /// Are eyes open?
  bool get eyesOpen =>
      (leftEyeOpenProbability ?? 1) > 0.5 &&
      (rightEyeOpenProbability ?? 1) > 0.5;
}

/// Full analysis result for one captured frame
class FaceAnalysisResult {
  final String id;
  final String cameraId;
  final String cameraName;
  final DateTime timestamp;
  final List<DetectedFace> faces;
  final Uint8List? thumbnail; // PNG of the captured frame

  const FaceAnalysisResult({
    required this.id,
    required this.cameraId,
    required this.cameraName,
    required this.timestamp,
    required this.faces,
    this.thumbnail,
  });

  int get faceCount => faces.length;

  /// Human-readable summary
  String get summary {
    if (faces.isEmpty) return 'לא זוהו פנים';
    if (faces.length == 1) return 'פנים 1 זוהה';
    return '${faces.length} פנים זוהו';
  }

  /// Alert level based on face count
  FaceAlertLevel get alertLevel {
    if (faces.isEmpty) return FaceAlertLevel.none;
    if (faces.length == 1) return FaceAlertLevel.low;
    if (faces.length <= 3) return FaceAlertLevel.medium;
    return FaceAlertLevel.high;
  }
}

enum FaceAlertLevel { none, low, medium, high }

extension FaceAlertLevelX on FaceAlertLevel {
  Color get color {
    switch (this) {
      case FaceAlertLevel.none:   return Colors.white38;
      case FaceAlertLevel.low:    return const Color(0xFF00C896);
      case FaceAlertLevel.medium: return const Color(0xFFFFA500);
      case FaceAlertLevel.high:   return const Color(0xFFFF4444);
    }
  }

  String get label {
    switch (this) {
      case FaceAlertLevel.none:   return 'ריק';
      case FaceAlertLevel.low:    return 'רגיל';
      case FaceAlertLevel.medium: return 'מספר אנשים';
      case FaceAlertLevel.high:   return 'עומס גבוה';
    }
  }
}
