import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/agent_action.dart';

class AiService {
  // Provider presets
  static const Map<String, Map<String, String>> providerPresets = {
    'gemini': {
      'name': 'Gemini',
      'baseUrl': 'https://generativelanguage.googleapis.com/v1beta',
      'defaultModel': 'gemini-2.0-flash',
    },
    'groq': {
      'name': 'Groq',
      'baseUrl': 'https://api.groq.com/openai/v1',
      'defaultModel': 'llama-3.3-70b-versatile',
    },
    'anthropic': {
      'name': 'Anthropic',
      'baseUrl': 'https://api.anthropic.com/v1',
      'defaultModel': 'claude-sonnet-4-20250514',
    },
    'openai': {
      'name': 'OpenAI',
      'baseUrl': 'https://api.openai.com/v1',
      'defaultModel': 'gpt-4o-mini',
    },
    'nvidia': {
      'name': 'NVIDIA',
      'baseUrl': 'https://integrate.api.nvidia.com/v1',
      'defaultModel': 'meta/llama-3.1-8b-instruct',
    },
    'ollama': {
      'name': 'Ollama',
      'baseUrl': 'http://localhost:11434/v1',
      'defaultModel': 'gemma2',
    },
    'custom': {
      'name': 'Custom',
      'baseUrl': '',
      'defaultModel': '',
    },
    'local': {
      'name': 'Local',
      'baseUrl': 'http://192.168.1.100:8080/v1',
      'defaultModel': 'default',
    },
  };

  static const String nvidiaBaseUrl = 'https://integrate.api.nvidia.com/v1';
  static const String nvidiaDefaultModel = 'meta/llama-3.1-8b-instruct';

  static bool isNvidiaBaseUrl(String baseUrl) {
    return baseUrl.toLowerCase().contains('integrate.api.nvidia.com');
  }

  String _apiKey = '';
  String _baseUrl = 'https://api.groq.com/openai/v1';
  String _model = 'llama-3.3-70b-versatile';
  String _provider = 'groq';
  int _maxSteps = 15;
  bool _disableMaxSteps = false;
  double _temperature = 0.7;
  int _maxTokens = 4096;
  bool _useScreenCompression = true;
  bool _useSystemPrompt = true;
  bool _isInitialized = false;

  final List<Map<String, String>> _conversationHistory = [];

  // Getters
  String get apiKey => _apiKey;
  String get baseUrl => _baseUrl;
  String get model => _model;
  String get provider => _provider;
  int get rawMaxSteps => _maxSteps;
  int get maxSteps => _disableMaxSteps ? 999 : _maxSteps;
  bool get disableMaxSteps => _disableMaxSteps;
  double get temperature => _temperature;
  int get maxTokens => _maxTokens;
  bool get useScreenCompression => _useScreenCompression;
  bool get useSystemPrompt => _useSystemPrompt;
  bool get isConfigured => _baseUrl.isNotEmpty && _model.isNotEmpty;

