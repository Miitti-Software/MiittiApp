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
import 'package:miitti_app/widgets/error_snackbar.dart';

class InputLifeSituationScreen extends ConsumerStatefulWidget {
  const InputLifeSituationScreen({super.key});

  @override
  _InputLifeSituationScreenState createState() => _InputLifeSituationScreenState();
}

class _InputLifeSituationScreenState extends ConsumerState<InputLifeSituationScreen> {
  String? selectedOccupationalStatus;
  List<Tuple2<String, String>> statusOptions = [];

  @override
  void initState() {
    super.initState();
    statusOptions = ref.read(remoteConfigServiceProvider).getTuplesList<String>('occupational_statuses');
    selectedOccupationalStatus = statusOptions.firstWhere(
        (occupationalStatus) => occupationalStatus.item1 == ref.read(userDataProvider).occupationalStatus,
        orElse: () => const Tuple2<String, String>("", ""),
      ).item1;
    if (selectedOccupationalStatus == "") {
      selectedOccupationalStatus = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final userData = ref.watch(userDataProvider);
    final config = ref.watch(remoteConfigServiceProvider);

    return ConfigScreen(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(flex: 1),
          Text(config.get<String>('input-occupational-status-title'),
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSizes.minVerticalDisclaimerPadding),
          Text(config.get<String>('input-occupational-status-disclaimer'),
              style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: AppSizes.verticalSeparationPadding),
          
          ListView.builder(
            shrinkWrap: true,
            itemCount: statusOptions.length,
            itemBuilder: (context, index) {
              final occupationalStatus = statusOptions[index];
              final isSelected = selectedOccupationalStatus == occupationalStatus.item1;
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
                            selectedOccupationalStatus = null;
                          } else {
                            selectedOccupationalStatus = occupationalStatus.item1;
                            userData.setOccupationalStatus(occupationalStatus.item1);
                          }
                        });
                      },
                    ),
                  );
                },
              ),
          
          const Spacer(flex: 1),
          ForwardButton(
            buttonText: config.get<String>('forward-button'),
            onPressed: () {
              if (selectedOccupationalStatus != null) {
                if (selectedOccupationalStatus == "student") {
                  context.push('/login/complete-profile/organization');
                } else {
                  context.push('/'); // TODO: direct to the next screen
                }
              } else {
                ErrorSnackbar.show(
                    context, config.get<String>('invalid-occupational-status-missing'));
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