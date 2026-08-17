// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $LastCastedDeviceTableTable extends LastCastedDeviceTable
    with TableInfo<$LastCastedDeviceTableTable, LastCastedDeviceTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LastCastedDeviceTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deviceNameMeta = const VerificationMeta(
    'deviceName',
  );
  @override
  late final GeneratedColumn<String> deviceName = GeneratedColumn<String>(
    'device_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _protocolMeta = const VerificationMeta(
    'protocol',
  );
  @override
  late final GeneratedColumn<String> protocol = GeneratedColumn<String>(
    'protocol',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastCastAtMeta = const VerificationMeta(
    'lastCastAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastCastAt = GeneratedColumn<DateTime>(
    'last_cast_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    deviceId,
    deviceName,
    protocol,
    lastCastAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'last_casted_device';
  @override
  VerificationContext validateIntegrity(
    Insertable<LastCastedDeviceTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('device_name')) {
      context.handle(
        _deviceNameMeta,
        deviceName.isAcceptableOrUnknown(data['device_name']!, _deviceNameMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceNameMeta);
    }
    if (data.containsKey('protocol')) {
      context.handle(
        _protocolMeta,
        protocol.isAcceptableOrUnknown(data['protocol']!, _protocolMeta),
      );
    } else if (isInserting) {
      context.missing(_protocolMeta);
    }
    if (data.containsKey('last_cast_at')) {
      context.handle(
        _lastCastAtMeta,
        lastCastAt.isAcceptableOrUnknown(
          data['last_cast_at']!,
          _lastCastAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastCastAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {deviceId};
  @override
  LastCastedDeviceTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LastCastedDeviceTableData(
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      deviceName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_name'],
      )!,
      protocol: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}protocol'],
      )!,
      lastCastAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_cast_at'],
      )!,
    );
  }

  @override
  $LastCastedDeviceTableTable createAlias(String alias) {
    return $LastCastedDeviceTableTable(attachedDatabase, alias);
  }
}

