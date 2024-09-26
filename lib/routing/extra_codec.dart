import 'dart:convert';
import 'package:miitti_app/models/user_created_activity.dart';

// Currently redundant - if it ever becomes necessary, the json conversions must be done in the model classes, all go router extras calls go through here and hence everything must be nullable
class UserCreatedActivityCodec extends Codec<UserCreatedActivity?, String?> {
  @override
  Converter<String?, UserCreatedActivity?> get decoder => _UserCreatedActivityDecoder();

  @override
  Converter<UserCreatedActivity?, String?> get encoder => _UserCreatedActivityEncoder();
}

class _UserCreatedActivityDecoder extends Converter<String?, UserCreatedActivity?> {
  @override
  UserCreatedActivity? convert(String? input) {
    if (input == null) return null;
    final Map<String, dynamic> jsonMap = jsonDecode(input);
    if (jsonMap['creationTime'] != null) {
      jsonMap['creationTime'] = DateTime.parse(jsonMap['creationTime']);
    }
    if (jsonMap['startTime'] != null) {
      jsonMap['startTime'] = DateTime.parse(jsonMap['startTime']);
    }
    if (jsonMap['endTime'] != null) {
      jsonMap['endTime'] = DateTime.parse(jsonMap['endTime']);
    }
    return UserCreatedActivity.fromMap(jsonMap);
  }
}

class _UserCreatedActivityEncoder extends Converter<UserCreatedActivity?, String?> {
  @override
  String? convert(UserCreatedActivity? input) {
    if (input == null) return null;
    final Map<String, dynamic> jsonMap = input.toMap();
    if (jsonMap['creationTime'] != null) {
      jsonMap['creationTime'] = (jsonMap['creationTime'] as DateTime).toIso8601String();
    }
    if (jsonMap['startTime'] != null) {
      jsonMap['startTime'] = (jsonMap['startTime'] as DateTime).toIso8601String();
    }
    if (jsonMap['endTime'] != null) {
      jsonMap['endTime'] = (jsonMap['endTime'] as DateTime).toIso8601String();
    }
    return jsonEncode(jsonMap);
  }
}