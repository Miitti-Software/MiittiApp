import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:miitti_app/screens/adminPanel/admin_userinfo.dart';
import 'package:miitti_app/services/service_providers.dart';
import 'package:miitti_app/widgets/fields/admin_searchbar.dart';
import 'package:miitti_app/constants/app_style.dart';
import 'package:miitti_app/models/miitti_user.dart';
import 'package:miitti_app/screens/user_profile_edit_screen.dart';
import 'package:miitti_app/functions/utils.dart';

class AdminSearchUser extends ConsumerStatefulWidget {
  const AdminSearchUser({super.key});

  @override
  ConsumerState<AdminSearchUser> createState() => _AdminSearchUserState();
}

class _AdminSearchUserState extends ConsumerState<AdminSearchUser> {
  //All Users
  List<MiittiUser> _miittiUsers = [];

  //List to display users
  List<MiittiUser> searchResults = [];

  //Updating the list based on the query
  void onQueryChanged(String query) {
    setState(() {
      searchResults = _miittiUsers
          .where((user) =>
              user.userName.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  void initState() {
    getAllTheUsers();
    super.initState();
  }

  //Fetching all the users from Google Firebase and assigning the list with them
  Future<void> getAllTheUsers() async {
    List<MiittiUser> users = await ref.read(firestoreService).fetchUsers();

    _miittiUsers = users.reversed.toList();
    searchResults = _miittiUsers;
    setState(() {});
  }

  //Used RichText because, we wanted different styles for the same text
  Widget getRichText() {
    return RichText(
      text: TextSpan(
        style: DefaultTextStyle.of(context).style,
        children: <TextSpan>[
          TextSpan(
            text: searchResults.length.toString(),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const TextSpan(
            text: ' profiilia löydetty',
            style: TextStyle(fontSize: 15),
          ),
        ],
      ),
    );
  }

  Widget getListTileButton(Color mainColor, String text, Function() onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
        ),
        minimumSize: const Size(0, 35),
        backgroundColor: mainColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
      ),
      child: Text(
        text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            AdminSearchBar(
              onChanged: onQueryChanged,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: getRichText(),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: searchResults.length,
                itemBuilder: (context, index) {
                  MiittiUser user = searchResults[index];

                  // Format the date and time in the desired format or provide an empty string if null
                  String formattedDate = DateFormat('MMMM d, HH:mm')
                      .format(user.lastActive.toDate());

                  return Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
                    ),
                    margin:
                        const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
                    height: 100,
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(20),
                            bottomRight: Radius.circular(20),
                          ),
                          child: Image.network(
                            user.profilePicture,
                            fit: BoxFit.cover,
                            height: 100,
                            width: 100,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "${user.userName}, ${calculateAge(user.userBirthday)}",
                                style: const TextStyle(
                                  fontFamily: 'Rubik',
                                  fontSize: 18,
                                ),
                              ),
                              Text(
                                'Aktiivisena viimeksi $formattedDate',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontFamily: 'Sora',
                                ),
                              ),
                              Expanded(
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    getListTileButton(
                                      AppStyle.lightPurple,
                                      'Katso profiili',
                                      () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              UserProfileEditScreen(
                                            user: user,
                                            comingFromAdmin: true,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(
                                      width: 10,
                                    ),
                                    getListTileButton(
                                      AppStyle.violet,
                                      'Käyttäjätiedot',
                                      () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              AdminUserInfo(user: user),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
