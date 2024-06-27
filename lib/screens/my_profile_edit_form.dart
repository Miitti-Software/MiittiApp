import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:miitti_app/constants/constants.dart';
import 'package:miitti_app/constants/app_style.dart';
import 'package:miitti_app/models/miitti_user.dart';
import 'package:miitti_app/models/activity.dart';

import 'package:miitti_app/services/providers.dart';
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

  Set<String> selectedLanguages = {};

  Map<String, String> userChoices = {};

  List<String> filteredActivities = [];
  List<String> favoriteActivities = [];

  @override
  void initState() {
    super.initState();
    filteredActivities = activities.keys.toList();
    favoriteActivities =
        updateActiviesId(widget.user.userFavoriteActivities.toSet());

    selectedLanguages = widget.user.userLanguages.toSet();
    userAreaController.text = widget.user.userArea;
    userSchoolController.text = widget.user.userSchool;
    userChoices = widget.user.userChoices;
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
        preferredSize: Size.fromHeight(70.w),
        child: AppBar(
          backgroundColor: AppStyle.black,
          automaticallyImplyLeading: false,
          title: Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: EdgeInsets.only(top: 20.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Muokkaa profiilia',
                    style: TextStyle(
                      fontSize: 27.sp,
                      fontFamily: 'Sora',
                      color: Colors.white,
                    ),
                  ),
                  const Expanded(child: SizedBox()),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Icon(
                      Icons.settings,
                      size: 30.r,
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
        margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
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
                                ref
                                    .read(firestoreService)
                                    .miittiUser!
                                    .profilePicture,
                                height: 400.h,
                                width: 400.w,
                                fit: BoxFit.cover,
                              )
                            : Image.file(
                                image!,
                                height: 400.h,
                                width: 400.w,
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
                  myPadding: EdgeInsets.only(right: 10.w),
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
                  myPadding: EdgeInsets.only(right: 10.w),
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
                      languages[0],
                    ),
                    _buildLanguageButton(
                      languages[1],
                    ),
                    _buildLanguageButton(
                      languages[2],
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 20.h,
              ),
              createSection(
                textTitle: 'Lisää lempiaktiviteettisi',
                textSubtitle:
                    'Valitse vähintään 3 lempiaktiviteettisi, mitä haluaisit tehdä muiden kanssa',
                secondWidget: SizedBox(
                  height: 400.h,
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
                          height: 100.h,
                          width: 50.w,
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
                                style: TextStyle(fontSize: 50.0.sp),
                              ),
                              Text(
                                Activity.getActivity(activity).name,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: 'Rubik',
                                  fontSize: 19.0.sp,
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
                  height: 200.w,
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
                          padding: EdgeInsets.all(15.w),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                question,
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: AppStyle.violet,
                                  fontSize: 22.0.sp,
                                  fontFamily: 'Sora',
                                ),
                              ),
                              SizedBox(
                                height: 8.h,
                              ),
                              Text(
                                answer,
                                maxLines: 4,
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 22.sp,
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
                    width: 225.w,
                    height: 45.w,
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
                    child: Text(
                      "+ Lisää uusi Q&A",
                      style: TextStyle(
                        fontSize: 16.sp,
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

                    final miittiUser = ref.read(firestoreService).miittiUser!;
                    final updatedUser = MiittiUser(
                      userName: miittiUser.userName,
                      userEmail: miittiUser.userEmail,
                      uid: miittiUser.uid,
                      userPhoneNumber: miittiUser.userPhoneNumber,
                      userBirthday: miittiUser.userBirthday,
                      userArea: userAreaController.text.trim(),
                      userFavoriteActivities: favoriteActivities
                          .map((activity) => activity)
                          .toList(),
                      userChoices: userChoices,
                      userGender: miittiUser.userGender,
                      profilePicture: miittiUser.profilePicture,
                      userLanguages: selectedLanguages.toList(),
                      invitedActivities: miittiUser.invitedActivities,
                      lastActive: miittiUser.lastActive,
                      userSchool: userSchoolController.text,
                      fcmToken: miittiUser.fcmToken,
                      userRegistrationDate: miittiUser.userRegistrationDate,
                    );
                    await ref
                        .read(firestoreService)
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
        padding: EdgeInsets.only(top: 20.0.h, bottom: 5.0.h),
        child: Text(
          bigText!,
          style: TextStyle(
            fontSize: 20.0.sp,
            fontFamily: 'Sora',
            fontWeight: FontWeight.bold,
            color: miittiColor,
          ),
        ),
      );
    } else {
      return Padding(
        padding: EdgeInsets.only(bottom: 15.0.h),
        child: Text(
          smallText!,
          style: TextStyle(
            fontSize: 13.0.sp,
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
        SizedBox(
          height: 10.h,
        ),
        secondWidget,
        SizedBox(
          height: 30.h,
        ),
      ],
    );
  }

  Widget _buildLanguageButton(
    String language,
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
        margin: EdgeInsets.only(right: 20.w),
        width: 65.w,
        height: 65.w,
        decoration: BoxDecoration(
          color: isSelected
              ? AppStyle.lightPurple
              : AppStyle.lightPurple.withOpacity(0.7),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            language,
            style: TextStyle(
              fontSize: 40.0.sp,
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
        SizedBox(
          height: 10.h,
        ),
        inputWidget,
        SizedBox(
          height: 10.h,
        ),
        secondWidget,
        SizedBox(
          height: 30.h,
        ),
      ],
    );
  }
}
