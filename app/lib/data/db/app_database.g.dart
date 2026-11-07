// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $ProjectsTable extends Projects with TableInfo<$ProjectsTable, Project> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProjectsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _updatedAtMeta = const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _remoteIdMeta = const VerificationMeta('remoteId');
  @override
  late final GeneratedColumn<String> remoteId = GeneratedColumn<String>(
    'remote_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
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
    additionalChecks: GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 100),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _storyMeta = const VerificationMeta('story');
  @override
  late final GeneratedColumn<String> story = GeneratedColumn<String>(
    'story',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [updatedAt, remoteId, id, title, story, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'projects';
  @override
  VerificationContext validateIntegrity(Insertable<Project> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('remote_id')) {
      context.handle(
        _remoteIdMeta,
        remoteId.isAcceptableOrUnknown(data['remote_id']!, _remoteIdMeta),
      );
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(_titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('story')) {
      context.handle(_storyMeta, story.isAcceptableOrUnknown(data['story']!, _storyMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Project map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Project(
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      remoteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_id'],
      ),
      id: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      story: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}story'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $ProjectsTable createAlias(String alias) {
    return $ProjectsTable(attachedDatabase, alias);
  }
}

class Project extends DataClass implements Insertable<Project> {
  final DateTime updatedAt;
  final String? remoteId;
  final String id;
  final String title;
  final String story;
  final DateTime createdAt;
  const Project({
    required this.updatedAt,
    this.remoteId,
    required this.id,
    required this.title,
    required this.story,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || remoteId != null) {
      map['remote_id'] = Variable<String>(remoteId);
    }
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    map['story'] = Variable<String>(story);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ProjectsCompanion toCompanion(bool nullToAbsent) {
    return ProjectsCompanion(
      updatedAt: Value(updatedAt),
      remoteId: remoteId == null && nullToAbsent ? const Value.absent() : Value(remoteId),
      id: Value(id),
      title: Value(title),
      story: Value(story),
      createdAt: Value(createdAt),
    );
  }

  factory Project.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Project(
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      remoteId: serializer.fromJson<String?>(json['remoteId']),
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      story: serializer.fromJson<String>(json['story']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'remoteId': serializer.toJson<String?>(remoteId),
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'story': serializer.toJson<String>(story),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Project copyWith({
    DateTime? updatedAt,
    Value<String?> remoteId = const Value.absent(),
    String? id,
    String? title,
    String? story,
    DateTime? createdAt,
  }) => Project(
    updatedAt: updatedAt ?? this.updatedAt,
    remoteId: remoteId.present ? remoteId.value : this.remoteId,
    id: id ?? this.id,
    title: title ?? this.title,
    story: story ?? this.story,
    createdAt: createdAt ?? this.createdAt,
  );
  Project copyWithCompanion(ProjectsCompanion data) {
    return Project(
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      remoteId: data.remoteId.present ? data.remoteId.value : this.remoteId,
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      story: data.story.present ? data.story.value : this.story,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Project(')
          ..write('updatedAt: $updatedAt, ')
          ..write('remoteId: $remoteId, ')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('story: $story, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(updatedAt, remoteId, id, title, story, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Project &&
          other.updatedAt == this.updatedAt &&
          other.remoteId == this.remoteId &&
          other.id == this.id &&
          other.title == this.title &&
          other.story == this.story &&
          other.createdAt == this.createdAt);
}

class ProjectsCompanion extends UpdateCompanion<Project> {
  final Value<DateTime> updatedAt;
  final Value<String?> remoteId;
  final Value<String> id;
  final Value<String> title;
  final Value<String> story;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const ProjectsCompanion({
    this.updatedAt = const Value.absent(),
    this.remoteId = const Value.absent(),
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.story = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProjectsCompanion.insert({
    this.updatedAt = const Value.absent(),
    this.remoteId = const Value.absent(),
    required String id,
    required String title,
    this.story = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title);
  static Insertable<Project> custom({
    Expression<DateTime>? updatedAt,
    Expression<String>? remoteId,
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? story,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (updatedAt != null) 'updated_at': updatedAt,
      if (remoteId != null) 'remote_id': remoteId,
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (story != null) 'story': story,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProjectsCompanion copyWith({
    Value<DateTime>? updatedAt,
    Value<String?>? remoteId,
    Value<String>? id,
    Value<String>? title,
    Value<String>? story,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return ProjectsCompanion(
      updatedAt: updatedAt ?? this.updatedAt,
      remoteId: remoteId ?? this.remoteId,
      id: id ?? this.id,
      title: title ?? this.title,
      story: story ?? this.story,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (remoteId.present) {
      map['remote_id'] = Variable<String>(remoteId.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (story.present) {
      map['story'] = Variable<String>(story.value);
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
    return (StringBuffer('ProjectsCompanion(')
          ..write('updatedAt: $updatedAt, ')
          ..write('remoteId: $remoteId, ')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('story: $story, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CharacterCardsTable extends CharacterCards
    with TableInfo<$CharacterCardsTable, CharacterCard> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CharacterCardsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _updatedAtMeta = const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _remoteIdMeta = const VerificationMeta('remoteId');
  @override
  late final GeneratedColumn<String> remoteId = GeneratedColumn<String>(
    'remote_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _projectIdMeta = const VerificationMeta('projectId');
  @override
  late final GeneratedColumn<String> projectId = GeneratedColumn<String>(
    'project_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES projects (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 20),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _appearanceMeta = const VerificationMeta('appearance');
  @override
  late final GeneratedColumn<String> appearance = GeneratedColumn<String>(
    'appearance',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _outfitMeta = const VerificationMeta('outfit');
  @override
  late final GeneratedColumn<String> outfit = GeneratedColumn<String>(
    'outfit',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  List<GeneratedColumn> get $columns => [
    updatedAt,
    remoteId,
    id,
    projectId,
    name,
    appearance,
    outfit,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'character_cards';
  @override
  VerificationContext validateIntegrity(
    Insertable<CharacterCard> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('remote_id')) {
      context.handle(
        _remoteIdMeta,
        remoteId.isAcceptableOrUnknown(data['remote_id']!, _remoteIdMeta),
      );
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('project_id')) {
      context.handle(
        _projectIdMeta,
        projectId.isAcceptableOrUnknown(data['project_id']!, _projectIdMeta),
      );
    } else if (isInserting) {
      context.missing(_projectIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(_nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('appearance')) {
      context.handle(
        _appearanceMeta,
        appearance.isAcceptableOrUnknown(data['appearance']!, _appearanceMeta),
      );
    }
    if (data.containsKey('outfit')) {
      context.handle(_outfitMeta, outfit.isAcceptableOrUnknown(data['outfit']!, _outfitMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CharacterCard map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CharacterCard(
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      remoteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_id'],
      ),
      id: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      projectId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}project_id'],
      )!,
      name: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      appearance: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}appearance'],
      )!,
      outfit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}outfit'],
      )!,
    );
  }

  @override
  $CharacterCardsTable createAlias(String alias) {
    return $CharacterCardsTable(attachedDatabase, alias);
  }
}

class CharacterCard extends DataClass implements Insertable<CharacterCard> {
  final DateTime updatedAt;
  final String? remoteId;
  final String id;
  final String projectId;
  final String name;
  final String appearance;
  final String outfit;
  const CharacterCard({
    required this.updatedAt,
    this.remoteId,
    required this.id,
    required this.projectId,
    required this.name,
    required this.appearance,
    required this.outfit,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || remoteId != null) {
      map['remote_id'] = Variable<String>(remoteId);
    }
    map['id'] = Variable<String>(id);
    map['project_id'] = Variable<String>(projectId);
    map['name'] = Variable<String>(name);
    map['appearance'] = Variable<String>(appearance);
    map['outfit'] = Variable<String>(outfit);
    return map;
  }

  CharacterCardsCompanion toCompanion(bool nullToAbsent) {
    return CharacterCardsCompanion(
      updatedAt: Value(updatedAt),
      remoteId: remoteId == null && nullToAbsent ? const Value.absent() : Value(remoteId),
      id: Value(id),
      projectId: Value(projectId),
      name: Value(name),
      appearance: Value(appearance),
      outfit: Value(outfit),
    );
  }

  factory CharacterCard.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CharacterCard(
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      remoteId: serializer.fromJson<String?>(json['remoteId']),
      id: serializer.fromJson<String>(json['id']),
      projectId: serializer.fromJson<String>(json['projectId']),
      name: serializer.fromJson<String>(json['name']),
      appearance: serializer.fromJson<String>(json['appearance']),
      outfit: serializer.fromJson<String>(json['outfit']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'remoteId': serializer.toJson<String?>(remoteId),
      'id': serializer.toJson<String>(id),
      'projectId': serializer.toJson<String>(projectId),
      'name': serializer.toJson<String>(name),
      'appearance': serializer.toJson<String>(appearance),
      'outfit': serializer.toJson<String>(outfit),
    };
  }

  CharacterCard copyWith({
    DateTime? updatedAt,
    Value<String?> remoteId = const Value.absent(),
    String? id,
    String? projectId,
    String? name,
    String? appearance,
    String? outfit,
  }) => CharacterCard(
    updatedAt: updatedAt ?? this.updatedAt,
    remoteId: remoteId.present ? remoteId.value : this.remoteId,
    id: id ?? this.id,
    projectId: projectId ?? this.projectId,
    name: name ?? this.name,
    appearance: appearance ?? this.appearance,
    outfit: outfit ?? this.outfit,
  );
  CharacterCard copyWithCompanion(CharacterCardsCompanion data) {
    return CharacterCard(
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      remoteId: data.remoteId.present ? data.remoteId.value : this.remoteId,
      id: data.id.present ? data.id.value : this.id,
      projectId: data.projectId.present ? data.projectId.value : this.projectId,
      name: data.name.present ? data.name.value : this.name,
      appearance: data.appearance.present ? data.appearance.value : this.appearance,
      outfit: data.outfit.present ? data.outfit.value : this.outfit,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CharacterCard(')
          ..write('updatedAt: $updatedAt, ')
          ..write('remoteId: $remoteId, ')
          ..write('id: $id, ')
          ..write('projectId: $projectId, ')
          ..write('name: $name, ')
          ..write('appearance: $appearance, ')
          ..write('outfit: $outfit')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(updatedAt, remoteId, id, projectId, name, appearance, outfit);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CharacterCard &&
          other.updatedAt == this.updatedAt &&
          other.remoteId == this.remoteId &&
          other.id == this.id &&
          other.projectId == this.projectId &&
          other.name == this.name &&
          other.appearance == this.appearance &&
          other.outfit == this.outfit);
}

class CharacterCardsCompanion extends UpdateCompanion<CharacterCard> {
  final Value<DateTime> updatedAt;
  final Value<String?> remoteId;
  final Value<String> id;
  final Value<String> projectId;
  final Value<String> name;
  final Value<String> appearance;
  final Value<String> outfit;
  final Value<int> rowid;
  const CharacterCardsCompanion({
    this.updatedAt = const Value.absent(),
    this.remoteId = const Value.absent(),
    this.id = const Value.absent(),
    this.projectId = const Value.absent(),
    this.name = const Value.absent(),
    this.appearance = const Value.absent(),
    this.outfit = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CharacterCardsCompanion.insert({
    this.updatedAt = const Value.absent(),
    this.remoteId = const Value.absent(),
    required String id,
    required String projectId,
    required String name,
    this.appearance = const Value.absent(),
    this.outfit = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       projectId = Value(projectId),
       name = Value(name);
  static Insertable<CharacterCard> custom({
    Expression<DateTime>? updatedAt,
    Expression<String>? remoteId,
    Expression<String>? id,
    Expression<String>? projectId,
    Expression<String>? name,
    Expression<String>? appearance,
    Expression<String>? outfit,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (updatedAt != null) 'updated_at': updatedAt,
      if (remoteId != null) 'remote_id': remoteId,
      if (id != null) 'id': id,
      if (projectId != null) 'project_id': projectId,
      if (name != null) 'name': name,
      if (appearance != null) 'appearance': appearance,
      if (outfit != null) 'outfit': outfit,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CharacterCardsCompanion copyWith({
    Value<DateTime>? updatedAt,
    Value<String?>? remoteId,
    Value<String>? id,
    Value<String>? projectId,
    Value<String>? name,
    Value<String>? appearance,
    Value<String>? outfit,
    Value<int>? rowid,
  }) {
    return CharacterCardsCompanion(
      updatedAt: updatedAt ?? this.updatedAt,
      remoteId: remoteId ?? this.remoteId,
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      name: name ?? this.name,
      appearance: appearance ?? this.appearance,
      outfit: outfit ?? this.outfit,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (remoteId.present) {
      map['remote_id'] = Variable<String>(remoteId.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (projectId.present) {
      map['project_id'] = Variable<String>(projectId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (appearance.present) {
      map['appearance'] = Variable<String>(appearance.value);
    }
    if (outfit.present) {
      map['outfit'] = Variable<String>(outfit.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CharacterCardsCompanion(')
          ..write('updatedAt: $updatedAt, ')
          ..write('remoteId: $remoteId, ')
          ..write('id: $id, ')
          ..write('projectId: $projectId, ')
          ..write('name: $name, ')
          ..write('appearance: $appearance, ')
          ..write('outfit: $outfit, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ShotsTable extends Shots with TableInfo<$ShotsTable, Shot> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ShotsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _updatedAtMeta = const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _remoteIdMeta = const VerificationMeta('remoteId');
  @override
  late final GeneratedColumn<String> remoteId = GeneratedColumn<String>(
    'remote_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _projectIdMeta = const VerificationMeta('projectId');
  @override
  late final GeneratedColumn<String> projectId = GeneratedColumn<String>(
    'project_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES projects (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta('sortOrder');
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<ShotSize, String> shotSize = GeneratedColumn<String>(
    'shot_size',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<ShotSize>($ShotsTable.$convertershotSize);
  static const VerificationMeta _sceneMeta = const VerificationMeta('scene');
  @override
  late final GeneratedColumn<String> scene = GeneratedColumn<String>(
    'scene',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dialogueMeta = const VerificationMeta('dialogue');
  @override
  late final GeneratedColumn<String> dialogue = GeneratedColumn<String>(
    'dialogue',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _reasonMeta = const VerificationMeta('reason');
  @override
  late final GeneratedColumn<String> reason = GeneratedColumn<String>(
    'reason',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  late final GeneratedColumnWithTypeConverter<List<String>, String> characterNames =
      GeneratedColumn<String>(
        'character_names',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('[]'),
      ).withConverter<List<String>>($ShotsTable.$convertercharacterNames);
  @override
  late final GeneratedColumnWithTypeConverter<ShotStatus, String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: Constant(ShotStatus.pending.name),
  ).withConverter<ShotStatus>($ShotsTable.$converterstatus);
  @override
  late final GeneratedColumnWithTypeConverter<CameraMove, String> cameraMove =
      GeneratedColumn<String>(
        'camera_move',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: Constant(CameraMove.fixed.name),
      ).withConverter<CameraMove>($ShotsTable.$convertercameraMove);
  static const VerificationMeta _durationMsMeta = const VerificationMeta('durationMs');
  @override
  late final GeneratedColumn<int> durationMs = GeneratedColumn<int>(
    'duration_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<List<ShotProp>?, String> propsJson =
      GeneratedColumn<String>(
        'props_json',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<List<ShotProp>?>($ShotsTable.$converterpropsJsonn);
  @override
  List<GeneratedColumn> get $columns => [
    updatedAt,
    remoteId,
    id,
    projectId,
    sortOrder,
    shotSize,
    scene,
    dialogue,
    reason,
    characterNames,
    status,
    cameraMove,
    durationMs,
    propsJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'shots';
  @override
  VerificationContext validateIntegrity(Insertable<Shot> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('remote_id')) {
      context.handle(
        _remoteIdMeta,
        remoteId.isAcceptableOrUnknown(data['remote_id']!, _remoteIdMeta),
      );
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('project_id')) {
      context.handle(
        _projectIdMeta,
        projectId.isAcceptableOrUnknown(data['project_id']!, _projectIdMeta),
      );
    } else if (isInserting) {
      context.missing(_projectIdMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    if (data.containsKey('scene')) {
      context.handle(_sceneMeta, scene.isAcceptableOrUnknown(data['scene']!, _sceneMeta));
    } else if (isInserting) {
      context.missing(_sceneMeta);
    }
    if (data.containsKey('dialogue')) {
      context.handle(
        _dialogueMeta,
        dialogue.isAcceptableOrUnknown(data['dialogue']!, _dialogueMeta),
      );
    }
    if (data.containsKey('reason')) {
      context.handle(_reasonMeta, reason.isAcceptableOrUnknown(data['reason']!, _reasonMeta));
    }
    if (data.containsKey('duration_ms')) {
      context.handle(
        _durationMsMeta,
        durationMs.isAcceptableOrUnknown(data['duration_ms']!, _durationMsMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Shot map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Shot(
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      remoteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_id'],
      ),
      id: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      projectId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}project_id'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      shotSize: $ShotsTable.$convertershotSize.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}shot_size'],
        )!,
      ),
      scene: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}scene'],
      )!,
      dialogue: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}dialogue'],
      )!,
      reason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reason'],
      )!,
      characterNames: $ShotsTable.$convertercharacterNames.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}character_names'],
        )!,
      ),
      status: $ShotsTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      ),
      cameraMove: $ShotsTable.$convertercameraMove.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}camera_move'],
        )!,
      ),
      durationMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_ms'],
      ),
      propsJson: $ShotsTable.$converterpropsJsonn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}props_json'],
        ),
      ),
    );
  }

  @override
  $ShotsTable createAlias(String alias) {
    return $ShotsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<ShotSize, String, String> $convertershotSize =
      const EnumNameConverter<ShotSize>(ShotSize.values);
  static TypeConverter<List<String>, String> $convertercharacterNames = const StringListConverter();
  static JsonTypeConverter2<ShotStatus, String, String> $converterstatus =
      const EnumNameConverter<ShotStatus>(ShotStatus.values);
  static JsonTypeConverter2<CameraMove, String, String> $convertercameraMove =
      const EnumNameConverter<CameraMove>(CameraMove.values);
  static TypeConverter<List<ShotProp>, String> $converterpropsJson = const ShotPropListConverter();
  static TypeConverter<List<ShotProp>?, String?> $converterpropsJsonn = NullAwareTypeConverter.wrap(
    $converterpropsJson,
  );
}

class Shot extends DataClass implements Insertable<Shot> {
  final DateTime updatedAt;
  final String? remoteId;
  final String id;
  final String projectId;

  /// 镜头顺序。`order` 是 SQL 关键字，所以叫 sort_order。
  final int sortOrder;
  final ShotSize shotSize;
  final String scene;
  final String dialogue;
  final String reason;

  /// 出场角色名。按名字而不是角色卡 ID 记录：模型输出的就是名字，没建角色卡的人物也要保留；
  /// 拼提示词时再按名字匹配角色卡，角色卡改名时由仓库同步改这里。
  final List<String> characterNames;
  final ShotStatus status;

  /// v3 新增。旧镜头迁移后为「固定」。
  final CameraMove cameraMove;

  /// v3 新增，毫秒。为空时按默认规则推导，不回写。
  final int? durationMs;

  /// v4 新增，镜头里的道具（名字和归属）。为空表示旧数据或模型没给，预演按画面描述的关键词兜底；
  /// 空数组表示模型明确说没有道具。
  final List<ShotProp>? propsJson;
  const Shot({
    required this.updatedAt,
    this.remoteId,
    required this.id,
    required this.projectId,
    required this.sortOrder,
    required this.shotSize,
    required this.scene,
    required this.dialogue,
    required this.reason,
    required this.characterNames,
    required this.status,
    required this.cameraMove,
    this.durationMs,
    this.propsJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || remoteId != null) {
      map['remote_id'] = Variable<String>(remoteId);
    }
    map['id'] = Variable<String>(id);
    map['project_id'] = Variable<String>(projectId);
    map['sort_order'] = Variable<int>(sortOrder);
    {
      map['shot_size'] = Variable<String>($ShotsTable.$convertershotSize.toSql(shotSize));
    }
    map['scene'] = Variable<String>(scene);
    map['dialogue'] = Variable<String>(dialogue);
    map['reason'] = Variable<String>(reason);
    {
      map['character_names'] = Variable<String>(
        $ShotsTable.$convertercharacterNames.toSql(characterNames),
      );
    }
    {
      map['status'] = Variable<String>($ShotsTable.$converterstatus.toSql(status));
    }
    {
      map['camera_move'] = Variable<String>($ShotsTable.$convertercameraMove.toSql(cameraMove));
    }
    if (!nullToAbsent || durationMs != null) {
      map['duration_ms'] = Variable<int>(durationMs);
    }
    if (!nullToAbsent || propsJson != null) {
      map['props_json'] = Variable<String>($ShotsTable.$converterpropsJsonn.toSql(propsJson));
    }
    return map;
  }

  ShotsCompanion toCompanion(bool nullToAbsent) {
    return ShotsCompanion(
      updatedAt: Value(updatedAt),
      remoteId: remoteId == null && nullToAbsent ? const Value.absent() : Value(remoteId),
      id: Value(id),
      projectId: Value(projectId),
      sortOrder: Value(sortOrder),
      shotSize: Value(shotSize),
      scene: Value(scene),
      dialogue: Value(dialogue),
      reason: Value(reason),
      characterNames: Value(characterNames),
      status: Value(status),
      cameraMove: Value(cameraMove),
      durationMs: durationMs == null && nullToAbsent ? const Value.absent() : Value(durationMs),
      propsJson: propsJson == null && nullToAbsent ? const Value.absent() : Value(propsJson),
    );
  }

  factory Shot.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Shot(
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      remoteId: serializer.fromJson<String?>(json['remoteId']),
      id: serializer.fromJson<String>(json['id']),
      projectId: serializer.fromJson<String>(json['projectId']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      shotSize: $ShotsTable.$convertershotSize.fromJson(
        serializer.fromJson<String>(json['shotSize']),
      ),
      scene: serializer.fromJson<String>(json['scene']),
      dialogue: serializer.fromJson<String>(json['dialogue']),
      reason: serializer.fromJson<String>(json['reason']),
      characterNames: serializer.fromJson<List<String>>(json['characterNames']),
      status: $ShotsTable.$converterstatus.fromJson(serializer.fromJson<String>(json['status'])),
      cameraMove: $ShotsTable.$convertercameraMove.fromJson(
        serializer.fromJson<String>(json['cameraMove']),
      ),
      durationMs: serializer.fromJson<int?>(json['durationMs']),
      propsJson: serializer.fromJson<List<ShotProp>?>(json['propsJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'remoteId': serializer.toJson<String?>(remoteId),
      'id': serializer.toJson<String>(id),
      'projectId': serializer.toJson<String>(projectId),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'shotSize': serializer.toJson<String>($ShotsTable.$convertershotSize.toJson(shotSize)),
      'scene': serializer.toJson<String>(scene),
      'dialogue': serializer.toJson<String>(dialogue),
      'reason': serializer.toJson<String>(reason),
      'characterNames': serializer.toJson<List<String>>(characterNames),
      'status': serializer.toJson<String>($ShotsTable.$converterstatus.toJson(status)),
      'cameraMove': serializer.toJson<String>($ShotsTable.$convertercameraMove.toJson(cameraMove)),
      'durationMs': serializer.toJson<int?>(durationMs),
      'propsJson': serializer.toJson<List<ShotProp>?>(propsJson),
    };
  }

  Shot copyWith({
    DateTime? updatedAt,
    Value<String?> remoteId = const Value.absent(),
    String? id,
    String? projectId,
    int? sortOrder,
    ShotSize? shotSize,
    String? scene,
    String? dialogue,
    String? reason,
    List<String>? characterNames,
    ShotStatus? status,
    CameraMove? cameraMove,
    Value<int?> durationMs = const Value.absent(),
    Value<List<ShotProp>?> propsJson = const Value.absent(),
  }) => Shot(
    updatedAt: updatedAt ?? this.updatedAt,
    remoteId: remoteId.present ? remoteId.value : this.remoteId,
    id: id ?? this.id,
    projectId: projectId ?? this.projectId,
    sortOrder: sortOrder ?? this.sortOrder,
    shotSize: shotSize ?? this.shotSize,
    scene: scene ?? this.scene,
    dialogue: dialogue ?? this.dialogue,
    reason: reason ?? this.reason,
    characterNames: characterNames ?? this.characterNames,
    status: status ?? this.status,
    cameraMove: cameraMove ?? this.cameraMove,
    durationMs: durationMs.present ? durationMs.value : this.durationMs,
    propsJson: propsJson.present ? propsJson.value : this.propsJson,
  );
  Shot copyWithCompanion(ShotsCompanion data) {
    return Shot(
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      remoteId: data.remoteId.present ? data.remoteId.value : this.remoteId,
      id: data.id.present ? data.id.value : this.id,
      projectId: data.projectId.present ? data.projectId.value : this.projectId,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      shotSize: data.shotSize.present ? data.shotSize.value : this.shotSize,
      scene: data.scene.present ? data.scene.value : this.scene,
      dialogue: data.dialogue.present ? data.dialogue.value : this.dialogue,
      reason: data.reason.present ? data.reason.value : this.reason,
      characterNames: data.characterNames.present ? data.characterNames.value : this.characterNames,
      status: data.status.present ? data.status.value : this.status,
      cameraMove: data.cameraMove.present ? data.cameraMove.value : this.cameraMove,
      durationMs: data.durationMs.present ? data.durationMs.value : this.durationMs,
      propsJson: data.propsJson.present ? data.propsJson.value : this.propsJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Shot(')
          ..write('updatedAt: $updatedAt, ')
          ..write('remoteId: $remoteId, ')
          ..write('id: $id, ')
          ..write('projectId: $projectId, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('shotSize: $shotSize, ')
          ..write('scene: $scene, ')
          ..write('dialogue: $dialogue, ')
          ..write('reason: $reason, ')
          ..write('characterNames: $characterNames, ')
          ..write('status: $status, ')
          ..write('cameraMove: $cameraMove, ')
          ..write('durationMs: $durationMs, ')
          ..write('propsJson: $propsJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    updatedAt,
    remoteId,
    id,
    projectId,
    sortOrder,
    shotSize,
    scene,
    dialogue,
    reason,
    characterNames,
    status,
    cameraMove,
    durationMs,
    propsJson,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Shot &&
          other.updatedAt == this.updatedAt &&
          other.remoteId == this.remoteId &&
          other.id == this.id &&
          other.projectId == this.projectId &&
          other.sortOrder == this.sortOrder &&
          other.shotSize == this.shotSize &&
          other.scene == this.scene &&
          other.dialogue == this.dialogue &&
          other.reason == this.reason &&
          other.characterNames == this.characterNames &&
          other.status == this.status &&
          other.cameraMove == this.cameraMove &&
          other.durationMs == this.durationMs &&
          other.propsJson == this.propsJson);
}

class ShotsCompanion extends UpdateCompanion<Shot> {
  final Value<DateTime> updatedAt;
  final Value<String?> remoteId;
  final Value<String> id;
  final Value<String> projectId;
  final Value<int> sortOrder;
  final Value<ShotSize> shotSize;
  final Value<String> scene;
  final Value<String> dialogue;
  final Value<String> reason;
  final Value<List<String>> characterNames;
  final Value<ShotStatus> status;
  final Value<CameraMove> cameraMove;
  final Value<int?> durationMs;
  final Value<List<ShotProp>?> propsJson;
  final Value<int> rowid;
  const ShotsCompanion({
    this.updatedAt = const Value.absent(),
    this.remoteId = const Value.absent(),
    this.id = const Value.absent(),
    this.projectId = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.shotSize = const Value.absent(),
    this.scene = const Value.absent(),
    this.dialogue = const Value.absent(),
    this.reason = const Value.absent(),
    this.characterNames = const Value.absent(),
    this.status = const Value.absent(),
    this.cameraMove = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.propsJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ShotsCompanion.insert({
    this.updatedAt = const Value.absent(),
    this.remoteId = const Value.absent(),
    required String id,
    required String projectId,
    required int sortOrder,
    required ShotSize shotSize,
    required String scene,
    this.dialogue = const Value.absent(),
    this.reason = const Value.absent(),
    this.characterNames = const Value.absent(),
    this.status = const Value.absent(),
    this.cameraMove = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.propsJson = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       projectId = Value(projectId),
       sortOrder = Value(sortOrder),
       shotSize = Value(shotSize),
       scene = Value(scene);
  static Insertable<Shot> custom({
    Expression<DateTime>? updatedAt,
    Expression<String>? remoteId,
    Expression<String>? id,
    Expression<String>? projectId,
    Expression<int>? sortOrder,
    Expression<String>? shotSize,
    Expression<String>? scene,
    Expression<String>? dialogue,
    Expression<String>? reason,
    Expression<String>? characterNames,
    Expression<String>? status,
    Expression<String>? cameraMove,
    Expression<int>? durationMs,
    Expression<String>? propsJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (updatedAt != null) 'updated_at': updatedAt,
      if (remoteId != null) 'remote_id': remoteId,
      if (id != null) 'id': id,
      if (projectId != null) 'project_id': projectId,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (shotSize != null) 'shot_size': shotSize,
      if (scene != null) 'scene': scene,
      if (dialogue != null) 'dialogue': dialogue,
      if (reason != null) 'reason': reason,
      if (characterNames != null) 'character_names': characterNames,
      if (status != null) 'status': status,
      if (cameraMove != null) 'camera_move': cameraMove,
      if (durationMs != null) 'duration_ms': durationMs,
      if (propsJson != null) 'props_json': propsJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ShotsCompanion copyWith({
    Value<DateTime>? updatedAt,
    Value<String?>? remoteId,
    Value<String>? id,
    Value<String>? projectId,
    Value<int>? sortOrder,
    Value<ShotSize>? shotSize,
    Value<String>? scene,
    Value<String>? dialogue,
    Value<String>? reason,
    Value<List<String>>? characterNames,
    Value<ShotStatus>? status,
    Value<CameraMove>? cameraMove,
    Value<int?>? durationMs,
    Value<List<ShotProp>?>? propsJson,
    Value<int>? rowid,
  }) {
    return ShotsCompanion(
      updatedAt: updatedAt ?? this.updatedAt,
      remoteId: remoteId ?? this.remoteId,
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      sortOrder: sortOrder ?? this.sortOrder,
      shotSize: shotSize ?? this.shotSize,
      scene: scene ?? this.scene,
      dialogue: dialogue ?? this.dialogue,
      reason: reason ?? this.reason,
      characterNames: characterNames ?? this.characterNames,
      status: status ?? this.status,
      cameraMove: cameraMove ?? this.cameraMove,
      durationMs: durationMs ?? this.durationMs,
      propsJson: propsJson ?? this.propsJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (remoteId.present) {
      map['remote_id'] = Variable<String>(remoteId.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (projectId.present) {
      map['project_id'] = Variable<String>(projectId.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (shotSize.present) {
      map['shot_size'] = Variable<String>($ShotsTable.$convertershotSize.toSql(shotSize.value));
    }
    if (scene.present) {
      map['scene'] = Variable<String>(scene.value);
    }
    if (dialogue.present) {
      map['dialogue'] = Variable<String>(dialogue.value);
    }
    if (reason.present) {
      map['reason'] = Variable<String>(reason.value);
    }
    if (characterNames.present) {
      map['character_names'] = Variable<String>(
        $ShotsTable.$convertercharacterNames.toSql(characterNames.value),
      );
    }
    if (status.present) {
      map['status'] = Variable<String>($ShotsTable.$converterstatus.toSql(status.value));
    }
    if (cameraMove.present) {
      map['camera_move'] = Variable<String>(
        $ShotsTable.$convertercameraMove.toSql(cameraMove.value),
      );
    }
    if (durationMs.present) {
      map['duration_ms'] = Variable<int>(durationMs.value);
    }
    if (propsJson.present) {
      map['props_json'] = Variable<String>($ShotsTable.$converterpropsJsonn.toSql(propsJson.value));
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ShotsCompanion(')
          ..write('updatedAt: $updatedAt, ')
          ..write('remoteId: $remoteId, ')
          ..write('id: $id, ')
          ..write('projectId: $projectId, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('shotSize: $shotSize, ')
          ..write('scene: $scene, ')
          ..write('dialogue: $dialogue, ')
          ..write('reason: $reason, ')
          ..write('characterNames: $characterNames, ')
          ..write('status: $status, ')
          ..write('cameraMove: $cameraMove, ')
          ..write('durationMs: $durationMs, ')
          ..write('propsJson: $propsJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $GenerationsTable extends Generations with TableInfo<$GenerationsTable, Generation> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GenerationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _updatedAtMeta = const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _remoteIdMeta = const VerificationMeta('remoteId');
  @override
  late final GeneratedColumn<String> remoteId = GeneratedColumn<String>(
    'remote_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _shotIdMeta = const VerificationMeta('shotId');
  @override
  late final GeneratedColumn<String> shotId = GeneratedColumn<String>(
    'shot_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES shots (id) ON DELETE CASCADE',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<VideoPlatform, String> platform =
      GeneratedColumn<String>(
        'platform',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<VideoPlatform>($GenerationsTable.$converterplatform);
  static const VerificationMeta _promptMeta = const VerificationMeta('prompt');
  @override
  late final GeneratedColumn<String> prompt = GeneratedColumn<String>(
    'prompt',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _resultNoteMeta = const VerificationMeta('resultNote');
  @override
  late final GeneratedColumn<String> resultNote = GeneratedColumn<String>(
    'result_note',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _pickedMeta = const VerificationMeta('picked');
  @override
  late final GeneratedColumn<bool> picked = GeneratedColumn<bool>(
    'picked',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("picked" IN (0, 1))'),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    updatedAt,
    remoteId,
    id,
    shotId,
    platform,
    prompt,
    resultNote,
    picked,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'generations';
  @override
  VerificationContext validateIntegrity(
    Insertable<Generation> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('remote_id')) {
      context.handle(
        _remoteIdMeta,
        remoteId.isAcceptableOrUnknown(data['remote_id']!, _remoteIdMeta),
      );
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('shot_id')) {
      context.handle(_shotIdMeta, shotId.isAcceptableOrUnknown(data['shot_id']!, _shotIdMeta));
    } else if (isInserting) {
      context.missing(_shotIdMeta);
    }
    if (data.containsKey('prompt')) {
      context.handle(_promptMeta, prompt.isAcceptableOrUnknown(data['prompt']!, _promptMeta));
    } else if (isInserting) {
      context.missing(_promptMeta);
    }
    if (data.containsKey('result_note')) {
      context.handle(
        _resultNoteMeta,
        resultNote.isAcceptableOrUnknown(data['result_note']!, _resultNoteMeta),
      );
    }
    if (data.containsKey('picked')) {
      context.handle(_pickedMeta, picked.isAcceptableOrUnknown(data['picked']!, _pickedMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Generation map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Generation(
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      remoteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_id'],
      ),
      id: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      shotId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}shot_id'],
      )!,
      platform: $GenerationsTable.$converterplatform.fromSql(
        attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}platform'])!,
      ),
      prompt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}prompt'],
      )!,
      resultNote: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}result_note'],
      )!,
      picked: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}picked'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $GenerationsTable createAlias(String alias) {
    return $GenerationsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<VideoPlatform, String, String> $converterplatform =
      const EnumNameConverter<VideoPlatform>(VideoPlatform.values);
}

class Generation extends DataClass implements Insertable<Generation> {
  final DateTime updatedAt;
  final String? remoteId;
  final String id;
  final String shotId;
  final VideoPlatform platform;

  /// 当次实际使用的提示词快照，用于回看哪种写法效果好。
  final String prompt;
  final String resultNote;
  final bool picked;
  final DateTime createdAt;
  const Generation({
    required this.updatedAt,
    this.remoteId,
    required this.id,
    required this.shotId,
    required this.platform,
    required this.prompt,
    required this.resultNote,
    required this.picked,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || remoteId != null) {
      map['remote_id'] = Variable<String>(remoteId);
    }
    map['id'] = Variable<String>(id);
    map['shot_id'] = Variable<String>(shotId);
    {
      map['platform'] = Variable<String>($GenerationsTable.$converterplatform.toSql(platform));
    }
    map['prompt'] = Variable<String>(prompt);
    map['result_note'] = Variable<String>(resultNote);
    map['picked'] = Variable<bool>(picked);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  GenerationsCompanion toCompanion(bool nullToAbsent) {
    return GenerationsCompanion(
      updatedAt: Value(updatedAt),
      remoteId: remoteId == null && nullToAbsent ? const Value.absent() : Value(remoteId),
      id: Value(id),
      shotId: Value(shotId),
      platform: Value(platform),
      prompt: Value(prompt),
      resultNote: Value(resultNote),
      picked: Value(picked),
      createdAt: Value(createdAt),
    );
  }

  factory Generation.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Generation(
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      remoteId: serializer.fromJson<String?>(json['remoteId']),
      id: serializer.fromJson<String>(json['id']),
      shotId: serializer.fromJson<String>(json['shotId']),
      platform: $GenerationsTable.$converterplatform.fromJson(
        serializer.fromJson<String>(json['platform']),
      ),
      prompt: serializer.fromJson<String>(json['prompt']),
      resultNote: serializer.fromJson<String>(json['resultNote']),
      picked: serializer.fromJson<bool>(json['picked']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'remoteId': serializer.toJson<String?>(remoteId),
      'id': serializer.toJson<String>(id),
      'shotId': serializer.toJson<String>(shotId),
      'platform': serializer.toJson<String>($GenerationsTable.$converterplatform.toJson(platform)),
      'prompt': serializer.toJson<String>(prompt),
      'resultNote': serializer.toJson<String>(resultNote),
      'picked': serializer.toJson<bool>(picked),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Generation copyWith({
    DateTime? updatedAt,
    Value<String?> remoteId = const Value.absent(),
    String? id,
    String? shotId,
    VideoPlatform? platform,
    String? prompt,
    String? resultNote,
    bool? picked,
    DateTime? createdAt,
  }) => Generation(
    updatedAt: updatedAt ?? this.updatedAt,
    remoteId: remoteId.present ? remoteId.value : this.remoteId,
    id: id ?? this.id,
    shotId: shotId ?? this.shotId,
    platform: platform ?? this.platform,
    prompt: prompt ?? this.prompt,
    resultNote: resultNote ?? this.resultNote,
    picked: picked ?? this.picked,
    createdAt: createdAt ?? this.createdAt,
  );
  Generation copyWithCompanion(GenerationsCompanion data) {
    return Generation(
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      remoteId: data.remoteId.present ? data.remoteId.value : this.remoteId,
      id: data.id.present ? data.id.value : this.id,
      shotId: data.shotId.present ? data.shotId.value : this.shotId,
      platform: data.platform.present ? data.platform.value : this.platform,
      prompt: data.prompt.present ? data.prompt.value : this.prompt,
      resultNote: data.resultNote.present ? data.resultNote.value : this.resultNote,
      picked: data.picked.present ? data.picked.value : this.picked,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Generation(')
          ..write('updatedAt: $updatedAt, ')
          ..write('remoteId: $remoteId, ')
          ..write('id: $id, ')
          ..write('shotId: $shotId, ')
          ..write('platform: $platform, ')
          ..write('prompt: $prompt, ')
          ..write('resultNote: $resultNote, ')
          ..write('picked: $picked, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(updatedAt, remoteId, id, shotId, platform, prompt, resultNote, picked, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Generation &&
          other.updatedAt == this.updatedAt &&
          other.remoteId == this.remoteId &&
          other.id == this.id &&
          other.shotId == this.shotId &&
          other.platform == this.platform &&
          other.prompt == this.prompt &&
          other.resultNote == this.resultNote &&
          other.picked == this.picked &&
          other.createdAt == this.createdAt);
}

class GenerationsCompanion extends UpdateCompanion<Generation> {
  final Value<DateTime> updatedAt;
  final Value<String?> remoteId;
  final Value<String> id;
  final Value<String> shotId;
  final Value<VideoPlatform> platform;
  final Value<String> prompt;
  final Value<String> resultNote;
  final Value<bool> picked;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const GenerationsCompanion({
    this.updatedAt = const Value.absent(),
    this.remoteId = const Value.absent(),
    this.id = const Value.absent(),
    this.shotId = const Value.absent(),
    this.platform = const Value.absent(),
    this.prompt = const Value.absent(),
    this.resultNote = const Value.absent(),
    this.picked = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GenerationsCompanion.insert({
    this.updatedAt = const Value.absent(),
    this.remoteId = const Value.absent(),
    required String id,
    required String shotId,
    required VideoPlatform platform,
    required String prompt,
    this.resultNote = const Value.absent(),
    this.picked = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       shotId = Value(shotId),
       platform = Value(platform),
       prompt = Value(prompt);
  static Insertable<Generation> custom({
    Expression<DateTime>? updatedAt,
    Expression<String>? remoteId,
    Expression<String>? id,
    Expression<String>? shotId,
    Expression<String>? platform,
    Expression<String>? prompt,
    Expression<String>? resultNote,
    Expression<bool>? picked,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (updatedAt != null) 'updated_at': updatedAt,
      if (remoteId != null) 'remote_id': remoteId,
      if (id != null) 'id': id,
      if (shotId != null) 'shot_id': shotId,
      if (platform != null) 'platform': platform,
      if (prompt != null) 'prompt': prompt,
      if (resultNote != null) 'result_note': resultNote,
      if (picked != null) 'picked': picked,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GenerationsCompanion copyWith({
    Value<DateTime>? updatedAt,
    Value<String?>? remoteId,
    Value<String>? id,
    Value<String>? shotId,
    Value<VideoPlatform>? platform,
    Value<String>? prompt,
    Value<String>? resultNote,
    Value<bool>? picked,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return GenerationsCompanion(
      updatedAt: updatedAt ?? this.updatedAt,
      remoteId: remoteId ?? this.remoteId,
      id: id ?? this.id,
      shotId: shotId ?? this.shotId,
      platform: platform ?? this.platform,
      prompt: prompt ?? this.prompt,
      resultNote: resultNote ?? this.resultNote,
      picked: picked ?? this.picked,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (remoteId.present) {
      map['remote_id'] = Variable<String>(remoteId.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (shotId.present) {
      map['shot_id'] = Variable<String>(shotId.value);
    }
    if (platform.present) {
      map['platform'] = Variable<String>(
        $GenerationsTable.$converterplatform.toSql(platform.value),
      );
    }
    if (prompt.present) {
      map['prompt'] = Variable<String>(prompt.value);
    }
    if (resultNote.present) {
      map['result_note'] = Variable<String>(resultNote.value);
    }
    if (picked.present) {
      map['picked'] = Variable<bool>(picked.value);
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
    return (StringBuffer('GenerationsCompanion(')
          ..write('updatedAt: $updatedAt, ')
          ..write('remoteId: $remoteId, ')
          ..write('id: $id, ')
          ..write('shotId: $shotId, ')
          ..write('platform: $platform, ')
          ..write('prompt: $prompt, ')
          ..write('resultNote: $resultNote, ')
          ..write('picked: $picked, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $KeyValuesTable extends KeyValues with TableInfo<$KeyValuesTable, KeyValueEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $KeyValuesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _entryKeyMeta = const VerificationMeta('entryKey');
  @override
  late final GeneratedColumn<String> entryKey = GeneratedColumn<String>(
    'entry_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entryValueMeta = const VerificationMeta('entryValue');
  @override
  late final GeneratedColumn<String> entryValue = GeneratedColumn<String>(
    'entry_value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [entryKey, entryValue];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'key_values';
  @override
  VerificationContext validateIntegrity(
    Insertable<KeyValueEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('entry_key')) {
      context.handle(
        _entryKeyMeta,
        entryKey.isAcceptableOrUnknown(data['entry_key']!, _entryKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_entryKeyMeta);
    }
    if (data.containsKey('entry_value')) {
      context.handle(
        _entryValueMeta,
        entryValue.isAcceptableOrUnknown(data['entry_value']!, _entryValueMeta),
      );
    } else if (isInserting) {
      context.missing(_entryValueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {entryKey};
  @override
  KeyValueEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return KeyValueEntry(
      entryKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entry_key'],
      )!,
      entryValue: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entry_value'],
      )!,
    );
  }

  @override
  $KeyValuesTable createAlias(String alias) {
    return $KeyValuesTable(attachedDatabase, alias);
  }
}

class KeyValueEntry extends DataClass implements Insertable<KeyValueEntry> {
  final String entryKey;
  final String entryValue;
  const KeyValueEntry({required this.entryKey, required this.entryValue});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['entry_key'] = Variable<String>(entryKey);
    map['entry_value'] = Variable<String>(entryValue);
    return map;
  }

  KeyValuesCompanion toCompanion(bool nullToAbsent) {
    return KeyValuesCompanion(entryKey: Value(entryKey), entryValue: Value(entryValue));
  }

  factory KeyValueEntry.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return KeyValueEntry(
      entryKey: serializer.fromJson<String>(json['entryKey']),
      entryValue: serializer.fromJson<String>(json['entryValue']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'entryKey': serializer.toJson<String>(entryKey),
      'entryValue': serializer.toJson<String>(entryValue),
    };
  }

  KeyValueEntry copyWith({String? entryKey, String? entryValue}) =>
      KeyValueEntry(entryKey: entryKey ?? this.entryKey, entryValue: entryValue ?? this.entryValue);
  KeyValueEntry copyWithCompanion(KeyValuesCompanion data) {
    return KeyValueEntry(
      entryKey: data.entryKey.present ? data.entryKey.value : this.entryKey,
      entryValue: data.entryValue.present ? data.entryValue.value : this.entryValue,
    );
  }

  @override
  String toString() {
    return (StringBuffer('KeyValueEntry(')
          ..write('entryKey: $entryKey, ')
          ..write('entryValue: $entryValue')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(entryKey, entryValue);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is KeyValueEntry &&
          other.entryKey == this.entryKey &&
          other.entryValue == this.entryValue);
}

class KeyValuesCompanion extends UpdateCompanion<KeyValueEntry> {
  final Value<String> entryKey;
  final Value<String> entryValue;
  final Value<int> rowid;
  const KeyValuesCompanion({
    this.entryKey = const Value.absent(),
    this.entryValue = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  KeyValuesCompanion.insert({
    required String entryKey,
    required String entryValue,
    this.rowid = const Value.absent(),
  }) : entryKey = Value(entryKey),
       entryValue = Value(entryValue);
  static Insertable<KeyValueEntry> custom({
    Expression<String>? entryKey,
    Expression<String>? entryValue,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (entryKey != null) 'entry_key': entryKey,
      if (entryValue != null) 'entry_value': entryValue,
      if (rowid != null) 'rowid': rowid,
    });
  }

  KeyValuesCompanion copyWith({
    Value<String>? entryKey,
    Value<String>? entryValue,
    Value<int>? rowid,
  }) {
    return KeyValuesCompanion(
      entryKey: entryKey ?? this.entryKey,
      entryValue: entryValue ?? this.entryValue,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (entryKey.present) {
      map['entry_key'] = Variable<String>(entryKey.value);
    }
    if (entryValue.present) {
      map['entry_value'] = Variable<String>(entryValue.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('KeyValuesCompanion(')
          ..write('entryKey: $entryKey, ')
          ..write('entryValue: $entryValue, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PropDrawingsTable extends PropDrawings with TableInfo<$PropDrawingsTable, PropDrawingRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PropDrawingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _drawingJsonMeta = const VerificationMeta('drawingJson');
  @override
  late final GeneratedColumn<String> drawingJson = GeneratedColumn<String>(
    'drawing_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<PropDrawingStatus, String> status =
      GeneratedColumn<String>(
        'status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<PropDrawingStatus>($PropDrawingsTable.$converterstatus);
  static const VerificationMeta _updatedAtMeta = const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [name, drawingJson, status, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'prop_drawings';
  @override
  VerificationContext validateIntegrity(
    Insertable<PropDrawingRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('name')) {
      context.handle(_nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('drawing_json')) {
      context.handle(
        _drawingJsonMeta,
        drawingJson.isAcceptableOrUnknown(data['drawing_json']!, _drawingJsonMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {name};
  @override
  PropDrawingRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PropDrawingRow(
      name: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      drawingJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}drawing_json'],
      ),
      status: $PropDrawingsTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $PropDrawingsTable createAlias(String alias) {
    return $PropDrawingsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<PropDrawingStatus, String, String> $converterstatus =
      const EnumNameConverter<PropDrawingStatus>(PropDrawingStatus.values);
}

class PropDrawingRow extends DataClass implements Insertable<PropDrawingRow> {
  final String name;

  /// 校验通过的绘图 JSON；失败时为空。
  final String? drawingJson;
  final PropDrawingStatus status;
  final DateTime updatedAt;
  const PropDrawingRow({
    required this.name,
    this.drawingJson,
    required this.status,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || drawingJson != null) {
      map['drawing_json'] = Variable<String>(drawingJson);
    }
    {
      map['status'] = Variable<String>($PropDrawingsTable.$converterstatus.toSql(status));
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  PropDrawingsCompanion toCompanion(bool nullToAbsent) {
    return PropDrawingsCompanion(
      name: Value(name),
      drawingJson: drawingJson == null && nullToAbsent ? const Value.absent() : Value(drawingJson),
      status: Value(status),
      updatedAt: Value(updatedAt),
    );
  }

  factory PropDrawingRow.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PropDrawingRow(
      name: serializer.fromJson<String>(json['name']),
      drawingJson: serializer.fromJson<String?>(json['drawingJson']),
      status: $PropDrawingsTable.$converterstatus.fromJson(
        serializer.fromJson<String>(json['status']),
      ),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'name': serializer.toJson<String>(name),
      'drawingJson': serializer.toJson<String?>(drawingJson),
      'status': serializer.toJson<String>($PropDrawingsTable.$converterstatus.toJson(status)),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  PropDrawingRow copyWith({
    String? name,
    Value<String?> drawingJson = const Value.absent(),
    PropDrawingStatus? status,
    DateTime? updatedAt,
  }) => PropDrawingRow(
    name: name ?? this.name,
    drawingJson: drawingJson.present ? drawingJson.value : this.drawingJson,
    status: status ?? this.status,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  PropDrawingRow copyWithCompanion(PropDrawingsCompanion data) {
    return PropDrawingRow(
      name: data.name.present ? data.name.value : this.name,
      drawingJson: data.drawingJson.present ? data.drawingJson.value : this.drawingJson,
      status: data.status.present ? data.status.value : this.status,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PropDrawingRow(')
          ..write('name: $name, ')
          ..write('drawingJson: $drawingJson, ')
          ..write('status: $status, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(name, drawingJson, status, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PropDrawingRow &&
          other.name == this.name &&
          other.drawingJson == this.drawingJson &&
          other.status == this.status &&
          other.updatedAt == this.updatedAt);
}

class PropDrawingsCompanion extends UpdateCompanion<PropDrawingRow> {
  final Value<String> name;
  final Value<String?> drawingJson;
  final Value<PropDrawingStatus> status;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const PropDrawingsCompanion({
    this.name = const Value.absent(),
    this.drawingJson = const Value.absent(),
    this.status = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PropDrawingsCompanion.insert({
    required String name,
    this.drawingJson = const Value.absent(),
    required PropDrawingStatus status,
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : name = Value(name),
       status = Value(status);
  static Insertable<PropDrawingRow> custom({
    Expression<String>? name,
    Expression<String>? drawingJson,
    Expression<String>? status,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (name != null) 'name': name,
      if (drawingJson != null) 'drawing_json': drawingJson,
      if (status != null) 'status': status,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PropDrawingsCompanion copyWith({
    Value<String>? name,
    Value<String?>? drawingJson,
    Value<PropDrawingStatus>? status,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return PropDrawingsCompanion(
      name: name ?? this.name,
      drawingJson: drawingJson ?? this.drawingJson,
      status: status ?? this.status,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (drawingJson.present) {
      map['drawing_json'] = Variable<String>(drawingJson.value);
    }
    if (status.present) {
      map['status'] = Variable<String>($PropDrawingsTable.$converterstatus.toSql(status.value));
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PropDrawingsCompanion(')
          ..write('name: $name, ')
          ..write('drawingJson: $drawingJson, ')
          ..write('status: $status, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ProjectsTable projects = $ProjectsTable(this);
  late final $CharacterCardsTable characterCards = $CharacterCardsTable(this);
  late final $ShotsTable shots = $ShotsTable(this);
  late final $GenerationsTable generations = $GenerationsTable(this);
  late final $KeyValuesTable keyValues = $KeyValuesTable(this);
  late final $PropDrawingsTable propDrawings = $PropDrawingsTable(this);
  late final Index shotsProjectOrder = Index(
    'shots_project_order',
    'CREATE INDEX shots_project_order ON shots (project_id, sort_order)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    projects,
    characterCards,
    shots,
    generations,
    keyValues,
    propDrawings,
    shotsProjectOrder,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName('projects', limitUpdateKind: UpdateKind.delete),
      result: [TableUpdate('character_cards', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName('projects', limitUpdateKind: UpdateKind.delete),
      result: [TableUpdate('shots', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName('shots', limitUpdateKind: UpdateKind.delete),
      result: [TableUpdate('generations', kind: UpdateKind.delete)],
    ),
  ]);
  @override
  DriftDatabaseOptions get options => const DriftDatabaseOptions(storeDateTimeAsText: true);
}

typedef $$ProjectsTableCreateCompanionBuilder = ProjectsCompanion Function({
  Value<DateTime> updatedAt,
  Value<String?> remoteId,
  required String id,
  required String title,
  Value<String> story,
  Value<DateTime> createdAt,
  Value<int> rowid,
});
typedef $$ProjectsTableUpdateCompanionBuilder = ProjectsCompanion Function({
  Value<DateTime> updatedAt,
  Value<String?> remoteId,
  Value<String> id,
  Value<String> title,
  Value<String> story,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

final class $$ProjectsTableReferences
    extends BaseReferences<_$AppDatabase, $ProjectsTable, Project> {
  $$ProjectsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$CharacterCardsTable, List<CharacterCard>> _characterCardsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.characterCards,
    aliasName: 'projects__id__character_cards__project_id',
  );

  $$CharacterCardsTableProcessedTableManager get characterCardsRefs {
    final manager = $$CharacterCardsTableTableManager(
      $_db,
      $_db.characterCards,
    ).filter((f) => f.projectId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_characterCardsRefsTable($_db));
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$ShotsTable, List<Shot>> _shotsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.shots, aliasName: 'projects__id__shots__project_id');

  $$ShotsTableProcessedTableManager get shotsRefs {
    final manager = $$ShotsTableTableManager(
      $_db,
      $_db.shots,
    ).filter((f) => f.projectId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_shotsRefsTable($_db));
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$ProjectsTableFilterComposer extends Composer<_$AppDatabase, $ProjectsTable> {
  $$ProjectsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get remoteId =>
      $composableBuilder(column: $table.remoteId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get story =>
      $composableBuilder(column: $table.story, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnFilters(column));

  Expression<bool> characterCardsRefs(
    Expression<bool> Function($$CharacterCardsTableFilterComposer f) f,
  ) {
    final $$CharacterCardsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.characterCards,
      getReferencedColumn: (t) => t.projectId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$CharacterCardsTableFilterComposer(
            $db: $db,
            $table: $db.characterCards,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> shotsRefs(Expression<bool> Function($$ShotsTableFilterComposer f) f) {
    final $$ShotsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.shots,
      getReferencedColumn: (t) => t.projectId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$ShotsTableFilterComposer(
            $db: $db,
            $table: $db.shots,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ProjectsTableOrderingComposer extends Composer<_$AppDatabase, $ProjectsTable> {
  $$ProjectsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get remoteId =>
      $composableBuilder(column: $table.remoteId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get story =>
      $composableBuilder(column: $table.story, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$ProjectsTableAnnotationComposer extends Composer<_$AppDatabase, $ProjectsTable> {
  $$ProjectsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get remoteId =>
      $composableBuilder(column: $table.remoteId, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get story =>
      $composableBuilder(column: $table.story, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> characterCardsRefs<T extends Object>(
    Expression<T> Function($$CharacterCardsTableAnnotationComposer a) f,
  ) {
    final $$CharacterCardsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.characterCards,
      getReferencedColumn: (t) => t.projectId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$CharacterCardsTableAnnotationComposer(
            $db: $db,
            $table: $db.characterCards,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> shotsRefs<T extends Object>(
    Expression<T> Function($$ShotsTableAnnotationComposer a) f,
  ) {
    final $$ShotsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.shots,
      getReferencedColumn: (t) => t.projectId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$ShotsTableAnnotationComposer(
            $db: $db,
            $table: $db.shots,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ProjectsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProjectsTable,
          Project,
          $$ProjectsTableFilterComposer,
          $$ProjectsTableOrderingComposer,
          $$ProjectsTableAnnotationComposer,
          $$ProjectsTableCreateCompanionBuilder,
          $$ProjectsTableUpdateCompanionBuilder,
          (Project, $$ProjectsTableReferences),
          Project,
          PrefetchHooks Function({bool characterCardsRefs, bool shotsRefs})
        > {
  $$ProjectsTableTableManager(_$AppDatabase db, $ProjectsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$ProjectsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$ProjectsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProjectsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<DateTime> updatedAt = const Value.absent(),
                Value<String?> remoteId = const Value.absent(),
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> story = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProjectsCompanion(
                updatedAt: updatedAt,
                remoteId: remoteId,
                id: id,
                title: title,
                story: story,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<DateTime> updatedAt = const Value.absent(),
                Value<String?> remoteId = const Value.absent(),
                required String id,
                required String title,
                Value<String> story = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProjectsCompanion.insert(
                updatedAt: updatedAt,
                remoteId: remoteId,
                id: id,
                title: title,
                story: story,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ProjectsTable, Project>(table),
                  $$ProjectsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({characterCardsRefs = false, shotsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (characterCardsRefs) db.characterCards,
                if (shotsRefs) db.shots,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (characterCardsRefs)
                    await $_getPrefetchedDataByColumns<
                      Project,
                      $ProjectsTable,
                      CharacterCard,
                      $CharacterCardsTable
                    >(
                      currentTable: table,
                      referencedTable: $$ProjectsTableReferences._characterCardsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$ProjectsTableReferences(db, table, p0).characterCardsRefs,
                      currentColumn: 'id',
                      referencedColumn: 'project_id',
                      typedResults: items,
                    ),
                  if (shotsRefs)
                    await $_getPrefetchedDataByColumns<Project, $ProjectsTable, Shot, $ShotsTable>(
                      currentTable: table,
                      referencedTable: $$ProjectsTableReferences._shotsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$ProjectsTableReferences(db, table, p0).shotsRefs,
                      currentColumn: 'id',
                      referencedColumn: 'project_id',
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$ProjectsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProjectsTable,
      Project,
      $$ProjectsTableFilterComposer,
      $$ProjectsTableOrderingComposer,
      $$ProjectsTableAnnotationComposer,
      $$ProjectsTableCreateCompanionBuilder,
      $$ProjectsTableUpdateCompanionBuilder,
      (Project, $$ProjectsTableReferences),
      Project,
      PrefetchHooks Function({bool characterCardsRefs, bool shotsRefs})
    >;
typedef $$CharacterCardsTableCreateCompanionBuilder = CharacterCardsCompanion Function({
  Value<DateTime> updatedAt,
  Value<String?> remoteId,
  required String id,
  required String projectId,
  required String name,
  Value<String> appearance,
  Value<String> outfit,
  Value<int> rowid,
});
typedef $$CharacterCardsTableUpdateCompanionBuilder = CharacterCardsCompanion Function({
  Value<DateTime> updatedAt,
  Value<String?> remoteId,
  Value<String> id,
  Value<String> projectId,
  Value<String> name,
  Value<String> appearance,
  Value<String> outfit,
  Value<int> rowid,
});

final class $$CharacterCardsTableReferences
    extends BaseReferences<_$AppDatabase, $CharacterCardsTable, CharacterCard> {
  $$CharacterCardsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ProjectsTable _projectIdTable(_$AppDatabase db) =>
      db.projects.createAlias('character_cards__project_id__projects__id');

  $$ProjectsTableProcessedTableManager get projectId {
    final $_column = $_itemColumn<String>('project_id')!;

    final manager = $$ProjectsTableTableManager(
      $_db,
      $_db.projects,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_projectIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$CharacterCardsTableFilterComposer extends Composer<_$AppDatabase, $CharacterCardsTable> {
  $$CharacterCardsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get remoteId =>
      $composableBuilder(column: $table.remoteId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get appearance =>
      $composableBuilder(column: $table.appearance, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get outfit =>
      $composableBuilder(column: $table.outfit, builder: (column) => ColumnFilters(column));

  $$ProjectsTableFilterComposer get projectId {
    final $$ProjectsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.projectId,
      referencedTable: $db.projects,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$ProjectsTableFilterComposer(
            $db: $db,
            $table: $db.projects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CharacterCardsTableOrderingComposer extends Composer<_$AppDatabase, $CharacterCardsTable> {
  $$CharacterCardsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get remoteId =>
      $composableBuilder(column: $table.remoteId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get appearance =>
      $composableBuilder(column: $table.appearance, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get outfit =>
      $composableBuilder(column: $table.outfit, builder: (column) => ColumnOrderings(column));

  $$ProjectsTableOrderingComposer get projectId {
    final $$ProjectsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.projectId,
      referencedTable: $db.projects,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$ProjectsTableOrderingComposer(
            $db: $db,
            $table: $db.projects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CharacterCardsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CharacterCardsTable> {
  $$CharacterCardsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get remoteId =>
      $composableBuilder(column: $table.remoteId, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get appearance =>
      $composableBuilder(column: $table.appearance, builder: (column) => column);

  GeneratedColumn<String> get outfit =>
      $composableBuilder(column: $table.outfit, builder: (column) => column);

  $$ProjectsTableAnnotationComposer get projectId {
    final $$ProjectsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.projectId,
      referencedTable: $db.projects,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$ProjectsTableAnnotationComposer(
            $db: $db,
            $table: $db.projects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CharacterCardsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CharacterCardsTable,
          CharacterCard,
          $$CharacterCardsTableFilterComposer,
          $$CharacterCardsTableOrderingComposer,
          $$CharacterCardsTableAnnotationComposer,
          $$CharacterCardsTableCreateCompanionBuilder,
          $$CharacterCardsTableUpdateCompanionBuilder,
          (CharacterCard, $$CharacterCardsTableReferences),
          CharacterCard,
          PrefetchHooks Function({bool projectId})
        > {
  $$CharacterCardsTableTableManager(_$AppDatabase db, $CharacterCardsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CharacterCardsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CharacterCardsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CharacterCardsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<DateTime> updatedAt = const Value.absent(),
                Value<String?> remoteId = const Value.absent(),
                Value<String> id = const Value.absent(),
                Value<String> projectId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> appearance = const Value.absent(),
                Value<String> outfit = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CharacterCardsCompanion(
                updatedAt: updatedAt,
                remoteId: remoteId,
                id: id,
                projectId: projectId,
                name: name,
                appearance: appearance,
                outfit: outfit,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<DateTime> updatedAt = const Value.absent(),
                Value<String?> remoteId = const Value.absent(),
                required String id,
                required String projectId,
                required String name,
                Value<String> appearance = const Value.absent(),
                Value<String> outfit = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CharacterCardsCompanion.insert(
                updatedAt: updatedAt,
                remoteId: remoteId,
                id: id,
                projectId: projectId,
                name: name,
                appearance: appearance,
                outfit: outfit,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CharacterCardsTable, CharacterCard>(table),
                  $$CharacterCardsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({projectId = false}) {
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
                    if (projectId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.projectId,
                        referencedTable: $$CharacterCardsTableReferences._projectIdTable(db),
                        referencedColumn: $$CharacterCardsTableReferences._projectIdTable(db).id,
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

typedef $$CharacterCardsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CharacterCardsTable,
      CharacterCard,
      $$CharacterCardsTableFilterComposer,
      $$CharacterCardsTableOrderingComposer,
      $$CharacterCardsTableAnnotationComposer,
      $$CharacterCardsTableCreateCompanionBuilder,
      $$CharacterCardsTableUpdateCompanionBuilder,
      (CharacterCard, $$CharacterCardsTableReferences),
      CharacterCard,
      PrefetchHooks Function({bool projectId})
    >;
typedef $$ShotsTableCreateCompanionBuilder = ShotsCompanion Function({
  Value<DateTime> updatedAt,
  Value<String?> remoteId,
  required String id,
  required String projectId,
  required int sortOrder,
  required ShotSize shotSize,
  required String scene,
  Value<String> dialogue,
  Value<String> reason,
  Value<List<String>> characterNames,
  Value<ShotStatus> status,
  Value<CameraMove> cameraMove,
  Value<int?> durationMs,
  Value<List<ShotProp>?> propsJson,
  Value<int> rowid,
});
typedef $$ShotsTableUpdateCompanionBuilder = ShotsCompanion Function({
  Value<DateTime> updatedAt,
  Value<String?> remoteId,
  Value<String> id,
  Value<String> projectId,
  Value<int> sortOrder,
  Value<ShotSize> shotSize,
  Value<String> scene,
  Value<String> dialogue,
  Value<String> reason,
  Value<List<String>> characterNames,
  Value<ShotStatus> status,
  Value<CameraMove> cameraMove,
  Value<int?> durationMs,
  Value<List<ShotProp>?> propsJson,
  Value<int> rowid,
});

final class $$ShotsTableReferences extends BaseReferences<_$AppDatabase, $ShotsTable, Shot> {
  $$ShotsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ProjectsTable _projectIdTable(_$AppDatabase db) =>
      db.projects.createAlias('shots__project_id__projects__id');

  $$ProjectsTableProcessedTableManager get projectId {
    final $_column = $_itemColumn<String>('project_id')!;

    final manager = $$ProjectsTableTableManager(
      $_db,
      $_db.projects,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_projectIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$GenerationsTable, List<Generation>> _generationsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(db.generations, aliasName: 'shots__id__generations__shot_id');

  $$GenerationsTableProcessedTableManager get generationsRefs {
    final manager = $$GenerationsTableTableManager(
      $_db,
      $_db.generations,
    ).filter((f) => f.shotId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_generationsRefsTable($_db));
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$ShotsTableFilterComposer extends Composer<_$AppDatabase, $ShotsTable> {
  $$ShotsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get remoteId =>
      $composableBuilder(column: $table.remoteId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<ShotSize, ShotSize, String> get shotSize => $composableBuilder(
    column: $table.shotSize,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get scene =>
      $composableBuilder(column: $table.scene, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get dialogue =>
      $composableBuilder(column: $table.dialogue, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get reason =>
      $composableBuilder(column: $table.reason, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<List<String>, List<String>, String> get characterNames =>
      $composableBuilder(
        column: $table.characterNames,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<ShotStatus, ShotStatus, String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<CameraMove, CameraMove, String> get cameraMove =>
      $composableBuilder(
        column: $table.cameraMove,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get durationMs =>
      $composableBuilder(column: $table.durationMs, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<List<ShotProp>?, List<ShotProp>, String> get propsJson =>
      $composableBuilder(
        column: $table.propsJson,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  $$ProjectsTableFilterComposer get projectId {
    final $$ProjectsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.projectId,
      referencedTable: $db.projects,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$ProjectsTableFilterComposer(
            $db: $db,
            $table: $db.projects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> generationsRefs(
    Expression<bool> Function($$GenerationsTableFilterComposer f) f,
  ) {
    final $$GenerationsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.generations,
      getReferencedColumn: (t) => t.shotId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$GenerationsTableFilterComposer(
            $db: $db,
            $table: $db.generations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ShotsTableOrderingComposer extends Composer<_$AppDatabase, $ShotsTable> {
  $$ShotsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get remoteId =>
      $composableBuilder(column: $table.remoteId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get shotSize =>
      $composableBuilder(column: $table.shotSize, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get scene =>
      $composableBuilder(column: $table.scene, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get dialogue =>
      $composableBuilder(column: $table.dialogue, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get reason =>
      $composableBuilder(column: $table.reason, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get characterNames => $composableBuilder(
    column: $table.characterNames,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get cameraMove =>
      $composableBuilder(column: $table.cameraMove, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get durationMs =>
      $composableBuilder(column: $table.durationMs, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get propsJson =>
      $composableBuilder(column: $table.propsJson, builder: (column) => ColumnOrderings(column));

  $$ProjectsTableOrderingComposer get projectId {
    final $$ProjectsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.projectId,
      referencedTable: $db.projects,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$ProjectsTableOrderingComposer(
            $db: $db,
            $table: $db.projects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ShotsTableAnnotationComposer extends Composer<_$AppDatabase, $ShotsTable> {
  $$ShotsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get remoteId =>
      $composableBuilder(column: $table.remoteId, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ShotSize, String> get shotSize =>
      $composableBuilder(column: $table.shotSize, builder: (column) => column);

  GeneratedColumn<String> get scene =>
      $composableBuilder(column: $table.scene, builder: (column) => column);

  GeneratedColumn<String> get dialogue =>
      $composableBuilder(column: $table.dialogue, builder: (column) => column);

  GeneratedColumn<String> get reason =>
      $composableBuilder(column: $table.reason, builder: (column) => column);

  GeneratedColumnWithTypeConverter<List<String>, String> get characterNames =>
      $composableBuilder(column: $table.characterNames, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ShotStatus, String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumnWithTypeConverter<CameraMove, String> get cameraMove =>
      $composableBuilder(column: $table.cameraMove, builder: (column) => column);

  GeneratedColumn<int> get durationMs =>
      $composableBuilder(column: $table.durationMs, builder: (column) => column);

  GeneratedColumnWithTypeConverter<List<ShotProp>?, String> get propsJson =>
      $composableBuilder(column: $table.propsJson, builder: (column) => column);

  $$ProjectsTableAnnotationComposer get projectId {
    final $$ProjectsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.projectId,
      referencedTable: $db.projects,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$ProjectsTableAnnotationComposer(
            $db: $db,
            $table: $db.projects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> generationsRefs<T extends Object>(
    Expression<T> Function($$GenerationsTableAnnotationComposer a) f,
  ) {
    final $$GenerationsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.generations,
      getReferencedColumn: (t) => t.shotId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$GenerationsTableAnnotationComposer(
            $db: $db,
            $table: $db.generations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ShotsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ShotsTable,
          Shot,
          $$ShotsTableFilterComposer,
          $$ShotsTableOrderingComposer,
          $$ShotsTableAnnotationComposer,
          $$ShotsTableCreateCompanionBuilder,
          $$ShotsTableUpdateCompanionBuilder,
          (Shot, $$ShotsTableReferences),
          Shot,
          PrefetchHooks Function({bool projectId, bool generationsRefs})
        > {
  $$ShotsTableTableManager(_$AppDatabase db, $ShotsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$ShotsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$ShotsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$ShotsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<DateTime> updatedAt = const Value.absent(),
                Value<String?> remoteId = const Value.absent(),
                Value<String> id = const Value.absent(),
                Value<String> projectId = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<ShotSize> shotSize = const Value.absent(),
                Value<String> scene = const Value.absent(),
                Value<String> dialogue = const Value.absent(),
                Value<String> reason = const Value.absent(),
                Value<List<String>> characterNames = const Value.absent(),
                Value<ShotStatus> status = const Value.absent(),
                Value<CameraMove> cameraMove = const Value.absent(),
                Value<int?> durationMs = const Value.absent(),
                Value<List<ShotProp>?> propsJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ShotsCompanion(
                updatedAt: updatedAt,
                remoteId: remoteId,
                id: id,
                projectId: projectId,
                sortOrder: sortOrder,
                shotSize: shotSize,
                scene: scene,
                dialogue: dialogue,
                reason: reason,
                characterNames: characterNames,
                status: status,
                cameraMove: cameraMove,
                durationMs: durationMs,
                propsJson: propsJson,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<DateTime> updatedAt = const Value.absent(),
                Value<String?> remoteId = const Value.absent(),
                required String id,
                required String projectId,
                required int sortOrder,
                required ShotSize shotSize,
                required String scene,
                Value<String> dialogue = const Value.absent(),
                Value<String> reason = const Value.absent(),
                Value<List<String>> characterNames = const Value.absent(),
                Value<ShotStatus> status = const Value.absent(),
                Value<CameraMove> cameraMove = const Value.absent(),
                Value<int?> durationMs = const Value.absent(),
                Value<List<ShotProp>?> propsJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ShotsCompanion.insert(
                updatedAt: updatedAt,
                remoteId: remoteId,
                id: id,
                projectId: projectId,
                sortOrder: sortOrder,
                shotSize: shotSize,
                scene: scene,
                dialogue: dialogue,
                reason: reason,
                characterNames: characterNames,
                status: status,
                cameraMove: cameraMove,
                durationMs: durationMs,
                propsJson: propsJson,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable<$ShotsTable, Shot>(table), $$ShotsTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({projectId = false, generationsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (generationsRefs) db.generations],
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
                    if (projectId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.projectId,
                        referencedTable: $$ShotsTableReferences._projectIdTable(db),
                        referencedColumn: $$ShotsTableReferences._projectIdTable(db).id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (generationsRefs)
                    await $_getPrefetchedDataByColumns<
                      Shot,
                      $ShotsTable,
                      Generation,
                      $GenerationsTable
                    >(
                      currentTable: table,
                      referencedTable: $$ShotsTableReferences._generationsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$ShotsTableReferences(db, table, p0).generationsRefs,
                      currentColumn: 'id',
                      referencedColumn: 'shot_id',
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$ShotsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ShotsTable,
      Shot,
      $$ShotsTableFilterComposer,
      $$ShotsTableOrderingComposer,
      $$ShotsTableAnnotationComposer,
      $$ShotsTableCreateCompanionBuilder,
      $$ShotsTableUpdateCompanionBuilder,
      (Shot, $$ShotsTableReferences),
      Shot,
      PrefetchHooks Function({bool projectId, bool generationsRefs})
    >;
typedef $$GenerationsTableCreateCompanionBuilder = GenerationsCompanion Function({
  Value<DateTime> updatedAt,
  Value<String?> remoteId,
  required String id,
  required String shotId,
  required VideoPlatform platform,
  required String prompt,
  Value<String> resultNote,
  Value<bool> picked,
  Value<DateTime> createdAt,
  Value<int> rowid,
});
typedef $$GenerationsTableUpdateCompanionBuilder = GenerationsCompanion Function({
  Value<DateTime> updatedAt,
  Value<String?> remoteId,
  Value<String> id,
  Value<String> shotId,
  Value<VideoPlatform> platform,
  Value<String> prompt,
  Value<String> resultNote,
  Value<bool> picked,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

final class $$GenerationsTableReferences
    extends BaseReferences<_$AppDatabase, $GenerationsTable, Generation> {
  $$GenerationsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ShotsTable _shotIdTable(_$AppDatabase db) =>
      db.shots.createAlias('generations__shot_id__shots__id');

  $$ShotsTableProcessedTableManager get shotId {
    final $_column = $_itemColumn<String>('shot_id')!;

    final manager = $$ShotsTableTableManager(
      $_db,
      $_db.shots,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_shotIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$GenerationsTableFilterComposer extends Composer<_$AppDatabase, $GenerationsTable> {
  $$GenerationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get remoteId =>
      $composableBuilder(column: $table.remoteId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<VideoPlatform, VideoPlatform, String> get platform =>
      $composableBuilder(
        column: $table.platform,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get prompt =>
      $composableBuilder(column: $table.prompt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get resultNote =>
      $composableBuilder(column: $table.resultNote, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get picked =>
      $composableBuilder(column: $table.picked, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnFilters(column));

  $$ShotsTableFilterComposer get shotId {
    final $$ShotsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.shotId,
      referencedTable: $db.shots,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$ShotsTableFilterComposer(
            $db: $db,
            $table: $db.shots,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$GenerationsTableOrderingComposer extends Composer<_$AppDatabase, $GenerationsTable> {
  $$GenerationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get remoteId =>
      $composableBuilder(column: $table.remoteId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get platform =>
      $composableBuilder(column: $table.platform, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get prompt =>
      $composableBuilder(column: $table.prompt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get resultNote =>
      $composableBuilder(column: $table.resultNote, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get picked =>
      $composableBuilder(column: $table.picked, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  $$ShotsTableOrderingComposer get shotId {
    final $$ShotsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.shotId,
      referencedTable: $db.shots,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$ShotsTableOrderingComposer(
            $db: $db,
            $table: $db.shots,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$GenerationsTableAnnotationComposer extends Composer<_$AppDatabase, $GenerationsTable> {
  $$GenerationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get remoteId =>
      $composableBuilder(column: $table.remoteId, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<VideoPlatform, String> get platform =>
      $composableBuilder(column: $table.platform, builder: (column) => column);

  GeneratedColumn<String> get prompt =>
      $composableBuilder(column: $table.prompt, builder: (column) => column);

  GeneratedColumn<String> get resultNote =>
      $composableBuilder(column: $table.resultNote, builder: (column) => column);

  GeneratedColumn<bool> get picked =>
      $composableBuilder(column: $table.picked, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$ShotsTableAnnotationComposer get shotId {
    final $$ShotsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.shotId,
      referencedTable: $db.shots,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$ShotsTableAnnotationComposer(
            $db: $db,
            $table: $db.shots,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$GenerationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $GenerationsTable,
          Generation,
          $$GenerationsTableFilterComposer,
          $$GenerationsTableOrderingComposer,
          $$GenerationsTableAnnotationComposer,
          $$GenerationsTableCreateCompanionBuilder,
          $$GenerationsTableUpdateCompanionBuilder,
          (Generation, $$GenerationsTableReferences),
          Generation,
          PrefetchHooks Function({bool shotId})
        > {
  $$GenerationsTableTableManager(_$AppDatabase db, $GenerationsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$GenerationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$GenerationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GenerationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<DateTime> updatedAt = const Value.absent(),
                Value<String?> remoteId = const Value.absent(),
                Value<String> id = const Value.absent(),
                Value<String> shotId = const Value.absent(),
                Value<VideoPlatform> platform = const Value.absent(),
                Value<String> prompt = const Value.absent(),
                Value<String> resultNote = const Value.absent(),
                Value<bool> picked = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GenerationsCompanion(
                updatedAt: updatedAt,
                remoteId: remoteId,
                id: id,
                shotId: shotId,
                platform: platform,
                prompt: prompt,
                resultNote: resultNote,
                picked: picked,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<DateTime> updatedAt = const Value.absent(),
                Value<String?> remoteId = const Value.absent(),
                required String id,
                required String shotId,
                required VideoPlatform platform,
                required String prompt,
                Value<String> resultNote = const Value.absent(),
                Value<bool> picked = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GenerationsCompanion.insert(
                updatedAt: updatedAt,
                remoteId: remoteId,
                id: id,
                shotId: shotId,
                platform: platform,
                prompt: prompt,
                resultNote: resultNote,
                picked: picked,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$GenerationsTable, Generation>(table),
                  $$GenerationsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({shotId = false}) {
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
                    if (shotId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.shotId,
                        referencedTable: $$GenerationsTableReferences._shotIdTable(db),
                        referencedColumn: $$GenerationsTableReferences._shotIdTable(db).id,
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

typedef $$GenerationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $GenerationsTable,
      Generation,
      $$GenerationsTableFilterComposer,
      $$GenerationsTableOrderingComposer,
      $$GenerationsTableAnnotationComposer,
      $$GenerationsTableCreateCompanionBuilder,
      $$GenerationsTableUpdateCompanionBuilder,
      (Generation, $$GenerationsTableReferences),
      Generation,
      PrefetchHooks Function({bool shotId})
    >;
typedef $$KeyValuesTableCreateCompanionBuilder = KeyValuesCompanion Function({
  required String entryKey,
  required String entryValue,
  Value<int> rowid,
});
typedef $$KeyValuesTableUpdateCompanionBuilder = KeyValuesCompanion Function({
  Value<String> entryKey,
  Value<String> entryValue,
  Value<int> rowid,
});

class $$KeyValuesTableFilterComposer extends Composer<_$AppDatabase, $KeyValuesTable> {
  $$KeyValuesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get entryKey =>
      $composableBuilder(column: $table.entryKey, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get entryValue =>
      $composableBuilder(column: $table.entryValue, builder: (column) => ColumnFilters(column));
}

class $$KeyValuesTableOrderingComposer extends Composer<_$AppDatabase, $KeyValuesTable> {
  $$KeyValuesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get entryKey =>
      $composableBuilder(column: $table.entryKey, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get entryValue =>
      $composableBuilder(column: $table.entryValue, builder: (column) => ColumnOrderings(column));
}

class $$KeyValuesTableAnnotationComposer extends Composer<_$AppDatabase, $KeyValuesTable> {
  $$KeyValuesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get entryKey =>
      $composableBuilder(column: $table.entryKey, builder: (column) => column);

  GeneratedColumn<String> get entryValue =>
      $composableBuilder(column: $table.entryValue, builder: (column) => column);
}

class $$KeyValuesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $KeyValuesTable,
          KeyValueEntry,
          $$KeyValuesTableFilterComposer,
          $$KeyValuesTableOrderingComposer,
          $$KeyValuesTableAnnotationComposer,
          $$KeyValuesTableCreateCompanionBuilder,
          $$KeyValuesTableUpdateCompanionBuilder,
          (KeyValueEntry, BaseReferences<_$AppDatabase, $KeyValuesTable, KeyValueEntry>),
          KeyValueEntry,
          PrefetchHooks Function()
        > {
  $$KeyValuesTableTableManager(_$AppDatabase db, $KeyValuesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$KeyValuesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$KeyValuesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$KeyValuesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> entryKey = const Value.absent(),
            Value<String> entryValue = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => KeyValuesCompanion(entryKey: entryKey, entryValue: entryValue, rowid: rowid),
          createCompanionCallback: ({
            required String entryKey,
            required String entryValue,
            Value<int> rowid = const Value.absent(),
          }) => KeyValuesCompanion.insert(entryKey: entryKey, entryValue: entryValue, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$KeyValuesTable, KeyValueEntry>(table),
                  BaseReferences<_$AppDatabase, $KeyValuesTable, KeyValueEntry>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$KeyValuesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $KeyValuesTable,
      KeyValueEntry,
      $$KeyValuesTableFilterComposer,
      $$KeyValuesTableOrderingComposer,
      $$KeyValuesTableAnnotationComposer,
      $$KeyValuesTableCreateCompanionBuilder,
      $$KeyValuesTableUpdateCompanionBuilder,
      (KeyValueEntry, BaseReferences<_$AppDatabase, $KeyValuesTable, KeyValueEntry>),
      KeyValueEntry,
      PrefetchHooks Function()
    >;
typedef $$PropDrawingsTableCreateCompanionBuilder = PropDrawingsCompanion Function({
  required String name,
  Value<String?> drawingJson,
  required PropDrawingStatus status,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});
typedef $$PropDrawingsTableUpdateCompanionBuilder = PropDrawingsCompanion Function({
  Value<String> name,
  Value<String?> drawingJson,
  Value<PropDrawingStatus> status,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$PropDrawingsTableFilterComposer extends Composer<_$AppDatabase, $PropDrawingsTable> {
  $$PropDrawingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get drawingJson =>
      $composableBuilder(column: $table.drawingJson, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<PropDrawingStatus, PropDrawingStatus, String> get status =>
      $composableBuilder(
        column: $table.status,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$PropDrawingsTableOrderingComposer extends Composer<_$AppDatabase, $PropDrawingsTable> {
  $$PropDrawingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get drawingJson =>
      $composableBuilder(column: $table.drawingJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$PropDrawingsTableAnnotationComposer extends Composer<_$AppDatabase, $PropDrawingsTable> {
  $$PropDrawingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get drawingJson =>
      $composableBuilder(column: $table.drawingJson, builder: (column) => column);

  GeneratedColumnWithTypeConverter<PropDrawingStatus, String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$PropDrawingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PropDrawingsTable,
          PropDrawingRow,
          $$PropDrawingsTableFilterComposer,
          $$PropDrawingsTableOrderingComposer,
          $$PropDrawingsTableAnnotationComposer,
          $$PropDrawingsTableCreateCompanionBuilder,
          $$PropDrawingsTableUpdateCompanionBuilder,
          (PropDrawingRow, BaseReferences<_$AppDatabase, $PropDrawingsTable, PropDrawingRow>),
          PropDrawingRow,
          PrefetchHooks Function()
        > {
  $$PropDrawingsTableTableManager(_$AppDatabase db, $PropDrawingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$PropDrawingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$PropDrawingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PropDrawingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> name = const Value.absent(),
                Value<String?> drawingJson = const Value.absent(),
                Value<PropDrawingStatus> status = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PropDrawingsCompanion(
                name: name,
                drawingJson: drawingJson,
                status: status,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String name,
                Value<String?> drawingJson = const Value.absent(),
                required PropDrawingStatus status,
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PropDrawingsCompanion.insert(
                name: name,
                drawingJson: drawingJson,
                status: status,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PropDrawingsTable, PropDrawingRow>(table),
                  BaseReferences<_$AppDatabase, $PropDrawingsTable, PropDrawingRow>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PropDrawingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PropDrawingsTable,
      PropDrawingRow,
      $$PropDrawingsTableFilterComposer,
      $$PropDrawingsTableOrderingComposer,
      $$PropDrawingsTableAnnotationComposer,
      $$PropDrawingsTableCreateCompanionBuilder,
      $$PropDrawingsTableUpdateCompanionBuilder,
      (PropDrawingRow, BaseReferences<_$AppDatabase, $PropDrawingsTable, PropDrawingRow>),
      PropDrawingRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ProjectsTableTableManager get projects => $$ProjectsTableTableManager(_db, _db.projects);
  $$CharacterCardsTableTableManager get characterCards =>
      $$CharacterCardsTableTableManager(_db, _db.characterCards);
  $$ShotsTableTableManager get shots => $$ShotsTableTableManager(_db, _db.shots);
  $$GenerationsTableTableManager get generations =>
      $$GenerationsTableTableManager(_db, _db.generations);
  $$KeyValuesTableTableManager get keyValues => $$KeyValuesTableTableManager(_db, _db.keyValues);
  $$PropDrawingsTableTableManager get propDrawings =>
      $$PropDrawingsTableTableManager(_db, _db.propDrawings);
}
