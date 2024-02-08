import 'package:easy_localization/easy_localization.dart';
import 'package:nocstore/constants.dart';
import 'package:nocstore/services/helper.dart';
import 'package:nocstore/ui/login/LoginScreen.dart';
import 'package:nocstore/ui/signUp/SignUpScreen.dart';
import 'package:flutter/material.dart';

class AuthScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Center(
            child: Image.asset(
              'assets/images/app_logo.png',
              // color: Color(COLOR_PRIMARY),
              fit: BoxFit.cover,
              width: 150,
              height: 150,
            ),
          ),
          Padding(
            padding:
                const EdgeInsets.only(left: 16, top: 32, right: 16, bottom: 8),
            child: Text(
              'Welcome to Store Admin App'.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Color(0xFFFEDF00),
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold),
            ).tr(),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
            child: Text(
              'Accept orders and manage your store products.'.tr(),
              style: TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ).tr(),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 40.0, left: 40.0, top: 40),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: double.infinity),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(COLOR_PRIMARY),
                  padding: EdgeInsets.only(top: 12, bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25.0),
                    side: BorderSide(
                      color: Color(0xFFFEDF00),
                    ),
                  ),
                ),
                child: Text(
                  'Log In'.tr(),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ).tr(),
                onPressed: () {
                  push(context, new LoginScreen());
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(
                right: 40.0, left: 40.0, top: 20, bottom: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: double.infinity),
              child: TextButton(
                style: TextButton.styleFrom(
                  padding: EdgeInsets.only(top: 12, bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25.0),
                    side: BorderSide(
                      color: Color(0xFFFEDF00),
                    ),
                  ),
                ),
                child: Text(
                  'Sign Up'.tr(),
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode(context) ? Color(COLOR_PRIMARY) : Colors.black),
                ).tr(),
                onPressed: () {
                  push(context, new SignUpScreen());
                },
              ),
            ),
          )
        ],
      ),
    );
  }
}
