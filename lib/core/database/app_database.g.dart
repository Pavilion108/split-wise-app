// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $TripsTable extends Trips with TableInfo<$TripsTable, TripRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TripsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _baseCurrencyMeta = const VerificationMeta(
    'baseCurrency',
  );
  @override
  late final GeneratedColumn<String> baseCurrency = GeneratedColumn<String>(
    'base_currency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('INR'),
  );
  static const VerificationMeta _inviteCodeMeta = const VerificationMeta(
    'inviteCode',
  );
  @override
  late final GeneratedColumn<String> inviteCode = GeneratedColumn<String>(
    'invite_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _deletedMeta = const VerificationMeta(
    'deleted',
  );
  @override
  late final GeneratedColumn<bool> deleted = GeneratedColumn<bool>(
    'deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
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
    name,
    baseCurrency,
    inviteCode,
    deleted,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'trips';
  @override
  VerificationContext validateIntegrity(
    Insertable<TripRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('base_currency')) {
      context.handle(
        _baseCurrencyMeta,
        baseCurrency.isAcceptableOrUnknown(
          data['base_currency']!,
          _baseCurrencyMeta,
        ),
      );
    }
    if (data.containsKey('invite_code')) {
      context.handle(
        _inviteCodeMeta,
        inviteCode.isAcceptableOrUnknown(data['invite_code']!, _inviteCodeMeta),
      );
    }
    if (data.containsKey('deleted')) {
      context.handle(
        _deletedMeta,
        deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta),
      );
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
  TripRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TripRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      baseCurrency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}base_currency'],
      )!,
      inviteCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}invite_code'],
      )!,
      deleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}deleted'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $TripsTable createAlias(String alias) {
    return $TripsTable(attachedDatabase, alias);
  }
}

class TripRow extends DataClass implements Insertable<TripRow> {
  final String id;
  final String name;
  final String baseCurrency;

