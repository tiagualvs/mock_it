import 'dart:convert';

import 'package:shelf/shelf.dart';

class MockItException implements Exception {
  final int statusCode;
  final String message;

  const MockItException(this.statusCode, this.message);

  Response toResponse() {
    return Response(
      statusCode,
      body: json.encode({'message': message}),
      headers: {'Content-Type': 'application/json'},
    );
  }
}
