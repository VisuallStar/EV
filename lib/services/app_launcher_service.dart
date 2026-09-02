import 'package:installed_apps/installed_apps.dart';
import 'package:installed_apps/app_info.dart';
import 'package:url_launcher/url_launcher.dart';

class AppLauncherService {
  List<AppInfo>? _cachedApps;

  Future<List<AppInfo>> getInstalledApps() async {
    _cachedApps ??= await InstalledApps.getInstalledApps(false, false);
    return _cachedApps!;
  }

  void clearCache() { _cachedApps = null; }

  Future<List<AppInfo>> searchApps(String query) async {
    final apps = await getInstalledApps();
    final lowerQuery = query.toLowerCase();
    return apps.where((app) => app.name.toLowerCase().contains(lowerQuery)).toList();
  }

  Future<String> openApp(String appName) async {
    final matches = await searchApps(appName);
    if (matches.isEmpty) return 'Could not find app "$appName".';
    AppInfo? target;
    for (final app in matches) {
      if (app.name.toLowerCase() == appName.toLowerCase()) { target = app; break; }
    }
    target ??= matches.first;
    try {
      await InstalledApps.startApp(target.packageName);
      return 'Opened ${target.name}';
    } catch (e) { return 'Error opening ${target.name}: $e'; }
  }

  Future<String> openPackage(String packageName) async {
    try {
      await InstalledApps.startApp(packageName);
      return 'Launched $packageName';
    } catch (e) { return 'Error launching $packageName: $e'; }
  }

  Future<String> openUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return 'Opened $url';
      }
      return 'Cannot open $url';
    } catch (e) { return 'Error opening URL: $e'; }
  }
}
