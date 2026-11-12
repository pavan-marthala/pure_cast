import 'package:flutter_test/flutter_test.dart';
import 'package:pure_cast/core/features/casting/data/repository/dart_cast_adapter.dart';
import 'package:pure_cast/core/features/casting/data/model/pure_cast_models.dart';
import 'package:dart_cast/dart_cast.dart' as dart_cast;

void main() {
  group('DartCastAdapter.shouldFallbackToDirect', () {
    test('ProbeFailedException falls back', () {
      final e = dart_cast.ProbeFailedException('Probe failed');
      expect(DartCastAdapter.shouldFallbackToDirect(e), isTrue);
    });

    test('UnsupportedMediaException does not fall back', () {
      final e = dart_cast.UnsupportedMediaException('Unsupported');
      expect(DartCastAdapter.shouldFallbackToDirect(e), isFalse);
    });

    test('PrepareFailedException does not fall back', () {
      final e = dart_cast.PrepareFailedException('Prepare failed');
      expect(DartCastAdapter.shouldFallbackToDirect(e), isFalse);
    });

    test('MediaLoadFailedException does not fall back', () {
      final e = dart_cast.MediaLoadFailedException('LOAD_FAILED');
      expect(DartCastAdapter.shouldFallbackToDirect(e), isFalse);
    });

    test('wrapped PureCastException with originalError=ProbeFailedException falls back', () {
      final inner = dart_cast.ProbeFailedException('Probe failed');
      final wrapped = PureCastException('Failed to load local file', inner);
      expect(DartCastAdapter.shouldFallbackToDirect(wrapped), isTrue);
    });

    test('wrapped PureCastException with originalError=UnsupportedMediaException does not fall back', () {
      final inner = dart_cast.UnsupportedMediaException('Unsupported');
      final wrapped = PureCastException('Failed to load local file', inner);
      expect(DartCastAdapter.shouldFallbackToDirect(wrapped), isFalse);
    });

    test('generic exception does not fall back', () {
      expect(DartCastAdapter.shouldFallbackToDirect(Exception('network error')), isFalse);
    });
  });
}
