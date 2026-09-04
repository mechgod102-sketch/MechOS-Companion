import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SavedConnection {
  const SavedConnection({
    required this.baseUrl,
    required this.token,
    required this.deviceName,
    this.remoteUrl,
    this.remoteEnabled = true,
  });

  final String baseUrl;
  final String token;
  final String deviceName;
  final String? remoteUrl;
  final bool remoteEnabled;

  SavedConnection copyWith({
    String? baseUrl,
    String? token,
    String? deviceName,
    String? remoteUrl,
    bool clearRemoteUrl = false,
    bool? remoteEnabled,
  }) =>
      SavedConnection(
        baseUrl: baseUrl ?? this.baseUrl,
        token: token ?? this.token,
        deviceName: deviceName ?? this.deviceName,
        remoteUrl: clearRemoteUrl ? null : (remoteUrl ?? this.remoteUrl),
        remoteEnabled: remoteEnabled ?? this.remoteEnabled,
      );
}

class SecureStore {
  static const _secure = FlutterSecureStorage();
  static const _tokenKey = 'bridge_token';
  static const _urlKey = 'bridge_url';
  static const _nameKey = 'bridge_device_name';
  static const _remoteUrlKey = 'bridge_remote_url';
  static const _remoteEnabledKey = 'bridge_remote_enabled';

  Future<void> save(SavedConnection connection) async {
    await _secure.write(key: _tokenKey, value: connection.token);
    final prefs = SharedPreferencesAsync();
    await prefs.setString(_urlKey, connection.baseUrl);
    await prefs.setString(_nameKey, connection.deviceName);
    if (connection.remoteUrl == null || connection.remoteUrl!.isEmpty) {
      await prefs.remove(_remoteUrlKey);
    } else {
      await prefs.setString(_remoteUrlKey, connection.remoteUrl!);
    }
    await prefs.setBool(_remoteEnabledKey, connection.remoteEnabled);
  }

  Future<SavedConnection?> load() async {
    final token = await _secure.read(key: _tokenKey);
    final prefs = SharedPreferencesAsync();
    final url = await prefs.getString(_urlKey);
    final name = await prefs.getString(_nameKey);
    final remoteUrl = await prefs.getString(_remoteUrlKey);
    final remoteEnabled = await prefs.getBool(_remoteEnabledKey) ?? true;
    if (token == null || url == null) return null;
    return SavedConnection(
      baseUrl: url,
      token: token,
      deviceName: name ?? 'MechOS',
      remoteUrl: remoteUrl,
      remoteEnabled: remoteEnabled,
    );
  }

  Future<void> clear() async {
    await _secure.delete(key: _tokenKey);
    final prefs = SharedPreferencesAsync();
    await prefs.remove(_urlKey);
    await prefs.remove(_nameKey);
    await prefs.remove(_remoteUrlKey);
    await prefs.remove(_remoteEnabledKey);
  }
}
