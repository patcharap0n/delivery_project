import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart'; // สำหรับเช็คระยะทาง
import 'dart:io';

class CurrentJobPage extends StatefulWidget {
  final String uid;
  const CurrentJobPage({super.key, required this.uid});

  @override
  State<CurrentJobPage> createState() => _CurrentJobPageState();
}

class _CurrentJobPageState extends State<CurrentJobPage> {
  final String? _riderId = FirebaseAuth.instance.currentUser?.uid;
  final ImagePicker _picker = ImagePicker();

  // --- Stream สำหรับติดตาม Rider Location (เพื่อเอา currentJobId) ---
  late final Stream<DocumentSnapshot> _riderLocationStream;

  // --- ตัวแปร State สำหรับแผนที่และรูปภาพ ---
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  File? _pickedImageFile;
  bool _isUploading = false; // สถานะกำลังอัปโหลดรูป
  bool _canInteractPickup = false; // อยู่ใกล้จุดรับพอที่จะกดปุ่มได้ไหม
  bool _canInteractDropoff = false; // อยู่ใกล้จุดส่งพอที่จะกดปุ่มได้ไหม

  @override
  void initState() {
    super.initState();
    if (_riderId != null) {
      _riderLocationStream = FirebaseFirestore.instance
          .collection('rider_locations')
          .doc(_riderId)
          .snapshots();
      _checkLocationPermission(); // ขอ Permission Location
    } else {
      _riderLocationStream = const Stream.empty();
    }
  }

