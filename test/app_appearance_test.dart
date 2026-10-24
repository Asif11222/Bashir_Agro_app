import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bashir_agro_app_2/state/app_appearance.dart';

void main() {
  test('remote appearance uses validated, bounded style settings', () {
    final app = AppAppearance.fromJson({
      'branding': {'name': 'Bashir Agro'},
      'headers': {
        'farmers_list': {
          'title': 'কৃষকের তালিকা',
          'title_color': '#FFAA22',
          'font_size': 24,
          'shadow': false,
          'overlay': 0.4,
          'alignment': 'right',
        },
      },
    });
    final style = app.forScreen('farmers_list');
    expect(style.label('title', 'fallback'), 'কৃষকের তালিকা');
    expect(style.fontSize, 24);
    expect(style.titleColor, const Color(0xFFFFAA22));
    expect(style.textAlign, TextAlign.right);
    expect(style.shadows, isEmpty);
    expect(app.forScreen('missing').label('title', 'fallback'), 'fallback');
  });
}
