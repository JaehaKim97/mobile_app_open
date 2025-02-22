import 'dart:io' show Platform;

import 'package:mlperfbench/backend/bridge/ffi_match.dart';
import 'package:mlperfbench/protos/backend_setting.pb.dart' as pb;

part 'list.gen.dart';

class BackendInfo {
  final pb.BackendSetting settings;
  final String libPath;

  BackendInfo._(this.settings, this.libPath);

  static BackendInfo findMatching() {
    for (var path in _getBackendsList()) {
      if (path == '') {
        continue;
      }
      if (Platform.isWindows) {
        path = '$path.dll';
      } else if (Platform.isAndroid) {
        path = '$path.so';
      }
      final backendSettings = backendMatch(path);
      if (backendSettings != null) {
        return BackendInfo._(backendSettings, path);
      }
    }
    // try built-in backend
    final backendSetting = backendMatch('');
    if (backendSetting != null) {
      return BackendInfo._(backendSetting, '');
    }
    throw 'no matching backend found';
  }

  static List<String> _getBackendsList() {
    if (Platform.isIOS) {
      // on iOS backend is statically linked
      return [];
    } else if (Platform.isWindows || Platform.isAndroid) {
      return _backendsList;
    } else {
      throw 'current platform is unsupported';
    }
  }

  static List<String> getExportBackendsList() {
    if (Platform.isIOS) {
      // on iOS backend is statically linked
      return ['built-in tflite'];
    } else if (Platform.isWindows || Platform.isAndroid) {
      final result = List<String>.from(_backendsList);
      result.removeWhere((element) => element == '');
      return result;
    } else {
      throw 'current platform is unsupported';
    }
  }
}
