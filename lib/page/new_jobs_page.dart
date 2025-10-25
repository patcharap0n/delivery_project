import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:delivery/page/current_job_page.dart';
import 'package:latlong2/latlong.dart'
    as latlong2; // +++ 1. เพิ่ม Import นี้ +++

class NewJobsPage extends StatefulWidget {
  final String uid;
  NewJobsPage({super.key, required this.uid});

  @override
  State<NewJobsPage> createState() => _NewJobsPageState();
}

class _NewJobsPageState extends State<NewJobsPage> {
  late final String _currentRiderId;
  late final Stream<QuerySnapshot> _newJobsStream;

  @override
  void initState() {
    super.initState();
    _currentRiderId = widget.uid;

    _newJobsStream = FirebaseFirestore.instance
        .collection('shipment')
        .where('status', isEqualTo: 'pending')
        .snapshots();
  }

  // (ส่วน _acceptJob ของคุณเหมือนเดิม ไม่ได้แก้ไข)
  Future<void> _acceptJob(String shipmentId) async {
    Get.dialog(
      AlertDialog(
        title: const Text('ยืนยันการรับงาน'),
        content: const Text('คุณต้องการรับงานนี้ใช่หรือไม่?'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('ยกเลิก')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () async {
              Get.back(); // ปิด dialog
              try {
                final db = FirebaseFirestore.instance;
                final riderId = widget.uid;

                // ✅ 1. ตรวจว่างานเก่าของ Rider ยังไม่เสร็จไหม
                final activeJobs = await db
                    .collection('shipment')
                    .where('riderId', isEqualTo: riderId)
                    .where('status', whereIn: ['accepted', 'inTransit'])
                    .get();

                if (activeJobs.docs.isNotEmpty) {
                  Get.snackbar(
                    "ไม่สามารถรับงานใหม่ได้",
                    "กรุณาส่งงานเดิมให้เสร็จก่อนรับงานใหม่",
                    backgroundColor: Colors.orange,
                    colorText: Colors.white,
                  );
                  return;
                }

                // ✅ 2. ตรวจว่างานนี้ยังว่างอยู่หรือไม่
                final shipmentRef = db.collection('shipment').doc(shipmentId);
                final snapshot = await shipmentRef.get();
                if (!snapshot.exists) {
                  Get.snackbar("ข้อผิดพลาด", "ไม่พบน้ำงานนี้ในระบบ");
                  return;
                }

                final data = snapshot.data()!;
                if (data['status'] != 'pending') {
                  Get.snackbar(
                    "งานนี้ถูกจับไปแล้ว",
                    "ไม่สามารถรับงานนี้ได้อีก",
                  );
                  return;
                }

                // ✅ 3. อัปเดตสถานะงานเป็น accepted
                WriteBatch batch = db.batch();

                batch.update(shipmentRef, {
                  'status': 'accepted',
                  'riderId': riderId,
                  'acceptedAt': FieldValue.serverTimestamp(),
                });

                batch.set(
                  db.collection('rider_locations').doc(riderId),
                  {
                    'currentJobId': shipmentId,
                    'lastUpdated': FieldValue.serverTimestamp(),
                  },
                  SetOptions(merge: true),
                );

                await batch.commit();

                Get.snackbar("สำเร็จ", "รับงานเรียบร้อยแล้ว");
                Get.off(() => CurrentJobPage(uid: widget.uid));
              } catch (e) {
                Get.snackbar("เกิดข้อผิดพลาด", e.toString());
              }
            },
            child: const Text('ยืนยัน', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // +++ 2. เพิ่มฟังก์ชัน _parseLatLng +++
  // (ฟังก์ชันนี้ใช้แปลง "16.123, 103.456" ให้เป็นพิกัด)
  latlong2.LatLng? _parseLatLng(String? latLngString) {
    if (latLngString == null) return null;
    final latLngParts = latLngString.split(',');
    if (latLngParts.length == 2) {
      final lat = double.tryParse(latLngParts[0].trim());
      final lng = double.tryParse(latLngParts[1].trim());
      if (lat != null && lng != null) {
        return latlong2.LatLng(lat, lng);
      }
    }
    return null;
  }

  // +++ 3. แก้ไขฟังก์ชัน getShipmentDetails +++
  Future<Map<String, dynamic>> getShipmentDetails(
    DocumentSnapshot shipmentDoc,
  ) async {
    var data = shipmentDoc.data() as Map<String, dynamic>;
    final db = FirebaseFirestore.instance;

    // 1. ดึงข้อมูลพื้นฐาน
    String packageId = shipmentDoc.id;
    String itemDesc = data['details'] ?? 'N/A';
    String jobId = data['receiverAddress'] ?? 'N/A';

    // 2. ดึงชื่อ (สำหรับงานใหม่)
    String senderName = data['senderName'] ?? 'N/A';
    String receiverName = data['receiverName'] ?? 'N/A';

    // 3. ดึง ID (สำหรับงานเก่า)
    String? senderId = data['senderId'];
    String? receiverId = data['receiverId'];

    // +++ 4. แก้ไขส่วนระยะทาง +++
    double distance =
        data['distance'] ?? 0.0; // 4.1 พยายามดึงระยะทางที่บันทึกไว้

    if (distance == 0.0) {
      // 4.2 ถ้าไม่มี (หรืองานเก่า) ให้คำนวณ
      String? senderAddrStr = data['senderAddress'];
      String? receiverAddrStr = data['receiverAddress'];

      // ใช้ฟังก์ชัน _parseLatLng ที่เราเพิ่ม
      final latlong2.LatLng? senderPos = _parseLatLng(senderAddrStr);
      final latlong2.LatLng? receiverPos = _parseLatLng(receiverAddrStr);

      if (senderPos != null && receiverPos != null) {
        final latlong2.Distance distanceCalc = latlong2.Distance();
        double distanceInMeters = distanceCalc(senderPos, receiverPos);
        distance = distanceInMeters / 1000.0; // แปลงเป็นกิโลเมตร
      }
    }
    // +++ จบส่วนแก้ไขระยะทาง +++

    // 5. ค้นหาชื่อ (ถ้าจำเป็น) (โค้ดส่วนนี้เหมือนเดิม)
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
        }
      }

      if ((receiverName == 'N/A' || receiverName.isEmpty) &&
          receiverId != null) {
        DocumentSnapshot receiverDoc = await db
            .collection('User')
            .doc(receiverId)
            .get();
        if (receiverDoc.exists) {
          var receiverData = receiverDoc.data() as Map<String, dynamic>;
          final firstName = receiverData['First_name'] ?? '';
          final lastName = receiverData['Last_name'] ?? '';
          receiverName = "$firstName $lastName".trim();
        }
      }
    } catch (e) {
      print("Error looking up names: $e");
    }

    // 6. คืนข้อมูล
    return {
      'packageId': packageId,
      'itemDesc': itemDesc,
      'jobId': jobId,
      'senderName': senderName.isEmpty ? 'Sender N/A' : senderName,
      'receiverName': receiverName.isEmpty ? 'Receiver N/A' : receiverName,
      'distance': distance, // <-- คืนค่าระยะทางที่ถูกต้อง (ไม่เป็น 0.0 แล้ว)
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        // (ส่วน AppBar ของคุณเหมือนเดิม)
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          "งานใหม่",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _newJobsStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('เกิดข้อผิดพลาดในการโหลดงาน'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: snapshot.data!.docs.length,
            // +++ 4. แก้ไข itemBuilder ให้ใช้ FutureBuilder +++
            itemBuilder: (context, index) {
              var doc = snapshot.data!.docs[index];
              // (ลบโค้ดที่ดึง data เดิมออก)

              // ใช้ FutureBuilder เพื่อรอข้อมูลชื่อ และ ระยะทาง
              return FutureBuilder<Map<String, dynamic>>(
                future: getShipmentDetails(
                  doc,
                ), // <-- เรียกฟังก์ชันที่แก้ไขแล้ว
                builder: (context, detailSnapshot) {
                  // สถานะ: กำลังค้นหา...
                  if (detailSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return _buildJobCard(
                      packageId: doc.id,
                      jobId: "กำลังโหลด...",
                      itemDescription: "กำลังโหลด...",
                      sender: "...",
                      receiver: "...",
                      distance: 0.0,
                      onAccept: () {},
                    );
                  }

                  // สถานะ: ไม่สำเร็จ
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
                    var details = detailSnapshot.data!;

                    return _buildJobCard(
                      packageId: details['packageId'],
                      jobId: details['jobId'],
                      itemDescription: details['itemDesc'],
                      sender: details['senderName'],
                      receiver: details['receiverName'],
                      distance:
                          details['distance'], // <-- แสดงระยะทางที่ถูกต้อง
                      onAccept: () => _acceptJob(details['packageId']),
                    );
                  }

                  return SizedBox.shrink();
                },
              );
            },
            // +++ สิ้นสุดส่วนที่แก้ไข +++
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    // (ส่วนนี้ของคุณเหมือนเดิม)
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
            "ยังไม่มีงานใหม่",
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildJobCard({
    // (ส่วนนี้ของคุณเหมือนเดิม)
    required String packageId,
    required String jobId,
    required String itemDescription,
    required String sender,
    required String receiver,
    required double distance,
    required VoidCallback onAccept,
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
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Text(
            "งาน #$jobId",
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            label: "สินค้า:",
            value: itemDescription,
            valueColor: primaryText,
          ),
          _buildInfoRow(label: "จาก:", value: sender, valueColor: primaryText),
          _buildInfoRow(label: "ไป:", value: receiver, valueColor: primaryText),
          _buildInfoRow(
            label: "ระยะทาง:",
            value:
                "${distance.toStringAsFixed(1)} km", // <-- จะไม่เป็น 0.0 แล้ว
            valueColor: primaryText,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onAccept,
              icon: const Icon(Icons.check_circle_outline, color: Colors.white),
              label: const Text(
                "รับงาน",
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    // (ส่วนนี้ของคุณเหมือนเดิม)
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2.0),
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
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
