import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../l10n.dart';
import 'home_section_header.dart';

/// A column of keyed [children] dragged by a [SectionDragStart] inside them.
/// While dragging, the item lifts ([homeSectionProxyDecorator]) and its drop
/// slot shows a dashed `primary` outline on `primaryContainer`, which
/// `ReorderableListView` can't draw. Keep it out of lazy lists: every item
/// must stay laid out while one is dragged.
class ReorderableSections extends StatefulWidget {
  const ReorderableSections({
    super.key,
    required this.children,
    required this.onReorder,
    this.spacing = 0,
  });

  final List<Widget> children;

  /// [to] is counted after removing the item at [from].
  final void Function(int from, int to) onReorder;
  final double spacing;

  @override
  State<ReorderableSections> createState() => _ReorderableSectionsState();
}

class _ReorderableSectionsState extends State<ReorderableSections> {
  final _keys = <Key, GlobalKey>{};
  int? _from;
  int? _to;
  var _size = Size.zero;
  var _anchor = Offset.zero;
  EdgeDraggingAutoScroller? _scroller;

  GlobalKey _keyOf(int index) =>
      _keys.putIfAbsent(widget.children[index].key!, GlobalKey.new);

  RenderBox _boxOf(int index) =>
      _keyOf(index).currentContext!.findRenderObject()! as RenderBox;

  /// Measures the item as the drag starts; the feedback keeps the grab point
  /// under the finger.
  Offset _grab(int index, Offset position) {
    final box = _boxOf(index);
    _size = box.size;
    return _anchor = box.globalToLocal(position);
  }

  void _start(int index) {
    final scrollable = Scrollable.maybeOf(context);
    _scroller = scrollable == null
        ? null
        : EdgeDraggingAutoScroller(scrollable, velocityScalar: 20);
    setState(() => _from = _to = index);
  }

  void _update(Offset position) {
    final from = _from;
    if (from == null) return;
    final top = position - _anchor;
    final center = top.dy + _size.height / 2;
    var to = 0;
    for (var i = 0; i < widget.children.length; i++) {
      if (i == from) continue;
      final box = _boxOf(i);
      if (box.localToGlobal(box.size.center(Offset.zero)).dy < center) to++;
    }
    if (to != _to) setState(() => _to = to);
    _scroller?.startAutoScrollIfNecessary(top & _size);
  }

  void _end() {
    _scroller?.stopAutoScroll();
    _scroller = null;
    final (from, to) = (_from, _to);
    setState(() => _from = _to = null);
    if (from != null && to != null && from != to) widget.onReorder(from, to);
  }

  Widget _feedback(int index) => InheritedTheme.captureAll(
    context,
    SizedBox.fromSize(
      size: _size,
      child: homeSectionProxyDecorator(
        widget.children[index],
        index,
        kAlwaysCompleteAnimation,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    Widget item(int i) =>
        KeyedSubtree(key: _keyOf(i), child: widget.children[i]);
    final from = _from;
    final children = <Widget>[];
    if (from == null) {
      for (var i = 0; i < widget.children.length; i++) {
        children.add(item(i));
      }
    } else {
      var shown = 0;
      for (var i = 0; i < widget.children.length; i++) {
        if (i == from) continue;
        if (shown++ == _to) children.add(_DropSlot(height: _size.height));
        children.add(item(i));
      }
      if (shown == _to) children.add(_DropSlot(height: _size.height));
      // Kept mounted, so its drag goes on.
      children.add(Offstage(child: item(from)));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: widget.spacing,
      children: children,
    );
  }
}

/// Starts dragging item [index] of the enclosing [ReorderableSections]: at
/// once (a drag handle) or after a long press ([delayed], a title). Outside
/// one, such as in the lifted copy, it is just [child].
class SectionDragStart extends StatelessWidget {
  const SectionDragStart({
    super.key,
    required this.index,
    required this.child,
    this.delayed = false,
  });

  final int index;
  final Widget child;
  final bool delayed;

  @override
  Widget build(BuildContext context) {
    final list = context.findAncestorStateOfType<_ReorderableSectionsState>();
    if (list == null) return child;
    final feedback = Builder(builder: (_) => list._feedback(index));
    Offset anchor(Draggable<Object> _, BuildContext _, Offset position) =>
        list._grab(index, position);
    void start() => list._start(index);
    void update(DragUpdateDetails d) => list._update(d.globalPosition);
    void end(DraggableDetails _) => list._end();
    if (delayed) {
      return LongPressDraggable<int>(
        data: index,
        axis: Axis.vertical,
        feedback: feedback,
        dragAnchorStrategy: anchor,
        onDragStarted: start,
        onDragUpdate: update,
        onDragEnd: end,
        child: child,
      );
    }
    return _HandleDraggable(
      data: index,
      axis: Axis.vertical,
      feedback: feedback,
      dragAnchorStrategy: anchor,
      onDragStarted: start,
      onDragUpdate: update,
      onDragEnd: end,
      child: child,
    );
  }
}

/// Starts on the first move, like `ReorderableDragStartListener`, while the
/// lifted item still only moves vertically.
class _HandleDraggable extends Draggable<int> {
  const _HandleDraggable({
    required super.child,
    required super.feedback,
    super.data,
    super.axis,
    super.dragAnchorStrategy,
    super.onDragStarted,
    super.onDragUpdate,
    super.onDragEnd,
  });

  @override
  MultiDragGestureRecognizer createRecognizer(
    GestureMultiDragStartCallback onStart,
  ) => ImmediateMultiDragGestureRecognizer(
    allowedButtonsFilter: allowedButtonsFilter,
  )..onStart = onStart;
}

class _DropSlot extends StatelessWidget {
  const _DropSlot({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return CustomPaint(
      painter: _DashedRect(scheme.primary),
      child: Container(
        height: height,
        color: scheme.primaryContainer,
        alignment: Alignment.center,
        child: Text(
          context.l10n.homeDropHere,
          style: Theme.of(context).textTheme.bodySmall!
              .copyWith(color: scheme.onPrimaryContainer),
        ),
      ),
    );
  }
}

class _DashedRect extends CustomPainter {
  _DashedRect(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final path = Path()..addRect((Offset.zero & size).deflate(0.75));
    for (final metric in path.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += 8) {
        canvas.drawPath(metric.extractPath(d, d + 4), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedRect old) => old.color != color;
}
