import 'dart:developer';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class CreateShipmentPage extends StatefulWidget {
  final String uid;

  const CreateShipmentPage({super.key, required this.uid});

  @override
  State<CreateShipmentPage> createState() => _CreateShipmentPageState();
}

class _CreateShipmentPageState extends State<CreateShipmentPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _senderPhoneController = TextEditingController();
  List<String> _senderSavedAddresses = [];
  String? _selectedSenderAddress;

  final TextEditingController _receiverAddressController =
      TextEditingController();
  final TextEditingController _receiverStateCountryController =
      TextEditingController();
  final TextEditingController _receiverOtherController =
      TextEditingController();
  List<String> _receiverSavedAddresses = [];

  final TextEditingController _packageQuantityController =
      TextEditingController();
  final TextEditingController _packageDetailsController =
      TextEditingController();
  final TextEditingController _packageNotesController = TextEditingController();

  bool _isUploadFinished = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadUserData(); // ดึงข้อมูลผู้ใช้จาก Firestore
  }

  Future<void> _loadUserData() async {
    try {
      final db = FirebaseFirestore.instance;
      final userRef = db.collection('User');
      // --- ดึงข้อมูลของผู้ส่ง (เจ้าของ uid นี้) ---
      final senderDoc = await userRef.doc(widget.uid).get();
      if (senderDoc.exists) {
        final senderData = senderDoc.data()!;
        setState(() {
          _senderPhoneController.text = senderData['Phone'] ?? '';
          _senderSavedAddresses = List<String>.from(senderData['addr'] ?? []);
          if (_senderSavedAddresses.isNotEmpty) {
            _selectedSenderAddress = _senderSavedAddresses.first;
          }
        });
      }
      // --- ดึงข้อมูลของผู้ใช้คนอื่นทั้งหมด (ยกเว้นตัวเอง) ---
      final otherUsersQuery = await userRef
          .where(FieldPath.documentId, isNotEqualTo: widget.uid)
          .get();
      for (var doc in otherUsersQuery.docs) {
        final userData = doc.data();
        if (userData.containsKey('addr')) {
          _receiverSavedAddresses = []; // เคลียร์ list ก่อนโหลดใหม่
          for (var doc in otherUsersQuery.docs) {
            var data = doc.data();
            final address = data['addr'] ?? '';
            final firstName = data['First_name'] ?? '';
            final lastName = data['Last_name'] ?? '';
            final fullName = "$firstName $lastName".trim();
            _receiverSavedAddresses.add("$fullName \n $address");
          }
          setState(() {});
        }
      }

      debugPrint("✅ โหลดข้อมูลผู้ส่งและผู้รับเสร็จสิ้น");
    } catch (e) {
      debugPrint("❌ โหลดข้อมูลจาก Firestore ผิดพลาด: $e");
    }
  }

  final ImagePicker _picker = ImagePicker();
  File? _image;

  @override
  void dispose() {
    _senderPhoneController.dispose();
    _receiverAddressController.dispose();
    _receiverStateCountryController.dispose();
    _receiverOtherController.dispose();
    _packageQuantityController.dispose();
    _packageDetailsController.dispose();
    _packageNotesController.dispose();
    super.dispose();
  }

  Future<void> _onUploadImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _isUploadFinished = true;
      });
    }
  }

  Future<void> _onConfirmShipment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // (แนะนำ) ตรวจสอบว่ามีรูปภาพหรือยัง
    if (_image == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("กรุณาอัปโหลดรูปภาพพัสดุ")));
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      String? imageUrl;

      String fileExtension = path.extension(_image!.path);
      String fileName =
          '${DateTime.now().millisecondsSinceEpoch}$fileExtension';

      Reference storageRef = FirebaseStorage.instance
          .ref()
          .child('shipment_images')
          .child(fileName);

      UploadTask uploadTask = storageRef.putFile(_image!);

      TaskSnapshot taskSnapshot = await uploadTask;

      imageUrl = await taskSnapshot.ref.getDownloadURL();

      final shipmentData = {
        'senderPhone': _senderPhoneController.text.toString(),
        'senderAddress': _selectedSenderAddress,
        'receiverAddress': _receiverAddressController.text,
        'receiverStateCountry': _receiverStateCountryController.text,
        'receiverOther': _receiverOtherController.text,
        'quantity': _packageQuantityController.text,
        'details': _packageDetailsController.text.toString(),
        'notes': _packageNotesController.text.toString(),
        'timestamp': FieldValue.serverTimestamp(),
        'imageUrl': imageUrl,
      };
      await FirebaseFirestore.instance.collection('shipment').add(shipmentData);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("✅ ส่งข้อมูลสำเร็จ")));

      Navigator.pop(context); // กลับหน้าเดิม
    } catch (e) {
      debugPrint("❌ เกิดข้อผิดพลาดในการบันทึกข้อมูล: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("เกิดข้อผิดพลาดในการส่งข้อมูล ")),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "ส่งพัสดุ",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader(
                  Icons.location_history_rounded,
                  "รายละเอียดแหล่งกำเนิด",
                ),
                _buildSenderSection(),
                const SizedBox(height: 24),
                _buildSectionHeader(
                  Icons.location_on_outlined,
                  "Destination Details",
                ),
                _buildDestinationSection(),
                const SizedBox(height: 24),
                _buildSectionHeader(
                  Icons.inventory_2_outlined,
                  "รายละเอียดแพ็คเกจ",
                ),
                _buildPackageSection(),
                const SizedBox(height: 24),
                _buildActionButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ================= Helper Widgets =================

  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: Colors.blue.shade700, size: 24),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildSenderSection() {
    return Padding(
      padding: const EdgeInsets.only(left: 32.0, top: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _senderPhoneController,
            decoration: const InputDecoration(labelText: "เบอร์โทรศัพท์"),
            keyboardType: TextInputType.phone,
            validator: (value) =>
                (value == null || value.isEmpty) ? 'กรุณากรอกเบอร์โทร' : null,
          ),
          const SizedBox(height: 16),
          if (_senderSavedAddresses.isEmpty)
            const Text(
              "ไม่พบที่อยู่ในระบบ",
              style: TextStyle(color: Colors.grey),
            ),
          ..._senderSavedAddresses.map((address) {
            bool isSelected = (_selectedSenderAddress == address);
            return _buildAddressCard(
              address: address,
              isSelected: isSelected,
              onTap: () {
                setState(() {
                  _selectedSenderAddress = address;
                });
              },
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildDestinationSection() {
    return Padding(
      padding: const EdgeInsets.only(left: 32.0, top: 8.0),
      child: Column(
        children: [
          TextFormField(
            controller: _receiverAddressController,
            decoration: const InputDecoration(labelText: "ชื่อผู้รับ"),
            validator: (value) =>
                (value == null || value.isEmpty) ? 'กรุณากรอกที่อยู่' : null,
          ),
          TextFormField(
            controller: _receiverStateCountryController,
            decoration: const InputDecoration(labelText: "ที่อยู่"),
            validator: (value) =>
                (value == null || value.isEmpty) ? 'กรุณากรอกข้อมูล' : null,
          ),
          TextFormField(
            controller: _receiverOtherController,
            decoration: const InputDecoration(labelText: "คนอื่น (ไม่จำเป็น)"),
          ),
          const SizedBox(height: 16),
          ..._receiverSavedAddresses.map((address) {
            return _buildSavedDestinationCard(address: address);
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildPackageSection() {
    return Padding(
      padding: const EdgeInsets.only(left: 32.0, top: 8.0),
      child: Column(
        children: [
          TextFormField(
            controller: _packageQuantityController,
            decoration: const InputDecoration(labelText: "จำนวน __ ชิ้น"),
            keyboardType: TextInputType.number,
            validator: (value) =>
                (value == null || value.isEmpty) ? 'กรุณาระบุจำนวน' : null,
          ),
          TextFormField(
            controller: _packageDetailsController,
            decoration: const InputDecoration(labelText: "รายละเอียดสินค้า:"),
            validator: (value) =>
                (value == null || value.isEmpty) ? 'กรุณาระบุรายละเอียด' : null,
          ),
          TextFormField(
            controller: _packageNotesController,
            decoration: const InputDecoration(labelText: "หมายเหตุเพิ่มเติม:"),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            OutlinedButton.icon(
              // ปิดปุ่มอัปโหลดระหว่างที่กำลังส่งข้อมูล
              onPressed: _isSubmitting ? null : _onUploadImage,
              icon: const Icon(Icons.camera_alt_outlined),
              label: const Text("อัปโหลด"),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.blue.shade700,
                side: BorderSide(color: Colors.blue.shade700),
              ),
            ),
            const SizedBox(width: 16),
            OutlinedButton(
              onPressed: null,
              child: Text(
                _isUploadFinished ? "อัปโหลดเสร็จสิ้น" : "ยังไม่อัปโหลด",
                style: TextStyle(
                  color: _isUploadFinished ? Colors.green : Colors.grey,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _onConfirmShipment,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF005FFF),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            // เปลี่ยน Text เป็น Spinner (วงกลมหมุนๆ) เมื่อกำลังโหลด
            child: _isSubmitting
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
                  )
                : const Text(
                    "ยืนยันส่งของ",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddressCard({
    required String address,
    bool isSelected = false,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 8.0),
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.shade50 : Colors.grey.shade100,
          border: Border.all(
            color: isSelected ? Colors.blue.shade700 : Colors.grey.shade300,
          ),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Text(
          address,
          style: TextStyle(
            color: isSelected ? Colors.blue.shade900 : Colors.black,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildSavedDestinationCard({required String address}) {
    return InkWell(
      onTap: () {
        String rawText = address;
        if (rawText.contains("—")) {
          rawText = rawText.split("—")[1].trim();
        }

        List<String> parts = rawText.split(" ");
        if (parts.length > 2) {
          String stateCountry = parts.sublist(parts.length - 2).join(" ");
          String addressOnly = parts.sublist(0, parts.length - 2).join(" ");

          setState(() {
            _receiverAddressController.text = addressOnly;
            _receiverStateCountryController.text = stateCountry;
          });
        } else {
          // ถ้าแยกไม่ได้ ก็ใส่ทั้งหมดเป็น address เฉย ๆ
          setState(() {
            _receiverAddressController.text = rawText;
          });
        }

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("เลือกที่อยู่ผู้รับแล้ว ✅")));
      },
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 8.0),
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Row(
          children: [
            Icon(Icons.add_circle_outline, color: Colors.blue.shade700),
            const SizedBox(width: 8),
            Expanded(child: Text(address)),
            const SizedBox(width: 8),
            const Text(
              "แตะเพื่อเลือก",
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
