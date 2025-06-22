import 'column.dart';
import 'table.dart';

Future<List<Table>> parseSqlFile(String content) async {
  final tableRegex = RegExp(
    r'CREATE\s+TABLE\s+(?:IF\s+NOT\s+EXISTS\s+)?([a-zA-Z0-9_]+)\s*\(([\s\S]*?)\);',
    caseSensitive: false,
  );

  final tables = <String, Table>{};

  for (final tableMatch in tableRegex.allMatches(content)) {
    final tableName = tableMatch.group(1)!;
    final rawColumns = tableMatch.group(2)!;

    final lines = rawColumns.split(',').map((line) => line.trim().replaceAll(RegExp(r'\s+'), ' ')).toList();

    final columns = <Column>[];

    for (var line in lines) {
      final lineUpper = line.toUpperCase();

      final refMatch = RegExp(
        r'REFERENCES\s+([a-zA-Z0-9_]+)\s*\(\s*([a-zA-Z0-9_]+)\s*\)',
        caseSensitive: false,
      ).firstMatch(line);

      if (lineUpper.startsWith('PRIMARY KEY') ||
          lineUpper.startsWith('FOREIGN KEY') ||
          lineUpper.startsWith('CONSTRAINT')) {
        continue;
      }

      final parts = line.split(' ');
      if (parts.length < 2) continue;

      final name = parts[0];
      final type = parts[1];

      final isPrimaryKey = lineUpper.contains('PRIMARY KEY');
      final isUnique = lineUpper.contains('UNIQUE');
      final isNullable = !lineUpper.contains('NOT NULL');
      final defaultMatch = RegExp(r'DEFAULT\s+([^\s,]+)', caseSensitive: false).firstMatch(line);
      final defaultValue = defaultMatch?.group(1);

      columns.add(
        Column(
          name: name,
          type: type,
          primaryKey: isPrimaryKey,
          unique: isUnique,
          nullable: isNullable,
          defaultValue: defaultValue,
          referencesTable: refMatch?.group(1),
          referencesColumn: refMatch?.group(2),
        ),
      );
    }

    tables[tableName] = Table(name: tableName, columns: columns);
  }

  return tables.values.toList();
}
