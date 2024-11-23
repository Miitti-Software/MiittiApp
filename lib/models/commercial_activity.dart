import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';
import 'package:miitti_app/models/miitti_activity.dart';
import 'package:miitti_app/models/miitti_user.dart';

class CommercialActivity extends MiittiActivity {
  String linkTitle;
  String hyperlink;
  String bannerImage;
  String customEmoji;
  String organization;

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
    required super.latestActivity,
    required super.paid,
    required super.maxParticipants,
    required super.participants,
    required super.participantsInfo,
    required this.linkTitle,
    required this.hyperlink,
    required this.bannerImage,
    required this.customEmoji,
    required this.organization,
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
      category: data['category'] ?? '',
      longitude: data['longitude'],
      latitude: data['latitude'],
      address: data['address'],
      creator: data['creator'] ?? '',
      creationTime: data['creationTime']?.toDate(),
      startTime: data['startTime']?.toDate(),
      endTime: data['endTime']?.toDate(),
      latestActivity: data['latestActivity']?.toDate(),
      paid: data['paid'],
      maxParticipants: data['maxParticipants'] ?? 1000000,
      participants: List<String>.from(data['participants']),
      participantsInfo: (data['participantsInfo'] as Map<String, dynamic>).map((key, value) => MapEntry(key, {
        'name': value['name'],
        'profilePicture': value['profilePicture'],
        'joined': value['joined']?.toDate(),
        'lastSeen': value['lastSeen']?.toDate(),    // In the context of the activity either in chat or ongoing miitti overlay, not overall
        'lastReadMessage': value['lastReadMessage'] ?? '',
      })),
      linkTitle: data['linkTitle'],
      hyperlink: data['hyperlink'],
      bannerImage: data['bannerImage'],
      customEmoji: data['customEmoji'],
      organization: data['organization'],
      views: data['views'] ?? 0,
      clicks: data['clicks'] ?? 0,
      hyperlinkClicks: data['hyperlinkClicks'] ?? 0,
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
      'location': GeoFirePoint(GeoPoint(latitude, longitude)).data,
      'address': address,
      'creator': creator,
      'creationTime': creationTime,
      'startTime': startTime,
      'endTime': endTime,
      'latestActivity': latestActivity,
      'paid': paid,
      'maxParticipants': maxParticipants,
      'participants': participants,
      'participantsInfo': participantsInfo.map((key, value) => MapEntry(key, {
        'name': value['name'],
        'profilePicture': value['profilePicture'],
        'joined': value['joined'],
        'lastSeen': value['lastSeen'],
        'lastReadMessage': value['lastReadMessage'],
      })),
      'linkTitle': linkTitle,
      'hyperlink': hyperlink,
      'bannerImage': bannerImage,
      'customEmoji': customEmoji,
      'organization': organization,
      'views': views,
      'clicks': clicks,
      'hyperlinkClicks': hyperlinkClicks,
    };
  }

  @override
  CommercialActivity addParticipant(MiittiUser user) {
    participants.add(user.uid);
    latestActivity = DateTime.now();
    participantsInfo[user.uid] = {
      'name': user.name,
      'profilePicture': user.profilePicture,
      'joined': DateTime.now(),
      'lastSeen': DateTime.now(),
      'lastReadMessage': '',
    };
    return this;
  }

  @override
  CommercialActivity removeParticipant(MiittiUser user) {
    participants.remove(user.uid);
    return this;
  }

  @override
  CommercialActivity notifyParticipants() {
    latestActivity = DateTime.now();
    return this;
  }

  @override
  CommercialActivity markSeen(String userId) {
    participantsInfo[userId]!['lastSeen'] = DateTime.now();
    return this;
  }

  @override
  CommercialActivity updateStartTime(DateTime? startTime) {
    this.startTime = startTime;
    latestActivity = DateTime.now();
    return this;
  }

  @override
  CommercialActivity updateEndTime(DateTime? endTime) {
    if (endTime != null && startTime != null && startTime!.isAfter(endTime)) {
      startTime = endTime;
    }
    this.endTime = endTime;
    return this;
  }
}
