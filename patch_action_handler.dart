import 'dart:io';
void main() {
  var file = File('/home/kali/EV/lib/services/action_handler.dart');
  var content = file.readAsStringSync();
  content = content.replaceFirst(
    '''
          final executor = TaskExecutor(
            aiService: aiService,
            screenAutomation: screenAutomation,
            actionHandler: this,
          );''',
    '''
          final executor = TaskExecutor(
            aiService: aiService,
            screenService: screenAutomation,
            appLauncher: appLauncher,
            shizukuService: shizuku,
            onProgress: onProgress,
          );'''
  );
  file.writeAsStringSync(content);
}
