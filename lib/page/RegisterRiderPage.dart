import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:delivery/page/LoginPage.dart';
import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/get_navigation.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class RegisterRiderPage extends StatefulWidget {
  final String role; // กำหนดเป็น 'Rider'

  const RegisterRiderPage({super.key, required this.role});

  @override
  State<RegisterRiderPage> createState() => _RegisterRiderPageState();
}

class _RegisterRiderPageState extends State<RegisterRiderPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _vehicleNumberController =
      TextEditingController();

  File? _riderImage; // รูปผู้ขับ
  File? _vehicleImage; // รูปยานพาหนะ

  final ImagePicker _picker = ImagePicker();

  // เลือกรูปภาพ
  Future<void> pickRiderImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _riderImage = File(pickedFile.path);
      });
    }
  }

  Future<void> pickVehicleImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _vehicleImage = File(pickedFile.path);
      });
    }
  }

  void register() {
    if (_formKey.currentState!.validate()) {
      var db = FirebaseFirestore.instance;
      var data = {
        'Role': widget.role,
        'Name': _nameController.text,
        'Phone': _phoneController.text,
        'Password': _passwordController.text,
        'VehicleNumber': _vehicleNumberController.text,
        'RiderImage': _riderImage.toString(),
        'VehicleImage': _vehicleImage.toString(),
      };
      db.collection('riders').doc().set(data);
      Get.to(LoginPage());
      // ข้อมูลพร้อมส่งไป backend / Firebase
      print('Role: ${widget.role}'); // Rider
      print('ชื่อ: ${_nameController.text}');
      print('เบอร์: ${_phoneController.text}');
      print('รหัสผ่าน: ${_passwordController.text}');
      print('ทะเบียนรถ: ${_vehicleNumberController.text}');
      print('รูปผู้ขับ: $_riderImage');
      print('รูปยานพาหนะ: $_vehicleImage');

      // TODO: ส่งข้อมูลไป Firebase Auth / Firestore / Storage
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ลงทะเบียน Rider')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'ชื่อ'),
                  validator: (value) => value!.isEmpty ? 'กรุณากรอกชื่อ' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'หมายเลขโทรศัพท์',
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) =>
                      value!.isEmpty ? 'กรุณากรอกเบอร์โทร' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'รหัสผ่าน'),
                  obscureText: true,
                  validator: (value) =>
                      value!.length < 6 ? 'รหัสผ่านต้องอย่างน้อย 6 ตัว' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _vehicleNumberController,
                  decoration: const InputDecoration(labelText: 'ทะเบียนรถ'),
                  validator: (value) =>
                      value!.isEmpty ? 'กรุณากรอกทะเบียนรถ' : null,
                ),
                const SizedBox(height: 16),

                // เลือกรูปผู้ขับ
                ElevatedButton.icon(
                  onPressed: pickRiderImage,
                  icon: const Icon(Icons.person),
                  label: const Text('เลือกรูปผู้ขับ'),
                ),
                if (_riderImage != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Image.file(_riderImage!, height: 100),
                  ),

                const SizedBox(height: 16),

                // เลือกรูปยานพาหนะ
                ElevatedButton.icon(
                  onPressed: pickVehicleImage,
                  icon: const Icon(Icons.directions_bike),
                  label: const Text('เลือกรูปยานพาหนะ'),
                ),
                if (_vehicleImage != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Image.file(_vehicleImage!, height: 100),
                  ),

                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0x9C0560FA),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'ลงทะเบียน',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
