import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SavedConnection {
  const SavedConnection({
    required this.localUrl,
    required this.token,
    required this.deviceName,
    this.remoteUrl,
  });

  final String localUrl;
  final String? remoteUrl;
  final String token;
  final String deviceName;

  // Kept for older screens/services that still refer to the primary address.
  String get baseUrl => localUrl;

  SavedConnection copyWith({String? localUrl, String? remoteUrl, bool clearRemoteUrl = false}) =>
      SavedConnection(
        localUrl: localUrl ?? this.localUrl,
        remoteUrl: clearRemoteUrl ? null : (remoteUrl ?? this.remoteUrl),
        token: token,
        deviceName: deviceName,
      );
}

class SecureStore {
  static const _secure = FlutterSecureStorage();
  static const _tokenKey = 'bridge_token';
  static const _urlKey = 'bridge_url';
  static const _remoteUrlKey = 'bridge_remote_url';
  static const _nameKey = 'bridge_device_name';

  Future<void> save(SavedConnection connection) async {
    await _secure.write(key: _tokenKey, value: connection.token);
    final prefs = SharedPreferencesAsync();
    await prefs.setString(_urlKey, connection.localUrl);
    await prefs.setString(_nameKey, connection.deviceName);
    final remote = connection.remoteUrl?.trim();
    if (remote == null || remote.isEmpty) {
      await prefs.remove(_remoteUrlKey);
    } else {
      await prefs.setString(_remoteUrlKey, remote);
    }
  }

  Future<SavedConnection?> load() async {
    final token = await _secure.read(key: _tokenKey);
    final prefs = SharedPreferencesAsync();
    final url = await prefs.getString(_urlKey);
    final remote = await prefs.getString(_remoteUrlKey);
    final name = await prefs.getString(_nameKey);
    if (token == null || url == null) return null;
    return SavedConnection(
      localUrl: url,
      remoteUrl: remote,
      token: token,
      deviceName: name ?? 'MechOS',
    );
  }

  Future<void> clear() async {
    await _secure.delete(key: _tokenKey);
    final prefs = SharedPreferencesAsync();
    await prefs.remove(_urlKey);
    await prefs.remove(_remoteUrlKey);
    await prefs.remove(_nameKey);
  }
}
