import 'package:miitti_app/state/user.dart';
import 'package:tuple/tuple.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:miitti_app/constants/miitti_theme.dart';
import 'package:miitti_app/state/service_providers.dart';
import 'package:miitti_app/widgets/buttons/backward_button.dart';
import 'package:miitti_app/widgets/buttons/forward_button.dart';
import 'package:miitti_app/widgets/config_screen.dart';
import 'package:miitti_app/widgets/overlays/error_snackbar.dart';

class AcceptNormsScreen extends ConsumerStatefulWidget {
  const AcceptNormsScreen({super.key});

  @override
  _AcceptNormsScreenState createState() => _AcceptNormsScreenState();
}

class _AcceptNormsScreenState extends ConsumerState<AcceptNormsScreen> {
  List<Tuple2<String, String>> norms = [];
  List<Tuple2<String, String>> acceptedNorms = [];

  @override
  void initState() {
    super.initState();
    norms = ref.read(remoteConfigServiceProvider).getTuplesList<String>('community_norms');
  }

  @override
  Widget build(BuildContext context) {
    final userState = ref.read(userStateProvider.notifier);
    final config = ref.watch(remoteConfigServiceProvider);

    return ConfigScreen(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(flex: 1),
          Text(config.get<String>('accept-norms-title'),
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSizes.minVerticalDisclaimerPadding),
          Text(config.get<String>('accept-norms-disclaimer'),
              style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: AppSizes.verticalSeparationPadding),
          
          SingleChildScrollView(child:
            ListView.builder(
              shrinkWrap: true,
              itemCount: norms.length,
              itemBuilder: (context, index) {
                final term = norms[index];
                final isSelected = acceptedNorms.contains(term);
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
                        title: Text(term.item2),
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              acceptedNorms.remove(term);
                            } else {
                              acceptedNorms.add(term);
                            }
                          });
                        },
                      ),
                    );
                  },
                ),
            ),
          
          const Spacer(flex: 1),
          ForwardButton(
            buttonText: config.get<String>('forward-button'),
            onPressed: () {
              if (Set.from(acceptedNorms).containsAll(norms)) {
                  userState.createUser();
                  context.go('/');
              } else {
                ErrorSnackbar.show(
                    context, config.get<String>('invalid-norms-missing'));
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