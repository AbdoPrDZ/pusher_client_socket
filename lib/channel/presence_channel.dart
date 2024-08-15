import '../utils/collection.dart';
import '../utils/member.dart';
import 'private_channel.dart';

class PresenceChannel extends PrivateChannel {
  PresenceChannel({required super.client, required super.name}) {
    onMemberAdded(_onMemberAdd);
    onMemberRemoved(_onMemberRemove);
  }

  void onMemberAdded(Function callback) =>
      bind('pusher:member_added', callback);

  void onMemberRemoved(Function callback) =>
      bind('pusher:member_removed', callback);

  @override
  Member? get me =>
      userId != null ? _members.get(userId!) ?? Member(id: userId!) : null;

  final _members = Collection<Member>();

  Member _onMemberAdd(Map data) {
    options.log("MEMBER_ADDED", name, "member: $data");
    final member = Member.fromMap(data);
    _members.add(data["id"], member, override: true);
    return _members.get(data["id"])!;
  }

  void _onMemberRemove(Map data) {
    options.log("MEMBER_REMOVED", name, "member: $data");
    _members.remove(data["id"]);
  }
}
