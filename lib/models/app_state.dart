import 'package:flutter/foundation.dart';

class AppState {
  static final AppState _instance = AppState._internal();
  factory AppState() => _instance;
  AppState._internal();

  final ValueNotifier<String> activeProjectId = ValueNotifier<String>('default');
  final ValueNotifier<int> currentTab = ValueNotifier<int>(0);
  final ValueNotifier<String> currentTheme = ValueNotifier<String>('Dark');
  final ValueNotifier<int> projectsVersion = ValueNotifier<int>(0);

  void refreshProjects() {
    projectsVersion.value++;
  }
  
  void setActiveProject(String id) {
    if (activeProjectId.value != id) {
      activeProjectId.value = id;
    }
  }
}

