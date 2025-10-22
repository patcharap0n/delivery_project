import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart'; // (Backend)
// import 'package:firebase_auth/firebase_auth.dart'; // (Backend)

// (Backend) นี่คือข้อมูลจำลอง
// คุณสามารถลบส่วนนี้ทิ้ง แล้วไปดึงข้อมูลจริงจาก Firestore
class _DummyPackageData {
  final String packageId;
  final String itemDescription;
  final String senderName;
  final String senderPhone;
  final String address;
  final String status;
  final String riderName;
  final String riderPhone;

  _DummyPackageData({
    required this.packageId,
    required this.itemDescription,
    required this.senderName,
    required this.senderPhone,
    required this.address,
    required this.status,
    required this.riderName,
    required this.riderPhone,
  });
}
// --------------------------------------------------

class ReceivedItemsPage extends StatefulWidget {
  const ReceivedItemsPage({super.key});

  @override
  State<ReceivedItemsPage> createState() => _ReceivedItemsPageState();
}

class _ReceivedItemsPageState extends State<ReceivedItemsPage> {
  // (Backend) ตัวแปรสำหรับเก็บข้อมูลจริง
  // List<Shipment> receivedItems = [];
  bool isLoading = true;

  // (Backend) ข้อมูลจำลอง (ลบทิ้งเมื่อเชื่อม Firebase)
  final List<_DummyPackageData> _dummyData = [
    _DummyPackageData(
      packageId: 'Package #12345',
      itemDescription: 'เอกสารด่วน',
      senderName: 'นายสมชาย',
      senderPhone: '081-xxx-xxxx',
      address: '99/1 ถนน A เขต B',
      status: '[3] ไรเดอร์รับสินค้าแล้วและกำลังเดินทางไปส่ง',
      riderName: 'คุณชัย',
      riderPhone: '089-xxx-xxxx',
    ),
    _DummyPackageData(
      packageId: 'Package #12346',
      itemDescription: 'กล่องพัสดุ',
      senderName: 'นางสมหญิง',
      senderPhone: '082-xxx-xxxx',
      address: '100/2 ถนน C เขต D',
      status: '[2] ไรเดอร์รับงาน (กำลังเดินทางมารับสินค้า)',
      riderName: 'คุณชาติ',
      riderPhone: '085-xxx-xxxx',
    ),
    _DummyPackageData(
      packageId: 'Package #12347',
      itemDescription: 'ซองจดหมาย',
      senderName: 'นายสมศักดิ์',
      senderPhone: '083-xxx-xxxx',
      address: '101/3 ถนน E เขต F',
      status: '[3] ไรเดอร์รับสินค้าแล้วและกำลังเดินทางไปส่ง',
      riderName: 'คุณวิทย์',
      riderPhone: '086-xxx-xxxx',
    ),
  ];
  // --------------------------------------------------

  @override
  void initState() {
    super.initState();
    // (Backend) TODO: เรียกฟังก์ชันดึงข้อมูลจริงที่นี่
    // _fetchReceivedItems();
    
    // (Backend) โค้ดสำหรับจำลองการโหลด (ลบทิ้งได้)
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        isLoading = false;
      });
    });
  }

  // (Backend) TODO: สร้างฟังก์ชันดึงข้อมูล
  // Future<void> _fetchReceivedItems() async {
  //   try {
  //     String? uid = FirebaseAuth.instance.currentUser?.uid;
  //     var snapshot = await FirebaseFirestore.instance
  //         .collection('shipments')
  //         .where('receiverId', isEqualTo: uid)
  //         .where('status', whereIn: ['pending', 'accepted', 'inTransit'])
  //         .get();
  //     
  //     // ... นำ snapshot ไปแปลงเป็น List<Shipment>
  //
  //     setState(() {
  //       // receivedItems = ... (ข้อมูลที่ดึงได้)
  //       isLoading = false;
  //     });
  //   } catch (e) {
  //     setState(() => isLoading = false);
  //     print("Error fetching items: $e");
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200], // สีพื้นหลังเทาอ่อนๆ
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "ของที่ได้รับ", // ในรูปเป็น "ของที่ได้รับ"
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          // (Backend) เปลี่ยน _dummyData.length เป็น receivedItems.length
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              // (Backend) เปลี่ยน _dummyData.length เป็น receivedItems.length
              itemCount: _dummyData.length,
              itemBuilder: (context, index) {
                // (Backend) ดึงข้อมูลจริงจาก
                // final item = receivedItems[index];
                
                // (Backend) ดึงข้อมูลจำลอง (ลบส่วนนี้เมื่อเชื่อม Firebase)
                final item = _dummyData[index];
                
                return _buildPackageCard(
                  packageId: item.packageId,
                  itemDescription: item.itemDescription,
                  senderName: item.senderName,
                  senderPhone: item.senderPhone,
                  address: item.address,
                  status: item.status,
                  riderName: item.riderName,
                  riderPhone: item.riderPhone,
                );
              },
            ),
    );
  }

  // --- Helper Widget: การ์ดแสดงข้อมูลพัสดุ ---
  Widget _buildPackageCard({
    required String packageId,
    required String itemDescription,
    required String senderName,
    required String senderPhone,
    required String address,
    required String status,
    required String riderName,
    required String riderPhone,
  }) {
    const Color primaryText = Color(0xFF005FFF); // สีน้ำเงิน

    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Package ID
          Text(
            packageId,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          
          // รายละเอียด
          _buildInfoRow(
            label: "สินค้า:",
            value: itemDescription,
            valueColor: primaryText,
          ),
          
          // ผู้รับ (ในรูปคือผู้ส่ง)
          _buildInfoRowWithIcon(
            label: "ผู้รับ:", // ในรูปเขียน "ผู้รับ"
            value: senderName,
            phone: senderPhone,
            valueColor: primaryText,
          ),

          _buildInfoRow(
            label: "ที่อยู่:",
            value: address,
            valueColor: primaryText,
          ),
          
          _buildInfoRow(
            label: "สถานะ:",
            value: status,
            valueColor: Colors.green.shade700, // สถานะสีเขียว
          ),

          _buildInfoRowWithIcon(
            label: "Rider:",
            value: riderName,
            phone: riderPhone,
            valueColor: primaryText,
          ),
          
          const SizedBox(height: 16),
          
          // ปุ่มดูแผนที่
          Align(
            alignment: Alignment.centerLeft,
            child: ElevatedButton(
              onPressed: () {
                // TODO: (Backend) ไปยังหน้าแผนที่
                // โดยส่ง ID ของ Rider หรือ Shipment ไป
                print("กดดูแผนที่ของ $packageId");
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[200],
                foregroundColor: Colors.black,
                elevation: 0,
              ),
              child: const Text("ดูแผนที่"),
            ),
          ),
        ],
      ),
    );
  }

  // Helper Widget: แถวข้อความธรรมดา
  Widget _buildInfoRow({
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 15, color: Colors.black54),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 15,
                color: valueColor ?? Colors.black,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper Widget: แถวข้อความที่มีไอคอนโทรศัพท์
  Widget _buildInfoRowWithIcon({
    required String label,
    required String value,
    required String phone,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 15, color: Colors.black54),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Row(
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    color: valueColor ?? Colors.black,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.phone_in_talk_rounded, color: Colors.green.shade600, size: 16),
                const SizedBox(width: 4),
                Text(
                  phone,
                  style: const TextStyle(fontSize: 15, color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}