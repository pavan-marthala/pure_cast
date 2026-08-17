// import 'dart:async';
// import 'package:flutter_test/flutter_test.dart';
// import 'package:pure_cast/core/database/app_database.dart';
// import 'package:pure_cast/core/features/casting/data/data_source/i_cast_service.dart';
// import 'package:pure_cast/core/features/casting/data/model/pure_cast_models.dart';
// import 'package:pure_cast/core/features/casting/data/repository/playback_history_repository.dart';
// import 'package:pure_cast/core/features/casting/presentation/logic/coordinator/playback_coordinator.dart';
// import 'package:pure_cast/core/features/casting/presentation/logic/queue/queue_bloc.dart';
// import 'package:pure_cast/core/features/casting/presentation/logic/session/cast_session_bloc.dart';
//
// class FakeCastService implements ICastService {
//   final StreamController<List<PureCastDevice>> discoveryController =
//       StreamController<List<PureCastDevice>>.broadcast();
//   final StreamController<PureCastSessionState> sessionStateController =
//       StreamController<PureCastSessionState>.broadcast();
//   final StreamController<Duration> positionController =
//       StreamController<Duration>.broadcast();
//   final StreamController<Duration> durationController =
//       StreamController<Duration>.broadcast();
//
//   bool connectCalled = false;
//   PureCastDevice? connectDeviceTarget;
//   bool shouldConnectFail = false;
//   bool disconnectCalled = false;
//   PureCastMedia? loadedMedia;
//
//   @override
//   Stream<List<PureCastDevice>> discoverDevices({Set<PureCastProtocol>? protocols}) {
//     return discoveryController.stream;
//   }
//
//   @override
//   Future<void> stopDiscovery() async {}
//
//   @override
//   Future<void> connect(PureCastDevice device) async {
//     connectCalled = true;
//     connectDeviceTarget = device;
//     if (shouldConnectFail) {
//       throw const PureCastException('Network connection failed');
//     }
//   }
//
//   @override
//   Future<void> disconnect() async {
//     disconnectCalled = true;
//   }
//
//   @override
//   Future<void> loadMedia(PureCastMedia media) async {
//     loadedMedia = media;
//     sessionStateController.add(PureCastSessionState.playing);
//   }
//
//   @override
//   Future<void> play() async {}
//
//   @override
//   Future<void> pause() async {}
//
//   @override
//   Future<void> stop() async {}
//
//   @override
//   Future<void> seek(Duration position) async {}
//
//   @override
//   Future<void> setVolume(double volume) async {}
//
//   @override
//   Stream<PureCastSessionState> get sessionStateStream => sessionStateController.stream;
//
//   @override
//   Stream<Duration> get positionStream => positionController.stream;
//
//   @override
//   Stream<Duration> get durationStream => durationController.stream;
//
//   @override
//   PureCastDevice? currentDevice;
//
//   @override
//   PureCastSessionState currentState = PureCastSessionState.disconnected;
//
//   @override
//   Future<void> dispose() async {
//     await discoveryController.close();
//     await sessionStateController.close();
//     await positionController.close();
//     await durationController.close();
//   }
// }
//
// class FakeAppDatabase implements AppDatabase {
//   String? lastDeviceId;
//   String? lastDeviceName;
//   String? lastProtocol;
//
//   List<PlaybackQueueTableData> queueData = [];
//   PlaybackHistoryTableData? mostRecentHistory;
//   PlaybackHistoryTableCompanion? recordedHistoryCompanion;
//   UserPreferencesTableData preferencesData = const UserPreferencesTableData(
//     id: 1,
//     preferredAudioLanguage: 'en',
//     preferredSubtitleLanguage: 'en',
//     autoPlayNext: true,
//   );
//
//   @override
//   Future<LastCastedDeviceTableData?> getLastCastedDevice() async {
//     if (lastDeviceId == null) return null;
//     return LastCastedDeviceTableData(
//       deviceId: lastDeviceId!,
//       deviceName: lastDeviceName!,
//       protocol: lastProtocol!,
//       lastCastAt: DateTime.now(),
//     );
//   }
//
//   @override
//   Future<int> setLastCastedDevice({
//     required String deviceId,
//     required String deviceName,
//     required String protocol,
//   }) async {
//     lastDeviceId = deviceId;
//     lastDeviceName = deviceName;
//     lastProtocol = protocol;
//     return 1;
//   }
//
//   @override
//   Future<List<PlaybackQueueTableData>> getQueue() async => queueData;
//
//   @override
//   Future<void> saveQueue(List<PlaybackQueueTableCompanion> items) async {
//     queueData = items.map((i) => PlaybackQueueTableData(
//       id: i.id.value,
//       mediaUri: i.mediaUri.value,
//       mediaType: i.mediaType.value,
//       title: i.title.value,
//       thumbnail: i.thumbnail.value,
//       durationMs: i.durationMs.value,
//       isLocalFile: i.isLocalFile.value,
//       queueOrder: i.queueOrder.value,
//       createdAt: i.createdAt.value,
//     )).toList();
//   }
//
//   @override
//   Future<void> clearQueue() async {
//     queueData.clear();
//   }
//
//   @override
//   Future<PlaybackHistoryTableData?> getMostRecentHistory() async => mostRecentHistory;
//
//   @override
//   Future<void> recordPlaybackHistory(PlaybackHistoryTableCompanion entry) async {
//     recordedHistoryCompanion = entry;
//   }
//
//   @override
//   Future<UserPreferencesTableData> getPreferences() async => preferencesData;
//
//   @override
//   dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
// }
//
// void main() {
//   late FakeCastService fakeCastService;
//   late FakeAppDatabase fakeDb;
//   late PlaybackHistoryRepository historyRepo;
//
//   setUp(() {
//     fakeCastService = FakeCastService();
//     fakeDb = FakeAppDatabase();
//     historyRepo = PlaybackHistoryRepository(fakeDb);
//   });
//
//   tearDown(() async {
//     await fakeCastService.dispose();
//   });
//
//   group('PlaybackCoordinator Unit & Orchestration Tests', () {
//     test('1. Empty queue does not trigger media load', () async {
//       final queueBloc = QueueBloc(fakeDb);
//       final sessionBloc = CastSessionBloc(fakeCastService, historyRepo);
//       final coordinator = PlaybackCoordinator(historyRepo);
//
//       coordinator.start(queueBloc, sessionBloc);
//       await pumpEventQueue();
//
//       expect(sessionBloc.state.activeMedia, isNull);
//       expect(fakeCastService.loadedMedia, isNull);
//
//       await coordinator.dispose();
//       await queueBloc.close();
//       await sessionBloc.close();
//     });
//
//     test('2. First item added to empty queue triggers LoadMediaEvent on CastSessionBloc', () async {
//       final queueBloc = QueueBloc(fakeDb);
//       final sessionBloc = CastSessionBloc(fakeCastService, historyRepo);
//       final coordinator = PlaybackCoordinator(historyRepo);
//
//       coordinator.start(queueBloc, sessionBloc);
//
//       const media = PureCastMedia(
//         uri: 'http://example.com/video1.mp4',
//         type: PureCastMediaType.mp4,
//         title: 'Video 1',
//       );
//
//       queueBloc.add(const AddToQueueEvent(media));
//       await pumpEventQueue();
//
//       expect(sessionBloc.state.activeMedia, equals(media));
//
//       await coordinator.dispose();
//       await queueBloc.close();
//       await sessionBloc.close();
//     });
//
//     test('3. Appending media while playing does not interrupt current playback', () async {
//       final queueBloc = QueueBloc(fakeDb);
//       final sessionBloc = CastSessionBloc(fakeCastService, historyRepo);
//       final coordinator = PlaybackCoordinator(historyRepo);
//
//       coordinator.start(queueBloc, sessionBloc);
//
//       const media1 = PureCastMedia(
//         uri: 'http://example.com/video1.mp4',
//         type: PureCastMediaType.mp4,
//         title: 'Video 1',
//       );
//       const media2 = PureCastMedia(
//         uri: 'http://example.com/video2.mp4',
//         type: PureCastMediaType.mp4,
//         title: 'Video 2',
//       );
//
//       queueBloc.add(const AddToQueueEvent(media1));
//       await pumpEventQueue();
//       expect(sessionBloc.state.activeMedia, equals(media1));
//
//       queueBloc.add(const AddToQueueEvent(media2));
//       await pumpEventQueue();
//
//       expect(sessionBloc.state.activeMedia, equals(media1));
//
//       await coordinator.dispose();
//       await queueBloc.close();
//       await sessionBloc.close();
//     });
//
//     test('4. Completion advances to next queue item when autoPlayNext is true', () async {
//       final queueBloc = QueueBloc(fakeDb);
//       final sessionBloc = CastSessionBloc(fakeCastService, historyRepo);
//       final coordinator = PlaybackCoordinator(historyRepo);
//
//       coordinator.start(queueBloc, sessionBloc);
//
//       const media1 = PureCastMedia(
//         uri: 'http://example.com/video1.mp4',
//         type: PureCastMediaType.mp4,
//         title: 'Video 1',
//       );
//       const media2 = PureCastMedia(
//         uri: 'http://example.com/video2.mp4',
//         type: PureCastMediaType.mp4,
//         title: 'Video 2',
//       );
//
//       queueBloc.add(const AddToQueueEvent(media1));
//       await pumpEventQueue();
//       queueBloc.add(const AddToQueueEvent(media2));
//       await pumpEventQueue();
//
//       fakeCastService.sessionStateController.add(PureCastSessionState.completed);
//       await pumpEventQueue();
//
//       expect(queueBloc.state.currentIndex, equals(1));
//       expect(sessionBloc.state.activeMedia, equals(media2));
//
//       await coordinator.dispose();
//       await queueBloc.close();
//       await sessionBloc.close();
//     });
//
//     test('5. Completion at end of queue stays completed', () async {
//       final queueBloc = QueueBloc(fakeDb);
//       final sessionBloc = CastSessionBloc(fakeCastService, historyRepo);
//       final coordinator = PlaybackCoordinator(historyRepo);
//
//       coordinator.start(queueBloc, sessionBloc);
//
//       const media1 = PureCastMedia(
//         uri: 'http://example.com/video1.mp4',
//         type: PureCastMediaType.mp4,
//         title: 'Video 1',
//       );
//
//       queueBloc.add(const AddToQueueEvent(media1));
//       await pumpEventQueue();
//
//       fakeCastService.sessionStateController.add(PureCastSessionState.completed);
//       await pumpEventQueue();
//
//       expect(queueBloc.state.currentIndex, equals(0));
//
//       await coordinator.dispose();
//       await queueBloc.close();
//       await sessionBloc.close();
//     });
//
//     test('6. Clearing queue while playing does not interrupt current active media', () async {
//       final queueBloc = QueueBloc(fakeDb);
//       final sessionBloc = CastSessionBloc(fakeCastService, historyRepo);
//       final coordinator = PlaybackCoordinator(historyRepo);
//
//       coordinator.start(queueBloc, sessionBloc);
//
//       const media1 = PureCastMedia(
//         uri: 'http://example.com/video1.mp4',
//         type: PureCastMediaType.mp4,
//         title: 'Video 1',
//       );
//
//       queueBloc.add(const AddToQueueEvent(media1));
//       await pumpEventQueue();
//
//       queueBloc.add(const ClearQueueEvent());
//       await pumpEventQueue();
//
//       expect(queueBloc.state.items, isEmpty);
//       expect(sessionBloc.state.activeMedia, equals(media1));
//
//       await coordinator.dispose();
//       await queueBloc.close();
//       await sessionBloc.close();
//     });
//
//     test('7. AutoPlayNext disabled halts playback on completion', () async {
//       fakeDb.preferencesData = const UserPreferencesTableData(
//         id: 1,
//         preferredAudioLanguage: 'en',
//         preferredSubtitleLanguage: 'en',
//         autoPlayNext: false,
//       );
//
//       final queueBloc = QueueBloc(fakeDb);
//       final sessionBloc = CastSessionBloc(fakeCastService, historyRepo);
//       final coordinator = PlaybackCoordinator(historyRepo);
//
//       coordinator.start(queueBloc, sessionBloc);
//
//       const media1 = PureCastMedia(
//         uri: 'http://example.com/video1.mp4',
//         type: PureCastMediaType.mp4,
//         title: 'Video 1',
//       );
//       const media2 = PureCastMedia(
//         uri: 'http://example.com/video2.mp4',
//         type: PureCastMediaType.mp4,
//         title: 'Video 2',
//       );
//
//       queueBloc.add(const AddToQueueEvent(media1));
//       await pumpEventQueue();
//       queueBloc.add(const AddToQueueEvent(media2));
//       await pumpEventQueue();
//
//       fakeCastService.sessionStateController.add(PureCastSessionState.completed);
//       await pumpEventQueue();
//
//       expect(queueBloc.state.currentIndex, equals(0));
//       expect(sessionBloc.state.activeMedia, equals(media1));
//
//       await coordinator.dispose();
//       await queueBloc.close();
//       await sessionBloc.close();
//     });
//
//     test('8. Duplicate completion events are guarded', () async {
//       final queueBloc = QueueBloc(fakeDb);
//       final sessionBloc = CastSessionBloc(fakeCastService, historyRepo);
//       final coordinator = PlaybackCoordinator(historyRepo);
//
//       coordinator.start(queueBloc, sessionBloc);
//
//       const media1 = PureCastMedia(
//         uri: 'http://example.com/video1.mp4',
//         type: PureCastMediaType.mp4,
//         title: 'Video 1',
//       );
//       const media2 = PureCastMedia(
//         uri: 'http://example.com/video2.mp4',
//         type: PureCastMediaType.mp4,
//         title: 'Video 2',
//       );
//
//       queueBloc.add(const AddToQueueEvent(media1));
//       await pumpEventQueue();
//       queueBloc.add(const AddToQueueEvent(media2));
//       await pumpEventQueue();
//
//       fakeCastService.sessionStateController.add(PureCastSessionState.completed);
//       fakeCastService.sessionStateController.add(PureCastSessionState.completed);
//       await pumpEventQueue();
//
//       expect(queueBloc.state.currentIndex, equals(1));
//
//       await coordinator.dispose();
//       await queueBloc.close();
//       await sessionBloc.close();
//     });
//   });
// }
