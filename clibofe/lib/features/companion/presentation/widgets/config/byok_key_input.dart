import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class ByokKeyInput extends StatefulWidget {
  final String label;
  final String hintText;
  final TextEditingController controller;
  final String? assetImage;
  final String? fallbackIcon;

  const ByokKeyInput({
    super.key,
    required this.label,
    required this.hintText,
    required this.controller,
    this.assetImage,
    this.fallbackIcon,
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
        Row(
          children: [
            if (widget.assetImage != null) ...[
              Image.asset(
                widget.assetImage!,
                width: 20,
                height: 20,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => widget.fallbackIcon != null
                    ? Text(widget.fallbackIcon!, style: const TextStyle(fontSize: 16))
                    : const SizedBox.shrink(),
              ),
              const SizedBox(width: 8),
            ] else if (widget.fallbackIcon != null) ...[
              Text(widget.fallbackIcon!, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                widget.label,
                style: theme.textTheme.p.copyWith(fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
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
