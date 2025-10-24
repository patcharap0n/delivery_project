import 'package:delivery/page/edit_profile_page.dart';
import 'package:delivery/page/received_items_page.dart';
import 'package:delivery/page/transit_items_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:delivery/page/LoginPage.dart'; // (เช็ค Path ให้ถูก)

// --- 1. เพิ่ม Import หน้า EditProfile ---
// (คุณต้องไปสร้างไฟล์ 'package:delivery/page/edit_profile_page.dart' เองนะครับ)
// import 'package:delivery/page/edit_profile_page.dart'; 

class HomeUser extends StatelessWidget {
  // --- คุณสามารถดึงข้อมูลจริงมาแทนที่ตรงนี้ ---
  final String userGreetingName = "User"; // จาก "สวัสดี User"
  final String userName = "tun tung tung"; // จากใน Banner
  final String userImageUrl =
      "https://static.wikia.nocookie.net/minecraft/images/f/fe/Villager_face.png/revision/latest"; // รูป Villager (ใช้ URL ชั่วคราว)
  // ------------------------------------

  const HomeUser({super.key});

  @override
  Widget build(BuildContext context) {
    // สีหลักของแอป (จากในรูป)
    const Color primaryColor = Color(0xFF005FFF);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          "หน้าหลัก",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black),
            tooltip: 'กลับไปหน้า Login', // <-- เปลี่ยนข้อความ
            onPressed: () {
              // --- 3. ใส่คำสั่ง Get.offAll() ที่ปุ่ม onPressed โดยตรง ---
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

                // (เนื้อหา UI ส่วนที่เหลือเหมือนเดิม)

                Text(
                  "สวัสดี $userGreetingName",
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "ทุกการส่งของของคุณ คือรอยยิ้มของคนที่รอรับ",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                _buildWelcomeBanner(primaryColor, userName, userImageUrl),
                const SizedBox(height: 20),
                _buildNavigationButtons(context, primaryColor),
                const SizedBox(height: 20),
                _buildCreateShipmentCard(context, primaryColor),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper Widget 1: Banner สีน้ำเงิน
  Widget _buildWelcomeBanner(
      Color primaryColor, String userName, String imageUrl) {
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
          )
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "สวัสดี $userName",
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
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          
          // --- 2. แก้ไขตรงนี้: หุ้ม CircleAvatar ด้วย GestureDetector ---
          GestureDetector(
            onTap: () {
              // (Backend) TODO: สร้างหน้า EditProfilePage.dart
              Get.to(() => const EditProfilePage()); 
              print("ไปหน้า Edit Profile"); 
            },
            child: CircleAvatar(
              radius: 32,
              backgroundColor: Colors.white,
              backgroundImage: NetworkImage(imageUrl),
            ),
          ),
          // --- สิ้นสุดการแก้ไข ---
        ],
      ),
    );
  }

  // Helper Widget 2: ปุ่มเมนู 2 ปุ่ม
  Widget _buildNavigationButtons(BuildContext context, Color primaryColor) {
    return Row(
      children: [
        Expanded(
          child: _buildMenuButton(
            context: context,
            label: "ของที่กำลังส่ง",
            primaryColor: primaryColor,
            onPressed: () {
              // 2. เปลี่ยนไปหน้า TransitItemsPage
              Get.to(() => const TransitItemsPage());
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildMenuButton(
            context: context,
            label: "ของที่ได้รับ",
            primaryColor: primaryColor,
            onPressed: () {
              // 3. เปลี่ยนไปหน้า ReceivedItemsPage
              Get.to(() => const ReceivedItemsPage());
            },
          ),
        ),
      ],
    );
  }

  // ปุ่มที่ใช้ซ้ำใน _buildNavigationButtons
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
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // Helper Widget 3: การ์ด "ส่งพัสดุ"
  Widget _buildCreateShipmentCard(BuildContext context, Color primaryColor) {
    return GestureDetector(
      onTap: () {
        print("ไปหน้าส่งพัสดุ");
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: Row(
          children: [
            Icon(
              Icons.archive_outlined,
              color: primaryColor,
              size: 44,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "ส่งพัสดุ",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "เรียกรถให้มารับพัสดุหรือส่งพัสดุของคุณ",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}