import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class LicenseOcrResult {
  final String rawText;
  final String? licenseNumber; // Driver's license number
  final String? vehiclePlate;  // e.g., 123TU4567
  final DateTime? expiryDate;

  const LicenseOcrResult({
    required this.rawText,
    this.licenseNumber,
    this.vehiclePlate,
    this.expiryDate,
  });
}

class LicenseOcrService {
  final TextRecognizer _recognizer = TextRecognizer();

  Future<LicenseOcrResult> scanImage(File imageFile) async {
    final inputImage = InputImage.fromFilePath(imageFile.path);
    final recognized = await _recognizer.processImage(inputImage);

    final buffer = StringBuffer();
    for (final block in recognized.blocks) {
      buffer.writeln('BLOCK: ${block.text}  bbox=${block.boundingBox}');
      for (final line in block.lines) {
        buffer.writeln('  LINE: ${line.text}');
        for (final el in line.elements) {
          buffer.writeln('    WORD: ${el.text}');
        }
      }
    }
    final rawDump = buffer.toString();
    debugPrint('OCR_RAW\n$rawDump');

    final allText = recognized.text;
    final parsed = _parseFields(allText);

    return LicenseOcrResult(
      rawText: allText,
      licenseNumber: parsed['licenseNumber'],
      vehiclePlate: parsed['vehiclePlate'],
      expiryDate: parsed['expiryDate'] != null ? DateTime.tryParse(parsed['expiryDate']!) : null,
    );
  }

  Map<String, String?> _parseFields(String text) {
    final results = <String, String?>{
      'licenseNumber': null,
      'vehiclePlate': null,
      'expiryDate': null,
    };

    final compact = text.toUpperCase().replaceAll(RegExp('[^A-Z0-9\n ]'), ' ');

    // Tunisian license plate: 3 digits + TU + 4 digits
    final plateRegex = RegExp(r"\b(\d{3}TU\d{4})\b");
    final plateMatch = plateRegex.firstMatch(compact);
    if (plateMatch != null) {
      results['vehiclePlate'] = plateMatch.group(1);
    }

    // Driver license number: heuristic - 6-12 alphanumerics, prefer lines containing LICENSE or NUM
    final lines = compact.split('\n');
    final likelyLine = lines.firstWhere(
      (l) => l.contains('LICENSE') || l.contains('NUM') || l.contains('PERMIS') || l.contains('DL'),
      orElse: () => '',
    );
    final licRegex = RegExp(r"\b([A-Z0-9]{6,12})\b");
    RegExpMatch? licMatch;
    if (likelyLine.isNotEmpty) {
      licMatch = licRegex.firstMatch(likelyLine);
    }
    licMatch ??= licRegex.firstMatch(compact);
    if (licMatch != null) {
      results['licenseNumber'] = licMatch.group(1);
    }

    // Dates: DD/MM/YYYY or YYYY-MM-DD
    final dateRegex = RegExp(r"\b((\d{2}[\/-]\d{2}[\/-]\d{4})|(\d{4}[\/-]\d{2}[\/-]\d{2}))\b");
    final dateMatch = dateRegex.firstMatch(text);
    if (dateMatch != null) {
      final rawDate = dateMatch.group(1)!;
      final iso = _toIsoDate(rawDate);
      results['expiryDate'] = iso;
    }

    // Tunisian license specific hints (French/Arabic cards)
    // Try to extract a numeric license ID (7-12 digits) from anywhere, prefer the longest.
    final idCandidates = RegExp(r"\b(\d{7,12})\b").allMatches(compact).map((m) => m.group(1)!).toList();
    if (idCandidates.isNotEmpty) {
      idCandidates.sort((a, b) => b.length.compareTo(a.length));
      results['licenseNumber'] ??= idCandidates.first;
    }

    return results;
  }

  String? _toIsoDate(String raw) {
    final s = raw.replaceAll('/', '-');
    // If DD-MM-YYYY -> convert to YYYY-MM-DD
    final ddmmyyyy = RegExp(r"^(\d{2})-(\d{2})-(\d{4})$");
    final m1 = ddmmyyyy.firstMatch(s);
    if (m1 != null) {
      return '${m1.group(3)}-${m1.group(2)}-${m1.group(1)}';
    }
    // Already YYYY-MM-DD
    if (RegExp(r"^\d{4}-\d{2}-\d{2}$").hasMatch(s)) return s;
    return null;
  }

  Future<void> close() async {
    await _recognizer.close();
  }
}


