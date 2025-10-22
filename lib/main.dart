import 'package:delivery/page/LoginPage.dart';
import 'package:flutter/material.dart';
<<<<<<< HEAD
=======
import 'package:flutter/material.dart' as Get;
import 'package:get/get_core/src/get_main.dart';
>>>>>>> parent of 37aaa2e (Merge pull request #7 from patcharap0n/done)

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
<<<<<<< HEAD
    return MaterialApp(
      home: LoginPage(),
    );
=======
    return Get.MaterialApp(home: LoginPage());
>>>>>>> parent of 37aaa2e (Merge pull request #7 from patcharap0n/done)
  }
}
