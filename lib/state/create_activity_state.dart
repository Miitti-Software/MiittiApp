import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:miitti_app/constants/genders.dart';
import 'package:miitti_app/constants/languages.dart';
import 'package:miitti_app/models/miitti_user.dart';
import 'package:miitti_app/models/user_created_activity.dart';
import 'package:miitti_app/services/analytics_service.dart';
import 'package:miitti_app/state/service_providers.dart';
import 'package:miitti_app/state/user.dart';

class CreateActivityState extends StateNotifier<CreateActivityStateData> {
  CreateActivityState(this.ref) : super(CreateActivityStateData());
  final Ref ref;

  List<MiittiUser> invitedUsers = [];

  UserCreatedActivity? get activity => state.isActivityCreated ? UserCreatedActivity(
    id: state.id!,
    title: state.title!,
    description: state.description!,
    category: state.category!,
    longitude: state.longitude!,
    latitude: state.latitude!,
    address: state.address!,
    creator: state.creator!,
    creationTime: state.creationTime!,
    startTime: state.startTime,
    endTime: state.endTime,
    paid: state.paid!,
    maxParticipants: state.maxParticipants!,
    participants: state.participants!,
    participantsInfo: state.participantsInfo!,
    requiresRequest: state.requiresRequest!,
    requests: state.requests!,
    creatorLanguages: state.creatorLanguages!,
    creatorGender: state.creatorGender!,
    creatorAge: state.creatorAge!,
  ) : null; 

  void update(Function(CreateActivityStateData) updateFn) {
    state = updateFn(state);
  }

  Future<UserCreatedActivity> createUserCreatedActivity() async {
    final creator = ref.read(userStateProvider).data;
    if (ref.read(userStateProvider).isAnonymous) {
      throw Exception('Anonymous users cannot create activities');
    }
    final address = await getAddressFromCoordinates(state.latitude!, state.longitude!);
    final activity = UserCreatedActivity(
      id: generateCustomId(),
      title: state.title!,
      description: state.description!,
      category: state.category!,
      longitude: state.longitude!,
      latitude: state.latitude!,
      address: address,
      creator: creator.uid!,
      creationTime: DateTime.now(),
      startTime: state.startTime,
      endTime: state.endTime,
      paid: state.paid!,
      maxParticipants: state.maxParticipants!,
      participants: [creator.uid!],
      participantsInfo: <String, Map<String, dynamic>>{
        creator.uid!: {
          'name': creator.name,
          'profilePicture': creator.profilePicture,
          'location': null,
        }
      },
      requiresRequest: state.requiresRequest!,
      requests: [],
      creatorLanguages: creator.languages,
      creatorGender: creator.gender!,
      creatorAge: ref.read(userStateProvider.notifier).getAge(),
    );
    return activity;
  }

  Future<void> publishUserCreatedActivity() async {
    final activity = await createUserCreatedActivity();
    await ref.read(firestoreServiceProvider).createActivity(activity.id, activity.toMap());
    ref.read(analyticsServiceProvider).logUserCreatedActivityCreated(activity, ref.read(userStateProvider).data.toMiittiUser());
    final user = ref.read(userStateProvider).data;
    user.incrementActivitiesCreated();
    ref.read(userStateProvider.notifier).updateUserData();
    for (final invitee in invitedUsers) {
      ref.read(notificationServiceProvider).sendInviteNotification(user.toMiittiUser(), invitee, activity);
    }
    Future.delayed(const Duration(seconds: 1), () {
      state = CreateActivityStateData();
    });
  }

  String generateCustomId() {
    final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final String random = Random().nextInt(9999999).toString().padLeft(7, '0');
    return '$timestamp$random';
  }

  Future<String> getAddressFromCoordinates(
      double latitude, double longitude) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);

      if (placemarks.isNotEmpty) {
        Placemark placemark = placemarks[0];
        String address = placemark.subLocality!.isEmpty
            ? '${placemark.locality}'
            : '${placemark.subLocality}, ${placemark.locality}';
        return address;
      } else {
        return "";
      }
    } catch (e) {
      return "";
    }
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
    this.paid = false,
    this.maxParticipants = 5,
    this.participants = const [],
    this.participantsInfo,
    this.requiresRequest = true,
    this.requests = const [],
    this.creatorLanguages = const [],
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

  CreateActivityStateData copyWithNullableStartTime({
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
      startTime: startTime,
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