import 'package:flutter/material.dart';

/// The rectangle an iPad anchors its share popover to. `share_plus` refuses
/// to open the sheet on an iPad without one (it throws), which made "share"
/// fail there; iPhones and Android ignore it.
Rect? shareOrigin(BuildContext context) {
  final box = context.findRenderObject();
  if (box is! RenderBox || !box.hasSize || box.size.isEmpty) return null;
  return box.localToGlobal(Offset.zero) & box.size;
}
