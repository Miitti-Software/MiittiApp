import 'package:miitti_app/services/analytics_service.dart';
import 'package:miitti_app/widgets/permanent_scrollbar.dart';
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

class InputOrganizationScreen extends ConsumerStatefulWidget {
  const InputOrganizationScreen({super.key});

  @override
  _InputOrganizationScreenState createState() => _InputOrganizationScreenState();
}

class _InputOrganizationScreenState extends ConsumerState<InputOrganizationScreen> {
  List<String> selectedOrganizations = [];
  List<Tuple2<String, String>> allOrganizations = [];
  List<Tuple2<String, String>> filteredOrganizations = [];
  final TextEditingController _searchController = TextEditingController();
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadOrganizations();
    final userOrganizations = ref.read(userStateProvider).data.organizations;
    selectedOrganizations = allOrganizations
        .where((organization) => userOrganizations.contains(organization.item1))
        .map((organization) => organization.item1)
        .toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadOrganizations() async {
    setState(() {
      allOrganizations = ref.read(remoteConfigServiceProvider).getTuplesList<String>('organizations');
      filteredOrganizations = allOrganizations;
    });
  }

  void _filterOrganizations(String query) {
    setState(() {
      filteredOrganizations = allOrganizations
          .where((organization) =>
              organization.item2.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final userData = ref.watch(userStateProvider).data;
    final userState = ref.read(userStateProvider.notifier);
    final config = ref.watch(remoteConfigServiceProvider);
    final isAnonymous = ref.watch(userStateProvider).isAnonymous;
    ref.read(analyticsServiceProvider).logScreenView('input_organization_screen');

    return Stack(
      children: [
        ConfigScreen(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSizes.minVerticalEdgePadding),
              Text(config.get<String>('input-organization-title'),
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppSizes.minVerticalDisclaimerPadding),
              Text(config.get<String>('input-organization-disclaimer'),
                  style: Theme.of(context).textTheme.labelSmall),
              const SizedBox(height: AppSizes.verticalSeparationPadding),
              
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: config.get<String>('input-search-organization'),
                  hintStyle: Theme.of(context).textTheme.labelSmall,
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 0),
                ),
                onChanged: _filterOrganizations,
                onTapOutside: (event) => FocusScope.of(context).unfocus(),
              ),
              
              const SizedBox(height: AppSizes.minVerticalPadding),
              Expanded(
                child: PermanentScrollbar(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: filteredOrganizations.length,
                    itemBuilder: (context, index) {
                      final organization = filteredOrganizations[index];
                      final isSelected = selectedOrganizations.contains(organization.item1);
                      return Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withAlpha(25),
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
                          title: Text(organization.item2),
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                selectedOrganizations.remove(organization.item1);
                                userState.update((state) => state.copyWith(
                                  data: userData.removeOrganization(organization.item1)
                                ));
                              } else {
                                selectedOrganizations.add(organization.item1);
                                userState.update((state) => state.copyWith(
                                  data: userData.addOrganization(organization.item1)
                                ));
                              }
                            });
                          },
                        ),
                      );
                    },
                  ),
                ),
              ),
              
              const SizedBox(height: AppSizes.verticalSeparationPadding),
              if (isAnonymous)
                ForwardButton(
                  buttonText: config.get<String>('forward-button'),
                  onPressed: () {
                    context.push('/login/complete-profile/qa-cards');
                  },
                )
              else
                ForwardButton(
                  buttonText: config.get<String>('save-button'),
                  onPressed: () async {
                    setState(() {
                      isLoading = true;
                    });
                    userState.update((state) => state.copyWith(
                      data: userData.copyWith(organizations: selectedOrganizations)
                    ));
                    await userState.updateUserData();
                    setState(() {
                      isLoading = false;
                    });
                    context.pop();
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