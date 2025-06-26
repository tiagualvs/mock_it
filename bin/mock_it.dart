import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:mock_it/src/extensions/exception_extension.dart';
import 'package:mock_it/src/parser.dart';
import 'package:mock_it/src/table.dart';
import 'package:path/path.dart' as p;
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_cors_headers/shelf_cors_headers.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_swagger_ui/shelf_swagger_ui.dart';
import 'package:sqlite3/sqlite3.dart';

final parser = ArgParser()
  ..addOption('port', abbr: 'p', help: 'Port to listen on!')
  ..addOption('input', abbr: 'i', help: 'Path to the input SQL file!')
  ..addOption('database', abbr: 'd', help: 'Path to the input database file!')
  ..addFlag('help', abbr: 'h', defaultsTo: false);
void main(List<String> args) async {
  final result = parser.parse(args);
  if (result['help'] as bool) {
    stdout.writeln(parser.usage);
    exit(0);
  }
  final port = switch (RegExp(r'\d+').hasMatch(result['port'] as String? ?? '')) {
    true => int.parse(result['port'] as String),
    false => 8080,
  };
  final input = switch (result['input'] != null) {
    true => File(p.normalize(result['input'] as String)),
    false => File(p.join(Directory.current.path, 'schema.sql')),
  };
  final db = switch (result['database'] != null) {
    true => sqlite3.open(p.normalize(result['database'] as String)),
    false => sqlite3.openInMemory(),
  };
  final content = await input.readAsString();
  final tables = await parseSqlFile(content);
  db.execute(content);
  final overrideHeaders = {
    ACCESS_CONTROL_ALLOW_ORIGIN: '*',
    ACCESS_CONTROL_ALLOW_HEADERS: 'Content-Type, Authorization',
    ACCESS_CONTROL_ALLOW_METHODS: 'GET, POST, PUT, DELETE, PATCH, OPTIONS',
  };
  final router = Router();
  final swagger = <String, dynamic>{
    'openapi': '3.0.0',
    'info': {
      'title': 'MockIt',
      'version': '1.0.0',
      'description': 'MockIt API generated from SQL file.',
      'license': {
        'name': 'MIT',
        'url': 'https://choosealicense.com/licenses/mit/',
      },
    },
    'paths': {},
  };
  for (final table in tables) {
    swagger['paths'] = <String, dynamic>{
      ...?swagger['paths'],
      ...table.toSwagger(tables),
    };
    router.post(
      '/${table.name}',
      (Request request) async {
        try {
          if (request.headers['Content-Type'] != 'application/json') {
            return Response(
              400,
              body: json.encode(
                {
                  'message': 'Invalid request, expected application/json only!',
                  'code': 'invalid_content_type',
                },
              ),
              headers: {
                'Content-Type': 'application/json',
              },
            );
          }
          if ((request.contentLength ?? 0) <= 0) {
            return Response(
              400,
              body: json.encode(
                {
                  'message': 'Invalid request, body is empty!',
                  'code': 'empty_body',
                },
              ),
              headers: {
                'Content-Type': 'application/json',
              },
            );
          }
          final body = json.decode(await request.readAsString()) as Map<String, dynamic>;
          final validated = table.createOneValidate(body);
          if (table.hasReferences()) {
            final references = table.columns.where((e) => e.hasReferences()).toList();

            for (final ref in references) {
              final check = db.select(
                'SELECT * FROM ${ref.referencesTable} WHERE ${ref.referencesColumn} = ?;',
                [validated[ref.name]],
              );

              if (check.isEmpty) {
                final referencePath = '${ref.referencesTable}/${ref.referencesColumn}/${validated[ref.name]}';
                return Response(
                  404,
                  body: json.encode(
                    {
                      'message': 'Reference to $referencePath not found!',
                      'code': 'reference_not_found',
                    },
                  ),
                  headers: {
                    'Content-Type': 'application/json',
                  },
                );
              }
            }
          }
          final names = validated.keys.toList();
          final result = db.select(
            'INSERT INTO ${table.name} (${names.map((e) => e).join(', ')}) VALUES (${names.map((e) => '?').join(', ')}) RETURNING *;',
            validated.values.toList(),
          );
          if (result.isEmpty) {
            return Response(
              500,
              body: json.encode(
                {
                  'message': 'Fail to insert into ${table.name}!',
                  'code': 'internal_error',
                },
              ),
              headers: {
                'Content-Type': 'application/json',
              },
            );
          }
          return Response(
            201,
            body: json.encode(result.first),
            headers: {
              'Content-Type': 'application/json',
            },
          );
        } on Exception catch (e) {
          return e.toResponse();
        }
      },
    );
    router.get(
      '/${table.name}',
      (Request request) {
        try {
          final page = int.parse(request.url.queryParameters['page'] ?? '1');
          final limit = int.parse(request.url.queryParameters['limit'] ?? '10');
          final params = Map<String, String>.from(request.requestedUri.queryParameters)
            ..remove('page')
            ..remove('limit');
          for (final key in params.keys) {
            if (!table.columns.any((e) => e.name == key)) {
              params.remove(key);
            }
          }
          for (final key in params.keys) {
            final value = params[key] ?? '';

            final regex = RegExp(r'(\w+):(.+)');

            final match = regex.firstMatch(value);

            if (match != null) {
              final op1 = match.group(1);
              final val1 = match.group(2);

              print('op1 $op1 val1 $val1');
            }
          }
          final where = switch (params.isEmpty) {
            true => '',
            false => ' WHERE ${params.keys.map((e) => '$e = ?').join(' AND ')}',
          };
          final query = 'SELECT * FROM ${table.name}$where LIMIT ? OFFSET ?';
          final values = [
            for (final key in params.keys)
              switch (table.columns.firstWhere((e) => e.name == key).type) {
                'INT' || 'INTEGER' => int.parse(params[key] ?? '0'),
                'FLOAT' => double.parse(params[key] ?? '0'),
                'TIMESTAMP' || 'TIMESTAMPTZ' => DateTime.parse(params[key] ?? '0'),
                _ => params[key],
              },
            limit,
            (page - 1) * limit,
          ];
          final result = db.select(query, values);
          final total = db.select('SELECT COUNT(*) FROM ${table.name}')[0]['COUNT(*)'];
          final nextPageURL = request.requestedUri.replace(
            queryParameters: {
              ...request.url.queryParameters,
              'page': (page + 1).toString(),
            },
          );
          final prevPageURL = request.requestedUri.replace(
            queryParameters: {
              ...request.url.queryParameters,
              'page': (page - 1).toString(),
            },
          );
          return Response(
            200,
            body: json.encode(
              <String, dynamic>{
                'page': page,
                'limit': limit,
                'total': total,
                'next_page_url': page < total / limit ? nextPageURL.toString() : null,
                'prev_page_url': page > 1 ? prevPageURL.toString() : null,
                'data': result,
              },
            ),
            headers: {'Content-Type': 'application/json'},
          );
        } on Exception catch (e) {
          return e.toResponse();
        }
      },
    );
    if (table.hasPrimaryKey()) {
      final pkType = table.columns.firstWhere((e) => e.primaryKey).type;
      final pkName = table.columns.firstWhere((e) => e.primaryKey).name;
      final pkPattern = switch (pkType) {
        'INT' || 'INTEGER' => r'<pk|[\d]+>',
        'TEXT' => r'<pk|[\w]+>',
        _ => '<pk>',
      };

      recursiveRoutes(table, pkPattern, pkName, pkType, tables, router, db);

      router.get(
        '/${table.name}/$pkPattern',
        (Request request, String pk) {
          try {
            final result = db.select(
              'SELECT * FROM ${table.name} WHERE $pkName = ?',
              [
                switch (pkType) {
                  'INT' || 'INTEGER' => int.tryParse(pk),
                  _ => pk,
                },
              ],
            );

            if (result.isEmpty) {
              return Response(
                404,
                body: json.encode({'message': 'Not found!'}),
                headers: {'Content-Type': 'application/json'},
              );
            }

            return Response(
              200,
              body: json.encode(result.first),
              headers: {'Content-Type': 'application/json'},
            );
          } on Exception catch (e) {
            return e.toResponse();
          }
        },
      );
      if (table.columns.any((e) => e.name == 'updated_at')) {
        router.put(
          '/${table.name}/$pkPattern',
          (Request request, String pk) async {
            try {
              if (request.headers['Content-Type'] != 'application/json') {
                return Response(
                  400,
                  body: json.encode({'message': 'Invalid request, expected application/json only!'}),
                  headers: {'Content-Type': 'application/json'},
                );
              }
              if ((request.contentLength ?? 0) <= 0) {
                return Response(
                  400,
                  body: json.encode({'message': 'Invalid request, body is empty!'}),
                  headers: {'Content-Type': 'application/json'},
                );
              }
              final body = json.decode(await request.readAsString()) as Map<String, dynamic>;
              final validated = table.updateOneValidate(body);
              if (table.hasReferences()) {
                final references = table.columns
                    .where((e) => e.hasReferences())
                    .where((e) => validated.containsKey(e.name))
                    .toList();

                for (final reference in references) {
                  final select = db.select(
                    'SELECT * FROM ${reference.referencesTable} WHERE ${reference.referencesColumn} = ?',
                    [validated[reference.name]],
                  );

                  if (select.isEmpty) {
                    return Response(
                      400,
                      body: json.encode({'message': 'Fail to update ${table.name}!'}),
                      headers: {'Content-Type': 'application/json'},
                    );
                  }
                }
              }
              final names = validated.keys.toList();
              if (names.isEmpty) {
                return Response(
                  400,
                  body: json.encode({'message': 'Nothing to update in ${table.name}!'}),
                  headers: {'Content-Type': 'application/json'},
                );
              }
              names.add('updated_at');
              final result = db.select(
                'UPDATE ${table.name} SET ${names.map((e) => '$e = ?').join(', ')} WHERE $pkName = ? RETURNING *;',
                [...validated.values, DateTime.now().toUtc().toIso8601String(), pk],
              );
              if (result.isEmpty) {
                return Response(
                  400,
                  body: json.encode({'message': 'Fail to update ${table.name}!'}),
                  headers: {'Content-Type': 'application/json'},
                );
              }
              return Response(
                200,
                body: json.encode(result.first),
                headers: {'Content-Type': 'application/json'},
              );
            } on Exception catch (e) {
              return e.toResponse();
            }
          },
        );
      }
      router.delete(
        '/${table.name}/$pkPattern',
        (Request request, String pk) {
          try {
            final result = db.select(
              'DELETE FROM ${table.name} WHERE $pkName = ? RETURNING *;',
              [
                switch (pkType) {
                  'INT' || 'INTEGER' => int.tryParse(pk),
                  _ => pk,
                },
              ],
            );
            if (result.isEmpty) {
              return Response(
                404,
                body: json.encode(
                  {
                    'message': 'Not found!',
                    'code': 'not_found',
                  },
                ),
                headers: {'Content-Type': 'application/json'},
              );
            }
            return Response(
              200,
              body: json.encode(result.first),
              headers: {
                'Content-Type': 'application/json',
              },
            );
          } on Exception catch (e) {
            return e.toResponse();
          }
        },
      );
    }
  }
  router.mount(
    '/docs',
    SwaggerUI(json.encode(swagger), title: 'MockIt API').call,
  );
  final handler = Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(corsHeaders(headers: overrideHeaders))
      .addHandler(router.call);
  final server = await io.serve(handler, '0.0.0.0', port);
  print('Listening on http://${server.address.host}:${server.port}');
}

