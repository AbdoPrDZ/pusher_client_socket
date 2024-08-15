class Member {
  final String id;
  final Map<String, dynamic>? info;

  const Member({required this.id, this.info});

  factory Member.fromMap(Map data) =>
      Member(id: data["id"], info: data["info"]);
}
