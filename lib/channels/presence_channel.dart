import '../utils/collection.dart';
import '../utils/member.dart';
import 'private_channel.dart';

/// Represents a presence channel in Pusher.
class PresenceChannel extends PrivateChannel {
  PresenceChannel({
    required super.client,
    required super.name,
  }) {
    onMemberAdded(_onMemberAdd);
    onMemberRemoved(_onMemberRemove);
  }

  /// Binding for the member added event.
  void onMemberAdded(Function callback) =>
      bind('pusher:member_added', callback);

  /// Binding for the member removed event.
  void onMemberRemoved(Function callback) =>
      bind('pusher:member_removed', callback);

  /// The user member of the channel.
  @override
  Member? get member =>
      userId != null ? _members.get(userId!) ?? Member(id: userId!) : null;

  final _members = Collection<Member>();

  List<Member> get members => _members.all();

  void _onMemberAdd(Map data) {
    options.log("MEMBER_ADDED", name, "member: $data");

    final member = Member.fromMap(data);
    _members.add(member.id, Member.fromMap(data), override: true);
  }

  void _onMemberRemove(Map data) {
    options.log("MEMBER_REMOVED", name, "member: $data");

    final id = data["user_id"] ?? data["id"];

    if (id != null) _members.remove(id);
  }
}
