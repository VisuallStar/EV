import '../models/chat_message.dart';
import '../models/agent_action.dart';
import 'ai_service.dart';
import 'app_launcher_service.dart';
import 'communication_service.dart';
import 'contacts_service.dart';
import 'alarm_service.dart';
import 'system_control_service.dart';
import 'device_actions_service.dart';
import 'screen_automation_service.dart';
import 'shizuku_service.dart';
import 'task_executor.dart';
import 'notification_service.dart';

class ActionHandler {
  final AppLauncherService appLauncher = AppLauncherService();
  final CommunicationService communication = CommunicationService();
  final ContactsService contacts = ContactsService();
  final AlarmService alarm = AlarmService();
  final SystemControlService systemControl = SystemControlService();
  final DeviceActionsService deviceActions = DeviceActionsService();
  final ScreenAutomationService screenAutomation = ScreenAutomationService();
  final ShizukuService shizuku = ShizukuService();
  final NotificationService notification = NotificationService();

  bool _taskCancelled = false;

  void cancelTask() {
    _taskCancelled = true;
  }

  void resetCancellation() {
    _taskCancelled = false;
  }

  bool get isTaskCancelled => _taskCancelled;

  Future<AgentActionResult> execute(
    Map<String, dynamic> actionData, {
    required AiService aiService,
    Function(String)? onProgress,
  }) async {
    final action = actionData['action'] as String? ?? 'general_query';
    final params = actionData['params'] as Map<String, dynamic>? ?? {};
    final response = actionData['response'] as String? ?? '';

    try {
      _taskCancelled = false;
      String result;
      switch (action) {
        case 'open_app':
          final appName = params['app_name'] as String? ?? '';
          result = await appLauncher.openApp(appName);
          break;

        case 'make_call':
          result = await communication.makeCall(
            contactName: params['contact_name'] as String?,
            phoneNumber: params['phone_number'] as String?,
          );
          break;

        case 'send_sms':
          result = await communication.sendSms(
            contactName: params['contact_name'] as String?,
            phoneNumber: params['phone_number'] as String?,
            message: params['message'] as String? ?? '',
          );
          break;

        case 'send_email':
          result = await communication.sendEmail(
            to: params['to'] as String? ?? '',
            subject: params['subject'] as String?,
            body: params['body'] as String?,
          );
          break;

        case 'search_contact':
          result = await contacts.searchAndFormat(params['query'] as String? ?? '');
          break;

        case 'set_alarm':
          result = await alarm.setAlarm(
            hour: params['hour'] as int? ?? 0,
            minute: params['minute'] as int? ?? 0,
            label: params['label'] as String?,
          );
          break;

        case 'set_timer':
          result = await alarm.setTimer(
            seconds: params['seconds'] as int? ?? 60,
            label: params['label'] as String?,
          );
          break;

        case 'set_volume':
          result = await systemControl.setVolume(params['level'] as int? ?? 50);
          break;

        case 'set_brightness':
          result = await systemControl.setBrightness(params['level'] as int? ?? 50);
          break;

        case 'toggle_flash':
          final state = params['state'] as String? ?? 'off';
          result = await systemControl.toggleFlash(state == 'on');
          break;

        case 'set_screen_timeout':
          result = await systemControl.setScreenTimeout(params['seconds'] as int? ?? 30);
          break;

        case 'youtube_search':
          result = await deviceActions.youtubeSearch(params['query'] as String? ?? '');
          break;

        case 'take_screenshot':
          final screenshot = await screenAutomation.takeScreenshot();
          result = screenshot != null ? 'Screenshot taken successfully' : 'Failed to take screenshot';
          break;

        case 'share_image':
          result = await deviceActions.shareImage(
            params['path'] as String? ?? '',
            packageName: _getPackageName(params['app'] as String?),
          );
          break;

        case 'open_whatsapp':
          result = await deviceActions.openWhatsApp(
            number: params['number'] as String?,
            message: params['message'] as String?,
          );
          break;

        case 'read_screen':
          result = await screenAutomation.getScreenDescription();
          break;

        case 'run_adb_command':
          result = await shizuku.runCommand(params['command'] as String? ?? '');
          break;

        case 'execute_task':
          final goal = params['goal'] as String? ?? '';
          if (_taskCancelled) {
            result = 'Task was cancelled.';
            break;
          }
          final executor = TaskExecutor(
            aiService: aiService,
            screenService: screenAutomation,
            appLauncher: appLauncher,
            shizukuService: shizuku,
            onProgress: onProgress,
          );
          result = await executor.executeTask(
            goal,
            onProgress: onProgress,
          );
          break;

        case 'general_query':
        default:
          return AgentActionResult(
            actionType: action,
            success: true,
            details: response,
          );
      }

      return AgentActionResult(
        actionType: action,
        success: true,
        details: result,
      );
    } catch (e) {
      return AgentActionResult(
        actionType: action,
        success: false,
        details: 'Error: $e',
      );
    }
  }

  String? _getPackageName(String? appName) {
    if (appName == null) return null;
    final lower = appName.toLowerCase();
    if (lower.contains('whatsapp')) return 'com.whatsapp';
    if (lower.contains('instagram')) return 'com.instagram.android';
    if (lower.contains('snapchat')) return 'com.snapchat.android';
    if (lower.contains('telegram')) return 'org.telegram.messenger';
    return null;
  }
}
