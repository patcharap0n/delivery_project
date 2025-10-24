import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class TrackingPage extends StatefulWidget {
  // (Backend) หน้านี้ควรรู้ว่ากำลังติดตามพัสดุชิ้นไหน
  // final String shipmentId;
  // const TrackingPage({super.key, required this.shipmentId});

  const TrackingPage({super.key, required String uid}); // แบบ UI

  @override
  State<TrackingPage> createState() => _TrackingPageState();
}

class _TrackingPageState extends State<TrackingPage> {
  // --- ตัวแปรและ State สำหรับแผนที่ ---
  final Completer<GoogleMapController> _mapController = Completer();

  // (Backend) ข้อมูลตำแหน่ง (ข้อมูลจำลอง)
  // ในแอปจริง ตำแหน่ง Rider (riderLocation) จะต้องมาจาก Stream
  static const LatLng riderLocation = LatLng(
    40.7295,
    -73.9965,
  ); // ตำแหน่ง Rider (NYU)
  static const LatLng pickupLocation = LatLng(
    40.7484,
    -73.9857,
  ); // จุดรับ (Empire State)
  static const LatLng dropoffLocation = LatLng(
    40.7128,
    -74.0060,
  ); // จุดส่ง (City Hall)

  // (Backend) ข้อมูลเส้นทาง (ข้อมูลจำลอง)
  final List<LatLng> _polylineCoordinates = [
    riderLocation,
    const LatLng(40.7390, -73.9912), // จุดระหว่างทาง
    pickupLocation, // ไปถึงจุดรับ
    const LatLng(40.7350, -73.9910), // จุดระหว่างทาง
    dropoffLocation, // ไปถึงจุดส่ง
  ];

  // (Backend) ข้อมูล Markers
  final Set<Marker> _markers = {};

  // (Backend) ข้อมูลเส้นทาง
  final Set<Polyline> _polylines = {};

  // --- ตัวแปรสำหรับข้อมูลพัสดุ (ข้อมูลจำลอง) ---
  final String packageId = "Package #12345";
  final String itemDescription = "เอกสารด่วน";
  final String receiverName = "นายสมชาย";
  final String receiverPhone = "081-xxx-xxxx";
  final String address = "99/1 ถนน A เขต B";
  final String status = "[2] ไรเดอร์กำลังมารับสินค้า";
  final String riderName = "คุณชัย";
  final String riderPhone = "089-xxx-xxxx";
  // --------------------------------------------------

  @override
  void initState() {
    super.initState();
    _setupMapData();
  }

  // (Backend) ฟังก์ชันเตรียมข้อมูลสำหรับแผนที่
  void _setupMapData() {
    setState(() {
      // 1. สร้าง Markers
      _markers.add(
        Marker(
          markerId: const MarkerId("rider"),
          position: riderLocation,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueOrange,
          ),
        ),
      );
      _markers.add(
        Marker(
          markerId: const MarkerId("pickup"),
          position: pickupLocation,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
        ),
      );
      _markers.add(
        Marker(
          markerId: const MarkerId("dropoff"),
          position: dropoffLocation,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );

      // 2. สร้างเส้นทาง (Polyline)
      _polylines.add(
        Polyline(
          polylineId: const PolylineId("route"),
          points: _polylineCoordinates,
          color: Colors.blue.shade700,
          width: 5,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar แบบไม่มี Title (ตามรูป)
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // 1. Google Map (อยู่ล่างสุด)
          GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: CameraPosition(
              target: riderLocation, // ซูมไปที่ Rider
              zoom: 13.5,
            ),
            onMapCreated: (GoogleMapController controller) {
              _mapController.complete(controller);
            },
            markers: _markers, // (Backend) รับค่าจาก Stream
            polylines: _polylines, // (Backend) รับค่าจาก Stream
          ),

          // 2. การ์ดรายละเอียด (อยู่ด้านล่าง)
          Positioned(left: 0, right: 0, bottom: 0, child: _buildDetailsPanel()),
        ],
      ),
    );
  }

  // --- Helper Widget: การ์ดรายละเอียดด้านล่าง ---
  Widget _buildDetailsPanel() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24.0),
          topRight: Radius.circular(24.0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 5,
          ),
        ],
        // เพิ่มเส้นขอบสีเทาด้านบน (ตามรูป)
        border: Border(
          top: BorderSide(color: Colors.grey.shade300, width: 1.0),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min, // ให้ความสูงพอดีกับเนื้อหา
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // (Backend) ใช้ตัวแปรที่ดึงมา
            Text(
              packageId,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 16),

            _buildInfoRow(label: "สินค้า:", value: itemDescription),
            _buildInfoRowWithIcon(
              label: "ผู้รับ:",
              value: receiverName,
              phone: receiverPhone,
            ),
            _buildInfoRow(label: "ที่อยู่:", value: address),

            // สถานะ (ทำให้เด่น)
            _buildInfoRow(
              label: "สถานะ:",
              value: status,
              valueColor: Colors.blue.shade700, // สีน้ำเงิน (ตามรูป)
              isBold: true,
            ),

            _buildInfoRowWithIcon(
              label: "Rider:",
              value: riderName,
              phone: riderPhone,
            ),

            const SizedBox(height: 16), // เว้นวรรค
          ],
        ),
      ),
    );
  }

  // --- Helper Widgets: (ใช้ซ้ำจาก ReceivedItemsPage) ---

  Widget _buildInfoRow({
    required String label,
    required String value,
    Color? valueColor,
    bool isBold = false,
  }) {
    const Color primaryText = Color(0xFF005FFF); // สีน้ำเงิน

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
                color: valueColor ?? primaryText, // สีค่า default เป็นสีน้ำเงิน
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
    const Color primaryText = Color(0xFF005FFF); // สีน้ำเงิน

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
}
