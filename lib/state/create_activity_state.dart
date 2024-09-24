import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:miitti_app/constants/genders.dart';
import 'package:miitti_app/constants/languages.dart';

class CreateActivityState extends StateNotifier<CreateActivityStateData> {
  CreateActivityState(this.ref) : super(CreateActivityStateData());
  final Ref ref;

  void update(Function(CreateActivityStateData) updateFn) {
    state = updateFn(state);
  }

  Future<void> refreshActivityData() async {
    // Add logic to refresh activity data if needed
  }
}

class CreateActivityStateData {
  final String? id;
  final String? title;
  final String? description;
  final String? category;
  final double? longitude;
  final double? latitude;
  final String? address;
  final String? creator;
  final DateTime? creationTime;
  final DateTime? startTime;
  final DateTime? endTime;
  final bool? paid;
  final int? maxParticipants;
  final List<String>? participants;
  final Map<String, Map<String, dynamic>>? participantsInfo;
  final bool? requiresRequest;
  final List<String>? requests;
  final List<Language>? creatorLanguages;
  final Gender? creatorGender;
  final int? creatorAge;

  CreateActivityStateData({
    this.id,
    this.title,
    this.description,
    this.category,
    this.longitude,
    this.latitude,
    this.address,
    this.creator,
    this.creationTime,
    this.startTime,
    this.endTime,
    this.paid,
    this.maxParticipants,
    this.participants,
    this.participantsInfo,
    this.requiresRequest,
    this.requests,
    this.creatorLanguages,
    this.creatorGender,
    this.creatorAge,
  });

  bool get isActivityCreated => id != null;

  CreateActivityStateData copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    double? longitude,
    double? latitude,
    String? address,
    String? creator,
    DateTime? creationTime,
    DateTime? startTime,
    DateTime? endTime,
    bool? paid,
    int? maxParticipants,
    List<String>? participants,
    Map<String, Map<String, dynamic>>? participantsInfo,
    bool? requiresRequest,
    List<String>? requests,
    List<Language>? creatorLanguages,
    Gender? creatorGender,
    int? creatorAge,
  }) {
    return CreateActivityStateData(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      longitude: longitude ?? this.longitude,
      latitude: latitude ?? this.latitude,
      address: address ?? this.address,
      creator: creator ?? this.creator,
      creationTime: creationTime ?? this.creationTime,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      paid: paid ?? this.paid,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      participants: participants ?? this.participants,
      participantsInfo: participantsInfo ?? this.participantsInfo,
      requiresRequest: requiresRequest ?? this.requiresRequest,
      requests: requests ?? this.requests,
      creatorLanguages: creatorLanguages ?? this.creatorLanguages,
      creatorGender: creatorGender ?? this.creatorGender,
      creatorAge: creatorAge ?? this.creatorAge,
    );
  }
}

final createActivityStateProvider = StateNotifierProvider<CreateActivityState, CreateActivityStateData>((ref) {
  return CreateActivityState(ref);
});