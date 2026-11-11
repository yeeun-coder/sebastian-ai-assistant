import 'package:flutter/material.dart';

enum TextFieldType {
  underline,
  box,
}

class CustomTextField extends StatefulWidget {
  const CustomTextField({
    super.key,
    required this.controller,
    this.hintText,
    this.isPassword = false,
    this.keyboardType,
    this.autocorrect = true,
    this.type = TextFieldType.underline,
    this.maxLines = 1,
    this.minLines,
  });

  final TextEditingController controller;
  final String? hintText;
  final bool isPassword;
  final TextInputType? keyboardType;
  final bool autocorrect;
  final TextFieldType type;
  final int maxLines;
  final int? minLines;

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    final isMultiline = widget.maxLines != 1;

    return _buildTextField(isMultiline);
  }

  Widget _buildTextField(bool isMultiline) {
    final textField = Theme(
      data: Theme.of(context).copyWith(
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: Colors.black,
          selectionColor: Color(0xFFE0E0E0),
          selectionHandleColor: Colors.black,
        ),
      ),
      child: TextField(
        controller: widget.controller,
        obscureText: widget.isPassword ? _obscure : false,
        keyboardType: isMultiline ? TextInputType.multiline : widget.keyboardType,
        autocorrect: widget.autocorrect,
        maxLines: widget.maxLines,
        minLines: widget.minLines,
        textAlignVertical: TextAlignVertical.center,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: widget.type == TextFieldType.box
            ? const EdgeInsets.symmetric(vertical: 16, horizontal: 14)
            : const EdgeInsets.symmetric(vertical: 4),

          border: widget.type == TextFieldType.box
              ? OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFD9D9D9)),
                )
              : const UnderlineInputBorder(),

          enabledBorder: widget.type == TextFieldType.box
              ? OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFD9D9D9)),
                )
              : const UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFE1E1E1)),
                ),

          focusedBorder: widget.type == TextFieldType.box
              ? OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.black, width: 1.5),
                )
              : const UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.black, width: 1.5),
                ),

          hintText: widget.hintText,
          hintStyle: const TextStyle(
            color: Color(0xFFD9D9D9),
            fontSize: 14,
          ),

          suffixIconConstraints: const BoxConstraints(
            minWidth: 24,
            minHeight: 24,
          ),

          suffixIcon: widget.isPassword
              ? IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: Icon(
                    _obscure ? Icons.visibility_off : Icons.visibility,
                    size: 18,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscure = !_obscure;
                    });
                  },
                )
              : null,
        ),
      ),
    );

    if (widget.type == TextFieldType.underline) {
      return SizedBox(
        height: 32,
        child: textField,
      );
    }

    return textField;
  }
}