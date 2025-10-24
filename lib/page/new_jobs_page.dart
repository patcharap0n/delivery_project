import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

// (Backend) TODO: Import RiderService และ CurrentJobPage
// import 'package:delivery/services/rider_service.dart';
import 'package:delivery/page/current_job_page.dart';

class NewJobsPage extends StatefulWidget {
  final String uid;
  NewJobsPage({super.key, required this.uid});

  @override
  State<NewJobsPage> createState() => _NewJobsPageState();
}

class _NewJobsPageState extends State<NewJobsPage> {
  // (Backend) TODO: สร้าง Instance ของ RiderService
  // final RiderService _riderService = RiderService();
  final String? _currentRiderId = FirebaseAuth.instance.currentUser?.uid;

  // --- Stream สำหรับดึงงานใหม่ ---
  late final Stream<QuerySnapshot> _newJobsStream;

  @override
  void initState() {
    super.initState();

    debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
    debugPrint("🔍 กำลังสร้าง Query:");
    debugPrint("   Collection: shipment");
    debugPrint("   Where status in ['pending']");
    debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n");

    //   _newJobsStream = FirebaseFirestore.instance
    //       .collection('shipment') // 👈 ให้ตรงกับ Firestore ของคุณ
    //       .where('status', isEqualTo: 'pending') // หรือปรับค่าให้ตรงใน Firestore
    //       .snapshots();
    // }

    _newJobsStream = FirebaseFirestore.instance
        .collection('shipment')
        .where('status', isEqualTo: 'pending')
        // .where('senderId', isNotEqualTo: _currentRiderId) // กัน Rider รับงานตัวเอง (ถ้าจำเป็น)
        .snapshots();
  }

  // --- ฟังก์ชันรับงาน ---
  Future<void> _acceptJob(String shipmentId) async {
    if (_currentRiderId == null) {
      Get.snackbar("ข้อผิดพลาด", "ไม่พบข้อมูล Rider");
      return;
    }

    // 1. แสดง Dialog ยืนยัน
    Get.dialog(
      AlertDialog(
        title: const Text('ยืนยันการรับงาน'),
        content: const Text('คุณต้องการรับงานนี้ใช่หรือไม่?'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('ยกเลิก')),
          ElevatedButton(
            onPressed: () async {
              Get.back(); // ปิด Dialog ก่อน
              // (Backend) TODO: แสดง Loading Indicator
              // Get.dialog(Center(child: CircularProgressIndicator()));

              try {
                // (Backend) TODO: เรียกใช้ Service เพื่อรับงาน (ใช้ Transaction)
                // bool success = await _riderService.acceptJob(shipmentId, _currentRiderId!);
                bool success = true; // --- <<<<<<<<<<<< (จำลองว่าสำเร็จ)

                // Get.back(); // ปิด Loading

                if (success) {
                  Get.snackbar("สำเร็จ", "รับงานเรียบร้อยแล้ว");
                  // ไปยังหน้า CurrentJob และลบหน้า NewJobs ออก
                  Get.off(() => CurrentJobPage(uid: widget.uid));
                } else {
                  // RiderService ควร throw Exception ที่มี message บอกสาเหตุ
                  // Get.snackbar("เกิดข้อผิดพลาด", "ไม่สามารถรับงานได้ (อาจถูกรับไปแล้ว)");
                }
              } catch (e) {
                // Get.back(); // ปิด Loading
                Get.snackbar("เกิดข้อผิดพลาด", e.toString());
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('ยืนยัน', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
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
            return _buildEmptyState(); // แสดงหน้าว่าง
          }

          // แสดงรายการงาน
          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var doc = snapshot.data!.docs[index];
              var data = doc.data() as Map<String, dynamic>? ?? {};

              // (Backend) TODO: ดึงข้อมูลให้ครบถ้วน (อาจต้อง Query เพิ่มเติม)
              String packageId = doc.id;
              String jobId = packageId ?? 'N/A'; // สมมติว่ามี Job ID
              String itemDesc = data['details'] ?? 'N/A';
              String senderName = data['senderName'] ?? 'Sender N/A';
              String receiverName = data['receiverAddress'] ?? 'Receiver N/A';
              double distance =
                  data['distance'] ?? 0.0; // สมมติว่าคำนวณระยะทางมาแล้ว

              return _buildJobCard(
                packageId: packageId,
                jobId: jobId,
                itemDescription: itemDesc,
                sender: senderName,
                receiver: receiverName,
                distance: distance,
                onAccept: () => _acceptJob(packageId),
              );
            },
          );
        },
      ),
    );
  }

  // --- Widget: แสดงหน้าว่าง ---
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
            "ยังไม่มีงานใหม่", // <-- เปลี่ยนข้อความ
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  // --- Widget: การ์ดแสดงข้อมูลงาน ---
  Widget _buildJobCard({
    required String packageId,
    required String jobId,
    required String itemDescription,
    required String sender,
    required String receiver,
    required double distance,
    required VoidCallback onAccept,
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
            value: "${distance.toStringAsFixed(1)} km",
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

  // Helper Widget: แถวข้อความ
  Widget _buildInfoRow({
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
