import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:delivery/page/GPSandMapPage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

// Cloudinary
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:latlong2/latlong.dart' as latlong2;

class RegisterUserPage extends StatefulWidget {
  final String role;
  const RegisterUserPage({super.key, required this.role});

  @override
  State<RegisterUserPage> createState() => _RegisterUserPageState();
}

class _RegisterUserPageState extends State<RegisterUserPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  File? _tempImageFile; // ไฟล์รูปชั่วคราว
  String? _imageUrl; // URL หลังอัปโหลด

  List<String> _addresses = []; // เก็บที่อยู่จาก GPS

  final ImagePicker _picker = ImagePicker();

  // Cloudinary
  final cloudinary = CloudinaryPublic(
    'dpar6zwks', // Cloud Name
    'delivery', // Upload Preset (Unsigned)
    cache: false,
  );

  // ฟังก์ชันเลือกภาพ
  Future<void> pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _tempImageFile = File(pickedFile.path);
      });
    }
  }

  // ฟังก์ชันอัปโหลด Cloudinary
  Future<String?> _uploadAndGetUrl(File? file, String folderName) async {
    if (file == null) return null;

    try {
      CloudinaryResponse response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          file.path,
          resourceType: CloudinaryResourceType.Image,
          folder: folderName,
        ),
      );
      return response.secureUrl;
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('อัปโหลดรูปภาพล้มเหลว: $e')));
      return null;
    }
  }

  void register() async {
    if (_formKey.currentState!.validate()) {
      // ตรวจสอบว่ามีรูปภาพหรือไม่
      if (_tempImageFile == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('กรุณาเลือกภาพผู้ใช้')));
        return;
      }

      // อัปโหลดรูป
      String? url = await _uploadAndGetUrl(
        _tempImageFile,
        'user_profile_images',
      );
      if (url == null) return;

      setState(() {
        _imageUrl = url;
      });

      // บันทึกลง Firestore
      var db = FirebaseFirestore.instance;
      var data = {
        'First_name': _firstNameController.text,
        'Last_name': _lastNameController.text,
        'Phone': _phoneController.text,
        'Password': _passwordController.text,
        'addr': _addresses,
        'Image': _imageUrl, // ใช้ URL จาก Cloudinary
        'Role': widget.role,
      };
      await db.collection('User').doc().set(data);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ลงทะเบียน User สำเร็จแล้ว')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ลงทะเบียน User')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _firstNameController,
                  decoration: const InputDecoration(labelText: 'ชื่อ'),
                  validator: (value) => value!.isEmpty ? 'กรุณากรอกชื่อ' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _lastNameController,
                  decoration: const InputDecoration(labelText: 'สกุล'),
                  validator: (value) => value!.isEmpty ? 'กรุณากรอกสกุล' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(labelText: 'เบอร์โทร'),
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

                ElevatedButton(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => GPSandMapPage(
                          onPick: (latlong2.LatLng pos) {
                            setState(() {
                              _addresses.add(
                                '${pos.latitude}, ${pos.longitude}',
                              );
                            });
                          },
                        ),
                      ),
                    );
                  },
                  child: const Text('เลือกที่อยู่จาก Map'),
                ),
                const SizedBox(height: 8),

                // แสดงรายการที่อยู่
                for (var i = 0; i < _addresses.length; i++)
                  ListTile(
                    leading: const Icon(Icons.home),
                    title: Text(_addresses[i]),
                    trailing: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        setState(() {
                          _addresses.removeAt(i);
                        });
                      },
                    ),
                  ),
                const SizedBox(height: 16),

                ElevatedButton.icon(
                  onPressed: pickImage,
                  icon: const Icon(Icons.image),
                  label: const Text('เลือกภาพจากเครื่อง'),
                ),
                if (_tempImageFile != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Image.file(_tempImageFile!, height: 100),
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
