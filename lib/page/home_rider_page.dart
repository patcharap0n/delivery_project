import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;

class HomeRider extends StatefulWidget {
  final String riderId;

  const HomeRider({super.key, required this.riderId});

  @override
  State<HomeRider> createState() => _HomeRiderState();
}

class _HomeRiderState extends State<HomeRider> {
  String? riderGreetingName;
  String? riderName;
  String? riderImageUrl;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRiderData();
  }

  /// โหลดข้อมูล Rider จาก Firestore Database
  Future<void> _fetchRiderData() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('riders')
          .doc(widget.riderId)
          .get();

      if (!snapshot.exists) throw Exception("ไม่พบ Rider");

      final data = snapshot.data() as Map<String, dynamic>;
      final String? urlFromFirestore = data['RiderImageUrl'];
      print("🔗 RiderImageUrl: $riderImageUrl");
      if (mounted) {
        setState(() {
          riderName = data['Name'] ?? "Rider";
          riderGreetingName = data['Name'] ?? "Rider";
          riderImageUrl =
              (urlFromFirestore != null && urlFromFirestore.isNotEmpty)
              ? urlFromFirestore
              : _getDefaultImageUrl();
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching rider data: $e");
      if (mounted) {
        setState(() {
          riderName = "เกิดข้อผิดพลาด";
          riderGreetingName = "Rider";
          riderImageUrl = _getDefaultImageUrl();
          _isLoading = false;
        });
      }
    }
  }

  /// URL รูป default กรณีไม่เจอหรือโหลดผิดพลาด
  String _getDefaultImageUrl() {
    return 'https://static.wikia.nocookie.net/minecraft/images/f/fe/Villager_face.png/revision/latest';
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF005FFF);

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
          ),
        ),
      );
    }

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
                const Text(
                  "สวัสดี Rider",
                  style: TextStyle(
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
                _buildWelcomeBanner(primaryColor, riderName!, riderImageUrl!),
                const SizedBox(height: 20),
                _buildRiderNavigationButtons(context, primaryColor),
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
            child: ClipOval(
              child: Image.network(
                riderImageUrl ?? _getDefaultImageUrl(),
                width: 64,
                height: 64,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  print("❌ โหลดรูปไม่สำเร็จ: $error");
                  return Image.network(_getDefaultImageUrl());
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  );
                },
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
              print("ไปหน้างานที่ทำอยู่");
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
}
