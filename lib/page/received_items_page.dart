import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer'; // สำหรับ debugPrint

class ReceivedItemsPage extends StatefulWidget {
  final String uid; // uid ของ "ผู้รับ" (ตัวเรา)
  ReceivedItemsPage({super.key, required this.uid});

  @override
  State<ReceivedItemsPage> createState() => _ReceivedItemsPageState();
}

class _ReceivedItemsPageState extends State<ReceivedItemsPage> {
  late final Stream<QuerySnapshot> _itemsStream;

  @override
  void initState() {
    super.initState();

    // Query หา shipment ที่ receiverId คือ uid ของเรา
    _itemsStream = FirebaseFirestore.instance
        .collection('shipment')
        .where('receiverId', isEqualTo: widget.uid) // <-- Query ที่ถูกต้อง
        .where('status', whereIn: ['pending', 'inTransit', 'accepted'])
        .snapshots();
  }

  Future<void> _handleRefresh() async {
    // โค้ด Refresh (เหมือนเดิม)
    await Future.delayed(const Duration(seconds: 1));
    debugPrint("RefreshIndicator triggered.");
  }

  // --- ฟังก์ชัน Lookup (เหมือนเดิม) ---
  Future<Map<String, dynamic>> getReceivedItemDetails(
    DocumentSnapshot shipmentDoc,
  ) async {
    var data = shipmentDoc.data() as Map<String, dynamic>;
    final db = FirebaseFirestore.instance;

    String packageId = shipmentDoc.id;
    String itemDesc = data['details'] ?? 'N/A';
    String status = data['status'] ?? 'N/A';
    String receiverLocation =
        data['receiverAddress'] ?? data['receiverStateCountry'] ?? 'N/A';
    String senderName = data['senderName'] ?? 'N/A';
    String senderPhone = data['senderPhone'] ?? 'N/A';
    String? senderId = data['senderId'];
    String? riderId = data['riderId'];
    String riderName = 'N/A';
    String riderPhone = 'N/A';

    try {
      if ((senderName == 'N/A' || senderName.isEmpty) && senderId != null) {
        DocumentSnapshot senderDoc = await db
            .collection('User')
            .doc(senderId)
            .get();
        if (senderDoc.exists) {
          var senderData = senderDoc.data() as Map<String, dynamic>;
          final firstName = senderData['First_name'] ?? '';
          final lastName = senderData['Last_name'] ?? '';
          senderName = "$firstName $lastName".trim();
          senderPhone = senderData['Phone'] ?? 'N/A';
        }
      }

      if (riderId != null && riderId.isNotEmpty) {
        // *** แก้ Collection/Field ไรเดอร์ ถ้าจำเป็น (เช่น 'riders') ***
        DocumentSnapshot riderDoc = await db
            .collection('riders')
            .doc(riderId)
            .get(); // <-- สมมติว่าแก้เป็น 'riders'
        if (riderDoc.exists) {
          var riderData = riderDoc.data() as Map<String, dynamic>;
          // *** แก้ Field ชื่อ/เบอร์ ไรเดอร์ ถ้าจำเป็น ***
          riderName =
              riderData['Name'] ?? 'N/A'; // <-- สมมติว่า Field ชื่อคือ 'Name'
          riderPhone =
              riderData['Phone'] ??
              'N/A'; // <-- สมมติว่า Field เบอร์คือ 'Phone'
        } else {
          riderName = 'ไรเดอร์ ไม่พบข้อมูล';
          riderPhone = '';
        }
      }
    } catch (e) {
      print("Error looking up details: $e");
    }

    return {
      'packageId': packageId,
      'itemDescription': itemDesc,
      'senderName': senderName.isEmpty ? 'Sender N/A' : senderName,
      'senderPhone': senderPhone.isEmpty ? 'N/A' : senderPhone,
      'address': receiverLocation,
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
        // AppBar configuration (เหมือนเดิม)
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "ของที่กำลังส่ง", // Title ภาษาไทย
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
          builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (snapshot.hasError) {
              debugPrint("StreamBuilder Error: ${snapshot.error}");
              return const Center(child: Text('เกิดข้อผิดพลาดในการโหลดข้อมูล'));
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              // แสดงหน้าว่างพร้อมข้อความภาษาไทย
              return _buildEmptyState("คุณยังไม่มีพัสดุที่กำลังส่งมาถึง");
            }

            // --- ใช้ ListView.builder กับ FutureBuilder (เหมือนเดิม)---
            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                var doc = snapshot.data!.docs[index];

                // ใช้ FutureBuilder รอผล Lookup
                return FutureBuilder<Map<String, dynamic>>(
                  future: getReceivedItemDetails(doc), // เรียกฟังก์ชัน Lookup
                  builder: (context, detailSnapshot) {
                    // สถานะ กำลังโหลด...
                    if (detailSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return _buildPackageCard(
                        packageId: doc.id,
                        itemDescription: "กำลังโหลด...",
                        personLabel: "ผู้ส่ง:",
                        personName: "...",
                        personPhone: "",
                        address: "...",
                        status: "...",
                        riderName: "...", // แสดง ... แทนไรเดอร์
                        riderPhone: "",
                      );
                    }

                    // สถานะ เกิด Error
                    if (detailSnapshot.hasError) {
                      return Card(
                        color: Colors.red[100],
                        margin: const EdgeInsets.only(bottom: 16.0),
                        child: ListTile(
                          title: Text("โหลดข้อมูลผิดพลาด: ${doc.id}"),
                          subtitle: Text(detailSnapshot.error.toString()),
                        ),
                      );
                    }

                    // สถานะ สำเร็จ
                    if (detailSnapshot.hasData) {
                      var details = detailSnapshot.data!;

                      return _buildPackageCard(
                        packageId: details['packageId'],
                        itemDescription: details['itemDescription'],
                        personLabel: "ผู้ส่ง:", // Label คือ "ผู้ส่ง:"
                        personName: details['senderName'], // ชื่อผู้ส่ง
                        personPhone: details['senderPhone'], // เบอร์ผู้ส่ง
                        address: details['address'], // ที่อยู่เรา
                        status: details['status'],
                        riderName:
                            details['riderName'], // ชื่อไรเดอร์ (อาจเป็น N/A)
                        riderPhone:
                            details['riderPhone'], // เบอร์ไรเดอร์ (อาจเป็น N/A)
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

  // --- Widget หน้าว่าง (เหมือนเดิม) ---
  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.local_shipping_outlined, // Icon รถส่งของ
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            message, // ใช้ข้อความที่ส่งเข้ามา
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // --- Widget การ์ดแสดงพัสดุ (เหมือนเดิม) ---
  Widget _buildPackageCard({
    required String packageId,
    required String itemDescription,
    required String personLabel, // ควรเป็น "ผู้ส่ง:"
    required String personName,
    required String personPhone,
    required String address, // ที่อยู่เรา
    required String status,
    required String riderName, // อาจเป็น N/A
    required String riderPhone, // อาจเป็น N/A
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
            // รายละเอียดสินค้า
            label: "สินค้า:",
            value: itemDescription,
            valueColor: primaryText,
          ),
          _buildInfoRowWithIcon(
            // ข้อมูลผู้ส่ง
            label: personLabel, // "ผู้ส่ง:"
            value: personName,
            phone: personPhone,
            valueColor: primaryText,
          ),
          _buildInfoRow(
            // ที่อยู่ (ของเรา)
            label: "ที่อยู่:",
            value: address,
            valueColor: primaryText,
          ),
          _buildInfoRow(
            // สถานะ
            label: "สถานะ:",
            value: status,
            valueColor: _getStatusColor(status), // สีตามสถานะ
          ),
          // --- ส่วนแสดงข้อมูลไรเดอร์ (เรียกใช้ Helper ที่แก้ไขแล้ว) ---
          _buildRiderInfoRow(
            // *** เรียกใช้ฟังก์ชันที่แก้ไขแล้ว ***
            riderName: riderName,
            riderPhone: riderPhone,
            valueColor: primaryText,
          ),
          // --- จบส่วนไรเดอร์ ---
          const SizedBox(height: 16),
          ElevatedButton(
            // ปุ่มดูแผนที่ (ยังไม่ได้ทำ)
            onPressed: () {
              print("กดดูแผนที่ของ $packageId");
              // TODO: เพิ่มโค้ดเปิดหน้าแผนที่
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

  // +++ แก้ไข Helper: แถวข้อมูลสำหรับไรเดอร์โดยเฉพาะ +++
  Widget _buildRiderInfoRow({
    required String riderName,
    required String riderPhone,
    Color? valueColor,
  }) {
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
  // +++ สิ้นสุด Helper: ไรเดอร์ (ฉบับแก้ไขล่าสุด) +++

  // --- Helper: ฟังก์ชันคืนค่าสีตามสถานะ (เหมือนเดิม) ---
  Color _getStatusColor(String status) {
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
