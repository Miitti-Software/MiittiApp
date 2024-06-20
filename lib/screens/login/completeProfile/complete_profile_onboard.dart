import 'dart:io';

import 'package:email_validator/email_validator.dart';
import 'package:flutter/cupertino.dart';

import 'package:flutter/material.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:miitti_app/constants/constants.dart';
import 'package:miitti_app/services/push_notification_service.dart';
import 'package:miitti_app/widgets/buttons/choice_button.dart';
import 'package:miitti_app/widgets/confirm_notifications_dialog.dart';

import 'package:miitti_app/widgets/buttons/custom_button.dart';
import 'package:miitti_app/widgets/fields/custom_textfield.dart';
import 'package:miitti_app/models/onboarding_part.dart';
import 'package:miitti_app/constants/app_style.dart';
import 'package:miitti_app/widgets/other_widgets.dart';
import 'package:miitti_app/models/miitti_user.dart';
import 'package:miitti_app/models/activity.dart';
import 'package:miitti_app/screens/index_page.dart';
import 'package:miitti_app/screens/login/completeProfile/complete_profile_answerpage.dart';
import 'package:miitti_app/services/auth_provider.dart';

import 'package:miitti_app/functions/utils.dart';
import 'package:miitti_app/widgets/safe_scaffold.dart';
import 'package:pinput/pinput.dart';
import 'package:provider/provider.dart';

class CompleteProfileOnboard extends StatefulWidget {
  const CompleteProfileOnboard({super.key});

  @override
  State<CompleteProfileOnboard> createState() => _CompleteProfileOnboard();
}

class _CompleteProfileOnboard extends State<CompleteProfileOnboard> {
  late PageController _pageController;

  File? myImage;

  late TextEditingController _emailController;
  late TextEditingController _nameController;

  final FocusNode nameFocusNode = FocusNode();
  final FocusNode emailFocusNode = FocusNode();

  final List<ConstantsOnboarding> onboardingScreens = [
    ConstantsOnboarding(
      title: 'Aloitetaan,\nmikä on etunimesi?',
      warningText:
          'Olet uniikki, muistathan siis käyttää vain omia henkilötietoja!',
      hintText: 'Syötä etunimesi',
      keyboardType: TextInputType.name,
    ),
    ConstantsOnboarding(
      title: 'Lisää aktiivinen sähköpostiosoite',
      warningText:
          'Emme käytä sähköpostiasi koskaan markkinointiin ilman lupaasi!',
      hintText: 'Syötä sähköpostiosoitteesi',
      keyboardType: TextInputType.emailAddress,
    ),
    ConstantsOnboarding(
      title: 'Kerro meille syntymäpäiväsi',
      warningText: 'Laskemme tämän perusteella ikäsi',
    ),
    ConstantsOnboarding(
      title: 'Mikä sukupuoli\nkuvaa sinua parhaiten',
      warningText:
          'Sukupuoli ei määrittele sinua, mutta sen avulla voimme tarjota entistä paremmin miittejä juuri sinulle!',
    ),
    ConstantsOnboarding(
      title: 'Puhun jotain seuraavista kielistä',
      warningText:
          'Valitse enintään neljä kieltä, joilla voit kommunikoida muiden kanssa.',
    ),
    ConstantsOnboarding(
      title: 'Valitse paikkakunta',
      warningText:
          'Valitse enintään kaksi paikkakuntaa, jossa oleskelet. Jos asuinpaikkakuntasi puuttuu listalta valitse “Muu Suomi”',
      isFullView: true,
    ),
    ConstantsOnboarding(
      title: 'Mikä on elämäntilanteesi?',
      warningText: 'Näin osaamme yhdistää sinut paremmin uusiin tuttavuuksiin',
    ),
    ConstantsOnboarding(
      title: 'Kerro itsestäsi',
      warningText: 'Valitse 1-10 Q&A -avausta, johon haluat vastata',
      isFullView: true,
    ),
    ConstantsOnboarding(
      title: 'Lisää profiilikuva',
      warningText:
          'Lisää profiilikuva, joka kuvastaa persoonaasi parhaiten! Huomioithan, että sinun tulee näkyä itse kuvassa, eikä se saa olla tekoälyn tuottama.',
      isFullView: true,
    ),
    ConstantsOnboarding(
      title: 'Mitä tykkäät tehdä?',
      warningText:
          'Valitse enintään yhdeksän lempiaktiviteettia, joista pidät!',
      isFullView: true,
    ),
    ConstantsOnboarding(
      title: 'Älä missaa yhtäkään miittiä',
      warningText:
          'Tiedämme, että sovellusilmoitukset voivat olla ärsyttäviä, mutta niiden avulla, et missaa yhtäkään miitti-kutsua tai viestiä!',
    ),
    ConstantsOnboarding(
      title: 'Vielä lopuksi!',
      warningText:
          'Jokainen yhteisö tarvitsee sääntöjä. Tässä keskeisimmät yhteisönormimme, joita odotamme sinun noudattavan:',
      isFullView: true,
    ),
  ];

