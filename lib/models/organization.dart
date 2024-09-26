class Organization {
  final String id;
  final String name;
  final String image;
  final String website;

  Organization({
    required this.id,
    required this.name,
    required this.image,
    required this.website,
  });

  factory Organization.fromFirestore(Map<String, dynamic> map) {
    return Organization(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      image: map['image'] ?? '',
      website: map['website'] ?? '',
    );
  }
}