import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:miitti_app/constants/languages.dart';
import 'package:miitti_app/models/miitti_user.dart';
import 'package:miitti_app/state/service_providers.dart';
import 'package:miitti_app/state/user.dart';
import 'package:miitti_app/widgets/config_screen.dart';
import 'package:miitti_app/widgets/overlays/report_bottom_sheet.dart';

class UserProfilePage extends ConsumerStatefulWidget {
  final MiittiUser? userData;

  const UserProfilePage({Key? key, required this.userData}) : super(key: key);

  @override
  _UserProfilePageState createState() => _UserProfilePageState();
}

class _UserProfilePageState extends ConsumerState<UserProfilePage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(userStateProvider);
    final currentUserUid = currentUser.uid;
    final config = ref.watch(remoteConfigServiceProvider);

    return Scaffold(
      body: widget.userData == null
          ? ConfigScreen(child: Center(child: Text('User not found', style: Theme.of(context).textTheme.titleMedium)))
          : Container(
              color: Theme.of(context).colorScheme.surface,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProfilePicture(context, currentUserUid!),
                    _buildFramedList(context, currentUserUid),
                    _buildQACarousel(context),
                    Center(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Theme.of(context).colorScheme.onPrimary,
                          textStyle: Theme.of(context).textTheme.bodyMedium,
                        ),
                        onPressed: () {
                          context.push('/login/complete-profile/qa-cards');
                        },
                        child: Text(config.get<String>('edit-qa-cards-button')),
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
                    _buildFavoriteActivitiesGrid(context),
                    if (widget.userData!.uid != currentUserUid)
                      Center(
                        child: TextButton(
                          onPressed: () {
                            ReportBottomSheet.show(
                              context: context,
                              isActivity: false,
                              id: widget.userData!.uid,
                            );
                          },
                          child: Text(
                            config.get<String>('report-profile-button'),
                            style: TextStyle(color: Theme.of(context).colorScheme.error),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildProfilePicture(BuildContext context, String currentUserUid) {
    final currentUser = ref.watch(userStateProvider);
    final profilePicture = (currentUserUid == widget.userData!.uid) ? currentUser.data.profilePicture : widget.userData!.profilePicture;

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
        if (widget.userData!.uid == currentUserUid) ...[
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
                  onPressed: () {
                    context.push('/login/complete-profile/profile-picture');
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
                '${widget.userData!.name}, ${_calculateAge(widget.userData!.birthday)}',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFramedList(BuildContext context, String currentUserUid) {
    final currentUser = ref.watch(userStateProvider);
    final userData = (currentUserUid == widget.userData!.uid) ? currentUser.data.toMiittiUser() : widget.userData!;

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
          _buildListItem(context, Icons.location_on_outlined, userData.areas.join(', '), currentUserUid, '/login/complete-profile/areas'),
          Divider(color: Theme.of(context).colorScheme.primary.withAlpha(100)),
          _buildListItem(context, Icons.cake_outlined, '${_calculateAge(userData.birthday)}', currentUserUid, null),
          Divider(color: Theme.of(context).colorScheme.primary.withAlpha(100)),
          _buildListItem(context, Icons.language_outlined, userData.languages.map((lang) => ref.watch(remoteConfigServiceProvider).get<String>(lang.code)).join(', '), currentUserUid, '/login/complete-profile/languages'),
          Divider(color: Theme.of(context).colorScheme.primary.withAlpha(100)),
          _buildListItem(context, Icons.work_outline, userData.occupationalStatuses.map((e) => ref.watch(remoteConfigServiceProvider).get<String>(e)).join(', '), currentUserUid, '/login/complete-profile/life-situation'),
          if (userData.organizations.isNotEmpty) ...[
            Divider(color: Theme.of(context).colorScheme.primary.withAlpha(100)),
            _buildListItem(context, Icons.business, userData.organizations.join(', '), currentUserUid, '/login/complete-profile/organization'),
          ],
        ],
      ),
    );
  }

  Widget _buildListItem(BuildContext context, IconData icon, String value, String currentUserUid, String? editRoute) {
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
          if (widget.userData!.uid == currentUserUid && editRoute != null) ...[
            IconButton(
              icon: const Icon(
                Icons.edit,
                size: 20,
                color: Colors.grey,
              ),
              onPressed: () {
                context.push(editRoute);
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQACarousel(BuildContext context) {
    final currentUser = ref.watch(userStateProvider);
    final userData = (currentUser.uid == widget.userData!.uid) ? currentUser.data.toMiittiUser() : widget.userData!;

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

  Widget _buildFavoriteActivitiesGrid(BuildContext context) {
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
        itemCount: widget.userData!.favoriteActivities.length,
        itemBuilder: (context, index) {
          final activity = widget.userData!.favoriteActivities[index];
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
                          color: Colors.white,
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

  int _calculateAge(DateTime? birthday) {
    if (birthday == null) return 0;
    final now = DateTime.now();
    int age = now.year - birthday.year;
    if (now.month < birthday.month || (now.month == birthday.month && now.day < birthday.day)) {
      age--;
    }
    return age;
  }
}