  // System prompt for the agent
  static const String systemPrompt = '''
You are EV, a super-fast AI assistant that controls Android devices. You execute user commands instantly.

When the user asks you to perform an action, respond with a JSON object:
{"action": "action_name", "params": {"key": "value"}, "response": "human readable response"}

Available actions:
- open_app: {"app_name": "YouTube"} - Opens an app
- make_call: {"contact_name": "Mom"} or {"phone_number": "+1234"} - Makes a call
- send_sms: {"contact_name": "John", "message": "Hi"} - Sends SMS
- search_contact: {"query": "John"} - Searches contacts
- set_alarm: {"hour": 7, "minute": 30, "label": "Wake up"} - Sets alarm directly (no screen control)
- set_timer: {"seconds": 300, "label": "Tea"} - Sets timer directly (no screen control)
- set_volume: {"level": 50} - Sets volume 0-100 directly
- set_brightness: {"level": 70} - Sets brightness 0-100 directly
- toggle_flash: {"state": "on"} or {"state": "off"} - Toggles flashlight directly
- set_screen_timeout: {"seconds": 30} - Sets screen timeout directly
- youtube_search: {"query": "cats"} - Searches YouTube directly without screen control
- take_screenshot: {} - Takes a screenshot
- share_image: {"path": "/path/to/image", "app": "whatsapp"} - Shares an image
- open_whatsapp: {"number": "+1234", "message": "Hi"} - Opens WhatsApp chat
- read_screen: {} - Reads current screen content
- send_email: {"to": "email@example.com", "subject": "Hi", "body": "Hello"} - Sends email
- run_adb_command: {"command": "..."} - Runs ADB command via Shizuku
- execute_task: {"goal": "do something complex"} - Multi-step screen automation task
- general_query: {} - For general questions, just respond naturally

IMPORTANT:
- For alarm, timer, volume, brightness, flash, screen timeout, YouTube search: these work DIRECTLY without screen control. Use them.
- For reminders: use set_timer with appropriate seconds
- For calls: prefer make_call action
- Only use execute_task for complex multi-step operations that require screen automation
- Be concise and fast in responses
- If it's a general question (not a device action), just respond normally without JSON
''';

  Future<void> init() async {
    if (_isInitialized) return;
    final prefs = await SharedPreferences.getInstance();
    _apiKey = prefs.getString('api_key') ?? '';
    _baseUrl = prefs.getString('base_url') ?? 'https://api.groq.com/openai/v1';
    _model = prefs.getString('model') ?? 'llama-3.3-70b-versatile';
    _provider = prefs.getString('provider') ?? 'groq';
    _maxSteps = prefs.getInt('max_steps') ?? 15;
    _disableMaxSteps = prefs.getBool('disable_max_steps') ?? false;
    _temperature = prefs.getDouble('temperature') ?? 0.7;
    _maxTokens = prefs.getInt('max_tokens') ?? 4096;
    _useScreenCompression = prefs.getBool('use_screen_compression') ?? true;
    _useSystemPrompt = prefs.getBool('use_system_prompt') ?? true;
    _isInitialized = true;
  }

  Future<void> saveSettings({required String apiKey, required String baseUrl, required String model, String? provider}) async {
    _apiKey = apiKey;
    _baseUrl = baseUrl;
    _model = model;
    if (provider != null) _provider = provider;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('api_key', apiKey);
    await prefs.setString('base_url', baseUrl);
    await prefs.setString('model', model);
    if (provider != null) await prefs.setString('provider', provider);
  }

  Future<void> saveMaxSteps(int steps) async {
    _maxSteps = steps;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('max_steps', steps);
  }

  Future<void> saveDisableMaxSteps(bool disable) async {
    _disableMaxSteps = disable;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('disable_max_steps', disable);
  }

  Future<void> saveAdvancedSettings({required double temperature, required int maxTokens, required bool useScreenCompression, required bool useSystemPrompt}) async {
    _temperature = temperature;
    _maxTokens = maxTokens;
    _useScreenCompression = useScreenCompression;
    _useSystemPrompt = useSystemPrompt;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('temperature', temperature);
    await prefs.setInt('max_tokens', maxTokens);
    await prefs.setBool('use_screen_compression', useScreenCompression);
    await prefs.setBool('use_system_prompt', useSystemPrompt);
  }

  void clearHistory() {
    _conversationHistory.clear();
  }

  List<Map<String, String>> get conversationHistory => _conversationHistory;

  void addHistoryMessage(String role, String content) {
    _conversationHistory.add({'role': role, 'content': content});
  }

  // Detect provider type from base URL
  String _detectProviderType() {
    final url = _baseUrl.toLowerCase();
    if (url.contains('generativelanguage.googleapis.com')) return 'gemini';
    if (url.contains('anthropic.com')) return 'anthropic';
    if (url.contains('integrate.api.nvidia.com')) return 'nvidia';
    if (url.contains('groq.com')) return 'groq';
    if (url.contains('api.openai.com')) return 'openai';
    if (url.contains('localhost') || url.contains('10.0.2.2') || url.contains('192.168')) {
      if (url.contains('11434')) return 'ollama';
      return 'local';
    }
    return 'custom';
  }

