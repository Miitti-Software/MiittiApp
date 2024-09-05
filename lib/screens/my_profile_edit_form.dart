import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:miitti_app/constants/constants.dart';
import 'package:miitti_app/constants/app_style.dart';
import 'package:miitti_app/constants/languages.dart';
import 'package:miitti_app/models/miitti_user.dart';
import 'package:miitti_app/models/activity.dart';

import 'package:miitti_app/state/service_providers.dart';
import 'package:miitti_app/state/user.dart';
import 'package:miitti_app/widgets/question_answer.dart';
import 'package:miitti_app/functions/utils.dart';


import 'index_page.dart';
import '../widgets/buttons/my_elevated_button.dart';

//TODO: New UI

class MyProfileEditForm extends ConsumerStatefulWidget {
  const MyProfileEditForm({required this.user, super.key});

  final MiittiUser user;

  @override
  ConsumerState<MyProfileEditForm> createState() => _MyProfileEditFormState();
}

class _MyProfileEditFormState extends ConsumerState<MyProfileEditForm> {
  Color miittiColor = const Color.fromRGBO(255, 136, 27, 1);

  final _formKey = GlobalKey<FormState>();

  TextEditingController userAreaController = TextEditingController();
  final userAreaFocusNode = FocusNode();

  TextEditingController userSchoolController = TextEditingController();
  final userSchoolFocusNode = FocusNode();

  File? image;

  Set<Language> selectedLanguages = {};

  Map<String, String> userChoices = {};

  List<String> filteredActivities = [];
  List<String> favoriteActivities = [];

  @override
  void initState() {
    super.initState();
    filteredActivities = activities.keys.toList();
    favoriteActivities =
        updateActiviesId(widget.user.favoriteActivities.toSet());

    selectedLanguages = widget.user.languages.map((lang) => Language.values.firstWhere((e) => e.name == lang)).toSet();
    userAreaController.text = widget.user.areas.join(', ');  // Assuming areas is a list
    userSchoolController.text = widget.user.organization ?? '';
    userChoices = widget.user.qaAnswers;
  }

  List<String> updateActiviesId(Set<String> favActivities) {
    List<String> updatedActivities = [];
    for (var favActivity in favActivities) {
      if (activities.containsKey(favActivity)) {
        updatedActivities.add(favActivity);
      } else {
        //If is found in activities values, set key of the value to favActivity value
        for (var entry in activities.entries) {
          if (entry.value.name == favActivity) {
            updatedActivities.add(entry.key);
            break;
          }
        }
      }
    }

    return updatedActivities;
  }

  @override
  void dispose() {
    userAreaController.dispose();
    userSchoolController.dispose();
    userAreaFocusNode.dispose();
    userSchoolFocusNode.dispose();
    super.dispose();
  }

  void selectImage() async {
    image = await pickImage(context);
    setState(() {});
  }

  void _toggleFavoriteActivity(String activity) {
    setState(() {
      if (favoriteActivities.contains(activity)) {
        favoriteActivities.remove(activity);
      } else {
        if (favoriteActivities.length < 9) {
          favoriteActivities.add(activity);
        }
      }
    });
  }

