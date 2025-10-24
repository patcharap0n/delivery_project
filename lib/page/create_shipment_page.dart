import 'dart:developer';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

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
  late String senderName;
  String? _selectedSenderAddress;

  final TextEditingController _receiverPhoneController =
      TextEditingController();
  final TextEditingController _receiverAddressController =
      TextEditingController();
  final TextEditingController _receiverStateCountryController =
      TextEditingController();
  final TextEditingController _receiverOtherController =
      TextEditingController();

  List<String> _receiverSavedAddresses = [];

  // --- ADDED ---
  // ตัวแปรใหม่สำหรับเก็บ address string ("FullName \n lat,long") ของการ์ดที่ถูกเลือก
  String? _selectedAddressForMap;
  // --- END ADDED ---

  final TextEditingController _packageQuantityController =
      TextEditingController();
  final TextEditingController _packageDetailsController =
      TextEditingController();
  final TextEditingController _packageNotesController = TextEditingController();

  bool _isUploadFinished = false;
  bool _isSubmitting = false;
  bool _isSearchingReceiver = false;
  String? _foundReceiverId;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final db = FirebaseFirestore.instance;
      final userRef = db.collection('User');
      final senderDoc = await userRef.doc(widget.uid).get();
      if (senderDoc.exists) {
        final senderData = senderDoc.data()!;
        setState(() {
          _senderPhoneController.text = senderData['Phone'] ?? '';
          _senderSavedAddresses = List<String>.from(senderData['addr'] ?? []);
          senderName = senderData['First_name'] + senderData['Last_name'];
          if (_senderSavedAddresses.isNotEmpty) {
            _selectedSenderAddress = _senderSavedAddresses.first;
          }
        });
      }
    } catch (e) {}
  }

  Future<void> _searchReceiverByPhone() async {
    final phone = _receiverPhoneController.text.trim();
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("กรุณาป้อนเบอร์โทรศัพท์เพื่อค้นหา")),
      );
      return;
    }

    setState(() {
      _isSearchingReceiver = true;
      _receiverSavedAddresses = [];
      _receiverAddressController.clear();
      _receiverStateCountryController.clear();
      _foundReceiverId = null; // 2. เคลียร์ ID ผู้รับเก่าทุกครั้งที่ค้นหา
    });

    try {
      final db = FirebaseFirestore.instance;
      final querySnapshot = await db
          .collection('User')
          .where('Phone', isEqualTo: phone)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("ไม่พบผู้ใช้จากเบอร์โทรนี้")),
        );
        setState(() {
          _receiverSavedAddresses = [];
        });
      } else {
        // --- 3. นี่คือจุดที่คุณต้องใส่โค้ด (โค้ดของคุณ) ---
        final userDoc = querySnapshot.docs.first; // <-- เอา Doc
        final userData = userDoc.data(); // <-- เอา Data

        _foundReceiverId = userDoc.id; // <-- 4. เก็บ UID ของผู้รับ
        // --- จบส่วนของโค้ดที่คุณส่งมา ---

        final firstName = userData['First_name'] ?? '';
        final lastName = userData['Last_name'] ?? '';
        final fullName = "$firstName $lastName".trim();
        final addresses = List<String>.from(userData['addr'] ?? []);

        List<String> tempFoundAddresses = [];
        if (addresses.isNotEmpty) {
          for (var address in addresses) {
            if (address.isNotEmpty) {
              tempFoundAddresses.add("$fullName \n $address");
            }
          }
        }

        setState(() {
          _receiverSavedAddresses = tempFoundAddresses;

          // 5. (แนะนำ) กรอกข้อมูลช่องแรกให้เลย
          _receiverAddressController.text = fullName; // "ชื่อผู้รับ"
          _receiverStateCountryController.text = addresses.isNotEmpty
              ? addresses.first
              : ''; // "ที่อยู่"
        });

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("✅ พบข้อมูลผู้รับ: $fullName")));
      }
    } catch (e) {
      debugPrint("❌ ค้นหาผู้รับผิดพลาด: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("เกิดข้อผิดพลาดในการค้นหา")));
    } finally {
      setState(() {
        _isSearchingReceiver = false;
      });
    }
  }

  final ImagePicker _picker = ImagePicker();
  File? _image;

  @override
  void dispose() {
    _senderPhoneController.dispose();
    _receiverPhoneController.dispose();
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
      final shipmentData = {
        'senderId': widget.uid,
        'senderName': senderName,
        'receiverId': _foundReceiverId,
        'senderPhone': _senderPhoneController.text.toString(),
        'senderAddress': _selectedSenderAddress,
        'receiverAddress': _receiverAddressController.text,
        'receiverStateCountry': _receiverStateCountryController.text,
        'receiverOther': _receiverOtherController.text,
        'quantity': _packageQuantityController.text,
        'details': _packageDetailsController.text.toString(),
        'notes': _packageNotesController.text.toString(),
        'ridername': 'none',
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending',
        // 'imageUrl': imageUrl,
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
    // ... (ส่วนนี้เหมือนเดิมครับ) ...
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
    // ... (ส่วนนี้เหมือนเดิมครับ) ...
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
    // ... (ส่วนนี้เหมือนเดิมครับ) ...
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
    // ... (ส่วนนี้เหมือนเดิมครับ) ...
    return Padding(
      padding: const EdgeInsets.only(left: 32.0, top: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _receiverPhoneController,
            decoration: InputDecoration(
              labelText: "ค้นหาผู้รับด้วยเบอร์โทร",
              suffixIcon: _isSearchingReceiver
                  ? const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 3),
                      ),
                    )
                  : IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: _searchReceiverByPhone,
                    ),
            ),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _receiverAddressController,
            decoration: const InputDecoration(labelText: "ชื่อผู้รับ"),
            validator: (value) =>
                (value == null || value.isEmpty) ? 'กรุณากรอกชื่อผู้รับ' : null,
          ),
          TextFormField(
            controller: _receiverStateCountryController,
            decoration: const InputDecoration(labelText: "ที่อยู่ (พิกัด)"),
            validator: (value) =>
                (value == null || value.isEmpty) ? 'กรุณากรอกที่อยู่' : null,
          ),
          TextFormField(
            controller: _receiverOtherController,
            decoration: const InputDecoration(labelText: "คนอื่น (ไม่จำเป็น)"),
          ),
          const SizedBox(height: 16),

          if (_receiverSavedAddresses.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                "ที่อยู่ที่บันทึกไว้ (แตะเพื่อเลือกและดูแผนที่):",
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ..._receiverSavedAddresses.map((address) {
            return _buildSavedDestinationCard(address: address);
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildPackageSection() {
    // ... (ส่วนนี้เหมือนเดิมครับ) ...
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
    // ... (ส่วนนี้เหมือนเดิมครับ) ...
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            OutlinedButton.icon(
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
    // ตรวจสอบว่าการ์ดใบนี้คือใบที่กำลังถูกเลือกอยู่หรือไม่
    final bool isSelected = (_selectedAddressForMap == address);

    // ฟังก์ชันสำหรับแปลง "lat, long" string เป็น LatLng
    LatLng? parseLatLng(String addressString) {
      final parts = addressString.split(" \n ");
      if (parts.length == 2) {
        final latLngString = parts[1];
        final latLngParts = latLngString.split(',');
        if (latLngParts.length == 2) {
          final lat = double.tryParse(latLngParts[0].trim());
          final lng = double.tryParse(latLngParts[1].trim());
          if (lat != null && lng != null) {
            return LatLng(lat, lng);
          }
        }
      }
      return null; // ถ้าแปลงไม่ได้
    }

    // ลองแปลงพิกัด
    final LatLng? position = parseLatLng(address);

    return Column(
      // 1. ใช้ Column ครอบการ์ดและแผนที่
      children: [
        InkWell(
          onTap: () {
            // ถ้ากดการ์ดที่เลือกอยู่แล้ว = ปิดแผนที่
            if (isSelected) {
              setState(() {
                _selectedAddressForMap = null;
                _receiverAddressController.clear();
                _receiverStateCountryController.clear();
              });
              return;
            }

            // ถ้าพิกัดถูกต้อง
            if (position != null) {
              final parts = address.split(" \n ");
              final fullName = parts[0];
              final latLngString = parts[1];

              setState(() {
                _receiverAddressController.text = fullName;
                _receiverStateCountryController.text = latLngString;
                _selectedAddressForMap =
                    address; // ตั้งค่าการ์ดนี้ให้เป็น "ที่เลือก"
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("เลือกที่อยู่ผู้รับแล้ว ✅")),
              );
            } else {
              // ถ้าพิกัดไม่ถูกต้อง (เช่น เป็นที่อยู่เก่าที่ไม่ได้เก็บเป็น lat,long)
              debugPrint("Map: ที่อยู่ $address ไม่อยู่ในรูปแบบ lat,long");
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("ที่อยู่นี้ไม่มีพิกัดแผนที่")),
              );
            }
          },
          child: Container(
            width: double.infinity,
            margin: isSelected
                ? const EdgeInsets.only(
                    bottom: 0,
                  ) // ถ้าถูกเลือก ไม่ต้องเว้นล่าง
                : const EdgeInsets.only(
                    bottom: 8.0,
                  ), // ถ้าไม่ถูกเลือก เว้นล่างปกติ
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: isSelected ? Colors.blue.shade50 : Colors.grey.shade100,
              border: Border.all(
                color: isSelected ? Colors.blue.shade700 : Colors.grey.shade300,
              ),
              // --- MODIFIED --- (ปรับขอบมน)
              borderRadius: isSelected
                  ? const BorderRadius.only(
                      // ถ้าถูกเลือก ให้มนแค่ข้างบน
                      topLeft: Radius.circular(8.0),
                      topRight: Radius.circular(8.0),
                    )
                  : BorderRadius.circular(8.0), // ถ้าไม่ถูกเลือก มนทั้งหมด
            ),
            child: Row(
              children: [
                Icon(Icons.add_circle_outline, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                Expanded(child: Text(address)),
                const SizedBox(width: 8),
                // --- ADDED --- (เพิ่มลูกศรชี้ขึ้น/ลง)
                Icon(
                  isSelected
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: Colors.grey.shade700,
                ),
              ],
            ),
          ),
        ),

        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          height: isSelected && position != null
              ? 200
              : 0, // ความสูง 200 เมื่อถูกเลือก (และมีพิกัด)
          width: double.infinity,
          margin: isSelected
              ? const EdgeInsets.only(bottom: 8.0) // เว้นระยะขอบล่างเมื่อเปิด
              : const EdgeInsets.only(bottom: 0),
          child: (isSelected && position != null)
              ? ClipRRect(
                  // ตัดขอบมนด้านล่าง
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(8.0),
                    bottomRight: Radius.circular(8.0),
                  ),
                  child: _buildInlineMap(position), // เรียกใช้แผนที่
                )
              : Container(), // ถ้าไม่เลือก/ไม่มีพิกัด ก็ไม่ต้องแสดงอะไร
        ),
      ],
    );
  }

  Widget _buildInlineMap(LatLng position) {
    return GoogleMap(
      initialCameraPosition: CameraPosition(target: position, zoom: 16.0),
      markers: {
        Marker(markerId: MarkerId(position.toString()), position: position),
      },
      mapType: MapType.normal,
      myLocationButtonEnabled: false, // ปิดปุ่ม GPS
      zoomControlsEnabled: false, // ปิดปุ่มซูม
      scrollGesturesEnabled: false, // ปิดการเลื่อนแผนที่ (ถ้าต้องการ)
      tiltGesturesEnabled: false, // ปิดการเอียง
    );
  }
}
