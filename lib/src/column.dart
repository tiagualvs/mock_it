import 'package:zard/zard.dart';

class Column {
  final String name;
  final String type;
  final bool primaryKey;
  final bool unique;
  final bool nullable;
  final String? defaultValue;
  final String? referencesTable;
  final String? referencesColumn;

  const Column({
    required this.name,
    required this.type,
    this.primaryKey = false,
    this.unique = false,
    this.nullable = true,
    this.defaultValue,
    this.referencesTable,
    this.referencesColumn,
  });

  bool hasReferences() {
    return referencesTable != null && referencesColumn != null;
  }

  Schema schema() {
    if (type == 'TEXT' || type.startsWith('VARCHAR')) {
      if (defaultValue != null || primaryKey) return z.string().optional();
      if (nullable) return z.string().optional();
      return z.string();
    } else if (type == 'INT' || type == 'INTEGER') {
      if (defaultValue != null || primaryKey) return z.int().optional();
      if (nullable) return z.int().optional();
      return z.int();
    } else if (type == 'BOOLEAN') {
      if (defaultValue != null || primaryKey) return z.bool().optional();
      if (nullable) return z.bool().optional();
      return z.bool();
    } else if (type == 'TIMESTAMP' || type == 'DATETIME') {
      if (defaultValue != null || primaryKey) return z.date().optional();
      if (nullable) return z.date().optional();
      return z.date();
    } else {
      if (defaultValue != null || primaryKey) return z.string().optional();
      if (nullable) return z.string().optional();
      return z.string();
    }
  }

  // Atualize o toMap
  Map<String, dynamic> toMap() => {
    'name': name,
    'type': type,
    'primaryKey': primaryKey,
    'unique': unique,
    'nullable': nullable,
    'default': defaultValue,
    'referencesTable': referencesTable,
    'referencesColumn': referencesColumn,
  };

  static Column fromMap(Map<String, dynamic> map) => Column(
    name: map['name'],
    type: map['type'],
    primaryKey: map['primaryKey'],
    unique: map['unique'],
    nullable: map['nullable'],
    defaultValue: map['default'],
    referencesTable: map['referencesTable'],
    referencesColumn: map['referencesColumn'],
  );

  Column copyWith({
    String? name,
    String? type,
    bool? primaryKey,
    bool? unique,
    bool? nullable,
    String? Function()? defaultValue,
    String? Function()? referencesTable,
    String? Function()? referencesColumn,
  }) {
    return Column(
      name: name ?? this.name,
      type: type ?? this.type,
      primaryKey: primaryKey ?? this.primaryKey,
      unique: unique ?? this.unique,
      nullable: nullable ?? this.nullable,
      defaultValue: defaultValue != null ? defaultValue() : this.defaultValue,
      referencesTable: referencesTable != null ? referencesTable() : this.referencesTable,
      referencesColumn: referencesColumn != null ? referencesColumn() : this.referencesColumn,
    );
  }

  @override
  String toString() {
    return 'Column(name: $name, type: $type, primaryKey: $primaryKey, unique: $unique, nullable: $nullable, defaultValue: $defaultValue, referencesTable: $referencesTable, referencesColumn: $referencesColumn)';
  }

  @override
  bool operator ==(covariant Column other) {
    if (identical(this, other)) return true;

    return other.name == name &&
        other.type == type &&
        other.primaryKey == primaryKey &&
        other.unique == unique &&
        other.nullable == nullable &&
        other.defaultValue == defaultValue &&
        other.referencesTable == referencesTable &&
        other.referencesColumn == referencesColumn;
  }

  @override
  int get hashCode {
    return name.hashCode ^
        type.hashCode ^
        primaryKey.hashCode ^
        unique.hashCode ^
        nullable.hashCode ^
        defaultValue.hashCode ^
        referencesTable.hashCode ^
        referencesColumn.hashCode;
  }
}
