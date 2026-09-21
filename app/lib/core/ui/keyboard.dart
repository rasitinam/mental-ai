import 'package:flutter/material.dart';

/// Hides the on-screen keyboard (drops the focus of whichever field has it).
void dismissKeyboard() => FocusManager.instance.primaryFocus?.unfocus();

/// Wraps the whole app so a tap on anything that is not a field or a button
/// hides the keyboard.
///
/// Flutter does this on desktop and the web but not on phones. Android has a
/// back gesture that closes the keyboard, so it never showed; an iPhone has
/// none, and its multi-line keyboards (journal, story, chat) have only a
/// "return" key and the number pad (birth year, verification code) has no key
/// at all, so once opened the keyboard stayed up until the page changed.
///
/// A field or button under the finger still wins the tap, so this only fires
/// on empty space, text and the like, and never steals a scroll or a drag.
class DismissKeyboardOnTap extends StatelessWidget {
  final Widget child;
  const DismissKeyboardOnTap({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      // A root-wide tap handler must not show up to VoiceOver/TalkBack as an
      // actionable element covering the whole screen.
      excludeFromSemantics: true,
      onTap: dismissKeyboard,
      child: child,
    );
  }
}
