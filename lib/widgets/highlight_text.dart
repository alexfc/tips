import 'package:flutter/material.dart';

class HighlightText extends StatelessWidget {
  const HighlightText(
    this.text, {
    super.key,
    required this.words,
    this.style,
    this.maxLines,
  });

  final String text;
  final List<String> words;
  final TextStyle? style;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    final base = style ?? DefaultTextStyle.of(context).style;
    if (words.isEmpty) {
      return Text(text, style: base, maxLines: maxLines, overflow: TextOverflow.ellipsis);
    }
    final scheme = Theme.of(context).colorScheme;
    final highlight = base.copyWith(
      backgroundColor: scheme.tertiaryContainer,
      color: scheme.onTertiaryContainer,
      fontWeight: FontWeight.w600,
    );
    final lower = text.toLowerCase();
    final spans = <TextSpan>[];
    var i = 0;
    while (i < text.length) {
      var matchEnd = -1;
      for (final w in words) {
        if (lower.startsWith(w, i) && i + w.length > matchEnd) {
          matchEnd = i + w.length;
        }
      }
      if (matchEnd > 0) {
        spans.add(TextSpan(text: text.substring(i, matchEnd), style: highlight));
        i = matchEnd;
      } else {
        final start = i;
        while (i < text.length && !words.any((w) => lower.startsWith(w, i))) {
          i++;
        }
        spans.add(TextSpan(text: text.substring(start, i)));
      }
    }
    return Text.rich(
      TextSpan(style: base, children: spans),
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
    );
  }
}
