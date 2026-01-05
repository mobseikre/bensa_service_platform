import 'package:flutter/material.dart';

/// Description textarea with character counter
class DescriptionInput extends StatefulWidget {
  final TextEditingController controller;
  final int maxLength;

  const DescriptionInput({
    super.key,
    required this.controller,
    this.maxLength = 500,
  });

  @override
  State<DescriptionInput> createState() => _DescriptionInputState();
}

class _DescriptionInputState extends State<DescriptionInput> {
  int _currentLength = 0;

  @override
  void initState() {
    super.initState();
    _currentLength = widget.controller.text.length;
    widget.controller.addListener(_updateLength);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_updateLength);
    super.dispose();
  }

  void _updateLength() {
    setState(() {
      _currentLength = widget.controller.text.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: widget.controller,
          maxLength: widget.maxLength,
          maxLines: 5,
          keyboardType: TextInputType.multiline,
          textDirection: TextDirection.rtl,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface,
          ),
          decoration: InputDecoration(
            hintText: 'اشرح المشكلة بالتفصيل...',
            hintStyle: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
            ),
            filled: true,
            fillColor: theme.colorScheme.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: theme.colorScheme.outline,
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: theme.colorScheme.outline,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: theme.colorScheme.primary,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: theme.colorScheme.error,
                width: 1,
              ),
            ),
            contentPadding: const EdgeInsets.all(16),
            counterText: '',
          ),
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            '$_currentLength / ${widget.maxLength}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: _currentLength > widget.maxLength
                  ? theme.colorScheme.error
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}
