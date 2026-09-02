class AgentAction {
  final String action;
  final Map<String, dynamic> params;
  final String response;

  AgentAction({
    required this.action,
    required this.params,
    required this.response,
  });

  factory AgentAction.fromJson(Map<String, dynamic> json) {
    return AgentAction(
      action: json['action'] as String? ?? 'general_query',
      params: json['params'] as Map<String, dynamic>? ?? {},
      response: json['response'] as String? ?? '',
    );
  }

  static const List<String> availableActions = [
    'open_app',
    'make_call',
    'send_sms',
    'search_contact',
    'set_alarm',
    'set_timer',
    'set_volume',
    'set_brightness',
    'toggle_flash',
    'set_screen_timeout',
    'youtube_search',
    'take_screenshot',
    'share_image',
    'open_whatsapp',
    'read_screen',
    'run_adb_command',
    'execute_task',
    'general_query',
  ];
}
