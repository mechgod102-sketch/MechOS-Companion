import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SavedConnection {
  const SavedConnection({required this.baseUrl, required this.token, required this.deviceName});
  final String baseUrl;
  final String token;
  final String deviceName;
}

class SecureStore {
  static const _secure = FlutterSecureStorage();
  static const _tokenKey = 'bridge_token';
  static const _urlKey = 'bridge_url';
  static const _nameKey = 'bridge_device_name';

  Future<void> save(SavedConnection connection) async {
    await _secure.write(key: _tokenKey, value: connection.token);
    final prefs = SharedPreferencesAsync();
    await prefs.setString(_urlKey, connection.baseUrl);
    await prefs.setString(_nameKey, connection.deviceName);
  }

  Future<SavedConnection?> load() async {
    final token = await _secure.read(key: _tokenKey);
    final prefs = SharedPreferencesAsync();
    final url = await prefs.getString(_urlKey);
    final name = await prefs.getString(_nameKey);
    if (token == null || url == null) return null;
    return SavedConnection(baseUrl: url, token: token, deviceName: name ?? 'MechOS');
  }

  Future<void> clear() async {
    await _secure.delete(key: _tokenKey);
    final prefs = SharedPreferencesAsync();
    await prefs.remove(_urlKey);
    await prefs.remove(_nameKey);
  }
}
