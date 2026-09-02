import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'action_handler.dart';
import 'ai_service.dart';

class TelegramService {
  final ActionHandler _actionHandler;
  final AiService _aiService;
  String _botToken = '';
  bool _isEnabled = false;
  int _lastUpdateId = 0;
  bool _isPolling = false;
  Timer? _pollingTimer;

  TelegramService(this._actionHandler, this._aiService);
  String get botToken => _botToken;
  bool get isEnabled => _isEnabled;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _botToken = prefs.getString('telegram_bot_token') ?? '';
    _isEnabled = prefs.getBool('telegram_enabled') ?? false;
    if (_isEnabled && _botToken.isNotEmpty) startPolling();
  }

  Future<void> saveSettings({required String botToken, required bool isEnabled}) async {
    _botToken = botToken; _isEnabled = isEnabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('telegram_bot_token', _botToken);
    await prefs.setBool('telegram_enabled', _isEnabled);
    if (_isEnabled && _botToken.isNotEmpty) startPolling(); else stopPolling();
  }

  void startPolling() { if (_isPolling) return; _isPolling = true; _pollUpdates(); }
  void stopPolling() { _isPolling = false; _pollingTimer?.cancel(); }

  Future<void> _pollUpdates() async {
    if (!_isPolling || _botToken.isEmpty) return;
    try {
      final url = Uri.parse('https://api.telegram.org/bot$_botToken/getUpdates');
      final response = await http.post(url, headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'offset': _lastUpdateId + 1, 'timeout': 30, 'allowed_updates': ['message']}));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['ok'] == true) {
          for (final update in data['result'] as List) {
            _lastUpdateId = update['update_id'];
            if (update['message']?['text'] != null) {
              _handleIncomingMessage(update['message']['chat']['id'].toString(), update['message']['text']);
            }
          }
        }
      }
    } catch (e) { print('Telegram error: $e'); }
    if (_isPolling) _pollingTimer = Timer(const Duration(seconds: 1), _pollUpdates);
  }

  Future<void> _handleIncomingMessage(String chatId, String text) async {
    await _sendMessage(chatId, '\u{1F916} Received: "$text". Working...');
    try {
      final aiResponse = await _aiService.sendMessage(text);
      final action = _aiService.parseAction(aiResponse);
      if (action != null) {
        final result = await _actionHandler.execute(action, aiService: _aiService, onProgress: (msg) { _sendMessage(chatId, '\u23F3 $msg'); });
        await _sendMessage(chatId, '\u2705 ${result.details ?? "Done"}');
      } else {
        await _sendMessage(chatId, '\u{1F4AC} $aiResponse');
      }
    } catch (e) { await _sendMessage(chatId, '\u274C Error: $e'); }
  }

  Future<void> _sendMessage(String chatId, String text) async {
    if (_botToken.isEmpty) return;
    try {
      await http.post(Uri.parse('https://api.telegram.org/bot$_botToken/sendMessage'),
        headers: {'Content-Type': 'application/json'}, body: jsonEncode({'chat_id': chatId, 'text': text}));
    } catch (e) {}
  }

  void dispose() { stopPolling(); }
}
