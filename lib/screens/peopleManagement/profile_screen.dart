import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:miitti_app/constants/languages.dart';
import 'package:miitti_app/models/miitti_user.dart';
import 'package:miitti_app/state/service_providers.dart';
import 'package:miitti_app/state/user.dart';
import 'package:miitti_app/state/users_state.dart';
import 'package:miitti_app/widgets/config_screen.dart';
import 'package:miitti_app/widgets/overlays/report_bottom_sheet.dart';

class UserProfilePage extends ConsumerStatefulWidget {
  final String? userId;

  const UserProfilePage({Key? key, this.userId}) : super(key: key);

  @override
  _UserProfilePageState createState() => _UserProfilePageState();
}

class _UserProfilePageState extends ConsumerState<UserProfilePage> {
  late Future<MiittiUser?> userFuture;
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final userId = widget.userId ?? ref.read(userStateProvider).uid;
    userFuture = fetchUserDetails(userId!);
  }

  Future<MiittiUser?> fetchUserDetails(String userId) async {
    return await ref.read(usersStateProvider.notifier).fetchUser(userId);
  }

  @override
  Widget build(BuildContext context) {
    final currentUserUid = ref.watch(userStateProvider).uid;

    return FutureBuilder<MiittiUser?>(
      future: userFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return ConfigScreen(
            child: Center(
              child: Text('Error loading user profile', style: Theme.of(context).textTheme.titleMedium),
            ),
          );
        } else if (!snapshot.hasData || snapshot.data == null) {
          return ConfigScreen(
            child: Center(
              child: Text('User not found', style: Theme.of(context).textTheme.titleMedium),
            ),
          );
        }

        final userData = snapshot.data!;
        return Scaffold(
          body: Container(
            color: Theme.of(context).colorScheme.surface,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProfilePicture(context, currentUserUid!, userData),
                  _buildFramedList(context, currentUserUid, userData),
                  _buildQACarousel(context, userData),
                  if (userData.uid == currentUserUid)
                    Center(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Theme.of(context).colorScheme.onPrimary,
                          textStyle: Theme.of(context).textTheme.bodyMedium,
                        ),
                        onPressed: () async {
                          await context.push('/login/complete-profile/qa-cards');
                          setState(() {userFuture = fetchUserDetails(userData.uid);});
                        },
                        child: Text(ref.watch(remoteConfigServiceProvider).get<String>('edit-qa-cards-button')),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.only(left: 16.0, top: 32.0, bottom: 0),
                    child: Text(
                      ref.watch(remoteConfigServiceProvider).get('favorite-activities-title'),
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.left,
                    ),
                  ),
                  _buildFavoriteActivitiesGrid(context, userData),
                  if (userData.uid == currentUserUid)
                    Center(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Theme.of(context).colorScheme.onPrimary,
                          textStyle: Theme.of(context).textTheme.bodyMedium,
                        ),
                        onPressed: () async {
                          await context.push('/login/complete-profile/activities');
                          setState(() {userFuture = fetchUserDetails(userData.uid);});
                        },
                        child: Text(ref.watch(remoteConfigServiceProvider).get<String>('edit-activities-button')),
                      ),
                    ),
                  if (userData.uid != currentUserUid)
                    Center(
                      child: TextButton(
                        onPressed: () {
                          ReportBottomSheet.show(
                            context: context,
                            isActivity: false,
                            id: userData.uid,
                          );
                        },
                        child: Text(
                          ref.watch(remoteConfigServiceProvider).get<String>('report-profile-button'),
                          style: TextStyle(color: Theme.of(context).colorScheme.error),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfilePicture(BuildContext context, String currentUserUid, MiittiUser userData) {
    final currentUser = ref.watch(userStateProvider);
    final profilePicture = (currentUserUid == userData.uid) ? currentUser.data.profilePicture : userData.profilePicture;

    return Stack(
      children: [
        ShaderMask(
          shaderCallback: (rect) {
            return LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Theme.of(context).colorScheme.surface,
                Colors.transparent,
              ],
              stops: const [0.4, 0.95],
            ).createShader(Rect.fromLTRB(0, 0, rect.width, rect.height));
          },
          blendMode: BlendMode.dstIn,
          child: CachedNetworkImage(
            imageUrl: profilePicture!,
            width: double.infinity,
            height: 420,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: 40,
          left: 16,
          child: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new, 
              color: Colors.white,
              shadows: <Shadow>[Shadow(color: Colors.black45, blurRadius: 20.0, offset: Offset(0, 2.0))],
            ),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/');
              }
            },
          ),
        ),
        if (userData.uid == currentUserUid) ...[
          Positioned(
            top: 40,
            right: 16,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.edit, 
                    size: 30,
                    color: Colors.white,
                    shadows: <Shadow>[Shadow(color: Colors.black45, blurRadius: 20.0, offset: Offset(0, 2.0))],
                  ),
                  onPressed: () async {
                    await context.push('/login/complete-profile/profile-picture');
                    setState(() {userFuture = fetchUserDetails(userData.uid);});
                  },
                ),
                IconButton(
                  icon: const Icon(
                    Icons.settings, 
                    size: 30,
                    color: Colors.white,
                    shadows: <Shadow>[Shadow(color: Colors.black45, blurRadius: 20.0, offset: Offset(0, 2.0))],
                  ),
                  onPressed: () {
                    context.go('/profile/settings');
                  },
                ),
              ],
            ),
          ),
        ],
        Positioned(
          bottom: 20,
          left: 0,
          right: 0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${userData.name}, ${_calculateAge(userData.birthday)}',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFramedList(BuildContext context, String currentUserUid, MiittiUser userData) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.primary.withAlpha(125)),
        borderRadius: BorderRadius.circular(10),
        color: Theme.of(context).colorScheme.primary.withAlpha(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildListItem(context, Icons.location_on_outlined, userData.areas.join(', '), currentUserUid, '/login/complete-profile/areas', userData),
          Divider(color: Theme.of(context).colorScheme.primary.withAlpha(100)),
          _buildListItem(context, Icons.cake_outlined, '${_calculateAge(userData.birthday)}', currentUserUid, null, userData),
          Divider(color: Theme.of(context).colorScheme.primary.withAlpha(100)),
          _buildListItem(context, Icons.language_outlined, userData.languages.map((lang) => ref.watch(remoteConfigServiceProvider).get<String>(lang.code)).join(', '), currentUserUid, '/login/complete-profile/languages', userData),
          Divider(color: Theme.of(context).colorScheme.primary.withAlpha(100)),
          _buildListItem(context, Icons.work_outline, userData.occupationalStatuses.map((e) => ref.watch(remoteConfigServiceProvider).get<String>(e)).join(', '), currentUserUid, '/login/complete-profile/life-situation', userData),
          if (userData.organizations.isNotEmpty) ...[
            Divider(color: Theme.of(context).colorScheme.primary.withAlpha(100)),
            _buildListItem(context, Icons.business, userData.organizations.join(', '), currentUserUid, '/login/complete-profile/organization', userData),
          ],
        ],
      ),
    );
  }

  Widget _buildListItem(BuildContext context, IconData icon, String value, String currentUserUid, String? editRoute, MiittiUser userData) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon, 
            color: Theme.of(context).colorScheme.primary,
            size: 30,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Wrap(
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          if (userData.uid == currentUserUid && editRoute != null) ...[
            IconButton(
              icon: const Icon(
                Icons.edit,
                size: 20,
                color: Colors.grey,
              ),
              onPressed: () async {
                await context.push(editRoute);
                setState(() {userFuture = fetchUserDetails(userData.uid);});
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQACarousel(BuildContext context, MiittiUser userData) {
    return Column(
      children: [
        SizedBox(
          height: 180,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemCount: userData.qaAnswers.length,
            itemBuilder: (context, index) {
              final entry = userData.qaAnswers.entries.elementAt(index);
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withAlpha(15),
                  border: Border.all(color: Theme.of(context).colorScheme.primary.withAlpha(125)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.key,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Text(
                            entry.value,
                            style: const TextStyle(fontSize: 14.0),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Wrap(
          alignment: WrapAlignment.center,
          children: List.generate(userData.qaAnswers.length, (index) {
            return Container(
              width: 8.0,
              height: 8.0,
              margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 5.0),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).colorScheme.primary.withAlpha(index == _currentPage ? 255 : 125),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildFavoriteActivitiesGrid(BuildContext context, MiittiUser userData) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const BouncingScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 20.0,
          mainAxisSpacing: 10.0,
        ),
        itemCount: userData.favoriteActivities.length,
        itemBuilder: (context, index) {
          final activity = userData.favoriteActivities[index];
          return Container(
            padding: const EdgeInsets.symmetric(
              vertical: 10,
              horizontal: 5,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16.0),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Text(
                    ref.watch(remoteConfigServiceProvider).getActivityTuple(activity).item2,
                    style: const TextStyle(fontSize: 32),
                  ),
                  Wrap(
                    children: [
                      Text(
                        textAlign: TextAlign.center,
                        ref.watch(remoteConfigServiceProvider).getActivityTuple(activity).item1,
                        overflow: TextOverflow.visible,
                        style: Theme.of(context).textTheme.labelMedium!.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  int _calculateAge(DateTime birthday) {
    final now = DateTime.now();
    int age = now.year - birthday.year;
    if (now.month < birthday.month || (now.month == birthday.month && now.day < birthday.day)) {
      age--;
    }
    return age;
  }
}