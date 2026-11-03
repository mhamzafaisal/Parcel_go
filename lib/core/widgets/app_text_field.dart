import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../app/theme.dart';

class AppTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final IconData? icon;
  final TextEditingController? controller;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final int maxLines;
  final int? maxLength;
  final String? suffixText;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;

  const AppTextField({
    super.key,
    required this.label,
    this.hint,
    this.icon,
    this.controller,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.maxLines = 1,
    this.maxLength,
    this.suffixText,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          validator: validator,
          maxLines: maxLines,
          maxLength: maxLength,
          inputFormatters: inputFormatters,
          textCapitalization: textCapitalization,
          decoration: InputDecoration(
            hintText: hint,
            suffixText: suffixText,
            prefixIcon: icon == null
                ? null
                : Icon(icon, color: AppColors.textMuted),
          ),
        ),
      ],
    );
  }
}