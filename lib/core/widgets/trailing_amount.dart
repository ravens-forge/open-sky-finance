import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'large_text.dart';

/// [text] with [amount] at its end. With large text, or an amount wider than
/// half the row next to a text that no longer fits on one line, the amount
/// drops below, end-aligned, so neither is squeezed into broken words.
class TrailingAmount extends StatelessWidget {
  const TrailingAmount({
    super.key,
    required this.text,
    required this.amount,
    this.gap = 12,
  });

  final Widget text;
  final Widget amount;
  final double gap;

  @override
  Widget build(BuildContext context) => isLargeText(context)
      ? Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            text,
            Align(alignment: AlignmentDirectional.centerEnd, child: amount),
          ],
        )
      : _TrailingLayout(gap: gap, children: [text, amount]);
}

class _TrailingLayout extends MultiChildRenderObjectWidget {
  const _TrailingLayout({required this.gap, required super.children});

  final double gap;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderTrailing(gap, Directionality.of(context));

  @override
  void updateRenderObject(BuildContext context, _RenderTrailing renderObject) =>
      renderObject
        ..gap = gap
        ..textDirection = Directionality.of(context);
}

class _TrailingParentData extends ContainerBoxParentData<RenderBox> {}

/// Text and amount side by side, centred, like a row; the amount below when
/// it takes over half the width and the text would wrap beside it.
class _RenderTrailing extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _TrailingParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _TrailingParentData> {
  _RenderTrailing(this._gap, this._textDirection);

  double _gap;
  set gap(double value) {
    if (value == _gap) return;
    _gap = value;
    markNeedsLayout();
  }

  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    if (value == _textDirection) return;
    _textDirection = value;
    markNeedsLayout();
  }

  RenderBox get _text => firstChild!;
  RenderBox get _amount => lastChild!;

  bool _below(double width, double amountWidth) =>
      amountWidth > (width - _gap) / 2 &&
      _text.getMaxIntrinsicWidth(double.infinity) > width - amountWidth - _gap;

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _TrailingParentData) {
      child.parentData = _TrailingParentData();
    }
  }

  Size _layout(BoxConstraints constraints, ChildLayouter layoutChild) {
    final width = constraints.maxWidth;
    final amount = layoutChild(_amount, BoxConstraints(maxWidth: width));
    final below = _below(width, amount.width);
    final textWidth = below ? width : width - amount.width - _gap;
    final text = layoutChild(_text, BoxConstraints.tightFor(width: textWidth));
    final size = constraints.constrain(
      Size(
        width,
        below
            ? text.height + amount.height
            : math.max(text.height, amount.height),
      ),
    );
    if (layoutChild == ChildLayoutHelper.layoutChild) {
      final ltr = _textDirection == TextDirection.ltr;
      // Centred in the height given, like a row's children.
      final top = below ? (size.height - text.height - amount.height) / 2 : 0.0;
      (_text.parentData! as _TrailingParentData).offset = Offset(
        ltr ? 0 : width - textWidth,
        below ? top : (size.height - text.height) / 2,
      );
      (_amount.parentData! as _TrailingParentData).offset = Offset(
        ltr ? width - amount.width : 0,
        below ? top + text.height : (size.height - amount.height) / 2,
      );
    }
    return size;
  }

  @override
  void performLayout() {
    assert(constraints.hasBoundedWidth);
    size = _layout(constraints, ChildLayoutHelper.layoutChild);
  }

  @override
  Size computeDryLayout(covariant BoxConstraints constraints) =>
      _layout(constraints, ChildLayoutHelper.dryLayoutChild);

  @override
  double computeMinIntrinsicWidth(double height) => math.max(
    _text.getMinIntrinsicWidth(height),
    _amount.getMinIntrinsicWidth(height),
  );

  @override
  double computeMaxIntrinsicWidth(double height) =>
      _text.getMaxIntrinsicWidth(height) +
      _gap +
      _amount.getMaxIntrinsicWidth(height);

  double _height(double width, double Function(RenderBox, double) of) {
    final amount = _amount.getMaxIntrinsicWidth(double.infinity);
    return _below(width, amount)
        ? of(_text, width) + of(_amount, width)
        : math.max(of(_text, width - amount - _gap), of(_amount, amount));
  }

  @override
  double computeMinIntrinsicHeight(double width) =>
      _height(width, (child, w) => child.getMinIntrinsicHeight(w));

  @override
  double computeMaxIntrinsicHeight(double width) =>
      _height(width, (child, w) => child.getMaxIntrinsicHeight(w));

  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) =>
      defaultComputeDistanceToFirstActualBaseline(baseline);

  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);
}
