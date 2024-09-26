class CommercialSpot {
  String id;
  String name;
  String address;
  String image;
  String organization;
  double longitude;
  double latitude;
  List<String> categories;

  int views;
  int cliks;
  int activitiesArranged;

  CommercialSpot({
    required this.id,
    required this.name,
    required this.address,
    required this.image,
    required this.organization,
    required this.latitude,
    required this.longitude,
    required this.categories,
    required this.views,
    required this.cliks,
    required this.activitiesArranged,
  });

  factory CommercialSpot.fromFirestore(Map<String, dynamic> map) {
    return CommercialSpot(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      address: map['address'] ?? '',
      image: map['image'] ?? '',
      organization: map['organization'] ?? '',
      latitude: map['latitude'] ?? 0,
      longitude: map['longitude'] ?? 0,
      categories: List<String>.from(map['categories'] ?? []),
      views: map['views'] ?? 0,
      cliks: map['cliks'] ?? 0,
      activitiesArranged: map['activitiesArranged'] ?? 0,
    );
  }
}
