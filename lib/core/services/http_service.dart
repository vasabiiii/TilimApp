import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class HttpService {
  static final HttpService _instance = HttpService._internal();
  factory HttpService() => _instance;
  HttpService._internal();

  Future<String?> _getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  Future<Map<String, String>> _getHeaders({Map<String, String>? additionalHeaders}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };

    final accessToken = await _getAccessToken();
    if (accessToken != null) {
      headers['Authorization'] = 'Bearer $accessToken';
    }

    if (additionalHeaders != null) {
      headers.addAll(additionalHeaders);
    }

    return headers;
  }

  Future<http.Response> get(String url, {Map<String, String>? headers}) async {
    final requestHeaders = await _getHeaders(additionalHeaders: headers);
    return await http.get(Uri.parse(url), headers: requestHeaders);
  }

  Future<http.Response> post(String url, {Map<String, String>? headers, Object? body}) async {
    final requestHeaders = await _getHeaders(additionalHeaders: headers);
    return await http.post(Uri.parse(url), headers: requestHeaders, body: body);
  }

  Future<http.Response> put(String url, {Map<String, String>? headers, Object? body}) async {
    final requestHeaders = await _getHeaders(additionalHeaders: headers);
    return await http.put(Uri.parse(url), headers: requestHeaders, body: body);
  }

  Future<http.Response> delete(String url, {Map<String, String>? headers}) async {
    final requestHeaders = await _getHeaders(additionalHeaders: headers);
    return await http.delete(Uri.parse(url), headers: requestHeaders);
  }

  Future<http.Response> patch(String url, {Map<String, String>? headers, Object? body}) async {
    final requestHeaders = await _getHeaders(additionalHeaders: headers);
    print('PATCH запрос к $url');
    print('Заголовки: $requestHeaders');
    print('Тело запроса: $body');
    return await http.patch(Uri.parse(url), headers: requestHeaders, body: body);
  }
} 