import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlong2;
import 'package:image_picker/image_picker.dart';

// +++ 1. เพิ่ม Import +++
import 'package:cloudinary_public/cloudinary_public.dart';

class CreateShipmentPage extends StatefulWidget {
  final String uid;

  const CreateShipmentPage({super.key, required this.uid});

  @override
  State<CreateShipmentPage> createState() => _CreateShipmentPageState();
}

class _CreateShipmentPageState extends State<CreateShipmentPage> {
  final MapController _mapController = MapController();
  final _formKey = GlobalKey<FormState>();
  String _senderName = '';

  final TextEditingController _senderPhoneController = TextEditingController();
  List<String> _senderSavedAddresses = [];
  String? _selectedSenderAddress;

  final TextEditingController _receiverPhoneController =
      TextEditingController();
  final TextEditingController _receiverAddressController =
      TextEditingController();
  final TextEditingController _receiverStateCountryController =
      TextEditingController();
  final TextEditingController _receiverOtherController =
      TextEditingController();

  List<Map<String, dynamic>> _receiverSavedAddresses = [];
  String? _foundReceiverId;
  String? _selectedReceiverDisplayString;

  final TextEditingController _packageQuantityController =
      TextEditingController();
  final TextEditingController _packageDetailsController =
      TextEditingController();
  final TextEditingController _packageNotesController = TextEditingController();

  final ImagePicker _picker = ImagePicker();

  // +++ 2. แก้ไข/เพิ่ม ตัวแปรสำหรับรูปภาพ +++
  File? _pickedImage;
  bool _isUploadFinished = false;
  bool _isSubmitting = false;
  bool _isUploadingImage = false;
  String? _uploadedImageUrl;

