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

  // ตำแหน่งเริ่มต้น
  final LatLng initialPosition = LatLng(16.246373, 103.251827);

  @override
  void initState() {
    super.initState();

    _jobsStream = FirebaseFirestore.instance
        .collection('shipment')
        .where('riderId', isEqualTo: widget.uid)
        .where('status', isEqualTo: 'accepted')
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
    if (s.isEmpty) return LatLng(16.246373, 103.251827); // default
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
      await Future.delayed(const Duration(seconds: 2)); // จำลองการอัพโหลด
      setState(() => _isUploading = false);
      Get.snackbar("สำเร็จ", "อัปโหลดรูปเรียบร้อย");
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

          List<Marker> markers = [];
          List<LatLng> allPositions = [];

          for (var job in jobs) {
            final data = job.data() as Map<String, dynamic>;
            final senderAddress = data['senderAddress'] ?? '';
            final receiverAddress = data['receiverStateCountry'] ?? '';

            if (senderAddress.isNotEmpty) {
              final senderLatLng = _parseLatLng(senderAddress);
              markers.add(
                Marker(
                  point: LatLng(16.246373, 103.251827),
                  width: 40,
                  height: 40,
                  child: Icon(Icons.location_on, color: Colors.green, size: 40),
                ),
              );
              allPositions.add(senderLatLng);
            }

            if (receiverAddress.isNotEmpty) {
              final receiverLatLng = _parseLatLng(receiverAddress);
              markers.add(
                Marker(
                  point: receiverLatLng,
                  width: 40,
                  height: 40,
                  child: const Icon(
                    Icons.location_on,
                    color: Colors.red,
                    size: 40,
                  ),
                ),
              );
              allPositions.add(receiverLatLng);
            }
          }

          // Rider marker
          LatLng? riderPosition;
          if (riderLat != null && riderLng != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _mapController.move(LatLng(riderLat!, riderLng!), 15); // zoom 15
            });
          }

          // Auto zoom to fit all markers
          if (riderPosition != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _mapController.move(riderPosition!, 15); // zoom 15
            });
          }

          // UI job ตัวแรก
          final jobData = jobs[0].data() as Map<String, dynamic>;
          final jobId = jobs[0].id;
          final itemName = jobData['itemName'] ?? '-';
          final senderAddr = jobData['senderAddress'] ?? '-';
          final receiverAddr = jobData['receiverStateCountry'] ?? '-';
          final receiverName = jobData['receiverAddress'] ?? '-';
          final receiverPhone = jobData['receiverPhone'] ?? '-';
          final status = jobData['status'] ?? '-';

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
                    initialCenter: LatLng(16.246373, 103.251827),
                    initialZoom: 15,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                      userAgentPackageName: 'com.example.delivery', // ต้องใส่
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
                    Text.rich(
                      TextSpan(
                        children: [
                          const TextSpan(
                            text: "สินค้า: ",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextSpan(text: itemName),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text("ที่อยู่สินค้า: $senderAddr"),
                    const SizedBox(height: 4),
                    Text("ที่อยู่ปลายทาง: $receiverAddr"),
                    const SizedBox(height: 4),
                    Text.rich(
                      TextSpan(
                        children: [
                          const TextSpan(
                            text: "ผู้รับ: ",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextSpan(
                            text: "$receiverName ($receiverPhone)",
                            style: const TextStyle(color: Color(0xFF005FFF)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text.rich(
                      TextSpan(
                        children: [
                          const TextSpan(
                            text: "สถานะ: ",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextSpan(
                            text: status,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        SizedBox(
                          height: 36,
                          child: ElevatedButton(
                            onPressed: _isUploading
                                ? null
                                : () => _pickAndUpload(jobId),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade700,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            child: const Text(
                              "อัพโหลด",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          height: 36,
                          child: OutlinedButton(
                            onPressed: null,
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Colors.grey.shade400),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            child: Text(
                              "อัพโหลดเสร็จสิ้น",
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                        const Spacer(),
                        SizedBox(
                          height: 36,
                          child: ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              side: const BorderSide(color: Colors.grey),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            child: const Text(
                              "รับของแล้ว",
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
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
