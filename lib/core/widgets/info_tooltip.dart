import 'package:flutter/material.dart';

import '../finance_colors.dart';

class InfoTooltip extends StatefulWidget {
  const InfoTooltip({
    super.key,
    required this.label,
    required this.text,
    this.eyebrow,
  });

  final String label;
  final String text;
  final String? eyebrow;

  @override
  State<InfoTooltip> createState() => _InfoTooltipState();
}

class _InfoTooltipState extends State<InfoTooltip> {
  static _InfoTooltipState? _open;

  final _controller = OverlayPortalController();
  final _iconKey = GlobalKey();

  void _show() {
    _open?._hide();
    _open = this;
    setState(_controller.show);
  }

  void _hide() {
    if (_open == this) _open = null;
    if (mounted && _controller.isShowing) setState(_controller.hide);
  }

  @override
  void dispose() {
    if (_open == this) _open = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final open = _controller.isShowing;
    return PopScope(
      canPop: !open,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _hide();
      },
      child: TapRegion(
        onTapOutside: (_) => _hide(),
        child: OverlayPortal(
          controller: _controller,
          overlayChildBuilder: _popover,
          child: Semantics(
            label: widget.label,
            expanded: open,
            child: IconButton(
              key: _iconKey,
              onPressed: open ? _hide : _show,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 44, height: 44),
              icon: Icon(
                Icons.info_outline,
                size: 17,
                color: FinanceColors.of(context).muted,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _popover(BuildContext context) {
    final theme = Theme.of(context);
    final overlay =
        Overlay.of(context).context.findRenderObject()! as RenderBox;
    final icon = _iconKey.currentContext!.findRenderObject()! as RenderBox;
    final anchor =
        icon.localToGlobal(Offset.zero, ancestor: overlay) & icon.size;
    final height = overlay.size.height;

    final above = anchor.center.dy > height * 0.6;
    const side = 20.0;

    return Positioned(
      left: side,
      right: side,
      top: above ? null : anchor.bottom + 2,
      bottom: above ? height - anchor.top + 2 : null,
      child: Semantics(
        liveRegion: true,
        container: true,
        child: CustomPaint(
          painter: _PopoverPainter(
            caretX: anchor.center.dx - side,
            above: above,
            fill: theme.colorScheme.surfaceContainer,
            border: theme.colorScheme.outline,
            shadow: theme.colorScheme.shadow,
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              14,
              12 + (above ? 0 : _caret),
              14,
              12 + (above ? _caret : 0),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.eyebrow != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      widget.eyebrow!,
                      style: theme.textTheme.labelSmall,
                    ),
                  ),
                Text(
                  widget.text,
                  style: theme.textTheme.bodySmall!.copyWith(
                    fontSize: 13,
                    height: 1.5,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Height of the caret pointing at the icon.
const _caret = 6.0;

class _PopoverPainter extends CustomPainter {
  _PopoverPainter({
    required this.caretX,
    required this.above,
    required this.fill,
    required this.border,
    required this.shadow,
  });

  final double caretX;
  final bool above;
  final Color fill;
  final Color border;
  final Color shadow;

  @override
  void paint(Canvas canvas, Size size) {
    final box = above
        ? Rect.fromLTRB(0, 0, size.width, size.height - _caret)
        : Rect.fromLTRB(0, _caret, size.width, size.height);
    final x = caretX.clamp(12.0, size.width - 12);
    final tipY = above ? size.height : 0.0;
    final baseY = above ? box.bottom : box.top;
    final path = Path.combine(
      PathOperation.union,
      Path()..addRect(box),
      Path()
        ..moveTo(x - 7, baseY)
        ..lineTo(x, tipY)
        ..lineTo(x + 7, baseY)
        ..close(),
    );
    canvas
      ..drawShadow(path, shadow.withValues(alpha: 0.5), 6, false)
      ..drawPath(path, Paint()..color = fill)
      ..drawPath(
        path,
        Paint()
          ..color = border
          ..style = PaintingStyle.stroke,
      );
  }

  @override
  bool shouldRepaint(_PopoverPainter old) =>
      old.caretX != caretX ||
      old.above != above ||
      old.fill != fill ||
      old.border != border ||
      old.shadow != shadow;
}
