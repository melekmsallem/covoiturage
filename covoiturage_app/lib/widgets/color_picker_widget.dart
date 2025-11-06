import 'package:flutter/material.dart';

class ColorPickerWidget extends StatelessWidget {
  final String colorName;
  final String hexColor;
  final VoidCallback onTap;

  const ColorPickerWidget({
    Key? key,
    required this.colorName,
    required this.hexColor,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Color indicator
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: _parseColor(hexColor),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.grey.shade300,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Color name
            Expanded(
              child: Text(
                colorName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _parseColor(String hexColor) {
    try {
      // Remove # if present
      String hex = hexColor.replaceAll('#', '');
      
      // Handle 3-character hex codes
      if (hex.length == 3) {
        hex = hex.split('').map((char) => char + char).join();
      }
      
      // Ensure we have 6 characters
      if (hex.length == 6) {
        return Color(int.parse('FF$hex', radix: 16));
      }
      
      // Fallback to black if parsing fails
      return Colors.black;
    } catch (e) {
      return Colors.black;
    }
  }
}