  //PAGE 1 NAME

  //PAGE 2 EMAIL

  //PAGE 3 BDAY
  String birthdayText = 'DDMMYYYY';
  String editiedVersionOfBirthdayText = "";

  //PAGE 4 GENDER
  final List<String> genders = ['Mies', 'Nainen', 'Ei-binäärinen'];
  String selectedGender = '';

  //PAGE 5 PICK LANGUAGES
  final List<String> languages = [
    'Suomi',
    'Englanti',
    'Ruotsi',
    'Viro',
    'Venäjä',
    'Arabia',
    'Saksa',
    'Ranska',
    'Espanja',
    'Kiina',
  ];
  Set<String> selectedLanguages = {};

  //PAGE 6 LIFE SITUATION
  bool noLifeSituation = false;
  final List<String> lifeOptions = [
    'Opiskelija',
    'Työelämässä',
    'Yrittäjä',
    'Etsimässä itseään',
  ];

  String selectedLifeOption = '';

  //PAGE 7 CITY
  final List<String> cities = [
    'Helsinki',
    'Espoo',
    'Vantaa',
    'Kauniainen',
    'Turku',
    'Tampere',
    'Oulu',
    'Jyväskylä',
    'Lappeenranta',
    'Muu Suomi',
  ];
  Set<String> selectedCities = {};

  //PAGE 8 Q&A
  final List<String> questionsAboutMe = [
    'Kuvailen itseäni näillä viidellä emojilla',
    'Persoonaani kuvaa parhaiten se, että',
    'Fakta, jota useimmat minusta eivät tiedä',
    'Olen uusien ihmisten seurassa yleensä',
    'Erikoisin taito, jonka osaan',
    'Lempiruokani on ehdottomasti',
    'En voisi elää ilman',
    'Olen miestäni',
    'Ottaisin mukaan autiolle saarelle',
    'Suosikkiartistini on',
    'Arvostan eniten ihmisiä, jotka',
    'Ylivoimainen inhokkiruokani on',
  ];
  final List<String> questionsAboutHobbies = [
    'Lempiharrastukseni on',
    'Käytän vapaa-päiväni useimmiten',
    'Haluaisin kokeilla',
    'Harrastin lapsena ',
    'Harrastus, jota en ole vielä uskaltanut kokeilla',
    'Haluaisin löytää',
    'Haluaisin matkustaa seuraavaksi',
    'Paras matkavinkkini on',
  ];
  final List<String> questionsAboutDeep = [
    'Koen olevani',
    'Pahin pakkomielteeni on',
    'Suurin vahvuuteni on',
    'En ole parhaimmillani',
    'Kiusallisin hetkeni oli, kun',
    'Olin viimeksi surullinen, koska',
    'En ole koskaan sanonut, että',
    'Olen otettu, jos',
    'Ottaisin mukaan autiolle saarelle',
    'Olen onnellinen, koska',
    'Tänä vuonna haluan',
  ];

  List<String> selectedList = [];

  int answerLimit = 10;
  int currentAnswers = 0;
  Map<String, String> userChoices = {};

  //PAGE 9 PICTURE
  File? image;

  //PAGE 10 ACTIVITIES
  Set<String> favoriteActivities = <String>{};

  //PAGE 11 NOTIFICATIONS
  bool notificationsEnabled = true;

  //PAGE 12 RULES
  List<String> miittiRules = <String>[
    'Käyttäydyn muita ihmisiä kohtaan ystävällisesti ja kunnioittavasti',
    'Esiinnyn sovelluksessa omana itsenäni, enkä käytä muiden kuvia tai henkilötietoja.',
    'Ymmärrän, että Miitti App ei ole deittipalvelu. Lähestyn sovelluksessa muita ihmisiä ainoastaan kaverimielessä.',
    'En harjoita tai kannusta harjoittamaan lain vastaista toimintaa sovelluksen avulla',
  ];
  List<String> userAcceptedRules = <String>[];
  bool warningSignVisible = false;

