import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:miitti_app/models/miitti_activity.dart';
import 'package:miitti_app/models/miitti_user.dart';

class CommercialActivity extends MiittiActivity {
  String linkTitle;
  String hyperlink;
  String bannerImage;

  int views = 0;
  int clicks = 0;
  int hyperlinkClicks = 0;

  CommercialActivity({
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
    required this.linkTitle,
    required this.hyperlink,
    required this.bannerImage,
    required this.views,
    required this.clicks,
    required this.hyperlinkClicks,
  });

  factory CommercialActivity.fromFirestore(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>;
    return CommercialActivity(
      id: snapshot.id,
      title: data['title'],
      description: data['description'],
      category: data['category'],
      longitude: data['longitude'],
      latitude: data['latitude'],
      address: data['address'],
      creator: data['creator'],
      creationTime: data['creationTime'],
      startTime: data['startTime'],
      endTime: data['endTime'],
      paid: data['paid'],
      maxParticipants: data['maxParticipants'],
      participants: List<String>.from(data['participants']),
      participantsInfo: (data['participantsInfo'] as Map<String, dynamic>).map((key, value) => MapEntry(key, {
        'name': value['name'],
        'profilePicture': value['profilePicture'],
      })),
      linkTitle: data['linkTitle'],
      hyperlink: data['hyperlink'],
      bannerImage: data['bannerImage'],
      views: data['views'],
      clicks: data['clicks'],
      hyperlinkClicks: data['hyperlinkClicks'],
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
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
      })),
      'linkTitle': linkTitle,
      'hyperlink': hyperlink,
      'bannerImage': bannerImage,
      'views': views,
      'clicks': clicks,
      'hyperlinkClicks': hyperlinkClicks,
    };
  }

  @override
  Map<String, dynamic> addParticipant(MiittiUser user) {
    participants.add(user.uid);
    participantsInfo[user.uid] = {
      'name': user.name,
      'profilePicture': user.profilePicture,
    };
    return {
      'participants': participants,
      'participantsInfo': participantsInfo.map((key, value) => MapEntry(key, {
        'name': value['name'],
        'profilePicture': value['profilePicture'],
      })),
    };
  }

  @override
  Map<String, dynamic> removeParticipant(MiittiUser user) {
    participants.remove(user.uid);
    participantsInfo.remove(user.uid);
    return {
      'participants': participants,
      'participantsInfo': participantsInfo.map((key, value) => MapEntry(key, {
        'name': value['name'],
        'profilePicture': value['profilePicture'],
      })),
    };
  }
}
