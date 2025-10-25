import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer'; // สำหรับ debugPrint

class ReceivedItemsPage extends StatefulWidget {
  final String uid; // uid ของ "ผู้ส่ง" (ตัวเรา)
  ReceivedItemsPage({super.key, required this.uid});

  @override
  State<ReceivedItemsPage> createState() => _ReceivedItemsPageState();
}

class _ReceivedItemsPageState extends State<ReceivedItemsPage> {
  late final Stream<QuerySnapshot> _itemsStream;

  @override
  void initState() {
    super.initState();

    // +++ Query หา shipment ที่ senderId คือ uid ของเรา +++
    _itemsStream = FirebaseFirestore.instance
        .collection('shipment')
        .where(
          'senderId',
          isEqualTo: widget.uid,
        ) // <-- ค้นหาด้วย ID ผู้ส่ง (เรา)
        .where('status', whereIn: ['pending', 'inTransit', 'accepted'])
        .snapshots();
  }

  Future<void> _handleRefresh() async {
    // โค้ด Refresh (เหมือนเดิม)
    await Future.delayed(const Duration(seconds: 1));
    debugPrint("RefreshIndicator triggered.");
  }

  // --- ฟังก์ชัน Lookup (ปรับปรุง Rider Lookup) ---
  Future<Map<String, dynamic>> getSentItemDetails(
    DocumentSnapshot shipmentDoc,
  ) async {
    var data = shipmentDoc.data() as Map<String, dynamic>;
    final db = FirebaseFirestore.instance;

    // 1. ดึงข้อมูลพื้นฐาน
    String packageId = shipmentDoc.id;
    String itemDesc = data['details'] ?? 'N/A';
    String status = data['status'] ?? 'N/A';
    String receiverLocation =
        data['receiverAddress'] ??
        data['receiverStateCountry'] ??
        'N/A'; // ที่อยู่ผู้รับ

    // 2. ดึงชื่อ/เบอร์ ผู้ส่ง (คือเราเอง - อาจจะไม่ต้อง Lookup)
    String senderName = data['senderName'] ?? 'N/A';
    String senderPhone = data['senderPhone'] ?? 'N/A';

    // 3. ดึงชื่อ/ID ผู้รับ (สำหรับ Lookup ชื่อ)
    String receiverName = data['receiverName'] ?? 'N/A';
    String? receiverId = data['receiverId'];

    // 4. ดึง ID ไรเดอร์ (ถ้ามี)
    String? riderId = data['riderId'];
    String riderName = 'N/A';
    String riderPhone = 'N/A';

    try {
      // --- (ส่วน Lookup ผู้ส่ง อาจจะไม่จำเป็น ถ้า senderName/Phone ถูกต้องเสมอ) ---
      // if ((senderName == 'N/A' || senderName.isEmpty) && senderId != null) { ... }

      // 5. Lookup ชื่อผู้รับ (ถ้าดึงตรงๆ ไม่ได้ หรือต้องการข้อมูลล่าสุด)
      if ((receiverName == 'N/A' || receiverName.isEmpty) &&
          receiverId != null) {
        // *** ตรวจสอบ Collection/Field ผู้รับ ('User'?) ***
        DocumentSnapshot receiverDoc = await db
            .collection('User')
            .doc(receiverId)
            .get();
        if (receiverDoc.exists) {
          var receiverData = receiverDoc.data() as Map<String, dynamic>;
          // *** ตรวจสอบ Field ชื่อผู้รับ ('First_name', 'Last_name'?) ***
          final firstName = receiverData['First_name'] ?? '';
          final lastName = receiverData['Last_name'] ?? '';
          receiverName = "$firstName $lastName".trim();
        }
      }

      // 6. Lookup ไรเดอร์ (แก้ไขให้ตรง Database ไรเดอร์)
      if (riderId != null && riderId.isNotEmpty) {
        // *** ใช้ Collection 'riders' ***
        DocumentSnapshot riderDoc = await db
            .collection('riders')
            .doc(riderId)
            .get();
        if (riderDoc.exists) {
          var riderData = riderDoc.data() as Map<String, dynamic>;
          // *** ใช้ Field 'Name' และ 'Phone' ***
          riderName = riderData['Name'] ?? 'N/A';
          riderPhone = riderData['Phone'] ?? 'N/A';
        } else {
          riderName = 'ไรเดอร์ ไม่พบข้อมูล'; // กรณีหา ID ไม่เจอ
          riderPhone = '';
        }
      }
    } catch (e) {
      print("Error looking up details: $e");
    }

    // 7. คืนข้อมูลทั้งหมด
    return {
      'packageId': packageId,
      'itemDescription': itemDesc,
      'senderName': senderName, // ชื่อเรา
      'senderPhone': senderPhone, // เบอร์เรา
      'receiverName': receiverName.isEmpty
          ? 'Receiver N/A'
          : receiverName, // ชื่อผู้รับ
      'address': receiverLocation, // ที่อยู่ผู้รับ
      'status': status,
      'riderName': riderName,
      'riderPhone': riderPhone,
    };
  }
  // --- สิ้นสุดฟังก์ชัน Lookup ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        // +++ Title: "ของที่กำลังส่ง" +++
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
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: StreamBuilder<QuerySnapshot>(
          stream: _itemsStream,
          builder:
              (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.hasError) {
                  debugPrint("StreamBuilder Error: ${snapshot.error}");
                  // อาจจะต้องเช็ค Error ประเภท Index ที่นี่ด้วย
                  if (snapshot.error.toString().contains('index')) {
                    return _buildEmptyState(
                      "กำลังสร้าง Index...\nกรุณาลองรีเฟรชในภายหลัง",
                    );
                  }
                  return const Center(
                    child: Text('เกิดข้อผิดพลาดในการโหลดข้อมูล'),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  // +++ ข้อความ Empty State: "ของที่กำลังส่ง" +++
                  return _buildEmptyState("คุณยังไม่มีรายการที่กำลังส่ง");
                }

                // --- ใช้ ListView.builder กับ FutureBuilder (เหมือนเดิม)---
                return ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var doc = snapshot.data!.docs[index];

                    // ใช้ FutureBuilder รอผล Lookup
                    return FutureBuilder<Map<String, dynamic>>(
                      future: getSentItemDetails(
                        doc,
                      ), // <-- เรียกฟังก์ชัน getSentItemDetails
                      builder: (context, detailSnapshot) {
                        // สถานะ กำลังโหลด...
                        if (detailSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return _buildPackageCard(
                            // แสดง Card แบบ Loading
                            packageId: doc.id,
                            itemDescription: "กำลังโหลด...",
                            personLabel: "ผู้รับ:", // แก้ Label
                            personName: "...",
                            personPhone: "",
                            address: "...",
                            addressLabel: "ที่อยู่ส่ง:", // แก้ Label
                            status: "...",
                            riderName: "...",
                            riderPhone: "",
                          );
                        }

                        // สถานะ เกิด Error
                        if (detailSnapshot.hasError) {
                          return Card(
                            color: Colors.red[100],
                            margin: const EdgeInsets.only(bottom: 16.0),
                            child: ListTile(
                              title: Text("โหลดรายละเอียดผิดพลาด: ${doc.id}"),
                              subtitle: Text(detailSnapshot.error.toString()),
                            ),
                          );
                        }

                        // สถานะ สำเร็จ
                        if (detailSnapshot.hasData) {
                          var details = detailSnapshot.data!;

                          // +++ ส่งข้อมูล "ผู้รับ" ไปแสดง +++
                          return _buildPackageCard(
                            packageId: details['packageId'],
                            itemDescription: details['itemDescription'],
                            personLabel: "ผู้รับ:", // <-- Label คือ "ผู้รับ:"
                            personName:
                                details['receiverName'], // <-- ชื่อผู้รับ
                            personPhone:
                                "", // <-- (เบอร์ผู้รับ ปกติไม่มีใน shipment)
                            address: details['address'], // <-- ที่อยู่ผู้รับ
                            addressLabel: "ที่อยู่ส่ง:", // <-- Label ที่อยู่
                            status: details['status'],
                            riderName: details['riderName'],
                            riderPhone: details['riderPhone'],
                          );
                        }

                        return SizedBox.shrink(); // กรณีอื่นๆ
                      },
                    );
                  },
                );
                // --- สิ้นสุด ListView.builder ---
              },
        ),
      ),
    );
  }

  // --- Widget หน้าว่าง (แก้ Icon) ---
  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.outbox_rounded, // <-- Icon กล่องส่งออก
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // +++ Widget การ์ดแสดงพัสดุ (แก้ Parameter) +++
  Widget _buildPackageCard({
    required String packageId,
    required String itemDescription,
    required String personLabel, // ควรเป็น "ผู้รับ:"
    required String personName,
    required String personPhone, // (อาจจะว่าง)
    required String address, // ที่อยู่ผู้รับ
    required String addressLabel, // ควรเป็น "ที่อยู่ส่ง:"
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
            // ข้อมูลผู้รับ
            label: personLabel, // "ผู้รับ:"
            value: personName,
            phone: personPhone, // (อาจจะไม่มีไอคอน ถ้า phone ว่าง)
            valueColor: primaryText,
          ),
          _buildInfoRow(
            // ที่อยู่ผู้รับ
            label: addressLabel, // "ที่อยู่ส่ง:"
            value: address,
            valueColor: primaryText,
          ),
          _buildInfoRow(
            label: "สถานะ:",
            value: status,
            valueColor: _getStatusColor(status),
          ),
          _buildRiderInfoRow(
            riderName: riderName,
            riderPhone: riderPhone,
            valueColor: primaryText,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              print("กดดูแผนที่ของ $packageId"); /* TODO */
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

  // --- Helper: แถวข้อมูลธรรมดา (เหมือนเดิม) ---
  Widget _buildInfoRow({
    required String label,
    required String value,
    Color? valueColor,
  }) {
    // ... (โค้ดเหมือนเดิม) ...
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

  // --- Helper: แถวข้อมูลพร้อมไอคอนโทรศัพท์ (เหมือนเดิม) ---
  Widget _buildInfoRowWithIcon({
    required String label,
    required String value,
    required String phone,
    Color? valueColor,
  }) {
    // ... (โค้ดเหมือนเดิม) ...
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
                Flexible(
                  // ทำให้ชื่อตัดคำถ้าเบอร์ยาว
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 15,
                      color: valueColor ?? Colors.black,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis, // ตัดคำถ้าชื่อยาวไป
                  ),
                ),
                // แสดงไอคอนและเบอร์โทร ถ้ามีเบอร์จริงๆ
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

  // --- Helper: แถวข้อมูลสำหรับไรเดอร์โดยเฉพาะ (เหมือนเดิม) ---
  Widget _buildRiderInfoRow({
    required String riderName,
    required String riderPhone,
    Color? valueColor,
  }) {
    // ... (โค้ดเหมือนเดิม) ...
    // กรณี: ยังไม่มีไรเดอร์รับงาน (หรือหาข้อมูลไรเดอร์ไม่เจอ)
    if (riderName == 'N/A' ||
        riderName.trim().isEmpty ||
        riderName == 'ไรเดอร์ ไม่พบข้อมูล') {
      return _buildInfoRow(
        label: "ไรเดอร์:", // Label ภาษาไทย
        value: "ยังไม่มีคนรับ", // ข้อความภาษาไทย
        valueColor: Colors.orange.shade700, // สีส้ม
      );
    }
    // กรณี: มีไรเดอร์รับงานแล้ว => แสดงชื่อและเบอร์โทรเลย
    else {
      return _buildInfoRowWithIcon(
        // <-- ใช้ Widget เดิมที่แสดงชื่อ+เบอร์
        label: "ไรเดอร์:", // Label ภาษาไทย
        value: riderName,
        phone: riderPhone,
        valueColor: valueColor,
      );
    }
  }

  // --- Helper: ฟังก์ชันคืนค่าสีตามสถานะ (เหมือนเดิม) ---
  Color _getStatusColor(String status) {
    // ... (โค้ดเหมือนเดิม) ...
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.blue.shade700;
      case 'accepted':
        return Colors.green.shade700;
      case 'intransit': // สมมติว่าอาจมีสถานะนี้ในอนาคต
        return Colors.purple.shade700;
      case 'completed':
        return Colors.grey.shade600;
      case 'cancelled':
        return Colors.red.shade700;
      default:
        return Colors.black; // สีเริ่มต้น
    }
  }
} // สิ้นสุด _ReceivedItemsPageState
