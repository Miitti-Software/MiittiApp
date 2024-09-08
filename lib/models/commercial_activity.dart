import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:miitti_app/models/miitti_activity.dart';

class CommercialActivity extends MiittiActivity {
  String linkTitle;
  String hyperlink;
  String bannerImage;

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
    required this.linkTitle,
    required this.hyperlink,
    required this.bannerImage,
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
      participants: (data['participants'] as Map<String, dynamic>).map((key, value) => MapEntry(key, {
        'name': value['name'],
        'profilePicture': value['profilePicture'],
      })),
      linkTitle: data['linkTitle'],
      hyperlink: data['hyperlink'],
      bannerImage: data['bannerImage'],
    );
  }
}
