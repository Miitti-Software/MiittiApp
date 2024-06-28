extension DynamicExtensions on dynamic {
  Map<String, String> toStringMap() {
    if (this is Map<String, dynamic>) {
      return (this as Map<String, dynamic>).cast<String, String>();
    }
    return {};
  }
}
