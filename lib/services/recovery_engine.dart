class RecoveryAction {
  final String action;
  final Map<String, dynamic> params;
  final String description;
  RecoveryAction({required this.action, required this.params, required this.description});
}

class RecoveryEngine {
  Future<RecoveryAction> diagnose(String lastFailedAction, String screenContent) async {
    final lowerScreen = screenContent.toLowerCase();
    if (lowerScreen.contains('loading') || lowerScreen.contains('progress') || lowerScreen.contains('spinner') || lowerScreen.contains('wait')) {
      return RecoveryAction(action: 'wait', params: {}, description: 'App seems to be loading, waiting...');
    }
    if (lowerScreen.contains('gboard') || lowerScreen.contains('keyboard')) {
      return RecoveryAction(action: 'press_back', params: {}, description: 'Keyboard might be blocking the screen, dismissing it.');
    }
    if (lastFailedAction == 'click_text' || lastFailedAction == 'click_at') {
      if (lowerScreen.contains('scrollable')) {
        return RecoveryAction(action: 'scroll', params: {'direction': 'down'}, description: 'Click failed, trying to scroll down.');
      } else {
        return RecoveryAction(action: 'press_back', params: {}, description: 'Click failed, pressing back.');
      }
    }
    if (lastFailedAction == 'open_app') {
      return RecoveryAction(action: 'press_home', params: {}, description: 'Failed to open app, going home.');
    }
    return RecoveryAction(action: 'press_back', params: {}, description: 'Unknown failure, pressing back.');
  }
}