  // Build messages for different providers
  Map<String, dynamic> _buildRequestBody(List<Map<String, String>> messages, {bool stream = false}) {
    final providerType = _detectProviderType();

    if (providerType == 'gemini') {
      return _buildGeminiBody(messages, stream: stream);
    } else if (providerType == 'anthropic') {
      return _buildAnthropicBody(messages);
    } else {
      return _buildOpenAICompatibleBody(messages, stream: stream);
    }
  }

  Map<String, dynamic> _buildGeminiBody(List<Map<String, String>> messages, {bool stream = false}) {
    final contents = <Map<String, dynamic>>[];
    for (final msg in messages) {
      if (msg['role'] == 'system') continue; // Gemini handles system prompt differently
      contents.add({
        'role': msg['role'] == 'assistant' ? 'model' : 'user',
        'parts': [{'text': msg['content'] ?? ''}],
      });
    }

    final body = <String, dynamic>{
      'contents': contents,
      'generationConfig': {
        'temperature': _temperature,
        'maxOutputTokens': _maxTokens,
      },
    };

    // Add system instruction
    final systemMsg = messages.where((m) => m['role'] == 'system').toList();
    if (systemMsg.isNotEmpty) {
      body['systemInstruction'] = {
        'parts': [{'text': systemMsg.first['content'] ?? ''}],
      };
    }

    return body;
  }

  Map<String, dynamic> _buildAnthropicBody(List<Map<String, String>> messages) {
    final anthropicMessages = <Map<String, dynamic>>[];
    String? systemText;

    for (final msg in messages) {
      if (msg['role'] == 'system') {
        systemText = msg['content'];
        continue;
      }
      anthropicMessages.add({
        'role': msg['role'],
        'content': msg['content'] ?? '',
      });
    }

    final body = <String, dynamic>{
      'model': _model,
      'messages': anthropicMessages,
      'max_tokens': _maxTokens,
      'temperature': _temperature,
    };

    if (systemText != null) {
      body['system'] = systemText;
    }

    return body;
  }

  Map<String, dynamic> _buildOpenAICompatibleBody(List<Map<String, String>> messages, {bool stream = false}) {
    return {
      'model': _model,
      'messages': messages,
      'temperature': _temperature,
      'max_tokens': _maxTokens,
      'stream': stream,
    };
  }

  Map<String, String> _buildHeaders() {
    final providerType = _detectProviderType();

    if (providerType == 'gemini') {
      return {'Content-Type': 'application/json'};
    } else if (providerType == 'anthropic') {
      return {
        'Content-Type': 'application/json',
        'x-api-key': _apiKey,
        'anthropic-version': '2023-06-01',
      };
    } else {
      return {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      };
    }
  }

  String _buildUrl({bool stream = false}) {
    final providerType = _detectProviderType();

    if (providerType == 'gemini') {
      final method = stream ? 'streamGenerateContent' : 'generateContent';
      return '$_baseUrl/models/$_model:$method?key=$_apiKey';
    } else if (providerType == 'anthropic') {
      return '$_baseUrl/messages';
    } else {
      return '$_baseUrl/chat/completions';
    }
  }

