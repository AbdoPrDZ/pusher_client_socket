/// Represents a member of presence channel in Pusher.
class Member {
  /// The member's id.
  final String id;

  /// The member's info.
  final dynamic info;

  const Member({required this.id, this.info});

  /// Creates a new instance from a map.
  factory Member.fromMap(Map data) => Member(
        id: data["user_id"] ?? data['id'] ?? '',
        info: data['user_info'] ?? data["info"],
      );
}
