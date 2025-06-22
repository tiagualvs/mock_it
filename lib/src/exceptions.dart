import 'dart:convert';

import 'package:shelf/shelf.dart';

class MockItException implements Exception {
  final int statusCode;
  final String message;
  final String code;

  const MockItException(this.statusCode, this.message, this.code);

  Response toResponse() {
    return Response(
      statusCode,
      body: json.encode(
        {
          'message': message,
          'code': code,
        },
      ),
      headers: {'Content-Type': 'application/json'},
    );
  }
}
