import 'package:shizuku_api/shizuku_api.dart';

class ShizukuService {
  final ShizukuApi _shizuku = ShizukuApi();
  bool _isAvailable = false;
  bool _hasPermission = false;
  bool get isAvailable => _isAvailable;
  bool get hasPermission => _hasPermission;

  Future<bool> checkAvailability() async {
    try {
      _isAvailable = await _shizuku.pingBinder() ?? false;
      if (_isAvailable) _hasPermission = await _shizuku.checkPermission() ?? false;
      return _isAvailable;
    } catch (e) { _isAvailable = false; _hasPermission = false; return false; }
  }

  Future<bool> requestPermission() async {
    if (!_isAvailable) return false;
    try { _hasPermission = await _shizuku.requestPermission() ?? false; return _hasPermission; } catch (e) { return false; }
  }

  Future<String> runCommand(String command) async {
    if (!_isAvailable) return 'Shizuku is not running.';
    if (!_hasPermission) { final granted = await requestPermission(); if (!granted) return 'Shizuku permission denied.'; }
    try { final result = await _shizuku.runCommand(command); return result ?? 'Command executed'; } catch (e) { return 'Error: $e'; }
  }

  Future<String> toggleWifi(bool enable) async => runCommand('svc wifi ${enable ? 'enable' : 'disable'}');
  Future<String> toggleBluetooth(bool enable) async => runCommand('cmd bluetooth_manager ${enable ? 'enable' : 'disable'}');
  Future<String> forceStopApp(String packageName) async => runCommand('am force-stop $packageName');
  Future<String> clearAppData(String packageName) async => runCommand('pm clear $packageName');
}