  // +++ 2.1 ใส่ Config ของคุณที่นี่ +++
  final String _cloudinaryCloudName = "dpar6zwks";
  final String _cloudinaryUploadPreset = "delivery";
  // +++++++++++++++++++++++++++++++++++++

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadAllReceivers();
  }

  Future<void> _loadUserData() async {
    // (โค้ดส่วนนี้เหมือนเดิม)
    try {
      final db = FirebaseFirestore.instance;
      final senderDoc = await db.collection('User').doc(widget.uid).get();
      if (senderDoc.exists) {
        final senderData = senderDoc.data()!;

        final firstName = senderData['First_name'] ?? '';
        final lastName = senderData['Last_name'] ?? '';
        final fullName = "$firstName $lastName".trim();

        setState(() {
          _senderName = fullName;
          _senderPhoneController.text = senderData['Phone'] ?? '';
          _senderSavedAddresses = List<String>.from(senderData['addr'] ?? []);
          if (_senderSavedAddresses.isNotEmpty) {
            _selectedSenderAddress = _senderSavedAddresses.first;
          }
        });
      }
    } catch (e) {
      debugPrint("❌ Load sender error: $e");
    }
  }

  Future<void> _loadAllReceivers() async {
    // (โค้ดส่วนนี้เหมือนเดิม)
    try {
      final db = FirebaseFirestore.instance;
      final querySnapshot = await db.collection('User').get();

      List<Map<String, dynamic>> tempAllAddresses = [];

      for (var doc in querySnapshot.docs) {
        final userData = doc.data();
        final firstName = userData['First_name'] ?? '';
        final lastName = userData['Last_name'] ?? '';
        final fullName = "$firstName $lastName".trim();
        final addresses = List<String>.from(userData['addr'] ?? []);
        final phone = userData['Phone'] ?? '';

        for (var address in addresses) {
          if (address.isNotEmpty) {
            tempAllAddresses.add({
              'id': doc.id,
              'name': fullName,
              'address': address,
              'phone': phone,
              'displayString': "$fullName\n$address",
            });
          }
        }
      }

      setState(() {
        _receiverSavedAddresses = tempAllAddresses;
      });
    } catch (e) {
      debugPrint("❌ โหลดข้อมูลผู้รับทั้งหมดผิดพลาด: $e");
    }
  }

  // +++ 3. แก้ไข: _pickImageFromCamera (ให้อัปโหลดอัตโนมัติ) +++
  Future<void> _pickImageFromCamera() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.camera);
    if (pickedFile == null) return; // ผู้ใช้กดยกเลิก

    setState(() {
      _pickedImage = File(pickedFile.path);
      _isUploadFinished = false;
      _uploadedImageUrl = null;
      _isUploadingImage = true; // <-- เริ่มหมุนทันที
    });

    // เรียกอัปโหลดอัตโนมัติ
    await _uploadImageToCloudinary();
  }

  // +++ 4. แก้ไข: _uploadImageToCloudinary (ลบ setSate ตอนเริ่ม) +++
  Future<void> _uploadImageToCloudinary() async {
    if (_pickedImage == null) {
      setState(() => _isUploadingImage = false); // หยุดหมุนถ้ามีอะไรผิดพลาด
      return;
    }

    // (ลบ setState(_isUploadingImage = true) จากตรงนี้ เพราะ _pickImage จัดการแล้ว)

    try {
      final cloudinary = CloudinaryPublic(
        _cloudinaryCloudName,
        _cloudinaryUploadPreset,
        cache: false,
      );

      CloudinaryResponse response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          _pickedImage!.path,
          resourceType: CloudinaryResourceType.Image,
        ),
      );

      setState(() {
        _uploadedImageUrl = response.secureUrl;
        _isUploadFinished = true;
        _isUploadingImage = false; // <-- หยุดหมุน (สำเร็จ)
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ อัปโหลดรูปสำเร็จ"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _isUploadingImage = false; // <-- หยุดหมุน (ล้มเหลว)
      });
      debugPrint("❌ อัปโหลด Cloudinary ผิดพลาด: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("เกิดข้อผิดพลาดในการอัปโหลดรูป: $e")),
      );
    }
  }

  // +++ 5. _onConfirmShipment (เหมือนเดิม) +++
  Future<void> _onConfirmShipment() async {
    if (!_formKey.currentState!.validate()) return;

    if (_uploadedImageUrl == null || _uploadedImageUrl!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("กรุณาถ่ายรูป (และรออัปโหลด) ให้เสร็จก่อน"),
        ),
      );
      return;
    }

    if (_foundReceiverId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("⚠️ กรุณาเลือกที่อยู่ผู้รับจากรายการก่อน"),
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final shipmentData = {
        'senderId': widget.uid,
        'senderName': _senderName,
        'senderPhone': _senderPhoneController.text,
        'senderAddress': _selectedSenderAddress,

        'receiverId': _foundReceiverId,
        'receiverName': _receiverAddressController.text,
        'receiverAddress': _receiverStateCountryController.text,

        'receiverOther': _receiverOtherController.text,
        'quantity': _packageQuantityController.text,
        'details': _packageDetailsController.text,
        'notes': _packageNotesController.text,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending',
        'imageUrl': _uploadedImageUrl, // <-- บันทึก URL
      };

      await FirebaseFirestore.instance.collection('shipment').add(shipmentData);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("✅ ส่งข้อมูลสำเร็จ")));

      Navigator.pop(context);
    } catch (e) {
      debugPrint("❌ เกิดข้อผิดพลาดในการบันทึกข้อมูล: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("เกิดข้อผิดพลาดในการส่งข้อมูล")),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  latlong2.LatLng? _parseLatLng(String addressString) {
    // (ฟังก์ชันนี้เหมือนเดิม)
    final parts = addressString.split("\n");
    if (parts.length >= 2) {
      final addressPart = parts.sublist(1).join("\n").trim();
      final latLngParts = addressPart.split(',');
      if (latLngParts.length == 2) {
        final lat = double.tryParse(latLngParts[0].trim()) ?? 16.246373;
        final lng = double.tryParse(latLngParts[1].trim()) ?? 103.251827;
        return latlong2.LatLng(lat, lng);
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        // (เหมือนเดิม)
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
                // (ส่วนผู้ส่งเหมือนเดิม)
                const Text(
                  "รายละเอียดผู้ส่ง",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _senderPhoneController,
                  decoration: const InputDecoration(labelText: "เบอร์โทรศัพท์"),
                  keyboardType: TextInputType.phone,
                  validator: (value) => (value == null || value.isEmpty)
                      ? 'กรุณากรอกเบอร์โทร'
                      : null,
                ),
                const SizedBox(height: 16),
                ..._senderSavedAddresses.map((address) {
                  final isSelected = (_selectedSenderAddress == address);
                  return _buildAddressCard(
                    address: address,
                    isSelected: isSelected,
                    onTap: () {
                      setState(() => _selectedSenderAddress = address);
                    },
                  );
                }).toList(),
                const SizedBox(height: 24),

                // (ส่วนผู้รับเหมือนเดิม... จนถึง ...รายการที่อยู่)
                const Text(
                  "รายละเอียดผู้รับ",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                TextFormField(
                  controller: _receiverPhoneController,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: "เบอร์โทรผู้รับ (เลือกจากรายการด้านล่าง)",
                  ),
                  keyboardType: TextInputType.phone,
                ),

                const SizedBox(height: 8),
                TextFormField(
                  controller: _receiverAddressController,
                  decoration: const InputDecoration(labelText: "ชื่อผู้รับ"),
                  validator: (value) => (value == null || value.isEmpty)
                      ? 'กรุณากรอกชื่อผู้รับ'
                      : null,
                ),
                TextFormField(
                  controller: _receiverStateCountryController,
                  decoration: const InputDecoration(
                    labelText: "ที่อยู่ (พิกัด)",
                  ),
                  validator: (value) => (value == null || value.isEmpty)
                      ? 'กรุณากรอกที่อยู่'
                      : null,
                ),
                TextFormField(
                  controller: _receiverOtherController,
                  decoration: const InputDecoration(
                    labelText: "คนอื่น (ไม่จำเป็น)",
                  ),
                ),
                const SizedBox(height: 8),

                ..._receiverSavedAddresses.map((addressData) {
                  final String addressString = addressData['displayString'];
                  final isSelected =
                      (_selectedReceiverDisplayString == addressString);
                  final latlong2.LatLng? position = _parseLatLng(addressString);

                  return Column(
                    children: [
                      InkWell(
                        onTap: () {
                          // (onTap เหมือนเดิม)
                          setState(() {
                            final bool wasSelected =
                                (_selectedReceiverDisplayString ==
                                addressString);

                            if (wasSelected) {
                              _selectedReceiverDisplayString = null;
                              _foundReceiverId = null;
                              _receiverPhoneController.clear();
                              _receiverAddressController.clear();
                              _receiverStateCountryController.clear();
                            } else {
                              _selectedReceiverDisplayString = addressString;
                              _foundReceiverId = addressData['id'];
                              _receiverPhoneController.text =
                                  addressData['phone'];
                              _receiverAddressController.text =
                                  addressData['name'];
                              _receiverStateCountryController.text =
                                  addressData['address'];
                            }
                          });
                        },
                        child: Container(
                          // (Container นี้เหมือนเดิม)
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.blue.shade50
                                : Colors.grey.shade100,
                            border: Border.all(
                              color: isSelected
                                  ? Colors.blue.shade700
                                  : Colors.grey.shade300,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.add_location_alt_outlined,
                                color: Colors.blue.shade700,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  addressString,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                              Icon(
                                isSelected
                                    ? Icons.keyboard_arrow_up
                                    : Icons.keyboard_arrow_down,
                              ),
                            ],
                          ),
                        ),
                      ),

                      // (ส่วนแผนที่ เหมือนเดิม)
                      if (isSelected && position != null)
                        SizedBox(
                          height: 200,
                          child: ClipRRect(
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(8),
                              bottomRight: Radius.circular(8),
                            ),
                            child: FlutterMap(
                              mapController: _mapController,
                              options: MapOptions(
                                onMapReady: () {
                                  _mapController.move(position, 16.0);
                                },
                                interactionOptions: const InteractionOptions(
                                  flags: InteractiveFlag.none,
                                ),
                              ),
                              children: [
                                TileLayer(
                                  urlTemplate:
                                      "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                                  subdomains: ['a', 'b', 'c'],
                                  retinaMode: true,
                                ),
                                MarkerLayer(
                                  markers: [
                                    Marker(
                                      width: 80.0,
                                      height: 80.0,
                                      point: position,
                                      child: Container(
                                        child: Icon(
                                          Icons.location_pin,
                                          color: Colors.red,
                                          size: 40.0,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  );
                }).toList(),

                // (ส่วนรายละเอียดพัสดุ เหมือนเดิม)
                const SizedBox(height: 24),
                const Text(
                  "รายละเอียดพัสดุ",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _packageQuantityController,
                  decoration: const InputDecoration(labelText: "จำนวน __ ชิ้น"),
                  keyboardType: TextInputType.number,
                  validator: (value) => (value == null || value.isEmpty)
                      ? 'กรุณาระบุจำนวน'
                      : null,
                ),
                TextFormField(
                  controller: _packageDetailsController,
                  decoration: const InputDecoration(
                    labelText: "รายละเอียดสินค้า:",
                  ),
                  validator: (value) => (value == null || value.isEmpty)
                      ? 'กรุณาระบุรายละเอียด'
                      : null,
                ),
                TextFormField(
                  controller: _packageNotesController,
                  decoration: const InputDecoration(
                    labelText: "หมายเหตุเพิ่มเติม:",
                  ),
                ),
                const SizedBox(height: 16),

                // +++ 6. แก้ไข: UI ปุ่ม (เหลือปุ่มเดียว) +++
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 1. ปุ่มเดียว (ถ่ายรูป + แสดงสถานะ)
                    OutlinedButton.icon(
                      // ปิดปุ่มถ้า: กำลังส่งฟอร์ม หรือ กำลังอัปโหลดรูป
                      onPressed: _isSubmitting || _isUploadingImage
                          ? null
                          : _pickImageFromCamera,

                      icon: _isUploadingImage
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(
                              _isUploadFinished
                                  ? Icons
                                        .check_circle // อัปเสร็จแล้ว
                                  : Icons.camera_alt_outlined, // ยังไม่ได้อัป
                            ),

                      label: Text(
                        _isUploadingImage
                            ? "กำลังอัปโหลด..."
                            : (_isUploadFinished
                                  ? "อัปโหลดเสร็จสิ้น" // <-- ใช้คำที่คุณต้องการ
                                  : "ถ่ายรูปพัสดุ"), // <-- ใช้คำที่คุณต้องการ
                      ),

                      style: OutlinedButton.styleFrom(
                        foregroundColor: _isUploadFinished
                            ? Colors.green
                            : null,
                      ),
                    ),

                    // (ลบปุ่มที่ 2 ทิ้ง)
                  ],
                ),

                // +++ สิ้นสุดส่วนแก้ไข +++
                const SizedBox(height: 16),

                // (ส่วนแสดงรูปที่ถ่าย เหมือนเดิม)
                if (_pickedImage != null)
                  Center(
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                      ),
                      child: Image.file(_pickedImage!, fit: BoxFit.cover),
                    ),
                  ),
                const SizedBox(height: 16),

                // (ปุ่มยืนยัน เหมือนเดิม)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _onConfirmShipment,
                    child: _isSubmitting
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("ยืนยันส่งของ"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddressCard({
    // (ฟังก์ชันนี้เหมือนเดิม)
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
        child: Text(address),
      ),
    );
  }

  @override
  void dispose() {
    // (ส่วนนี้เหมือนเดิม)
    _senderPhoneController.dispose();
    _receiverPhoneController.dispose();
    _receiverAddressController.dispose();
    _receiverStateCountryController.dispose();
    _receiverOtherController.dispose();
    _packageQuantityController.dispose();
    _packageDetailsController.dispose();
    _packageNotesController.dispose();
    _mapController.dispose();
    super.dispose();
  }
}
