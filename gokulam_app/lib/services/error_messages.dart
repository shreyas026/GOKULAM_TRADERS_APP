import 'package:dio/dio.dart';

String friendlyAuthError(Object e) {
  final serverMessage = _serverError(e);
  if (serverMessage != null) return serverMessage;
  if (e is DioException) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return 'Could not reach the server. Check your internet connection and try again.';
      default:
        break;
    }
    final statusCode = e.response?.statusCode;
    if (statusCode != null) {
      return 'Server error ($statusCode). Please try again.';
    }
    final cause = e.error?.toString();
    return 'Could not complete the request${_parenthesised(cause)}. Please try again.';
  }
  return 'Something went wrong${_parenthesised(e.toString())}. Please try again.';
}

String _parenthesised(String? value) {
  if (value == null || value.trim().isEmpty) return '';
  final trimmed = value.trim();
  return ' (${trimmed.length > 160 ? '${trimmed.substring(0, 160)}...' : trimmed})';
}

String? _serverError(Object e) {
  if (e is! DioException) return null;
  final data = e.response?.data;
  if (data == null) return null;

  final messages = <String>[];
  if (data is Map) {
    for (final entry in data.entries) {
      final text = _flatten(entry.value).trim();
      if (text.isEmpty) continue;
      switch (entry.key.toString()) {
        case 'non_field_errors':
        case 'detail':
        case 'error':
        case 'message':
          messages.add(text);
          break;
        case 'username':
          messages.add(text.toLowerCase().contains('exists')
              ? 'This username is already taken.'
              : 'Username may only use letters, numbers and @ . _ + - (no spaces).');
          break;
        case 'phone':
          messages.add('This phone number is already registered.');
          break;
        case 'email':
          messages.add('Please enter a valid email address.');
          break;
        case 'password':
          messages.add('Password must be at least 6 characters.');
          break;
        default:
          messages.add(text);
      }
    }
  } else {
    final text = data.toString().trim();
    final looksLikeHtml = text.toLowerCase().startsWith('<') || text.toLowerCase().contains('<html');
    if (text.isEmpty || text == 'null') {
      return null;
    }
    if (looksLikeHtml || text.length > 300) {
      final statusCode = e.response?.statusCode;
      return statusCode != null ? 'Server error ($statusCode). Please try again.' : null;
    }
    messages.add(text);
  }

  if (messages.isEmpty) return null;
  final joined = messages.join('\n');
  if (e.response?.statusCode == 401 ||
      joined.toLowerCase().contains('invalid credentials') ||
      joined.toLowerCase().contains('no active account')) {
    return 'Invalid username or password.';
  }
  if (joined.toLowerCase().contains('pending admin approval')) {
    return 'Account pending admin approval. Please wait.';
  }
  return joined;
}

String _flatten(dynamic value) {
  if (value == null) return '';
  if (value is List) {
    return value.map(_flatten).where((e) => e.trim().isNotEmpty).join(' ');
  }
  if (value is Map) {
    return value.values.map(_flatten).where((e) => e.trim().isNotEmpty).join(' ');
  }
  return value.toString();
}
