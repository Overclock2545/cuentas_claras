import 'package:flutter/material.dart';

class DividerWithText extends StatelessWidget {
  final String text;

  const DividerWithText({
    super.key,
    this.text = 'o',
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }
}