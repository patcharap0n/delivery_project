import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:delivery/page/RegisterRiderPage.dart';
import 'package:delivery/page/RegisterUserPage.dart';
import 'package:delivery/page/home_User_page.dart';
import 'package:delivery/page/home_rider_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                const Text(
                  'ยินดีต้อนรับสู่แอปพลิเคชันการจัดส่ง',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'กรอกอีเมล์และรหัสผ่านของคุณเพื่อดำเนินการต่อ',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 40),

                // ช่องใส่อีเมล์
                TextFormField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    labelText: 'เบอร์โทรศัพท์',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter
                        .digitsOnly, // ✅ พิมพ์ได้เฉพาะตัวเลข
                    LengthLimitingTextInputFormatter(10), // ✅ จำกัดแค่ 10 หลัก
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'กรุณากรอกเบอร์โทรศัพท์';
                    }
                    if (!RegExp(r'^0[0-9]{9}$').hasMatch(value)) {
                      return 'กรุณากรอกเบอร์โทรศัพท์ให้ถูกต้อง';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // ช่องใส่รหัสผ่าน
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'กรุณากรอกรหัสผ่าน';
                    }
                    if (value.length < 6) {
                      return 'รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // ปุ่ม Login
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0x9C0560FA),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'Login',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // ปุ่มลงทะเบียน User และ Rider
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // ปุ่มลงทะเบียน User
                    OutlinedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                RegisterUserPage(role: 'User'),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: Color(0x9C0560FA)),
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
                      ),
                      child: const Text(
                        'ลงทะเบียน User',
                        style: TextStyle(color: Color(0x9C0560FA)),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // ปุ่มลงทะเบียน Rider
                    OutlinedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                RegisterRiderPage(role: 'Rider'),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: Color(0x9C0560FA)),
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
                      ),
                      child: const Text(
                        'ลงทะเบียน Rider',
                        style: TextStyle(color: Color(0x9C0560FA)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void login() async {
    var db = FirebaseFirestore.instance;

    var userRef = db.collection('User');
    var riderRef = db.collection('riders');

    var userquery = await userRef
        .where("Phone", isEqualTo: _phoneController.text.trim())
        .where("Password", isEqualTo: _passwordController.text.trim())
        .get();
    var riderquery = await riderRef
        .where("Phone", isEqualTo: _phoneController.text.trim())
        .where("Password", isEqualTo: _passwordController.text.trim())
        .get();

    if (userquery.docs.isNotEmpty) {
      var userData = userquery.docs.first.data();
      String role = userData['Role'];
      if (role == "User") {
        Get.to(Userhome());
      } else {
        Get.snackbar("Error", "Role ไม่ถูกต้อง");
      }
    } else {
      if (riderquery.docs.isNotEmpty) {
        var userData = riderquery.docs.first.data();
        String role = userData['Role'];
        if (role == "Rider") {
          Get.to(HomeRider());
        } else {
          Get.snackbar("Error", "Role ไม่ถูกต้อง");
        }
      } else {
        Get.snackbar("Login Failed", "อีเมลหรือรหัสผ่านไม่ถูกต้อง");
      }
    }
  }
}
