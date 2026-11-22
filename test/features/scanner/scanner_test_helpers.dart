import 'package:flutter/material.dart';

/// Stands in for the camera: tests call [see] to "show" it a barcode.
///
/// Pass [build] to a `ScannerCameraScope` above the app under test.
class FakeCamera {
  ValueChanged<String>? _onCode;
  int builds = 0;

  Widget build(BuildContext context, ValueChanged<String> onCode) {
    _onCode = onCode;
    builds++;
    return const ColoredBox(color: Colors.black26);
  }

  void see(String raw) => _onCode!(raw);
}
