import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

/// A tap anywhere but the text field being edited (an empty area, a button,
/// a row) closes the keyboard. Scrolling keeps it, and so do taps on the
/// field's own toolbar and handles.
class KeyboardHider extends HookWidget {
  const KeyboardHider({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final down = useRef(Offset.zero);
    return Listener(
      onPointerDown: (event) => down.value = event.position,
      child: Actions(
        actions: {
          // Flutter sends it for every pointer up outside a focused field,
          // the end of a scroll included.
          EditableTextTapUpOutsideIntent:
              CallbackAction<EditableTextTapUpOutsideIntent>(
                onInvoke: (intent) {
                  final up = intent.pointerUpEvent.position;
                  if ((up - down.value).distance < kTouchSlop) {
                    intent.focusNode.unfocus();
                  }
                  return null;
                },
              ),
        },
        child: child,
      ),
    );
  }
}
