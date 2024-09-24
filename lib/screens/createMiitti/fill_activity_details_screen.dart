import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:miitti_app/constants/languages.dart';
import 'package:miitti_app/constants/miitti_theme.dart';
import 'package:miitti_app/services/analytics_service.dart';
import 'package:miitti_app/state/create_activity_state.dart';
import 'package:miitti_app/state/service_providers.dart';
import 'package:miitti_app/state/settings.dart';
import 'package:miitti_app/widgets/fields/filled_text_area.dart';
import 'package:miitti_app/widgets/fields/filled_textfield.dart';
import 'package:miitti_app/widgets/overlays/error_snackbar.dart';
import 'package:miitti_app/widgets/buttons/forward_button.dart';
import 'package:miitti_app/widgets/buttons/backward_button.dart';

class FillActivityDetailsScreen extends ConsumerStatefulWidget {
  const FillActivityDetailsScreen({super.key});

  @override
  _FillActivityDetailsScreenState createState() => _FillActivityDetailsScreenState();
}

class _FillActivityDetailsScreenState extends ConsumerState<FillActivityDetailsScreen> {
  late TextEditingController titleController;
  late TextEditingController subTitleController;
  bool requiresRequest = true;
  bool isActivityFree = true;
  double activityParticipantsCount = 5;
  bool isActivityTimeUndefined = true;
  DateTime activityTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController();
    subTitleController = TextEditingController();
    titleController.text = ref.read(createActivityStateProvider).title ?? '';
    subTitleController.text = ref.read(createActivityStateProvider).description ?? '';
    requiresRequest = ref.read(createActivityStateProvider).requiresRequest ?? true;
    final paid = ref.read(createActivityStateProvider).paid;
    isActivityFree = paid != null ? !paid : true;
    activityParticipantsCount = ref.read(createActivityStateProvider).maxParticipants?.toDouble() ?? 5;
    isActivityTimeUndefined = ref.read(createActivityStateProvider).startTime == null;
    activityTime = ref.read(createActivityStateProvider).startTime ?? DateTime.now();
  }

  @override
  void dispose() {
    titleController.dispose();
    subTitleController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime(BuildContext context) async {
  final language = ref.watch(languageProvider);
  
  // Show the date picker first
  final DateTime? pickedDate = await showDatePicker(
    context: context,
    locale: Locale(language.code),
    initialDate: activityTime,
    firstDate: DateTime.now(),
    lastDate: DateTime(2101),
    builder: (BuildContext context, Widget? child) {
      return Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(
            primary: Theme.of(context).colorScheme.primary,
            onPrimary: Theme.of(context).colorScheme.onPrimary,
            surface: Theme.of(context).colorScheme.surface,
            onSurface: Theme.of(context).colorScheme.onSurface,
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.primary,
            ),
          ),
          textTheme: const TextTheme().copyWith(
            titleSmall: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w300,
              fontSize: 16,
            ),
          ),
        ),
        child: child!,
      );
    },
  );

  if (pickedDate != null) {
    // Show the time picker after a date has been picked
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(activityTime),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).colorScheme.primary,
              onPrimary: Theme.of(context).colorScheme.onPrimary,
              surface: Theme.of(context).colorScheme.surface,
              onSurface: Theme.of(context).colorScheme.onSurface,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary,
              ),
            ),
            textTheme: const TextTheme().copyWith(
              titleSmall: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w300,
                fontSize: 16,
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedTime != null) {
      // Combine the picked date and time into a single DateTime object
      setState(() {
        activityTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
      });
    }
  }
}

  @override
  Widget build(BuildContext context) {
    final createActivityState = ref.read(createActivityStateProvider.notifier);
    final config = ref.watch(remoteConfigServiceProvider);
    ref.read(analyticsServiceProvider).logScreenView('create_activity_details_screen');
    final DateFormat formatter = DateFormat('dd.MM.yyyy   HH:mm');
    final String formattedTime = formatter.format(activityTime);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Center(
        child: Container(
          color: Theme.of(context).colorScheme.surface,
          padding: const EdgeInsets.all(20.0),
          child: SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          config.get<String>('create-activity-details-title'),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      const SizedBox(height: AppSizes.verticalSeparationPadding),
                      FilledTextField(
                        controller: titleController,
                        hintText: config.get<String>('create-activity-details-title-placeholder'),
                      ),
                      const SizedBox(height: 20),
                      FilledTextArea(
                        controller: subTitleController,
                        hintText: config.get<String>('create-activity-details-description-placeholder'),
                        autofocus: false,
                      ),
                      ListTile(
                        minVerticalPadding: 0,
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                        leading: Switch(
                          activeColor: Theme.of(context).colorScheme.primary,
                          value: requiresRequest,
                          onChanged: (bool value) {
                            setState(() {
                              requiresRequest = value;
                            });
                          },
                        ),
                        title: Text(
                          config.get<String>('create-activity-requires-request-toggle'),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      ListTile(
                        minVerticalPadding: 0,
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                        leading: Switch(
                          activeColor: Theme.of(context).colorScheme.primary,
                          value: isActivityFree,
                          onChanged: (bool value) {
                            setState(() {
                              isActivityFree = value;
                            });
                          },
                        ),
                        title: Text(
                          config.get<String>('create-activity-free-to-attend-toggle'),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      SizedBox(
                        width: double.infinity,
                        child: Slider(
                          activeColor: Theme.of(context).colorScheme.primary,
                          value: activityParticipantsCount,
                          divisions: 18,
                          min: 2,
                          max: 20,
                          label: activityParticipantsCount.round().toString(),
                          onChanged: (newValue) {
                            setState(() {
                              activityParticipantsCount = newValue;
                            });
                          },
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          "${config.get<String>('create-activity-max-participants-before-number')} ${activityParticipantsCount.round()} ${config.get<String>('create-activity-max-participants-after-number')}",
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ),
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                        minVerticalPadding: 0,
                        leading: Switch(
                          activeColor: Theme.of(context).colorScheme.primary,
                          value: isActivityTimeUndefined,
                          onChanged: (bool value) {
                            setState(() {
                              isActivityTimeUndefined = value;
                            });
                            if (!isActivityTimeUndefined) {
                              _pickDateTime(context);
                            }
                          },
                        ),
                        title: Text(
                          isActivityTimeUndefined
                              ? config.get<String>('create-activity-agree-time-later-toggle')
                              : formattedTime,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      const Spacer(),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: AppSizes.minVerticalPadding),
                          LinearProgressIndicator(
                            value: 0.75,
                            backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(height: AppSizes.minVerticalPadding),
                          const SizedBox(height: AppSizes.minVerticalPadding),
                          ForwardButton(
                            buttonText: config.get<String>('forward-button'),
                            onPressed: () {
                              if (titleController.text.isEmpty || subTitleController.text.isEmpty) {
                                ErrorSnackbar.show(context, config.get<String>('invalid-activity-fields-missing'));
                              } else {
                                createActivityState.update((state) => state.copyWith(
                                  title: titleController.text,
                                  description: subTitleController.text,
                                  paid: !isActivityFree,
                                  requiresRequest: requiresRequest,
                                  maxParticipants: activityParticipantsCount.round(),
                                  startTime: isActivityTimeUndefined ? null : activityTime,
                                ));
                                context.go('/create-activity/invite');
                              }
                            },
                          ),
                          const SizedBox(height: AppSizes.minVerticalPadding),
                          BackwardButton(
                            buttonText: config.get<String>('back-button'),
                            onPressed: () => context.go('/create-activity/location'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}