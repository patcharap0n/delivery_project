import 'package:delivery/page/LoginPage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // <-- 1. Import Firestore

// --- Import หน้าใหม่เข้ามา ---
import 'package:delivery/page/new_jobs_page.dart';
import 'package:delivery/page/current_job_page.dart';
import 'package:delivery/page/edit_rider_profile_page.dart';
// (เช็ค Path ให้ถูกต้อง)

// --- MODIFIED --- (เปลี่ยนเป็น StatefulWidget)
class HomeRider extends StatefulWidget {
  final String uid; // uid ของ Rider
  const HomeRider({super.key, required this.uid});

  @override
  State<HomeRider> createState() => _HomeRiderState();
}

class _HomeRiderState extends State<HomeRider> {
  // --- END MODIFIED ---

  // --- 2. ย้ายตัวแปรมาไว้ใน State ---
  String riderGreetingName = "Rider"; // ค่าเริ่มต้น
  String riderName = "Rider"; // ค่าเริ่มต้น
  String riderImageUrl =
      "https://static.wikia.nocookie.net/minecraft_gamepedia/images/f/fe/Villager_face.png"; // URL เริ่มต้นใหม่ (อันเก่าเสีย)
  // --- END ---

  // --- 3. เพิ่ม initState และ _loadUserData ---
  @override
  void initState() {
    super.initState();
    _loadUserData(); // เรียกฟังก์ชันดึงข้อมูลตอนเริ่มต้น
  }

  Future<void> _loadUserData() async {
    try {
      var db = FirebaseFirestore.instance;
      // ดึงข้อมูลจาก Collection "User" (สมมติว่า Rider เก็บใน Collection เดียวกัน)
      var userRef = db.collection('User');

      final userdata = await userRef.doc(widget.uid).get(); // ใช้ widget.uid

      if (userdata.exists) {
        final data = userdata.data();

        // ดึงชื่อ (ปรับ Field ตาม Firestore ของคุณ)
        final firstName = data?['First_name'] ?? 'Rider';
        final lastName = data?['Last_name'] ?? '';

        // ดึง URL รูปภาพ (ปรับ Field ตาม Firestore ของคุณ)
        final imageUrlFromDb = data?['Image'];

        setState(() {
          riderName = "$firstName $lastName".trim();
          riderGreetingName = firstName;
          if (imageUrlFromDb != null && imageUrlFromDb.isNotEmpty) {
            riderImageUrl = imageUrlFromDb;
          }
        });
      }
    } catch (e) {
      debugPrint("❌ เกิดข้อผิดพลาดในการดึงข้อมูล Rider: $e");
    }
  }
  // --- END ---

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF005FFF); // สีหลัก

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          "หน้าหลัก Rider",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black),
            tooltip: 'กลับไปหน้า Login',
            onPressed: () {
              Get.offAll(() => const LoginPage());
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                Text(
                  "สวัสดี $riderGreetingName", // <-- ใช้ตัวแปร State
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "ขอให้ทุกการเดินทางของคุณปลอดภัย มีแต่ความสุขและราบรื่น",
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                _buildWelcomeBanner(
                  primaryColor,
                  riderName, // <-- ใช้ตัวแปร State
                  riderImageUrl, // <-- ใช้ตัวแปร State
                ),
                const SizedBox(height: 20),
                _buildRiderNavigationButtons(context, primaryColor),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Helper Widgets (ย้ายมาอยู่ใน State) ---
  Widget _buildWelcomeBanner(
    Color primaryColor,
    String userName, // (เปลี่ยนชื่อ parameter เป็น userName เพื่อให้ใช้ซ้ำได้)
    String imageUrl,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: primaryColor,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "สวัสดี $userName", // <-- ใช้ parameter
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                const Text(
                  "เราเชื่อว่าคุณมีช่วงเวลาดีๆ",
                  style: TextStyle(fontSize: 14, color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          GestureDetector(
            onTap: () {
              // --- 4. MODIFIED --- (ส่ง uid ไปด้วย)
              Get.to(() => EditRiderProfilePage(uid: widget.uid));
              // --- END MODIFIED ---
            },
            child: CircleAvatar(
              radius: 32,
              backgroundColor: Colors.white,
              // ใช้ Image.network พร้อม errorBuilder
              child: ClipOval(
                child: Image.network(
                  imageUrl, // <-- ใช้ parameter
                  fit: BoxFit.cover,
                  width: 64,
                  height: 64,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.person, // ไอคอนเริ่มต้นถ้าไม่มีรูป
                      size: 40,
                      color: primaryColor,
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiderNavigationButtons(
    BuildContext context,
    Color primaryColor,
  ) {
    return Row(
      children: [
        Expanded(
          child: _buildMenuButton(
            context: context,
            label: "งานใหม่",
            primaryColor: primaryColor,
            onPressed: () {
              // --- 5. MODIFIED --- (ส่ง uid ไปด้วย)
              Get.to(() => NewJobsPage(uid: widget.uid));
              // --- END MODIFIED ---
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildMenuButton(
            context: context,
            label: "งานที่ทำอยู่",
            primaryColor: primaryColor,
            onPressed: () {
              // --- 6. MODIFIED --- (ส่ง uid ไปด้วย)
              Get.to(() => CurrentJobPage(uid: widget.uid));
              // --- END MODIFIED ---
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMenuButton({
    required BuildContext context,
    required String label,
    required Color primaryColor,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: primaryColor,
        side: BorderSide(color: Colors.grey[300]!),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    );
  }
  // --- END ---
}