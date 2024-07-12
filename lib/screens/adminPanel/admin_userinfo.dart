import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:miitti_app/constants/app_style.dart';
import 'package:miitti_app/models/miitti_user.dart';

class AdminUserInfo extends StatefulWidget {
  final MiittiUser user;
  const AdminUserInfo({required this.user, super.key});

  @override
  State<AdminUserInfo> createState() => _AdminUserInfoState();
}

class _AdminUserInfoState extends State<AdminUserInfo> {
  String userLastOpenDate = "";

  @override
  void initState() {
    DateFormat('MMMM d, HH:mm').format(widget.user.lastActive.toDate());
    super.initState();
  }

  //Creates 3 of the purple info boxes
  Widget createPurpleBox(
      String title, String mainText, BuildContext context, bool isCopy) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      height: 100,
      width: MediaQuery.of(context).size.width,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: AppStyle.violet,
      ),
      child: ListTile(
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            color: Colors.white,
          ),
        ),
        subtitle: Text(
          mainText,
          style: const TextStyle(
            fontSize: 18,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        trailing: isCopy
            ? IconButton(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: mainText));
                },
                icon: const Icon(
                  Icons.copy,
                  size: 20,
                  color: Colors.white,
                ),
              )
            : null,
      ),
    );
  }

  Widget getRichText(String normalText, String boldedText) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(color: Colors.black),
        children: <TextSpan>[
          TextSpan(
            text: normalText,
            style: const TextStyle(fontSize: 15),
          ),
          TextSpan(
            text: boldedText,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      body: SafeArea(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 40),
                  height: 60,
                  width: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(50),
                    gradient: AppStyle.pinkGradient,
                  ),
                  child: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ),
              const Text(
                'Käyttäjätiedot',
                style: TextStyle(
                  fontSize: 20,
                ),
              ),
              createPurpleBox('Etunimi', widget.user.userName, context, false),
              createPurpleBox(
                  'Sähköposti', widget.user.userEmail, context, true),
              createPurpleBox(
                  'Puhelinnumero', widget.user.userPhoneNumber, context, true),
              getRichText('Ollut viimeksi aktiivisena:   ', userLastOpenDate),
              const SizedBox(height: 5),
              getRichText('Profiili luotu:  ',
                  widget.user.userRegistrationDate.toString()),
              const SizedBox(height: 5),
              getRichText('Käytössä oleva sovellusversio:  ', '1.2.8'),
            ],
          ),
        ),
      ),
    );
  }
}
