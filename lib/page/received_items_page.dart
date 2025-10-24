import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:developer'; // <-- ADDED: สำหรับ debugPrint

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

class ReceivedItemsPage extends StatefulWidget {
  final String uid; // uid ของ "ผู้รับ" (ตัวเรา)
  ReceivedItemsPage({super.key, required this.uid});

  @override
  State<ReceivedItemsPage> createState() => _ReceivedItemsPageState();
}

class _ReceivedItemsPageState extends State<ReceivedItemsPage> {
  // --- 3. สร้าง "ท่อ" (Stream) ---
  late final Stream<QuerySnapshot> _itemsStream;

  @override
  void initState() {
    super.initState();

    // สร้าง Stream
    _itemsStream = FirebaseFirestore.instance
        .collection('shipment')
        .where('senderId', isEqualTo: widget.uid)
        .where('status', whereIn: ['pending', 'accepted', 'inTransit'])
        .snapshots();
    print(widget.uid);
  }

  Future<void> _handleRefresh() async {
    await Future.delayed(const Duration(seconds: 1));
    debugPrint("RefreshIndicator triggered.");
  }

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
          "ของที่กำลังส่ง", // <-- Title
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
      ),

      // --- 6. เปลี่ยน body เป็น StreamBuilder ---
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: StreamBuilder<QuerySnapshot>(
          stream: _itemsStream, // <-- ให้มันฟังจาก "ท่อ" ของเรา
          builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
            // 1. (if) ตรวจสอบ Error ก่อน
            if (snapshot.hasError) {
              debugPrint("StreamBuilder Error: ${snapshot.error}");
              return const Center(child: Text('เกิดข้อผิดพลาดในการโหลดข้อมูล'));
            }

            // 2. (if) ตรวจสอบว่ากำลังโหลด
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            // 3. (if) (สำคัญ!) ตรวจสอบว่า "ไม่มีข้อมูล"
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              // (ถ้ามาหยุดตรงนี้ แปลว่า query 'receiverId' ของคุณไม่เจออะไรเลย)
              return _buildEmptyState(); // <-- เรียกหน้าว่าง
            }

            // 4. (else) ถ้ามีข้อมูล...
            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                var doc = snapshot.data!.docs[index];
                var data = doc.data() as Map<String, dynamic>? ?? {};

                // --- MODIFIED ---
                // แก้ไขการจับคู่ Field ให้ตรงกับ Firestore
                final item = _DummyPackageData(
                  packageId: doc.id,
                  // 'details' คือ "รายละเอียดสินค้า"
                  itemDescription: data['details'] ?? 'N/A',
                  // 'senderPhone' คือ "เบอร์ผู้ส่ง" (เราไม่มีชื่อผู้ส่งในเอกสารนี้)
                  senderName: data['senderPhone'] ?? 'N/A', // แสดงเบอร์แทนชื่อ
                  senderPhone: data['senderPhone'] ?? 'N/A',
                  // 'receiverStateCountry' คือ "ที่อยู่ผู้รับ" (ที่อยู่ของเรา)
                  address: data['receiverStateCountry'] ?? 'N/A',
                  status: data['status'] ?? 'N/A',
                  riderName: data['riderName'] ?? 'N/A',
                  riderPhone: data['riderPhone'] ?? 'N/A',
                );
                // --- END MODIFIED ---

                return _buildPackageCard(
                  packageId: item.packageId,
                  itemDescription: item.itemDescription,
                  personLabel: "ผู้ส่ง:", // <-- (จุดที่ต่าง)
                  personName: item.senderName, // (แสดงเบอร์โทรผู้ส่ง)
                  personPhone: item.senderPhone,
                  address: item.address, // (ที่อยู่ของเรา)
                  status: item.status,
                  riderName: item.riderName,
                  riderPhone: item.riderPhone,
                );
              },
            );
          },
        ),
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
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
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
            label: personLabel, // "ผู้ส่ง:"
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
    // ... (โค้ด InfoRow เหมือนเดิม) ...
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
    // ... (โค้ด InfoRowWithIcon เหมือนเดิม) ...
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
                // --- MODIFIED --- (ซ่อน Icon ถ้าไม่มีเบอร์)
                if (phone.isNotEmpty && phone != "N/A") ...[
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}
