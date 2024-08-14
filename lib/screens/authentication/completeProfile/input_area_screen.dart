import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:miitti_app/constants/miitti_theme.dart';
import 'package:miitti_app/state/service_providers.dart';
import 'package:miitti_app/state/user.dart';
import 'package:miitti_app/widgets/buttons/backward_button.dart';
import 'package:miitti_app/widgets/buttons/forward_button.dart';
import 'package:miitti_app/widgets/config_screen.dart';
import 'package:miitti_app/widgets/custom_scrollbar.dart';
import 'package:miitti_app/widgets/error_snackbar.dart';

class InputAreaScreen extends ConsumerStatefulWidget {
  const InputAreaScreen({super.key});

  @override
  _InputAreaScreenState createState() => _InputAreaScreenState();
}

class _InputAreaScreenState extends ConsumerState<InputAreaScreen> {
  String? selectedArea;
  List<String> allAreas = [];
  List<String> filteredAreas = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    selectedArea = ref.read(userDataProvider).area;
    _loadAreas();
  }

  Future<void> _loadAreas() async {
    final String jsonString = await rootBundle.loadString('lib/constants/areas.json');
    final Map<String, dynamic> jsonMap = json.decode(jsonString);
    setState(() {
      allAreas = jsonMap.values.cast<String>().toList()..sort();
      filteredAreas = allAreas;
    });
  }

  void _filterAreas(String query) {
    setState(() {
      filteredAreas = allAreas
          .where((locality) =>
              locality.toLowerCase().contains(query.toLowerCase()))
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
                  final isSelected = selectedArea == area;
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
                      minVerticalPadding: 5,
                      minTileHeight: 1,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                      title: Text(area),
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            selectedArea = null;
                          } else {
                            selectedArea = area;
                            userData.setUserArea(selectedArea);
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
          ForwardButton(
            buttonText: config.get<String>('forward-button'),
            onPressed: () {
              if (selectedArea != null) {
                context.push('/');
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
    );
  }
}