  // ขอ Permission Location
  Future<void> _checkLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    // TODO: จัดการกรณี Permission ถูกปฏิเสธถาวร
  }

  // --- ฟังก์ชันอัปเดตสถานะ (รับของ/ส่งของ) ---

  // ฟังก์ชันเลือกและอัปโหลดรูป
  Future<void> _pickAndUploadImage(
    String shipmentId,
    String statusField,
  ) async {
    final pickedFile = await _picker.pickImage(
      source: ImageSource.camera,
    ); // บังคับถ่ายจากกล้อง
    if (pickedFile != null) {
      setState(() {
        _pickedImageFile = File(pickedFile.path);
        _isUploading = true;
      });

      // (Backend) TODO:
      // 1. อัปโหลด _pickedImageFile ไป Firebase Storage
      // 2. เอา URL ที่ได้
      // 3. อัปเดต Firestore: shipments/{shipmentId} -> { statusField: url }
      // String imageUrl = await uploadToStorage(_pickedImageFile, shipmentId, statusField);
      // await FirebaseFirestore.instance.collection('shipments').doc(shipmentId).update({
      //   statusField: imageUrl
      // });
      print("จำลองการอัปโหลดรูปสำหรับ $statusField...");
      await Future.delayed(const Duration(seconds: 2)); // จำลองเวลาอัปโหลด

      setState(() {
        _isUploading = false;
        // ล้างรูปที่เลือก ถ้าต้องการ
        // _pickedImageFile = null;
      });
      Get.snackbar("สำเร็จ", "อัปโหลดรูปภาพเรียบร้อย");
    }
  }

  // กด "รับของแล้ว" (หลังจากถ่ายรูปจุด Pickup)
  Future<void> _markAsPickedUp(String shipmentId) async {
    // (Backend) TODO: ตรวจสอบว่ารูป Pickup ถูกอัปโหลดหรือยัง
    // (Backend) TODO: เช็คระยะทางอีกครั้งก่อนกด

    // (Backend) TODO: ใช้ Transaction เพื่อป้องกันปัญหา
    // try {
    //   await FirebaseFirestore.instance.collection('shipments').doc(shipmentId).update({
    //     'status': 'inTransit' // [3]
    //   });
    //   Get.snackbar("สำเร็จ", "อัปเดตสถานะ: กำลังไปส่ง");
    // } catch (e) { Get.snackbar("ผิดพลาด", "ไม่สามารถอัปเดตสถานะได้"); }
    print("กดรับของแล้ว");
    Get.snackbar("จำลอง", "อัปเดตสถานะเป็น 'inTransit'");
  }

  // กด "ส่งของแล้ว" (หลังจากถ่ายรูปจุด Dropoff)
  Future<void> _markAsDelivered(String shipmentId) async {
    // (Backend) TODO: ตรวจสอบว่ารูป Delivery ถูกอัปโหลดหรือยัง
    // (Backend) TODO: เช็คระยะทางอีกครั้งก่อนกด

    // (Backend) TODO: ใช้ Transaction เพื่ออัปเดต 2 ที่
    // try {
    //   WriteBatch batch = FirebaseFirestore.instance.batch();
    //   // 1. อัปเดต Shipment
    //   batch.update(FirebaseFirestore.instance.collection('shipments').doc(shipmentId), {
    //     'status': 'delivered' // [4]
    //   });
    //   // 2. อัปเดต Rider Location ให้ว่าง
    //   batch.update(FirebaseFirestore.instance.collection('rider_locations').doc(_riderId!), {
    //     'currentJobId': null
    //   });
    //   await batch.commit();
    //   Get.snackbar("สำเร็จ", "ส่งสินค้าเรียบร้อยแล้ว!");
    //   // หน้านี้จะเปลี่ยนเป็น Empty State เองเพราะ currentJobId เป็น null แล้ว
    // } catch (e) { Get.snackbar("ผิดพลาด", "ไม่สามารถอัปเดตสถานะได้"); }
    print("กดส่งของแล้ว");
    Get.snackbar("จำลอง", "อัปเดตสถานะเป็น 'delivered' และ Rider ว่าง");
    // จำลองการเคลียร์ Job ID (เพื่อให้ UI กลับไป Empty State)
    // ในแอปจริง StreamBuilder จะจัดการให้เอง
    // await FirebaseFirestore.instance.collection('rider_locations').doc(_riderId!).update({'currentJobId': null});
  }

  // --- ฟังก์ชันเช็คระยะทาง ---
  // (ฟังก์ชันนี้ควรถูกเรียกใช้เป็นระยะๆ หรือเมื่อตำแหน่ง Rider เปลี่ยน)
  Future<void> _checkProximity(GeoPoint pickupGeo, GeoPoint dropoffGeo) async {
    try {
      Position currentPosition = await Geolocator.getCurrentPosition();
      double distanceToPickup = Geolocator.distanceBetween(
        currentPosition.latitude,
        currentPosition.longitude,
        pickupGeo.latitude,
        pickupGeo.longitude,
      );
      double distanceToDropoff = Geolocator.distanceBetween(
        currentPosition.latitude,
        currentPosition.longitude,
        dropoffGeo.latitude,
        dropoffGeo.longitude,
      );

      setState(() {
        _canInteractPickup = distanceToPickup <= 20; // อยู่ในระยะ 20 เมตร
        _canInteractDropoff = distanceToDropoff <= 20;
      });
    } catch (e) {
      print("Error getting current location: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_riderId == null) {
      // กรณีร้ายแรง: ไม่ควรเกิดขึ้นถ้า Login ถูกต้อง
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text("ไม่พบข้อมูล Rider")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          "งานที่ทำอยู่",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _riderLocationStream,
        builder: (context, riderSnapshot) {
          if (riderSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (riderSnapshot.hasError ||
              !riderSnapshot.hasData ||
              !riderSnapshot.data!.exists) {
            return _buildEmptyState("ไม่สามารถโหลดข้อมูล Rider ได้");
          }

          var riderData =
              riderSnapshot.data!.data() as Map<String, dynamic>? ?? {};
          String? currentJobId = riderData['currentJobId'];

          // --- ถ้า Rider ไม่มีงาน ---
          if (currentJobId == null) {
            return _buildEmptyState("คุณยังไม่มีงานที่ต้องทำ"); // แสดงหน้าว่าง
          }

          // --- ถ้า Rider มีงาน ---
          // ใช้ StreamBuilder อีกชั้นเพื่อดึงข้อมูล Shipment
          return StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('shipments')
                .doc(currentJobId)
                .snapshots(),
            builder: (context, jobSnapshot) {
              if (jobSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (jobSnapshot.hasError ||
                  !jobSnapshot.hasData ||
                  !jobSnapshot.data!.exists) {
                return const Center(child: Text("ไม่สามารถโหลดข้อมูลงานได้"));
              }

              var jobData =
                  jobSnapshot.data!.data() as Map<String, dynamic>? ?? {};
              String status = jobData['status'] ?? 'unknown';

              // (Backend) TODO: ดึงข้อมูลที่อยู่และอื่นๆ ให้ครบ
              GeoPoint pickupGeo =
                  jobData['pickupAddress']?['location'] ?? const GeoPoint(0, 0);
              GeoPoint dropoffGeo =
                  jobData['deliveryAddress']?['location'] ??
                  const GeoPoint(0, 0);
              String pickupAddr =
                  jobData['pickupAddress']?['fullAddress'] ?? 'N/A';
              String dropoffAddr =
                  jobData['deliveryAddress']?['fullAddress'] ?? 'N/A';
              String receiverName = jobData['receiverName'] ?? 'N/A';
              String receiverPhone = jobData['receiverPhone'] ?? 'N/A';
              String itemDesc = jobData['packageDetails'] ?? 'N/A';
              String photoPendingUrl =
                  jobData['photoPendingUrl']; // รูปตอนสร้างงาน
              String photoInTransitUrl =
                  jobData['photoInTransitUrl']; // รูปตอนรับของ
              String photoDeliveredUrl =
                  jobData['photoDeliveredUrl']; // รูปตอนส่งของ

              // (สำคัญ) เช็คระยะทางเป็นระยะ (อาจต้องทำ background task จริงจัง)
              _checkProximity(pickupGeo, dropoffGeo);

              // อัปเดต Markers บนแผนที่
              _markers.clear();
              _markers.add(
                Marker(
                  markerId: const MarkerId('pickup'),
                  position: LatLng(pickupGeo.latitude, pickupGeo.longitude),
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueGreen,
                  ),
                ),
              );
              _markers.add(
                Marker(
                  markerId: const MarkerId('dropoff'),
                  position: LatLng(dropoffGeo.latitude, dropoffGeo.longitude),
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueRed,
                  ),
                ),
              );
              // (Backend) TODO: เพิ่ม Marker ของ Rider (จาก riderData['currentLocation'])

              return Stack(
                children: [
                  // --- แผนที่ ---
                  GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: LatLng(pickupGeo.latitude, pickupGeo.longitude),
                      zoom: 14,
                    ),
                    onMapCreated: (controller) => _mapController = controller,
                    markers: _markers,
                    myLocationEnabled: true, // แสดงตำแหน่ง Rider
                    myLocationButtonEnabled: true,
                  ),
                  // --- Panel รายละเอียด ---
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: _buildDetailsPanel(
                      jobId: currentJobId,
                      status: status,
                      itemDesc: itemDesc,
                      pickupAddr: pickupAddr,
                      dropoffAddr: dropoffAddr,
                      receiverName: receiverName,
                      receiverPhone: receiverPhone,
                      photoInTransitUrl: photoInTransitUrl, // ส่ง URL รูปไปเช็ค
                      photoDeliveredUrl: photoDeliveredUrl,
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  // --- Widget: แสดงหน้าว่าง ---
  Widget _buildEmptyState(String message) {
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
            message,
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  // --- Widget: Panel รายละเอียดด้านล่าง ---
  Widget _buildDetailsPanel({
    required String jobId,
    required String status,
    required String itemDesc,
    required String pickupAddr,
    required String dropoffAddr,
    required String receiverName,
    required String receiverPhone,
    String? photoInTransitUrl,
    String? photoDeliveredUrl,
  }) {
    bool isGoingToPickup = (status == 'accepted');
    bool isGoingToDropoff = (status == 'inTransit');
    bool pickupPhotoUploaded =
        photoInTransitUrl != null && photoInTransitUrl.isNotEmpty;
    bool deliveryPhotoUploaded =
        photoDeliveredUrl != null && photoDeliveredUrl.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24.0),
          topRight: Radius.circular(24.0),
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10),
        ],
        border: Border(
          top: BorderSide(color: Colors.grey.shade300, width: 1.0),
        ),
      ),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Package #$jobId",
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildInfoRow(label: "สินค้า:", value: itemDesc),
          _buildInfoRow(label: "ที่อยู่รับสินค้า:", value: pickupAddr),
          _buildInfoRow(label: "ที่อยู่ปลายทาง:", value: dropoffAddr),
          _buildInfoRowWithIcon(
            label: "ผู้รับ:",
            value: receiverName,
            phone: receiverPhone,
          ),
          _buildInfoRow(
            label: "สถานะ:",
            value: _getStatusText(status),
            valueColor: _getStatusColor(status),
            isBold: true,
          ),

          // --- แสดงรูปที่เลือก (ถ้ามี) ---
          if (_pickedImageFile != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Image.file(
                _pickedImageFile!,
                height: 100,
                fit: BoxFit.cover,
              ),
            ),

          // --- ปุ่ม Actions ---
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // ปุ่มอัปโหลดรูป (Pickup)
              if (isGoingToPickup)
                ElevatedButton.icon(
                  onPressed: _isUploading || !_canInteractPickup
                      ? null
                      : () => _pickAndUploadImage(jobId, 'photoInTransitUrl'),
                  icon: _isUploading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.camera_alt),
                  label: Text(
                    pickupPhotoUploaded
                        ? "อัปโหลด Pickup ใหม่"
                        : "อัปโหลด Pickup",
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey,
                  ),
                ),

              // ปุ่มอัปโหลดรูป (Delivery)
              if (isGoingToDropoff)
                ElevatedButton.icon(
                  onPressed: _isUploading || !_canInteractDropoff
                      ? null
                      : () => _pickAndUploadImage(jobId, 'photoDeliveredUrl'),
                  icon: _isUploading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.camera_alt),
                  label: Text(
                    deliveryPhotoUploaded
                        ? "อัปโหลด Delivery ใหม่"
                        : "อัปโหลด Delivery",
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey,
                  ),
                ),

              // ปุ่มยืนยัน (เปลี่ยนไปตามสถานะ)
              if (isGoingToPickup)
                ElevatedButton(
                  onPressed:
                      _isUploading ||
                          !pickupPhotoUploaded ||
                          !_canInteractPickup
                      ? null
                      : () => _markAsPickedUp(jobId),
                  child: const Text("รับของแล้ว"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey,
                  ),
                ),
              if (isGoingToDropoff)
                ElevatedButton(
                  onPressed:
                      _isUploading ||
                          !deliveryPhotoUploaded ||
                          !_canInteractDropoff
                      ? null
                      : () => _markAsDelivered(jobId),
                  child: const Text("ส่งของแล้ว"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // --- Helper Widgets (เหมือนเดิม + แปลสถานะ) ---
  Widget _buildInfoRow({
    required String label,
    required String value,
    Color? valueColor,
    bool isBold = false,
  }) {
    const Color primaryText = Color(0xFF005FFF);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
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
                color: valueColor ?? primaryText,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
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
    const Color primaryText = Color(0xFF005FFF);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 15, color: Colors.black54),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Wrap(
              // ใช้ Wrap เผื่อหน้าจอเล็ก
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8.0,
              runSpacing: 4.0,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    color: valueColor ?? primaryText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.phone_in_talk_rounded,
                      color: Colors.green.shade600,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      phone,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.black54,
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

  String _getStatusText(String status) {
    switch (status) {
      case 'accepted':
        return '[2] กำลังเดินทางไปรับสินค้า';
      case 'inTransit':
        return '[3] รับสินค้าแล้ว กำลังไปส่ง';
      // เพิ่ม case อื่นๆ ถ้ามี
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'accepted':
        return Colors.orange.shade700;
      case 'inTransit':
        return Colors.blue.shade700;
      default:
        return Colors.grey;
    }
  }
}
