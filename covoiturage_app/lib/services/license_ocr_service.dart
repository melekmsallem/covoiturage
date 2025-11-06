import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

class LicenseOCRService {
  final TextRecognizer _textRecognizer = TextRecognizer();
  final ImagePicker _imagePicker = ImagePicker();

  /// Extract text from driver's license image
  Future<String> extractTextFromImage(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      return recognizedText.text;
    } catch (e) {
      throw Exception('Failed to extract text from image: $e');
    }
  }

  /// Parse driver's license information from extracted text
  Future<DriverLicenseInfo?> parseLicenseInfo(String extractedText) async {
    try {
      final lines = extractedText.split('\n');
      final info = DriverLicenseInfo();

      // Debug: Print all extracted text to help debug
      print('OCR Extracted Text:');
      print(extractedText);
      print('---');

      final List<String> foundDates = [];
      final List<String> potentialNames = []; // Collect all potential name lines
      String? lastPrefixLine; // Track if we saw "1." or "2." on previous line
      int? firstNameIndex; // Track where we found firstName to help find lastName

      for (int i = 0; i < lines.length; i++) {
        final String line = lines[i];
        final cleanLine = line.trim();
        final upperLine = cleanLine.toUpperCase();
        
        // Extract license number (Tunisian formats)
        if (info.licenseNumber == null || info.licenseNumber!.isEmpty) {
          // 1) Format like 01/543353 or 01-543353
          final slashMatch = RegExp(r'\b\d{2}\s*[\/-]\s*\d{6}\b').firstMatch(cleanLine);
          if (slashMatch != null) {
            info.licenseNumber = slashMatch.group(0)!.replaceAll(RegExp(r'\s+'), '');
            print('Found license number (slash format): ${info.licenseNumber}');
          } else {
            // 2) 8-digit number like 15009213
            final eightDigitMatch = RegExp(r'\b\d{8}\b').firstMatch(cleanLine);
            if (eightDigitMatch != null) {
              info.licenseNumber = eightDigitMatch.group(0);
              print('Found license number (8-digit): ${info.licenseNumber}');
            }
          }
        }

        // Extract name (look for patterns like "1. MSALLEM" or "2. MOHAMED MALEK" or "2, MOHAMED MALEK")
        // Tunisian licenses have format "1. LASTNAME" (nom) and "2. FIRSTNAME" (prenom) or "2, FIRSTNAME"
        if (cleanLine.startsWith('1.') || cleanLine.startsWith('1,')) {
          final nameMatch = RegExp(r'^1[.,]\s*(.+)$').firstMatch(cleanLine);
          if (nameMatch != null) {
            final lastName = nameMatch.group(1)?.trim() ?? '';
            if (lastName.isNotEmpty) {
              info.lastName = lastName;
              print('Found last name (nom) from prefix 1.: ${info.lastName}');
            }
          }
        } else if (cleanLine.startsWith('2.') || cleanLine.startsWith('2,')) {
          final nameMatch = RegExp(r'^2[.,]\s*(.+)$').firstMatch(cleanLine);
          if (nameMatch != null) {
            final firstName = nameMatch.group(1)?.trim() ?? '';
            if (firstName.isNotEmpty) {
              info.firstName = firstName;
              print('Found first name (prenom) from prefix 2.: ${info.firstName}');
            }
          }
        }
        
        // Check if previous line had "1." or "2." prefix and this line is the name
        // Sometimes OCR separates the prefix and the name on different lines
        if (i > 0) {
          final prevLine = lines[i - 1].trim();
          final prevLineUpper = prevLine.toUpperCase();
          
          // Check if previous line is just "1." or "1," (prefix only)
          if ((prevLine == '1.' || prevLine == '1,' || prevLineUpper == '1.' || prevLineUpper == '1,' || 
               prevLine.startsWith('1.') || prevLine.startsWith('1,')) && 
              cleanLine.length > 3 && 
              cleanLine.length < 20 &&
              RegExp(r'^[A-Z\s]+$').hasMatch(cleanLine) &&
              !cleanLine.contains('PERMIS') &&
              !cleanLine.contains('REPUBLIQUE') &&
              !cleanLine.contains('TUNIS') &&
              !cleanLine.contains('CONDUIRE')) {
            if (info.lastName == null || info.lastName!.isEmpty) {
              info.lastName = cleanLine.trim();
              print('Found last name (nom) from line after 1.: ${info.lastName}');
              lastPrefixLine = '1.'; // Mark that we processed this
            }
          } else if ((prevLine == '2.' || prevLine == '2,' || prevLineUpper == '2.' || prevLineUpper == '2,' ||
                     prevLine.startsWith('2.') || prevLine.startsWith('2,')) &&
                     cleanLine.length > 5 && 
                     cleanLine.length < 30 &&
                     RegExp(r'^[A-Z\s]+$').hasMatch(cleanLine) &&
                     !cleanLine.contains('PERMIS') &&
                     !cleanLine.contains('REPUBLIQUE') &&
                     !cleanLine.contains('TUNIS') &&
                     !cleanLine.contains('CONDUIRE')) {
            if (info.firstName == null || info.firstName!.isEmpty) {
              info.firstName = cleanLine.trim();
              firstNameIndex = i; // Track where we found firstName
              print('Found first name (prenom) from line after 2.: ${info.firstName}');
              lastPrefixLine = '2.'; // Mark that we processed this
            }
          }
        }
        
        // Also check two lines back in case there's a blank line
        if (i > 1) {
          final prevPrevLine = lines[i - 2].trim();
          final prevPrevLineUpper = prevPrevLine.toUpperCase();
          
          if ((prevPrevLine == '1.' || prevPrevLine == '1,' || prevPrevLineUpper == '1.' || prevPrevLineUpper == '1,' ||
               prevPrevLine.startsWith('1.') || prevPrevLine.startsWith('1,')) && 
              cleanLine.length > 3 && 
              cleanLine.length < 20 &&
              RegExp(r'^[A-Z\s]+$').hasMatch(cleanLine) &&
              !cleanLine.contains('PERMIS') &&
              !cleanLine.contains('REPUBLIQUE') &&
              !cleanLine.contains('TUNIS') &&
              !cleanLine.contains('CONDUIRE')) {
            if (info.lastName == null || info.lastName!.isEmpty) {
              info.lastName = cleanLine.trim();
              print('Found last name (nom) from line 2 lines after 1.: ${info.lastName}');
              lastPrefixLine = '1.'; // Mark that we processed this
            }
          }
        }
        
        // Also look for patterns like "NOM:" or "NAME:"
        if (upperLine.contains('NOM:') || upperLine.contains('NAME:')) {
          final nameMatch = RegExp(r'(?:NOM:|NAME:)\s*(.+)').firstMatch(upperLine);
          if (nameMatch != null) {
            info.fullName = nameMatch.group(1)?.trim();
            print('Found name (NOM): ${info.fullName}');
          }
        }
        
        // Collect potential name lines (will process after all lines are scanned)
        // Always collect potential names, we'll filter them later
        if (cleanLine.length >= 4 && 
            cleanLine.length < 30 &&
            RegExp(r'^[A-Z\s]+$').hasMatch(cleanLine) &&
            !cleanLine.contains('PERMIS') &&
            !cleanLine.contains('REPUBLIQUE') &&
            !cleanLine.contains('TUNIS') &&
            !cleanLine.contains('CONDUIRE') &&
            !cleanLine.contains('A.T.T.T') &&
            // Exclude license class patterns (short codes like "AA B H", "A B", etc.)
            !RegExp(r'^[A-Z]{1,2}(\s+[A-Z]{1,2})*\s*$').hasMatch(cleanLine) &&
            // Make sure it's not a license class (typically 2-3 letters separated by spaces, max 10 chars total)
            !(cleanLine.split(' ').length <= 4 && cleanLine.replaceAll(' ', '').length <= 10) &&
            // Don't add if it's already been processed from prefix
            !(info.lastName != null && cleanLine.trim() == info.lastName) &&
            !(info.firstName != null && cleanLine.trim() == info.firstName) &&
            // Don't add if we just processed this line as a name from prefix
            !(lastPrefixLine != null && i > 0 && lines[i-1].trim().startsWith(lastPrefixLine)) &&
            // Don't add if it's just a number or date
            !RegExp(r'^\d+$').hasMatch(cleanLine) &&
            !RegExp(r'\d{1,2}[-\./]\d{1,2}[-\./]\d{4}').hasMatch(cleanLine)) {
          potentialNames.add(cleanLine.trim());
          print('Added potential name: ${cleanLine.trim()}');
        }

        // Collect all date candidates (DD-MM-YYYY, DD/MM/YYYY, DD.MM.YYYY)
        final dateMatches = RegExp(r'\b(\d{1,2}[-\./]\d{1,2}[-\./]\d{4})\b').allMatches(cleanLine);
        for (final m in dateMatches) {
          final ds = m.group(1);
          if (ds != null) {
            foundDates.add(ds);
          }
        }

        // Extract address
        if (info.address == null || info.address!.isEmpty) {
          if (upperLine.contains('ADRESSE') || upperLine.contains('ADDRESS')) {
            final addressMatch = RegExp(r'(?:ADRESSE|ADDRESS):\s*(.+)').firstMatch(upperLine);
            if (addressMatch != null) {
              info.address = addressMatch.group(1)?.trim();
            }
          }
        }

        // Extract license class (format: "AA B H")
        // License classes are typically short letter codes (1-2 letters each) separated by spaces
        // Examples: "AA B H", "A B", "B", "AA B"
        if (info.licenseClass == null || info.licenseClass!.isEmpty) {
          // Look for patterns like "AA B H" - short letter codes (1-2 letters each)
          // Must be on a line that's mostly just the class code (not mixed with other text)
          if (cleanLine.length <= 15 && 
              RegExp(r'^[A-Z]{1,2}(\s+[A-Z]{1,2})*\s*$').hasMatch(cleanLine) &&
              cleanLine.split(' ').where((s) => s.isNotEmpty).length <= 5) {
            info.licenseClass = cleanLine.trim();
            print('Found license class: ${info.licenseClass}');
          } else {
            // Try to find license class within a line (e.g., "Class: AA B H")
            final classMatch = RegExp(r'(?:CLASS|CATEGORY|CATÉGORIE)[:\s]+([A-Z]{1,2}(?:\s+[A-Z]{1,2})*)').firstMatch(upperLine);
            if (classMatch != null) {
              final candidate = classMatch.group(1)?.trim();
              if (candidate != null && candidate.split(' ').length <= 5 && candidate.length <= 15) {
                info.licenseClass = candidate;
                print('Found license class (with label): ${info.licenseClass}');
              }
            }
          }
        }

        // (Expiry handled later via heuristic ordering of foundDates)
      }

      // Process potential names after scanning all lines
      // Sort by length and content to identify lastName (shorter) and firstName (longer or contains common names)
      if (potentialNames.isNotEmpty && (info.firstName == null || info.lastName == null)) {
        print('Processing ${potentialNames.length} potential name lines: $potentialNames');
        
        // If we still don't have names, process all potential names
        // Sort names: shorter ones first (likely lastName), longer ones or with common first names last (likely firstName)
        potentialNames.sort((a, b) {
          final aIsCommonFirst = a.contains('MOHAMED') || a.contains('MALEK') || 
                                 a.contains('AHMED') || a.contains('ALI') ||
                                 a.contains('HASSAN') || a.contains('MUSTAPHA');
          final bIsCommonFirst = b.contains('MOHAMED') || b.contains('MALEK') || 
                                 b.contains('AHMED') || b.contains('ALI') ||
                                 b.contains('HASSAN') || b.contains('MUSTAPHA');
          
          // If one has common first name pattern, it should be last (firstName)
          if (aIsCommonFirst && !bIsCommonFirst) return 1;
          if (!aIsCommonFirst && bIsCommonFirst) return -1;
          
          // Otherwise sort by length (shorter = lastName)
          return a.length.compareTo(b.length);
        });
        
        // Assign: shortest/non-common-name = lastName, longest/common-name = firstName
        for (final name in potentialNames) {
          final isCommonFirst = name.contains('MOHAMED') || name.contains('MALEK') || 
                               name.contains('AHMED') || name.contains('ALI') ||
                               name.contains('HASSAN') || name.contains('MUSTAPHA');
          
          // Prioritize lastName if we don't have it
          if (info.lastName == null && 
              name.length >= 4 && 
              name.length <= 15 &&
              name.split(' ').length <= 2 &&
              !isCommonFirst) {
            info.lastName = name;
            print('Found last name (nom) from potential names: ${info.lastName}');
          } else if (info.firstName == null && 
                     (isCommonFirst || name.split(' ').length >= 2) &&
                     name.length > 5) {
            info.firstName = name;
            print('Found first name (prenom) from potential names: ${info.firstName}');
          }
        }
      }
      
      // Special case: If we found firstName but not lastName
      // Look for a name that appears BEFORE or AFTER the firstName in the text (likely lastName)
      if (info.lastName == null && info.firstName != null && firstNameIndex != null) {
        print('Looking for lastName near firstName position (index $firstNameIndex)...');
        
        // Look backwards from firstName position (up to 5 lines before)
        if (firstNameIndex > 0) {
          for (int j = firstNameIndex - 1; j >= 0 && j >= firstNameIndex - 5; j--) {
            final checkLine = lines[j].trim();
            if (checkLine.length >= 4 && 
                checkLine.length <= 15 &&
                RegExp(r'^[A-Z\s]+$').hasMatch(checkLine) &&
                !checkLine.contains('PERMIS') &&
                !checkLine.contains('REPUBLIQUE') &&
                !checkLine.contains('TUNIS') &&
                !checkLine.contains('CONDUIRE') &&
                !checkLine.contains('A.T.T.T') &&
                !RegExp(r'^[A-Z]{1,2}(\s+[A-Z]{1,2})*\s*$').hasMatch(checkLine) &&
                !checkLine.contains('MOHAMED') &&
                !checkLine.contains('MALEK') &&
                checkLine != info.firstName &&
                checkLine.split(' ').length <= 2) {
              // Found a potential lastName before firstName
              if (checkLine != '1.' && checkLine != '1,' && checkLine != '2.' && checkLine != '2,' &&
                  !checkLine.startsWith('1.') && !checkLine.startsWith('1,') &&
                  !checkLine.startsWith('2.') && !checkLine.startsWith('2,')) {
                info.lastName = checkLine;
                print('Found last name (nom) before firstName position: ${info.lastName}');
                break;
              }
            }
          }
        }
        
        // Also look forward from firstName position (up to 3 lines after)
        // Sometimes OCR reads in reverse order or the order is different
        if (info.lastName == null && firstNameIndex < lines.length - 1) {
          for (int j = firstNameIndex + 1; j < lines.length && j <= firstNameIndex + 3; j++) {
            final checkLine = lines[j].trim();
            if (checkLine.length >= 4 && 
                checkLine.length <= 15 &&
                RegExp(r'^[A-Z\s]+$').hasMatch(checkLine) &&
                !checkLine.contains('PERMIS') &&
                !checkLine.contains('REPUBLIQUE') &&
                !checkLine.contains('TUNIS') &&
                !checkLine.contains('CONDUIRE') &&
                !checkLine.contains('A.T.T.T') &&
                !RegExp(r'^[A-Z]{1,2}(\s+[A-Z]{1,2})*\s*$').hasMatch(checkLine) &&
                !checkLine.contains('MOHAMED') &&
                !checkLine.contains('MALEK') &&
                checkLine != info.firstName &&
                checkLine.split(' ').length <= 2) {
              // Found a potential lastName after firstName
              if (checkLine != '1.' && checkLine != '1,' && checkLine != '2.' && checkLine != '2,' &&
                  !checkLine.startsWith('1.') && !checkLine.startsWith('1,') &&
                  !checkLine.startsWith('2.') && !checkLine.startsWith('2,')) {
                info.lastName = checkLine;
                print('Found last name (nom) after firstName position: ${info.lastName}');
                break;
              }
            }
          }
        }
      }
      
      // Final check: if we still don't have lastName but have potential names, try to find a short one
      if (info.lastName == null && potentialNames.isNotEmpty) {
        print('Final check: Looking for lastName among ${potentialNames.length} potential names: $potentialNames');
        
        // Look for the shortest name that's not the firstName and doesn't contain common first names
        final candidateNames = potentialNames
            .where((n) => 
                n != info.firstName && 
                n.length >= 4 && 
                n.length <= 15 &&
                !n.contains('MOHAMED') &&
                !n.contains('MALEK') &&
                !n.contains('AHMED') &&
                !n.contains('ALI') &&
                !n.contains('HASSAN') &&
                !n.contains('MUSTAPHA'))
            .toList()
          ..sort((a, b) => a.length.compareTo(b.length));
        
        print('Candidate last names: $candidateNames');
        
        if (candidateNames.isNotEmpty) {
          info.lastName = candidateNames.first;
          print('Found last name (nom) as shortest potential name: ${info.lastName}');
        } else {
          // If no good candidate, just take the shortest one that's not firstName
          final fallbackNames = potentialNames
              .where((n) => n != info.firstName && n.length >= 4 && n.length <= 15)
              .toList()
            ..sort((a, b) => a.length.compareTo(b.length));
          
          if (fallbackNames.isNotEmpty) {
            info.lastName = fallbackNames.first;
            print('Found last name (nom) as fallback shortest name: ${info.lastName}');
          }
        }
      }

      // Infer DOB / Issue (delivery) / Expiry from collected dates
      if (foundDates.isNotEmpty) {
        DateTime? parseDate(String s) {
          final parts = s.replaceAll('.', '-').replaceAll('/', '-').split('-');
          if (parts.length != 3) return null;
          final d = int.tryParse(parts[0]);
          final m = int.tryParse(parts[1]);
          final y = int.tryParse(parts[2]);
          if (d == null || m == null || y == null) return null;
          try { return DateTime(y, m, d); } catch (_) { return null; }
        }

        final parsed = foundDates
            .map((s) => MapEntry(s, parseDate(s)))
            .where((e) => e.value != null)
            .toList()
          ..sort((a, b) => a.value!.compareTo(b.value!));

        if (parsed.isNotEmpty) {
          // Earliest -> DOB
          info.dateOfBirth ??= parsed.first.key;
          // Latest -> Expiry
          info.expiryDate ??= parsed.last.key;
          // Middle (if any) -> Delivery/Issue date
          if (parsed.length >= 3) {
            info.deliveryDate ??= parsed[1].key;
          } else if (parsed.length == 2) {
            // If only two dates, assume earlier is DOB, later is Expiry
          }
          print('Heuristic dates => DOB: ${info.dateOfBirth}, Delivery: ${info.deliveryDate}, Expiry: ${info.expiryDate}');
        }
      }

      // Try alternative patterns if no license number found
      if ((info.licenseNumber == null || info.licenseNumber!.isEmpty) && extractedText.isNotEmpty) {
        // Look for any 6-12 digit numbers in the entire text
        final allNumberMatches = RegExp(r'\b\d{6,12}\b').allMatches(extractedText);
        for (var match in allNumberMatches) {
          final num = match.group(0);
          if (num != null && num.length >= 6) {
            info.licenseNumber = num;
            print('Found alternative license number: ${info.licenseNumber}');
            break;
          }
        }
      }

      // Build fullName from firstName and lastName if we have them separately
      // Always prioritize separately extracted firstName and lastName
      if ((info.firstName != null && info.firstName!.isNotEmpty) || 
          (info.lastName != null && info.lastName!.isNotEmpty)) {
        final parts = <String>[];
        // In Tunisian format: LastName FirstName (Nom Prenom)
        if (info.lastName != null && info.lastName!.isNotEmpty) {
          parts.add(info.lastName!);
        }
        if (info.firstName != null && info.firstName!.isNotEmpty) {
          parts.add(info.firstName!);
        }
        if (parts.isNotEmpty) {
          info.fullName = parts.join(' ');
          print('Built full name from parts: ${info.fullName} (LastName: ${info.lastName}, FirstName: ${info.firstName})');
        }
      }
      
      // Extract name from "1." and "2." patterns if we still don't have names
      if ((info.fullName == null || info.fullName!.isEmpty) && extractedText.isNotEmpty) {
        final nameLines = RegExp(r'^[12][.,]\s*(.+)$', multiLine: true).allMatches(extractedText);
        if (nameLines.isNotEmpty) {
          final names = nameLines.map((m) => m.group(1)?.trim()).whereType<String>().toList();
          if (names.isNotEmpty) {
            info.fullName = names.join(' ');
            print('Found combined name: ${info.fullName}');
          }
        }
      }

      // If we found at least a license number or name, return the info
      if ((info.licenseNumber != null && info.licenseNumber!.isNotEmpty) ||
          (info.fullName != null && info.fullName!.isNotEmpty)) {
        print('License info extracted successfully: ${info.toString()}');
        return info;
      }

      print('No license information could be extracted from OCR text');
      return null;
    } catch (e) {
      throw Exception('Failed to parse license information: $e');
    }
  }

  /// Take a photo using camera
  Future<String?> takePhoto() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1080,
      );
      return image?.path;
    } catch (e) {
      throw Exception('Failed to take photo: $e');
    }
  }

  /// Pick image from gallery
  Future<String?> pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1080,
      );
      return image?.path;
    } catch (e) {
      throw Exception('Failed to pick image: $e');
    }
  }

  /// Process driver's license image and extract information
  Future<DriverLicenseInfo?> processDriverLicense() async {
    try {
      // Let user choose between camera and gallery
      final imagePath = await takePhoto();
      if (imagePath == null) return null;

      // Extract text from image
      final extractedText = await extractTextFromImage(imagePath);
      
      // Parse license information
      final licenseInfo = await parseLicenseInfo(extractedText);
      
      return licenseInfo;
    } catch (e) {
      throw Exception('Failed to process driver license: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    _textRecognizer.close();
  }
}

/// Data class for driver's license information
class DriverLicenseInfo {
  String? licenseNumber;
  String? fullName;
  String? firstName;  // prénom
  String? lastName;   // nom
  String? dateOfBirth;
  String? deliveryDate; // issue/delivery date
  String? address;
  String? licenseClass;
  String? expiryDate;
  String? imagePath;

  Map<String, dynamic> toJson() {
    return {
      'licenseNumber': licenseNumber,
      'fullName': fullName,
      'firstName': firstName,
      'lastName': lastName,
      'dateOfBirth': dateOfBirth,
      'address': address,
      'licenseClass': licenseClass,
      'expiryDate': expiryDate,
      'imagePath': imagePath,
    };
  }

  @override
  String toString() {
    return 'DriverLicenseInfo(licenseNumber: $licenseNumber, fullName: $fullName, firstName: $firstName, lastName: $lastName, dateOfBirth: $dateOfBirth, deliveryDate: $deliveryDate, address: $address, licenseClass: $licenseClass, expiryDate: $expiryDate)';
  }
}



