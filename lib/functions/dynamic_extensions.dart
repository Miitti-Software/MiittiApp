extension DynamicExtensions on dynamic {
  List<String> toStringList() {
    if (this is List<dynamic>) {
      return (this as List<dynamic>).cast<String>();
    }
    return [];
  }

  Map<String, String> toStringMap() {
    if (this is Map<String, dynamic>) {
      return (this as Map<String, dynamic>).cast<String, String>();
    }
    return {};
  }
}
