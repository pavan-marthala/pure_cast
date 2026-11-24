import 'package:dart_cast/src/core/hls_master_playlist.dart';
import 'package:test/test.dart';

void main() {
  group('HlsMasterPlaylistWriter', () {
    test('writes a variant with no renditions', () {
      final playlist = HlsMasterPlaylistWriter.build(videoUri: 'video.m3u8');
      expect(playlist, startsWith('#EXTM3U\n'));
      expect(playlist, contains('#EXT-X-STREAM-INF:BANDWIDTH=5000000'));
      expect(playlist.trimRight(), endsWith('video.m3u8'));
      expect(playlist, isNot(contains('EXT-X-MEDIA')));
    });

    test('writes an audio rendition group with a default', () {
      final playlist = HlsMasterPlaylistWriter.build(
        videoUri: 'video.m3u8',
        audio: const [
          HlsAudioRendition(
            name: 'English',
            language: 'en',
            uri: 'audio_0.m3u8',
            isDefault: true,
          ),
          HlsAudioRendition(
            name: 'Spanish',
            language: 'es',
            uri: 'audio_1.m3u8',
            channels: 6,
          ),
        ],
      );
      expect(
        playlist,
        contains(
          '#EXT-X-MEDIA:TYPE=AUDIO,GROUP-ID="aud",NAME="English",'
          'DEFAULT=YES,AUTOSELECT=YES,LANGUAGE="en",CHANNELS="2",'
          'URI="audio_0.m3u8"',
        ),
      );
      expect(
        playlist,
        contains(
          '#EXT-X-MEDIA:TYPE=AUDIO,GROUP-ID="aud",NAME="Spanish",'
          'DEFAULT=NO,AUTOSELECT=NO,LANGUAGE="es",CHANNELS="6",'
          'URI="audio_1.m3u8"',
        ),
      );
      expect(playlist, contains('AUDIO="aud"'));
      expect(playlist, isNot(contains('SUBTITLES=')));
    });

    test('writes a subtitle rendition group and links the variant', () {
      final playlist = HlsMasterPlaylistWriter.build(
        videoUri: 'video.m3u8',
        subtitles: const [
          HlsSubtitleRendition(
            name: 'English',
            language: 'en',
            uri: 'sub_0.m3u8',
            isDefault: true,
          ),
        ],
      );
      expect(
        playlist,
        contains(
          '#EXT-X-MEDIA:TYPE=SUBTITLES,GROUP-ID="subs",NAME="English",'
          'DEFAULT=YES,AUTOSELECT=YES,LANGUAGE="en",URI="sub_0.m3u8"',
        ),
      );
      expect(playlist, contains('SUBTITLES="subs"'));
    });

    test('escapes quotes in names', () {
      final playlist = HlsMasterPlaylistWriter.build(
        videoUri: 'video.m3u8',
        audio: const [
          HlsAudioRendition(name: 'English "CC"', uri: 'audio_0.m3u8'),
        ],
      );
      expect(playlist, contains('NAME="English \\"CC\\""'));
    });
  });
}
