import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// "Label value" line under the payment badge ("Processed on 5.3.2026",
/// "Payment cycle November 2026"). Separate runs — a mixed-direction label +
/// value scrambles under RTL bidi if concatenated.
class PaymentStripDetailRow extends StatelessWidget {
  const PaymentStripDetailRow({
    super.key,
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  static const _style = TextStyle(fontSize: 12, color: AppTheme.mutedForeground);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Text(label, style: _style),
          const SizedBox(width: 4),
          Flexible(child: Text(value, style: _style)),
        ],
      ),
    );
  }
}
