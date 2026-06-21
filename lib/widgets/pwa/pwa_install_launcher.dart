import 'package:flutter/material.dart';
import '../../utils/pwa_utils.dart';
import 'ios_install_instructions_sheet.dart';
import 'native_install_sheet.dart';

/// Opens the right install drawer for the current platform: iOS gets the manual
/// "Add to Home Screen" steps; everything else (Android / desktop Chromium) gets
/// the native-install drawer, which itself adapts to whether a `beforeinstallprompt`
/// was actually captured.
Future<void> showPwaInstallSheet(BuildContext context) {
  if (PwaUtils.isIOS) {
    return IosInstallInstructionsSheet.show(context);
  }
  return NativeInstallSheet.show(context);
}
