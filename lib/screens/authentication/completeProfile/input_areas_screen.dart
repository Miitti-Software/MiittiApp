import 'package:miitti_app/services/analytics_service.dart';
import 'package:tuple/tuple.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:miitti_app/constants/miitti_theme.dart';
import 'package:miitti_app/state/service_providers.dart';
import 'package:miitti_app/state/user.dart';
import 'package:miitti_app/widgets/buttons/backward_button.dart';
import 'package:miitti_app/widgets/buttons/forward_button.dart';
import 'package:miitti_app/widgets/config_screen.dart';
import 'package:miitti_app/widgets/permanent_scrollbar.dart';
import 'package:miitti_app/widgets/overlays/error_snackbar.dart';

class InputAreasScreen extends ConsumerStatefulWidget {
  const InputAreasScreen({super.key});

  @override
  _InputAreasScreenState createState() => _InputAreasScreenState();
}

class _InputAreasScreenState extends ConsumerState<InputAreasScreen> {
  List<String> selectedAreas = [];
  List<Tuple2<String, String>> allAreas = [];
  List<Tuple2<String, String>> filteredAreas = [];
  final TextEditingController _searchController = TextEditingController();
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadAreas();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAreas() async {
    setState(() {
      allAreas = ref.read(remoteConfigServiceProvider).getTuplesList<Map<String, dynamic>>('areas').map((e) => Tuple2(e.item1, e.item2['name'] as String)).toList();
      filteredAreas = allAreas;
      final userAreas = ref.read(userStateProvider).data.areas;
      selectedAreas = allAreas
          .where((area) => userAreas.contains(area.item1))
          .map((area) => area.item1)
          .toList();
    });
  }

  void _filterAreas(String query) {
    setState(() {
      filteredAreas = allAreas
          .where((area) =>
              area.item2.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final userData = ref.watch(userStateProvider).data;
    final userState = ref.read(userStateProvider.notifier);
    final config = ref.watch(remoteConfigServiceProvider);
    final isAnonymous = ref.watch(userStateProvider).isAnonymous;
    ref.read(analyticsServiceProvider).logScreenView('input_areas_screen');

    return Stack(
      children: [
        ConfigScreen(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSizes.minVerticalEdgePadding),
              Text(config.get<String>('input-area-title'),
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppSizes.minVerticalDisclaimerPadding),
              Text(config.get<String>('input-area-disclaimer'),
                  style: Theme.of(context).textTheme.labelSmall),
              const SizedBox(height: AppSizes.verticalSeparationPadding),

              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: config.get<String>('input-search-area'),
                  hintStyle: Theme.of(context).textTheme.labelSmall,
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 0),
                ),
                onChanged: _filterAreas,
                onTapOutside: (event) => FocusScope.of(context).unfocus(),
              ),
              
              const SizedBox(height: AppSizes.minVerticalPadding),
              Expanded(
                child: PermanentScrollbar(
                  child: ListView.builder(
                    itemCount: filteredAreas.length,
                    itemBuilder: (context, index) {
                      final area = filteredAreas[index];
                      final isSelected = selectedAreas.contains(area.item1);
                      return Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          border: isSelected
                              ? Border.all(color: Theme.of(context).colorScheme.primary, width: 1)
                              : Border.all(color: Colors.transparent, width: 1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 0),
                        margin: const EdgeInsets.only(bottom: 8, right: 10),
                        child: ListTile(
                          titleTextStyle: Theme.of(context).textTheme.bodyMedium,
                          minVerticalPadding: 6,
                          minTileHeight: 1,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                          title: Text(area.item2),
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                selectedAreas.remove(area.item1);
                              } else if (selectedAreas.length < 3) {
                                selectedAreas.add(area.item1);
                              } else {
                                ErrorSnackbar.show(
                                    context, config.get<String>('invalid-area-too-many'));
                              }
                            });
                          },
                        ),
                      );
                    },
                  ),
                ),
              ),
              
              const SizedBox(height: AppSizes.minVerticalEdgePadding),
              if (isAnonymous)
                ForwardButton(
                  buttonText: config.get<String>('forward-button'),
                  onPressed: () {
                    if (selectedAreas.isNotEmpty) {
                      userState.update((state) => state.copyWith(
                        data: userData.copyWith(areas: selectedAreas)
                      ));
                      context.push('/login/complete-profile/life-situation');
                    } else {
                      ErrorSnackbar.show(
                          context, config.get<String>('invalid-area-missing'));
                    }
                  },
                )
              else
                ForwardButton(
                  buttonText: config.get<String>('save-button'),
                  onPressed: () async {
                    if (selectedAreas.isNotEmpty) {
                      setState(() {
                        isLoading = true;
                      });
                      userState.update((state) => state.copyWith(
                        data: userData.copyWith(areas: selectedAreas)
                      ));
                      await userState.updateUserData();
                      setState(() {
                        isLoading = false;
                      });
                      context.pop();
                    } else {
                      ErrorSnackbar.show(
                          context, config.get<String>('invalid-area-missing'));
                    }
                  },
                ),
              const SizedBox(height: AppSizes.minVerticalPadding),
              BackwardButton(
                buttonText: config.get<String>('back-button'),
                onPressed: () => context.pop(),
              ),
              const SizedBox(height: AppSizes.minVerticalEdgePadding),
            ],
          ),
        ),
        if (isLoading)
          Container(
            color: Colors.black.withOpacity(0.5),
            child: Center(
              child: CircularProgressIndicator(),
            ),
          ),
      ],
    );
  }
}