import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // <-- 1. Import
import 'package:firebase_auth/firebase_auth.dart'; // <-- 1. Import
// (import หน้า EmptyStatePage.dart ของคุณด้วย)
// import 'package:delivery/page/EmptyStatePage.dart';

// (Class _DummyPackageData ยังคงเดิม)
class _DummyPackageData {
  final String packageId;
  final String itemDescription;
  final String receiverName;
  final String receiverPhone;
  final String address;
  final String status;
  final String riderName;
  final String riderPhone;

  _DummyPackageData({
    required this.packageId,
    required this.itemDescription,
    required this.receiverName,
    required this.receiverPhone,
    required this.address,
    required this.status,
    required this.riderName,
    required this.riderPhone,
  });
}
// --------------------------------------------------

class TransitItemsPage extends StatefulWidget {
  const TransitItemsPage({super.key, required String uid});

  @override
  State<TransitItemsPage> createState() => _TransitItemsPageState();
}

class _TransitItemsPageState extends State<TransitItemsPage> {
  // --- 2. ลบ isLoading และ _transitItems ออกไป ---
  // (StreamBuilder จะจัดการ state ให้เรา)

  // --- 3. สร้าง "ท่อ" (Stream) ---
  late final Stream<QuerySnapshot> _itemsStream;

  @override
  void initState() {
    super.initState();

    // (Backend) TODO: ดึง UID จริง
    // (สำคัญ: ถ้า uid เป็น null ต้องจัดการด้วย)
    String? uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid != null) {
      // 4. ให้ "ท่อ" นี้เชื่อมต่อกับ Firebase
      _itemsStream = FirebaseFirestore.instance
          .collection('shipments')
          .where('senderId', isEqualTo: uid) // ค้นหาจาก senderId
          .where('status', whereIn: ['pending', 'accepted', 'inTransit'])
          .snapshots(); // <-- .snapshots() คือหัวใจสำคัญ (แปลว่า "ติดตามตลอด")
    } else {
      // ถ้าไม่เจอ uid (ยังไม่ login?)
      _itemsStream = const Stream.empty(); // สร้างท่อว่างๆ
    }
  }

  // --- 5. ลบ _fetchTransitItems() ทิ้งไป ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        // ... (AppBar เหมือนเดิม) ...
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "ของที่กำลังส่ง",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
      ),

      // --- 6. เปลี่ยน body เป็น StreamBuilder ---
      body: StreamBuilder<QuerySnapshot>(
        stream: _itemsStream, // <-- ใช้ "ท่อ" เดิม
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          // --- (นี่คือ Logic ที่แก้ไขแล้ว) ---

          // 1. (if) ตรวจสอบ Error ก่อน
          if (snapshot.hasError) {
            return const Center(child: Text('เกิดข้อผิดพลาดในการโหลดข้อมูล'));
          }

          // 2. (if) ตรวจสอบว่ากำลังโหลด (มีวงกลมหมุนๆ)
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // 3. (if) (สำคัญ!) ตรวจสอบว่า "ไม่มีข้อมูล"
          //    เช็คว่า (snapshot.hasData เป็น false) หรือ (snapshot.data!.docs ว่าง)
          //    การเช็ค !snapshot.hasData ก่อน จะป้องกัน Error `!` บน `null` ครับ
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState(); // <-- เรียกหน้าว่าง
          }

          // 4. (else) ถ้ามาถึงตรงนี้ได้ แปลว่ามีข้อมูลแน่นอน
          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var doc = snapshot.data!.docs[index];

              // (แก้ไขการดึงข้อมูลให้ปลอดภัยขึ้น เผื่อ field ใน Firebase เป็น null)
              var data =
                  doc.data() as Map<String, dynamic>? ??
                  {}; // <-- ใช้ Map ว่างเป็น default

              // (Backend) TODO: ตรวจสอบชื่อ Field ให้ตรงกับ Firestore ของคุณ
              final item = _DummyPackageData(
                packageId: doc.id,
                itemDescription: data['packageDetails'] ?? 'N/A',
                receiverName: data['receiverName'] ?? 'N/A', // (ตัวอย่าง)
                receiverPhone: data['receiverPhone'] ?? 'N/A', // (ตัวอย่าง)
                address:
                    (data['deliveryAddress']
                        as Map<String, dynamic>?)?['fullAddress'] ??
                    'N/A',
                status: data['status'] ?? 'N/A',
                riderName: data['riderName'] ?? 'N/A', // (ตัวอย่าง)
                riderPhone: data['riderPhone'] ?? 'N/A', // (ตัวอย่าง)
              );

              return _buildPackageCard(
                packageId: item.packageId,
                itemDescription: item.itemDescription,
                personLabel: "ผู้รับ:", // (สำหรับ TransitItemsPage)
                personName: item.receiverName,
                personPhone: item.receiverPhone,
                address: item.address,
                status: item.status,
                riderName: item.riderName,
                riderPhone: item.riderPhone,
              );
            },
          );
        },
      ),
    );
  }

  // (Helper Widgets: _buildEmptyState, _buildPackageCard ฯลฯ เหมือนเดิม)
  // ...
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none_rounded,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            "คุณยังไม่มีรายการที่กำลังส่ง", // <-- เปลี่ยนข้อความ
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildPackageCard({
    required String packageId,
    required String itemDescription,
    required String personLabel,
    required String personName,
    required String personPhone,
    required String address,
    required String status,
    required String riderName,
    required String riderPhone,
  }) {
    const Color primaryText = Color(0xFF005FFF);
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
          Text(
            packageId,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            label: "สินค้า:",
            value: itemDescription,
            valueColor: primaryText,
          ),
          _buildInfoRowWithIcon(
            label: personLabel,
            value: personName,
            phone: personPhone,
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
            valueColor: Colors.green.shade700,
          ),
          _buildInfoRowWithIcon(
            label: "Rider:",
            value: riderName,
            phone: riderPhone,
            valueColor: primaryText,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              print("กดดูแผนที่ของ $packageId");
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[200],
              foregroundColor: Colors.black,
              elevation: 0,
            ),
            child: const Text("ดูแผนที่"),
          ),
        ],
      ),
    );
  }

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
                Icon(
                  Icons.phone_in_talk_rounded,
                  color: Colors.green.shade600,
                  size: 16,
                ),
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
