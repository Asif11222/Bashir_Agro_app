import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'farmer_app_state.dart';

/// A single remote configuration shared by admin screens and the farmer home.
/// If the server is unavailable, every screen keeps its existing artwork/text.
class AppAppearance {
  final Map<String, dynamic> branding;
  final Map<String, dynamic> headers;
  const AppAppearance(this.branding, this.headers);

  factory AppAppearance.fromJson(Map<String, dynamic> data) => AppAppearance(
        Map<String, dynamic>.from(data['branding'] is Map ? data['branding'] as Map : {}),
        Map<String, dynamic>.from(data['headers'] is Map ? data['headers'] as Map : {}),
      );

  HeaderStyle forScreen(String id) {
    final raw = headers[id];
    return HeaderStyle(raw is Map ? Map<String, dynamic>.from(raw) : const {});
  }
}

class HeaderStyle {
  final Map<String, dynamic> data;
  const HeaderStyle(this.data);

  String label(String key, String fallback) {
    final value = data[key];
    return value is String ? value : fallback;
  }

  String? get imageUrl {
    final image = data['image_url'];
    if (image is! String || image.isEmpty) return null;
    final uri = Uri.tryParse(image);
    return uri != null && (uri.scheme == 'https' || uri.scheme == 'http') ? image : null;
  }

  Color get titleColor {
    final hex = data['title_color']?.toString();
    if (hex == null || !RegExp(r'^#[0-9a-fA-F]{6}$').hasMatch(hex)) {
      return Colors.white;
    }
    return Color(int.parse(hex.substring(1), radix: 16) | 0xFF000000);
  }

  double get fontSize => ((data['font_size'] is num
          ? (data['font_size'] as num).toDouble()
          : 18.0)
      .clamp(16.0, 26.0)).toDouble();
  double get overlay => ((data['overlay'] is num
          ? (data['overlay'] as num).toDouble()
          : 0.35)
      .clamp(0.15, 0.7)).toDouble();
  bool get shadow => data['shadow'] != false;
  TextAlign get textAlign => switch (data['alignment']) {
        'left' => TextAlign.left,
        'right' => TextAlign.right,
        _ => TextAlign.center,
      };
  List<Shadow> get shadows => shadow
      ? const [Shadow(color: Colors.black54, offset: Offset(0, 1), blurRadius: 3)]
      : const [];
}

final appAppearanceProvider = FutureProvider<AppAppearance>((ref) async {
  final response = await ref.read(apiServiceProvider).client.get('/app-appearance');
  final data = response['data'];
  if (data is! Map<String, dynamic>) throw const FormatException('Invalid appearance response');
  return AppAppearance.fromJson(data);
});
