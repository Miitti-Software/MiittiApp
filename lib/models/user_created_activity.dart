import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';
import 'package:miitti_app/constants/genders.dart';
import 'package:miitti_app/constants/languages.dart';
import 'package:miitti_app/models/miitti_activity.dart';

class UserCreatedActivity extends MiittiActivity {
  Map<String, LatLng> participantLocations;
  List<String> requests;
  List<Language> creatorLanguages;
  Gender creatorGender;
  int creatorAge;

  UserCreatedActivity({
    required super.id,
    required super.title,
    required super.description,
    required super.category,
    required super.longitude,
    required super.latitude,
    required super.address,
    required super.creator,
    required super.creationTime,
    required super.startTime,
    required super.endTime,
    required super.paid,
    required super.maxParticipants,
    required super.participants,
    required this.requests,
    required this.creatorLanguages,
    required this.creatorGender,
    required this.creatorAge,
    required this.participantLocations,
  });

  factory UserCreatedActivity.fromFirestore(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>;
    return UserCreatedActivity(
      id: snapshot.id,
      title: data['title'],
      description: data['description'],
      category: data['category'],
      longitude: data['longitude'],
      latitude: data['latitude'],
      address: data['address'],
      creator: data['creator'],
      creationTime: data['creationTime'].toDate(),
      startTime: data['startTime']?.toDate(),
      endTime: data['endTime']?.toDate(),
      paid: data['paid'],
      maxParticipants: data['maxParticipants'],
      participants: List<String>.from(data['participants']),
      requests: List<String>.from(data['requests']),
      creatorLanguages: List.from(data['creatorLanguages']).map((elem) => Language.values.firstWhere((e) => e.toString().split('.').last.toLowerCase() == elem.toLowerCase())).toList(),
      creatorGender: Gender.values.firstWhere((e) => e.toString().split('.').last.toLowerCase() == data['creatorGender'].toLowerCase()),
      creatorAge: data['creatorAge'],
      participantLocations: (data['participantLocations'] as Map<String, dynamic>).map((key, value) => MapEntry(key, LatLng(value['latitude'], value['longitude']))),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'longitude': longitude,
      'latitude': latitude,
      'address': address,
      'creator': creator,
      'creationTime': creationTime,
      'startTime': startTime,
      'endTime': endTime,
      'paid': paid,
      'maxParticipants': maxParticipants,
      'participants': participants,
      'requests': requests,
      'creatorLanguages': creatorLanguages,
      'creatorGender': creatorGender.name,
      'creatorAge': creatorAge,
      'participantLocations': participantLocations.map((key, value) => MapEntry(key, {'latitude': value.latitude, 'longitude': value.longitude})),
    };
  }
}
