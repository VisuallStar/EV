import 'package:android_intent_plus/android_intent.dart';
import 'device_actions_service.dart';

class AlarmService {
  final DeviceActionsService _deviceActions = DeviceActionsService();

  /// Set an alarm directly using native Android API (no screen control)
  Future<String> setAlarm({required int hour, required int minute, String? label}) async {
    return await _deviceActions.setAlarmDirect(hour: hour, minute: minute, label: label);
  }

  /// Set a timer directly using native Android API (no screen control)
  Future<String> setTimer({required int seconds, String? label}) async {
    return await _deviceActions.setTimerDirect(seconds: seconds, label: label);
  }

  /// Set a reminder (uses timer)
  Future<String> setReminder({required int minutes, String? label}) async {
    return await _deviceActions.setTimerDirect(seconds: minutes * 60, label: label ?? 'Reminder');
  }
}
