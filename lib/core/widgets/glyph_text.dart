import 'package:flutter/material.dart';

/// Arrows the bundled fonts lack, drawn with their Material icon instead.
const _glyphs = {'⇄': Icons.sync_alt, '→': Icons.arrow_forward};

final _pattern = RegExp('[${_glyphs.keys.join()}]');

/// [Text] that draws `⇄` and `→` as icons in the text's size and colour, so
/// they look the same on every device instead of depending on a system
/// fallback font. Screen readers still read [semanticsLabel] or [text].
class GlyphText extends StatelessWidget {
  const GlyphText(
    this.text, {
    super.key,
    this.style,
    this.semanticsLabel,
    this.maxLines,
  });

  final String text;
  final TextStyle? style;
  final String? semanticsLabel;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    if (!_pattern.hasMatch(text)) {
      return Text(
        text,
        style: style,
        semanticsLabel: semanticsLabel,
        maxLines: maxLines,
      );
    }
    final resolved = DefaultTextStyle.of(context).style.merge(style);
    final spans = <InlineSpan>[];
    text.splitMapJoin(
      _pattern,
      onMatch: (m) {
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Icon(
              _glyphs[m[0]],
              size: resolved.fontSize,
              color: resolved.color,
            ),
          ),
        );
        return '';
      },
      onNonMatch: (s) {
        if (s.isNotEmpty) spans.add(TextSpan(text: s));
        return '';
      },
    );
    return Text.rich(
      TextSpan(children: spans),
      style: style,
      semanticsLabel: semanticsLabel ?? text,
      maxLines: maxLines,
    );
  }
}
