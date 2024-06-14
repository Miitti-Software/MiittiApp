import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:miitti_app/screens/adminPanel/admin_homepage.dart';
import 'package:miitti_app/widgets/admin_button.dart';
import 'package:miitti_app/widgets/admin_textfield.dart';
import 'package:miitti_app/functions/utils.dart';

class AdminSignIn extends StatefulWidget {
  const AdminSignIn({super.key});

  @override
  State<AdminSignIn> createState() => _AdminRegistrationState();
}

class _AdminRegistrationState extends State<AdminSignIn> {
  //text editing controllers
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  //sign user in method
  void signUserIn() {
    if (usernameController.text == 'fatih' &&
        passwordController.text == 'admin') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AdminHomePage()),
      );
    } else {
      showSnackBar(
          context, 'Väärä tunnukset, yritä uudelleen!', Colors.red.shade800);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: 50.h),

              //logo
              Icon(
                Icons.lock,
                size: 100.sp,
              ),

              SizedBox(height: 50.h),

              //welcome back
              Text(
                'Tervetuloa takaisin, sinua on ikävöity!',
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 16.sp,
                ),
              ),

              SizedBox(height: 25.h),

              //username textfield
              AdminTextField(
                controller: usernameController,
                hintText: 'Käyttäjä:',
                obsecureText: false,
              ),

              SizedBox(height: 10.h),

              //password textfield
              AdminTextField(
                controller: passwordController,
                hintText: 'Salasana:',
                obsecureText: true,
              ),

              SizedBox(height: 35.h),

              //sign in button
              AdminButton(
                onTap: signUserIn,
              ),

              SizedBox(height: 25.h),

              //info about the admin panel
              Text(
                '🚧 Vain valtuutetut henkilöt! 🚧',
                style: TextStyle(color: Colors.grey[700], fontSize: 16.sp),
              ),

              SizedBox(height: 5.h),

              Padding(
                padding: EdgeInsets.symmetric(horizontal: 5.w),
                child: Text(
                  'Tämä alue on tarkoitettu vain sovelluksen henkilökunnalle. Jos päädyit tänne vahingossa, sulje sovellus ja yritä uudelleen. Kysymyksiä tai ongelmia? Ota yhteyttä tukitiimiimme. ',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 14.sp,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
