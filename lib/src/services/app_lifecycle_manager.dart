import 'package:flutter/material.dart';
import '../models/pet_state.dart';
import 'floating_window_manager.dart';

/// 应用生命周期和悬浮窗管理
class AppLifecycleManager extends WidgetsBindingObserver {
  final ValueChanged<PetSnapshot?> petStateListener;

  PetSnapshot? _currentPetState;

  AppLifecycleManager({required this.petStateListener}) {
    WidgetsBinding.instance.addObserver(this);
  }

  /// 更新当前宠物状态
  void updatePetState(PetSnapshot state) {
    _currentPetState = state;
  }

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        // 应用即将离开前台，显示悬浮窗  
        if (_currentPetState != null) {
          await FloatingWindowManager.showFloatingWindow(
            petName: _currentPetState!.speciesId,
            eventText: _currentPetState!.eventText,
          );
        }
        break;
      case AppLifecycleState.resumed:
        // 应用返回前台，隐藏悬浮窗
        await FloatingWindowManager.hideFloatingWindow();
        break;
      case AppLifecycleState.inactive:
        // 应用为非活跃状态，可选择隐藏
        break;
      case AppLifecycleState.hidden:
        // 应用被隐藏，显示悬浮窗
        if (_currentPetState != null) {
          await FloatingWindowManager.showFloatingWindow(
            petName: _currentPetState!.speciesId,
            eventText: _currentPetState!.eventText,
          );
        }
        break;
    }
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
  }
}
