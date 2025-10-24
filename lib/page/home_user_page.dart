import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:delivery/page/LoginPage.dart';
import 'package:delivery/page/create_shipment_page.dart';
import 'package:delivery/page/received_items_page.dart';
import 'package:delivery/page/transit_items_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/get_navigation.dart';

class HomeUser extends StatefulWidget {
  final String uid;
  const HomeUser({super.key, required this.uid});

  @override
  State<HomeUser> createState() => _HomeUserState();
}

class _HomeUserState extends State<HomeUser> {
  String? userGreetingName;
  String? userName;
  String? userImageUrl;
  bool _isLoading = true;

  final String defaultImageUrl =
      'https://static.wikia.nocookie.net/minecraft/images/f/fe/Villager_face.png/revision/latest';

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('User')
          .doc(widget.uid)
          .get();

      if (!snapshot.exists) throw Exception("ไม่พบ User");

      final data = snapshot.data() as Map<String, dynamic>;
      final String? imageUrlFromFirestore = data['Image'];
      if (mounted) {
        setState(() {
          userName =
              "${data['First_name'] ?? 'User'} ${data['Last_name'] ?? ''}"
                  .trim();
          userGreetingName = data['First_name'] ?? 'User';
          userImageUrl =
              (imageUrlFromFirestore != null &&
                  imageUrlFromFirestore.isNotEmpty)
              ? imageUrlFromFirestore
              : defaultImageUrl;
          _isLoading = false;
        });
      }
    } catch (e) {
      print("❌ Error fetching user data: $e");
      if (mounted) {
        setState(() {
          userName = "User";
          userGreetingName = "User";
          userImageUrl = defaultImageUrl;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF005FFF);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          "หน้าหลัก User", // <-- เปลี่ยน Title เล็กน้อย
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

                // --- ส่วนทักทายด้านบน ---
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
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // --- Banner สีน้ำเงิน ---
                _buildWelcomeBanner(primaryColor, userName!, userImageUrl!),

                const SizedBox(height: 20),

                // --- ปุ่มเมนู 2 ปุ่ม ---
                _buildNavigationButtons(context, primaryColor),

                const SizedBox(height: 20),

                // --- การ์ด "ส่งพัสดุ" ---
                _buildCreateShipmentCard(context, primaryColor),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeBanner(
    Color primaryColor,
    String userName,
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
                  style: TextStyle(fontSize: 14, color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          CircleAvatar(
            radius: 32,
            backgroundColor: Colors.white,
            backgroundImage: NetworkImage(imageUrl),
          ),
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
              Get.to(() => ReceivedItemsPage(uid: widget.uid));
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
              Get.to(() => TransitItemsPage(uid: widget.uid));
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
        foregroundColor: primaryColor, // สีตัวอักษร
        side: BorderSide(color: Colors.grey[300]!), // สีขอบ
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

  // Helper Widget 3: การ์ด "ส่งพัสดุ"
  Widget _buildCreateShipmentCard(BuildContext context, Color primaryColor) {
    return GestureDetector(
      onTap: () {
        // 12. แก้จาก this.uid เป็น widget.uid
        Get.to(() => CreateShipmentPage(uid: widget.uid));
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
              Icons.archive_outlined, // Icon รูปกล่อง
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
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
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
