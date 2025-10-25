import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';

class CurrentJobPage extends StatefulWidget {
  final String uid;
  const CurrentJobPage({super.key, required this.uid});

  @override
  State<CurrentJobPage> createState() => _CurrentJobPageState();
}

class _CurrentJobPageState extends State<CurrentJobPage> {
  final MapController _mapController = MapController();
  final ImagePicker _picker = ImagePicker();

  double? riderLat;
  double? riderLng;
  StreamSubscription<Position>? _positionSub;
  File? _pickedImage;
  bool _isUploading = false;

  late final Stream<QuerySnapshot> _jobsStream;

  final LatLng initialPosition = LatLng(16.246373, 103.251827);

  @override
  void initState() {
    super.initState();

    _jobsStream = FirebaseFirestore.instance
        .collection('shipment')
        .where('riderId', isEqualTo: widget.uid)
        .where('status', whereIn: ['accepted', 'inTransit'])
        .snapshots();

    _listenRiderLocation();
    _startUpdatingLocation();
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    super.dispose();
  }

  void _listenRiderLocation() {
    FirebaseFirestore.instance
        .collection('riders')
        .doc(widget.uid)
        .snapshots()
        .listen((doc) {
          if (doc.exists && doc.data() != null) {
            final data = doc.data()!;
            if (data['currentLocation'] != null) {
              final geo = data['currentLocation'] as GeoPoint;
              setState(() {
                riderLat = geo.latitude;
                riderLng = geo.longitude;
              });
            }
          }
        });
  }

  Future<void> _updateJobStatus(String jobId, String newStatus) async {
    try {
      await FirebaseFirestore.instance.collection('shipment').doc(jobId).update(
        {'status': newStatus, 'updatedAt': FieldValue.serverTimestamp()},
      );

      Get.snackbar(
        "อัปเดตสำเร็จ",
        "สถานะถูกเปลี่ยนเป็น $newStatus แล้ว",
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        "เกิดข้อผิดพลาด",
        e.toString(),
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _startUpdatingLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      Get.snackbar("แจ้งเตือน", "กรุณาเปิด Location Service");
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        Get.snackbar("แจ้งเตือน", "คุณปฏิเสธสิทธิ์ Location");
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      Get.snackbar("แจ้งเตือน", "โปรดอนุญาต Location ใน Settings");
      return;
    }

    _positionSub =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.best,
            distanceFilter: 5,
          ),
        ).listen((pos) {
          FirebaseFirestore.instance
              .collection('riders')
              .doc(widget.uid)
              .update({
                'currentLocation': GeoPoint(pos.latitude, pos.longitude),
                'updatedAt': FieldValue.serverTimestamp(),
              });
        });
  }

  LatLng _parseLatLng(String s) {
    if (s.isEmpty) return LatLng(16.246373, 103.251827);
    final parts = s.split(',');
    if (parts.length != 2) return LatLng(16.246373, 103.251827);

    double? lat = double.tryParse(parts[0].trim());
    double? lng = double.tryParse(parts[1].trim());

    if (lat == null || lng == null) return LatLng(16.246373, 103.251827);

    return LatLng(lat, lng);
  }

  Future<void> _pickAndUpload(String jobId) async {
    final file = await _picker.pickImage(source: ImageSource.camera);
    if (file != null) {
      setState(() {
        _pickedImage = File(file.path);
        _isUploading = true;
      });

      // จำลองการอัปโหลด
      await Future.delayed(const Duration(seconds: 2));

      setState(() => _isUploading = false);
      Get.snackbar("สำเร็จ", "อัปโหลดรูปเรียบร้อย");

      // เมื่ออัปโหลดเสร็จ → เปลี่ยนสถานะเป็น completed
      await _updateJobStatus(jobId, "completed");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("งานที่ทำอยู่"), centerTitle: true),
      body: StreamBuilder<QuerySnapshot>(
        stream: _jobsStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("ยังไม่มีงาน"));
          }

          final jobs = snapshot.data!.docs;
          final jobData = jobs[0].data() as Map<String, dynamic>;
          final jobId = jobs[0].id;

          final itemName = jobData['itemName'] ?? '-';
          final senderAddr = jobData['senderAddress'] ?? '-';
          final receiverAddr = jobData['receiverStateCountry'] ?? '-';
          final receiverName = jobData['receiverAddress'] ?? '-';
          final receiverPhone = jobData['receiverPhone'] ?? '-';
          final status = jobData['status'] ?? '-';

          // Marker map
          List<Marker> markers = [];
          if (senderAddr.isNotEmpty) {
            markers.add(
              Marker(
                point: _parseLatLng(senderAddr),
                width: 40,
                height: 40,
                child: const Icon(
                  Icons.location_on,
                  color: Colors.green,
                  size: 40,
                ),
              ),
            );
          }
          if (receiverAddr.isNotEmpty) {
            markers.add(
              Marker(
                point: _parseLatLng(receiverAddr),
                width: 40,
                height: 40,
                child: const Icon(
                  Icons.location_on,
                  color: Colors.red,
                  size: 40,
                ),
              ),
            );
          }

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (riderLat != null && riderLng != null) {
              _mapController.move(LatLng(riderLat!, riderLng!), 15);
            } else if (markers.isNotEmpty) {
              _mapController.move(markers[0].point, 15);
            }
          });

          return Column(
            children: [
              Expanded(
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    minZoom: 3,
                    maxZoom: 18,
                    initialCenter: initialPosition,
                    initialZoom: 15,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                      userAgentPackageName: 'com.example.delivery',
                    ),
                    MarkerLayer(markers: markers),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: const Offset(0, -3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Package #$jobId",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text("สินค้า: $itemName"),
                    const SizedBox(height: 4),
                    Text("ที่อยู่สินค้า: $senderAddr"),
                    const SizedBox(height: 4),
                    Text("ที่อยู่ปลายทาง: $receiverAddr"),
                    const SizedBox(height: 4),
                    Text("ผู้รับ: $receiverName ($receiverPhone)"),
                    const SizedBox(height: 8),
                    Text(
                      "สถานะ: $status",
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 16),

                    // 🔽 ปุ่มเปลี่ยนตามสถานะ 🔽
                    Row(
                      children: [
                        if (status == "accepted") ...[
                          SizedBox(
                            height: 36,
                            child: ElevatedButton(
                              onPressed: () =>
                                  _updateJobStatus(jobId, "inTransit"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                side: const BorderSide(color: Colors.grey),
                              ),
                              child: const Text(
                                "รับของแล้ว",
                                style: TextStyle(color: Colors.black),
                              ),
                            ),
                          ),
                        ] else if (status == "inTransit") ...[
                          SizedBox(
                            height: 36,
                            child: ElevatedButton(
                              onPressed: _isUploading
                                  ? null
                                  : () async {
                                      await _pickAndUpload(jobId);
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                              ),
                              child: const Text(
                                "ส่งของเสร็จสิ้น",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ] else ...[
                          SizedBox(
                            height: 36,
                            child: OutlinedButton(
                              onPressed: null,
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: Colors.grey.shade400),
                              ),
                              child: Text(
                                "เสร็จสิ้นแล้ว",
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
