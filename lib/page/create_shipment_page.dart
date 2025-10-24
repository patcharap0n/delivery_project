import 'package:flutter/material.dart';
// import 'dart:io'; // สำหรับเก็บไฟล์รูปภาพที่อัปโหลด

class CreateShipmentPage extends StatefulWidget {
  const CreateShipmentPage({super.key, required String uid});

  @override
  State<CreateShipmentPage> createState() => _CreateShipmentPageState();
}

class _CreateShipmentPageState extends State<CreateShipmentPage> {
  // --- ตัวแปรและ State ทั้งหมดที่หน้านี้ต้องใช้ ---

  final _formKey = GlobalKey<FormState>();

  // 1. รายละเอียดแหล่งกำเนิด (Sender)
  final TextEditingController _senderPhoneController = TextEditingController();

  // (ตัวอย่างข้อมูลที่อยู่ User ที่ดึงมาจาก Firebase)
  final List<String> _senderSavedAddresses = [
    "num 1 00000000 (ที่อยู่บ้าน)",
    "num 2 00000000 (ที่ทำงาน)",
    "num 3 00000000 (คอนโด)",
  ];
  String? _selectedSenderAddress; // เก็บที่อยู่ที่ User เลือก

  // 2. Destination Details (Receiver)
  final TextEditingController _receiverAddressController =
      TextEditingController();
  final TextEditingController _receiverStateCountryController =
      TextEditingController();
  final TextEditingController _receiverOtherController =
      TextEditingController();

  // (ตัวอย่างข้อมูลที่อยู่ผู้รับที่อาจจะดึงมา หลังค้นหาด้วยเบอร์)
  final List<String> _receiverSavedAddresses = [
    "Address 1 00000000 State 000, Country 0000",
    "Address 2 00000000 State 000, Country 0000",
  ];

  // 3. รายละเอียดแพ็คเกจ (Package)
  final TextEditingController _packageQuantityController =
      TextEditingController();
  final TextEditingController _packageDetailsController =
      TextEditingController();
  final TextEditingController _packageNotesController = TextEditingController();

  // 4. สถานะการอัปโหลดรูป
  // File? _packageImage; // ตัวแปรเก็บไฟล์รูปภาพ
  bool _isUploadFinished = false;

  // --------------------------------------------------

  @override
  void initState() {
    super.initState();
    // (Backend) อาจจะดึงข้อมูลเบอร์โทร User มาใส่ช่องนี้อัตโนมัติ
    // _senderPhoneController.text = "เบอร์ที่ล็อกอินอยู่";

    // (Frontend) เลือกที่อยู่แรกเป็นค่าเริ่มต้น
    if (_senderSavedAddresses.isNotEmpty) {
      _selectedSenderAddress = _senderSavedAddresses.first;
    }
  }

  @override
  void dispose() {
    // คืนหน่วยความจำ Controller
    _senderPhoneController.dispose();
    _receiverAddressController.dispose();
    _receiverStateCountryController.dispose();
    _receiverOtherController.dispose();
    _packageQuantityController.dispose();
    _packageDetailsController.dispose();
    _packageNotesController.dispose();
    super.dispose();
  }

  // --- ฟังก์ชันสำหรับกดปุ่ม ---

  void _onUploadImage() {
    // TODO: (Backend) เชื่อมต่อ Logic การเลือก/ถ่ายรูป
    // และอัปโหลดไป Firebase Storage
    print("กดอัปโหลดรูป");
    // setState(() {
    //   _packageImage = ... (ไฟล์ที่เลือก);
    //   _isUploadFinished = true; // สมมติว่าอัปโหลดเสร็จ
    // });
  }

