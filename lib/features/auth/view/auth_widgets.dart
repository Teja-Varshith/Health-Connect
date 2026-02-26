import 'package:flutter/material.dart';

/// Shared form field for all auth screens.
Widget authField({
  required TextEditingController controller,
  required String label,
  required IconData icon,
  TextInputType keyboard = TextInputType.text,
  TextCapitalization capitalization = TextCapitalization.none,
  bool obscure = false,
  Widget? suffix,
  int? maxLength,
  TextAlign textAlign = TextAlign.start,
  String? Function(String?)? validator,
}) {
  return TextFormField(
    controller: controller,
    keyboardType: keyboard,
    textCapitalization: capitalization,
    obscureText: obscure,
    maxLength: maxLength,
    textAlign: textAlign,
    style: const TextStyle(fontSize: 15),
    decoration: InputDecoration(
      labelText: label,
      counterText: '',
      labelStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
      floatingLabelStyle: const TextStyle(color: Color(0xFF00897B)),
      prefixIcon: Icon(icon, color: Colors.grey.shade400, size: 20),
      suffixIcon: suffix,
      filled: true,
      fillColor: const Color(0xFFF7F8FA),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF00897B), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.red.shade300),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.red.shade400, width: 1.5),
      ),
    ),
    validator: validator,
  );
}

/// Shared primary button for all auth screens.
Widget authButton({
  required String label,
  required bool isLoading,
  required VoidCallback onPressed,
}) {
  return SizedBox(
    height: 54,
    child: ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF00897B),
        foregroundColor: Colors.white,
        disabledBackgroundColor: const Color(0xFF00897B).withOpacity(0.5),
        elevation: 2,
        shadowColor: const Color(0xFF00897B).withOpacity(0.3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: isLoading
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Colors.white,
              ),
            )
          : Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
    ),
  );
}
