import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class EditRiderProfilePage extends StatefulWidget {
  const EditRiderProfilePage({super.key});

  @override
  State<EditRiderProfilePage> createState() => _EditRiderProfilePageState();
}

class _EditRiderProfilePageState extends State<EditRiderProfilePage> {
  final _formKey = GlobalKey<FormState>();

  // --- (Backend) TODO: ดึงข้อมูล Rider จริงมาใส่ ---
  // 1. Name
  final TextEditingController _nameController =
      TextEditingController(text: "Tun Tung Tung");

  // 2. Phone
  final TextEditingController _phoneController =
      TextEditingController(text: "081-234-5678");

  // 3. Vehicle Number
  final TextEditingController _vehicleNumberController =
      TextEditingController(text: "กท 1234");

  // 4. Rider Image
  String _existingRiderImageUrl =
      "https://static.wikia.nocookie.net/minecraft/images/f/fe/Villager_face.png/revision/latest";
  File? _newRiderImageFile;

  // 5. Vehicle Image
  String _existingVehicleImageUrl =
      "https://via.placeholder.com/150/0000FF/FFFFFF?Text=Vehicle"; // รูป Placeholder
  File? _newVehicleImageFile;

  final ImagePicker _picker = ImagePicker();

  // 6. Password
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  // ------------------------------------------

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _vehicleNumberController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // --- ฟังก์ชันสำหรับเลือกรูป ---
  Future<void> _pickImage(bool isRiderImage) async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        if (isRiderImage) {
          _newRiderImageFile = File(pickedFile.path);
        } else {
          _newVehicleImageFile = File(pickedFile.path);
        }
      });
    }
  }

  // --- ฟังก์ชันสำหรับบันทึก ---
  void _saveProfile() {
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
                // (Backend) TODO:
                // 1. ตรวจสอบ/เปลี่ยน Password (ถ้ามีการกรอก)
                // 2. ตรวจสอบ/เปลี่ยน Phone (ถ้ามีการเปลี่ยน)
                // 3. อัปโหลด _newRiderImageFile (ถ้ามี) ไป Storage
                // 4. อัปโหลด _newVehicleImageFile (ถ้ามี) ไป Storage
                // 5. อัปเดต Firestore (Name, Phone, VehicleNumber, URLs)

                print("บันทึกข้อมูล Rider...");
                print("ชื่อ: ${_nameController.text}");
                print("เบอร์โทรใหม่: ${_phoneController.text}");
                print("ทะเบียนรถใหม่: ${_vehicleNumberController.text}");
                print("รูป Rider ใหม่: ${_newRiderImageFile?.path ?? 'ไม่ได้เปลี่ยน'}");
                print("รูป Vehicle ใหม่: ${_newVehicleImageFile?.path ?? 'ไม่ได้เปลี่ยน'}");

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

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF005FFF);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          "แก้ไขโปรไฟล์ Rider",
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
                // --- 1. รูป Rider ---
                Center(child: _buildProfileImagePicker(isRiderImage: true)),
                const SizedBox(height: 24),

                _buildSectionTitle("ข้อมูล Rider"),

                // --- 2. ชื่อ ---
                TextFormField(
                  controller: _nameController,
                  decoration: _inputDecoration(labelText: 'ชื่อ-นามสกุล'),
                  validator: (value) =>
                      (value == null || value.isEmpty) ? 'กรุณากรอกชื่อ' : null,
                ),
                const SizedBox(height: 16),

                // --- 3. เบอร์โทร ---
                TextFormField(
                  controller: _phoneController,
                  decoration: _inputDecoration(labelText: 'เบอร์โทรศัพท์'),
                  keyboardType: TextInputType.phone,
                  validator: (value) =>
                      (value == null || value.isEmpty) ? 'กรุณากรอกเบอร์โทร' : null,
                ),
                const SizedBox(height: 24),

                _buildSectionTitle("ข้อมูลยานพาหนะ"),

                // --- 4. ทะเบียนรถ ---
                TextFormField(
                  controller: _vehicleNumberController,
                  decoration: _inputDecoration(labelText: 'ทะเบียนรถ'),
                  validator: (value) =>
                      (value == null || value.isEmpty) ? 'กรุณากรอกทะเบียนรถ' : null,
                ),
                const SizedBox(height: 16),

                // --- 5. รูปยานพาหนะ ---
                _buildVehicleImagePicker(),
                const SizedBox(height: 24),


                // --- 6. รหัสผ่าน ---
                _buildPasswordSection(),
                const SizedBox(height: 32),

                // --- 7. ปุ่มบันทึก ---
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

  // --- Helper Widgets ---

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  InputDecoration _inputDecoration({required String labelText}) {
    return InputDecoration(
      labelText: labelText,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  // ตัวเลือกรูป Rider
  Widget _buildProfileImagePicker({required bool isRiderImage}) {
    ImageProvider backgroundImage;
    File? newImage = isRiderImage ? _newRiderImageFile : _newVehicleImageFile;
    String existingImage = isRiderImage ? _existingRiderImageUrl : _existingVehicleImageUrl;

    backgroundImage = (newImage != null)
        ? FileImage(newImage)
        : NetworkImage(existingImage);

    return GestureDetector(
      onTap: () => _pickImage(isRiderImage),
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

   // ตัวเลือกรูป Vehicle (ทำให้เป็นสี่เหลี่ยม)
  Widget _buildVehicleImagePicker() {
    ImageProvider backgroundImage;
    backgroundImage = (_newVehicleImageFile != null)
        ? FileImage(_newVehicleImageFile!)
        : NetworkImage(_existingVehicleImageUrl);

    return GestureDetector(
      onTap: () => _pickImage(false), // isRiderImage = false
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          Container(
            height: 150,
            width: double.infinity, // เต็มความกว้าง
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
              image: DecorationImage(
                image: backgroundImage,
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.all(8), // ขยับไอคอนเข้ามาหน่อย
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


  Widget _buildPasswordSection() {
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