  /// 6-char invite code for sharing via WhatsApp/Gmail.
  final String inviteCode;
  final bool deleted;
  final DateTime createdAt;
  const TripRow({
    required this.id,
    required this.name,
    required this.baseCurrency,
    required this.inviteCode,
    required this.deleted,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['base_currency'] = Variable<String>(baseCurrency);
    map['invite_code'] = Variable<String>(inviteCode);
    map['deleted'] = Variable<bool>(deleted);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  TripsCompanion toCompanion(bool nullToAbsent) {
    return TripsCompanion(
      id: Value(id),
      name: Value(name),
      baseCurrency: Value(baseCurrency),
      inviteCode: Value(inviteCode),
      deleted: Value(deleted),
      createdAt: Value(createdAt),
    );
  }

  factory TripRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TripRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      baseCurrency: serializer.fromJson<String>(json['baseCurrency']),
      inviteCode: serializer.fromJson<String>(json['inviteCode']),
      deleted: serializer.fromJson<bool>(json['deleted']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'baseCurrency': serializer.toJson<String>(baseCurrency),
      'inviteCode': serializer.toJson<String>(inviteCode),
      'deleted': serializer.toJson<bool>(deleted),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  TripRow copyWith({
    String? id,
    String? name,
    String? baseCurrency,
    String? inviteCode,
    bool? deleted,
    DateTime? createdAt,
  }) => TripRow(
    id: id ?? this.id,
    name: name ?? this.name,
    baseCurrency: baseCurrency ?? this.baseCurrency,
    inviteCode: inviteCode ?? this.inviteCode,
    deleted: deleted ?? this.deleted,
    createdAt: createdAt ?? this.createdAt,
  );
  TripRow copyWithCompanion(TripsCompanion data) {
    return TripRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      baseCurrency: data.baseCurrency.present
          ? data.baseCurrency.value
          : this.baseCurrency,
      inviteCode: data.inviteCode.present
          ? data.inviteCode.value
          : this.inviteCode,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TripRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('baseCurrency: $baseCurrency, ')
          ..write('inviteCode: $inviteCode, ')
          ..write('deleted: $deleted, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, baseCurrency, inviteCode, deleted, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TripRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.baseCurrency == this.baseCurrency &&
          other.inviteCode == this.inviteCode &&
          other.deleted == this.deleted &&
          other.createdAt == this.createdAt);
}

class TripsCompanion extends UpdateCompanion<TripRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> baseCurrency;
  final Value<String> inviteCode;
  final Value<bool> deleted;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const TripsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.baseCurrency = const Value.absent(),
    this.inviteCode = const Value.absent(),
    this.deleted = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TripsCompanion.insert({
    required String id,
    required String name,
    this.baseCurrency = const Value.absent(),
    this.inviteCode = const Value.absent(),
    this.deleted = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       createdAt = Value(createdAt);
  static Insertable<TripRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? baseCurrency,
    Expression<String>? inviteCode,
    Expression<bool>? deleted,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (baseCurrency != null) 'base_currency': baseCurrency,
      if (inviteCode != null) 'invite_code': inviteCode,
      if (deleted != null) 'deleted': deleted,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TripsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? baseCurrency,
    Value<String>? inviteCode,
    Value<bool>? deleted,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return TripsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      baseCurrency: baseCurrency ?? this.baseCurrency,
      inviteCode: inviteCode ?? this.inviteCode,
      deleted: deleted ?? this.deleted,
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
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (baseCurrency.present) {
      map['base_currency'] = Variable<String>(baseCurrency.value);
    }
    if (inviteCode.present) {
      map['invite_code'] = Variable<String>(inviteCode.value);
    }
    if (deleted.present) {
      map['deleted'] = Variable<bool>(deleted.value);
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
    return (StringBuffer('TripsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('baseCurrency: $baseCurrency, ')
          ..write('inviteCode: $inviteCode, ')
          ..write('deleted: $deleted, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MembersTable extends Members with TableInfo<$MembersTable, MemberRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MembersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tripIdMeta = const VerificationMeta('tripId');
  @override
  late final GeneratedColumn<String> tripId = GeneratedColumn<String>(
    'trip_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES trips (id)',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
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
  static const VerificationMeta _avatarColorMeta = const VerificationMeta(
    'avatarColor',
  );
  @override
  late final GeneratedColumn<int> avatarColor = GeneratedColumn<int>(
    'avatar_color',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0xFF1E88E5),
  );
  static const VerificationMeta _joinedAtMeta = const VerificationMeta(
    'joinedAt',
  );
  @override
  late final GeneratedColumn<DateTime> joinedAt = GeneratedColumn<DateTime>(
    'joined_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedMeta = const VerificationMeta(
    'deleted',
  );
  @override
  late final GeneratedColumn<bool> deleted = GeneratedColumn<bool>(
    'deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    tripId,
    name,
    deviceId,
    avatarColor,
    joinedAt,
    deleted,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'members';
  @override
  VerificationContext validateIntegrity(
    Insertable<MemberRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('trip_id')) {
      context.handle(
        _tripIdMeta,
        tripId.isAcceptableOrUnknown(data['trip_id']!, _tripIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tripIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('avatar_color')) {
      context.handle(
        _avatarColorMeta,
        avatarColor.isAcceptableOrUnknown(
          data['avatar_color']!,
          _avatarColorMeta,
        ),
      );
    }
    if (data.containsKey('joined_at')) {
      context.handle(
        _joinedAtMeta,
        joinedAt.isAcceptableOrUnknown(data['joined_at']!, _joinedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_joinedAtMeta);
    }
    if (data.containsKey('deleted')) {
      context.handle(
        _deletedMeta,
        deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MemberRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MemberRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      tripId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}trip_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      avatarColor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}avatar_color'],
      )!,
      joinedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}joined_at'],
      )!,
      deleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}deleted'],
      )!,
    );
  }

  @override
  $MembersTable createAlias(String alias) {
    return $MembersTable(attachedDatabase, alias);
  }
}

class MemberRow extends DataClass implements Insertable<MemberRow> {
  final String id;
  final String tripId;
  final String name;
  final String deviceId;
  final int avatarColor;
  final DateTime joinedAt;
  final bool deleted;
  const MemberRow({
    required this.id,
    required this.tripId,
    required this.name,
    required this.deviceId,
    required this.avatarColor,
    required this.joinedAt,
    required this.deleted,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['trip_id'] = Variable<String>(tripId);
    map['name'] = Variable<String>(name);
    map['device_id'] = Variable<String>(deviceId);
    map['avatar_color'] = Variable<int>(avatarColor);
    map['joined_at'] = Variable<DateTime>(joinedAt);
    map['deleted'] = Variable<bool>(deleted);
    return map;
  }

  MembersCompanion toCompanion(bool nullToAbsent) {
    return MembersCompanion(
      id: Value(id),
      tripId: Value(tripId),
      name: Value(name),
      deviceId: Value(deviceId),
      avatarColor: Value(avatarColor),
      joinedAt: Value(joinedAt),
      deleted: Value(deleted),
    );
  }

  factory MemberRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MemberRow(
      id: serializer.fromJson<String>(json['id']),
      tripId: serializer.fromJson<String>(json['tripId']),
      name: serializer.fromJson<String>(json['name']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      avatarColor: serializer.fromJson<int>(json['avatarColor']),
      joinedAt: serializer.fromJson<DateTime>(json['joinedAt']),
      deleted: serializer.fromJson<bool>(json['deleted']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'tripId': serializer.toJson<String>(tripId),
      'name': serializer.toJson<String>(name),
      'deviceId': serializer.toJson<String>(deviceId),
      'avatarColor': serializer.toJson<int>(avatarColor),
      'joinedAt': serializer.toJson<DateTime>(joinedAt),
      'deleted': serializer.toJson<bool>(deleted),
    };
  }

  MemberRow copyWith({
    String? id,
    String? tripId,
    String? name,
    String? deviceId,
    int? avatarColor,
    DateTime? joinedAt,
    bool? deleted,
  }) => MemberRow(
    id: id ?? this.id,
    tripId: tripId ?? this.tripId,
    name: name ?? this.name,
    deviceId: deviceId ?? this.deviceId,
    avatarColor: avatarColor ?? this.avatarColor,
    joinedAt: joinedAt ?? this.joinedAt,
    deleted: deleted ?? this.deleted,
  );
  MemberRow copyWithCompanion(MembersCompanion data) {
    return MemberRow(
      id: data.id.present ? data.id.value : this.id,
      tripId: data.tripId.present ? data.tripId.value : this.tripId,
      name: data.name.present ? data.name.value : this.name,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      avatarColor: data.avatarColor.present
          ? data.avatarColor.value
          : this.avatarColor,
      joinedAt: data.joinedAt.present ? data.joinedAt.value : this.joinedAt,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MemberRow(')
          ..write('id: $id, ')
          ..write('tripId: $tripId, ')
          ..write('name: $name, ')
          ..write('deviceId: $deviceId, ')
          ..write('avatarColor: $avatarColor, ')
          ..write('joinedAt: $joinedAt, ')
          ..write('deleted: $deleted')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, tripId, name, deviceId, avatarColor, joinedAt, deleted);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MemberRow &&
          other.id == this.id &&
          other.tripId == this.tripId &&
          other.name == this.name &&
          other.deviceId == this.deviceId &&
          other.avatarColor == this.avatarColor &&
          other.joinedAt == this.joinedAt &&
          other.deleted == this.deleted);
}

class MembersCompanion extends UpdateCompanion<MemberRow> {
  final Value<String> id;
  final Value<String> tripId;
  final Value<String> name;
  final Value<String> deviceId;
  final Value<int> avatarColor;
  final Value<DateTime> joinedAt;
  final Value<bool> deleted;
  final Value<int> rowid;
  const MembersCompanion({
    this.id = const Value.absent(),
    this.tripId = const Value.absent(),
    this.name = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.avatarColor = const Value.absent(),
    this.joinedAt = const Value.absent(),
    this.deleted = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MembersCompanion.insert({
    required String id,
    required String tripId,
    required String name,
    required String deviceId,
    this.avatarColor = const Value.absent(),
    required DateTime joinedAt,
    this.deleted = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       tripId = Value(tripId),
       name = Value(name),
       deviceId = Value(deviceId),
       joinedAt = Value(joinedAt);
  static Insertable<MemberRow> custom({
    Expression<String>? id,
    Expression<String>? tripId,
    Expression<String>? name,
    Expression<String>? deviceId,
    Expression<int>? avatarColor,
    Expression<DateTime>? joinedAt,
    Expression<bool>? deleted,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (tripId != null) 'trip_id': tripId,
      if (name != null) 'name': name,
      if (deviceId != null) 'device_id': deviceId,
      if (avatarColor != null) 'avatar_color': avatarColor,
      if (joinedAt != null) 'joined_at': joinedAt,
      if (deleted != null) 'deleted': deleted,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MembersCompanion copyWith({
    Value<String>? id,
    Value<String>? tripId,
    Value<String>? name,
    Value<String>? deviceId,
    Value<int>? avatarColor,
    Value<DateTime>? joinedAt,
    Value<bool>? deleted,
    Value<int>? rowid,
  }) {
    return MembersCompanion(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      name: name ?? this.name,
      deviceId: deviceId ?? this.deviceId,
      avatarColor: avatarColor ?? this.avatarColor,
      joinedAt: joinedAt ?? this.joinedAt,
      deleted: deleted ?? this.deleted,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (tripId.present) {
      map['trip_id'] = Variable<String>(tripId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (avatarColor.present) {
      map['avatar_color'] = Variable<int>(avatarColor.value);
    }
    if (joinedAt.present) {
      map['joined_at'] = Variable<DateTime>(joinedAt.value);
    }
    if (deleted.present) {
      map['deleted'] = Variable<bool>(deleted.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MembersCompanion(')
          ..write('id: $id, ')
          ..write('tripId: $tripId, ')
          ..write('name: $name, ')
          ..write('deviceId: $deviceId, ')
          ..write('avatarColor: $avatarColor, ')
          ..write('joinedAt: $joinedAt, ')
          ..write('deleted: $deleted, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CategoriesTable extends Categories
    with TableInfo<$CategoriesTable, CategoryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tripIdMeta = const VerificationMeta('tripId');
  @override
  late final GeneratedColumn<String> tripId = GeneratedColumn<String>(
    'trip_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES trips (id)',
    ),
  );
  static const VerificationMeta _isDefaultMeta = const VerificationMeta(
    'isDefault',
  );
  @override
  late final GeneratedColumn<bool> isDefault = GeneratedColumn<bool>(
    'is_default',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_default" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _deletedMeta = const VerificationMeta(
    'deleted',
  );
  @override
  late final GeneratedColumn<bool> deleted = GeneratedColumn<bool>(
    'deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, tripId, isDefault, deleted];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'categories';
  @override
  VerificationContext validateIntegrity(
    Insertable<CategoryRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('trip_id')) {
      context.handle(
        _tripIdMeta,
        tripId.isAcceptableOrUnknown(data['trip_id']!, _tripIdMeta),
      );
    }
    if (data.containsKey('is_default')) {
      context.handle(
        _isDefaultMeta,
        isDefault.isAcceptableOrUnknown(data['is_default']!, _isDefaultMeta),
      );
    }
    if (data.containsKey('deleted')) {
      context.handle(
        _deletedMeta,
        deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CategoryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CategoryRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      tripId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}trip_id'],
      ),
      isDefault: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_default'],
      )!,
      deleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}deleted'],
      )!,
    );
  }

  @override
  $CategoriesTable createAlias(String alias) {
    return $CategoriesTable(attachedDatabase, alias);
  }
}

class CategoryRow extends DataClass implements Insertable<CategoryRow> {
  final String id;
  final String name;
  final String? tripId;
  final bool isDefault;
  final bool deleted;
  const CategoryRow({
    required this.id,
    required this.name,
    this.tripId,
    required this.isDefault,
    required this.deleted,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || tripId != null) {
      map['trip_id'] = Variable<String>(tripId);
    }
    map['is_default'] = Variable<bool>(isDefault);
    map['deleted'] = Variable<bool>(deleted);
    return map;
  }

  CategoriesCompanion toCompanion(bool nullToAbsent) {
    return CategoriesCompanion(
      id: Value(id),
      name: Value(name),
      tripId: tripId == null && nullToAbsent
          ? const Value.absent()
          : Value(tripId),
      isDefault: Value(isDefault),
      deleted: Value(deleted),
    );
  }

  factory CategoryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CategoryRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      tripId: serializer.fromJson<String?>(json['tripId']),
      isDefault: serializer.fromJson<bool>(json['isDefault']),
      deleted: serializer.fromJson<bool>(json['deleted']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'tripId': serializer.toJson<String?>(tripId),
      'isDefault': serializer.toJson<bool>(isDefault),
      'deleted': serializer.toJson<bool>(deleted),
    };
  }

  CategoryRow copyWith({
    String? id,
    String? name,
    Value<String?> tripId = const Value.absent(),
    bool? isDefault,
    bool? deleted,
  }) => CategoryRow(
    id: id ?? this.id,
    name: name ?? this.name,
    tripId: tripId.present ? tripId.value : this.tripId,
    isDefault: isDefault ?? this.isDefault,
    deleted: deleted ?? this.deleted,
  );
  CategoryRow copyWithCompanion(CategoriesCompanion data) {
    return CategoryRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      tripId: data.tripId.present ? data.tripId.value : this.tripId,
      isDefault: data.isDefault.present ? data.isDefault.value : this.isDefault,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CategoryRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('tripId: $tripId, ')
          ..write('isDefault: $isDefault, ')
          ..write('deleted: $deleted')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, tripId, isDefault, deleted);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CategoryRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.tripId == this.tripId &&
          other.isDefault == this.isDefault &&
          other.deleted == this.deleted);
}

class CategoriesCompanion extends UpdateCompanion<CategoryRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> tripId;
  final Value<bool> isDefault;
  final Value<bool> deleted;
  final Value<int> rowid;
  const CategoriesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.tripId = const Value.absent(),
    this.isDefault = const Value.absent(),
    this.deleted = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CategoriesCompanion.insert({
    required String id,
    required String name,
    this.tripId = const Value.absent(),
    this.isDefault = const Value.absent(),
    this.deleted = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name);
  static Insertable<CategoryRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? tripId,
    Expression<bool>? isDefault,
    Expression<bool>? deleted,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (tripId != null) 'trip_id': tripId,
      if (isDefault != null) 'is_default': isDefault,
      if (deleted != null) 'deleted': deleted,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CategoriesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String?>? tripId,
    Value<bool>? isDefault,
    Value<bool>? deleted,
    Value<int>? rowid,
  }) {
    return CategoriesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      tripId: tripId ?? this.tripId,
      isDefault: isDefault ?? this.isDefault,
      deleted: deleted ?? this.deleted,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (tripId.present) {
      map['trip_id'] = Variable<String>(tripId.value);
    }
    if (isDefault.present) {
      map['is_default'] = Variable<bool>(isDefault.value);
    }
    if (deleted.present) {
      map['deleted'] = Variable<bool>(deleted.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoriesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('tripId: $tripId, ')
          ..write('isDefault: $isDefault, ')
          ..write('deleted: $deleted, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ExpensesTable extends Expenses
    with TableInfo<$ExpensesTable, ExpenseRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExpensesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tripIdMeta = const VerificationMeta('tripId');
  @override
  late final GeneratedColumn<String> tripId = GeneratedColumn<String>(
    'trip_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES trips (id)',
    ),
  );
  static const VerificationMeta _authorIdMeta = const VerificationMeta(
    'authorId',
  );
  @override
  late final GeneratedColumn<String> authorId = GeneratedColumn<String>(
    'author_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES members (id)',
    ),
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currencyMeta = const VerificationMeta(
    'currency',
  );
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
    'currency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _convertedAmountMeta = const VerificationMeta(
    'convertedAmount',
  );
  @override
  late final GeneratedColumn<double> convertedAmount = GeneratedColumn<double>(
    'converted_amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rateUsedMeta = const VerificationMeta(
    'rateUsed',
  );
  @override
  late final GeneratedColumn<double> rateUsed = GeneratedColumn<double>(
    'rate_used',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _splitTypeMeta = const VerificationMeta(
    'splitType',
  );
  @override
  late final GeneratedColumn<String> splitType = GeneratedColumn<String>(
    'split_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('equal'),
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
  static const VerificationMeta _editedAtMeta = const VerificationMeta(
    'editedAt',
  );
  @override
  late final GeneratedColumn<DateTime> editedAt = GeneratedColumn<DateTime>(
    'edited_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deletedMeta = const VerificationMeta(
    'deleted',
  );
  @override
  late final GeneratedColumn<bool> deleted = GeneratedColumn<bool>(
    'deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    tripId,
    authorId,
    category,
    amount,
    currency,
    convertedAmount,
    rateUsed,
    note,
    splitType,
    createdAt,
    editedAt,
    deleted,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'expenses';
  @override
  VerificationContext validateIntegrity(
    Insertable<ExpenseRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('trip_id')) {
      context.handle(
        _tripIdMeta,
        tripId.isAcceptableOrUnknown(data['trip_id']!, _tripIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tripIdMeta);
    }
    if (data.containsKey('author_id')) {
      context.handle(
        _authorIdMeta,
        authorId.isAcceptableOrUnknown(data['author_id']!, _authorIdMeta),
      );
    } else if (isInserting) {
      context.missing(_authorIdMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('currency')) {
      context.handle(
        _currencyMeta,
        currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta),
      );
    } else if (isInserting) {
      context.missing(_currencyMeta);
    }
    if (data.containsKey('converted_amount')) {
      context.handle(
        _convertedAmountMeta,
        convertedAmount.isAcceptableOrUnknown(
          data['converted_amount']!,
          _convertedAmountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_convertedAmountMeta);
    }
    if (data.containsKey('rate_used')) {
      context.handle(
        _rateUsedMeta,
        rateUsed.isAcceptableOrUnknown(data['rate_used']!, _rateUsedMeta),
      );
    } else if (isInserting) {
      context.missing(_rateUsedMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('split_type')) {
      context.handle(
        _splitTypeMeta,
        splitType.isAcceptableOrUnknown(data['split_type']!, _splitTypeMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('edited_at')) {
      context.handle(
        _editedAtMeta,
        editedAt.isAcceptableOrUnknown(data['edited_at']!, _editedAtMeta),
      );
    }
    if (data.containsKey('deleted')) {
      context.handle(
        _deletedMeta,
        deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ExpenseRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ExpenseRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      tripId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}trip_id'],
      )!,
      authorId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}author_id'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}amount'],
      )!,
      currency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency'],
      )!,
      convertedAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}converted_amount'],
      )!,
      rateUsed: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}rate_used'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      )!,
      splitType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}split_type'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      editedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}edited_at'],
      ),
      deleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}deleted'],
      )!,
    );
  }

  @override
  $ExpensesTable createAlias(String alias) {
    return $ExpensesTable(attachedDatabase, alias);
  }
}

class ExpenseRow extends DataClass implements Insertable<ExpenseRow> {
  final String id;
  final String tripId;
  final String authorId;
  final String category;
  final double amount;
  final String currency;
  final double convertedAmount;
  final double rateUsed;
  final String note;
  final String splitType;
  final DateTime createdAt;
  final DateTime? editedAt;
  final bool deleted;
  const ExpenseRow({
    required this.id,
    required this.tripId,
    required this.authorId,
    required this.category,
    required this.amount,
    required this.currency,
    required this.convertedAmount,
    required this.rateUsed,
    required this.note,
    required this.splitType,
    required this.createdAt,
    this.editedAt,
    required this.deleted,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['trip_id'] = Variable<String>(tripId);
    map['author_id'] = Variable<String>(authorId);
    map['category'] = Variable<String>(category);
    map['amount'] = Variable<double>(amount);
    map['currency'] = Variable<String>(currency);
    map['converted_amount'] = Variable<double>(convertedAmount);
    map['rate_used'] = Variable<double>(rateUsed);
    map['note'] = Variable<String>(note);
    map['split_type'] = Variable<String>(splitType);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || editedAt != null) {
      map['edited_at'] = Variable<DateTime>(editedAt);
    }
    map['deleted'] = Variable<bool>(deleted);
    return map;
  }

  ExpensesCompanion toCompanion(bool nullToAbsent) {
    return ExpensesCompanion(
      id: Value(id),
      tripId: Value(tripId),
      authorId: Value(authorId),
      category: Value(category),
      amount: Value(amount),
      currency: Value(currency),
      convertedAmount: Value(convertedAmount),
      rateUsed: Value(rateUsed),
      note: Value(note),
      splitType: Value(splitType),
      createdAt: Value(createdAt),
      editedAt: editedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(editedAt),
      deleted: Value(deleted),
    );
  }

  factory ExpenseRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ExpenseRow(
      id: serializer.fromJson<String>(json['id']),
      tripId: serializer.fromJson<String>(json['tripId']),
      authorId: serializer.fromJson<String>(json['authorId']),
      category: serializer.fromJson<String>(json['category']),
      amount: serializer.fromJson<double>(json['amount']),
      currency: serializer.fromJson<String>(json['currency']),
      convertedAmount: serializer.fromJson<double>(json['convertedAmount']),
      rateUsed: serializer.fromJson<double>(json['rateUsed']),
      note: serializer.fromJson<String>(json['note']),
      splitType: serializer.fromJson<String>(json['splitType']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      editedAt: serializer.fromJson<DateTime?>(json['editedAt']),
      deleted: serializer.fromJson<bool>(json['deleted']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'tripId': serializer.toJson<String>(tripId),
      'authorId': serializer.toJson<String>(authorId),
      'category': serializer.toJson<String>(category),
      'amount': serializer.toJson<double>(amount),
      'currency': serializer.toJson<String>(currency),
      'convertedAmount': serializer.toJson<double>(convertedAmount),
      'rateUsed': serializer.toJson<double>(rateUsed),
      'note': serializer.toJson<String>(note),
      'splitType': serializer.toJson<String>(splitType),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'editedAt': serializer.toJson<DateTime?>(editedAt),
      'deleted': serializer.toJson<bool>(deleted),
    };
  }

  ExpenseRow copyWith({
    String? id,
    String? tripId,
    String? authorId,
    String? category,
    double? amount,
    String? currency,
    double? convertedAmount,
    double? rateUsed,
    String? note,
    String? splitType,
    DateTime? createdAt,
    Value<DateTime?> editedAt = const Value.absent(),
    bool? deleted,
  }) => ExpenseRow(
    id: id ?? this.id,
    tripId: tripId ?? this.tripId,
    authorId: authorId ?? this.authorId,
    category: category ?? this.category,
    amount: amount ?? this.amount,
    currency: currency ?? this.currency,
    convertedAmount: convertedAmount ?? this.convertedAmount,
    rateUsed: rateUsed ?? this.rateUsed,
    note: note ?? this.note,
    splitType: splitType ?? this.splitType,
    createdAt: createdAt ?? this.createdAt,
    editedAt: editedAt.present ? editedAt.value : this.editedAt,
    deleted: deleted ?? this.deleted,
  );
  ExpenseRow copyWithCompanion(ExpensesCompanion data) {
    return ExpenseRow(
      id: data.id.present ? data.id.value : this.id,
      tripId: data.tripId.present ? data.tripId.value : this.tripId,
      authorId: data.authorId.present ? data.authorId.value : this.authorId,
      category: data.category.present ? data.category.value : this.category,
      amount: data.amount.present ? data.amount.value : this.amount,
      currency: data.currency.present ? data.currency.value : this.currency,
      convertedAmount: data.convertedAmount.present
          ? data.convertedAmount.value
          : this.convertedAmount,
      rateUsed: data.rateUsed.present ? data.rateUsed.value : this.rateUsed,
      note: data.note.present ? data.note.value : this.note,
      splitType: data.splitType.present ? data.splitType.value : this.splitType,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      editedAt: data.editedAt.present ? data.editedAt.value : this.editedAt,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ExpenseRow(')
          ..write('id: $id, ')
          ..write('tripId: $tripId, ')
          ..write('authorId: $authorId, ')
          ..write('category: $category, ')
          ..write('amount: $amount, ')
          ..write('currency: $currency, ')
          ..write('convertedAmount: $convertedAmount, ')
          ..write('rateUsed: $rateUsed, ')
          ..write('note: $note, ')
          ..write('splitType: $splitType, ')
          ..write('createdAt: $createdAt, ')
          ..write('editedAt: $editedAt, ')
          ..write('deleted: $deleted')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    tripId,
    authorId,
    category,
    amount,
    currency,
    convertedAmount,
    rateUsed,
    note,
    splitType,
    createdAt,
    editedAt,
    deleted,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExpenseRow &&
          other.id == this.id &&
          other.tripId == this.tripId &&
          other.authorId == this.authorId &&
          other.category == this.category &&
          other.amount == this.amount &&
          other.currency == this.currency &&
          other.convertedAmount == this.convertedAmount &&
          other.rateUsed == this.rateUsed &&
          other.note == this.note &&
          other.splitType == this.splitType &&
          other.createdAt == this.createdAt &&
          other.editedAt == this.editedAt &&
          other.deleted == this.deleted);
}

class ExpensesCompanion extends UpdateCompanion<ExpenseRow> {
  final Value<String> id;
  final Value<String> tripId;
  final Value<String> authorId;
  final Value<String> category;
  final Value<double> amount;
  final Value<String> currency;
  final Value<double> convertedAmount;
  final Value<double> rateUsed;
  final Value<String> note;
  final Value<String> splitType;
  final Value<DateTime> createdAt;
  final Value<DateTime?> editedAt;
  final Value<bool> deleted;
  final Value<int> rowid;
  const ExpensesCompanion({
    this.id = const Value.absent(),
    this.tripId = const Value.absent(),
    this.authorId = const Value.absent(),
    this.category = const Value.absent(),
    this.amount = const Value.absent(),
    this.currency = const Value.absent(),
    this.convertedAmount = const Value.absent(),
    this.rateUsed = const Value.absent(),
    this.note = const Value.absent(),
    this.splitType = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.editedAt = const Value.absent(),
    this.deleted = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ExpensesCompanion.insert({
    required String id,
    required String tripId,
    required String authorId,
    required String category,
    required double amount,
    required String currency,
    required double convertedAmount,
    required double rateUsed,
    this.note = const Value.absent(),
    this.splitType = const Value.absent(),
    required DateTime createdAt,
    this.editedAt = const Value.absent(),
    this.deleted = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       tripId = Value(tripId),
       authorId = Value(authorId),
       category = Value(category),
       amount = Value(amount),
       currency = Value(currency),
       convertedAmount = Value(convertedAmount),
       rateUsed = Value(rateUsed),
       createdAt = Value(createdAt);
  static Insertable<ExpenseRow> custom({
    Expression<String>? id,
    Expression<String>? tripId,
    Expression<String>? authorId,
    Expression<String>? category,
    Expression<double>? amount,
    Expression<String>? currency,
    Expression<double>? convertedAmount,
    Expression<double>? rateUsed,
    Expression<String>? note,
    Expression<String>? splitType,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? editedAt,
    Expression<bool>? deleted,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (tripId != null) 'trip_id': tripId,
      if (authorId != null) 'author_id': authorId,
      if (category != null) 'category': category,
      if (amount != null) 'amount': amount,
      if (currency != null) 'currency': currency,
      if (convertedAmount != null) 'converted_amount': convertedAmount,
      if (rateUsed != null) 'rate_used': rateUsed,
      if (note != null) 'note': note,
      if (splitType != null) 'split_type': splitType,
      if (createdAt != null) 'created_at': createdAt,
      if (editedAt != null) 'edited_at': editedAt,
      if (deleted != null) 'deleted': deleted,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ExpensesCompanion copyWith({
    Value<String>? id,
    Value<String>? tripId,
    Value<String>? authorId,
    Value<String>? category,
    Value<double>? amount,
    Value<String>? currency,
    Value<double>? convertedAmount,
    Value<double>? rateUsed,
    Value<String>? note,
    Value<String>? splitType,
    Value<DateTime>? createdAt,
    Value<DateTime?>? editedAt,
    Value<bool>? deleted,
    Value<int>? rowid,
  }) {
    return ExpensesCompanion(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      authorId: authorId ?? this.authorId,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      convertedAmount: convertedAmount ?? this.convertedAmount,
      rateUsed: rateUsed ?? this.rateUsed,
      note: note ?? this.note,
      splitType: splitType ?? this.splitType,
      createdAt: createdAt ?? this.createdAt,
      editedAt: editedAt ?? this.editedAt,
      deleted: deleted ?? this.deleted,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (tripId.present) {
      map['trip_id'] = Variable<String>(tripId.value);
    }
    if (authorId.present) {
      map['author_id'] = Variable<String>(authorId.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (convertedAmount.present) {
      map['converted_amount'] = Variable<double>(convertedAmount.value);
    }
    if (rateUsed.present) {
      map['rate_used'] = Variable<double>(rateUsed.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (splitType.present) {
      map['split_type'] = Variable<String>(splitType.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (editedAt.present) {
      map['edited_at'] = Variable<DateTime>(editedAt.value);
    }
    if (deleted.present) {
      map['deleted'] = Variable<bool>(deleted.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExpensesCompanion(')
          ..write('id: $id, ')
          ..write('tripId: $tripId, ')
          ..write('authorId: $authorId, ')
          ..write('category: $category, ')
          ..write('amount: $amount, ')
          ..write('currency: $currency, ')
          ..write('convertedAmount: $convertedAmount, ')
          ..write('rateUsed: $rateUsed, ')
          ..write('note: $note, ')
          ..write('splitType: $splitType, ')
          ..write('createdAt: $createdAt, ')
          ..write('editedAt: $editedAt, ')
          ..write('deleted: $deleted, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SplitRowsTable extends SplitRows
    with TableInfo<$SplitRowsTable, SplitRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SplitRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _expenseIdMeta = const VerificationMeta(
    'expenseId',
  );
  @override
  late final GeneratedColumn<String> expenseId = GeneratedColumn<String>(
    'expense_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES expenses (id)',
    ),
  );
  static const VerificationMeta _memberIdMeta = const VerificationMeta(
    'memberId',
  );
  @override
  late final GeneratedColumn<String> memberId = GeneratedColumn<String>(
    'member_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES members (id)',
    ),
  );
  static const VerificationMeta _shareAmountMeta = const VerificationMeta(
    'shareAmount',
  );
  @override
  late final GeneratedColumn<double> shareAmount = GeneratedColumn<double>(
    'share_amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _shareConvertedMeta = const VerificationMeta(
    'shareConverted',
  );
  @override
  late final GeneratedColumn<double> shareConverted = GeneratedColumn<double>(
    'share_converted',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    expenseId,
    memberId,
    shareAmount,
    shareConverted,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'split_rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<SplitRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('expense_id')) {
      context.handle(
        _expenseIdMeta,
        expenseId.isAcceptableOrUnknown(data['expense_id']!, _expenseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_expenseIdMeta);
    }
    if (data.containsKey('member_id')) {
      context.handle(
        _memberIdMeta,
        memberId.isAcceptableOrUnknown(data['member_id']!, _memberIdMeta),
      );
    } else if (isInserting) {
      context.missing(_memberIdMeta);
    }
    if (data.containsKey('share_amount')) {
      context.handle(
        _shareAmountMeta,
        shareAmount.isAcceptableOrUnknown(
          data['share_amount']!,
          _shareAmountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_shareAmountMeta);
    }
    if (data.containsKey('share_converted')) {
      context.handle(
        _shareConvertedMeta,
        shareConverted.isAcceptableOrUnknown(
          data['share_converted']!,
          _shareConvertedMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_shareConvertedMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SplitRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SplitRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      expenseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}expense_id'],
      )!,
      memberId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}member_id'],
      )!,
      shareAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}share_amount'],
      )!,
      shareConverted: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}share_converted'],
      )!,
    );
  }

  @override
  $SplitRowsTable createAlias(String alias) {
    return $SplitRowsTable(attachedDatabase, alias);
  }
}

class SplitRow extends DataClass implements Insertable<SplitRow> {
  final String id;
  final String expenseId;
  final String memberId;
  final double shareAmount;
  final double shareConverted;
  const SplitRow({
    required this.id,
    required this.expenseId,
    required this.memberId,
    required this.shareAmount,
    required this.shareConverted,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['expense_id'] = Variable<String>(expenseId);
    map['member_id'] = Variable<String>(memberId);
    map['share_amount'] = Variable<double>(shareAmount);
    map['share_converted'] = Variable<double>(shareConverted);
    return map;
  }

  SplitRowsCompanion toCompanion(bool nullToAbsent) {
    return SplitRowsCompanion(
      id: Value(id),
      expenseId: Value(expenseId),
      memberId: Value(memberId),
      shareAmount: Value(shareAmount),
      shareConverted: Value(shareConverted),
    );
  }

  factory SplitRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SplitRow(
      id: serializer.fromJson<String>(json['id']),
      expenseId: serializer.fromJson<String>(json['expenseId']),
      memberId: serializer.fromJson<String>(json['memberId']),
      shareAmount: serializer.fromJson<double>(json['shareAmount']),
      shareConverted: serializer.fromJson<double>(json['shareConverted']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'expenseId': serializer.toJson<String>(expenseId),
      'memberId': serializer.toJson<String>(memberId),
      'shareAmount': serializer.toJson<double>(shareAmount),
      'shareConverted': serializer.toJson<double>(shareConverted),
    };
  }

  SplitRow copyWith({
    String? id,
    String? expenseId,
    String? memberId,
    double? shareAmount,
    double? shareConverted,
  }) => SplitRow(
    id: id ?? this.id,
    expenseId: expenseId ?? this.expenseId,
    memberId: memberId ?? this.memberId,
    shareAmount: shareAmount ?? this.shareAmount,
    shareConverted: shareConverted ?? this.shareConverted,
  );
  SplitRow copyWithCompanion(SplitRowsCompanion data) {
    return SplitRow(
      id: data.id.present ? data.id.value : this.id,
      expenseId: data.expenseId.present ? data.expenseId.value : this.expenseId,
      memberId: data.memberId.present ? data.memberId.value : this.memberId,
      shareAmount: data.shareAmount.present
          ? data.shareAmount.value
          : this.shareAmount,
      shareConverted: data.shareConverted.present
          ? data.shareConverted.value
          : this.shareConverted,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SplitRow(')
          ..write('id: $id, ')
          ..write('expenseId: $expenseId, ')
          ..write('memberId: $memberId, ')
          ..write('shareAmount: $shareAmount, ')
          ..write('shareConverted: $shareConverted')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, expenseId, memberId, shareAmount, shareConverted);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SplitRow &&
          other.id == this.id &&
          other.expenseId == this.expenseId &&
          other.memberId == this.memberId &&
          other.shareAmount == this.shareAmount &&
          other.shareConverted == this.shareConverted);
}

class SplitRowsCompanion extends UpdateCompanion<SplitRow> {
  final Value<String> id;
  final Value<String> expenseId;
  final Value<String> memberId;
  final Value<double> shareAmount;
  final Value<double> shareConverted;
  final Value<int> rowid;
  const SplitRowsCompanion({
    this.id = const Value.absent(),
    this.expenseId = const Value.absent(),
    this.memberId = const Value.absent(),
    this.shareAmount = const Value.absent(),
    this.shareConverted = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SplitRowsCompanion.insert({
    required String id,
    required String expenseId,
    required String memberId,
    required double shareAmount,
    required double shareConverted,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       expenseId = Value(expenseId),
       memberId = Value(memberId),
       shareAmount = Value(shareAmount),
       shareConverted = Value(shareConverted);
  static Insertable<SplitRow> custom({
    Expression<String>? id,
    Expression<String>? expenseId,
    Expression<String>? memberId,
    Expression<double>? shareAmount,
    Expression<double>? shareConverted,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (expenseId != null) 'expense_id': expenseId,
      if (memberId != null) 'member_id': memberId,
      if (shareAmount != null) 'share_amount': shareAmount,
      if (shareConverted != null) 'share_converted': shareConverted,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SplitRowsCompanion copyWith({
    Value<String>? id,
    Value<String>? expenseId,
    Value<String>? memberId,
    Value<double>? shareAmount,
    Value<double>? shareConverted,
    Value<int>? rowid,
  }) {
    return SplitRowsCompanion(
      id: id ?? this.id,
      expenseId: expenseId ?? this.expenseId,
      memberId: memberId ?? this.memberId,
      shareAmount: shareAmount ?? this.shareAmount,
      shareConverted: shareConverted ?? this.shareConverted,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (expenseId.present) {
      map['expense_id'] = Variable<String>(expenseId.value);
    }
    if (memberId.present) {
      map['member_id'] = Variable<String>(memberId.value);
    }
    if (shareAmount.present) {
      map['share_amount'] = Variable<double>(shareAmount.value);
    }
    if (shareConverted.present) {
      map['share_converted'] = Variable<double>(shareConverted.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SplitRowsCompanion(')
          ..write('id: $id, ')
          ..write('expenseId: $expenseId, ')
          ..write('memberId: $memberId, ')
          ..write('shareAmount: $shareAmount, ')
          ..write('shareConverted: $shareConverted, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SettlementsTable extends Settlements
    with TableInfo<$SettlementsTable, SettlementRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettlementsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tripIdMeta = const VerificationMeta('tripId');
  @override
  late final GeneratedColumn<String> tripId = GeneratedColumn<String>(
    'trip_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES trips (id)',
    ),
  );
  static const VerificationMeta _fromMemberIdMeta = const VerificationMeta(
    'fromMemberId',
  );
  @override
  late final GeneratedColumn<String> fromMemberId = GeneratedColumn<String>(
    'from_member_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES members (id)',
    ),
  );
  static const VerificationMeta _toMemberIdMeta = const VerificationMeta(
    'toMemberId',
  );
  @override
  late final GeneratedColumn<String> toMemberId = GeneratedColumn<String>(
    'to_member_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES members (id)',
    ),
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _partialRemainingMeta = const VerificationMeta(
    'partialRemaining',
  );
  @override
  late final GeneratedColumn<double> partialRemaining = GeneratedColumn<double>(
    'partial_remaining',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _paidAtMeta = const VerificationMeta('paidAt');
  @override
  late final GeneratedColumn<DateTime> paidAt = GeneratedColumn<DateTime>(
    'paid_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedMeta = const VerificationMeta(
    'deleted',
  );
  @override
  late final GeneratedColumn<bool> deleted = GeneratedColumn<bool>(
    'deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    tripId,
    fromMemberId,
    toMemberId,
    amount,
    partialRemaining,
    note,
    paidAt,
    deleted,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settlements';
  @override
  VerificationContext validateIntegrity(
    Insertable<SettlementRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('trip_id')) {
      context.handle(
        _tripIdMeta,
        tripId.isAcceptableOrUnknown(data['trip_id']!, _tripIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tripIdMeta);
    }
    if (data.containsKey('from_member_id')) {
      context.handle(
        _fromMemberIdMeta,
        fromMemberId.isAcceptableOrUnknown(
          data['from_member_id']!,
          _fromMemberIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_fromMemberIdMeta);
    }
    if (data.containsKey('to_member_id')) {
      context.handle(
        _toMemberIdMeta,
        toMemberId.isAcceptableOrUnknown(
          data['to_member_id']!,
          _toMemberIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_toMemberIdMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('partial_remaining')) {
      context.handle(
        _partialRemainingMeta,
        partialRemaining.isAcceptableOrUnknown(
          data['partial_remaining']!,
          _partialRemainingMeta,
        ),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('paid_at')) {
      context.handle(
        _paidAtMeta,
        paidAt.isAcceptableOrUnknown(data['paid_at']!, _paidAtMeta),
      );
    } else if (isInserting) {
      context.missing(_paidAtMeta);
    }
    if (data.containsKey('deleted')) {
      context.handle(
        _deletedMeta,
        deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SettlementRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SettlementRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      tripId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}trip_id'],
      )!,
      fromMemberId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}from_member_id'],
      )!,
      toMemberId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}to_member_id'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}amount'],
      )!,
      partialRemaining: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}partial_remaining'],
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      )!,
      paidAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}paid_at'],
      )!,
      deleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}deleted'],
      )!,
    );
  }

  @override
  $SettlementsTable createAlias(String alias) {
    return $SettlementsTable(attachedDatabase, alias);
  }
}

class SettlementRow extends DataClass implements Insertable<SettlementRow> {
  final String id;
  final String tripId;
  final String fromMemberId;
  final String toMemberId;
  final double amount;
  final double? partialRemaining;
  final String note;
  final DateTime paidAt;
  final bool deleted;
  const SettlementRow({
    required this.id,
    required this.tripId,
    required this.fromMemberId,
    required this.toMemberId,
    required this.amount,
    this.partialRemaining,
    required this.note,
    required this.paidAt,
    required this.deleted,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['trip_id'] = Variable<String>(tripId);
    map['from_member_id'] = Variable<String>(fromMemberId);
    map['to_member_id'] = Variable<String>(toMemberId);
    map['amount'] = Variable<double>(amount);
    if (!nullToAbsent || partialRemaining != null) {
      map['partial_remaining'] = Variable<double>(partialRemaining);
    }
    map['note'] = Variable<String>(note);
    map['paid_at'] = Variable<DateTime>(paidAt);
    map['deleted'] = Variable<bool>(deleted);
    return map;
  }

  SettlementsCompanion toCompanion(bool nullToAbsent) {
    return SettlementsCompanion(
      id: Value(id),
      tripId: Value(tripId),
      fromMemberId: Value(fromMemberId),
      toMemberId: Value(toMemberId),
      amount: Value(amount),
      partialRemaining: partialRemaining == null && nullToAbsent
          ? const Value.absent()
          : Value(partialRemaining),
      note: Value(note),
      paidAt: Value(paidAt),
      deleted: Value(deleted),
    );
  }

  factory SettlementRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SettlementRow(
      id: serializer.fromJson<String>(json['id']),
      tripId: serializer.fromJson<String>(json['tripId']),
      fromMemberId: serializer.fromJson<String>(json['fromMemberId']),
      toMemberId: serializer.fromJson<String>(json['toMemberId']),
      amount: serializer.fromJson<double>(json['amount']),
      partialRemaining: serializer.fromJson<double?>(json['partialRemaining']),
      note: serializer.fromJson<String>(json['note']),
      paidAt: serializer.fromJson<DateTime>(json['paidAt']),
      deleted: serializer.fromJson<bool>(json['deleted']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'tripId': serializer.toJson<String>(tripId),
      'fromMemberId': serializer.toJson<String>(fromMemberId),
      'toMemberId': serializer.toJson<String>(toMemberId),
      'amount': serializer.toJson<double>(amount),
      'partialRemaining': serializer.toJson<double?>(partialRemaining),
      'note': serializer.toJson<String>(note),
      'paidAt': serializer.toJson<DateTime>(paidAt),
      'deleted': serializer.toJson<bool>(deleted),
    };
  }

  SettlementRow copyWith({
    String? id,
    String? tripId,
    String? fromMemberId,
    String? toMemberId,
    double? amount,
    Value<double?> partialRemaining = const Value.absent(),
    String? note,
    DateTime? paidAt,
    bool? deleted,
  }) => SettlementRow(
    id: id ?? this.id,
    tripId: tripId ?? this.tripId,
    fromMemberId: fromMemberId ?? this.fromMemberId,
    toMemberId: toMemberId ?? this.toMemberId,
    amount: amount ?? this.amount,
    partialRemaining: partialRemaining.present
        ? partialRemaining.value
        : this.partialRemaining,
    note: note ?? this.note,
    paidAt: paidAt ?? this.paidAt,
    deleted: deleted ?? this.deleted,
  );
  SettlementRow copyWithCompanion(SettlementsCompanion data) {
    return SettlementRow(
      id: data.id.present ? data.id.value : this.id,
      tripId: data.tripId.present ? data.tripId.value : this.tripId,
      fromMemberId: data.fromMemberId.present
          ? data.fromMemberId.value
          : this.fromMemberId,
      toMemberId: data.toMemberId.present
          ? data.toMemberId.value
          : this.toMemberId,
      amount: data.amount.present ? data.amount.value : this.amount,
      partialRemaining: data.partialRemaining.present
          ? data.partialRemaining.value
          : this.partialRemaining,
      note: data.note.present ? data.note.value : this.note,
      paidAt: data.paidAt.present ? data.paidAt.value : this.paidAt,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SettlementRow(')
          ..write('id: $id, ')
          ..write('tripId: $tripId, ')
          ..write('fromMemberId: $fromMemberId, ')
          ..write('toMemberId: $toMemberId, ')
          ..write('amount: $amount, ')
          ..write('partialRemaining: $partialRemaining, ')
          ..write('note: $note, ')
          ..write('paidAt: $paidAt, ')
          ..write('deleted: $deleted')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    tripId,
    fromMemberId,
    toMemberId,
    amount,
    partialRemaining,
    note,
    paidAt,
    deleted,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SettlementRow &&
          other.id == this.id &&
          other.tripId == this.tripId &&
          other.fromMemberId == this.fromMemberId &&
          other.toMemberId == this.toMemberId &&
          other.amount == this.amount &&
          other.partialRemaining == this.partialRemaining &&
          other.note == this.note &&
          other.paidAt == this.paidAt &&
          other.deleted == this.deleted);
}

class SettlementsCompanion extends UpdateCompanion<SettlementRow> {
  final Value<String> id;
  final Value<String> tripId;
  final Value<String> fromMemberId;
  final Value<String> toMemberId;
  final Value<double> amount;
  final Value<double?> partialRemaining;
  final Value<String> note;
  final Value<DateTime> paidAt;
  final Value<bool> deleted;
  final Value<int> rowid;
  const SettlementsCompanion({
    this.id = const Value.absent(),
    this.tripId = const Value.absent(),
    this.fromMemberId = const Value.absent(),
    this.toMemberId = const Value.absent(),
    this.amount = const Value.absent(),
    this.partialRemaining = const Value.absent(),
    this.note = const Value.absent(),
    this.paidAt = const Value.absent(),
    this.deleted = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettlementsCompanion.insert({
    required String id,
    required String tripId,
    required String fromMemberId,
    required String toMemberId,
    required double amount,
    this.partialRemaining = const Value.absent(),
    this.note = const Value.absent(),
    required DateTime paidAt,
    this.deleted = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       tripId = Value(tripId),
       fromMemberId = Value(fromMemberId),
       toMemberId = Value(toMemberId),
       amount = Value(amount),
       paidAt = Value(paidAt);
  static Insertable<SettlementRow> custom({
    Expression<String>? id,
    Expression<String>? tripId,
    Expression<String>? fromMemberId,
    Expression<String>? toMemberId,
    Expression<double>? amount,
    Expression<double>? partialRemaining,
    Expression<String>? note,
    Expression<DateTime>? paidAt,
    Expression<bool>? deleted,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (tripId != null) 'trip_id': tripId,
      if (fromMemberId != null) 'from_member_id': fromMemberId,
      if (toMemberId != null) 'to_member_id': toMemberId,
      if (amount != null) 'amount': amount,
      if (partialRemaining != null) 'partial_remaining': partialRemaining,
      if (note != null) 'note': note,
      if (paidAt != null) 'paid_at': paidAt,
      if (deleted != null) 'deleted': deleted,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SettlementsCompanion copyWith({
    Value<String>? id,
    Value<String>? tripId,
    Value<String>? fromMemberId,
    Value<String>? toMemberId,
    Value<double>? amount,
    Value<double?>? partialRemaining,
    Value<String>? note,
    Value<DateTime>? paidAt,
    Value<bool>? deleted,
    Value<int>? rowid,
  }) {
    return SettlementsCompanion(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      fromMemberId: fromMemberId ?? this.fromMemberId,
      toMemberId: toMemberId ?? this.toMemberId,
      amount: amount ?? this.amount,
      partialRemaining: partialRemaining ?? this.partialRemaining,
      note: note ?? this.note,
      paidAt: paidAt ?? this.paidAt,
      deleted: deleted ?? this.deleted,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (tripId.present) {
      map['trip_id'] = Variable<String>(tripId.value);
    }
    if (fromMemberId.present) {
      map['from_member_id'] = Variable<String>(fromMemberId.value);
    }
    if (toMemberId.present) {
      map['to_member_id'] = Variable<String>(toMemberId.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (partialRemaining.present) {
      map['partial_remaining'] = Variable<double>(partialRemaining.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (paidAt.present) {
      map['paid_at'] = Variable<DateTime>(paidAt.value);
    }
    if (deleted.present) {
      map['deleted'] = Variable<bool>(deleted.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettlementsCompanion(')
          ..write('id: $id, ')
          ..write('tripId: $tripId, ')
          ..write('fromMemberId: $fromMemberId, ')
          ..write('toMemberId: $toMemberId, ')
          ..write('amount: $amount, ')
          ..write('partialRemaining: $partialRemaining, ')
          ..write('note: $note, ')
          ..write('paidAt: $paidAt, ')
          ..write('deleted: $deleted, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RateCachesTable extends RateCaches
    with TableInfo<$RateCachesTable, RateCacheRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RateCachesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _baseCurrencyMeta = const VerificationMeta(
    'baseCurrency',
  );
  @override
  late final GeneratedColumn<String> baseCurrency = GeneratedColumn<String>(
    'base_currency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currencyMeta = const VerificationMeta(
    'currency',
  );
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
    'currency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rateInBaseMeta = const VerificationMeta(
    'rateInBase',
  );
  @override
  late final GeneratedColumn<double> rateInBase = GeneratedColumn<double>(
    'rate_in_base',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('rbi'),
  );
  static const VerificationMeta _fetchedAtMeta = const VerificationMeta(
    'fetchedAt',
  );
  @override
  late final GeneratedColumn<DateTime> fetchedAt = GeneratedColumn<DateTime>(
    'fetched_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    baseCurrency,
    currency,
    rateInBase,
    source,
    fetchedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'rate_caches';
  @override
  VerificationContext validateIntegrity(
    Insertable<RateCacheRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('base_currency')) {
      context.handle(
        _baseCurrencyMeta,
        baseCurrency.isAcceptableOrUnknown(
          data['base_currency']!,
          _baseCurrencyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_baseCurrencyMeta);
    }
    if (data.containsKey('currency')) {
      context.handle(
        _currencyMeta,
        currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta),
      );
    } else if (isInserting) {
      context.missing(_currencyMeta);
    }
    if (data.containsKey('rate_in_base')) {
      context.handle(
        _rateInBaseMeta,
        rateInBase.isAcceptableOrUnknown(
          data['rate_in_base']!,
          _rateInBaseMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_rateInBaseMeta);
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    }
    if (data.containsKey('fetched_at')) {
      context.handle(
        _fetchedAtMeta,
        fetchedAt.isAcceptableOrUnknown(data['fetched_at']!, _fetchedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_fetchedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RateCacheRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RateCacheRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      baseCurrency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}base_currency'],
      )!,
      currency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency'],
      )!,
      rateInBase: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}rate_in_base'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      fetchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fetched_at'],
      )!,
    );
  }

  @override
  $RateCachesTable createAlias(String alias) {
    return $RateCachesTable(attachedDatabase, alias);
  }
}

class RateCacheRow extends DataClass implements Insertable<RateCacheRow> {
  final int id;
  final String baseCurrency;
  final String currency;
  final double rateInBase;
  final String source;
  final DateTime fetchedAt;
  const RateCacheRow({
    required this.id,
    required this.baseCurrency,
    required this.currency,
    required this.rateInBase,
    required this.source,
    required this.fetchedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['base_currency'] = Variable<String>(baseCurrency);
    map['currency'] = Variable<String>(currency);
    map['rate_in_base'] = Variable<double>(rateInBase);
    map['source'] = Variable<String>(source);
    map['fetched_at'] = Variable<DateTime>(fetchedAt);
    return map;
  }

  RateCachesCompanion toCompanion(bool nullToAbsent) {
    return RateCachesCompanion(
      id: Value(id),
      baseCurrency: Value(baseCurrency),
      currency: Value(currency),
      rateInBase: Value(rateInBase),
      source: Value(source),
      fetchedAt: Value(fetchedAt),
    );
  }

  factory RateCacheRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RateCacheRow(
      id: serializer.fromJson<int>(json['id']),
      baseCurrency: serializer.fromJson<String>(json['baseCurrency']),
      currency: serializer.fromJson<String>(json['currency']),
      rateInBase: serializer.fromJson<double>(json['rateInBase']),
      source: serializer.fromJson<String>(json['source']),
      fetchedAt: serializer.fromJson<DateTime>(json['fetchedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'baseCurrency': serializer.toJson<String>(baseCurrency),
      'currency': serializer.toJson<String>(currency),
      'rateInBase': serializer.toJson<double>(rateInBase),
      'source': serializer.toJson<String>(source),
      'fetchedAt': serializer.toJson<DateTime>(fetchedAt),
    };
  }

  RateCacheRow copyWith({
    int? id,
    String? baseCurrency,
    String? currency,
    double? rateInBase,
    String? source,
    DateTime? fetchedAt,
  }) => RateCacheRow(
    id: id ?? this.id,
    baseCurrency: baseCurrency ?? this.baseCurrency,
    currency: currency ?? this.currency,
    rateInBase: rateInBase ?? this.rateInBase,
    source: source ?? this.source,
    fetchedAt: fetchedAt ?? this.fetchedAt,
  );
  RateCacheRow copyWithCompanion(RateCachesCompanion data) {
    return RateCacheRow(
      id: data.id.present ? data.id.value : this.id,
      baseCurrency: data.baseCurrency.present
          ? data.baseCurrency.value
          : this.baseCurrency,
      currency: data.currency.present ? data.currency.value : this.currency,
      rateInBase: data.rateInBase.present
          ? data.rateInBase.value
          : this.rateInBase,
      source: data.source.present ? data.source.value : this.source,
      fetchedAt: data.fetchedAt.present ? data.fetchedAt.value : this.fetchedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RateCacheRow(')
          ..write('id: $id, ')
          ..write('baseCurrency: $baseCurrency, ')
          ..write('currency: $currency, ')
          ..write('rateInBase: $rateInBase, ')
          ..write('source: $source, ')
          ..write('fetchedAt: $fetchedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, baseCurrency, currency, rateInBase, source, fetchedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RateCacheRow &&
          other.id == this.id &&
          other.baseCurrency == this.baseCurrency &&
          other.currency == this.currency &&
          other.rateInBase == this.rateInBase &&
          other.source == this.source &&
          other.fetchedAt == this.fetchedAt);
}

class RateCachesCompanion extends UpdateCompanion<RateCacheRow> {
  final Value<int> id;
  final Value<String> baseCurrency;
  final Value<String> currency;
  final Value<double> rateInBase;
  final Value<String> source;
  final Value<DateTime> fetchedAt;
  const RateCachesCompanion({
    this.id = const Value.absent(),
    this.baseCurrency = const Value.absent(),
    this.currency = const Value.absent(),
    this.rateInBase = const Value.absent(),
    this.source = const Value.absent(),
    this.fetchedAt = const Value.absent(),
  });
  RateCachesCompanion.insert({
    this.id = const Value.absent(),
    required String baseCurrency,
    required String currency,
    required double rateInBase,
    this.source = const Value.absent(),
    required DateTime fetchedAt,
  }) : baseCurrency = Value(baseCurrency),
       currency = Value(currency),
       rateInBase = Value(rateInBase),
       fetchedAt = Value(fetchedAt);
  static Insertable<RateCacheRow> custom({
    Expression<int>? id,
    Expression<String>? baseCurrency,
    Expression<String>? currency,
    Expression<double>? rateInBase,
    Expression<String>? source,
    Expression<DateTime>? fetchedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (baseCurrency != null) 'base_currency': baseCurrency,
      if (currency != null) 'currency': currency,
      if (rateInBase != null) 'rate_in_base': rateInBase,
      if (source != null) 'source': source,
      if (fetchedAt != null) 'fetched_at': fetchedAt,
    });
  }

  RateCachesCompanion copyWith({
    Value<int>? id,
    Value<String>? baseCurrency,
    Value<String>? currency,
    Value<double>? rateInBase,
    Value<String>? source,
    Value<DateTime>? fetchedAt,
  }) {
    return RateCachesCompanion(
      id: id ?? this.id,
      baseCurrency: baseCurrency ?? this.baseCurrency,
      currency: currency ?? this.currency,
      rateInBase: rateInBase ?? this.rateInBase,
      source: source ?? this.source,
      fetchedAt: fetchedAt ?? this.fetchedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (baseCurrency.present) {
      map['base_currency'] = Variable<String>(baseCurrency.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (rateInBase.present) {
      map['rate_in_base'] = Variable<double>(rateInBase.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (fetchedAt.present) {
      map['fetched_at'] = Variable<DateTime>(fetchedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RateCachesCompanion(')
          ..write('id: $id, ')
          ..write('baseCurrency: $baseCurrency, ')
          ..write('currency: $currency, ')
          ..write('rateInBase: $rateInBase, ')
          ..write('source: $source, ')
          ..write('fetchedAt: $fetchedAt')
          ..write(')'))
        .toString();
  }
}

class $OpLogsTable extends OpLogs with TableInfo<$OpLogsTable, OpLogRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OpLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tripIdMeta = const VerificationMeta('tripId');
  @override
  late final GeneratedColumn<String> tripId = GeneratedColumn<String>(
    'trip_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _opTypeMeta = const VerificationMeta('opType');
  @override
  late final GeneratedColumn<String> opType = GeneratedColumn<String>(
    'op_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityIdMeta = const VerificationMeta(
    'entityId',
  );
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
    'entity_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _authorDeviceMeta = const VerificationMeta(
    'authorDevice',
  );
  @override
  late final GeneratedColumn<String> authorDevice = GeneratedColumn<String>(
    'author_device',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lamportTsMeta = const VerificationMeta(
    'lamportTs',
  );
  @override
  late final GeneratedColumn<int> lamportTs = GeneratedColumn<int>(
    'lamport_ts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deviceCounterMeta = const VerificationMeta(
    'deviceCounter',
  );
  @override
  late final GeneratedColumn<int> deviceCounter = GeneratedColumn<int>(
    'device_counter',
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
    tripId,
    opType,
    entityId,
    payload,
    authorDevice,
    lamportTs,
    deviceCounter,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'op_logs';
  @override
  VerificationContext validateIntegrity(
    Insertable<OpLogRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('trip_id')) {
      context.handle(
        _tripIdMeta,
        tripId.isAcceptableOrUnknown(data['trip_id']!, _tripIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tripIdMeta);
    }
    if (data.containsKey('op_type')) {
      context.handle(
        _opTypeMeta,
        opType.isAcceptableOrUnknown(data['op_type']!, _opTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_opTypeMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(
        _entityIdMeta,
        entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('author_device')) {
      context.handle(
        _authorDeviceMeta,
        authorDevice.isAcceptableOrUnknown(
          data['author_device']!,
          _authorDeviceMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_authorDeviceMeta);
    }
    if (data.containsKey('lamport_ts')) {
      context.handle(
        _lamportTsMeta,
        lamportTs.isAcceptableOrUnknown(data['lamport_ts']!, _lamportTsMeta),
      );
    } else if (isInserting) {
      context.missing(_lamportTsMeta);
    }
    if (data.containsKey('device_counter')) {
      context.handle(
        _deviceCounterMeta,
        deviceCounter.isAcceptableOrUnknown(
          data['device_counter']!,
          _deviceCounterMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_deviceCounterMeta);
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
  OpLogRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OpLogRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      tripId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}trip_id'],
      )!,
      opType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}op_type'],
      )!,
      entityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_id'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      authorDevice: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}author_device'],
      )!,
      lamportTs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}lamport_ts'],
      )!,
      deviceCounter: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}device_counter'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $OpLogsTable createAlias(String alias) {
    return $OpLogsTable(attachedDatabase, alias);
  }
}

class OpLogRow extends DataClass implements Insertable<OpLogRow> {
  final String id;
  final String tripId;
  final String opType;
  final String entityId;
  final String payload;
  final String authorDevice;
  final int lamportTs;
  final int deviceCounter;
  final DateTime createdAt;
  const OpLogRow({
    required this.id,
    required this.tripId,
    required this.opType,
    required this.entityId,
    required this.payload,
    required this.authorDevice,
    required this.lamportTs,
    required this.deviceCounter,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['trip_id'] = Variable<String>(tripId);
    map['op_type'] = Variable<String>(opType);
    map['entity_id'] = Variable<String>(entityId);
    map['payload'] = Variable<String>(payload);
    map['author_device'] = Variable<String>(authorDevice);
    map['lamport_ts'] = Variable<int>(lamportTs);
    map['device_counter'] = Variable<int>(deviceCounter);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  OpLogsCompanion toCompanion(bool nullToAbsent) {
    return OpLogsCompanion(
      id: Value(id),
      tripId: Value(tripId),
      opType: Value(opType),
      entityId: Value(entityId),
      payload: Value(payload),
      authorDevice: Value(authorDevice),
      lamportTs: Value(lamportTs),
      deviceCounter: Value(deviceCounter),
      createdAt: Value(createdAt),
    );
  }

  factory OpLogRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OpLogRow(
      id: serializer.fromJson<String>(json['id']),
      tripId: serializer.fromJson<String>(json['tripId']),
      opType: serializer.fromJson<String>(json['opType']),
      entityId: serializer.fromJson<String>(json['entityId']),
      payload: serializer.fromJson<String>(json['payload']),
      authorDevice: serializer.fromJson<String>(json['authorDevice']),
      lamportTs: serializer.fromJson<int>(json['lamportTs']),
      deviceCounter: serializer.fromJson<int>(json['deviceCounter']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'tripId': serializer.toJson<String>(tripId),
      'opType': serializer.toJson<String>(opType),
      'entityId': serializer.toJson<String>(entityId),
      'payload': serializer.toJson<String>(payload),
      'authorDevice': serializer.toJson<String>(authorDevice),
      'lamportTs': serializer.toJson<int>(lamportTs),
      'deviceCounter': serializer.toJson<int>(deviceCounter),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  OpLogRow copyWith({
    String? id,
    String? tripId,
    String? opType,
    String? entityId,
    String? payload,
    String? authorDevice,
    int? lamportTs,
    int? deviceCounter,
    DateTime? createdAt,
  }) => OpLogRow(
    id: id ?? this.id,
    tripId: tripId ?? this.tripId,
    opType: opType ?? this.opType,
    entityId: entityId ?? this.entityId,
    payload: payload ?? this.payload,
    authorDevice: authorDevice ?? this.authorDevice,
    lamportTs: lamportTs ?? this.lamportTs,
    deviceCounter: deviceCounter ?? this.deviceCounter,
    createdAt: createdAt ?? this.createdAt,
  );
  OpLogRow copyWithCompanion(OpLogsCompanion data) {
    return OpLogRow(
      id: data.id.present ? data.id.value : this.id,
      tripId: data.tripId.present ? data.tripId.value : this.tripId,
      opType: data.opType.present ? data.opType.value : this.opType,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      payload: data.payload.present ? data.payload.value : this.payload,
      authorDevice: data.authorDevice.present
          ? data.authorDevice.value
          : this.authorDevice,
      lamportTs: data.lamportTs.present ? data.lamportTs.value : this.lamportTs,
      deviceCounter: data.deviceCounter.present
          ? data.deviceCounter.value
          : this.deviceCounter,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OpLogRow(')
          ..write('id: $id, ')
          ..write('tripId: $tripId, ')
          ..write('opType: $opType, ')
          ..write('entityId: $entityId, ')
          ..write('payload: $payload, ')
          ..write('authorDevice: $authorDevice, ')
          ..write('lamportTs: $lamportTs, ')
          ..write('deviceCounter: $deviceCounter, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    tripId,
    opType,
    entityId,
    payload,
    authorDevice,
    lamportTs,
    deviceCounter,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OpLogRow &&
          other.id == this.id &&
          other.tripId == this.tripId &&
          other.opType == this.opType &&
          other.entityId == this.entityId &&
          other.payload == this.payload &&
          other.authorDevice == this.authorDevice &&
          other.lamportTs == this.lamportTs &&
          other.deviceCounter == this.deviceCounter &&
          other.createdAt == this.createdAt);
}

class OpLogsCompanion extends UpdateCompanion<OpLogRow> {
  final Value<String> id;
  final Value<String> tripId;
  final Value<String> opType;
  final Value<String> entityId;
  final Value<String> payload;
  final Value<String> authorDevice;
  final Value<int> lamportTs;
  final Value<int> deviceCounter;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const OpLogsCompanion({
    this.id = const Value.absent(),
    this.tripId = const Value.absent(),
    this.opType = const Value.absent(),
    this.entityId = const Value.absent(),
    this.payload = const Value.absent(),
    this.authorDevice = const Value.absent(),
    this.lamportTs = const Value.absent(),
    this.deviceCounter = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OpLogsCompanion.insert({
    required String id,
    required String tripId,
    required String opType,
    required String entityId,
    required String payload,
    required String authorDevice,
    required int lamportTs,
    required int deviceCounter,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       tripId = Value(tripId),
       opType = Value(opType),
       entityId = Value(entityId),
       payload = Value(payload),
       authorDevice = Value(authorDevice),
       lamportTs = Value(lamportTs),
       deviceCounter = Value(deviceCounter),
       createdAt = Value(createdAt);
  static Insertable<OpLogRow> custom({
    Expression<String>? id,
    Expression<String>? tripId,
    Expression<String>? opType,
    Expression<String>? entityId,
    Expression<String>? payload,
    Expression<String>? authorDevice,
    Expression<int>? lamportTs,
    Expression<int>? deviceCounter,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (tripId != null) 'trip_id': tripId,
      if (opType != null) 'op_type': opType,
      if (entityId != null) 'entity_id': entityId,
      if (payload != null) 'payload': payload,
      if (authorDevice != null) 'author_device': authorDevice,
      if (lamportTs != null) 'lamport_ts': lamportTs,
      if (deviceCounter != null) 'device_counter': deviceCounter,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OpLogsCompanion copyWith({
    Value<String>? id,
    Value<String>? tripId,
    Value<String>? opType,
    Value<String>? entityId,
    Value<String>? payload,
    Value<String>? authorDevice,
    Value<int>? lamportTs,
    Value<int>? deviceCounter,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return OpLogsCompanion(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      opType: opType ?? this.opType,
      entityId: entityId ?? this.entityId,
      payload: payload ?? this.payload,
      authorDevice: authorDevice ?? this.authorDevice,
      lamportTs: lamportTs ?? this.lamportTs,
      deviceCounter: deviceCounter ?? this.deviceCounter,
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
    if (tripId.present) {
      map['trip_id'] = Variable<String>(tripId.value);
    }
    if (opType.present) {
      map['op_type'] = Variable<String>(opType.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (authorDevice.present) {
      map['author_device'] = Variable<String>(authorDevice.value);
    }
    if (lamportTs.present) {
      map['lamport_ts'] = Variable<int>(lamportTs.value);
    }
    if (deviceCounter.present) {
      map['device_counter'] = Variable<int>(deviceCounter.value);
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
    return (StringBuffer('OpLogsCompanion(')
          ..write('id: $id, ')
          ..write('tripId: $tripId, ')
          ..write('opType: $opType, ')
          ..write('entityId: $entityId, ')
          ..write('payload: $payload, ')
          ..write('authorDevice: $authorDevice, ')
          ..write('lamportTs: $lamportTs, ')
          ..write('deviceCounter: $deviceCounter, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $TripsTable trips = $TripsTable(this);
  late final $MembersTable members = $MembersTable(this);
  late final $CategoriesTable categories = $CategoriesTable(this);
  late final $ExpensesTable expenses = $ExpensesTable(this);
  late final $SplitRowsTable splitRows = $SplitRowsTable(this);
  late final $SettlementsTable settlements = $SettlementsTable(this);
  late final $RateCachesTable rateCaches = $RateCachesTable(this);
  late final $OpLogsTable opLogs = $OpLogsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    trips,
    members,
    categories,
    expenses,
    splitRows,
    settlements,
    rateCaches,
    opLogs,
  ];
}

typedef $$TripsTableCreateCompanionBuilder = TripsCompanion Function({
  required String id,
  required String name,
  Value<String> baseCurrency,
  Value<String> inviteCode,
  Value<bool> deleted,
  required DateTime createdAt,
  Value<int> rowid,
});
typedef $$TripsTableUpdateCompanionBuilder = TripsCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String> baseCurrency,
  Value<String> inviteCode,
  Value<bool> deleted,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

final class $$TripsTableReferences
    extends BaseReferences<_$AppDatabase, $TripsTable, TripRow> {
  $$TripsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$MembersTable, List<MemberRow>> _membersRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.members,
    aliasName: 'trips__id__members__trip_id',
  );

  $$MembersTableProcessedTableManager get membersRefs {
    final manager = $$MembersTableTableManager(
      $_db,
      $_db.members,
    ).filter((f) => f.tripId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_membersRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$CategoriesTable, List<CategoryRow>>
  _categoriesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.categories,
    aliasName: 'trips__id__categories__trip_id',
  );

  $$CategoriesTableProcessedTableManager get categoriesRefs {
    final manager = $$CategoriesTableTableManager(
      $_db,
      $_db.categories,
    ).filter((f) => f.tripId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_categoriesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ExpensesTable, List<ExpenseRow>>
  _expensesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.expenses,
    aliasName: 'trips__id__expenses__trip_id',
  );

  $$ExpensesTableProcessedTableManager get expensesRefs {
    final manager = $$ExpensesTableTableManager(
      $_db,
      $_db.expenses,
    ).filter((f) => f.tripId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_expensesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$SettlementsTable, List<SettlementRow>>
  _settlementsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.settlements,
    aliasName: 'trips__id__settlements__trip_id',
  );

  $$SettlementsTableProcessedTableManager get settlementsRefs {
    final manager = $$SettlementsTableTableManager(
      $_db,
      $_db.settlements,
    ).filter((f) => f.tripId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_settlementsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$TripsTableFilterComposer extends Composer<_$AppDatabase, $TripsTable> {
  $$TripsTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get baseCurrency => $composableBuilder(
    column: $table.baseCurrency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get inviteCode => $composableBuilder(
    column: $table.inviteCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> membersRefs(
    Expression<bool> Function($$MembersTableFilterComposer f) f,
  ) {
    final $$MembersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.members,
      getReferencedColumn: (t) => t.tripId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MembersTableFilterComposer(
            $db: $db,
            $table: $db.members,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> categoriesRefs(
    Expression<bool> Function($$CategoriesTableFilterComposer f) f,
  ) {
    final $$CategoriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.tripId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableFilterComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> expensesRefs(
    Expression<bool> Function($$ExpensesTableFilterComposer f) f,
  ) {
    final $$ExpensesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.expenses,
      getReferencedColumn: (t) => t.tripId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExpensesTableFilterComposer(
            $db: $db,
            $table: $db.expenses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> settlementsRefs(
    Expression<bool> Function($$SettlementsTableFilterComposer f) f,
  ) {
    final $$SettlementsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.settlements,
      getReferencedColumn: (t) => t.tripId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SettlementsTableFilterComposer(
            $db: $db,
            $table: $db.settlements,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TripsTableOrderingComposer
    extends Composer<_$AppDatabase, $TripsTable> {
  $$TripsTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get baseCurrency => $composableBuilder(
    column: $table.baseCurrency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get inviteCode => $composableBuilder(
    column: $table.inviteCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TripsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TripsTable> {
  $$TripsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get baseCurrency => $composableBuilder(
    column: $table.baseCurrency,
    builder: (column) => column,
  );

  GeneratedColumn<String> get inviteCode => $composableBuilder(
    column: $table.inviteCode,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> membersRefs<T extends Object>(
    Expression<T> Function($$MembersTableAnnotationComposer a) f,
  ) {
    final $$MembersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.members,
      getReferencedColumn: (t) => t.tripId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MembersTableAnnotationComposer(
            $db: $db,
            $table: $db.members,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> categoriesRefs<T extends Object>(
    Expression<T> Function($$CategoriesTableAnnotationComposer a) f,
  ) {
    final $$CategoriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.tripId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableAnnotationComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> expensesRefs<T extends Object>(
    Expression<T> Function($$ExpensesTableAnnotationComposer a) f,
  ) {
    final $$ExpensesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.expenses,
      getReferencedColumn: (t) => t.tripId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExpensesTableAnnotationComposer(
            $db: $db,
            $table: $db.expenses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> settlementsRefs<T extends Object>(
    Expression<T> Function($$SettlementsTableAnnotationComposer a) f,
  ) {
    final $$SettlementsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.settlements,
      getReferencedColumn: (t) => t.tripId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SettlementsTableAnnotationComposer(
            $db: $db,
            $table: $db.settlements,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TripsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TripsTable,
          TripRow,
          $$TripsTableFilterComposer,
          $$TripsTableOrderingComposer,
          $$TripsTableAnnotationComposer,
          $$TripsTableCreateCompanionBuilder,
          $$TripsTableUpdateCompanionBuilder,
          (TripRow, $$TripsTableReferences),
          TripRow,
          PrefetchHooks Function({
            bool membersRefs,
            bool categoriesRefs,
            bool expensesRefs,
            bool settlementsRefs,
          })
        > {
  $$TripsTableTableManager(_$AppDatabase db, $TripsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TripsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TripsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TripsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> baseCurrency = const Value.absent(),
                Value<String> inviteCode = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TripsCompanion(
                id: id,
                name: name,
                baseCurrency: baseCurrency,
                inviteCode: inviteCode,
                deleted: deleted,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String> baseCurrency = const Value.absent(),
                Value<String> inviteCode = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => TripsCompanion.insert(
                id: id,
                name: name,
                baseCurrency: baseCurrency,
                inviteCode: inviteCode,
                deleted: deleted,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$TripsTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                membersRefs = false,
                categoriesRefs = false,
                expensesRefs = false,
                settlementsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (membersRefs) db.members,
                    if (categoriesRefs) db.categories,
                    if (expensesRefs) db.expenses,
                    if (settlementsRefs) db.settlements,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (membersRefs)
                        await $_getPrefetchedData<
                          TripRow,
                          $TripsTable,
                          MemberRow
                        >(
                          currentTable: table,
                          referencedTable: $$TripsTableReferences
                              ._membersRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TripsTableReferences(db, table, p0).membersRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.tripId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (categoriesRefs)
                        await $_getPrefetchedData<
                          TripRow,
                          $TripsTable,
                          CategoryRow
                        >(
                          currentTable: table,
                          referencedTable: $$TripsTableReferences
                              ._categoriesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TripsTableReferences(
                                db,
                                table,
                                p0,
                              ).categoriesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.tripId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (expensesRefs)
                        await $_getPrefetchedData<
                          TripRow,
                          $TripsTable,
                          ExpenseRow
                        >(
                          currentTable: table,
                          referencedTable: $$TripsTableReferences
                              ._expensesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TripsTableReferences(
                                db,
                                table,
                                p0,
                              ).expensesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.tripId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (settlementsRefs)
                        await $_getPrefetchedData<
                          TripRow,
                          $TripsTable,
                          SettlementRow
                        >(
                          currentTable: table,
                          referencedTable: $$TripsTableReferences
                              ._settlementsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TripsTableReferences(
                                db,
                                table,
                                p0,
                              ).settlementsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.tripId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$TripsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TripsTable,
      TripRow,
      $$TripsTableFilterComposer,
      $$TripsTableOrderingComposer,
      $$TripsTableAnnotationComposer,
      $$TripsTableCreateCompanionBuilder,
      $$TripsTableUpdateCompanionBuilder,
      (TripRow, $$TripsTableReferences),
      TripRow,
      PrefetchHooks Function({
        bool membersRefs,
        bool categoriesRefs,
        bool expensesRefs,
        bool settlementsRefs,
      })
    >;
typedef $$MembersTableCreateCompanionBuilder = MembersCompanion Function({
  required String id,
  required String tripId,
  required String name,
  required String deviceId,
  Value<int> avatarColor,
  required DateTime joinedAt,
  Value<bool> deleted,
  Value<int> rowid,
});
typedef $$MembersTableUpdateCompanionBuilder = MembersCompanion Function({
  Value<String> id,
  Value<String> tripId,
  Value<String> name,
  Value<String> deviceId,
  Value<int> avatarColor,
  Value<DateTime> joinedAt,
  Value<bool> deleted,
  Value<int> rowid,
});

final class $$MembersTableReferences
    extends BaseReferences<_$AppDatabase, $MembersTable, MemberRow> {
  $$MembersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $TripsTable _tripIdTable(_$AppDatabase db) =>
      db.trips.createAlias('members__trip_id__trips__id');

  $$TripsTableProcessedTableManager get tripId {
    final $_column = $_itemColumn<String>('trip_id')!;

    final manager = $$TripsTableTableManager(
      $_db,
      $_db.trips,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_tripIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$ExpensesTable, List<ExpenseRow>>
  _expensesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.expenses,
    aliasName: 'members__id__expenses__author_id',
  );

  $$ExpensesTableProcessedTableManager get expensesRefs {
    final manager = $$ExpensesTableTableManager(
      $_db,
      $_db.expenses,
    ).filter((f) => f.authorId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_expensesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$SplitRowsTable, List<SplitRow>>
  _splitRowsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.splitRows,
    aliasName: 'members__id__split_rows__member_id',
  );

  $$SplitRowsTableProcessedTableManager get splitRowsRefs {
    final manager = $$SplitRowsTableTableManager(
      $_db,
      $_db.splitRows,
    ).filter((f) => f.memberId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_splitRowsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$MembersTableFilterComposer
    extends Composer<_$AppDatabase, $MembersTable> {
  $$MembersTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get avatarColor => $composableBuilder(
    column: $table.avatarColor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get joinedAt => $composableBuilder(
    column: $table.joinedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnFilters(column),
  );

  $$TripsTableFilterComposer get tripId {
    final $$TripsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tripId,
      referencedTable: $db.trips,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TripsTableFilterComposer(
            $db: $db,
            $table: $db.trips,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> expensesRefs(
    Expression<bool> Function($$ExpensesTableFilterComposer f) f,
  ) {
    final $$ExpensesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.expenses,
      getReferencedColumn: (t) => t.authorId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExpensesTableFilterComposer(
            $db: $db,
            $table: $db.expenses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> splitRowsRefs(
    Expression<bool> Function($$SplitRowsTableFilterComposer f) f,
  ) {
    final $$SplitRowsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.splitRows,
      getReferencedColumn: (t) => t.memberId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SplitRowsTableFilterComposer(
            $db: $db,
            $table: $db.splitRows,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$MembersTableOrderingComposer
    extends Composer<_$AppDatabase, $MembersTable> {
  $$MembersTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get avatarColor => $composableBuilder(
    column: $table.avatarColor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get joinedAt => $composableBuilder(
    column: $table.joinedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnOrderings(column),
  );

  $$TripsTableOrderingComposer get tripId {
    final $$TripsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tripId,
      referencedTable: $db.trips,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TripsTableOrderingComposer(
            $db: $db,
            $table: $db.trips,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MembersTableAnnotationComposer
    extends Composer<_$AppDatabase, $MembersTable> {
  $$MembersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<int> get avatarColor => $composableBuilder(
    column: $table.avatarColor,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get joinedAt =>
      $composableBuilder(column: $table.joinedAt, builder: (column) => column);

  GeneratedColumn<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);

  $$TripsTableAnnotationComposer get tripId {
    final $$TripsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tripId,
      referencedTable: $db.trips,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TripsTableAnnotationComposer(
            $db: $db,
            $table: $db.trips,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> expensesRefs<T extends Object>(
    Expression<T> Function($$ExpensesTableAnnotationComposer a) f,
  ) {
    final $$ExpensesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.expenses,
      getReferencedColumn: (t) => t.authorId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExpensesTableAnnotationComposer(
            $db: $db,
            $table: $db.expenses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> splitRowsRefs<T extends Object>(
    Expression<T> Function($$SplitRowsTableAnnotationComposer a) f,
  ) {
    final $$SplitRowsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.splitRows,
      getReferencedColumn: (t) => t.memberId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SplitRowsTableAnnotationComposer(
            $db: $db,
            $table: $db.splitRows,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$MembersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MembersTable,
          MemberRow,
          $$MembersTableFilterComposer,
          $$MembersTableOrderingComposer,
          $$MembersTableAnnotationComposer,
          $$MembersTableCreateCompanionBuilder,
          $$MembersTableUpdateCompanionBuilder,
          (MemberRow, $$MembersTableReferences),
          MemberRow,
          PrefetchHooks Function({
            bool tripId,
            bool expensesRefs,
            bool splitRowsRefs,
          })
        > {
  $$MembersTableTableManager(_$AppDatabase db, $MembersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MembersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MembersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MembersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> tripId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> deviceId = const Value.absent(),
                Value<int> avatarColor = const Value.absent(),
                Value<DateTime> joinedAt = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MembersCompanion(
                id: id,
                tripId: tripId,
                name: name,
                deviceId: deviceId,
                avatarColor: avatarColor,
                joinedAt: joinedAt,
                deleted: deleted,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String tripId,
                required String name,
                required String deviceId,
                Value<int> avatarColor = const Value.absent(),
                required DateTime joinedAt,
                Value<bool> deleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MembersCompanion.insert(
                id: id,
                tripId: tripId,
                name: name,
                deviceId: deviceId,
                avatarColor: avatarColor,
                joinedAt: joinedAt,
                deleted: deleted,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$MembersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({tripId = false, expensesRefs = false, splitRowsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (expensesRefs) db.expenses,
                    if (splitRowsRefs) db.splitRows,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (tripId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.tripId,
                            referencedTable: $$MembersTableReferences
                                ._tripIdTable(db),
                            referencedColumn: $$MembersTableReferences
                                ._tripIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (expensesRefs)
                        await $_getPrefetchedData<
                          MemberRow,
                          $MembersTable,
                          ExpenseRow
                        >(
                          currentTable: table,
                          referencedTable: $$MembersTableReferences
                              ._expensesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$MembersTableReferences(
                                db,
                                table,
                                p0,
                              ).expensesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.authorId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (splitRowsRefs)
                        await $_getPrefetchedData<
                          MemberRow,
                          $MembersTable,
                          SplitRow
                        >(
                          currentTable: table,
                          referencedTable: $$MembersTableReferences
                              ._splitRowsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$MembersTableReferences(
                                db,
                                table,
                                p0,
                              ).splitRowsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.memberId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$MembersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MembersTable,
      MemberRow,
      $$MembersTableFilterComposer,
      $$MembersTableOrderingComposer,
      $$MembersTableAnnotationComposer,
      $$MembersTableCreateCompanionBuilder,
      $$MembersTableUpdateCompanionBuilder,
      (MemberRow, $$MembersTableReferences),
      MemberRow,
      PrefetchHooks Function({
        bool tripId,
        bool expensesRefs,
        bool splitRowsRefs,
      })
    >;
typedef $$CategoriesTableCreateCompanionBuilder = CategoriesCompanion Function({
  required String id,
  required String name,
  Value<String?> tripId,
  Value<bool> isDefault,
  Value<bool> deleted,
  Value<int> rowid,
});
typedef $$CategoriesTableUpdateCompanionBuilder = CategoriesCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String?> tripId,
  Value<bool> isDefault,
  Value<bool> deleted,
  Value<int> rowid,
});

final class $$CategoriesTableReferences
    extends BaseReferences<_$AppDatabase, $CategoriesTable, CategoryRow> {
  $$CategoriesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $TripsTable _tripIdTable(_$AppDatabase db) =>
      db.trips.createAlias('categories__trip_id__trips__id');

  $$TripsTableProcessedTableManager? get tripId {
    final $_column = $_itemColumn<String>('trip_id');
    if ($_column == null) return null;
    final manager = $$TripsTableTableManager(
      $_db,
      $_db.trips,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_tripIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$CategoriesTableFilterComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDefault => $composableBuilder(
    column: $table.isDefault,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnFilters(column),
  );

  $$TripsTableFilterComposer get tripId {
    final $$TripsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tripId,
      referencedTable: $db.trips,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TripsTableFilterComposer(
            $db: $db,
            $table: $db.trips,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CategoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDefault => $composableBuilder(
    column: $table.isDefault,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnOrderings(column),
  );

  $$TripsTableOrderingComposer get tripId {
    final $$TripsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tripId,
      referencedTable: $db.trips,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TripsTableOrderingComposer(
            $db: $db,
            $table: $db.trips,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CategoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<bool> get isDefault =>
      $composableBuilder(column: $table.isDefault, builder: (column) => column);

  GeneratedColumn<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);

  $$TripsTableAnnotationComposer get tripId {
    final $$TripsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tripId,
      referencedTable: $db.trips,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TripsTableAnnotationComposer(
            $db: $db,
            $table: $db.trips,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CategoriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CategoriesTable,
          CategoryRow,
          $$CategoriesTableFilterComposer,
          $$CategoriesTableOrderingComposer,
          $$CategoriesTableAnnotationComposer,
          $$CategoriesTableCreateCompanionBuilder,
          $$CategoriesTableUpdateCompanionBuilder,
          (CategoryRow, $$CategoriesTableReferences),
          CategoryRow,
          PrefetchHooks Function({bool tripId})
        > {
  $$CategoriesTableTableManager(_$AppDatabase db, $CategoriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CategoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> tripId = const Value.absent(),
                Value<bool> isDefault = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CategoriesCompanion(
                id: id,
                name: name,
                tripId: tripId,
                isDefault: isDefault,
                deleted: deleted,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String?> tripId = const Value.absent(),
                Value<bool> isDefault = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CategoriesCompanion.insert(
                id: id,
                name: name,
                tripId: tripId,
                isDefault: isDefault,
                deleted: deleted,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CategoriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({tripId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (tripId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.tripId,
                        referencedTable: $$CategoriesTableReferences
                            ._tripIdTable(db),
                        referencedColumn: $$CategoriesTableReferences
                            ._tripIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$CategoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CategoriesTable,
      CategoryRow,
      $$CategoriesTableFilterComposer,
      $$CategoriesTableOrderingComposer,
      $$CategoriesTableAnnotationComposer,
      $$CategoriesTableCreateCompanionBuilder,
      $$CategoriesTableUpdateCompanionBuilder,
      (CategoryRow, $$CategoriesTableReferences),
      CategoryRow,
      PrefetchHooks Function({bool tripId})
    >;
typedef $$ExpensesTableCreateCompanionBuilder = ExpensesCompanion Function({
  required String id,
  required String tripId,
  required String authorId,
  required String category,
  required double amount,
  required String currency,
  required double convertedAmount,
  required double rateUsed,
  Value<String> note,
  Value<String> splitType,
  required DateTime createdAt,
  Value<DateTime?> editedAt,
  Value<bool> deleted,
  Value<int> rowid,
});
typedef $$ExpensesTableUpdateCompanionBuilder = ExpensesCompanion Function({
  Value<String> id,
  Value<String> tripId,
  Value<String> authorId,
  Value<String> category,
  Value<double> amount,
  Value<String> currency,
  Value<double> convertedAmount,
  Value<double> rateUsed,
  Value<String> note,
  Value<String> splitType,
  Value<DateTime> createdAt,
  Value<DateTime?> editedAt,
  Value<bool> deleted,
  Value<int> rowid,
});

final class $$ExpensesTableReferences
    extends BaseReferences<_$AppDatabase, $ExpensesTable, ExpenseRow> {
  $$ExpensesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $TripsTable _tripIdTable(_$AppDatabase db) =>
      db.trips.createAlias('expenses__trip_id__trips__id');

  $$TripsTableProcessedTableManager get tripId {
    final $_column = $_itemColumn<String>('trip_id')!;

    final manager = $$TripsTableTableManager(
      $_db,
      $_db.trips,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_tripIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $MembersTable _authorIdTable(_$AppDatabase db) =>
      db.members.createAlias('expenses__author_id__members__id');

  $$MembersTableProcessedTableManager get authorId {
    final $_column = $_itemColumn<String>('author_id')!;

    final manager = $$MembersTableTableManager(
      $_db,
      $_db.members,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_authorIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$SplitRowsTable, List<SplitRow>>
  _splitRowsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.splitRows,
    aliasName: 'expenses__id__split_rows__expense_id',
  );

  $$SplitRowsTableProcessedTableManager get splitRowsRefs {
    final manager = $$SplitRowsTableTableManager(
      $_db,
      $_db.splitRows,
    ).filter((f) => f.expenseId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_splitRowsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ExpensesTableFilterComposer
    extends Composer<_$AppDatabase, $ExpensesTable> {
  $$ExpensesTableFilterComposer({
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

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get convertedAmount => $composableBuilder(
    column: $table.convertedAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get rateUsed => $composableBuilder(
    column: $table.rateUsed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get splitType => $composableBuilder(
    column: $table.splitType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get editedAt => $composableBuilder(
    column: $table.editedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnFilters(column),
  );

  $$TripsTableFilterComposer get tripId {
    final $$TripsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tripId,
      referencedTable: $db.trips,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TripsTableFilterComposer(
            $db: $db,
            $table: $db.trips,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$MembersTableFilterComposer get authorId {
    final $$MembersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.authorId,
      referencedTable: $db.members,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MembersTableFilterComposer(
            $db: $db,
            $table: $db.members,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> splitRowsRefs(
    Expression<bool> Function($$SplitRowsTableFilterComposer f) f,
  ) {
    final $$SplitRowsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.splitRows,
      getReferencedColumn: (t) => t.expenseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SplitRowsTableFilterComposer(
            $db: $db,
            $table: $db.splitRows,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ExpensesTableOrderingComposer
    extends Composer<_$AppDatabase, $ExpensesTable> {
  $$ExpensesTableOrderingComposer({
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

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get convertedAmount => $composableBuilder(
    column: $table.convertedAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get rateUsed => $composableBuilder(
    column: $table.rateUsed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get splitType => $composableBuilder(
    column: $table.splitType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get editedAt => $composableBuilder(
    column: $table.editedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnOrderings(column),
  );

  $$TripsTableOrderingComposer get tripId {
    final $$TripsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tripId,
      referencedTable: $db.trips,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TripsTableOrderingComposer(
            $db: $db,
            $table: $db.trips,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$MembersTableOrderingComposer get authorId {
    final $$MembersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.authorId,
      referencedTable: $db.members,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MembersTableOrderingComposer(
            $db: $db,
            $table: $db.members,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ExpensesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ExpensesTable> {
  $$ExpensesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumn<double> get convertedAmount => $composableBuilder(
    column: $table.convertedAmount,
    builder: (column) => column,
  );

  GeneratedColumn<double> get rateUsed =>
      $composableBuilder(column: $table.rateUsed, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<String> get splitType =>
      $composableBuilder(column: $table.splitType, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get editedAt =>
      $composableBuilder(column: $table.editedAt, builder: (column) => column);

  GeneratedColumn<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);

  $$TripsTableAnnotationComposer get tripId {
    final $$TripsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tripId,
      referencedTable: $db.trips,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TripsTableAnnotationComposer(
            $db: $db,
            $table: $db.trips,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$MembersTableAnnotationComposer get authorId {
    final $$MembersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.authorId,
      referencedTable: $db.members,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MembersTableAnnotationComposer(
            $db: $db,
            $table: $db.members,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> splitRowsRefs<T extends Object>(
    Expression<T> Function($$SplitRowsTableAnnotationComposer a) f,
  ) {
    final $$SplitRowsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.splitRows,
      getReferencedColumn: (t) => t.expenseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SplitRowsTableAnnotationComposer(
            $db: $db,
            $table: $db.splitRows,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ExpensesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ExpensesTable,
          ExpenseRow,
          $$ExpensesTableFilterComposer,
          $$ExpensesTableOrderingComposer,
          $$ExpensesTableAnnotationComposer,
          $$ExpensesTableCreateCompanionBuilder,
          $$ExpensesTableUpdateCompanionBuilder,
          (ExpenseRow, $$ExpensesTableReferences),
          ExpenseRow,
          PrefetchHooks Function({
            bool tripId,
            bool authorId,
            bool splitRowsRefs,
          })
        > {
  $$ExpensesTableTableManager(_$AppDatabase db, $ExpensesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExpensesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExpensesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ExpensesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> tripId = const Value.absent(),
                Value<String> authorId = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<double> amount = const Value.absent(),
                Value<String> currency = const Value.absent(),
                Value<double> convertedAmount = const Value.absent(),
                Value<double> rateUsed = const Value.absent(),
                Value<String> note = const Value.absent(),
                Value<String> splitType = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> editedAt = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExpensesCompanion(
                id: id,
                tripId: tripId,
                authorId: authorId,
                category: category,
                amount: amount,
                currency: currency,
                convertedAmount: convertedAmount,
                rateUsed: rateUsed,
                note: note,
                splitType: splitType,
                createdAt: createdAt,
                editedAt: editedAt,
                deleted: deleted,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String tripId,
                required String authorId,
                required String category,
                required double amount,
                required String currency,
                required double convertedAmount,
                required double rateUsed,
                Value<String> note = const Value.absent(),
                Value<String> splitType = const Value.absent(),
                required DateTime createdAt,
                Value<DateTime?> editedAt = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExpensesCompanion.insert(
                id: id,
                tripId: tripId,
                authorId: authorId,
                category: category,
                amount: amount,
                currency: currency,
                convertedAmount: convertedAmount,
                rateUsed: rateUsed,
                note: note,
                splitType: splitType,
                createdAt: createdAt,
                editedAt: editedAt,
                deleted: deleted,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ExpensesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({tripId = false, authorId = false, splitRowsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [if (splitRowsRefs) db.splitRows],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (tripId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.tripId,
                            referencedTable: $$ExpensesTableReferences
                                ._tripIdTable(db),
                            referencedColumn: $$ExpensesTableReferences
                                ._tripIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (authorId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.authorId,
                            referencedTable: $$ExpensesTableReferences
                                ._authorIdTable(db),
                            referencedColumn: $$ExpensesTableReferences
                                ._authorIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (splitRowsRefs)
                        await $_getPrefetchedData<
                          ExpenseRow,
                          $ExpensesTable,
                          SplitRow
                        >(
                          currentTable: table,
                          referencedTable: $$ExpensesTableReferences
                              ._splitRowsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ExpensesTableReferences(
                                db,
                                table,
                                p0,
                              ).splitRowsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.expenseId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$ExpensesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ExpensesTable,
      ExpenseRow,
      $$ExpensesTableFilterComposer,
      $$ExpensesTableOrderingComposer,
      $$ExpensesTableAnnotationComposer,
      $$ExpensesTableCreateCompanionBuilder,
      $$ExpensesTableUpdateCompanionBuilder,
      (ExpenseRow, $$ExpensesTableReferences),
      ExpenseRow,
      PrefetchHooks Function({bool tripId, bool authorId, bool splitRowsRefs})
    >;
typedef $$SplitRowsTableCreateCompanionBuilder = SplitRowsCompanion Function({
  required String id,
  required String expenseId,
  required String memberId,
  required double shareAmount,
  required double shareConverted,
  Value<int> rowid,
});
typedef $$SplitRowsTableUpdateCompanionBuilder = SplitRowsCompanion Function({
  Value<String> id,
  Value<String> expenseId,
  Value<String> memberId,
  Value<double> shareAmount,
  Value<double> shareConverted,
  Value<int> rowid,
});

final class $$SplitRowsTableReferences
    extends BaseReferences<_$AppDatabase, $SplitRowsTable, SplitRow> {
  $$SplitRowsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ExpensesTable _expenseIdTable(_$AppDatabase db) =>
      db.expenses.createAlias('split_rows__expense_id__expenses__id');

  $$ExpensesTableProcessedTableManager get expenseId {
    final $_column = $_itemColumn<String>('expense_id')!;

    final manager = $$ExpensesTableTableManager(
      $_db,
      $_db.expenses,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_expenseIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $MembersTable _memberIdTable(_$AppDatabase db) =>
      db.members.createAlias('split_rows__member_id__members__id');

  $$MembersTableProcessedTableManager get memberId {
    final $_column = $_itemColumn<String>('member_id')!;

    final manager = $$MembersTableTableManager(
      $_db,
      $_db.members,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_memberIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$SplitRowsTableFilterComposer
    extends Composer<_$AppDatabase, $SplitRowsTable> {
  $$SplitRowsTableFilterComposer({
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

  ColumnFilters<double> get shareAmount => $composableBuilder(
    column: $table.shareAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get shareConverted => $composableBuilder(
    column: $table.shareConverted,
    builder: (column) => ColumnFilters(column),
  );

  $$ExpensesTableFilterComposer get expenseId {
    final $$ExpensesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.expenseId,
      referencedTable: $db.expenses,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExpensesTableFilterComposer(
            $db: $db,
            $table: $db.expenses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$MembersTableFilterComposer get memberId {
    final $$MembersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.memberId,
      referencedTable: $db.members,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MembersTableFilterComposer(
            $db: $db,
            $table: $db.members,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SplitRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $SplitRowsTable> {
  $$SplitRowsTableOrderingComposer({
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

  ColumnOrderings<double> get shareAmount => $composableBuilder(
    column: $table.shareAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get shareConverted => $composableBuilder(
    column: $table.shareConverted,
    builder: (column) => ColumnOrderings(column),
  );

  $$ExpensesTableOrderingComposer get expenseId {
    final $$ExpensesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.expenseId,
      referencedTable: $db.expenses,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExpensesTableOrderingComposer(
            $db: $db,
            $table: $db.expenses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$MembersTableOrderingComposer get memberId {
    final $$MembersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.memberId,
      referencedTable: $db.members,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MembersTableOrderingComposer(
            $db: $db,
            $table: $db.members,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SplitRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SplitRowsTable> {
  $$SplitRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<double> get shareAmount => $composableBuilder(
    column: $table.shareAmount,
    builder: (column) => column,
  );

  GeneratedColumn<double> get shareConverted => $composableBuilder(
    column: $table.shareConverted,
    builder: (column) => column,
  );

  $$ExpensesTableAnnotationComposer get expenseId {
    final $$ExpensesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.expenseId,
      referencedTable: $db.expenses,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExpensesTableAnnotationComposer(
            $db: $db,
            $table: $db.expenses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$MembersTableAnnotationComposer get memberId {
    final $$MembersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.memberId,
      referencedTable: $db.members,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MembersTableAnnotationComposer(
            $db: $db,
            $table: $db.members,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SplitRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SplitRowsTable,
          SplitRow,
          $$SplitRowsTableFilterComposer,
          $$SplitRowsTableOrderingComposer,
          $$SplitRowsTableAnnotationComposer,
          $$SplitRowsTableCreateCompanionBuilder,
          $$SplitRowsTableUpdateCompanionBuilder,
          (SplitRow, $$SplitRowsTableReferences),
          SplitRow,
          PrefetchHooks Function({bool expenseId, bool memberId})
        > {
  $$SplitRowsTableTableManager(_$AppDatabase db, $SplitRowsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SplitRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SplitRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SplitRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> expenseId = const Value.absent(),
                Value<String> memberId = const Value.absent(),
                Value<double> shareAmount = const Value.absent(),
                Value<double> shareConverted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SplitRowsCompanion(
                id: id,
                expenseId: expenseId,
                memberId: memberId,
                shareAmount: shareAmount,
                shareConverted: shareConverted,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String expenseId,
                required String memberId,
                required double shareAmount,
                required double shareConverted,
                Value<int> rowid = const Value.absent(),
              }) => SplitRowsCompanion.insert(
                id: id,
                expenseId: expenseId,
                memberId: memberId,
                shareAmount: shareAmount,
                shareConverted: shareConverted,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$SplitRowsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({expenseId = false, memberId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (expenseId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.expenseId,
                        referencedTable: $$SplitRowsTableReferences
                            ._expenseIdTable(db),
                        referencedColumn: $$SplitRowsTableReferences
                            ._expenseIdTable(db)
                            .id,
                      ) as T;
                    }
                    if (memberId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.memberId,
                        referencedTable: $$SplitRowsTableReferences
                            ._memberIdTable(db),
                        referencedColumn: $$SplitRowsTableReferences
                            ._memberIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$SplitRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SplitRowsTable,
      SplitRow,
      $$SplitRowsTableFilterComposer,
      $$SplitRowsTableOrderingComposer,
      $$SplitRowsTableAnnotationComposer,
      $$SplitRowsTableCreateCompanionBuilder,
      $$SplitRowsTableUpdateCompanionBuilder,
      (SplitRow, $$SplitRowsTableReferences),
      SplitRow,
      PrefetchHooks Function({bool expenseId, bool memberId})
    >;
typedef $$SettlementsTableCreateCompanionBuilder =
    SettlementsCompanion Function({
      required String id,
      required String tripId,
      required String fromMemberId,
      required String toMemberId,
      required double amount,
      Value<double?> partialRemaining,
      Value<String> note,
      required DateTime paidAt,
      Value<bool> deleted,
      Value<int> rowid,
    });
typedef $$SettlementsTableUpdateCompanionBuilder =
    SettlementsCompanion Function({
      Value<String> id,
      Value<String> tripId,
      Value<String> fromMemberId,
      Value<String> toMemberId,
      Value<double> amount,
      Value<double?> partialRemaining,
      Value<String> note,
      Value<DateTime> paidAt,
      Value<bool> deleted,
      Value<int> rowid,
    });

final class $$SettlementsTableReferences
    extends BaseReferences<_$AppDatabase, $SettlementsTable, SettlementRow> {
  $$SettlementsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $TripsTable _tripIdTable(_$AppDatabase db) =>
      db.trips.createAlias('settlements__trip_id__trips__id');

  $$TripsTableProcessedTableManager get tripId {
    final $_column = $_itemColumn<String>('trip_id')!;

    final manager = $$TripsTableTableManager(
      $_db,
      $_db.trips,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_tripIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $MembersTable _fromMemberIdTable(_$AppDatabase db) =>
      db.members.createAlias('settlements__from_member_id__members__id');

  $$MembersTableProcessedTableManager get fromMemberId {
    final $_column = $_itemColumn<String>('from_member_id')!;

    final manager = $$MembersTableTableManager(
      $_db,
      $_db.members,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_fromMemberIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $MembersTable _toMemberIdTable(_$AppDatabase db) =>
      db.members.createAlias('settlements__to_member_id__members__id');

  $$MembersTableProcessedTableManager get toMemberId {
    final $_column = $_itemColumn<String>('to_member_id')!;

    final manager = $$MembersTableTableManager(
      $_db,
      $_db.members,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_toMemberIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$SettlementsTableFilterComposer
    extends Composer<_$AppDatabase, $SettlementsTable> {
  $$SettlementsTableFilterComposer({
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

  ColumnFilters<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get partialRemaining => $composableBuilder(
    column: $table.partialRemaining,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get paidAt => $composableBuilder(
    column: $table.paidAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnFilters(column),
  );

  $$TripsTableFilterComposer get tripId {
    final $$TripsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tripId,
      referencedTable: $db.trips,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TripsTableFilterComposer(
            $db: $db,
            $table: $db.trips,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$MembersTableFilterComposer get fromMemberId {
    final $$MembersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.fromMemberId,
      referencedTable: $db.members,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MembersTableFilterComposer(
            $db: $db,
            $table: $db.members,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$MembersTableFilterComposer get toMemberId {
    final $$MembersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.toMemberId,
      referencedTable: $db.members,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MembersTableFilterComposer(
            $db: $db,
            $table: $db.members,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SettlementsTableOrderingComposer
    extends Composer<_$AppDatabase, $SettlementsTable> {
  $$SettlementsTableOrderingComposer({
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

  ColumnOrderings<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get partialRemaining => $composableBuilder(
    column: $table.partialRemaining,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get paidAt => $composableBuilder(
    column: $table.paidAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnOrderings(column),
  );

  $$TripsTableOrderingComposer get tripId {
    final $$TripsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tripId,
      referencedTable: $db.trips,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TripsTableOrderingComposer(
            $db: $db,
            $table: $db.trips,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$MembersTableOrderingComposer get fromMemberId {
    final $$MembersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.fromMemberId,
      referencedTable: $db.members,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MembersTableOrderingComposer(
            $db: $db,
            $table: $db.members,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$MembersTableOrderingComposer get toMemberId {
    final $$MembersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.toMemberId,
      referencedTable: $db.members,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MembersTableOrderingComposer(
            $db: $db,
            $table: $db.members,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SettlementsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SettlementsTable> {
  $$SettlementsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<double> get partialRemaining => $composableBuilder(
    column: $table.partialRemaining,
    builder: (column) => column,
  );

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get paidAt =>
      $composableBuilder(column: $table.paidAt, builder: (column) => column);

  GeneratedColumn<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);

  $$TripsTableAnnotationComposer get tripId {
    final $$TripsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tripId,
      referencedTable: $db.trips,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TripsTableAnnotationComposer(
            $db: $db,
            $table: $db.trips,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$MembersTableAnnotationComposer get fromMemberId {
    final $$MembersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.fromMemberId,
      referencedTable: $db.members,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MembersTableAnnotationComposer(
            $db: $db,
            $table: $db.members,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$MembersTableAnnotationComposer get toMemberId {
    final $$MembersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.toMemberId,
      referencedTable: $db.members,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MembersTableAnnotationComposer(
            $db: $db,
            $table: $db.members,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SettlementsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SettlementsTable,
          SettlementRow,
          $$SettlementsTableFilterComposer,
          $$SettlementsTableOrderingComposer,
          $$SettlementsTableAnnotationComposer,
          $$SettlementsTableCreateCompanionBuilder,
          $$SettlementsTableUpdateCompanionBuilder,
          (SettlementRow, $$SettlementsTableReferences),
          SettlementRow,
          PrefetchHooks Function({
            bool tripId,
            bool fromMemberId,
            bool toMemberId,
          })
        > {
  $$SettlementsTableTableManager(_$AppDatabase db, $SettlementsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettlementsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettlementsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettlementsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> tripId = const Value.absent(),
                Value<String> fromMemberId = const Value.absent(),
                Value<String> toMemberId = const Value.absent(),
                Value<double> amount = const Value.absent(),
                Value<double?> partialRemaining = const Value.absent(),
                Value<String> note = const Value.absent(),
                Value<DateTime> paidAt = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SettlementsCompanion(
                id: id,
                tripId: tripId,
                fromMemberId: fromMemberId,
                toMemberId: toMemberId,
                amount: amount,
                partialRemaining: partialRemaining,
                note: note,
                paidAt: paidAt,
                deleted: deleted,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String tripId,
                required String fromMemberId,
                required String toMemberId,
                required double amount,
                Value<double?> partialRemaining = const Value.absent(),
                Value<String> note = const Value.absent(),
                required DateTime paidAt,
                Value<bool> deleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SettlementsCompanion.insert(
                id: id,
                tripId: tripId,
                fromMemberId: fromMemberId,
                toMemberId: toMemberId,
                amount: amount,
                partialRemaining: partialRemaining,
                note: note,
                paidAt: paidAt,
                deleted: deleted,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$SettlementsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({tripId = false, fromMemberId = false, toMemberId = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (tripId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.tripId,
                            referencedTable: $$SettlementsTableReferences
                                ._tripIdTable(db),
                            referencedColumn: $$SettlementsTableReferences
                                ._tripIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (fromMemberId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.fromMemberId,
                            referencedTable: $$SettlementsTableReferences
                                ._fromMemberIdTable(db),
                            referencedColumn: $$SettlementsTableReferences
                                ._fromMemberIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (toMemberId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.toMemberId,
                            referencedTable: $$SettlementsTableReferences
                                ._toMemberIdTable(db),
                            referencedColumn: $$SettlementsTableReferences
                                ._toMemberIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [];
                  },
                );
              },
        ),
      );
}

typedef $$SettlementsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SettlementsTable,
      SettlementRow,
      $$SettlementsTableFilterComposer,
      $$SettlementsTableOrderingComposer,
      $$SettlementsTableAnnotationComposer,
      $$SettlementsTableCreateCompanionBuilder,
      $$SettlementsTableUpdateCompanionBuilder,
      (SettlementRow, $$SettlementsTableReferences),
      SettlementRow,
      PrefetchHooks Function({bool tripId, bool fromMemberId, bool toMemberId})
    >;
typedef $$RateCachesTableCreateCompanionBuilder = RateCachesCompanion Function({
  Value<int> id,
  required String baseCurrency,
  required String currency,
  required double rateInBase,
  Value<String> source,
  required DateTime fetchedAt,
});
typedef $$RateCachesTableUpdateCompanionBuilder = RateCachesCompanion Function({
  Value<int> id,
  Value<String> baseCurrency,
  Value<String> currency,
  Value<double> rateInBase,
  Value<String> source,
  Value<DateTime> fetchedAt,
});

class $$RateCachesTableFilterComposer
    extends Composer<_$AppDatabase, $RateCachesTable> {
  $$RateCachesTableFilterComposer({
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

  ColumnFilters<String> get baseCurrency => $composableBuilder(
    column: $table.baseCurrency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get rateInBase => $composableBuilder(
    column: $table.rateInBase,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RateCachesTableOrderingComposer
    extends Composer<_$AppDatabase, $RateCachesTable> {
  $$RateCachesTableOrderingComposer({
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

  ColumnOrderings<String> get baseCurrency => $composableBuilder(
    column: $table.baseCurrency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get rateInBase => $composableBuilder(
    column: $table.rateInBase,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RateCachesTableAnnotationComposer
    extends Composer<_$AppDatabase, $RateCachesTable> {
  $$RateCachesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get baseCurrency => $composableBuilder(
    column: $table.baseCurrency,
    builder: (column) => column,
  );

  GeneratedColumn<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumn<double> get rateInBase => $composableBuilder(
    column: $table.rateInBase,
    builder: (column) => column,
  );

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<DateTime> get fetchedAt =>
      $composableBuilder(column: $table.fetchedAt, builder: (column) => column);
}

class $$RateCachesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RateCachesTable,
          RateCacheRow,
          $$RateCachesTableFilterComposer,
          $$RateCachesTableOrderingComposer,
          $$RateCachesTableAnnotationComposer,
          $$RateCachesTableCreateCompanionBuilder,
          $$RateCachesTableUpdateCompanionBuilder,
          (
            RateCacheRow,
            BaseReferences<_$AppDatabase, $RateCachesTable, RateCacheRow>,
          ),
          RateCacheRow,
          PrefetchHooks Function()
        > {
  $$RateCachesTableTableManager(_$AppDatabase db, $RateCachesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RateCachesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RateCachesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RateCachesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> baseCurrency = const Value.absent(),
                Value<String> currency = const Value.absent(),
                Value<double> rateInBase = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<DateTime> fetchedAt = const Value.absent(),
              }) => RateCachesCompanion(
                id: id,
                baseCurrency: baseCurrency,
                currency: currency,
                rateInBase: rateInBase,
                source: source,
                fetchedAt: fetchedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String baseCurrency,
                required String currency,
                required double rateInBase,
                Value<String> source = const Value.absent(),
                required DateTime fetchedAt,
              }) => RateCachesCompanion.insert(
                id: id,
                baseCurrency: baseCurrency,
                currency: currency,
                rateInBase: rateInBase,
                source: source,
                fetchedAt: fetchedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RateCachesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RateCachesTable,
      RateCacheRow,
      $$RateCachesTableFilterComposer,
      $$RateCachesTableOrderingComposer,
      $$RateCachesTableAnnotationComposer,
      $$RateCachesTableCreateCompanionBuilder,
      $$RateCachesTableUpdateCompanionBuilder,
      (
        RateCacheRow,
        BaseReferences<_$AppDatabase, $RateCachesTable, RateCacheRow>,
      ),
      RateCacheRow,
      PrefetchHooks Function()
    >;
typedef $$OpLogsTableCreateCompanionBuilder = OpLogsCompanion Function({
  required String id,
  required String tripId,
  required String opType,
  required String entityId,
  required String payload,
  required String authorDevice,
  required int lamportTs,
  required int deviceCounter,
  required DateTime createdAt,
  Value<int> rowid,
});
typedef $$OpLogsTableUpdateCompanionBuilder = OpLogsCompanion Function({
  Value<String> id,
  Value<String> tripId,
  Value<String> opType,
  Value<String> entityId,
  Value<String> payload,
  Value<String> authorDevice,
  Value<int> lamportTs,
  Value<int> deviceCounter,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

class $$OpLogsTableFilterComposer
    extends Composer<_$AppDatabase, $OpLogsTable> {
  $$OpLogsTableFilterComposer({
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

  ColumnFilters<String> get tripId => $composableBuilder(
    column: $table.tripId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get opType => $composableBuilder(
    column: $table.opType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get authorDevice => $composableBuilder(
    column: $table.authorDevice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lamportTs => $composableBuilder(
    column: $table.lamportTs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deviceCounter => $composableBuilder(
    column: $table.deviceCounter,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$OpLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $OpLogsTable> {
  $$OpLogsTableOrderingComposer({
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

  ColumnOrderings<String> get tripId => $composableBuilder(
    column: $table.tripId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get opType => $composableBuilder(
    column: $table.opType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get authorDevice => $composableBuilder(
    column: $table.authorDevice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lamportTs => $composableBuilder(
    column: $table.lamportTs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deviceCounter => $composableBuilder(
    column: $table.deviceCounter,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OpLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $OpLogsTable> {
  $$OpLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get tripId =>
      $composableBuilder(column: $table.tripId, builder: (column) => column);

  GeneratedColumn<String> get opType =>
      $composableBuilder(column: $table.opType, builder: (column) => column);

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<String> get authorDevice => $composableBuilder(
    column: $table.authorDevice,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lamportTs =>
      $composableBuilder(column: $table.lamportTs, builder: (column) => column);

  GeneratedColumn<int> get deviceCounter => $composableBuilder(
    column: $table.deviceCounter,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$OpLogsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OpLogsTable,
          OpLogRow,
          $$OpLogsTableFilterComposer,
          $$OpLogsTableOrderingComposer,
          $$OpLogsTableAnnotationComposer,
          $$OpLogsTableCreateCompanionBuilder,
          $$OpLogsTableUpdateCompanionBuilder,
          (OpLogRow, BaseReferences<_$AppDatabase, $OpLogsTable, OpLogRow>),
          OpLogRow,
          PrefetchHooks Function()
        > {
  $$OpLogsTableTableManager(_$AppDatabase db, $OpLogsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OpLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OpLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OpLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> tripId = const Value.absent(),
                Value<String> opType = const Value.absent(),
                Value<String> entityId = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<String> authorDevice = const Value.absent(),
                Value<int> lamportTs = const Value.absent(),
                Value<int> deviceCounter = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OpLogsCompanion(
                id: id,
                tripId: tripId,
                opType: opType,
                entityId: entityId,
                payload: payload,
                authorDevice: authorDevice,
                lamportTs: lamportTs,
                deviceCounter: deviceCounter,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String tripId,
                required String opType,
                required String entityId,
                required String payload,
                required String authorDevice,
                required int lamportTs,
                required int deviceCounter,
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => OpLogsCompanion.insert(
                id: id,
                tripId: tripId,
                opType: opType,
                entityId: entityId,
                payload: payload,
                authorDevice: authorDevice,
                lamportTs: lamportTs,
                deviceCounter: deviceCounter,
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

typedef $$OpLogsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OpLogsTable,
      OpLogRow,
      $$OpLogsTableFilterComposer,
      $$OpLogsTableOrderingComposer,
      $$OpLogsTableAnnotationComposer,
      $$OpLogsTableCreateCompanionBuilder,
      $$OpLogsTableUpdateCompanionBuilder,
      (OpLogRow, BaseReferences<_$AppDatabase, $OpLogsTable, OpLogRow>),
      OpLogRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$TripsTableTableManager get trips =>
      $$TripsTableTableManager(_db, _db.trips);
  $$MembersTableTableManager get members =>
      $$MembersTableTableManager(_db, _db.members);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db, _db.categories);
  $$ExpensesTableTableManager get expenses =>
      $$ExpensesTableTableManager(_db, _db.expenses);
  $$SplitRowsTableTableManager get splitRows =>
      $$SplitRowsTableTableManager(_db, _db.splitRows);
  $$SettlementsTableTableManager get settlements =>
      $$SettlementsTableTableManager(_db, _db.settlements);
  $$RateCachesTableTableManager get rateCaches =>
      $$RateCachesTableTableManager(_db, _db.rateCaches);
  $$OpLogsTableTableManager get opLogs =>
      $$OpLogsTableTableManager(_db, _db.opLogs);
}
