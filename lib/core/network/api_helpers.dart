import '../errors/app_exception.dart';

Map<String, String> authHeaders(String accessToken) {
  return {
    'Authorization': 'Bearer $accessToken',
  };
}

List<Object?> expectList(Object? value, String source) {
  if (value is List) {
    return value.cast<Object?>();
  }

  if (value is Map<String, dynamic>) {
    final items = value['items'];
    if (items is List) {
      return items.cast<Object?>();
    }
  }

  throw AppException('Unexpected response received from $source.');
}

Map<String, dynamic> expectMap(Object? value, String source) {
  if (value is Map<String, dynamic>) {
    final item = value['item'];
    if (item is Map<String, dynamic>) {
      return item;
    }

    if (!value.containsKey('item')) {
      return value;
    }
  }

  throw AppException('Unexpected response received from $source.');
}

Map<String, dynamic> expectItem(Object? value, String source) {
  return expectMap(value, source);
}

String stringValue(Object? value) => '$value'.trim();

String? nullableStringValue(Object? value) {
  final normalized = '$value'.trim();
  if (normalized.isEmpty || normalized == 'null') {
    return null;
  }

  return normalized;
}

int intValue(Object? value) {
  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  return int.tryParse('$value') ?? 0;
}

DateTime? dateValue(Object? value) {
  final raw = nullableStringValue(value);
  if (raw == null) {
    return null;
  }

  return DateTime.tryParse(raw);
}

Map<String, String> queryParamsFrom(Map<String, String?> params) {
  return Map<String, String>.fromEntries(
    params.entries
        .where((entry) => entry.value != null && entry.value!.isNotEmpty)
        .map((entry) => MapEntry(entry.key, entry.value!)),
  );
}
