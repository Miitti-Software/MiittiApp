import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';
import 'package:miitti_app/constants/genders.dart';
import 'package:miitti_app/constants/languages.dart';
import 'package:miitti_app/models/miitti_activity.dart';
import 'package:miitti_app/models/miitti_user.dart';

class UserCreatedActivity extends MiittiActivity {
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
    required super.participantsInfo,
    required this.requests,
    required this.creatorLanguages,
    required this.creatorGender,
    required this.creatorAge,
  });

  factory UserCreatedActivity.fromMap(Map<String, dynamic> data) {
    return UserCreatedActivity(
      id: data['id'],
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
      participantsInfo: (data['participantsInfo'] as Map<String, dynamic>).map((key, value) => MapEntry(key, {
        'name': value['name'],
        'profilePicture': value['profilePicture'],
        'location': value['location'] != null ? LatLng(value['location']['latitude'], value['location']['longitude']) : null,
      })),
      requests: List<String>.from(data['requests']),
      creatorLanguages: List.from(data['creatorLanguages']).map((elem) => Language.values.firstWhere((e) => e.toString().split('.').last.toLowerCase() == elem.toLowerCase())).toList(),
      creatorGender: Gender.values.firstWhere((e) => e.toString().split('.').last.toLowerCase() == data['creatorGender'].toLowerCase()),
      creatorAge: data['creatorAge'],
    );
  }

  factory UserCreatedActivity.fromFirestore(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>;
    return UserCreatedActivity.fromMap(data);
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
      'participantsInfo': participantsInfo.map((key, value) => MapEntry(key, {
        'name': value['name'],
        'profilePicture': value['profilePicture'],
        'location': value['location'] != null ? {
          'latitude': (value['location'] as LatLng).latitude,
          'longitude': (value['location'] as LatLng).longitude,
        } : null,
      })),
      'requests': requests,
      'creatorLanguages': creatorLanguages.map((e) => e.toString().split('.').last).toList(),
      'creatorGender': creatorGender.name,
      'creatorAge': creatorAge,
    };
  }

  Map<String, dynamic> addRequest(String userId) {
    requests.add(userId);
    return {'requests': requests};
  }

  Map<String, dynamic> removeRequest(String userId) {
    requests.remove(userId);
    return {'requests': requests};
  }

  Map<String, dynamic> addParticipant(String userId, MiittiUser userInfo) {
    participants.add(userId);
    participantsInfo[userId] = {
      'name': userInfo.name,
      'profilePicture': userInfo.profilePicture,
    };
    return {
      'participants': participants,
      'participantsInfo': participantsInfo.map((key, value) => MapEntry(key, {
        'name': value['name'],
        'profilePicture': value['profilePicture'],
        'location': value['location'] != null ? {
          'latitude': (value['location'] as LatLng).latitude,
          'longitude': (value['location'] as LatLng).longitude,
        } : null,
      })),
    };
  }

  Map<String, dynamic> removeParticipant(String userId) {
    participants.remove(userId);
    participantsInfo.remove(userId);
    return {
      'participants': participants,
      'participantsInfo': participantsInfo.map((key, value) => MapEntry(key, {
        'name': value['name'],
        'profilePicture': value['profilePicture'],
        'location': value['location'] != null ? {
          'latitude': (value['location'] as LatLng).latitude,
          'longitude': (value['location'] as LatLng).longitude,
        } : null,
      })),
    };
  }
}
