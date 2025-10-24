import 'package:flutter/material.dart';

class EmptyStatePage extends StatelessWidget {
  
  // --- ตัวแปรสำหรับรับค่าจากหน้าก่อนหน้า ---
  // เพื่อให้หน้านี้ใช้ซ้ำได้
  final String appBarTitle; 

  const EmptyStatePage({
    super.key, 
    required this.appBarTitle, // บังคับให้หน้าที่เรียกใช้ ต้องส่ง title มา
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        // 1. ลูกศรย้อนกลับ
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        // 2. ชื่อหัวข้อ (จะเปลี่ยนไปตามที่ส่งมา)
        title: Text(
          appBarTitle,
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
      ),
      // 3. เนื้อหาตรงกลาง
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 4. ไอคอนรูประฆัง (เหมือนในรูป)
            Icon(
              Icons.notifications_none_rounded,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            // 5. ข้อความ
            Text(
              "คุณไม่มีการแจ้งเตือน", // ในรูปใช้คำนี้
              // หรือจะเปลี่ยนเป็น "คุณยังไม่มีรายการ" ก็ได้
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}