import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

// แพ็กเกจใหม่ที่ใช้ในการอัปโหลด
import 'package:cloudinary_public/cloudinary_public.dart';

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

  File? _tempRiderImageFile; // ไฟล์รูปชั่วคราวที่เลือกจากเครื่อง
  File? _tempVehicleImageFile; // ไฟล์รูปชั่วคราวที่เลือกจากเครื่อง

  // **ตัวแปรสำหรับเก็บ URL หลังจากอัปโหลดสำเร็จ**
  String? _riderImageUrl;
  String? _vehicleImageUrl;

  final ImagePicker _picker = ImagePicker();

  // **กำหนดค่า Cloudinary ที่นี่**
  // ***เปลี่ยนค่า 'YOUR_CLOUD_NAME' และ 'YOUR_UNSIGNED_PRESET' ด้วยค่าจริงของคุณ***
  final cloudinary = CloudinaryPublic(
    'YOUR_CLOUD_NAME', // <--- Cloud Name
    'YOUR_UNSIGNED_PRESET', // <--- ชื่อ Upload Preset (ต้องเป็น Unsigned)
    cache: false,
  );

  // ------------------------------------
  // Helper function สำหรับเลือกและอัปโหลดรูป
  // ------------------------------------
  Future<String?> _uploadAndGetUrl(File? file, String folderName) async {
    if (file == null) return null;

    try {
      CloudinaryResponse response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          file.path,
          resourceType: CloudinaryResourceType.Image,
          folder: folderName, // เช่น 'rider_images' หรือ 'vehicle_images'
        ),
      );
      return response.secureUrl; // ส่ง URL กลับไป
    } catch (e) {
      // โชว์ error ให้ผู้ใช้เห็น
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('อัปโหลดรูปภาพ $folderName ล้มเหลว: $e')),
      );
      return null;
    }
  }

  // เลือกรูปผู้ขับ
  Future<void> pickRiderImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _tempRiderImageFile = File(pickedFile.path);
      });
    }
  }

  // เลือกรูปยานพาหนะ
  Future<void> pickVehicleImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _tempVehicleImageFile = File(pickedFile.path);
      });
    }
  }

  void register() async {
    if (_formKey.currentState!.validate()) {
      // 1. ตรวจสอบว่ามีรูปภาพถูกเลือกหรือไม่
      if (_tempRiderImageFile == null || _tempVehicleImageFile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('กรุณาเลือกรูปผู้ขับและรูปยานพาหนะให้ครบ'),
          ),
        );
        return;
      }

      // 2. อัปโหลดรูปภาพไปยัง Cloudinary
      // (ควรแสดง Loading indicator ที่นี่ก่อนทำขั้นตอนต่อไป)

      String? riderUrl = await _uploadAndGetUrl(
        _tempRiderImageFile,
        'rider_profile_images', // โฟลเดอร์บน Cloudinary
      );

      String? vehicleUrl = await _uploadAndGetUrl(
        _tempVehicleImageFile,
        'rider_vehicle_images', // โฟลเดอร์บน Cloudinary
      );

      // 3. ตรวจสอบการอัปโหลด
      if (riderUrl == null || vehicleUrl == null) {
        // หากอัปโหลดล้มเหลวอย่างใดอย่างหนึ่ง ให้หยุด
        return;
      }

      // 4. บันทึก URL ที่ได้ลงในตัวแปร State
      setState(() {
        _riderImageUrl = riderUrl;
        _vehicleImageUrl = vehicleUrl;
      });

      // 5. บันทึกข้อมูลลง Firestore (ใช้ URL แทน File)
      var db = FirebaseFirestore.instance;
      var data = {
        'Role': widget.role,
        'Name': _nameController.text,
        'Phone': _phoneController.text,
        // ***ในแอปจริง ควรใช้ Firebase Auth สร้าง User และเก็บ UID
        // ไม่ควรเก็บ Password ใน Firestore ตรงๆ***
        'Password': _passwordController.text,
        'VehicleNumber': _vehicleNumberController.text,
        'RiderImageUrl': _riderImageUrl, // ใช้ URL
        'VehicleImageUrl': _vehicleImageUrl, // ใช้ URL
        'Status': 'Pending', // สถานะเริ่มต้น
        'createdAt': FieldValue.serverTimestamp(),
      };

      await db.collection('riders').doc().set(data);

      // แสดงข้อความสำเร็จ
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ลงทะเบียน Rider สำเร็จแล้ว')),
      );

      // (TODO: นำทางผู้ใช้ไปยังหน้าถัดไป)
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
                // ... (ส่วน TextFormField เหมือนเดิม) ...
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
                // ***แสดงรูปจาก File ชั่วคราว***
                if (_tempRiderImageFile != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Image.file(_tempRiderImageFile!, height: 100),
                  ),

                const SizedBox(height: 16),

                // เลือกรูปยานพาหนะ
                ElevatedButton.icon(
                  onPressed: pickVehicleImage,
                  icon: const Icon(Icons.directions_bike),
                  label: const Text('เลือกรูปยานพาหนะ'),
                ),
                // ***แสดงรูปจาก File ชั่วคราว***
                if (_tempVehicleImageFile != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Image.file(_tempVehicleImageFile!, height: 100),
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
