import 'package:flutter_test/flutter_test.dart';
import 'package:pure_cast/core/features/casting/data/model/pure_cast_models.dart';

void main() {
  group('PureCastDomainModels Test', () {
    test('PureCastCapabilities correctly differentiates protocols', () {
      final chromecastCaps = PureCastCapabilities.forProtocol(PureCastProtocol.chromecast);
      final dlnaCaps = PureCastCapabilities.forProtocol(PureCastProtocol.dlna);

      expect(chromecastCaps.canChangeAudioTrack, isTrue);
      expect(chromecastCaps.canChangeSubtitle, isTrue);
      expect(chromecastCaps.canQueue, isTrue);

      expect(dlnaCaps.canChangeAudioTrack, isFalse);
      expect(dlnaCaps.canChangeSubtitle, isFalse);
      expect(dlnaCaps.canQueue, isFalse);
    });

    test('PureCastDevice value equality', () {
      final dev1 = PureCastDevice(
        id: 'dev_123',
        name: 'Living Room TV',
        protocol: PureCastProtocol.chromecast,
        host: '192.168.1.50',
        port: 8009,
        capabilities: PureCastCapabilities.forProtocol(PureCastProtocol.chromecast),
      );

      final dev2 = PureCastDevice(
        id: 'dev_123',
        name: 'Living Room TV',
        protocol: PureCastProtocol.chromecast,
        host: '192.168.1.50',
        port: 8009,
        capabilities: PureCastCapabilities.forProtocol(PureCastProtocol.chromecast),
      );

      expect(dev1, equals(dev2));
    });

    test('PureCastMedia value equality', () {
      const media1 = PureCastMedia(
        uri: 'http://example.com/video.mp4',
        type: PureCastMediaType.mp4,
        title: 'Sample Video',
      );

      const media2 = PureCastMedia(
        uri: 'http://example.com/video.mp4',
        type: PureCastMediaType.mp4,
        title: 'Sample Video',
      );

      expect(media1, equals(media2));
    });
  });
}
