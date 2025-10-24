import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

// --- 1. Import หน้าแผนที่ และ latlong2 ---
import 'package:delivery/page/GPSandMapPage.dart'; // (เช็ค Path ให้ถูก)
import 'package:latlong2/latlong.dart' as latlong2; // (ใช้ as latlong2 เพื่อกันชื่อชน)
// import 'package:cloud_firestore/cloud_firestore.dart'; // (Backend)

// (ข้อมูลจำลองสำหรับ Class ที่อยู่ - Backend ควรใช้ Model จริง)
class UserAddress {
  final String id;
  final String label;
  UserAddress({required this.id, required this.label});
}
// ---------------------------------

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();

  // (Controllers and variables)
  String _existingImageUrl =
      "https://static.wikia.nocookie.net/minecraft/images/f/fe/Villager_face.png/revision/latest";
  File? _newImageFile;
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _firstNameController =
      TextEditingController(text: "Tun");
  final TextEditingController _lastNameController =
      TextEditingController(text: "Tung Tung");
  final TextEditingController _phoneController =
      TextEditingController(text: "081-234-5678");
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  
  // (State) ทำให้ List นี้เปลี่ยนแปลงได้
  final List<UserAddress> _userAddresses = [
    UserAddress(id: "1", label: "ที่อยู่บ้าน"),
    UserAddress(id: "2", label: "ที่ทำงาน"),
  ];

  @override
  void dispose() {
    // ... (dispose controllers)
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    // ... (logic pickImage)
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _newImageFile = File(pickedFile.path);
      });
    }
  }

  void _saveProfile() {
    // ... (logic saveProfile)
    if (_formKey.currentState!.validate()) {
      Get.dialog(
        AlertDialog(
          title: const Text('ยืนยันการแก้ไข'),
          content: const Text('คุณแน่ใจหรือไม่ว่าต้องการบันทึกการเปลี่ยนแปลงนี้?'),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('ยกเลิก'),
            ),
            ElevatedButton(
              onPressed: () {
                // (Backend) TODO: Logic บันทึกข้อมูล
                Get.back(); // ปิด Dialog
                Get.back(); // กลับหน้า Home
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF005FFF),
              ),
              child: const Text('ยืนยัน', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }
  }

  // --- 2. ฟังก์ชันสำหรับเปิดหน้าแผนที่ ---
  void _navigateAndAddAddress() {
    // ใช้ Get.to เพื่อไปหน้า GPSandMapPage
    Get.to(() => GPSandMapPage(
          onPick: (latlong2.LatLng pos) {
            // --- นี่คือสิ่งที่จะเกิดขึ้นเมื่อ User "เลือกตำแหน่งนี้" ---
            
            // 1. (Frontend) เมื่อได้พิกัดแล้ว, ให้ถาม "ชื่อ" ของสถานที่
            // (เราส่ง 'pos' ที่ได้จากแผนที่ ไปยังฟังก์ชันถัดไป)
            _showAddAddressLabelDialog(pos);
          },
        ));
  }

  // --- 3. ฟังก์ชันสำหรับแสดง Dialog ถามชื่อสถานที่ ---
  void _showAddAddressLabelDialog(latlong2.LatLng pos) {
    final TextEditingController labelController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: const Text("เพิ่มที่อยู่ใหม่"),
        content: TextField(
          controller: labelController,
          autofocus: true,
          decoration: const InputDecoration(
              labelText: "ชื่อสถานที่ (เช่น บ้าน, คอนโด)"),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(), // ปิด Dialog
            child: const Text("ยกเลิก"),
          ),
          ElevatedButton(
            onPressed: () {
              String label = labelController.text.trim();
              if (label.isNotEmpty) {
                
                // (Backend) TODO:
                // 1. สร้าง GeoPoint
                //    GeoPoint newLocation = GeoPoint(pos.latitude, pos.longitude);
                // 2. (สำคัญ) บันทึก newLocation และ label นี้ลงใน
                //    FirebaseFirestore (อัปเดต Array 'addresses' ของ User)

                // (Frontend) อัปเดต UI ชั่วคราว (เพิ่มใน List)
                setState(() {
                  _userAddresses.add(
                    UserAddress(id: DateTime.now().toString(), label: label),
                  );
                });

                Get.back(); // ปิด Dialog
              }
            },
            child: const Text("บันทึก"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF005FFF);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        // ... (AppBar)
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          "แก้ไขโปรไฟล์",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // (โค้ด UI ส่วนที่เหลือทั้งหมดเหมือนเดิม)
                Center(child: _buildProfileImagePicker()),
                const SizedBox(height: 24),
                _buildSectionTitle("ข้อมูลส่วนตัว"),
                TextFormField(
                  controller: _firstNameController,
                  decoration: _inputDecoration(labelText: 'ชื่อจริง'),
                  validator: (value) =>
                      (value == null || value.isEmpty) ? 'กรุณากรอกชื่อ' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _lastNameController,
                  decoration: _inputDecoration(labelText: 'นามสกุล'),
                  validator: (value) =>
                      (value == null || value.isEmpty) ? 'กรุณากรอกนามสกุล' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  decoration: _inputDecoration(labelText: 'เบอร์โทรศัพท์'),
                  keyboardType: TextInputType.phone,
                  validator: (value) =>
                      (value == null || value.isEmpty) ? 'กรุณากรอกเบอร์โทร' : null,
                ),
                const SizedBox(height: 24),
                
                _buildSectionTitle("ที่อยู่ที่บันทึกไว้"),
                _buildAddressSection(), // <-- (แก้ไขฟังก์ชันนี้)
                
                const SizedBox(height: 24),
                _buildPasswordSection(),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'บันทึกการเปลี่ยนแปลง',
                      style: TextStyle(color: Colors.white, fontSize: 16),
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

  // --- (Helper Widgets) ---

  Widget _buildSectionTitle(String title) {
    // ... (เหมือนเดิม)
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  InputDecoration _inputDecoration({required String labelText}) {
    // ... (เหมือนเดิม)
    return InputDecoration(
      labelText: labelText,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  Widget _buildProfileImagePicker() {
    // ... (เหมือนเดิม)
    ImageProvider backgroundImage = (_newImageFile != null)
        ? FileImage(_newImageFile!)
        : NetworkImage(_existingImageUrl);

    return GestureDetector(
      onTap: _pickImage,
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          CircleAvatar(
            radius: 60,
            backgroundColor: Colors.grey[200],
            backgroundImage: backgroundImage,
          ),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(1, 1),
                ),
              ],
            ),
            child: const Icon(
              Icons.edit,
              color: Color(0xFF005FFF),
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  // --- 4. แก้ไขฟังก์ชันนี้ ---
  Widget _buildAddressSection() {
    return Column(
      children: [
        // (Backend) วนลูปที่อยู่จริง
        ..._userAddresses.map((address) {
          return Card(
            elevation: 0,
            color: Colors.grey[100],
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: const Icon(Icons.home_outlined),
              title: Text(address.label),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                    onPressed: () {
                      // (Backend) TODO: ไปหน้าแก้ที่อยู่
                      // Get.to(() => GPSandMapPage(addressToEdit: address));
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () {
                      // (Backend) TODO: ลบที่อยู่
                    },
                  ),
                ],
              ),
            ),
          );
        }).toList(),

        // ปุ่มเพิ่มที่อยู่
        OutlinedButton.icon(
          onPressed: _navigateAndAddAddress, // <-- 5. เปลี่ยนมาเรียกฟังก์ชันใหม่
          icon: const Icon(Icons.add_location_alt_outlined),
          label: const Text("เพิ่มที่อยู่ใหม่"),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF005FFF),
            side: const BorderSide(color: Color(0xFF005FFF)),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordSection() {
    // ... (เหมือนเดิม)
    return ExpansionTile(
      title: _buildSectionTitle("เปลี่ยนรหัสผ่าน"),
      subtitle: const Text("กรอกเฉพาะในกรณีที่ต้องการเปลี่ยน"),
      childrenPadding: const EdgeInsets.symmetric(vertical: 16),
      children: [
        TextFormField(
          controller: _currentPasswordController,
          decoration: _inputDecoration(labelText: 'รหัสผ่านปัจจุบัน'),
          obscureText: true,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _newPasswordController,
          decoration: _inputDecoration(labelText: 'รหัสผ่านใหม่'),
          obscureText: true,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _confirmPasswordController,
          decoration: _inputDecoration(labelText: 'ยืนยันรหัสผ่านใหม่'),
          obscureText: true,
          validator: (value) {
            if (_newPasswordController.text.isNotEmpty &&
                value != _newPasswordController.text) {
              return 'รหัสผ่านใหม่ไม่ตรงกัน';
            }
            return null;
          },
        ),
      ],
    );
  }
}