import 'package:flutter/material.dart';

class HomeRider extends StatelessWidget {
  // --- ตัวแปรสำหรับ Backend นำไปต่อยอด ---
  final String riderGreetingName = "Rider"; // "สวัสดี Rider"
  final String riderName = "tun tung tung"; // ชื่อใน Banner
  final String riderImageUrl = 
      "https://static.wikia.nocookie.net/minecraft/images/f/fe/Villager_face.png/revision/latest"; // รูปโปรไฟล์ (ใช้ URL ชั่วคราว)
  // ------------------------------------

  const HomeRider({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF005FFF); // สีหลัก

    return Scaffold(
      backgroundColor: Colors.white,
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
                  "สวัสดี $riderGreetingName", // <-- ใช้ตัวแปร
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "ขอให้ทุกการเดินทางของคุณปลอดภัย มีแต่ความสุขและราบรื่น",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // --- Banner สีน้ำเงิน ---
                _buildWelcomeBanner(
                  primaryColor,
                  riderName,    // <-- ใช้ตัวแปร
                  riderImageUrl // <-- ใช้ตัวแปร
                ),
                
                const SizedBox(height: 20),

                // --- ปุ่มเมนู 2 ปุ่ม (ของ Rider) ---
                _buildRiderNavigationButtons(context, primaryColor),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper Widget 1: Banner สีน้ำเงิน
  Widget _buildWelcomeBanner(Color primaryColor, String userName, String imageUrl) {
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
                  "สวัสดี $userName", // <-- ใช้ตัวแปร
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
          CircleAvatar(
            radius: 32,
            backgroundColor: Colors.white,
            // ใช้ NetworkImage สำหรับ URL
            // หรือเปลี่ยนเป็น AssetImage ถ้ามีรูปในโปรเจกต์
            backgroundImage: NetworkImage(imageUrl), 
          ),
        ],
      ),
    );
  }

  // Helper Widget 2: ปุ่มเมนู 2 ปุ่ม (สำหรับ Rider)
  Widget _buildRiderNavigationButtons(BuildContext context, Color primaryColor) {
    return Row(
      children: [
        Expanded(
          child: _buildMenuButton(
            context: context,
            label: "งานใหม่",
            primaryColor: primaryColor,
            onPressed: () {
              // TODO: ไปยังหน้า "แสดงรายการงานใหม่"
              print("ไปหน้างานใหม่");
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
              // TODO: ไปยังหน้า "งานที่กำลังทำ" (ถ้ามี)
              print("ไปหน้างานที่ทำอยู่");
            },
          ),
        ),
      ],
    );
  }

  // Helper Widget 3: ปุ่มที่ใช้ซ้ำ
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
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}