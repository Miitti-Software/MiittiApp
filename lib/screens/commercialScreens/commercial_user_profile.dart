import 'package:flutter/material.dart';
import 'package:miitti_app/models/commercial_user.dart';
import 'package:miitti_app/constants/app_style.dart';
import 'package:url_launcher/url_launcher.dart';

class CommercialProfileScreen extends StatefulWidget {
  final CommercialUser user;
  final bool? comingFromAdmin;
  const CommercialProfileScreen(
      {required this.user, this.comingFromAdmin, super.key});

  @override
  State<CommercialProfileScreen> createState() =>
      _CommercialProfileScreenState();
}

class _CommercialProfileScreenState extends State<CommercialProfileScreen> {
  Color miittiColor = const Color.fromRGBO(255, 136, 27, 1);

  @override
  void initState() {
    super.initState();
    //Initialize the list from given data
  }

  @override
  Widget build(BuildContext context) {
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
                  Text(
                    widget.user.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontFamily: 'Sora',
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: ListView(
        children: [
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            margin: const EdgeInsets.symmetric(
              vertical: 12,
              horizontal: 12,
            ),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.all(Radius.circular(15)),
                  child: Image.network(
                    widget.user.profilePicture,
                    height: 400,
                    width: 400,
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.medium,
                  ),
                ),
                Positioned(
                  top: 10,
                  left: 10,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: miittiColor,
                        gradient: AppStyle.pinkGradient,
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(
            height: 10,
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: InkWell(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.user.linkTitle,
                      textAlign: TextAlign.end,
                      style: const TextStyle(
                        fontFamily: 'Rubik',
                        fontSize: 17.0,
                        color: AppStyle.lightPurple,
                      ),
                    ),
                    const SizedBox(
                      width: 4.0,
                    ),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 12.0,
                      color: Colors.white,
                    )
                  ],
                ),
                onTap: () async {
                  await launchUrl(Uri.parse(widget.user.hyperlink));
                }),
          ),
          const SizedBox(
            height: 10,
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              widget.user.description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Rubik',
                fontSize: 17.0,
                color: AppStyle.white,
              ),
            ),
          ),
          const SizedBox(
            height: 10,
          ),
        ],
      ),
    );
  }
}
