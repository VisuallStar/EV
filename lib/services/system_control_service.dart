import 'package:volume_controller/volume_controller.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'device_actions_service.dart';

class SystemControlService {
  final DeviceActionsService _deviceActions = DeviceActionsService();

  SystemControlService() {
    VolumeController().showSystemUI = false;
  }

  Future<String> setVolume(int level) async {
    return await _deviceActions.setVolumeNative(level);
  }

  Future<int> getVolume() async {
    try {
      final volume = await VolumeController().getVolume();
      return (volume * 100).round();
    } catch (e) { return -1; }
  }

  Future<String> setBrightness(int level) async {
    final value = (level * 255 / 100).round();
    return await _deviceActions.setBrightnessNative(value);
  }

  Future<int> getBrightness() async {
    try {
      final brightness = await ScreenBrightness().current;
      return (brightness * 100).round();
    } catch (e) { return -1; }
  }

  Future<String> toggleFlash(bool on) async {
    return await _deviceActions.toggleFlash(on);
  }

  Future<String> setScreenTimeout(int seconds) async {
    return await _deviceActions.setScreenTimeout(seconds);
  }
}
