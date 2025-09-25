import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class GPSandMapPage extends StatefulWidget {
  final void Function(LatLng) onPick; // LatLng จาก latlong2
  const GPSandMapPage({super.key, required this.onPick});

  @override
  State<GPSandMapPage> createState() => _GPSandMapPageState();
}

class _GPSandMapPageState extends State<GPSandMapPage> {
  LatLng pickedPosition = LatLng(16.246671, 103.252079); // ค่าเริ่มต้น
  final MapController mapController = MapController();

  // ฟังก์ชันดึงตำแหน่งปัจจุบัน
  Future<void> goToCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('กรุณาอนุญาตเข้าถึงตำแหน่ง')),
        );
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      LatLng currentPos = LatLng(position.latitude, position.longitude);

      setState(() {
        pickedPosition = currentPos;
      });

      mapController.move(currentPos, 17); // เลื่อน Map ไปตำแหน่งปัจจุบัน
    } catch (e) {
      debugPrint('Error getting location: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('เลือกตำแหน่งบนแผนที่')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton.icon(
              onPressed: goToCurrentLocation,
              icon: const Icon(Icons.my_location),
              label: const Text('ไปตำแหน่งปัจจุบัน'),
            ),
          ),
          Expanded(
            child: FlutterMap(
              mapController: mapController,
              options: MapOptions(
                // ไม่ใช้ center หรือ zoom
                maxZoom: 17, // ใช้ zoom ที่ MapOptions ได้
                onTap: (tapPosition, point) {
                  setState(() {
                    pickedPosition = point;
                  });
                },
                initialCenter: pickedPosition, // ใช้ initialCenter แทน center
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                  subdomains: const ['a', 'b', 'c'],
                  userAgentPackageName: 'com.example.delivery',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: pickedPosition,
                      width: 50,
                      height: 50,
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.red,
                        size: 40,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: () {
                widget.onPick(pickedPosition); // ส่ง latlong2.LatLng
                Navigator.pop(context);
              },
              child: const Text('เลือกตำแหน่งนี้'),
            ),
          ),
        ],
      ),
    );
  }
}
