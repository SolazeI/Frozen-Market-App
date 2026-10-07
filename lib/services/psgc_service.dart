import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../core/errors/app_exception.dart';
import '../models/psgc_place.dart';

/// Client for the free PSGC API (https://psgc.gitlab.io/api). No API key.
/// Results are cached in memory for the session, so each list loads once.
class PsgcService {
  PsgcService([http.Client? client]) : _client = client ?? http.Client();

  static const _base = 'https://psgc.gitlab.io/api';
  final http.Client _client;
  final Map<String, List<PsgcPlace>> _cache = {};

  Future<List<PsgcPlace>> regions() => _get('/regions/', isRegion: true);

  Future<List<PsgcPlace>> provinces(String regionCode) =>
      _get('/regions/$regionCode/provinces/');

  Future<List<PsgcPlace>> citiesByProvince(String provinceCode) =>
      _get('/provinces/$provinceCode/cities-municipalities/');

  /// For regions without provinces (e.g. NCR).
  Future<List<PsgcPlace>> citiesByRegion(String regionCode) =>
      _get('/regions/$regionCode/cities-municipalities/');

  Future<List<PsgcPlace>> barangays(String cityCode) =>
      _get('/cities-municipalities/$cityCode/barangays/');

  Future<List<PsgcPlace>> _get(String path, {bool isRegion = false}) async {
    final cached = _cache[path];
    if (cached != null) return cached;

    try {
      final res = await _client
          .get(Uri.parse('$_base$path'))
          .timeout(const Duration(seconds: 20));
      if (res.statusCode != 200) throw const _PsgcFailure();

      final list = (jsonDecode(res.body) as List)
          .map((e) => PsgcPlace.fromJson(Map<String, dynamic>.from(e as Map),
              isRegion: isRegion))
          .toList()
        ..sort((a, b) => a.name.compareTo(b.name));

      return _cache[path] = list;
    } on SocketException {
      throw const AppException(
          'No internet connection. Check your network and try again.');
    } on TimeoutException {
      throw const AppException('Loading locations timed out. Please try again.');
    } on _PsgcFailure {
      throw const AppException(
          "We couldn't load locations right now. Please try again.");
    } on http.ClientException {
      throw const AppException(
          "We couldn't load locations right now. Please try again.");
    } on FormatException {
      throw const AppException(
          "We couldn't load locations right now. Please try again.");
    }
  }
}

class _PsgcFailure implements Exception {
  const _PsgcFailure();
}