  // Non-streaming message
  Future<String> sendMessage(String userMessage) async {
    if (!isConfigured) return 'AI is not configured. Please set up API in Settings.';

    _conversationHistory.add({'role': 'user', 'content': userMessage});

    final messages = <Map<String, String>>[];
    if (_useSystemPrompt) {
      messages.add({'role': 'system', 'content': systemPrompt});
    }
    messages.addAll(_conversationHistory);

    try {
      final url = _buildUrl();
      final headers = _buildHeaders();
      final body = _buildRequestBody(messages);

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = _extractContent(data);
        _conversationHistory.add({'role': 'assistant', 'content': content});
        return content;
      } else {
        return 'API Error ${response.statusCode}: ${response.body.length > 200 ? response.body.substring(0, 200) : response.body}';
      }
    } catch (e) {
      return 'Error: $e';
    }
  }

  String _extractContent(Map<String, dynamic> data) {
    final providerType = _detectProviderType();

    if (providerType == 'gemini') {
      final candidates = data['candidates'] as List?;
      if (candidates != null && candidates.isNotEmpty) {
        final content = candidates[0]['content'];
        final parts = content?['parts'] as List?;
        if (parts != null && parts.isNotEmpty) {
          return parts[0]['text'] ?? '';
        }
      }
      return '';
    } else if (providerType == 'anthropic') {
      final content = data['content'] as List?;
      if (content != null && content.isNotEmpty) {
        return content[0]['text'] ?? '';
      }
      return '';
    } else {
      // OpenAI compatible
      final choices = data['choices'] as List?;
      if (choices != null && choices.isNotEmpty) {
        return choices[0]['message']?['content'] ?? '';
      }
      return '';
    }
  }

  // Streaming message
  Stream<String> sendMessageStream(String userMessage, {bool isAgentMode = false}) async* {
    if (!isConfigured) {
      yield 'AI is not configured. Please set up API in Settings.';
      return;
    }

    _conversationHistory.add({'role': 'user', 'content': userMessage});

    final messages = <Map<String, String>>[];
    if (_useSystemPrompt) {
      messages.add({'role': 'system', 'content': systemPrompt});
    }
    messages.addAll(_conversationHistory);

    final providerType = _detectProviderType();
    final url = _buildUrl(stream: true);
    final headers = _buildHeaders();
    final body = _buildRequestBody(messages, stream: providerType != 'anthropic');

    // Anthropic streaming
    if (providerType == 'anthropic') {
      body['stream'] = true;
    }

    try {
      final request = http.Request('POST', Uri.parse(url));
      request.headers.addAll(headers);
      request.body = jsonEncode(body);

      final client = http.Client();
      final response = await client.send(request).timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        final errorBody = await response.stream.bytesToString();
        yield 'API Error ${response.statusCode}: ${errorBody.length > 200 ? errorBody.substring(0, 200) : errorBody}';
        client.close();
        return;
      }

      final fullResponse = StringBuffer();
      String buffer = '';

      await for (final chunk in response.stream.transform(utf8.decoder)) {
        buffer += chunk;
        final lines = buffer.split('\n');
        buffer = lines.removeLast();

        for (final line in lines) {
          final trimmed = line.trim();
          if (trimmed.isEmpty) continue;

          if (providerType == 'gemini') {
            // Gemini streaming returns JSON array chunks
            if (trimmed.startsWith('[')) {
              try {
                String jsonStr = trimmed;
                if (jsonStr.startsWith('[')) jsonStr = jsonStr.substring(1);
                if (jsonStr.startsWith(',')) jsonStr = jsonStr.substring(1);
                if (jsonStr.endsWith(']')) jsonStr = jsonStr.substring(0, jsonStr.length - 1);
                jsonStr = jsonStr.trim();
                if (jsonStr.isEmpty || !jsonStr.startsWith('{')) continue;
                final data = jsonDecode(jsonStr);
                final candidates = data['candidates'] as List?;
                if (candidates != null && candidates.isNotEmpty) {
                  final parts = candidates[0]['content']?['parts'] as List?;
                  if (parts != null && parts.isNotEmpty) {
                    final text = parts[0]['text'] ?? '';
                    if (text.isNotEmpty) {
                      fullResponse.write(text);
                      yield fullResponse.toString();
                    }
                  }
                }
              } catch (_) {}
            }
          } else if (providerType == 'anthropic') {
            if (!trimmed.startsWith('data: ')) continue;
            final jsonStr = trimmed.substring(6);
            if (jsonStr == '[DONE]') break;
            try {
              final data = jsonDecode(jsonStr);
              final type = data['type'];
              if (type == 'content_block_delta') {
                final text = data['delta']?['text'] ?? '';
                if (text.isNotEmpty) {
                  fullResponse.write(text);
                  yield fullResponse.toString();
                }
              }
            } catch (_) {}
          } else {
            // OpenAI compatible SSE
            if (!trimmed.startsWith('data: ')) continue;
            final jsonStr = trimmed.substring(6);
            if (jsonStr == '[DONE]') break;
            try {
              final data = jsonDecode(jsonStr);
              final delta = data['choices']?[0]?['delta']?['content'];
              if (delta != null && delta.isNotEmpty) {
                fullResponse.write(delta);
                yield fullResponse.toString();
              }
            } catch (_) {}
          }
        }
      }

      // Process remaining buffer
      if (buffer.trim().isNotEmpty) {
        // handle any remaining data in buffer similar to above
      }

      final finalResponse = fullResponse.toString();
      if (finalResponse.isNotEmpty) {
        _conversationHistory.add({'role': 'assistant', 'content': finalResponse});
      }
      client.close();
    } catch (e) {
      yield 'Error: $e';
    }
  }

  // Task message for TaskExecutor (non-streaming)
  Future<String> sendTaskMessage(String taskPrompt, List<Map<String, String>> taskHistory) async {
    if (!isConfigured) return '{"action": "task_complete", "summary": "AI not configured"}';

    final messages = <Map<String, String>>[];
    messages.addAll(taskHistory);
    messages.add({'role': 'user', 'content': taskPrompt});

    try {
      final url = _buildUrl();
      final headers = _buildHeaders();
      final body = _buildRequestBody(messages);

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return _extractContent(jsonDecode(response.body));
      } else {
        return '{"action": "task_complete", "summary": "API error ${response.statusCode}"}';
      }
    } catch (e) {
      return '{"action": "task_complete", "summary": "Error: $e"}';
    }
  }

  // Parse action from AI response
  Map<String, dynamic>? parseAction(String response) {
    try {
      // Try to find JSON in the response
      final jsonMatch = RegExp(r'\{[^{}]*"action"[^{}]*\}', dotAll: true).firstMatch(response);
      if (jsonMatch != null) {
        final jsonStr = jsonMatch.group(0)!;
        final parsed = jsonDecode(jsonStr) as Map<String, dynamic>;
        if (parsed.containsKey('action')) {
          return parsed;
        }
      }

      // Try parsing entire response as JSON
      if (response.trim().startsWith('{')) {
        final parsed = jsonDecode(response.trim()) as Map<String, dynamic>;
        if (parsed.containsKey('action')) {
          return parsed;
        }
      }
    } catch (_) {}
    return null;
  }

  // Fetch available models from API
  Future<List<String>> fetchAvailableModels(String baseUrl, String apiKey) async {
    try {
      final providerType = _detectProviderFromUrl(baseUrl);

      if (providerType == 'gemini') {
        final url = '$baseUrl/models?key=$apiKey';
        final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final models = (data['models'] as List?) ?? [];
          return models.where((m) => m['name']?.toString().contains('gemini') ?? false)
              .map<String>((m) => m['name'].toString().replaceFirst('models/', '')).toList();
        }
      } else if (providerType == 'anthropic') {
        // Anthropic doesn't have a models endpoint, return known models
        return ['claude-sonnet-4-20250514', 'claude-3-5-haiku-20241022', 'claude-3-5-sonnet-20241022'];
      } else {
        // OpenAI-compatible
        final url = '$baseUrl/models';
        final headers = <String, String>{'Authorization': 'Bearer $apiKey'};
        final response = await http.get(Uri.parse(url), headers: headers).timeout(const Duration(seconds: 10));
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final models = (data['data'] as List?) ?? [];
          return models.map<String>((m) => m['id'].toString()).toList()..sort();
        }
      }
    } catch (e) {
      print('Error fetching models: $e');
    }
    return [];
  }

  String _detectProviderFromUrl(String url) {
    final lower = url.toLowerCase();
    if (lower.contains('generativelanguage.googleapis.com')) return 'gemini';
    if (lower.contains('anthropic.com')) return 'anthropic';
    return 'openai';
  }
}
