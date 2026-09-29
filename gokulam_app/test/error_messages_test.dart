import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gokulam_app/services/error_messages.dart';

DioException _http(int? statusCode, Object? data,
    {DioExceptionType type = DioExceptionType.badResponse}) {
  final options = RequestOptions(path: '/api/auth/login/');
  return DioException(
    requestOptions: options,
    type: type,
    response: Response(requestOptions: options, statusCode: statusCode, data: data),
  );
}

void main() {
  test('server rejects username with spaces', () {
    expect(
      friendlyAuthError(_http(400, {
        'username': [
          'Enter a valid username. This value may contain only letters, numbers, and @/./+/-/_ characters.'
        ]
      })),
      'Username may only use letters, numbers and @ . _ + - (no spaces).',
    );
  });

  test('duplicate username', () {
    expect(
      friendlyAuthError(_http(400, {
        'username': ['A user with that username already exists.']
      })),
      'This username is already taken.',
    );
  });

  test('duplicate phone', () {
    expect(
      friendlyAuthError(_http(400, {
        'phone': ['user with this phone already exists.']
      })),
      'This phone number is already registered.',
    );
  });

  test('invalid email', () {
    expect(
      friendlyAuthError(_http(400, {'email': ['Enter a valid email address.']})),
      'Please enter a valid email address.',
    );
  });

  test('bad credentials maps to friendly login text', () {
    expect(
      friendlyAuthError(_http(401, {
        'non_field_errors': ['Invalid credentials']
      })),
      'Invalid username or password.',
    );
  });

  test('inactive account awaiting approval', () {
    expect(
      friendlyAuthError(_http(403, {
        'error': 'Account pending admin approval. Please wait.'
      })),
      'Account pending admin approval. Please wait.',
    );
  });

  test('network failure', () {
    expect(
      friendlyAuthError(_http(null, null, type: DioExceptionType.connectionError)),
      'Could not reach the server. Check your internet connection and try again.',
    );
  });

  test('unknown errors carry a diagnostic detail', () {
    expect(
      friendlyAuthError(Exception('boom')),
      'Something went wrong (Exception: boom). Please try again.',
    );
    expect(
      friendlyAuthError(_http(500, null)),
      'Server error (500). Please try again.',
    );
  });

  test('html error page is not dumped into the UI', () {
    expect(
      friendlyAuthError(_http(502, '<html><body>502 Bad Gateway</body></html>')),
      'Server error (502). Please try again.',
    );
  });

  test('failure before the request completed names the cause', () {
    final options = RequestOptions(path: '/api/auth/login/');
    expect(
      friendlyAuthError(DioException(
        requestOptions: options,
        type: DioExceptionType.unknown,
        error: PlatformException(code: 'BAD_PADDING_CLASS', message: 'Keystore failure'),
      )),
      'Could not complete the request (PlatformException(BAD_PADDING_CLASS, Keystore failure, null, null)). Please try again.',
    );
  });
}
