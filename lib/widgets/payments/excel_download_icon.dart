import 'package:flutter/material.dart';

/// "Download as Excel" glyph: a green spreadsheet tile with an X and a small
/// down-arrow badge, drawn (no asset) so it stays crisp. Used where a bare
/// download arrow would not say what the file is (the Payments bulk bar).
class ExcelDownloadIcon extends StatelessWidget {
  const ExcelDownloadIcon({super.key, this.size = 20});

  final double size;

  static const Color _green = Color(0xFF1D6F42);

  @override
  Widget build(BuildContext context) {
    final badge = size * 0.55;
    // The glyph is a picture, not text: same in LTR and RTL.
    return Directionality(
      textDirection: TextDirection.ltr,
      child: SizedBox(
        width: size + badge * 0.35,
        height: size + badge * 0.35,
        child: Stack(
          children: [
            Container(
              width: size,
              height: size,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _green,
                borderRadius: BorderRadius.circular(size * 0.18),
              ),
              child: Text(
                'X',
                style: TextStyle(
                  fontSize: size * 0.62,
                  height: 1,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: badge,
                height: badge,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: _green, width: 1.2),
                ),
                child: Icon(Icons.arrow_downward,
                    size: badge * 0.75, color: _green),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
