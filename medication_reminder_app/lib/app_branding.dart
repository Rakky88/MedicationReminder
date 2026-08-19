import 'package:flutter/material.dart';

const String appLogoMarkAsset = 'assets/branding/app_logo_mark.png';

class AppLogoMark extends StatelessWidget {
  const AppLogoMark({
    super.key,
    required this.size,
    this.imageKey,
    this.semanticLabel,
  });

  final double size;
  final Key? imageKey;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      appLogoMarkAsset,
      key: imageKey,
      width: size,
      height: size,
      fit: BoxFit.contain,
      semanticLabel: semanticLabel,
    );
  }
}

class AppWordmark extends StatelessWidget {
  const AppWordmark({
    super.key,
    required this.title,
    this.textKey,
    this.style,
    this.textAlign = TextAlign.start,
    this.maxLines = 1,
  });

  final String title;
  final Key? textKey;
  final TextStyle? style;
  final TextAlign textAlign;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final titleBreak = title.lastIndexOf(' ');
    final titleLead = titleBreak < 0
        ? title
        : title.substring(0, titleBreak + 1);
    final titleAccent = titleBreak < 0 ? '' : title.substring(titleBreak + 1);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Text.rich(
      TextSpan(
        children: <InlineSpan>[
          TextSpan(
            text: titleLead,
            style: TextStyle(
              color: isDark ? const Color(0xFF80CBC4) : const Color(0xFF00695C),
            ),
          ),
          TextSpan(
            text: titleAccent,
            style: TextStyle(
              color: isDark ? const Color(0xFF90CAF9) : const Color(0xFF1565C0),
            ),
          ),
        ],
      ),
      key: textKey,
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      textAlign: textAlign,
      style: style,
    );
  }
}