  void _onConfirmShipment() {
    // TODO: (Backend) รวบรวมข้อมูลทั้งหมดจาก Controller
    // และตัวแปร State เพื่อสร้าง Shipment ใน Firestore
    if (_formKey.currentState!.validate()) {
      print("--- ข้อมูลการส่ง ---");
      print("เบอร์ผู้ส่ง: ${_senderPhoneController.text}");
      print("ที่อยู่ผู้ส่ง: $_selectedSenderAddress");
      print("ที่อยู่ผู้รับ: ${_receiverAddressController.text}");
      print(
        "รายละเอียดผู้รับ: ${_receiverStateCountryController.text}, ${_receiverOtherController.text}",
      );
      print("จำนวน: ${_packageQuantityController.text} ชิ้น");
      print("รายละเอียด: ${_packageDetailsController.text}");
      print("หมายเหตุ: ${_packageNotesController.text}");
      // print("รูปภาพ: ${_packageImage?.path}");

      // ... ส่งข้อมูลไป Firebase ...

      // กลับไปหน้า Home
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        // ลูกศรย้อนกลับ
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
                // --- 1. ส่วนแหล่งกำเนิด ---
                _buildSectionHeader(
                  Icons.location_history_rounded,
                  "รายละเอียดแหล่งกำเนิด",
                ),
                _buildSenderSection(),

                const SizedBox(height: 24),

                // --- 2. ส่วนปลายทาง ---
                _buildSectionHeader(
                  Icons.location_on_outlined,
                  "Destination Details",
                ),
                _buildDestinationSection(),

                const SizedBox(height: 24),

                // --- 3. ส่วนแพ็คเกจ ---
                _buildSectionHeader(
                  Icons.inventory_2_outlined,
                  "รายละเอียดแพ็คเกจ",
                ),
                _buildPackageSection(),

                const SizedBox(height: 24),

                // --- 4. ส่วนปุ่ม ---
                _buildActionButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Helper Widgets (แบ่งโค้ดให้อ่านง่าย) ---

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
          // รายการที่อยู่ที่บันทึกไว้ (ของผู้ส่ง)
          ..._senderSavedAddresses.map((address) {
            bool isSelected = (_selectedSenderAddress == address);
            return _buildAddressCard(
              address: address,
              isSelected: isSelected,
              onTap: () {
                setState(() {
                  _selectedSenderAddress = address; // อัปเดตการเลือก
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
          // (Backend) TODO: เพิ่มช่องค้นหาด้วยเบอร์โทร
          TextFormField(
            controller: _receiverAddressController,
            decoration: const InputDecoration(labelText: "ที่อยู่"),
            validator: (value) =>
                (value == null || value.isEmpty) ? 'กรุณากรอกที่อยู่' : null,
          ),
          TextFormField(
            controller: _receiverStateCountryController,
            decoration: const InputDecoration(labelText: "รัฐ,ประเทศ"),
            validator: (value) =>
                (value == null || value.isEmpty) ? 'กรุณากรอกข้อมูล' : null,
          ),
          TextFormField(
            controller: _receiverOtherController,
            decoration: const InputDecoration(labelText: "คนอื่น (ไม่จำเป็น)"),
          ),
          const SizedBox(height: 16),
          // รายการที่อยู่ที่บันทึกไว้ (ของผู้รับ)
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
              onPressed: _onUploadImage,
              icon: const Icon(Icons.camera_alt_outlined),
              label: const Text("อัปโหลด"),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.blue.shade700,
                side: BorderSide(color: Colors.blue.shade700),
              ),
            ),
            const SizedBox(width: 16),
            OutlinedButton(
              onPressed: null, // (Frontend) ทำให้กดได้เมื่ออัปโหลดเสร็จ
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
            onPressed: _onConfirmShipment,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF005FFF),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              "ยืนยันส่งของ",
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }

  // การ์ดที่อยู่ (สำหรับผู้ส่ง)
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

  // การ์ดที่อยู่ (สำหรับผู้รับ)
  Widget _buildSavedDestinationCard({required String address}) {
    return Container(
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
            "เพิ่มจุดหมายปลายทาง",
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
