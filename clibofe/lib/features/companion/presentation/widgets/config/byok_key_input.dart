import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class ByokKeyInput extends StatefulWidget {
  final String label;
  final String hintText;
  final TextEditingController controller;

  const ByokKeyInput({
    super.key,
    required this.label,
    required this.hintText,
    required this.controller,
  });

  @override
  State<ByokKeyInput> createState() => _ByokKeyInputState();
}

class _ByokKeyInputState extends State<ByokKeyInput> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: theme.textTheme.p.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: widget.controller,
          obscureText: _obscureText,
          style: TextStyle(color: theme.colorScheme.foreground),
          decoration: InputDecoration(
            hintText: widget.hintText,
            filled: true,
            fillColor: theme.colorScheme.card,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureText ? Icons.visibility_off : Icons.visibility,
                color: theme.colorScheme.mutedForeground,
              ),
              onPressed: () {
                setState(() {
                  _obscureText = !_obscureText;
                });
              },
            ),
          ),
        ),
      ],
    );
  }
}
