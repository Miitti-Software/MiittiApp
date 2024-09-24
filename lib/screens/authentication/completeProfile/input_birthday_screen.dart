import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:miitti_app/constants/languages.dart';
import 'package:miitti_app/constants/miitti_theme.dart';
import 'package:miitti_app/services/analytics_service.dart';
import 'package:miitti_app/state/service_providers.dart';
import 'package:miitti_app/state/settings.dart';
import 'package:miitti_app/state/user.dart';
import 'package:miitti_app/widgets/buttons/backward_button.dart';
import 'package:miitti_app/widgets/buttons/forward_button.dart';
import 'package:miitti_app/widgets/config_screen.dart';
import 'package:miitti_app/widgets/overlays/error_snackbar.dart';
import 'package:pinput/pinput.dart';

class InputBirthdayScreen extends ConsumerStatefulWidget {
  const InputBirthdayScreen({super.key});

  @override
  _InputBirthdayScreenState createState() => _InputBirthdayScreenState();
}

class _InputBirthdayScreenState extends ConsumerState<InputBirthdayScreen> {
  bool placeholderVisible = true;
  final placeholder = 'DDMMYYYY';
  late TextEditingController controller;
  DateTime? birthday;

  @override
  void initState() {
    super.initState();
    placeholderVisible = ref.read(userStateProvider).data.birthday == null;
    birthday = ref.read(userStateProvider).data.birthday;
    controller = TextEditingController(text: ref.read(userStateProvider).data.birthday != null ? DateFormat('ddMMyyyy').format(ref.read(userStateProvider).data.birthday!) : placeholder);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(remoteConfigServiceProvider);
    final userData = ref.watch(userStateProvider).data;
    final userState = ref.read(userStateProvider.notifier);
    final language = ref.watch(languageProvider);
    ref.read(analyticsServiceProvider).logScreenView('input_birthday_screen');

    return ConfigScreen(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(),
          Text(config.get<String>('input-birthday-title'),
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSizes.verticalSeparationPadding),
          Row(
            children: [
              Expanded(
                child: Pinput(
                  mainAxisAlignment: MainAxisAlignment.start,
                  length: 8,
                  controller: controller,
                  autofocus: false,
                  separatorBuilder: (index) {
                    if (index == 1 || index == 3) {
                      return const SizedBox(width: 18);
                    }
                    return const SizedBox(width: 8);
                  },
                  defaultPinTheme: PinTheme(
                    height: 40,
                    width: 30,
                    textStyle: placeholderVisible
                        ? Theme.of(context).textTheme.bodyMedium!.copyWith(
                            fontWeight: FontWeight.w800,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withAlpha(100))
                        : Theme.of(context).textTheme.bodyMedium!.copyWith(
                            fontWeight: FontWeight.w800,
                            color: Theme.of(context).colorScheme.onSurface),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .tertiary
                          .withAlpha(40),
                      border: const Border(
                        bottom: BorderSide(width: 1.0, color: Colors.white),
                      ),
                    ),
                  ),
                  onTapOutside: (PointerDownEvent event) {
                    FocusScope.of(context).unfocus();
                    if (controller.text == '') {
                      controller.text = placeholder;
                      placeholderVisible = true;
                    } else if (controller.text.length < 8) {
                      ErrorSnackbar.show(
                        context,
                        config.get<String>('invalid-birthday-input'),
                      );
                    }
                  },
                  onTap: () {
                    if (controller.text == placeholder) {
                      controller.clear();
                      setState(() {
                        placeholderVisible = false;
                      });
                    }
                  },
                  onChanged: (String value) {
                    if (value.isEmpty) {
                      controller.selection =
                          const TextSelection.collapsed(offset: 0);
                    }
                  },
                  onCompleted: (String value) {
                    if (value.length == 8 && value != placeholder) {
                      if (_validateBirthdayDate(value)) {
                        setState(() {
                          birthday = DateTime(
                            int.parse(value.substring(4, 8)),
                            int.parse(value.substring(2, 4)),
                            int.parse(value.substring(0, 2)),
                          );
                        });
                        userState.update((state) => state.copyWith(
                          data: userData.setBirthday(birthday!)
                        ));
                      }
                    }
                  },
                ),
              ),

              /// Calendar button to open date picker
              GestureDetector(
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    locale: Locale(language.code),
                    initialDate: DateTime.now(),
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now(),
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
                              foregroundColor:
                                  Theme.of(context).colorScheme.primary,
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
                  if (picked != null) {
                    controller.text = DateFormat('ddMMyyyy').format(picked);
                    setState(() {
                      placeholderVisible = false;
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.only(right: 0, left: 20),
                  child: Icon(
                    Icons.calendar_today,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.minVerticalDisclaimerPadding),
          Text(config.get<String>('input-birthday-disclaimer'),
              style: Theme.of(context).textTheme.labelSmall),
          const Spacer(),
          ForwardButton(
            buttonText: config.get<String>('forward-button'),
            onPressed: () {
              if (birthday == null) {
                ErrorSnackbar.show(
                  context,
                  config.get<String>('invalid-birthday-missing'),
                );
              } else if (_validateBirthdayDate(controller.text)) {
                userState.update((state) => state.copyWith(
                  data: userData.setBirthday(birthday!)
                ));
                context.push('/login/complete-profile/gender');
              }
            },
          ),
          const SizedBox(height: AppSizes.minVerticalPadding),
          BackwardButton(
            buttonText: config.get<String>('back-button'),
            onPressed: () {
              context.pop();
            },
          ),
          const SizedBox(height: AppSizes.minVerticalEdgePadding),
        ],
      ),
    );
  }

  bool _validateBirthdayDate(
    String birthday,
  ) {
    try {
      DateTime today = DateTime.now();
      DateTime minimumAge = DateTime(today.year - 18, today.month, today.day);
      DateTime maximumAge = DateTime(today.year - 118, today.month, today.day);
      
      String year = birthday.substring(4, 8);
      String month = birthday.substring(2, 4);
      String day = birthday.substring(0, 2);

      DateFormat dateFormat = DateFormat('dd/MM/yyyy');
      DateTime birthDate = dateFormat.parseStrict('$day/$month/$year');
      
      // Check that the user age is in the correct range
      if (birthDate.isAfter(minimumAge)) {
        ErrorSnackbar.show(
          context,
          ref.watch(remoteConfigServiceProvider).get<String>('invalid-birthday-too-young'),
        );
        return false;  // The minimum age is a hard limit
      }
      
      if (birthDate.isBefore(maximumAge)) {
        ErrorSnackbar.show(
          context,
          ref.watch(remoteConfigServiceProvider).get<String>('invalid-birthday-too-old'),
        );
        return true;  // The maximum age is more of a sanity check and therefore a soft limit
      }
      
      return true;

    } catch (e) {

      // Handle invalid date format or out-of-range values
      ErrorSnackbar.show(
        context,
        ref.watch(remoteConfigServiceProvider).get<String>('invalid-birthday-input'),
      );

      return false;
    }
  }
}

