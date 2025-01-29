String? dateTimeIsNotEmptyValidator(DateTime? dateTime) {
  if (dateTime == null) {
    return "Cannot empty";
  }
  return null;
}

String? stringIsPositiveNumberValidator(String? text) {
  if (text == null || text.isEmpty) {
    return "Cannot empty. Must be number";
  }
  int number = int.parse(text);
  if (number <= 0) {
    return "Must be positive number";
  }
  return null;
}

String? stringNotEmptyValidator(String? text) {
  if (text == null || text.trim().isEmpty) {
    return "Cannot empty";
  }
  return null;
}