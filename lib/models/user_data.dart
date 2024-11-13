import 'package:cloud_firestore/cloud_firestore.dart';

class UserData {
  final String uid;
  final String sources;
  final String groups;
  final String friends;

  UserData({
    required this.uid,
    required this.sources,
    required this.groups,
    required this.friends,
  });

  factory UserData.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data();
    return UserData(
        uid: data?['uid'] ?? '001',
        sources: data?['sources'] ?? 'Cara, Cola',
        groups: data?['groups'] ?? 'Caracola',
        friends: data?['friends'] ?? 'a lot of them');
  }

  Map<String, dynamic> toFirestore() {
    return {
      'sources': sources,
      'groups': groups,
      'friends': friends,
    };
  }
}