  void capitalizeInput() {
    final originalText = userAreaController.text;
    if (originalText.isNotEmpty) {
      final capitalizedText =
          originalText[0].toUpperCase() + originalText.substring(1);
      if (capitalizedText != originalText) {
        userAreaController.value = userAreaController.value.copyWith(
          text: capitalizedText,
          selection: TextSelection.collapsed(offset: capitalizedText.length),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    List<String> answeredQuestions = questionOrder
        .where((question) => userChoices.containsKey(question))
        .toList();

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: AppBar(
          backgroundColor: AppStyle.black,
          automaticallyImplyLeading: false,
          title: Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Muokkaa profiilia',
                    style: TextStyle(
                      fontSize: 27,
                      fontFamily: 'Sora',
                      color: Colors.white,
                    ),
                  ),
                  const Expanded(child: SizedBox()),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: const Icon(
                      Icons.settings,
                      size: 30,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              InkWell(
                onTap: () {
                  selectImage();
                },
                child: Card(
                  elevation: 4,
                  color: miittiColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius:
                            const BorderRadius.all(Radius.circular(20)),
                        child: image == null
                            ? Image.network(
                                ref.read(userStateProvider.notifier).data.profilePicture!,
                                height: 400,
                                width: 400,
                                fit: BoxFit.cover,
                              )
                            : Image.file(
                                image!,
                                height: 400,
                                width: 400,
                                fit: BoxFit.cover,
                              ),
                      ),
                    ],
                  ),
                ),
              ),
              getSections(
                title: 'Missä asustelet',
                subtitle:
                    'Emme tunge kylään, mutta näin osaamme ehdottaa sopiva miittejä alueellasi',
                mainWidget: getOurTextField(
                  myPadding: const EdgeInsets.only(right: 10),
                  myController: userAreaController,
                  myFocusNode: userAreaFocusNode,
                  myOnChanged: (_) => capitalizeInput(),
                  myOnTap: () {
                    if (userAreaFocusNode.hasFocus) {
                      userAreaFocusNode.unfocus();
                    }
                  },
                  myKeyboardType: TextInputType.streetAddress,
                ),
              ),
              getSections(
                title: 'Missä opiskelet',
                subtitle: 'Yliopisto vai kahvilan nurkka?',
                mainWidget: getOurTextField(
                  myPadding: const EdgeInsets.only(right: 10),
                  myController: userSchoolController,
                  myFocusNode: userSchoolFocusNode,
                  myOnChanged: (_) => capitalizeInput(),
                  myOnTap: () {
                    if (userSchoolFocusNode.hasFocus) {
                      userSchoolFocusNode.unfocus();
                    }
                  },
                  myKeyboardType: TextInputType.streetAddress,
                ),
              ),
              getSections(
                title: 'Mitä kieliä puhut',
                subtitle: 'Valitse ne kielet, joita puhut',
                mainWidget: Row(
                  children: [
                    _buildLanguageButton(
                      Language.en,
                    ),
                    _buildLanguageButton(
                      Language.fi,
                    ),
                    _buildLanguageButton(
                      Language.sv,
                    ),
                  ],
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              createSection(
                textTitle: 'Lisää lempiaktiviteettisi',
                textSubtitle:
                    'Valitse vähintään 3 lempiaktiviteettisi, mitä haluaisit tehdä muiden kanssa',
                secondWidget: SizedBox(
                  height: 400,
                  child: GridView.builder(
                    itemCount: filteredActivities.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 4.0,
                      mainAxisSpacing: 4.0,
                    ),
                    itemBuilder: (context, index) {
                      final activity = filteredActivities[index];
                      final isSelected = favoriteActivities.contains(activity);
                      return GestureDetector(
                        onTap: () => _toggleFavoriteActivity(activity),
                        child: Container(
                          height: 100,
                          width: 50,
                          decoration: BoxDecoration(
                              color: isSelected
                                  ? AppStyle.violet
                                  : Colors.transparent,
                              borderRadius: const BorderRadius.all(
                                  Radius.circular(10.0))),
                          child: Column(
                            children: [
                              Text(
                                Activity.getActivity(activity).emojiData,
                                style: const TextStyle(fontSize: 50.0),
                              ),
                              Text(
                                Activity.getActivity(activity).name,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: 'Rubik',
                                  fontSize: 19.0,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              createDifferentSection(
                textTitle: 'Esittele itsesi',
                textSubtitle:
                    'Valitse 1-5 Q&A korttia, joiden avulla voit kertoa itsestäsi enemmän',
                inputWidget: SizedBox(
                  height: 200,
                  child: PageView.builder(
                    itemCount: userChoices.length,
                    itemBuilder: (context, index) {
                      String question = answeredQuestions[index];
                      String answer = userChoices[question]!;

                      return Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 5.0,
                        child: Container(
                          padding: const EdgeInsets.all(15),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                question,
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppStyle.violet,
                                  fontSize: 22.0,
                                  fontFamily: 'Sora',
                                ),
                              ),
                              const SizedBox(
                                height: 8,
                              ),
                              Text(
                                answer,
                                maxLines: 4,
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Rubik',
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                secondWidget: Center(
                  child: MyElevatedButton(
                    width: 225,
                    height: 45,
                    onPressed: () async {
                      Map<String, String>? result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => QuestionAnswer(
                            recievedData: userChoices,
                          ),
                        ),
                      );
                      if (result != null) {
                        setState(
                          () {
                            userChoices = result;
                          },
                        );
                      }
                    },
                    child: const Text(
                      "+ Lisää uusi Q&A",
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: 'Rubik',
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              MyElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate() &&
                      userAreaController.text.trim().isNotEmpty &&
                      userSchoolController.text.trim().isNotEmpty &&
                      selectedLanguages.isNotEmpty &&
                      userChoices.isNotEmpty &&
                      favoriteActivities.length >= 3) {
                    _formKey.currentState!.save();

                    final miittiUser = ref.read(userStateProvider.notifier).data.toMiittiUser();
                    final updatedUser = MiittiUser(
                      name: miittiUser.name,
                      email: miittiUser.email,
                      uid: miittiUser.uid,
                      occupationalStatus: miittiUser.occupationalStatus,
                      phoneNumber: miittiUser.phoneNumber,
                      birthday: miittiUser.birthday,
                      areas: [userAreaController.text.trim()],  // TODO: Make into an actual list
                      favoriteActivities: favoriteActivities
                          .map((activity) => activity)
                          .toList(),
                      qaAnswers: userChoices,
                      gender: miittiUser.gender,
                      profilePicture: miittiUser.profilePicture,
                      languages: selectedLanguages.toList(),
                      invitedActivities: miittiUser.invitedActivities,
                      lastActive: miittiUser.lastActive,
                      organization: userSchoolController.text,
                      fcmToken: miittiUser.fcmToken,
                      registrationDate: miittiUser.registrationDate,
                    );
                    await ref
                        .read(firestoreServiceProvider)
                        .updateUserInfo(
                          updatedUser: updatedUser,
                          imageFile: image,
                          context: context,
                        )
                        .then((value) {
                      pushNRemoveUntil(
                          context,
                          const IndexPage(
                            initialPage: 3,
                          ));
                    });
                  } else {
                    showSnackBar(
                        context,
                        'Varmista, että täytät kaikki tyhjät kohdat ja yritä uudeelleen!',
                        AppStyle.red);
                  }
                },
                child: ref.watch(providerLoading)
                    ? const CircularProgressIndicator(
                        color: AppStyle.violet,
                      )
                    : Text(
                        'Tallenna muutokset',
                        style: AppStyle.body,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget returnTexts(String? bigText, String? smallText, bool isBigText) {
    if (isBigText) {
      return Padding(
        padding: const EdgeInsets.only(top: 20.0, bottom: 5.0),
        child: Text(
          bigText!,
          style: TextStyle(
            fontSize: 20.0,
            fontFamily: 'Sora',
            fontWeight: FontWeight.bold,
            color: miittiColor,
          ),
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.only(bottom: 15.0),
        child: Text(
          smallText!,
          style: TextStyle(
            fontSize: 13.0,
            fontFamily: 'Sora',
            color: miittiColor,
          ),
        ),
      );
    }
  }

  Widget createSection({
    required String textTitle,
    required String textSubtitle,
    required Widget secondWidget,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          textTitle,
          style: AppStyle.title,
        ),
        Text(
          textSubtitle,
          style: AppStyle.body,
        ),
        const SizedBox(
          height: 10,
        ),
        secondWidget,
        const SizedBox(
          height: 30,
        ),
      ],
    );
  }

  Widget _buildLanguageButton(
    Language language,
  ) {
    final bool isSelected = selectedLanguages.contains(language);

    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            selectedLanguages.remove(language);
          } else {
            selectedLanguages.add(language);
          }
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 20),
        width: 65,
        height: 65,
        decoration: BoxDecoration(
          color: isSelected
              ? AppStyle.lightPurple
              : AppStyle.lightPurple.withOpacity(0.7),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            language.name,
            style: const TextStyle(
              fontSize: 40.0,
            ),
          ),
        ),
      ),
    );
  }

  Widget createDifferentSection({
    required String textTitle,
    required String textSubtitle,
    required Widget inputWidget,
    required Widget secondWidget,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          textTitle,
          style: AppStyle.body,
        ),
        Text(
          textSubtitle,
          style: AppStyle.body,
        ),
        const SizedBox(
          height: 10,
        ),
        inputWidget,
        const SizedBox(
          height: 10,
        ),
        secondWidget,
        const SizedBox(
          height: 30,
        ),
      ],
    );
  }
}