  @override
  void initState() {
    super.initState();
    selectedList = questionsAboutMe;
    /*_formControllers = List.generate(onboardingScreens.length - 1, (index) {
      if (index == 1) {
        var ap = Provider.of<AuthProvider>(context, listen: false);
        return TextEditingController(text: ap.getUserEmail());
      }
      return TextEditingController();
    });*/
    var ap = Provider.of<AuthProvider>(context, listen: false);
    _emailController = TextEditingController(text: ap.getUserEmail());
    _nameController = TextEditingController();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    /*for (var controller in _formControllers) {
      controller.dispose();
    }*/
    _emailController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> selectImage({required bool isCamera}) async {
    showLoadingDialog(context);

    image = isCamera
        ? await pickImageFromCamera(context)
        : await pickImage(context);

    if (mounted) {
      Navigator.pop(context);
    }
    setState(() {});
  }

  Widget mainWidgetsForScreens(int page) {
    ConstantsOnboarding screen = onboardingScreens[page];
    switch (page) {
      case 0:
        return MyTextField(
          hintText: screen.hintText!,
          controller: _nameController,
          keyboardType: screen.keyboardType,
          focusNode: nameFocusNode,
        );
      case 1:
        return MyTextField(
          hintText: screen.hintText!,
          controller: _emailController,
          keyboardType: screen.keyboardType,
          focusNode: emailFocusNode,
        );
      case 2:
        //Pin input for birthdate
        return Pinput(
          length: 8,
          autofocus: true,
          separatorBuilder: (index) {
            if (index == 1 || index == 3) {
              return SizedBox(width: 16.w);
            }
            return SizedBox(
              width: 8.w,
            );
          },
          defaultPinTheme: PinTheme(
            height: 45.h,
            width: 40.w,
            textStyle: AppStyle.body.copyWith(fontWeight: FontWeight.w800),
            decoration: const BoxDecoration(
              color: Color.fromRGBO(152, 28, 228, 0.10),
              border: Border(
                bottom: BorderSide(width: 1.0, color: Colors.white),
              ),
            ),
          ),
          onCompleted: (String value) {
            if (value.length == 8 && validateBirthdayDate(value)) {
              setState(() {
                editiedVersionOfBirthdayText = "${value.substring(0, 2)}/"
                    "${value.substring(2, 4)}/"
                    "${value.substring(4, 8)}";
                birthdayText = value;
              });
            } else {
              showSnackBar(
                context,
                'Syntymäpäivä ei kelpaa!',
                AppStyle.red,
              );
            }
          },
        );
      /*Row(
          children: [
            for (int i = 0; i <= 7; i++)
              GestureDetector(
                onTap: () => pickBirthdayDate(
                  context: context,
                  onDateTimeChanged: (dateTime) {
                    setState(() {
                      editiedVersionOfBirthdayText =
                          '${dateTime.month}/${dateTime.day}/${dateTime.year}';
                      birthdayText =
                          '${dateTime.day.toString().padLeft(2, '0')}${dateTime.month.toString().padLeft(2, '0')}${dateTime.year}';
                    });
                  },
                ),
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color.fromRGBO(152, 28, 228, 0.10),
                    border: Border(
                      bottom: BorderSide(width: 1.0, color: Colors.white),
                    ),
                  ),
                  margin: EdgeInsets.only(
                    right: (i == 1 || i == 3)
                        ? i == 7
                            ? 0.w
                            : 18.w
                        : 7.w,
                  ),
                  padding: EdgeInsets.all(10.w),
                  child: Center(
                    child: Text(
                      birthdayText[i],
                      style: ConstantStyles.body.copyWith(
                        color: Colors.white.withOpacity(
                          birthdayText == "DDMMYYYY" ? 0.5 : 1.0,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );*/
      case 3:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (String gender in genders)
              ChoiceButton(
                text: "Olen $gender",
                onSelected: (bool selected) {
                  if (!selected) {
                    setState(
                      () {
                        selectedGender = gender;
                      },
                    );
                  }
                },
                isSelected: gender == selectedGender,
              )
          ],
        );
      case 4:
        return Wrap(
          children: [
            for (String language in languages)
              ChoiceButton(
                text: language,
                isSelected: selectedLanguages.contains(language),
                onSelected: (bool selected) {
                  if (!selectedLanguages.contains(language)) {
                    if (selectedLanguages.length < 4) {
                      setState(() {
                        selectedLanguages.add(language);
                      });
                    } else {
                      showSnackBar(
                        context,
                        'Voit valita enintään neljä kieltä!',
                        AppStyle.red,
                      );
                    }
                  } else {
                    setState(() {
                      selectedLanguages.remove(language);
                    });
                  }
                },
              )
          ],
        );
      case 5:
        return Expanded(
          child: ListView.builder(
            itemCount: cities.length,
            itemBuilder: (context, index) {
              String city = cities[index];
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (!selectedCities.contains(city) &&
                        selectedCities.length <= 1) {
                      selectedCities.add(city);
                    } else {
                      selectedCities.remove(city);
                    }
                  });
                },
                child: Container(
                  padding: EdgeInsets.all(10.w),
                  margin: EdgeInsets.only(bottom: 8.h),
                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(224, 84, 148, 0.05),
                    border: Border.all(
                      color: selectedCities.contains(city)
                          ? AppStyle.pink
                          : Colors.transparent,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    city,
                    style: AppStyle.body,
                  ),
                ),
              );
            },
          ),
        );
      case 6:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 220.h,
              child: ListView.builder(
                itemCount: lifeOptions.length,
                itemBuilder: (context, index) {
                  String option = lifeOptions[index];
                  return GestureDetector(
                    onTap: () {
                      if (!noLifeSituation) {
                        setState(() {
                          selectedLifeOption = option;
                        });
                      }
                    },
                    child: Opacity(
                      opacity: !noLifeSituation ? 1.0 : 0.2,
                      child: Container(
                        padding: EdgeInsets.all(10.w),
                        margin: EdgeInsets.only(bottom: 8.h),
                        decoration: BoxDecoration(
                          color: const Color.fromRGBO(224, 84, 148, 0.05),
                          border: Border.all(
                            color: selectedLifeOption == option
                                ? AppStyle.pink
                                : Colors.transparent,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          option,
                          style: AppStyle.body,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CupertinoSwitch(
                activeColor: AppStyle.pink,
                value: noLifeSituation,
                onChanged: (bool value) {
                  setState(() {
                    selectedLifeOption = "";
                    noLifeSituation = value;
                  });
                },
              ),
              title: Text(
                'Jätän tämän tyhjäksi',
                style: AppStyle.hintText.copyWith(
                    fontWeight: FontWeight.w500,
                    color: noLifeSituation
                        ? Colors.white
                        : const Color.fromRGBO(255, 255, 255, 0.20)),
              ),
            )
          ],
        );
      case 7:
        return Column(
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedList = questionsAboutMe;
                    });
                  },
                  child: Container(
                    margin: EdgeInsets.only(right: 10.w, bottom: 10.h),
                    padding:
                        EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A1026),
                      borderRadius: BorderRadius.circular(10.0),
                      border: Border.all(
                        color: selectedList == questionsAboutMe
                            ? AppStyle.pink
                            : Colors.transparent,
                        width: 1.0,
                      ),
                    ),
                    child: Text(
                      'Enemmän minusta',
                      style: AppStyle.warning,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedList = questionsAboutHobbies;
                    });
                  },
                  child: Container(
                    margin: EdgeInsets.only(right: 10.w, bottom: 10.h),
                    padding:
                        EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A1026),
                      borderRadius: BorderRadius.circular(10.0),
                      border: Border.all(
                        color: selectedList == questionsAboutHobbies
                            ? AppStyle.pink
                            : Colors.transparent,
                        width: 1.0,
                      ),
                    ),
                    child: Text(
                      'Harrastukset',
                      style: AppStyle.warning,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedList = questionsAboutDeep;
                    });
                  },
                  child: Container(
                    margin: EdgeInsets.only(right: 10.w, bottom: 10.h),
                    padding:
                        EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A1026),
                      borderRadius: BorderRadius.circular(10.0),
                      border: Border.all(
                        color: selectedList == questionsAboutDeep
                            ? AppStyle.pink
                            : Colors.transparent,
                        width: 1.0,
                      ),
                    ),
                    child: Text(
                      'Syvälliset',
                      style: AppStyle.warning,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(
              height: 500.h,
              child: ListView.builder(
                itemCount: selectedList.length,
                itemBuilder: (context, index) {
                  String question = selectedList[index];
                  return GestureDetector(
                    onTap: () async {
                      String? result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CompleteProfileAnswerPage(
                            question: question,
                            questionAnswer: userChoices[question],
                          ),
                        ),
                      );
                      if (result != null) {
                        setState(() {
                          if (result != "") {
                            userChoices[question] = result;
                          } else {
                            userChoices.remove(question);
                          }
                        });
                      }
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 15.h),
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            width: 1.0,
                            color: Color.fromRGBO(224, 84, 148, 0.20),
                          ),
                          top: BorderSide(
                            width: 1.0,
                            color: Color.fromRGBO(224, 84, 148, 0.20),
                          ),
                        ),
                      ),
                      child: Text(
                        question,
                        style: AppStyle.question.copyWith(
                          color: Colors.white.withOpacity(
                            userChoices.containsKey(question) ? 0.5 : 1.0,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      case 8:
        return Expanded(
          child: Column(
            children: [
              image != null
                  ? SizedBox(
                      height: 350.h,
                      width: 350.w,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(
                          image!,
                          fit: BoxFit.cover,
                        ),
                      ),
                    )
                  : Container(
                      height: 350.h,
                      width: 350.w,
                      decoration: const BoxDecoration(
                        color: Color.fromRGBO(250, 250, 253, 0.10),
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                      ),
                      child: Center(
                        child: Text(
                          'Ei lisättyjä kuvia',
                          style: AppStyle.body.copyWith(fontSize: 24.sp),
                        ),
                      ),
                    ),
              gapH10,
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () {
                      selectImage(isCamera: false);
                    },
                    child: Container(
                      padding: EdgeInsets.all(10.w),
                      decoration: const BoxDecoration(
                        color: Color.fromRGBO(250, 250, 253, 0.05),
                        borderRadius: BorderRadius.all(Radius.circular(6)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.image_search_rounded,
                            color: Colors.white,
                          ),
                          gapW5,
                          Text(
                            'Lisää uusi kuva',
                            style: AppStyle.body.copyWith(fontSize: 16.sp),
                          ),
                        ],
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      selectImage(isCamera: true);
                    },
                    child: Container(
                      padding: EdgeInsets.all(10.w),
                      decoration: const BoxDecoration(
                        color: Color.fromRGBO(250, 250, 253, 0.05),
                        borderRadius: BorderRadius.all(Radius.circular(6)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.photo_camera_rounded,
                            color: Colors.white,
                          ),
                          gapW5,
                          Text(
                            'Ota uusi kuva',
                            style: AppStyle.body.copyWith(fontSize: 16.sp),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      case 9:
        return Expanded(
          child: GridView.builder(
            itemCount: activities.keys.toList().length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 20.0,
              mainAxisSpacing: 10.0,
            ),
            itemBuilder: (context, index) {
              final activity = activities.keys.toList()[index];
              final isSelected = favoriteActivities.contains(activity);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (favoriteActivities.contains(activity)) {
                      favoriteActivities.remove(activity);
                    } else {
                      if (favoriteActivities.length < 9) {
                        favoriteActivities.add(activity);
                      }
                    }
                  });
                },
                child: Container(
                  width: 100.w,
                  padding: EdgeInsets.symmetric(
                    vertical: 10.h,
                    horizontal: 5.h,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? AppStyle.pink : Colors.transparent,
                    borderRadius: const BorderRadius.all(
                      Radius.circular(10.0),
                    ),
                    border: Border.all(color: AppStyle.pink),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Text(
                        Activity.getActivity(activity).emojiData,
                        style: AppStyle.title,
                      ),
                      Text(
                        Activity.getActivity(activity).name,
                        overflow: TextOverflow.ellipsis,
                        style: AppStyle.warning.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      case 10:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ChoiceButton(
              text: "Hyväksyn push-ilmoitukset",
              onSelected: (bool selected) {
                if (!selected) {
                  PushNotificationService.requestPermission(true)
                      .then((bool granted) {
                    if (granted) {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.linear,
                      );
                    }
                  });
                  setState(
                    () {
                      notificationsEnabled = true;
                    },
                  );
                }
              },
              isSelected: notificationsEnabled,
            ),
            ChoiceButton(
              text: "En hyväksy",
              onSelected: (bool selected) {
                if (!selected) {
                  setState(
                    () {
                      notificationsEnabled = false;
                    },
                  );
                }
              },
              isSelected: !notificationsEnabled,
            ),
          ],
        );
      case 11:
        return Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              for (String rule in miittiRules)
                GestureDetector(
                  onTap: () {
                    setState(() {
                      if (userAcceptedRules.contains(rule)) {
                        userAcceptedRules.remove(rule);
                      } else {
                        userAcceptedRules.add(rule);
                      }
                    });
                  },
                  child: Container(
                    margin: EdgeInsets.only(bottom: 15.h),
                    padding: EdgeInsets.all(10.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A1026),
                      borderRadius: BorderRadius.circular(10.0),
                      border: Border.all(
                        color: userAcceptedRules.contains(rule)
                            ? AppStyle.pink
                            : Colors.transparent,
                        width: 1.0,
                      ),
                    ),
                    child: Text(
                      rule,
                      style: AppStyle.warning,
                    ),
                  ),
                ),
              const Spacer(),
              warningSignVisible
                  ? Text(
                      'Sinun täytyy klikata kaikki kohdat hyväksytyksi jatkaaksesi!',
                      style: AppStyle.warning.copyWith(
                        color: AppStyle.red,
                      ),
                    )
                  : Container()
            ],
          ),
        );
    }
    //Error
    return Center(
      child: Text(
        'Error',
        style: AppStyle.warning,
      ),
    );
  }

  void registerUser(BuildContext context, MiittiUser user) {
    final ap = Provider.of<AuthProvider>(context, listen: false);
    /*user.uid = ap.uid;
    if (ap.isAnonymous) {
      ap
          .updateUserInfo(
            updatedUser: user,
            imageFile: image,
            context: context,
          )
          .then(
            (value) => ap.saveUserDataToSP().then(
                  (value) => ap.setSignIn().then(
                        (value) => ap.setAnonymousModeOf().then(
                            (value) => Navigator.pop(
                                context) /*pushNRemoveUntil(
                                context,
                                const IndexPage(),
                              ),*/
                            ),
                      ),
                ),
          );
    } else {*/
    ap.saveUserDatatoFirebase(
      context: context,
      userModel: user,
      image: image,
      onSuccess: () {
        ap.saveUserDataToSP().then(
              (value) => ap.setAnonymousModeOff().then(
                    (value) => ap.setSignIn().then(
                      (value) {
                        pushNRemoveUntil(context, const IndexPage());
                      },
                    ),
                  ),
            );
      },
    );
    //}
  }

  void errorHandlingScreens(int page) {
    final currentPage = _pageController.page!.toInt();

    switch (currentPage) {
      case 0:
        if (_nameController.text.isEmpty) {
          showSnackBar(
            context,
            'Kysymys "${onboardingScreens[0].title}" ei voi olla tyhjä!',
            AppStyle.red,
          );
          return;
        }
        break;
      case 1:
        if (!EmailValidator.validate(_emailController.text)) {
          showSnackBar(
            context,
            'Sähköposti on tyhjä tai se on väärä sähköposti!!',
            AppStyle.red,
          );
          return;
        }
        break;
      case 2:
        if (birthdayText == 'DDMMYYYY') {
          showSnackBar(
            context,
            'Syntymäpäivä ei kelpaa!',
            AppStyle.red,
          );
          return;
        }
        break;
      case 3:
        if (selectedGender.isEmpty) {
          showSnackBar(
            context,
            'Kysymys "${onboardingScreens[3].title}" ei voi olla tyhjä!',
            AppStyle.red,
          );
          return;
        }
      case 4:
        if (selectedLanguages.isEmpty || selectedLanguages.length > 4) {
          showSnackBar(
            context,
            'Valitse vähintään 1 ja enintään 4 kieltä!',
            AppStyle.red,
          );
          return;
        }
      case 5:
        if (selectedCities.isEmpty && selectedCities.length <= 1) {
          showSnackBar(
            context,
            'Valitse vähintään 1 ja enintään 2 paikkakuntaa!',
            AppStyle.red,
          );
          return;
        }
      case 6:
        if (selectedLifeOption.isEmpty && noLifeSituation == false) {
          showSnackBar(
            context,
            'Valitse  1 elämäntilanteesi tai jätä sen tyhjäksi!',
            AppStyle.red,
          );
          return;
        }

      case 7:
        if (userChoices.isEmpty) {
          showSnackBar(
            context,
            'Valitse 1-10 Q&A -avausta, johon haluat vastata',
            AppStyle.red,
          );
          return;
        }
      case 8:
        if (image == null) {
          showSnackBar(
            context,
            'Profiilikuva ei voi olla tyhjä!',
            AppStyle.red,
          );
          return;
        }
      case 9:
        if (favoriteActivities.isEmpty || favoriteActivities.length > 9) {
          showSnackBar(
            context,
            'Valitse lempiaktiviteettia, joista pidät!',
            AppStyle.red,
          );
          return;
        }
      case 10:
        if (!notificationsEnabled) {
          showDialog(
            context: context,
            builder: (context) => ConfirmNotificationsDialog(
              nextPage: () {
                _pageController.nextPage(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.linear,
                );
              },
            ),
          );
        } else {
          PushNotificationService.checkPermission().then((granted) {
            if (granted) {
              _pageController.nextPage(
                duration: const Duration(milliseconds: 500),
                curve: Curves.linear,
              );
            } else {
              PushNotificationService.requestPermission(true)
                  .then((grantFixed) {
                if (grantFixed) {
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.linear,
                  );
                } else {
                  showSnackBar(
                    context,
                    'Hyväksy push-ilmoitukset myös laitteeltasi jatkaaksesi!',
                    AppStyle.red,
                  );
                }
              });
            }
          });
        }
        return;
      case 11:
        if (userAcceptedRules.length != miittiRules.length) {
          setState(() {
            warningSignVisible = true;
          });
          return;
        }
    }

    if (page != onboardingScreens.length - 1) {
      if (page == 0 && nameFocusNode.hasFocus) {
        nameFocusNode.unfocus();
      } else if (page == 1 && emailFocusNode.hasFocus) {
        emailFocusNode.unfocus();
      }

      if (page == 9) {
        //Next page is notification page, if push notifications are already enabled, skip this page
        PushNotificationService.checkPermission().then((enabled) {
          if (enabled) {
            _pageController.animateToPage(
              11,
              duration: const Duration(milliseconds: 500),
              curve: Curves.linear,
            );
          } else {
            _pageController.nextPage(
              duration: const Duration(milliseconds: 500),
              curve: Curves.linear,
            );
            PushNotificationService.requestPermission(false)
                .then((bool granted) {
              if (granted) {
                _pageController.nextPage(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.linear,
                );
              }
            });
          }
        });
      } else {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 500),
          curve: Curves.linear,
        );
      }
    } else {
      MiittiUser miittiUser = MiittiUser(
        userName: _nameController.text.trim(),
        userEmail: _emailController.text.trim(),
        uid: '',
        userPhoneNumber: '',
        userBirthday: editiedVersionOfBirthdayText,
        userArea: selectedCities.join(","),
        userFavoriteActivities: favoriteActivities,
        userChoices: userChoices,
        userGender: selectedGender,
        userLanguages: selectedLanguages,
        profilePicture: '',
        invitedActivities: {},
        userStatus: '',
        userSchool: noLifeSituation ? '' : selectedLifeOption,
        fcmToken: '',
        userRegistrationDate: DateFormat('dd/MM/yyyy').format(DateTime.now()),
      );
      registerUser(context, miittiUser);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeScaffold(
      Flex(
        direction: Axis.vertical,
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: onboardingScreens.length,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                ConstantsOnboarding screen = onboardingScreens[index];
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      screen.isFullView == true ? gapH10 : const Spacer(),
                      Text(
                        screen.title,
                        style: AppStyle.title,
                      ),
                      Text(
                        screen.warningText!,
                        style: AppStyle.warning,
                      ),
                      gapH20,
                      mainWidgetsForScreens(index),

                      screen.isFullView == true ? gapH10 : const Spacer(),
                      MyButton(
                        buttonText: screen.title == 'Vielä lopuksi!'
                            ? 'Hyväksyn yhteisönormit'
                            : 'Seuraava',
                        onPressed: () => errorHandlingScreens(index),
                      ), //Removed extra padding in ConstantsCustomButton
                      gapH10,
                      MyButton(
                        buttonText: 'Takaisin',
                        isWhiteButton: true,
                        onPressed: () {
                          if (_pageController.page != 0) {
                            _pageController.previousPage(
                              duration: const Duration(milliseconds: 500),
                              curve: Curves.linear,
                            );
                          } else {
                            Navigator.pop(context);
                          }
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
