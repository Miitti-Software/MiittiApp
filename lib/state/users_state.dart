import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:miitti_app/models/miitti_user.dart';
import 'package:miitti_app/state/service_providers.dart';

class UsersState extends StateNotifier<UsersStateData> {
  UsersState(this.ref) : super(UsersStateData()) {
    loadMoreUsers();
  }

  final Ref ref;
  Timer? _debounce;
  bool _isLoadingMore = false;

  Future<MiittiUser?> fetchUser(String userId) async {
    final firestoreService = ref.read(firestoreServiceProvider);
    MiittiUser? user = await firestoreService.loadUserData(userId);
    if (user == null) {
      debugPrint('User with ID $userId does not exist.');
      return null;
    }
    state = state.copyWith(users: state.users.followedBy([user]).toList());
    return user;
  }

  Future<void> loadMoreUsers({bool fullRefresh = false}) async {
    if (_isLoadingMore) return;
    _isLoadingMore = true;

    if (fullRefresh) {
      state = state.copyWith(users: []);
    }

    final firestoreService = ref.read(firestoreServiceProvider);
    List<MiittiUser> newUsers = await firestoreService.fetchFilteredUsers(pageSize: 10, fullRefresh: fullRefresh);

    final currentUserIds = state.users.map((user) => user.uid).toSet();
    final filteredUsers = newUsers.where((user) => !currentUserIds.contains(user.uid)).toList();

    if (filteredUsers.isNotEmpty) {
      state = state.copyWith(users: state.users.followedBy(filteredUsers).toList());
    }

    _isLoadingMore = false;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}

final usersStateProvider = StateNotifierProvider<UsersState, UsersStateData>((ref) {
  return UsersState(ref);
});

final usersProvider = Provider<List<MiittiUser>>((ref) {
  return ref.watch(usersStateProvider).users;
});

class UsersStateData {
  final List<MiittiUser> users;

  UsersStateData({
    this.users = const [],
  });

  UsersStateData copyWith({
    List<MiittiUser>? users,
  }) {
    return UsersStateData(
      users: users ?? this.users,
    );
  }
}