class LastCastedDeviceTableData extends DataClass
    implements Insertable<LastCastedDeviceTableData> {
  final String deviceId;
  final String deviceName;
  final String protocol;
  final DateTime lastCastAt;
  const LastCastedDeviceTableData({
    required this.deviceId,
    required this.deviceName,
    required this.protocol,
    required this.lastCastAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['device_id'] = Variable<String>(deviceId);
    map['device_name'] = Variable<String>(deviceName);
    map['protocol'] = Variable<String>(protocol);
    map['last_cast_at'] = Variable<DateTime>(lastCastAt);
    return map;
  }

  LastCastedDeviceTableCompanion toCompanion(bool nullToAbsent) {
    return LastCastedDeviceTableCompanion(
      deviceId: Value(deviceId),
      deviceName: Value(deviceName),
      protocol: Value(protocol),
      lastCastAt: Value(lastCastAt),
    );
  }

  factory LastCastedDeviceTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LastCastedDeviceTableData(
      deviceId: serializer.fromJson<String>(json['deviceId']),
      deviceName: serializer.fromJson<String>(json['deviceName']),
      protocol: serializer.fromJson<String>(json['protocol']),
      lastCastAt: serializer.fromJson<DateTime>(json['lastCastAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'deviceId': serializer.toJson<String>(deviceId),
      'deviceName': serializer.toJson<String>(deviceName),
      'protocol': serializer.toJson<String>(protocol),
      'lastCastAt': serializer.toJson<DateTime>(lastCastAt),
    };
  }

  LastCastedDeviceTableData copyWith({
    String? deviceId,
    String? deviceName,
    String? protocol,
    DateTime? lastCastAt,
  }) => LastCastedDeviceTableData(
    deviceId: deviceId ?? this.deviceId,
    deviceName: deviceName ?? this.deviceName,
    protocol: protocol ?? this.protocol,
    lastCastAt: lastCastAt ?? this.lastCastAt,
  );
  LastCastedDeviceTableData copyWithCompanion(
    LastCastedDeviceTableCompanion data,
  ) {
    return LastCastedDeviceTableData(
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      deviceName: data.deviceName.present
          ? data.deviceName.value
          : this.deviceName,
      protocol: data.protocol.present ? data.protocol.value : this.protocol,
      lastCastAt: data.lastCastAt.present
          ? data.lastCastAt.value
          : this.lastCastAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LastCastedDeviceTableData(')
          ..write('deviceId: $deviceId, ')
          ..write('deviceName: $deviceName, ')
          ..write('protocol: $protocol, ')
          ..write('lastCastAt: $lastCastAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(deviceId, deviceName, protocol, lastCastAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LastCastedDeviceTableData &&
          other.deviceId == this.deviceId &&
          other.deviceName == this.deviceName &&
          other.protocol == this.protocol &&
          other.lastCastAt == this.lastCastAt);
}

class LastCastedDeviceTableCompanion
    extends UpdateCompanion<LastCastedDeviceTableData> {
  final Value<String> deviceId;
  final Value<String> deviceName;
  final Value<String> protocol;
  final Value<DateTime> lastCastAt;
  final Value<int> rowid;
  const LastCastedDeviceTableCompanion({
    this.deviceId = const Value.absent(),
    this.deviceName = const Value.absent(),
    this.protocol = const Value.absent(),
    this.lastCastAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LastCastedDeviceTableCompanion.insert({
    required String deviceId,
    required String deviceName,
    required String protocol,
    required DateTime lastCastAt,
    this.rowid = const Value.absent(),
  }) : deviceId = Value(deviceId),
       deviceName = Value(deviceName),
       protocol = Value(protocol),
       lastCastAt = Value(lastCastAt);
  static Insertable<LastCastedDeviceTableData> custom({
    Expression<String>? deviceId,
    Expression<String>? deviceName,
    Expression<String>? protocol,
    Expression<DateTime>? lastCastAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (deviceId != null) 'device_id': deviceId,
      if (deviceName != null) 'device_name': deviceName,
      if (protocol != null) 'protocol': protocol,
      if (lastCastAt != null) 'last_cast_at': lastCastAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LastCastedDeviceTableCompanion copyWith({
    Value<String>? deviceId,
    Value<String>? deviceName,
    Value<String>? protocol,
    Value<DateTime>? lastCastAt,
    Value<int>? rowid,
  }) {
    return LastCastedDeviceTableCompanion(
      deviceId: deviceId ?? this.deviceId,
      deviceName: deviceName ?? this.deviceName,
      protocol: protocol ?? this.protocol,
      lastCastAt: lastCastAt ?? this.lastCastAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (deviceName.present) {
      map['device_name'] = Variable<String>(deviceName.value);
    }
    if (protocol.present) {
      map['protocol'] = Variable<String>(protocol.value);
    }
    if (lastCastAt.present) {
      map['last_cast_at'] = Variable<DateTime>(lastCastAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LastCastedDeviceTableCompanion(')
          ..write('deviceId: $deviceId, ')
          ..write('deviceName: $deviceName, ')
          ..write('protocol: $protocol, ')
          ..write('lastCastAt: $lastCastAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PlaybackQueueTableTable extends PlaybackQueueTable
    with TableInfo<$PlaybackQueueTableTable, PlaybackQueueTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlaybackQueueTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mediaUriMeta = const VerificationMeta(
    'mediaUri',
  );
  @override
  late final GeneratedColumn<String> mediaUri = GeneratedColumn<String>(
    'media_uri',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mediaTypeMeta = const VerificationMeta(
    'mediaType',
  );
  @override
  late final GeneratedColumn<String> mediaType = GeneratedColumn<String>(
    'media_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _thumbnailMeta = const VerificationMeta(
    'thumbnail',
  );
  @override
  late final GeneratedColumn<String> thumbnail = GeneratedColumn<String>(
    'thumbnail',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _durationMsMeta = const VerificationMeta(
    'durationMs',
  );
  @override
  late final GeneratedColumn<int> durationMs = GeneratedColumn<int>(
    'duration_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isLocalFileMeta = const VerificationMeta(
    'isLocalFile',
  );
  @override
  late final GeneratedColumn<bool> isLocalFile = GeneratedColumn<bool>(
    'is_local_file',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_local_file" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _queueOrderMeta = const VerificationMeta(
    'queueOrder',
  );
  @override
  late final GeneratedColumn<int> queueOrder = GeneratedColumn<int>(
    'queue_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    mediaUri,
    mediaType,
    title,
    thumbnail,
    durationMs,
    isLocalFile,
    queueOrder,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'playback_queue';
  @override
  VerificationContext validateIntegrity(
    Insertable<PlaybackQueueTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('media_uri')) {
      context.handle(
        _mediaUriMeta,
        mediaUri.isAcceptableOrUnknown(data['media_uri']!, _mediaUriMeta),
      );
    } else if (isInserting) {
      context.missing(_mediaUriMeta);
    }
    if (data.containsKey('media_type')) {
      context.handle(
        _mediaTypeMeta,
        mediaType.isAcceptableOrUnknown(data['media_type']!, _mediaTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_mediaTypeMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('thumbnail')) {
      context.handle(
        _thumbnailMeta,
        thumbnail.isAcceptableOrUnknown(data['thumbnail']!, _thumbnailMeta),
      );
    }
    if (data.containsKey('duration_ms')) {
      context.handle(
        _durationMsMeta,
        durationMs.isAcceptableOrUnknown(data['duration_ms']!, _durationMsMeta),
      );
    }
    if (data.containsKey('is_local_file')) {
      context.handle(
        _isLocalFileMeta,
        isLocalFile.isAcceptableOrUnknown(
          data['is_local_file']!,
          _isLocalFileMeta,
        ),
      );
    }
    if (data.containsKey('queue_order')) {
      context.handle(
        _queueOrderMeta,
        queueOrder.isAcceptableOrUnknown(data['queue_order']!, _queueOrderMeta),
      );
    } else if (isInserting) {
      context.missing(_queueOrderMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PlaybackQueueTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlaybackQueueTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      mediaUri: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}media_uri'],
      )!,
      mediaType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}media_type'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      thumbnail: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}thumbnail'],
      ),
      durationMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_ms'],
      ),
      isLocalFile: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_local_file'],
      )!,
      queueOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}queue_order'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $PlaybackQueueTableTable createAlias(String alias) {
    return $PlaybackQueueTableTable(attachedDatabase, alias);
  }
}

class PlaybackQueueTableData extends DataClass
    implements Insertable<PlaybackQueueTableData> {
  final String id;
  final String mediaUri;
  final String mediaType;
  final String title;
  final String? thumbnail;
  final int? durationMs;
  final bool isLocalFile;
  final int queueOrder;
  final DateTime createdAt;
  const PlaybackQueueTableData({
    required this.id,
    required this.mediaUri,
    required this.mediaType,
    required this.title,
    this.thumbnail,
    this.durationMs,
    required this.isLocalFile,
    required this.queueOrder,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['media_uri'] = Variable<String>(mediaUri);
    map['media_type'] = Variable<String>(mediaType);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || thumbnail != null) {
      map['thumbnail'] = Variable<String>(thumbnail);
    }
    if (!nullToAbsent || durationMs != null) {
      map['duration_ms'] = Variable<int>(durationMs);
    }
    map['is_local_file'] = Variable<bool>(isLocalFile);
    map['queue_order'] = Variable<int>(queueOrder);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  PlaybackQueueTableCompanion toCompanion(bool nullToAbsent) {
    return PlaybackQueueTableCompanion(
      id: Value(id),
      mediaUri: Value(mediaUri),
      mediaType: Value(mediaType),
      title: Value(title),
      thumbnail: thumbnail == null && nullToAbsent
          ? const Value.absent()
          : Value(thumbnail),
      durationMs: durationMs == null && nullToAbsent
          ? const Value.absent()
          : Value(durationMs),
      isLocalFile: Value(isLocalFile),
      queueOrder: Value(queueOrder),
      createdAt: Value(createdAt),
    );
  }

  factory PlaybackQueueTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlaybackQueueTableData(
      id: serializer.fromJson<String>(json['id']),
      mediaUri: serializer.fromJson<String>(json['mediaUri']),
      mediaType: serializer.fromJson<String>(json['mediaType']),
      title: serializer.fromJson<String>(json['title']),
      thumbnail: serializer.fromJson<String?>(json['thumbnail']),
      durationMs: serializer.fromJson<int?>(json['durationMs']),
      isLocalFile: serializer.fromJson<bool>(json['isLocalFile']),
      queueOrder: serializer.fromJson<int>(json['queueOrder']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'mediaUri': serializer.toJson<String>(mediaUri),
      'mediaType': serializer.toJson<String>(mediaType),
      'title': serializer.toJson<String>(title),
      'thumbnail': serializer.toJson<String?>(thumbnail),
      'durationMs': serializer.toJson<int?>(durationMs),
      'isLocalFile': serializer.toJson<bool>(isLocalFile),
      'queueOrder': serializer.toJson<int>(queueOrder),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  PlaybackQueueTableData copyWith({
    String? id,
    String? mediaUri,
    String? mediaType,
    String? title,
    Value<String?> thumbnail = const Value.absent(),
    Value<int?> durationMs = const Value.absent(),
    bool? isLocalFile,
    int? queueOrder,
    DateTime? createdAt,
  }) => PlaybackQueueTableData(
    id: id ?? this.id,
    mediaUri: mediaUri ?? this.mediaUri,
    mediaType: mediaType ?? this.mediaType,
    title: title ?? this.title,
    thumbnail: thumbnail.present ? thumbnail.value : this.thumbnail,
    durationMs: durationMs.present ? durationMs.value : this.durationMs,
    isLocalFile: isLocalFile ?? this.isLocalFile,
    queueOrder: queueOrder ?? this.queueOrder,
    createdAt: createdAt ?? this.createdAt,
  );
  PlaybackQueueTableData copyWithCompanion(PlaybackQueueTableCompanion data) {
    return PlaybackQueueTableData(
      id: data.id.present ? data.id.value : this.id,
      mediaUri: data.mediaUri.present ? data.mediaUri.value : this.mediaUri,
      mediaType: data.mediaType.present ? data.mediaType.value : this.mediaType,
      title: data.title.present ? data.title.value : this.title,
      thumbnail: data.thumbnail.present ? data.thumbnail.value : this.thumbnail,
      durationMs: data.durationMs.present
          ? data.durationMs.value
          : this.durationMs,
      isLocalFile: data.isLocalFile.present
          ? data.isLocalFile.value
          : this.isLocalFile,
      queueOrder: data.queueOrder.present
          ? data.queueOrder.value
          : this.queueOrder,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlaybackQueueTableData(')
          ..write('id: $id, ')
          ..write('mediaUri: $mediaUri, ')
          ..write('mediaType: $mediaType, ')
          ..write('title: $title, ')
          ..write('thumbnail: $thumbnail, ')
          ..write('durationMs: $durationMs, ')
          ..write('isLocalFile: $isLocalFile, ')
          ..write('queueOrder: $queueOrder, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    mediaUri,
    mediaType,
    title,
    thumbnail,
    durationMs,
    isLocalFile,
    queueOrder,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlaybackQueueTableData &&
          other.id == this.id &&
          other.mediaUri == this.mediaUri &&
          other.mediaType == this.mediaType &&
          other.title == this.title &&
          other.thumbnail == this.thumbnail &&
          other.durationMs == this.durationMs &&
          other.isLocalFile == this.isLocalFile &&
          other.queueOrder == this.queueOrder &&
          other.createdAt == this.createdAt);
}

class PlaybackQueueTableCompanion
    extends UpdateCompanion<PlaybackQueueTableData> {
  final Value<String> id;
  final Value<String> mediaUri;
  final Value<String> mediaType;
  final Value<String> title;
  final Value<String?> thumbnail;
  final Value<int?> durationMs;
  final Value<bool> isLocalFile;
  final Value<int> queueOrder;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const PlaybackQueueTableCompanion({
    this.id = const Value.absent(),
    this.mediaUri = const Value.absent(),
    this.mediaType = const Value.absent(),
    this.title = const Value.absent(),
    this.thumbnail = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.isLocalFile = const Value.absent(),
    this.queueOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PlaybackQueueTableCompanion.insert({
    required String id,
    required String mediaUri,
    required String mediaType,
    required String title,
    this.thumbnail = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.isLocalFile = const Value.absent(),
    required int queueOrder,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       mediaUri = Value(mediaUri),
       mediaType = Value(mediaType),
       title = Value(title),
       queueOrder = Value(queueOrder),
       createdAt = Value(createdAt);
  static Insertable<PlaybackQueueTableData> custom({
    Expression<String>? id,
    Expression<String>? mediaUri,
    Expression<String>? mediaType,
    Expression<String>? title,
    Expression<String>? thumbnail,
    Expression<int>? durationMs,
    Expression<bool>? isLocalFile,
    Expression<int>? queueOrder,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (mediaUri != null) 'media_uri': mediaUri,
      if (mediaType != null) 'media_type': mediaType,
      if (title != null) 'title': title,
      if (thumbnail != null) 'thumbnail': thumbnail,
      if (durationMs != null) 'duration_ms': durationMs,
      if (isLocalFile != null) 'is_local_file': isLocalFile,
      if (queueOrder != null) 'queue_order': queueOrder,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PlaybackQueueTableCompanion copyWith({
    Value<String>? id,
    Value<String>? mediaUri,
    Value<String>? mediaType,
    Value<String>? title,
    Value<String?>? thumbnail,
    Value<int?>? durationMs,
    Value<bool>? isLocalFile,
    Value<int>? queueOrder,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return PlaybackQueueTableCompanion(
      id: id ?? this.id,
      mediaUri: mediaUri ?? this.mediaUri,
      mediaType: mediaType ?? this.mediaType,
      title: title ?? this.title,
      thumbnail: thumbnail ?? this.thumbnail,
      durationMs: durationMs ?? this.durationMs,
      isLocalFile: isLocalFile ?? this.isLocalFile,
      queueOrder: queueOrder ?? this.queueOrder,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (mediaUri.present) {
      map['media_uri'] = Variable<String>(mediaUri.value);
    }
    if (mediaType.present) {
      map['media_type'] = Variable<String>(mediaType.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (thumbnail.present) {
      map['thumbnail'] = Variable<String>(thumbnail.value);
    }
    if (durationMs.present) {
      map['duration_ms'] = Variable<int>(durationMs.value);
    }
    if (isLocalFile.present) {
      map['is_local_file'] = Variable<bool>(isLocalFile.value);
    }
    if (queueOrder.present) {
      map['queue_order'] = Variable<int>(queueOrder.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlaybackQueueTableCompanion(')
          ..write('id: $id, ')
          ..write('mediaUri: $mediaUri, ')
          ..write('mediaType: $mediaType, ')
          ..write('title: $title, ')
          ..write('thumbnail: $thumbnail, ')
          ..write('durationMs: $durationMs, ')
          ..write('isLocalFile: $isLocalFile, ')
          ..write('queueOrder: $queueOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PlaybackHistoryTableTable extends PlaybackHistoryTable
    with TableInfo<$PlaybackHistoryTableTable, PlaybackHistoryTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlaybackHistoryTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mediaUriMeta = const VerificationMeta(
    'mediaUri',
  );
  @override
  late final GeneratedColumn<String> mediaUri = GeneratedColumn<String>(
    'media_uri',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mediaTypeMeta = const VerificationMeta(
    'mediaType',
  );
  @override
  late final GeneratedColumn<String> mediaType = GeneratedColumn<String>(
    'media_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isLocalFileMeta = const VerificationMeta(
    'isLocalFile',
  );
  @override
  late final GeneratedColumn<bool> isLocalFile = GeneratedColumn<bool>(
    'is_local_file',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_local_file" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _thumbnailUrlMeta = const VerificationMeta(
    'thumbnailUrl',
  );
  @override
  late final GeneratedColumn<String> thumbnailUrl = GeneratedColumn<String>(
    'thumbnail_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastPositionMsMeta = const VerificationMeta(
    'lastPositionMs',
  );
  @override
  late final GeneratedColumn<int> lastPositionMs = GeneratedColumn<int>(
    'last_position_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _totalDurationMsMeta = const VerificationMeta(
    'totalDurationMs',
  );
  @override
  late final GeneratedColumn<int> totalDurationMs = GeneratedColumn<int>(
    'total_duration_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastPlayedAtMeta = const VerificationMeta(
    'lastPlayedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastPlayedAt = GeneratedColumn<DateTime>(
    'last_played_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _completedMeta = const VerificationMeta(
    'completed',
  );
  @override
  late final GeneratedColumn<bool> completed = GeneratedColumn<bool>(
    'completed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("completed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    mediaUri,
    mediaType,
    isLocalFile,
    thumbnailUrl,
    lastPositionMs,
    totalDurationMs,
    lastPlayedAt,
    completed,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'playback_history';
  @override
  VerificationContext validateIntegrity(
    Insertable<PlaybackHistoryTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('media_uri')) {
      context.handle(
        _mediaUriMeta,
        mediaUri.isAcceptableOrUnknown(data['media_uri']!, _mediaUriMeta),
      );
    } else if (isInserting) {
      context.missing(_mediaUriMeta);
    }
    if (data.containsKey('media_type')) {
      context.handle(
        _mediaTypeMeta,
        mediaType.isAcceptableOrUnknown(data['media_type']!, _mediaTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_mediaTypeMeta);
    }
    if (data.containsKey('is_local_file')) {
      context.handle(
        _isLocalFileMeta,
        isLocalFile.isAcceptableOrUnknown(
          data['is_local_file']!,
          _isLocalFileMeta,
        ),
      );
    }
    if (data.containsKey('thumbnail_url')) {
      context.handle(
        _thumbnailUrlMeta,
        thumbnailUrl.isAcceptableOrUnknown(
          data['thumbnail_url']!,
          _thumbnailUrlMeta,
        ),
      );
    }
    if (data.containsKey('last_position_ms')) {
      context.handle(
        _lastPositionMsMeta,
        lastPositionMs.isAcceptableOrUnknown(
          data['last_position_ms']!,
          _lastPositionMsMeta,
        ),
      );
    }
    if (data.containsKey('total_duration_ms')) {
      context.handle(
        _totalDurationMsMeta,
        totalDurationMs.isAcceptableOrUnknown(
          data['total_duration_ms']!,
          _totalDurationMsMeta,
        ),
      );
    }
    if (data.containsKey('last_played_at')) {
      context.handle(
        _lastPlayedAtMeta,
        lastPlayedAt.isAcceptableOrUnknown(
          data['last_played_at']!,
          _lastPlayedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastPlayedAtMeta);
    }
    if (data.containsKey('completed')) {
      context.handle(
        _completedMeta,
        completed.isAcceptableOrUnknown(data['completed']!, _completedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PlaybackHistoryTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlaybackHistoryTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      mediaUri: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}media_uri'],
      )!,
      mediaType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}media_type'],
      )!,
      isLocalFile: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_local_file'],
      )!,
      thumbnailUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}thumbnail_url'],
      ),
      lastPositionMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_position_ms'],
      )!,
      totalDurationMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_duration_ms'],
      )!,
      lastPlayedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_played_at'],
      )!,
      completed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}completed'],
      )!,
    );
  }

  @override
  $PlaybackHistoryTableTable createAlias(String alias) {
    return $PlaybackHistoryTableTable(attachedDatabase, alias);
  }
}

class PlaybackHistoryTableData extends DataClass
    implements Insertable<PlaybackHistoryTableData> {
  final String id;
  final String title;
  final String mediaUri;
  final String mediaType;
  final bool isLocalFile;
  final String? thumbnailUrl;
  final int lastPositionMs;
  final int totalDurationMs;
  final DateTime lastPlayedAt;
  final bool completed;
  const PlaybackHistoryTableData({
    required this.id,
    required this.title,
    required this.mediaUri,
    required this.mediaType,
    required this.isLocalFile,
    this.thumbnailUrl,
    required this.lastPositionMs,
    required this.totalDurationMs,
    required this.lastPlayedAt,
    required this.completed,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    map['media_uri'] = Variable<String>(mediaUri);
    map['media_type'] = Variable<String>(mediaType);
    map['is_local_file'] = Variable<bool>(isLocalFile);
    if (!nullToAbsent || thumbnailUrl != null) {
      map['thumbnail_url'] = Variable<String>(thumbnailUrl);
    }
    map['last_position_ms'] = Variable<int>(lastPositionMs);
    map['total_duration_ms'] = Variable<int>(totalDurationMs);
    map['last_played_at'] = Variable<DateTime>(lastPlayedAt);
    map['completed'] = Variable<bool>(completed);
    return map;
  }

  PlaybackHistoryTableCompanion toCompanion(bool nullToAbsent) {
    return PlaybackHistoryTableCompanion(
      id: Value(id),
      title: Value(title),
      mediaUri: Value(mediaUri),
      mediaType: Value(mediaType),
      isLocalFile: Value(isLocalFile),
      thumbnailUrl: thumbnailUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(thumbnailUrl),
      lastPositionMs: Value(lastPositionMs),
      totalDurationMs: Value(totalDurationMs),
      lastPlayedAt: Value(lastPlayedAt),
      completed: Value(completed),
    );
  }

  factory PlaybackHistoryTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlaybackHistoryTableData(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      mediaUri: serializer.fromJson<String>(json['mediaUri']),
      mediaType: serializer.fromJson<String>(json['mediaType']),
      isLocalFile: serializer.fromJson<bool>(json['isLocalFile']),
      thumbnailUrl: serializer.fromJson<String?>(json['thumbnailUrl']),
      lastPositionMs: serializer.fromJson<int>(json['lastPositionMs']),
      totalDurationMs: serializer.fromJson<int>(json['totalDurationMs']),
      lastPlayedAt: serializer.fromJson<DateTime>(json['lastPlayedAt']),
      completed: serializer.fromJson<bool>(json['completed']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'mediaUri': serializer.toJson<String>(mediaUri),
      'mediaType': serializer.toJson<String>(mediaType),
      'isLocalFile': serializer.toJson<bool>(isLocalFile),
      'thumbnailUrl': serializer.toJson<String?>(thumbnailUrl),
      'lastPositionMs': serializer.toJson<int>(lastPositionMs),
      'totalDurationMs': serializer.toJson<int>(totalDurationMs),
      'lastPlayedAt': serializer.toJson<DateTime>(lastPlayedAt),
      'completed': serializer.toJson<bool>(completed),
    };
  }

  PlaybackHistoryTableData copyWith({
    String? id,
    String? title,
    String? mediaUri,
    String? mediaType,
    bool? isLocalFile,
    Value<String?> thumbnailUrl = const Value.absent(),
    int? lastPositionMs,
    int? totalDurationMs,
    DateTime? lastPlayedAt,
    bool? completed,
  }) => PlaybackHistoryTableData(
    id: id ?? this.id,
    title: title ?? this.title,
    mediaUri: mediaUri ?? this.mediaUri,
    mediaType: mediaType ?? this.mediaType,
    isLocalFile: isLocalFile ?? this.isLocalFile,
    thumbnailUrl: thumbnailUrl.present ? thumbnailUrl.value : this.thumbnailUrl,
    lastPositionMs: lastPositionMs ?? this.lastPositionMs,
    totalDurationMs: totalDurationMs ?? this.totalDurationMs,
    lastPlayedAt: lastPlayedAt ?? this.lastPlayedAt,
    completed: completed ?? this.completed,
  );
  PlaybackHistoryTableData copyWithCompanion(
    PlaybackHistoryTableCompanion data,
  ) {
    return PlaybackHistoryTableData(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      mediaUri: data.mediaUri.present ? data.mediaUri.value : this.mediaUri,
      mediaType: data.mediaType.present ? data.mediaType.value : this.mediaType,
      isLocalFile: data.isLocalFile.present
          ? data.isLocalFile.value
          : this.isLocalFile,
      thumbnailUrl: data.thumbnailUrl.present
          ? data.thumbnailUrl.value
          : this.thumbnailUrl,
      lastPositionMs: data.lastPositionMs.present
          ? data.lastPositionMs.value
          : this.lastPositionMs,
      totalDurationMs: data.totalDurationMs.present
          ? data.totalDurationMs.value
          : this.totalDurationMs,
      lastPlayedAt: data.lastPlayedAt.present
          ? data.lastPlayedAt.value
          : this.lastPlayedAt,
      completed: data.completed.present ? data.completed.value : this.completed,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlaybackHistoryTableData(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('mediaUri: $mediaUri, ')
          ..write('mediaType: $mediaType, ')
          ..write('isLocalFile: $isLocalFile, ')
          ..write('thumbnailUrl: $thumbnailUrl, ')
          ..write('lastPositionMs: $lastPositionMs, ')
          ..write('totalDurationMs: $totalDurationMs, ')
          ..write('lastPlayedAt: $lastPlayedAt, ')
          ..write('completed: $completed')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    mediaUri,
    mediaType,
    isLocalFile,
    thumbnailUrl,
    lastPositionMs,
    totalDurationMs,
    lastPlayedAt,
    completed,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlaybackHistoryTableData &&
          other.id == this.id &&
          other.title == this.title &&
          other.mediaUri == this.mediaUri &&
          other.mediaType == this.mediaType &&
          other.isLocalFile == this.isLocalFile &&
          other.thumbnailUrl == this.thumbnailUrl &&
          other.lastPositionMs == this.lastPositionMs &&
          other.totalDurationMs == this.totalDurationMs &&
          other.lastPlayedAt == this.lastPlayedAt &&
          other.completed == this.completed);
}

class PlaybackHistoryTableCompanion
    extends UpdateCompanion<PlaybackHistoryTableData> {
  final Value<String> id;
  final Value<String> title;
  final Value<String> mediaUri;
  final Value<String> mediaType;
  final Value<bool> isLocalFile;
  final Value<String?> thumbnailUrl;
  final Value<int> lastPositionMs;
  final Value<int> totalDurationMs;
  final Value<DateTime> lastPlayedAt;
  final Value<bool> completed;
  final Value<int> rowid;
  const PlaybackHistoryTableCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.mediaUri = const Value.absent(),
    this.mediaType = const Value.absent(),
    this.isLocalFile = const Value.absent(),
    this.thumbnailUrl = const Value.absent(),
    this.lastPositionMs = const Value.absent(),
    this.totalDurationMs = const Value.absent(),
    this.lastPlayedAt = const Value.absent(),
    this.completed = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PlaybackHistoryTableCompanion.insert({
    required String id,
    required String title,
    required String mediaUri,
    required String mediaType,
    this.isLocalFile = const Value.absent(),
    this.thumbnailUrl = const Value.absent(),
    this.lastPositionMs = const Value.absent(),
    this.totalDurationMs = const Value.absent(),
    required DateTime lastPlayedAt,
    this.completed = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       mediaUri = Value(mediaUri),
       mediaType = Value(mediaType),
       lastPlayedAt = Value(lastPlayedAt);
  static Insertable<PlaybackHistoryTableData> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? mediaUri,
    Expression<String>? mediaType,
    Expression<bool>? isLocalFile,
    Expression<String>? thumbnailUrl,
    Expression<int>? lastPositionMs,
    Expression<int>? totalDurationMs,
    Expression<DateTime>? lastPlayedAt,
    Expression<bool>? completed,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (mediaUri != null) 'media_uri': mediaUri,
      if (mediaType != null) 'media_type': mediaType,
      if (isLocalFile != null) 'is_local_file': isLocalFile,
      if (thumbnailUrl != null) 'thumbnail_url': thumbnailUrl,
      if (lastPositionMs != null) 'last_position_ms': lastPositionMs,
      if (totalDurationMs != null) 'total_duration_ms': totalDurationMs,
      if (lastPlayedAt != null) 'last_played_at': lastPlayedAt,
      if (completed != null) 'completed': completed,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PlaybackHistoryTableCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<String>? mediaUri,
    Value<String>? mediaType,
    Value<bool>? isLocalFile,
    Value<String?>? thumbnailUrl,
    Value<int>? lastPositionMs,
    Value<int>? totalDurationMs,
    Value<DateTime>? lastPlayedAt,
    Value<bool>? completed,
    Value<int>? rowid,
  }) {
    return PlaybackHistoryTableCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      mediaUri: mediaUri ?? this.mediaUri,
      mediaType: mediaType ?? this.mediaType,
      isLocalFile: isLocalFile ?? this.isLocalFile,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      lastPositionMs: lastPositionMs ?? this.lastPositionMs,
      totalDurationMs: totalDurationMs ?? this.totalDurationMs,
      lastPlayedAt: lastPlayedAt ?? this.lastPlayedAt,
      completed: completed ?? this.completed,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (mediaUri.present) {
      map['media_uri'] = Variable<String>(mediaUri.value);
    }
    if (mediaType.present) {
      map['media_type'] = Variable<String>(mediaType.value);
    }
    if (isLocalFile.present) {
      map['is_local_file'] = Variable<bool>(isLocalFile.value);
    }
    if (thumbnailUrl.present) {
      map['thumbnail_url'] = Variable<String>(thumbnailUrl.value);
    }
    if (lastPositionMs.present) {
      map['last_position_ms'] = Variable<int>(lastPositionMs.value);
    }
    if (totalDurationMs.present) {
      map['total_duration_ms'] = Variable<int>(totalDurationMs.value);
    }
    if (lastPlayedAt.present) {
      map['last_played_at'] = Variable<DateTime>(lastPlayedAt.value);
    }
    if (completed.present) {
      map['completed'] = Variable<bool>(completed.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlaybackHistoryTableCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('mediaUri: $mediaUri, ')
          ..write('mediaType: $mediaType, ')
          ..write('isLocalFile: $isLocalFile, ')
          ..write('thumbnailUrl: $thumbnailUrl, ')
          ..write('lastPositionMs: $lastPositionMs, ')
          ..write('totalDurationMs: $totalDurationMs, ')
          ..write('lastPlayedAt: $lastPlayedAt, ')
          ..write('completed: $completed, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UserPreferencesTableTable extends UserPreferencesTable
    with TableInfo<$UserPreferencesTableTable, UserPreferencesTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserPreferencesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _preferredAudioLanguageMeta =
      const VerificationMeta('preferredAudioLanguage');
  @override
  late final GeneratedColumn<String> preferredAudioLanguage =
      GeneratedColumn<String>(
        'preferred_audio_language',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('en'),
      );
  static const VerificationMeta _preferredSubtitleLanguageMeta =
      const VerificationMeta('preferredSubtitleLanguage');
  @override
  late final GeneratedColumn<String> preferredSubtitleLanguage =
      GeneratedColumn<String>(
        'preferred_subtitle_language',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('en'),
      );
  static const VerificationMeta _autoPlayNextMeta = const VerificationMeta(
    'autoPlayNext',
  );
  @override
  late final GeneratedColumn<bool> autoPlayNext = GeneratedColumn<bool>(
    'auto_play_next',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("auto_play_next" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    preferredAudioLanguage,
    preferredSubtitleLanguage,
    autoPlayNext,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_preferences';
  @override
  VerificationContext validateIntegrity(
    Insertable<UserPreferencesTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('preferred_audio_language')) {
      context.handle(
        _preferredAudioLanguageMeta,
        preferredAudioLanguage.isAcceptableOrUnknown(
          data['preferred_audio_language']!,
          _preferredAudioLanguageMeta,
        ),
      );
    }
    if (data.containsKey('preferred_subtitle_language')) {
      context.handle(
        _preferredSubtitleLanguageMeta,
        preferredSubtitleLanguage.isAcceptableOrUnknown(
          data['preferred_subtitle_language']!,
          _preferredSubtitleLanguageMeta,
        ),
      );
    }
    if (data.containsKey('auto_play_next')) {
      context.handle(
        _autoPlayNextMeta,
        autoPlayNext.isAcceptableOrUnknown(
          data['auto_play_next']!,
          _autoPlayNextMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UserPreferencesTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserPreferencesTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      preferredAudioLanguage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}preferred_audio_language'],
      )!,
      preferredSubtitleLanguage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}preferred_subtitle_language'],
      )!,
      autoPlayNext: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}auto_play_next'],
      )!,
    );
  }

  @override
  $UserPreferencesTableTable createAlias(String alias) {
    return $UserPreferencesTableTable(attachedDatabase, alias);
  }
}

class UserPreferencesTableData extends DataClass
    implements Insertable<UserPreferencesTableData> {
  final int id;
  final String preferredAudioLanguage;
  final String preferredSubtitleLanguage;
  final bool autoPlayNext;
  const UserPreferencesTableData({
    required this.id,
    required this.preferredAudioLanguage,
    required this.preferredSubtitleLanguage,
    required this.autoPlayNext,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['preferred_audio_language'] = Variable<String>(preferredAudioLanguage);
    map['preferred_subtitle_language'] = Variable<String>(
      preferredSubtitleLanguage,
    );
    map['auto_play_next'] = Variable<bool>(autoPlayNext);
    return map;
  }

  UserPreferencesTableCompanion toCompanion(bool nullToAbsent) {
    return UserPreferencesTableCompanion(
      id: Value(id),
      preferredAudioLanguage: Value(preferredAudioLanguage),
      preferredSubtitleLanguage: Value(preferredSubtitleLanguage),
      autoPlayNext: Value(autoPlayNext),
    );
  }

  factory UserPreferencesTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserPreferencesTableData(
      id: serializer.fromJson<int>(json['id']),
      preferredAudioLanguage: serializer.fromJson<String>(
        json['preferredAudioLanguage'],
      ),
      preferredSubtitleLanguage: serializer.fromJson<String>(
        json['preferredSubtitleLanguage'],
      ),
      autoPlayNext: serializer.fromJson<bool>(json['autoPlayNext']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'preferredAudioLanguage': serializer.toJson<String>(
        preferredAudioLanguage,
      ),
      'preferredSubtitleLanguage': serializer.toJson<String>(
        preferredSubtitleLanguage,
      ),
      'autoPlayNext': serializer.toJson<bool>(autoPlayNext),
    };
  }

  UserPreferencesTableData copyWith({
    int? id,
    String? preferredAudioLanguage,
    String? preferredSubtitleLanguage,
    bool? autoPlayNext,
  }) => UserPreferencesTableData(
    id: id ?? this.id,
    preferredAudioLanguage:
        preferredAudioLanguage ?? this.preferredAudioLanguage,
    preferredSubtitleLanguage:
        preferredSubtitleLanguage ?? this.preferredSubtitleLanguage,
    autoPlayNext: autoPlayNext ?? this.autoPlayNext,
  );
  UserPreferencesTableData copyWithCompanion(
    UserPreferencesTableCompanion data,
  ) {
    return UserPreferencesTableData(
      id: data.id.present ? data.id.value : this.id,
      preferredAudioLanguage: data.preferredAudioLanguage.present
          ? data.preferredAudioLanguage.value
          : this.preferredAudioLanguage,
      preferredSubtitleLanguage: data.preferredSubtitleLanguage.present
          ? data.preferredSubtitleLanguage.value
          : this.preferredSubtitleLanguage,
      autoPlayNext: data.autoPlayNext.present
          ? data.autoPlayNext.value
          : this.autoPlayNext,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserPreferencesTableData(')
          ..write('id: $id, ')
          ..write('preferredAudioLanguage: $preferredAudioLanguage, ')
          ..write('preferredSubtitleLanguage: $preferredSubtitleLanguage, ')
          ..write('autoPlayNext: $autoPlayNext')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    preferredAudioLanguage,
    preferredSubtitleLanguage,
    autoPlayNext,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserPreferencesTableData &&
          other.id == this.id &&
          other.preferredAudioLanguage == this.preferredAudioLanguage &&
          other.preferredSubtitleLanguage == this.preferredSubtitleLanguage &&
          other.autoPlayNext == this.autoPlayNext);
}

class UserPreferencesTableCompanion
    extends UpdateCompanion<UserPreferencesTableData> {
  final Value<int> id;
  final Value<String> preferredAudioLanguage;
  final Value<String> preferredSubtitleLanguage;
  final Value<bool> autoPlayNext;
  const UserPreferencesTableCompanion({
    this.id = const Value.absent(),
    this.preferredAudioLanguage = const Value.absent(),
    this.preferredSubtitleLanguage = const Value.absent(),
    this.autoPlayNext = const Value.absent(),
  });
  UserPreferencesTableCompanion.insert({
    this.id = const Value.absent(),
    this.preferredAudioLanguage = const Value.absent(),
    this.preferredSubtitleLanguage = const Value.absent(),
    this.autoPlayNext = const Value.absent(),
  });
  static Insertable<UserPreferencesTableData> custom({
    Expression<int>? id,
    Expression<String>? preferredAudioLanguage,
    Expression<String>? preferredSubtitleLanguage,
    Expression<bool>? autoPlayNext,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (preferredAudioLanguage != null)
        'preferred_audio_language': preferredAudioLanguage,
      if (preferredSubtitleLanguage != null)
        'preferred_subtitle_language': preferredSubtitleLanguage,
      if (autoPlayNext != null) 'auto_play_next': autoPlayNext,
    });
  }

  UserPreferencesTableCompanion copyWith({
    Value<int>? id,
    Value<String>? preferredAudioLanguage,
    Value<String>? preferredSubtitleLanguage,
    Value<bool>? autoPlayNext,
  }) {
    return UserPreferencesTableCompanion(
      id: id ?? this.id,
      preferredAudioLanguage:
          preferredAudioLanguage ?? this.preferredAudioLanguage,
      preferredSubtitleLanguage:
          preferredSubtitleLanguage ?? this.preferredSubtitleLanguage,
      autoPlayNext: autoPlayNext ?? this.autoPlayNext,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (preferredAudioLanguage.present) {
      map['preferred_audio_language'] = Variable<String>(
        preferredAudioLanguage.value,
      );
    }
    if (preferredSubtitleLanguage.present) {
      map['preferred_subtitle_language'] = Variable<String>(
        preferredSubtitleLanguage.value,
      );
    }
    if (autoPlayNext.present) {
      map['auto_play_next'] = Variable<bool>(autoPlayNext.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserPreferencesTableCompanion(')
          ..write('id: $id, ')
          ..write('preferredAudioLanguage: $preferredAudioLanguage, ')
          ..write('preferredSubtitleLanguage: $preferredSubtitleLanguage, ')
          ..write('autoPlayNext: $autoPlayNext')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $LastCastedDeviceTableTable lastCastedDeviceTable =
      $LastCastedDeviceTableTable(this);
  late final $PlaybackQueueTableTable playbackQueueTable =
      $PlaybackQueueTableTable(this);
  late final $PlaybackHistoryTableTable playbackHistoryTable =
      $PlaybackHistoryTableTable(this);
  late final $UserPreferencesTableTable userPreferencesTable =
      $UserPreferencesTableTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    lastCastedDeviceTable,
    playbackQueueTable,
    playbackHistoryTable,
    userPreferencesTable,
  ];
}

typedef $$LastCastedDeviceTableTableCreateCompanionBuilder =
    LastCastedDeviceTableCompanion Function({
      required String deviceId,
      required String deviceName,
      required String protocol,
      required DateTime lastCastAt,
      Value<int> rowid,
    });
typedef $$LastCastedDeviceTableTableUpdateCompanionBuilder =
    LastCastedDeviceTableCompanion Function({
      Value<String> deviceId,
      Value<String> deviceName,
      Value<String> protocol,
      Value<DateTime> lastCastAt,
      Value<int> rowid,
    });

class $$LastCastedDeviceTableTableFilterComposer
    extends Composer<_$AppDatabase, $LastCastedDeviceTableTable> {
  $$LastCastedDeviceTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceName => $composableBuilder(
    column: $table.deviceName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get protocol => $composableBuilder(
    column: $table.protocol,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastCastAt => $composableBuilder(
    column: $table.lastCastAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LastCastedDeviceTableTableOrderingComposer
    extends Composer<_$AppDatabase, $LastCastedDeviceTableTable> {
  $$LastCastedDeviceTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceName => $composableBuilder(
    column: $table.deviceName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get protocol => $composableBuilder(
    column: $table.protocol,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastCastAt => $composableBuilder(
    column: $table.lastCastAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LastCastedDeviceTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $LastCastedDeviceTableTable> {
  $$LastCastedDeviceTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<String> get deviceName => $composableBuilder(
    column: $table.deviceName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get protocol =>
      $composableBuilder(column: $table.protocol, builder: (column) => column);

  GeneratedColumn<DateTime> get lastCastAt => $composableBuilder(
    column: $table.lastCastAt,
    builder: (column) => column,
  );
}

class $$LastCastedDeviceTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LastCastedDeviceTableTable,
          LastCastedDeviceTableData,
          $$LastCastedDeviceTableTableFilterComposer,
          $$LastCastedDeviceTableTableOrderingComposer,
          $$LastCastedDeviceTableTableAnnotationComposer,
          $$LastCastedDeviceTableTableCreateCompanionBuilder,
          $$LastCastedDeviceTableTableUpdateCompanionBuilder,
          (
            LastCastedDeviceTableData,
            BaseReferences<
              _$AppDatabase,
              $LastCastedDeviceTableTable,
              LastCastedDeviceTableData
            >,
          ),
          LastCastedDeviceTableData,
          PrefetchHooks Function()
        > {
  $$LastCastedDeviceTableTableTableManager(
    _$AppDatabase db,
    $LastCastedDeviceTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LastCastedDeviceTableTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$LastCastedDeviceTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$LastCastedDeviceTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> deviceId = const Value.absent(),
                Value<String> deviceName = const Value.absent(),
                Value<String> protocol = const Value.absent(),
                Value<DateTime> lastCastAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LastCastedDeviceTableCompanion(
                deviceId: deviceId,
                deviceName: deviceName,
                protocol: protocol,
                lastCastAt: lastCastAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String deviceId,
                required String deviceName,
                required String protocol,
                required DateTime lastCastAt,
                Value<int> rowid = const Value.absent(),
              }) => LastCastedDeviceTableCompanion.insert(
                deviceId: deviceId,
                deviceName: deviceName,
                protocol: protocol,
                lastCastAt: lastCastAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LastCastedDeviceTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LastCastedDeviceTableTable,
      LastCastedDeviceTableData,
      $$LastCastedDeviceTableTableFilterComposer,
      $$LastCastedDeviceTableTableOrderingComposer,
      $$LastCastedDeviceTableTableAnnotationComposer,
      $$LastCastedDeviceTableTableCreateCompanionBuilder,
      $$LastCastedDeviceTableTableUpdateCompanionBuilder,
      (
        LastCastedDeviceTableData,
        BaseReferences<
          _$AppDatabase,
          $LastCastedDeviceTableTable,
          LastCastedDeviceTableData
        >,
      ),
      LastCastedDeviceTableData,
      PrefetchHooks Function()
    >;
typedef $$PlaybackQueueTableTableCreateCompanionBuilder =
    PlaybackQueueTableCompanion Function({
      required String id,
      required String mediaUri,
      required String mediaType,
      required String title,
      Value<String?> thumbnail,
      Value<int?> durationMs,
      Value<bool> isLocalFile,
      required int queueOrder,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$PlaybackQueueTableTableUpdateCompanionBuilder =
    PlaybackQueueTableCompanion Function({
      Value<String> id,
      Value<String> mediaUri,
      Value<String> mediaType,
      Value<String> title,
      Value<String?> thumbnail,
      Value<int?> durationMs,
      Value<bool> isLocalFile,
      Value<int> queueOrder,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$PlaybackQueueTableTableFilterComposer
    extends Composer<_$AppDatabase, $PlaybackQueueTableTable> {
  $$PlaybackQueueTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mediaUri => $composableBuilder(
    column: $table.mediaUri,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mediaType => $composableBuilder(
    column: $table.mediaType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get thumbnail => $composableBuilder(
    column: $table.thumbnail,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isLocalFile => $composableBuilder(
    column: $table.isLocalFile,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get queueOrder => $composableBuilder(
    column: $table.queueOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PlaybackQueueTableTableOrderingComposer
    extends Composer<_$AppDatabase, $PlaybackQueueTableTable> {
  $$PlaybackQueueTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mediaUri => $composableBuilder(
    column: $table.mediaUri,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mediaType => $composableBuilder(
    column: $table.mediaType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get thumbnail => $composableBuilder(
    column: $table.thumbnail,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isLocalFile => $composableBuilder(
    column: $table.isLocalFile,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get queueOrder => $composableBuilder(
    column: $table.queueOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PlaybackQueueTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlaybackQueueTableTable> {
  $$PlaybackQueueTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get mediaUri =>
      $composableBuilder(column: $table.mediaUri, builder: (column) => column);

  GeneratedColumn<String> get mediaType =>
      $composableBuilder(column: $table.mediaType, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get thumbnail =>
      $composableBuilder(column: $table.thumbnail, builder: (column) => column);

  GeneratedColumn<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isLocalFile => $composableBuilder(
    column: $table.isLocalFile,
    builder: (column) => column,
  );

  GeneratedColumn<int> get queueOrder => $composableBuilder(
    column: $table.queueOrder,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$PlaybackQueueTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PlaybackQueueTableTable,
          PlaybackQueueTableData,
          $$PlaybackQueueTableTableFilterComposer,
          $$PlaybackQueueTableTableOrderingComposer,
          $$PlaybackQueueTableTableAnnotationComposer,
          $$PlaybackQueueTableTableCreateCompanionBuilder,
          $$PlaybackQueueTableTableUpdateCompanionBuilder,
          (
            PlaybackQueueTableData,
            BaseReferences<
              _$AppDatabase,
              $PlaybackQueueTableTable,
              PlaybackQueueTableData
            >,
          ),
          PlaybackQueueTableData,
          PrefetchHooks Function()
        > {
  $$PlaybackQueueTableTableTableManager(
    _$AppDatabase db,
    $PlaybackQueueTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlaybackQueueTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlaybackQueueTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlaybackQueueTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> mediaUri = const Value.absent(),
                Value<String> mediaType = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> thumbnail = const Value.absent(),
                Value<int?> durationMs = const Value.absent(),
                Value<bool> isLocalFile = const Value.absent(),
                Value<int> queueOrder = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlaybackQueueTableCompanion(
                id: id,
                mediaUri: mediaUri,
                mediaType: mediaType,
                title: title,
                thumbnail: thumbnail,
                durationMs: durationMs,
                isLocalFile: isLocalFile,
                queueOrder: queueOrder,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String mediaUri,
                required String mediaType,
                required String title,
                Value<String?> thumbnail = const Value.absent(),
                Value<int?> durationMs = const Value.absent(),
                Value<bool> isLocalFile = const Value.absent(),
                required int queueOrder,
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => PlaybackQueueTableCompanion.insert(
                id: id,
                mediaUri: mediaUri,
                mediaType: mediaType,
                title: title,
                thumbnail: thumbnail,
                durationMs: durationMs,
                isLocalFile: isLocalFile,
                queueOrder: queueOrder,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PlaybackQueueTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PlaybackQueueTableTable,
      PlaybackQueueTableData,
      $$PlaybackQueueTableTableFilterComposer,
      $$PlaybackQueueTableTableOrderingComposer,
      $$PlaybackQueueTableTableAnnotationComposer,
      $$PlaybackQueueTableTableCreateCompanionBuilder,
      $$PlaybackQueueTableTableUpdateCompanionBuilder,
      (
        PlaybackQueueTableData,
        BaseReferences<
          _$AppDatabase,
          $PlaybackQueueTableTable,
          PlaybackQueueTableData
        >,
      ),
      PlaybackQueueTableData,
      PrefetchHooks Function()
    >;
typedef $$PlaybackHistoryTableTableCreateCompanionBuilder =
    PlaybackHistoryTableCompanion Function({
      required String id,
      required String title,
      required String mediaUri,
      required String mediaType,
      Value<bool> isLocalFile,
      Value<String?> thumbnailUrl,
      Value<int> lastPositionMs,
      Value<int> totalDurationMs,
      required DateTime lastPlayedAt,
      Value<bool> completed,
      Value<int> rowid,
    });
typedef $$PlaybackHistoryTableTableUpdateCompanionBuilder =
    PlaybackHistoryTableCompanion Function({
      Value<String> id,
      Value<String> title,
      Value<String> mediaUri,
      Value<String> mediaType,
      Value<bool> isLocalFile,
      Value<String?> thumbnailUrl,
      Value<int> lastPositionMs,
      Value<int> totalDurationMs,
      Value<DateTime> lastPlayedAt,
      Value<bool> completed,
      Value<int> rowid,
    });

class $$PlaybackHistoryTableTableFilterComposer
    extends Composer<_$AppDatabase, $PlaybackHistoryTableTable> {
  $$PlaybackHistoryTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mediaUri => $composableBuilder(
    column: $table.mediaUri,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mediaType => $composableBuilder(
    column: $table.mediaType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isLocalFile => $composableBuilder(
    column: $table.isLocalFile,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get thumbnailUrl => $composableBuilder(
    column: $table.thumbnailUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastPositionMs => $composableBuilder(
    column: $table.lastPositionMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalDurationMs => $composableBuilder(
    column: $table.totalDurationMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastPlayedAt => $composableBuilder(
    column: $table.lastPlayedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get completed => $composableBuilder(
    column: $table.completed,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PlaybackHistoryTableTableOrderingComposer
    extends Composer<_$AppDatabase, $PlaybackHistoryTableTable> {
  $$PlaybackHistoryTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mediaUri => $composableBuilder(
    column: $table.mediaUri,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mediaType => $composableBuilder(
    column: $table.mediaType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isLocalFile => $composableBuilder(
    column: $table.isLocalFile,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get thumbnailUrl => $composableBuilder(
    column: $table.thumbnailUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastPositionMs => $composableBuilder(
    column: $table.lastPositionMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalDurationMs => $composableBuilder(
    column: $table.totalDurationMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastPlayedAt => $composableBuilder(
    column: $table.lastPlayedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get completed => $composableBuilder(
    column: $table.completed,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PlaybackHistoryTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlaybackHistoryTableTable> {
  $$PlaybackHistoryTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get mediaUri =>
      $composableBuilder(column: $table.mediaUri, builder: (column) => column);

  GeneratedColumn<String> get mediaType =>
      $composableBuilder(column: $table.mediaType, builder: (column) => column);

  GeneratedColumn<bool> get isLocalFile => $composableBuilder(
    column: $table.isLocalFile,
    builder: (column) => column,
  );

  GeneratedColumn<String> get thumbnailUrl => $composableBuilder(
    column: $table.thumbnailUrl,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastPositionMs => $composableBuilder(
    column: $table.lastPositionMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totalDurationMs => $composableBuilder(
    column: $table.totalDurationMs,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastPlayedAt => $composableBuilder(
    column: $table.lastPlayedAt,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get completed =>
      $composableBuilder(column: $table.completed, builder: (column) => column);
}

class $$PlaybackHistoryTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PlaybackHistoryTableTable,
          PlaybackHistoryTableData,
          $$PlaybackHistoryTableTableFilterComposer,
          $$PlaybackHistoryTableTableOrderingComposer,
          $$PlaybackHistoryTableTableAnnotationComposer,
          $$PlaybackHistoryTableTableCreateCompanionBuilder,
          $$PlaybackHistoryTableTableUpdateCompanionBuilder,
          (
            PlaybackHistoryTableData,
            BaseReferences<
              _$AppDatabase,
              $PlaybackHistoryTableTable,
              PlaybackHistoryTableData
            >,
          ),
          PlaybackHistoryTableData,
          PrefetchHooks Function()
        > {
  $$PlaybackHistoryTableTableTableManager(
    _$AppDatabase db,
    $PlaybackHistoryTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlaybackHistoryTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlaybackHistoryTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$PlaybackHistoryTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> mediaUri = const Value.absent(),
                Value<String> mediaType = const Value.absent(),
                Value<bool> isLocalFile = const Value.absent(),
                Value<String?> thumbnailUrl = const Value.absent(),
                Value<int> lastPositionMs = const Value.absent(),
                Value<int> totalDurationMs = const Value.absent(),
                Value<DateTime> lastPlayedAt = const Value.absent(),
                Value<bool> completed = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlaybackHistoryTableCompanion(
                id: id,
                title: title,
                mediaUri: mediaUri,
                mediaType: mediaType,
                isLocalFile: isLocalFile,
                thumbnailUrl: thumbnailUrl,
                lastPositionMs: lastPositionMs,
                totalDurationMs: totalDurationMs,
                lastPlayedAt: lastPlayedAt,
                completed: completed,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String title,
                required String mediaUri,
                required String mediaType,
                Value<bool> isLocalFile = const Value.absent(),
                Value<String?> thumbnailUrl = const Value.absent(),
                Value<int> lastPositionMs = const Value.absent(),
                Value<int> totalDurationMs = const Value.absent(),
                required DateTime lastPlayedAt,
                Value<bool> completed = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlaybackHistoryTableCompanion.insert(
                id: id,
                title: title,
                mediaUri: mediaUri,
                mediaType: mediaType,
                isLocalFile: isLocalFile,
                thumbnailUrl: thumbnailUrl,
                lastPositionMs: lastPositionMs,
                totalDurationMs: totalDurationMs,
                lastPlayedAt: lastPlayedAt,
                completed: completed,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PlaybackHistoryTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PlaybackHistoryTableTable,
      PlaybackHistoryTableData,
      $$PlaybackHistoryTableTableFilterComposer,
      $$PlaybackHistoryTableTableOrderingComposer,
      $$PlaybackHistoryTableTableAnnotationComposer,
      $$PlaybackHistoryTableTableCreateCompanionBuilder,
      $$PlaybackHistoryTableTableUpdateCompanionBuilder,
      (
        PlaybackHistoryTableData,
        BaseReferences<
          _$AppDatabase,
          $PlaybackHistoryTableTable,
          PlaybackHistoryTableData
        >,
      ),
      PlaybackHistoryTableData,
      PrefetchHooks Function()
    >;
typedef $$UserPreferencesTableTableCreateCompanionBuilder =
    UserPreferencesTableCompanion Function({
      Value<int> id,
      Value<String> preferredAudioLanguage,
      Value<String> preferredSubtitleLanguage,
      Value<bool> autoPlayNext,
    });
typedef $$UserPreferencesTableTableUpdateCompanionBuilder =
    UserPreferencesTableCompanion Function({
      Value<int> id,
      Value<String> preferredAudioLanguage,
      Value<String> preferredSubtitleLanguage,
      Value<bool> autoPlayNext,
    });

class $$UserPreferencesTableTableFilterComposer
    extends Composer<_$AppDatabase, $UserPreferencesTableTable> {
  $$UserPreferencesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get preferredAudioLanguage => $composableBuilder(
    column: $table.preferredAudioLanguage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get preferredSubtitleLanguage => $composableBuilder(
    column: $table.preferredSubtitleLanguage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get autoPlayNext => $composableBuilder(
    column: $table.autoPlayNext,
    builder: (column) => ColumnFilters(column),
  );
}

class $$UserPreferencesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $UserPreferencesTableTable> {
  $$UserPreferencesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get preferredAudioLanguage => $composableBuilder(
    column: $table.preferredAudioLanguage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get preferredSubtitleLanguage => $composableBuilder(
    column: $table.preferredSubtitleLanguage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get autoPlayNext => $composableBuilder(
    column: $table.autoPlayNext,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UserPreferencesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $UserPreferencesTableTable> {
  $$UserPreferencesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get preferredAudioLanguage => $composableBuilder(
    column: $table.preferredAudioLanguage,
    builder: (column) => column,
  );

  GeneratedColumn<String> get preferredSubtitleLanguage => $composableBuilder(
    column: $table.preferredSubtitleLanguage,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get autoPlayNext => $composableBuilder(
    column: $table.autoPlayNext,
    builder: (column) => column,
  );
}

class $$UserPreferencesTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UserPreferencesTableTable,
          UserPreferencesTableData,
          $$UserPreferencesTableTableFilterComposer,
          $$UserPreferencesTableTableOrderingComposer,
          $$UserPreferencesTableTableAnnotationComposer,
          $$UserPreferencesTableTableCreateCompanionBuilder,
          $$UserPreferencesTableTableUpdateCompanionBuilder,
          (
            UserPreferencesTableData,
            BaseReferences<
              _$AppDatabase,
              $UserPreferencesTableTable,
              UserPreferencesTableData
            >,
          ),
          UserPreferencesTableData,
          PrefetchHooks Function()
        > {
  $$UserPreferencesTableTableTableManager(
    _$AppDatabase db,
    $UserPreferencesTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserPreferencesTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UserPreferencesTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$UserPreferencesTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> preferredAudioLanguage = const Value.absent(),
                Value<String> preferredSubtitleLanguage = const Value.absent(),
                Value<bool> autoPlayNext = const Value.absent(),
              }) => UserPreferencesTableCompanion(
                id: id,
                preferredAudioLanguage: preferredAudioLanguage,
                preferredSubtitleLanguage: preferredSubtitleLanguage,
                autoPlayNext: autoPlayNext,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> preferredAudioLanguage = const Value.absent(),
                Value<String> preferredSubtitleLanguage = const Value.absent(),
                Value<bool> autoPlayNext = const Value.absent(),
              }) => UserPreferencesTableCompanion.insert(
                id: id,
                preferredAudioLanguage: preferredAudioLanguage,
                preferredSubtitleLanguage: preferredSubtitleLanguage,
                autoPlayNext: autoPlayNext,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UserPreferencesTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UserPreferencesTableTable,
      UserPreferencesTableData,
      $$UserPreferencesTableTableFilterComposer,
      $$UserPreferencesTableTableOrderingComposer,
      $$UserPreferencesTableTableAnnotationComposer,
      $$UserPreferencesTableTableCreateCompanionBuilder,
      $$UserPreferencesTableTableUpdateCompanionBuilder,
      (
        UserPreferencesTableData,
        BaseReferences<
          _$AppDatabase,
          $UserPreferencesTableTable,
          UserPreferencesTableData
        >,
      ),
      UserPreferencesTableData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$LastCastedDeviceTableTableTableManager get lastCastedDeviceTable =>
      $$LastCastedDeviceTableTableTableManager(_db, _db.lastCastedDeviceTable);
  $$PlaybackQueueTableTableTableManager get playbackQueueTable =>
      $$PlaybackQueueTableTableTableManager(_db, _db.playbackQueueTable);
  $$PlaybackHistoryTableTableTableManager get playbackHistoryTable =>
      $$PlaybackHistoryTableTableTableManager(_db, _db.playbackHistoryTable);
  $$UserPreferencesTableTableTableManager get userPreferencesTable =>
      $$UserPreferencesTableTableTableManager(_db, _db.userPreferencesTable);
}
