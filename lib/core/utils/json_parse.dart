num? nullableNumValue(Object? value) {
  if (value == null) {
    return null;
  }

  if (value is num) {
    return value;
  }

  return num.tryParse('$value');
}
