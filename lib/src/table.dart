import 'package:mock_it/src/column.dart';
import 'package:strings/strings.dart';
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

  String primaryKey() {
    return columns.firstWhere((column) => column.primaryKey).name;
  }

  Map<String, dynamic> createOneValidate(Map<String, dynamic> body) {
    final schema = z.map({
      for (final column in columns) column.name: column.schema(),
    });

    final result = schema.safeParse(body);

    if (!result.success) {
      throw MockItException(400, result.error?.issues.first.message ?? 'Invalid request!', 'invalid_request');
    }

    return result.data;
  }

  Map<String, dynamic> updateOneValidate(Map<String, dynamic> body) {
    final schema = z.map({
      for (final column in columns) column.name: column.schema().optional(),
    });

    final result = schema.safeParse(body);

    if (!result.success) {
      throw MockItException(400, result.error?.issues.first.message ?? 'Invalid request!', 'invalid_request');
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

  Map<String, dynamic> toSwagger([List<Table> tables = const []]) {
    return {
      '/$name': {
        'post': {
          'description': 'Create $name',
          'tags': [name.toCapitalised()],
          'requestBody': {
            'required': true,
            'content': {
              'application/json': {
                'schema': {
                  'type': 'object',
                  'required': columns
                      .where((c) => c.primaryKey == false)
                      .where((c) => c.defaultValue == null)
                      .where((c) => c.nullable == false)
                      .map((column) => column.name)
                      .toList(),
                  'properties': {
                    for (final column
                        in columns
                            .where((c) => c.primaryKey == false)
                            .where((c) => c.defaultValue == null)
                            .where((c) => c.nullable == false))
                      column.name: column.toSwagger(),
                  },
                },
              },
            },
          },
          'responses': {
            '201': {
              'description': 'Created',
              'content': {
                'application/json': {
                  'schema': {
                    'type': 'object',
                    'properties': {
                      ...columns.fold(
                        {},
                        (previous, next) => {
                          ...previous,
                          next.name: next.toSwagger(),
                        },
                      ),
                    },
                  },
                },
              },
            },
            '400': {
              'description': 'Bad Request',
              'content': {
                'application/json': {
                  'schema': {
                    'type': 'object',
                    'properties': {
                      'message': {
                        'type': 'string',
                        'example': 'Invalid request!',
                      },
                      'code': {
                        'type': 'string',
                        'example': 'invalid_request',
                      },
                    },
                  },
                },
              },
            },
            '409': {
              'description': 'Conflict',
              'content': {
                'application/json': {
                  'schema': {
                    'type': 'object',
                    'properties': {
                      'message': {
                        'type': 'string',
                        'example': 'Conflict!',
                      },
                      'code': {
                        'type': 'string',
                        'example': 'conflict',
                      },
                    },
                  },
                },
              },
            },
            '500': {
              'description': 'Internal Server Error',
              'content': {
                'application/json': {
                  'schema': {
                    'type': 'object',
                    'properties': {
                      'message': {
                        'type': 'string',
                        'example': 'Internal Server Error',
                      },
                      'code': {
                        'type': 'string',
                        'example': 'internal_server_error',
                      },
                    },
                  },
                },
              },
            },
          },
        },
        'get': {
          'description': 'List $name',
          'tags': [name.toCamelCase()],
          'parameters': [
            for (final c in columns)
              {
                'name': c.name,
                'in': 'query',
                'required': false,
                'schema': {
                  'type': 'string',
                },
              },
          ],
          'requestBody': null,
          'responses': {
            '200': {
              'description': 'OK',
              'content': {
                'application/json': {
                  'schema': {
                    'type': 'object',
                    'properties': {
                      'page': {
                        'type': 'integer',
                        'example': 0,
                      },
                      'limit': {
                        'type': 'integer',
                        'example': 0,
                      },
                      'total': {
                        'type': 'integer',
                        'example': 0,
                      },
                      'data': {
                        'type': 'array',
                        'items': {
                          'type': 'object',
                          'properties': {
                            for (final column in columns) column.name: column.toSwagger(),
                          },
                        },
                      },
                    },
                  },
                },
              },
            },
            '500': {
              'description': 'Internal Server Error',
              'content': {
                'application/json': {
                  'schema': {
                    'type': 'object',
                    'properties': {
                      'message': {
                        'type': 'string',
                        'example': 'Internal Server Error',
                      },
                      'code': {
                        'type': 'string',
                        'example': 'internal_server_error',
                      },
                    },
                  },
                },
              },
            },
          },
        },
      },
      '/$name/{${trySingularize(name)}_${primaryKey()}}': {
        'get': {
          'description': 'Get ${trySingularize(name)} by id',
          'tags': [name.toCapitalised()],
          'parameters': [
            ...columns
                .where((c) => c.primaryKey)
                .map(
                  (c) => {
                    'name': '${trySingularize(name)}_${c.name}',
                    'in': 'path',
                    'required': true,
                    'schema': c.toSwagger(),
                  },
                ),
          ],
          'responses': {
            '200': {
              'description': 'OK',
              'content': {
                'application/json': {
                  'schema': {
                    'type': 'object',
                    'properties': {
                      ...columns.fold(
                        {},
                        (previous, next) => {
                          ...previous,
                          next.name: next.toSwagger(),
                        },
                      ),
                    },
                  },
                },
              },
            },
          },
        },
        if (columns.any((c) => c.name == 'updated_at'))
          'put': {
            'description': 'Update ${trySingularize(name)} by id',
            'tags': [name.toCapitalised()],
            'parameters': [
              ...columns
                  .where((c) => c.primaryKey)
                  .map(
                    (c) => {
                      'name': '${trySingularize(name)}_${c.name}',
                      'in': 'path',
                      'required': true,
                      'schema': c.toSwagger(),
                    },
                  ),
            ],
            'requestBody': {
              'required': true,
              'content': {
                'application/json': {
                  'schema': {
                    'type': 'object',
                    'properties': {
                      ...columns
                          .where((c) => c.primaryKey == false)
                          .where((c) => c.defaultValue == null)
                          .fold(
                            {},
                            (previous, next) => {
                              ...previous,
                              next.name: next.toSwagger(),
                            },
                          ),
                    },
                  },
                },
              },
            },
            'responses': {
              '200': {
                'description': 'OK',
                'content': {
                  'application/json': {
                    'schema': {
                      'type': 'object',
                      'properties': {
                        ...columns.fold(
                          {},
                          (previous, next) => {
                            ...previous,
                            next.name: next.toSwagger(),
                          },
                        ),
                      },
                    },
                  },
                },
              },
              '404': {
                'description': 'Not Found',
                'content': {
                  'application/json': {
                    'schema': {
                      'type': 'object',
                      'properties': {
                        'message': {
                          'type': 'string',
                          'example': 'Not Found',
                        },
                        'code': {
                          'type': 'string',
                          'example': 'not_found',
                        },
                      },
                    },
                  },
                },
              },
              '500': {
                'description': 'Internal Server Error',
                'content': {
                  'application/json': {
                    'schema': {
                      'type': 'object',
                      'properties': {
                        'message': {
                          'type': 'string',
                          'example': 'Internal Server Error',
                        },
                        'code': {
                          'type': 'string',
                          'example': 'internal_server_error',
                        },
                      },
                    },
                  },
                },
              },
            },
          },
        'delete': {
          'description': 'Delete ${trySingularize(name)} by id',
          'tags': [name.toCapitalised()],
          'parameters': [
            ...columns
                .where((c) => c.primaryKey)
                .map(
                  (c) => {
                    'name': '${trySingularize(name)}_${c.name}',
                    'in': 'path',
                    'required': true,
                    'schema': c.toSwagger(),
                  },
                ),
          ],
          'responses': {
            '200': {
              'description': 'OK',
              'content': {
                'application/json': {
                  'schema': {
                    'type': 'object',
                    'properties': {
                      ...columns.fold(
                        {},
                        (previous, next) => {
                          ...previous,
                          next.name: next.toSwagger(),
                        },
                      ),
                    },
                  },
                },
              },
            },
            '404': {
              'description': 'Not Found',
              'content': {
                'application/json': {
                  'schema': {
                    'type': 'object',
                    'properties': {
                      'message': {
                        'type': 'string',
                        'example': 'Not Found',
                      },
                      'code': {
                        'type': 'string',
                        'example': 'not_found',
                      },
                    },
                  },
                },
              },
            },
            '500': {
              'description': 'Internal Server Error',
              'content': {
                'application/json': {
                  'schema': {
                    'type': 'object',
                    'properties': {
                      'message': {
                        'type': 'string',
                        'example': 'Internal Server Error',
                      },
                      'code': {
                        'type': 'string',
                        'example': 'internal_server_error',
                      },
                    },
                  },
                },
              },
            },
          },
        },
      },
      for (final table in tables.where((t) => columns.any((c) => c.referencesTable == t.name))) ...{
        '/${table.name}/{${trySingularize(table.name)}_${table.primaryKey()}}/$name': {
          'get': {
            'description': 'Get $name from ${trySingularize(table.name)} by id',
            'tags': [table.name.toCapitalised()],
            'parameters': [
              ...columns
                  .where((c) => c.primaryKey == false)
                  .map(
                    (c) => {
                      'name': c.name,
                      'in': 'query',
                      'required': false,
                      'schema': c.toSwagger(),
                    },
                  ),
              ...columns
                  .where((c) => c.primaryKey)
                  .map(
                    (c) => {
                      'name': '${trySingularize(table.name)}_${c.name}',
                      'in': 'path',
                      'required': true,
                      'schema': {'type': 'string'},
                    },
                  ),
            ],
            'responses': {
              '200': {
                'description': 'OK',
                'content': {
                  'application/json': {
                    'schema': {
                      'type': 'object',
                      'properties': {
                        ...columns.fold(
                          {},
                          (previous, next) => {
                            ...previous,
                            next.name: next.toSwagger(),
                          },
                        ),
                      },
                    },
                  },
                },
              },
            },
          },
        },
        '/${table.name}/{${trySingularize(table.name)}_${table.primaryKey()}}/$name/{${trySingularize(name)}_${columns.firstWhere((c) => c.primaryKey).name}}':
            {
              'get': {
                'description': 'Get ${trySingularize(name)} from ${trySingularize(table.name)} by id',
                'tags': [table.name.toCapitalised()],
                'parameters': [
                  ...table.columns
                      .where((c) => c.primaryKey)
                      .map(
                        (c) => {
                          'name': '${trySingularize(table.name)}_${c.name}',
                          'in': 'path',
                          'required': true,
                          'schema': c.toSwagger(),
                        },
                      ),
                  ...columns
                      .where((c) => c.primaryKey)
                      .map(
                        (c) => {
                          'name': '${trySingularize(name)}_${c.name}',
                          'in': 'path',
                          'required': true,
                          'schema': c.toSwagger(),
                        },
                      ),
                ],
                'responses': {
                  '200': {
                    'description': 'OK',
                    'content': {
                      'application/json': {
                        'schema': {
                          'type': 'object',
                          'properties': {
                            ...columns.fold(
                              {},
                              (previous, next) => {
                                ...previous,
                                next.name: next.toSwagger(),
                              },
                            ),
                          },
                        },
                      },
                    },
                  },
                },
              },
            },
      },
    };
  }
}

String trySingularize(String text) {
  if (text.endsWith('s')) return text.substring(0, text.length - 1);
  if (text.endsWith('ies')) return '${text.substring(0, text.length - 3)}y';
  if (text.endsWith('es')) return text.substring(0, text.length - 2);
  return text;
}
