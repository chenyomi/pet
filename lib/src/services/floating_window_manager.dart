import 'dart:io' show Platform;
import 'package:flutter/services.dart';

/// 管理后台悬浮窗的显示/隐藏
class FloatingWindowManager {
  static const platform = MethodChannel('com.digipet/floating_window');

  /// 显示后台悬浮窗（仅在 macOS 上有效）
  static Future<bool> showFloatingWindow({
    required String petName,
    required String eventText,
  }) async {
    if (!Platform.isMacOS) return false;

    try {
      final result = await platform.invokeMethod<bool>(
        'showFloatingWindow',
        {
          'petName': petName,
          'eventText': eventText,
        },
      );
      return result ?? false;
    } catch (e) {
      print('FloatingWindowManager error: $e');
      return false;
    }
  }

  /// 隐藏后台悬浮窗
  static Future<bool> hideFloatingWindow() async {
    if (!Platform.isMacOS) return false;

    try {
      final result = await platform.invokeMethod<bool>('hideFloatingWindow');
      return result ?? false;
    } catch (e) {
      print('FloatingWindowManager error: $e');
      return false;
    }
  }

  /// 更新悬浮窗信息
  static Future<bool> updateFloatingWindow({
    required String petName,
    required String eventText,
  }) async {
    if (!Platform.isMacOS) return false;

    try {
      final result = await platform.invokeMethod<bool>(
        'updateFloatingWindow',
        {
          'petName': petName,
          'eventText': eventText,
        },
      );
      return result ?? false;
    } catch (e) {
      print('FloatingWindowManager error: $e');
      return false;
    }
  }
}
