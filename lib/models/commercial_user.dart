class CommercialUser {
  String hyperlink;
  String businessId;
  String profilePicture;
  String name;
  String description;
  String linkTitle;

  CommercialUser({
    required this.name,
    required this.profilePicture,
    required this.hyperlink,
    required this.businessId,
    required this.description,
    required this.linkTitle,
  });

  factory CommercialUser.fromMap(Map<String, dynamic> map) {
    return CommercialUser(
      name: map['name'] ?? '',
      profilePicture: map['profilePicture'] ?? '',
      hyperlink: map['hyperlink'],
      businessId: map['businessId'],
      description: map['description'],
      linkTitle: map['linkTitle'],
    );
  }
}
