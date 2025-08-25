import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../screens/login/login_screen.dart';
import '../screens/home/home_screen.dart';

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GetX<AuthController>(
      builder: (controller) {
        if (controller.isLoggedIn.value) {
          return HomeScreen();
        } else {
          return LoginScreen();
        }
      },
    );
  }
}