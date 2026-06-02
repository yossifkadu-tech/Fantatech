// ─────────────────────────────────────────────────────────────────────────────
// FaceDetectionService — Google ML Kit face detection wrapper
//
// Works 100% on-device (no cloud, no cost, no internet required).
// Detects faces + landmarks + emotions from image files or bytes.
// ─────────────────────────────────────────────────────────────────────────────
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import '../../models/face_analysis.dart';

class FaceDetectionService {
  static FaceDetector? _detector;

  static FaceDetector get _instance {
    _detector ??= FaceDetector(
      options: FaceDetectorOptions(
        enableLandmarks:      true,
        enableClassification: true,  // smile + eye-open probability
        enableTracking:       false,
        performanceMode:      FaceDetectorMode.accurate,
        minFaceSize:          0.10,  // detect faces as small as 10% of frame
      ),
    );
    return _detector!;
  }

  // ── Analyze from file path ──────────────────────────────────────────────────

  static Future<List<DetectedFace>> detectFromFile(String path) async {
    try {
      final inputImage = InputImage.fromFilePath(path);
      final faces = await _instance.processImage(inputImage);
      return _convert(faces);
    } catch (_) {
      return [];
    }
  }

  // ── Analyze from File object ────────────────────────────────────────────────

  static Future<List<DetectedFace>> detectFromFileObj(File file) async {
    return detectFromFile(file.path);
  }

  // ── Convert ML Kit faces → our model ───────────────────────────────────────

  static List<DetectedFace> _convert(List<Face> mlFaces) {
    return mlFaces.map((f) {
      final box = f.boundingBox;
      return DetectedFace(
        boundingBox: Rect.fromLTWH(
          box.left.toDouble(),
          box.top.toDouble(),
          box.width.toDouble(),
          box.height.toDouble(),
        ),
        smileProbability:          f.smilingProbability,
        leftEyeOpenProbability:    f.leftEyeOpenProbability,
        rightEyeOpenProbability:   f.rightEyeOpenProbability,
        headEulerAngleY:           f.headEulerAngleY,
        headEulerAngleZ:           f.headEulerAngleZ,
      );
    }).toList();
  }

  // ── Dispose ────────────────────────────────────────────────────────────────

  static void dispose() {
    _detector?.close();
    _detector = null;
  }
}
