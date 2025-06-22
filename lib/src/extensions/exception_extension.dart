import 'dart:convert';

import 'package:mock_it/src/exceptions.dart';
import 'package:shelf/shelf.dart';
import 'package:sqlite3/sqlite3.dart';

extension ExceptionExtension on Exception {
  Response toResponse() {
    if (this is SqliteException) {
      final message = (this as SqliteException).message;
      if (message.contains('UNIQUE constraint failed')) {
        return Response(
          409,
          body: json.encode(
            {
              'message': message,
              'code': 'conflict',
            },
          ),
          headers: {
            'Content-Type': 'application/json',
          },
        );
      }
    }

    if (this is MockItException) {
      return (this as MockItException).toResponse();
    }

    return Response(
      500,
      body: json.encode(
        {
          'message': toString(),
          'code': 'internal_server_error',
        },
      ),
      headers: {
        'Content-Type': 'application/json',
      },
    );
  }
}
