import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../models/place_result.dart';

final geocodingServiceProvider =
    Provider<GeocodingService>((ref) => GeocodingService());

class GeocodingException implements Exception {
  final String message;
  const GeocodingException(this.message);
}

/// Nominatim (OpenStreetMap) ke rules: 1 request/second, cache, app ki pehchaan.
class GeocodingService {
  static const _host = 'nominatim.openstreetmap.org';
  static const _countryCodes = 'pk'; // search sirf is mulk mein. Badalna ho to yahan.
  static const _minGap = Duration(milliseconds: 1100);

  final _client = http.Client();
  final _cache = <String, dynamic>{};
  DateTime _last = DateTime.fromMillisecondsSinceEpoch(0);
  Future<void> _queue = Future.value();

  /// Saari requests ek line mein chalti hain, har ek ke beech kam se kam 1.1 second
  Future<T> _throttled<T>(Future<T> Function() task) {
    final completer = Completer<T>();
    _queue = _queue.then((_) async {
      final wait = _minGap - DateTime.now().difference(_last);
      if (wait > Duration.zero) await Future.delayed(wait);
      try {
        completer.complete(await task());
      } catch (e, s) {
        completer.completeError(e, s);
      }
      _last = DateTime.now();
    });
    return completer.future;
  }

  Future<dynamic> _getJson(String path, Map<String, String> params) async {
    final uri = Uri.https(_host, path, params);
    final key = uri.toString();
    if (_cache.containsKey(key)) return _cache[key];

    try {
      final data = await _throttled(() async {
        final res = await _client.get(uri, headers: {
          // Browser User-Agent set nahi karne deta, wahan Referer khud jata hai
          if (!kIsWeb) 'User-Agent': 'ParcelGo/1.0 (com.hamza.parcelgo.parcel_go)',
        }).timeout(const Duration(seconds: 12));
        if (res.statusCode != 200) {
          throw const GeocodingException(
              'Address service is busy. Please try again in a moment.');
        }
        return jsonDecode(res.body);
      });
      _cache[key] = data;
      return data;
    } on GeocodingException {
      rethrow;
    } catch (_) {
      throw const GeocodingException(
          'Could not reach the address service. Check your internet.');
    }
  }

  Future<List<PlaceResult>> search(String query) async {
    final q = query.trim();
    if (q.length < 3) return [];
    final data = await _getJson('/search', {
      'q': q,
      'format': 'jsonv2',
      'limit': '5',
      'countrycodes': _countryCodes,
      'accept-language': 'en',
    });
    return (data as List)
        .map((e) => PlaceResult(
              address: e['display_name'] as String,
              latitude: double.parse(e['lat'] as String),
              longitude: double.parse(e['lon'] as String),
            ))
        .toList();
  }

  Future<String?> reverse(LatLng point) async {
    final data = await _getJson('/reverse', {
      'lat': point.latitude.toStringAsFixed(5),
      'lon': point.longitude.toStringAsFixed(5),
      'format': 'jsonv2',
      'zoom': '18',
      'accept-language': 'en',
    });
    if (data is Map && data['display_name'] is String) {
      return data['display_name'] as String;
    }
    return null;
  }
}