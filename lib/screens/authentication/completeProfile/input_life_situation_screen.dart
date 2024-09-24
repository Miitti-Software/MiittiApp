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

class InputLifeSituationScreen extends ConsumerStatefulWidget {
  const InputLifeSituationScreen({super.key});

  @override
  _InputLifeSituationScreenState createState() => _InputLifeSituationScreenState();
}

class _InputLifeSituationScreenState extends ConsumerState<InputLifeSituationScreen> {
  List<String> selectedOccupationalStatuses = [];
  List<Tuple2<String, String>> statusOptions = [];

  @override
  void initState() {
    super.initState();
    _loadStatusOptions();
    final userStatuses = ref.read(userStateProvider).data.occupationalStatuses;
    selectedOccupationalStatuses = statusOptions
        .where((status) => userStatuses.contains(status.item1))
        .map((status) => status.item1)
        .toList();
  }

  Future<void> _loadStatusOptions() async {
    setState(() {
      statusOptions = ref.read(remoteConfigServiceProvider).getTuplesList<String>('occupational_statuses');
    });
  }

  @override
  Widget build(BuildContext context) {
    final userData = ref.watch(userStateProvider).data;
    final userState = ref.read(userStateProvider.notifier);
    final config = ref.watch(remoteConfigServiceProvider);
    ref.read(analyticsServiceProvider).logScreenView('input_life_situation_screen');

    return ConfigScreen(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSizes.minVerticalEdgePadding),
          Text(config.get<String>('input-occupational-status-title'),
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSizes.minVerticalDisclaimerPadding),
          Text(config.get<String>('input-occupational-status-disclaimer'),
              style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: AppSizes.verticalSeparationPadding),

          Expanded(
            child: PermanentScrollbar(
              child: ListView.builder(
                itemCount: statusOptions.length,
                itemBuilder: (context, index) {
                  final occupationalStatus = statusOptions[index];
                  final isSelected = selectedOccupationalStatuses.contains(occupationalStatus.item1);
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
                      title: Text(occupationalStatus.item2),
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            selectedOccupationalStatuses.remove(occupationalStatus.item1);
                            userState.update((state) => state.copyWith(
                              data: userData.removeOccupationalStatus(occupationalStatus.item1)
                            ));
                          } else if (selectedOccupationalStatuses.length < 3) {
                            selectedOccupationalStatuses.add(occupationalStatus.item1);
                            userState.update((state) => state.copyWith(
                              data: userData.addOccupationalStatus(occupationalStatus.item1)
                            ));
                          } else {
                            ErrorSnackbar.show(
                                context, config.get<String>('invalid-occupational-status-too-many'));
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
              if (selectedOccupationalStatuses.isNotEmpty) {
                if (selectedOccupationalStatuses.contains("student")) {
                  context.push('/login/complete-profile/organization');
                } else {
                  context.push('/login/complete-profile/qa-cards');
                }
              } else {
                ErrorSnackbar.show(context, config.get<String>('invalid-occupational-status-missing'));
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