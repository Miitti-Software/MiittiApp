import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';
import 'package:latlong2/latlong.dart';
import 'package:miitti_app/constants/genders.dart';
import 'package:miitti_app/constants/languages.dart';
import 'package:miitti_app/models/miitti_activity.dart';
import 'package:miitti_app/models/miitti_user.dart';

class UserCreatedActivity extends MiittiActivity {
  bool requiresRequest;
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
    required super.latestActivity,
    required super.paid,
    required super.maxParticipants,
    required super.participants,
    required super.participantsInfo,
    required this.requiresRequest,
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
      latestActivity: data['latestActivity'].toDate(),
      paid: data['paid'],
      maxParticipants: data['maxParticipants'],
      participants: List<String>.from(data['participants']),
      participantsInfo: (data['participantsInfo'] as Map<String, dynamic>).map((key, value) => MapEntry(key, {
        'name': value['name'],
        'profilePicture': value['profilePicture'],
        'location': value['location'] != null ? LatLng(value['location']['latitude'], value['location']['longitude']) : null,
        'joined': value['joined']?.toDate(),
        'lastSeen': value['lastSeen']?.toDate(),    // In the context of the activity either in chat or ongoing miitti overlay, not overall
        'lastReadMessage': value['lastReadMessage'] ?? '',
      })),
      requiresRequest: data['requiresRequest'],
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

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'location': GeoFirePoint(GeoPoint(latitude, longitude)).data,
      'longitude': longitude,
      'latitude': latitude,
      'address': address,
      'creator': creator,
      'creationTime': creationTime,
      'startTime': startTime,
      'endTime': endTime,
      'latestActivity': DateTime.now(),
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
        'joined': value['joined'],
        'lastSeen': DateTime.now(),
        'lastReadMessage': value['lastReadMessage'],
      })),
      'requiresRequest': requiresRequest,
      'requests': requests,
      'creatorLanguages': creatorLanguages.map((e) => e.toString().split('.').last).toList(),
      'creatorGender': creatorGender.name,
      'creatorAge': creatorAge,
    };
  }

  UserCreatedActivity addRequest(String userId) {
    requests.add(userId);
    return this;
  }

  UserCreatedActivity removeRequest(String userId) {
    requests.remove(userId);
    return this;
  }

  @override
  UserCreatedActivity addParticipant(MiittiUser user) {
    participants.add(user.uid);
    participantsInfo[user.uid] = {
      'name': user.name,
      'profilePicture': user.profilePicture,
      'location': null,
      'joined': DateTime.now(),
      'lastSeen': DateTime.now(),
      'lastReadMessage': '',
    };
    return this;
  }

  @override
  UserCreatedActivity removeParticipant(MiittiUser user) {
    requests.remove(user.uid);
    participants.remove(user.uid);
    return this;
  }
}
