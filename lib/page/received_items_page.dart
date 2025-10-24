import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // <-- 1. Import
import 'package:firebase_auth/firebase_auth.dart'; // <-- 1. Import

// (Backend) นี่คือข้อมูลจำลอง (ใช้เป็น Data Model ชั่วคราว)
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
  // --- 2. ลบ isLoading และ _receivedItems ออกไป ---

  // --- 3. สร้าง "ท่อ" (Stream) ---
  late final Stream<QuerySnapshot> _itemsStream;

  @override
  void initState() {
    super.initState();
    
    // (Backend) TODO: ดึง UID จริง
    String? uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid != null) {
      // 4. ให้ "ท่อ" นี้เชื่อมต่อกับ Firebase
      _itemsStream = FirebaseFirestore.instance
          .collection('shipments')
          .where('receiverId', isEqualTo: uid) // <-- (จุดที่ต่าง) ค้นหาจาก receiverId
          .where('status', whereIn: ['pending', 'accepted', 'inTransit'])
          .snapshots(); // <-- .snapshots() เพื่อติดตามตลอด
    } else {
      _itemsStream = const Stream.empty(); 
    }
  }

  // --- 5. ลบ _fetchReceivedItems() ทิ้งไป ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "ของที่ได้รับ", // <-- Title
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
      ),
      
      // --- 6. เปลี่ยน body เป็น StreamBuilder ---
      body: StreamBuilder<QuerySnapshot>(
        stream: _itemsStream, // <-- ให้มันฟังจาก "ท่อ" ของเรา
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          
          // --- (Logic ที่ปลอดภัย แก้ Error `Null check` แล้ว) ---

          // 1. (if) ตรวจสอบ Error ก่อน
          if (snapshot.hasError) {
            return const Center(child: Text('เกิดข้อผิดพลาดในการโหลดข้อมูล'));
          }

          // 2. (if) ตรวจสอบว่ากำลังโหลด
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // 3. (if) (สำคัญ!) ตรวจสอบว่า "ไม่มีข้อมูล"
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState(); // <-- เรียกหน้าว่าง
          }

          // 4. (else) ถ้ามีข้อมูล...
          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              
              var doc = snapshot.data!.docs[index];
              var data = doc.data() as Map<String, dynamic>? ?? {};

              // (Backend) TODO: ตรวจสอบชื่อ Field ให้ตรงกับ Firestore ของคุณ
              final item = _DummyPackageData(
                packageId: doc.id,
                itemDescription: data['packageDetails'] ?? 'N/A',
                senderName: data['senderName'] ?? 'N/A', // (ตัวอย่าง)
                senderPhone: data['senderPhone'] ?? 'N/A', // (ตัวอย่าง)
                address: (data['deliveryAddress'] as Map<String, dynamic>?)?['fullAddress'] ?? 'N/A',
                status: data['status'] ?? 'N/A',
                riderName: data['riderName'] ?? 'N/A', // (ตัวอย่าง)
                riderPhone: data['riderPhone'] ?? 'N/A', // (ตัวอย่าง)
              );

              return _buildPackageCard(
                packageId: item.packageId,
                itemDescription: item.itemDescription,
                personLabel: "ผู้ส่ง:", // <-- (จุดที่ต่าง)
                personName: item.senderName,
                personPhone: item.senderPhone,
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

  // --- Widget: แสดงหน้าว่าง (ดึงมาจาก EmptyStatePage) ---
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
            "คุณยังไม่มีรายการที่ได้รับ", // <-- (จุดที่ต่าง)
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  // --- (Helper Widgets: _buildPackageCard และอื่นๆ เหมือนเดิม) ---

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
    // ... (โค้ดการ์ดเหมือนเดิม) ...
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
          Text(packageId, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildInfoRow(label: "สินค้า:", value: itemDescription, valueColor: primaryText),
          _buildInfoRowWithIcon(
            label: personLabel, // "ผู้ส่ง:"
            value: personName,
            phone: personPhone,
            valueColor: primaryText,
          ),
          _buildInfoRow(label: "ที่อยู่:", value: address, valueColor: primaryText),
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

  Widget _buildInfoRow({required String label, required String value, Color? valueColor}) {
    // ... (โค้ด InfoRow เหมือนเดิม) ...
     return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 15, color: Colors.black54)),
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

  Widget _buildInfoRowWithIcon({required String label, required String value, required String phone, Color? valueColor}) {
    // ... (โค้ด InfoRowWithIcon เหมือนเดิม) ...
     return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 15, color: Colors.black54)),
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
                Text(phone, style: const TextStyle(fontSize: 15, color: Colors.black54)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}