void recursiveRoutes(
  Table pkTable,
  String pkPattern,
  String pkName,
  String pkType,
  List<Table> tables,
  Router router,
  Database db,
) {
  if (tables.any((t) => t.columns.any((col) => col.referencesTable == pkTable.name))) {
    final fkTables = tables.where((t) => t.columns.any((col) => col.referencesTable == pkTable.name)).toSet().toList();

    for (final fkTable in fkTables) {
      final fkType = fkTable.columns.firstWhere((e) => e.hasReferences()).type;
      final fkName = fkTable.columns.firstWhere((e) => e.hasReferences()).name;
      final fkPattern = switch (fkType) {
        'INT' || 'INTEGER' => r'<fk|[\d]+>',
        _ => '<fk>',
      };
      router.get(
        '/${pkTable.name}/$pkPattern/${fkTable.name}',
        (Request request, String pk) {
          try {
            final page = int.parse(request.url.queryParameters['page'] ?? '1');
            final limit = int.parse(request.url.queryParameters['limit'] ?? '10');
            final params = Map<String, String>.from(request.requestedUri.queryParameters)
              ..remove('page')
              ..remove('limit');
            for (final key in params.keys) {
              if (!fkTable.columns.any((e) => e.name == key)) {
                params.remove(key);
              }
            }
            final where = switch (params.isEmpty) {
              true => '',
              false => ' AND ${params.keys.map((e) => '$e = ?').join(' AND ')}',
            };

            final result = db.select(
              'SELECT * FROM ${fkTable.name} WHERE $pkName = ?$where',
              [
                switch (pkType) {
                  'INT' || 'INTEGER' => int.tryParse(pk),
                  _ => pk,
                },
                for (final key in params.keys)
                  switch (fkTable.columns.firstWhere((e) => e.name == key).type) {
                    'INT' || 'INTEGER' => int.parse(params[key] ?? '0'),
                    'FLOAT' => double.parse(params[key] ?? '0'),
                    'TIMESTAMP' || 'TIMESTAMPTZ' => DateTime.parse(params[key] ?? '0'),
                    _ => params[key],
                  },
              ],
            );

            final total = db.select('SELECT COUNT(*) FROM ${fkTable.name} WHERE $pkName = ?', [pk])[0]['COUNT(*)'];

            return Response(
              200,
              body: json.encode({
                'page': page,
                'limit': limit,
                'total': total,
                'next_page_url': page < total / limit
                    ? request.requestedUri.replace(queryParameters: {'page': (page + 1).toString()}).toString()
                    : null,
                'prev_page_url': page > 1
                    ? request.requestedUri.replace(queryParameters: {'page': (page - 1).toString()}).toString()
                    : null,
                'data': result,
              }),
              headers: {'Content-Type': 'application/json'},
            );
          } on Exception catch (e) {
            return e.toResponse();
          }
        },
      );
      router.get(
        '/${pkTable.name}/$pkPattern/${fkTable.name}/$fkPattern',
        (Request request, String pk, String fk) {
          try {
            final result = db.select(
              'SELECT * FROM ${fkTable.name} WHERE $pkName = ? AND $fkName = ?',
              [
                switch (pkType) {
                  'INT' || 'INTEGER' => int.tryParse(pk),
                  _ => pk,
                },
                switch (fkType) {
                  'INT' || 'INTEGER' => int.tryParse(fk),
                  _ => fk,
                },
              ],
            );

            if (result.isEmpty) {
              return Response(
                404,
                body: json.encode(
                  {
                    'message': 'Not found!',
                    'code': 'not_found',
                  },
                ),
                headers: {'Content-Type': 'application/json'},
              );
            }

            return Response(
              200,
              body: json.encode(result.first),
              headers: {'Content-Type': 'application/json'},
            );
          } on Exception catch (e) {
            return e.toResponse();
          }
        },
      );

      if (tables.any((t) => t.columns.any((col) => col.referencesTable == fkTable.name))) {
        recursiveRoutes(fkTable, fkPattern, fkName, fkType, tables, router, db);
      }
    }
  }
}
