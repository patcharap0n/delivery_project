import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
// (import หน้า EmptyStatePage.dart ของคุณด้วย)
// import 'package:delivery/page/EmptyStatePage.dart';

// (เราไม่ใช้ Class _DummyPackageData แล้ว)

class TransitItemsPage extends StatefulWidget {
  final String uid;
  TransitItemsPage({super.key, required this.uid});

  @override
  State<TransitItemsPage> createState() => _TransitItemsPageState();
}

class _TransitItemsPageState extends State<TransitItemsPage> {
  late final Stream<QuerySnapshot> _itemsStream;

  @override
  void initState() {
    super.initState();

    _itemsStream = FirebaseFirestore.instance
        .collection('shipment')
        .where('receiverId', isEqualTo: widget.uid)
        .where('status', whereIn: ['pending', 'inTransit', 'accepted'])
        .snapshots();
    print(widget.uid);
  }

  // +++ 1. ฟังก์ชัน _getPackageDetails (ที่แก้ไขแล้ว) +++
  // ฟังก์ชันนี้จะดึงข้อมูล shipment และข้อมูล Rider ที่เชื่อมโยงกัน
  Future<Map<String, dynamic>> _getPackageDetails(
    DocumentSnapshot shipmentDoc,
  ) async {
    var data = shipmentDoc.data() as Map<String, dynamic>? ?? {};
    final db = FirebaseFirestore.instance;

    // 1. ดึงข้อมูลพื้นฐานจาก shipment
    String packageId = shipmentDoc.id;
    String itemDescription = data['details'] ?? 'N/A';
    String address = data['receiverAddress'] ?? 'N/A';
    String status = data['status'] ?? 'N/A';
    String imageUrl = data['imageUrl'] ?? '';

    // 2. ดึง ID สำหรับการค้นหา
    String? receiverId = data['receiverId'];
    String? riderId = data['riderId']; // <-- ID ของ Rider

    // 3. เตรียมตัวแปรสำหรับเก็บชื่อ/เบอร์
    String receiverName = data['receiverName'] ?? 'N/A';
    String receiverPhone = data['receiverPhone'] ?? 'N/A';
    String riderName = 'N/A'; // ค่าเริ่มต้น
    String riderPhone = 'N/A'; // ค่าเริ่มต้น

    try {
      // 4. (เผื่อไว้) ดึงข้อมูลผู้รับ ถ้าใน shipment ไม่มี
      if ((receiverName == 'N/A' || receiverName.isEmpty) &&
          receiverId != null) {
        DocumentSnapshot userDoc = await db
            .collection('User')
            .doc(receiverId)
            .get();
        if (userDoc.exists) {
          var userData = userDoc.data() as Map<String, dynamic>;
          receiverName =
              "${userData['First_name'] ?? ''} ${userData['Last_name'] ?? ''}"
                  .trim();
          // ❗️ สมมติว่า field เบอร์โทรใน 'User' ชื่อ 'phone'
          receiverPhone = userData['phone'] ?? 'N/A';
        }
      }

      // 5. ⭐️⭐️ (จุดแก้ไขหลัก) ดึงข้อมูล Rider ⭐️⭐️
      if (riderId != null) {
        // --- 🔴 แก้ไขตรงนี้ 🔴 ---
        // ❗️❗️ เปลี่ยน 'Riders' ให้เป็นชื่อ Collection ที่คุณใช้เก็บ Rider
        DocumentSnapshot riderDoc = await db
            .collection('Riders')
            .doc(riderId)
            .get();

        if (riderDoc.exists) {
          var riderData = riderDoc.data() as Map<String, dynamic>;

          // ❗️❗️ ตรวจสอบ Field ชื่อ, นามสกุล, เบอร์ ของ Rider ให้ตรง
          riderName =
              "${riderData['First_name'] ?? ''} ${riderData['Last_name'] ?? ''}"
                  .trim();
          riderPhone = riderData['phone'] ?? 'N/A';
        } else {
          // ถ้าหา riderId เจอใน shipment แต่ไม่เจอใน collection 'Riders'
          riderName = 'Rider (deleted)';
        }
      } else if (status == 'pending') {
        // ถ้าสถานะ 'pending' และยังไม่มี riderId
        riderName = 'กำลังค้นหา Rider...';
      }
    } catch (e) {
      print("Error fetching details in TransitItemsPage: $e");
      // หากเกิด Error, จะใช้ค่า N/A ที่ตั้งไว้
    }

    // 6. คืนค่าทั้งหมด
    return {
      'packageId': packageId,
      'itemDescription': itemDescription,
      'receiverName': receiverName.isEmpty ? 'N/A' : receiverName,
      'receiverPhone': receiverPhone.isEmpty ? 'N/A' : receiverPhone,
      'address': address,
      'status': status,
      'riderName': riderName.isEmpty ? 'N/A' : riderName,
      'riderPhone': riderPhone.isEmpty ? 'N/A' : riderPhone,
      'imageUrl': imageUrl,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        // (AppBar เหมือนเดิม)
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "ของที่ได้รับ",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _itemsStream,
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('เกิดข้อผิดพลาดในการโหลดข้อมูล'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          // +++ 2. แก้ไข ListView.builder ให้ใช้ FutureBuilder +++
          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var doc = snapshot.data!.docs[index];

              // ใช้ FutureBuilder เพื่อรอข้อมูล Rider
              return FutureBuilder<Map<String, dynamic>>(
                future: _getPackageDetails(doc), // <-- เรียกฟังก์ชันใหม่
                builder: (context, detailSnapshot) {
                  // สถานะ: กำลังโหลด (แสดง Card โครงร่าง)
                  if (detailSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return _buildPackageCard(
                      packageId: doc.id,
                      itemDescription: "กำลังโหลด...",
                      personLabel: "ผู้รับ:",
                      personName: "...",
                      personPhone: "...",
                      address: "...",
                      status: "...",
                      riderName: "...", // 👈
                      riderPhone: "...", // 👈
                      imageUrl: "", // ยังไม่โหลดรูป
                    );
                  }

                  // สถานะ: Error
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

                  // สถานะ: สำเร็จ
                  if (detailSnapshot.hasData) {
                    var item = detailSnapshot.data!;

                    return _buildPackageCard(
                      packageId: item['packageId'],
                      itemDescription: item['itemDescription'],
                      personLabel: "ผู้รับ:",
                      personName: item['receiverName'],
                      personPhone: item['receiverPhone'],
                      address: item['address'],
                      status: item['status'],
                      riderName: item['riderName'], // 👈 จะแสดงชื่อ Rider
                      riderPhone: item['riderPhone'], // 👈 จะแสดงเบอร์ Rider
                      imageUrl: item['imageUrl'],
                    );
                  }

                  return SizedBox.shrink(); // กรณีไม่คาดคิด
                },
              );
              // --- สิ้นสุด FutureBuilder ---
            },
          );
        },
      ),
    );
  }

  // --- ส่วน Widget ที่เหลือ (EmptyState, PackageCard, InfoRow) ---
  // --- ไม่ต้องแก้ไข ใช้โค้ดเดิมของคุณได้เลย ---

  Widget _buildEmptyState() {
    // ... (โค้ดส่วนนี้เหมือนเดิม) ...
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
            "คุณยังไม่มีรายการที่จะได้รับ",
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
    required String imageUrl,
  }) {
    // ... (โค้ดส่วนนี้เหมือนเดิม) ...
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
          // --- 4. เพิ่ม Widget สำหรับแสดงรูปภาพ ---
          if (imageUrl.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Image.network(
                  imageUrl,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      height: 180,
                      alignment: Alignment.center,
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 180,
                      alignment: Alignment.center,
                      color: Colors.grey[200],
                      child: Icon(
                        Icons.image_not_supported_rounded,
                        color: Colors.grey[400],
                        size: 50,
                      ),
                    );
                  },
                ),
              ),
            ),

          // --- สิ้นสุดส่วนรูปภาพ ---
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
          // ⭐️⭐️ นี่คือแถวที่จะแสดงข้อมูล Rider ที่ดึงมาใหม่ ⭐️⭐️
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
    // ... (โค้ดส่วนนี้เหมือนเดิม) ...
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
    // ... (โค้ดส่วนนี้เหมือนเดิม) ...
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
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 15,
                      color: valueColor ?? Colors.black,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                  ),
                ),
                const SizedBox(width: 8),
                if (phone != 'N/A')
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.phone_in_talk_rounded,
                        color: Colors.green.shade600,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          phone,
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.black54,
                          ),
                          overflow: TextOverflow.ellipsis,
                          softWrap: false,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
