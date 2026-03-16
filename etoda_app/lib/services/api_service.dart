import 'package:http/http.dart' as http;
import 'dart:convert';

/// Simple service wrapper for calling the Go backend.
///
/// The `baseUrl` is now configurable at compile time via the
/// `--dart-define=BASE_URL=...` flag (see `flutter run` docs) and can also
/// be overridden at runtime using [setBaseUrl].
///
/// The default value (`10.0.2.2`) works with the Android emulator; if you
/// ever run the app on a physical device you'll want to redefine the host
/// address (e.g. your machine's LAN IP).
class ApiService {
  // use a mutable field so tests or higher‑level code can re‑configure
  static String baseUrl = const String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'http://10.0.2.2:8080',
  );

  /// Override the base URL at runtime (e.g. after determining the device's
  /// network settings).
  static void setBaseUrl(String url) {
    baseUrl = url;
  }

  Future<Map<String, dynamic>> fetchDriverData() async {
    final response = await http.get(Uri.parse('$baseUrl/api/drivers'));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to connect to Go Backend');
    }
  }
}