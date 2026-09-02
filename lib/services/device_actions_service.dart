import 'package:flutter/services.dart';

/// Direct device control service using native Android APIs.
/// These actions execute instantly without screen automation.
class DeviceActionsService {
  static const _channel = MethodChannel('com.ev/device_actions');

  /// Toggle flashlight on/off
  Future<String> toggleFlash(bool on) async {
    try {
      final result = await _channel.invokeMethod<String>('toggleFlash', {'state': on ? 'on' : 'off'});
      return result ?? 'Flashlight toggled';
    } catch (e) {
      return 'Error toggling flashlight: $e';
    }
  }

  /// Set screen timeout in seconds
  Future<String> setScreenTimeout(int seconds) async {
    try {
      final result = await _channel.invokeMethod<String>('setScreenTimeout', {'seconds': seconds});
      return result ?? 'Screen timeout set';
    } catch (e) {
      return 'Error setting screen timeout: $e';
    }
  }

  /// Search YouTube directly without screen control
  Future<String> youtubeSearch(String query) async {
    try {
      final result = await _channel.invokeMethod<String>('youtubeSearch', {'query': query});
      return result ?? 'YouTube search launched';
    } catch (e) {
      return 'Error searching YouTube: $e';
    }
  }

  /// Set brightness directly via Settings.System
  Future<String> setBrightnessNative(int value) async {
    try {
      final result = await _channel.invokeMethod<String>('setBrightnessNative', {'value': value});
      return result ?? 'Brightness set';
    } catch (e) {
      return 'Error setting brightness: $e';
    }
  }

  /// Set volume directly via AudioManager
  Future<String> setVolumeNative(int level) async {
    try {
      final result = await _channel.invokeMethod<String>('setVolumeNative', {'level': level});
      return result ?? 'Volume set';
    } catch (e) {
      return 'Error setting volume: $e';
    }
  }

  /// Set alarm directly without UI
  Future<String> setAlarmDirect({required int hour, required int minute, String? label}) async {
    try {
      final result = await _channel.invokeMethod<String>('setAlarmDirect', {
        'hour': hour,
        'minute': minute,
        'label': label ?? '',
      });
      return result ?? 'Alarm set';
    } catch (e) {
      return 'Error setting alarm: $e';
    }
  }

  /// Set timer directly without UI
  Future<String> setTimerDirect({required int seconds, String? label}) async {
    try {
      final result = await _channel.invokeMethod<String>('setTimerDirect', {
        'seconds': seconds,
        'label': label ?? '',
      });
      return result ?? 'Timer set';
    } catch (e) {
      return 'Error setting timer: $e';
    }
  }

  /// Share image to a specific app
  Future<String> shareImage(String path, {String? packageName}) async {
    try {
      final result = await _channel.invokeMethod<String>('shareImage', {
        'path': path,
        'package': packageName ?? '',
      });
      return result ?? 'Image shared';
    } catch (e) {
      return 'Error sharing image: $e';
    }
  }

  /// Make a direct phone call
  Future<String> makeDirectCall(String number) async {
    try {
      final result = await _channel.invokeMethod<String>('makeDirectCall', {'number': number});
      return result ?? 'Calling';
    } catch (e) {
      return 'Error making call: $e';
    }
  }

  /// Open WhatsApp with optional number and message
  Future<String> openWhatsApp({String? number, String? message}) async {
    try {
      final result = await _channel.invokeMethod<String>('openWhatsApp', {
        'number': number ?? '',
        'message': message ?? '',
      });
      return result ?? 'WhatsApp opened';
    } catch (e) {
      return 'Error opening WhatsApp: $e';
    }
  }
}
