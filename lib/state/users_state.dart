import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:miitti_app/models/miitti_user.dart';
import 'package:miitti_app/state/service_providers.dart';
import 'package:geocoding/geocoding.dart';
import 'package:miitti_app/state/user.dart';
import 'package:miitti_app/state/users_filter_settings.dart'; // Add this import for placemarkFromCoordinates

class UsersState extends StateNotifier<UsersStateData> {
  UsersState(this.ref) : super(UsersStateData()) {
    loadMoreUsers();
  }

  final Ref ref;
  bool _isLoadingMore = false;

  Future<MiittiUser?> fetchUser(String userId) async {
    if (userId == ref.read(userStateProvider).uid) {
      print('Fetching current user from user state.');
      return ref.read(userStateProvider).data.toMiittiUser();
    }
    if (state.users.any((element) => element.uid == userId)) { 
      return state.users.firstWhere((element) => element.uid == userId);
    }
    final firestoreService = ref.read(firestoreServiceProvider);
    MiittiUser? user = await firestoreService.fetchUser(userId);
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
    final filterSettings = ref.read(usersFilterSettingsProvider);
    await ref.read(usersFilterSettingsProvider.notifier).loadPreferences();

    List<MiittiUser> newUsers = await firestoreService.fetchFilteredUsers(
      pageSize: 10,
      fullRefresh: fullRefresh,
    );

    String? area;
    if (filterSettings.sameArea) {
      final userState = ref.read(userStateProvider);
      area = userState.data.areas[0];
      if (userState.data.latestLocation != null) {
        final placemarks = await placemarkFromCoordinates(
          userState.data.latestLocation!.latitude,
          userState.data.latestLocation!.longitude,
        );
        if (placemarks.isNotEmpty) {
          final city = placemarks.first.locality;
          if (city != null) {
            area = city;
          }
        }
      }
      newUsers = newUsers.where((user) => user.areas.contains(area)).toList();
    }

    final currentUserIds = state.users.map((user) => user.uid).toSet();
    final filteredUsers = newUsers.where((user) => !currentUserIds.contains(user.uid)).toList();

    if (filteredUsers.isNotEmpty) {
      state = state.copyWith(users: state.users.followedBy(filteredUsers).toList());
    }

    _isLoadingMore = false;
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