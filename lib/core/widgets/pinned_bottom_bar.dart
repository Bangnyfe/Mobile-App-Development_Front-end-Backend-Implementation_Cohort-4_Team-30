import 'package:flutter/material.dart';

/// A screen's main action(s), pinned under its scrolling content and kept
/// clear of the system navigation area. Width-capped so buttons stay a
/// sensible size in landscape and on tablets.
class PinnedBottomBar extends StatelessWidget {
  const PinnedBottomBar({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Align(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ),
      ),
    );
  }
}
