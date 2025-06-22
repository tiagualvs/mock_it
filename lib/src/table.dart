import 'package:mock_it/src/column.dart';
import 'package:zard/zard.dart';

import 'exceptions.dart';

class Table {
  final String name;
  final List<Column> columns;

  const Table({required this.name, required this.columns});

  bool hasReferences() {
    return columns.any((column) => column.hasReferences());
  }

  bool hasPrimaryKey() {
    return columns.any((column) => column.primaryKey);
  }

  Map<String, dynamic> createOneValidate(Map<String, dynamic> body) {
    final schema = z.map({
      for (final column in columns) column.name: column.schema(),
    });

    final result = schema.safeParse(body);

    if (!result.success) {
      throw MockItException(400, result.error?.issues.first.message ?? 'Invalid request!');
    }

    return result.data;
  }

  Map<String, dynamic> updateOneValidate(Map<String, dynamic> body) {
    final schema = z.map({
      for (final column in columns) column.name: column.schema().optional(),
    });

    final result = schema.safeParse(body);

    if (!result.success) {
      throw MockItException(400, result.error?.issues.first.message ?? 'Invalid request!');
    }

    return result.data;
  }

  @override
  String toString() => 'Table(name: $name, columns: $columns)';

  Map<String, dynamic> toMap() => {
    'name': name,
    'columns': columns.map((e) => e.toMap()).toList(),
  };

  static Table fromMap(Map<String, dynamic> map) => Table(
    name: map['name'],
    columns: (map['columns'] as List).map((e) => Column.fromMap(e)).toList(),
  );

  Table copyWith({
    String? name,
    List<Column>? columns,
  }) {
    return Table(
      name: name ?? this.name,
      columns: columns ?? this.columns,
    );
  }

  @override
  bool operator ==(covariant Table other) {
    if (identical(this, other)) return true;
    bool listEquals(List a, List b) {
      if (a.length != b.length) return false;
      for (int i = 0; i < a.length; i++) {
        if (a[i] != b[i]) return false;
      }
      return true;
    }

    return other.name == name && listEquals(other.columns, columns);
  }

  @override
  int get hashCode => name.hashCode ^ columns.hashCode;
}
