import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:miitti_app/screens/adminPanel/admin_userinfo.dart';
import 'package:miitti_app/widgets/admin_searchbar.dart';
import 'package:miitti_app/constants/app_style.dart';
import 'package:miitti_app/models/miitti_user.dart';
import 'package:miitti_app/services/auth_provider.dart';
import 'package:miitti_app/screens/user_profile_edit_screen.dart';
import 'package:miitti_app/functions/utils.dart';
import 'package:provider/provider.dart';

class AdminSearchUser extends StatefulWidget {
  const AdminSearchUser({super.key});

  @override
  State<AdminSearchUser> createState() => _AdminSearchUserState();
}

class _AdminSearchUserState extends State<AdminSearchUser> {
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
    List<MiittiUser> users =
        await Provider.of<AuthProvider>(context, listen: false).fetchUsers();

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
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15.sp),
          ),
          TextSpan(
            text: ' profiilia löydetty',
            style: TextStyle(fontSize: 15.sp),
          ),
        ],
      ),
    );
  }

  Widget getListTileButton(Color mainColor, String text, Function() onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(
          horizontal: 10.w,
        ),
        minimumSize: Size(0, 35.h),
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
              padding: EdgeInsets.symmetric(horizontal: 10.w),
              child: getRichText(),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: searchResults.length,
                itemBuilder: (context, index) {
                  MiittiUser user = searchResults[index];

                  // Format the date and time in the desired format or provide an empty string if null
                  String formattedDate = user.userStatus.isEmpty
                      ? ''
                      : DateFormat('MMMM d, HH:mm')
                          .format(DateTime.tryParse(user.userStatus)!);

                  return Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
                    ),
                    margin:
                        EdgeInsets.symmetric(vertical: 20.h, horizontal: 15.w),
                    height: 100.h,
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
                            height: 100.h,
                            width: 100.w,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "${user.userName}, ${calculateAge(user.userBirthday)}",
                                style: TextStyle(
                                  fontFamily: 'Rubik',
                                  fontSize: 18.sp,
                                ),
                              ),
                              Text(
                                'Aktiivisena viimeksi $formattedDate',
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  fontFamily: 'Sora',
                                ),
                              ),
                              Expanded(
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    getListTileButton(
                                      AppStyle.lightPurpleColor,
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
                                    SizedBox(
                                      width: 10.w,
                                    ),
                                    getListTileButton(
                                      AppStyle.purpleColor,
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
