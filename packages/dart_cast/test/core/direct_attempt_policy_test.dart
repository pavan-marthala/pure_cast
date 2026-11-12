import 'package:dart_cast/src/core/cast_exceptions.dart';
import 'package:dart_cast/src/core/direct_attempt_policy.dart';
import 'package:test/test.dart';

void main() {
  group('DirectAttemptPolicy', () {
    test('LOAD_FAILED + HEVC + no subtitle + direct -> record', () {
      expect(
        DirectAttemptPolicy.shouldRecordDirectFailed(
          isMediaLoadFailed: true,
          codec: 'hevc',
          hasSubtitle: false,
          isDirectAttempt: true,
        ),
        isTrue,
      );
    });

    test('LOAD_FAILED + VP9 + no subtitle + direct -> record', () {
      expect(
        DirectAttemptPolicy.shouldRecordDirectFailed(
          isMediaLoadFailed: true,
          codec: 'vp9',
          hasSubtitle: false,
          isDirectAttempt: true,
        ),
        isTrue,
      );
    });

    test('LOAD_FAILED + HEVC + subtitle attached -> do not record', () {
      expect(
        DirectAttemptPolicy.shouldRecordDirectFailed(
          isMediaLoadFailed: true,
          codec: 'hevc',
          hasSubtitle: true,
          isDirectAttempt: true,
        ),
        isFalse,
      );
    });

    test('LOAD_FAILED + H.264 -> never record', () {
      expect(
        DirectAttemptPolicy.shouldRecordDirectFailed(
          isMediaLoadFailed: true,
          codec: 'h264',
          hasSubtitle: false,
          isDirectAttempt: true,
        ),
        isFalse,
      );
    });

    test('LOAD_FAILED + AV1 -> never record', () {
      expect(
        DirectAttemptPolicy.shouldRecordDirectFailed(
          isMediaLoadFailed: true,
          codec: 'av1',
          hasSubtitle: false,
          isDirectAttempt: true,
        ),
        isFalse,
      );
    });

    test('network error (not MediaLoadFailed) -> do not record', () {
      expect(
        DirectAttemptPolicy.shouldRecordDirectFailed(
          isMediaLoadFailed: false,
          codec: 'hevc',
          hasSubtitle: false,
          isDirectAttempt: true,
        ),
        isFalse,
      );
    });

    test('not a direct attempt -> do not record', () {
      expect(
        DirectAttemptPolicy.shouldRecordDirectFailed(
          isMediaLoadFailed: true,
          codec: 'hevc',
          hasSubtitle: false,
          isDirectAttempt: false,
        ),
        isFalse,
      );
    });

    test('MediaLoadFailedException type check', () {
      final ex = MediaLoadFailedException('Receiver returned LOAD_FAILED');
      expect(ex is MediaLoadFailedException, isTrue);
      expect(
        DirectAttemptPolicy.shouldRecordDirectFailed(
          isMediaLoadFailed: ex is MediaLoadFailedException,
          codec: 'vp9',
          hasSubtitle: false,
          isDirectAttempt: true,
        ),
        isTrue,
      );
    });
  });
}
