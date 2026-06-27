import 'package:flutter/material.dart';

class CustomTextField extends StatefulWidget {
  final String label;
  final String? hint;
  final IconData? prefixIcon;
  final bool isPassword;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;

  const CustomTextField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.prefixIcon,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
    this.validator,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      keyboardType: widget.keyboardType,
      validator: widget.validator,
      obscureText: widget.isPassword ? _obscureText : false,

      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,

        prefixIcon: widget.prefixIcon != null
            ? Icon(widget.prefixIcon)
            : null,

        suffixIcon: widget.isPassword
            ? IconButton(
                icon: Icon(
                  _obscureText
                      ? Icons.visibility_off
                      : Icons.visibility,
                ),
                onPressed: () {
                  setState(() {
                    _obscureText = !_obscureText;
                  });
                },
              )
            : null,

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }
}