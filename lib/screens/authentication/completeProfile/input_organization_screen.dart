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
  String? selectedOrganization;
  List<Tuple2<String, String>> allOrganizations = [];
  List<Tuple2<String, String>> filteredOrganizations = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadOrganizations();
    selectedOrganization = allOrganizations.firstWhere(
        (Organization) => Organization.item1 == ref.read(userDataProvider).organization,
        orElse: () => const Tuple2<String, String>("", ""),
      ).item1;
    if (selectedOrganization == "") {
      selectedOrganization = null;
    }
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
    final userData = ref.watch(userDataProvider);
    final config = ref.watch(remoteConfigServiceProvider);

    return ConfigScreen(
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
                  final isSelected = selectedOrganization == organization.item1;
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
                          title: Text(organization.item2),
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                selectedOrganization = null;
                              } else {
                                selectedOrganization = organization.item1;
                                userData.setOrganization(organization.item1);
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
          ForwardButton(
            buttonText: config.get<String>('forward-button'),
            onPressed: () {
              context.push('/login/complete-profile/qa-cards');
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
    );
  }
}