import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/app_theme.dart';

void main() {
  test('AppColors success color is defined correctly', () {
    expect(AppColors.success, const Color(0xFF4ADE80));
  });
}
