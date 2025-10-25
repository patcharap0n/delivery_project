import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';

class CreateShipmentPage extends StatefulWidget {
  final String uid;

  const CreateShipmentPage({super.key, required this.uid});

  @override
  State<CreateShipmentPage> createState() => _CreateShipmentPageState();
}

class _CreateShipmentPageState extends State<CreateShipmentPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _senderPhoneController = TextEditingController();
  List<String> _senderSavedAddresses = [];
  String? _selectedSenderAddress;

  final TextEditingController _receiverPhoneController =
      TextEditingController();
  final TextEditingController _receiverAddressController =
      TextEditingController();
  final TextEditingController _receiverStateCountryController =
      TextEditingController();
  final TextEditingController _receiverOtherController =
      TextEditingController();
  List<String> _receiverSavedAddresses = [];
  String? _foundReceiverId;

  String? _selectedAddressForMap;

  final TextEditingController _packageQuantityController =
      TextEditingController();
  final TextEditingController _packageDetailsController =
      TextEditingController();
  final TextEditingController _packageNotesController = TextEditingController();

  File? _pickedImage;
  bool _isUploadFinished = false;
  bool _isSubmitting = false;
  bool _isSearchingReceiver = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadAllReceivers();
  }

  Future<void> _loadUserData() async {
    try {
      final db = FirebaseFirestore.instance;
      final senderDoc = await db.collection('User').doc(widget.uid).get();
      if (senderDoc.exists) {
        final senderData = senderDoc.data()!;
        setState(() {
          _senderPhoneController.text = senderData['Phone'] ?? '';
          _senderSavedAddresses = List<String>.from(senderData['addr'] ?? []);
          if (_senderSavedAddresses.isNotEmpty) {
            _selectedSenderAddress = _senderSavedAddresses.first;
          }
        });
      }
    } catch (e) {
      debugPrint("❌ Load sender error: $e");
    }
  }

  Future<void> _loadAllReceivers() async {
    try {
      final db = FirebaseFirestore.instance;
      final querySnapshot = await db.collection('User').get();

      List<String> tempAllAddresses = [];

      for (var doc in querySnapshot.docs) {
        final userData = doc.data();
        final firstName = userData['First_name'] ?? '';
        final lastName = userData['Last_name'] ?? '';
        final fullName = "$firstName $lastName".trim();
        final addresses = List<String>.from(userData['addr'] ?? []);

        for (var address in addresses) {
          if (address.isNotEmpty) {
            tempAllAddresses.add("$fullName\n$address");
            _receiverAddressController.text = fullName;
            _receiverStateCountryController.text = address;
          }
        }
      }

      setState(() {
        _receiverSavedAddresses = tempAllAddresses;
      });
    } catch (e) {
      debugPrint("❌ โหลดข้อมูลผู้รับทั้งหมดผิดพลาด: $e");
    }
  }

  Future<void> _searchReceiverByPhone() async {
    final phone = _receiverPhoneController.text.trim();
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("กรุณาป้อนเบอร์โทรศัพท์เพื่อค้นหา")),
      );
      return;
    }

    setState(() {
      _isSearchingReceiver = true;
      _receiverSavedAddresses = [];
      _receiverAddressController.clear();
      _receiverStateCountryController.clear();
      _foundReceiverId = null;
    });

    try {
      final db = FirebaseFirestore.instance;
      final querySnapshot = await db
          .collection('User')
          .where('Phone', isEqualTo: phone)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("ไม่พบผู้ใช้จากเบอร์โทรนี้")),
        );
      } else {
        final userDoc = querySnapshot.docs.first;
        final userData = userDoc.data();
        _foundReceiverId = userDoc.id;

        final firstName = userData['First_name'] ?? '';
        final lastName = userData['Last_name'] ?? '';
        final fullName = "$firstName $lastName".trim();
        final addresses = List<String>.from(userData['addr'] ?? []);

        List<String> tempFoundAddresses = [];
        for (var address in addresses) {
          if (address.isNotEmpty) {
            tempFoundAddresses.add("$fullName \n $address");
          }
        }

        setState(() {
          _receiverSavedAddresses = tempFoundAddresses;
          if (addresses.isNotEmpty) {
            _receiverAddressController.text = fullName;
            _receiverStateCountryController.text = addresses.first;
          }
        });

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("✅ พบข้อมูลผู้รับ: $fullName")));
      }
    } catch (e) {
      debugPrint("❌ ค้นหาผู้รับผิดพลาด: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("เกิดข้อผิดพลาดในการค้นหา")));
    } finally {
      setState(() {
        _isSearchingReceiver = false;
      });
    }
  }

  Future<void> _pickImageFromCamera() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        _pickedImage = File(pickedFile.path);
        _isUploadFinished = true;
      });
    }
  }

  Future<void> _onConfirmShipment() async {
    if (!_formKey.currentState!.validate()) return;

    if (_pickedImage == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("กรุณาอัปโหลดรูปภาพพัสดุ")));
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final shipmentData = {
        'senderId': widget.uid,
        'receiverId': _foundReceiverId,
        'senderPhone': _senderPhoneController.text,
        'senderAddress': _selectedSenderAddress,
        'receiverAddress': _receiverAddressController.text,
        'receiverStateCountry': _receiverStateCountryController.text,
        'receiverOther': _receiverOtherController.text,
        'quantity': _packageQuantityController.text,
        'details': _packageDetailsController.text,
        'notes': _packageNotesController.text,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending',
      };

      await FirebaseFirestore.instance.collection('shipment').add(shipmentData);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("✅ ส่งข้อมูลสำเร็จ")));

      Navigator.pop(context);
    } catch (e) {
      debugPrint("❌ เกิดข้อผิดพลาดในการบันทึกข้อมูล: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("เกิดข้อผิดพลาดในการส่งข้อมูล")),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  LatLng? _parseLatLng(String addressString) {
    final parts = addressString.split(" \n ");
    if (parts.length == 2) {
      final latLngParts = parts[1].split(',');
      if (latLngParts.length == 2) {
        final lat = double.tryParse(latLngParts[0].trim()) ?? 16.246373;
        final lng = double.tryParse(latLngParts[1].trim()) ?? 103.251827;
        return LatLng(lat, lng);
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "ส่งพัสดุ",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "รายละเอียดผู้ส่ง",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _senderPhoneController,
                  decoration: const InputDecoration(labelText: "เบอร์โทรศัพท์"),
                  keyboardType: TextInputType.phone,
                  validator: (value) => (value == null || value.isEmpty)
                      ? 'กรุณากรอกเบอร์โทร'
                      : null,
                ),
                const SizedBox(height: 16),
                ..._senderSavedAddresses.map((address) {
                  final isSelected = (_selectedSenderAddress == address);
                  return _buildAddressCard(
                    address: address,
                    isSelected: isSelected,
                    onTap: () {
                      setState(() => _selectedSenderAddress = address);
                    },
                  );
                }).toList(),
                const SizedBox(height: 24),

                const Text(
                  "รายละเอียดผู้รับ",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _receiverPhoneController,
                  decoration: InputDecoration(
                    labelText: "ค้นหาผู้รับด้วยเบอร์โทร",
                    suffixIcon: _isSearchingReceiver
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 3),
                            ),
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // 🔍 ปุ่มค้นหา
                              IconButton(
                                icon: const Icon(Icons.search),
                                onPressed: _searchReceiverByPhone,
                              ),
                              // ❌ ปุ่มรีเซ็ต / ดูทั้งหมด
                              IconButton(
                                icon: const Icon(Icons.refresh),
                                onPressed: () {
                                  _receiverPhoneController.clear();
                                  _loadAllReceivers(); // โหลดข้อมูลทั้งหมดกลับมาใหม่
                                },
                              ),
                            ],
                          ),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _receiverAddressController,
                  decoration: const InputDecoration(labelText: "ชื่อผู้รับ"),
                  validator: (value) => (value == null || value.isEmpty)
                      ? 'กรุณากรอกชื่อผู้รับ'
                      : null,
                ),
                TextFormField(
                  controller: _receiverStateCountryController,
                  decoration: const InputDecoration(
                    labelText: "ที่อยู่ (พิกัด)",
                  ),
                  validator: (value) => (value == null || value.isEmpty)
                      ? 'กรุณากรอกที่อยู่'
                      : null,
                ),
                TextFormField(
                  controller: _receiverOtherController,
                  decoration: const InputDecoration(
                    labelText: "คนอื่น (ไม่จำเป็น)",
                  ),
                ),
                const SizedBox(height: 8),
                ..._receiverSavedAddresses.map((address) {
                  final isSelected = (_selectedAddressForMap == address);
                  final position = _parseLatLng(address);

                  return Column(
                    children: [
                      InkWell(
                        onTap: () {
                          setState(() {
                            _selectedAddressForMap = isSelected
                                ? null
                                : address;

                            // ✅ แยกชื่อกับที่อยู่
                            final parts = address.split("\n");
                            if (parts.length >= 2) {
                              final fullName = parts[0].trim();
                              final fullAddress = parts
                                  .sublist(1)
                                  .join("\n")
                                  .trim();

                              // ✅ ใส่ค่าลงช่องกรอกอัตโนมัติ
                              _receiverAddressController.text = fullName;
                              _receiverStateCountryController.text =
                                  fullAddress;
                            } else {
                              _receiverAddressController.text = address;
                              _receiverStateCountryController.text = "";
                            }
                          });
                        },
                        child: Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.blue.shade50
                                : Colors.grey.shade100,
                            border: Border.all(
                              color: isSelected
                                  ? Colors.blue.shade700
                                  : Colors.grey.shade300,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.add_location_alt_outlined,
                                color: Colors.blue.shade700,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  address,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                              Icon(
                                isSelected
                                    ? Icons.keyboard_arrow_up
                                    : Icons.keyboard_arrow_down,
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (isSelected && position != null)
                        SizedBox(
                          height: 200,
                          child: ClipRRect(
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(8),
                              bottomRight: Radius.circular(8),
                            ),
                            child: GoogleMap(
                              initialCameraPosition: CameraPosition(
                                target: position,
                                zoom: 16,
                              ),
                              markers: {
                                Marker(
                                  markerId: MarkerId(position.toString()),
                                  position: position,
                                ),
                              },
                              mapType: MapType.normal,
                              myLocationButtonEnabled: false,
                              zoomControlsEnabled: false,
                              scrollGesturesEnabled: false,
                              tiltGesturesEnabled: false,
                            ),
                          ),
                        ),
                    ],
                  );
                }).toList(),

                const SizedBox(height: 24),
                const Text(
                  "รายละเอียดพัสดุ",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _packageQuantityController,
                  decoration: const InputDecoration(labelText: "จำนวน __ ชิ้น"),
                  keyboardType: TextInputType.number,
                  validator: (value) => (value == null || value.isEmpty)
                      ? 'กรุณาระบุจำนวน'
                      : null,
                ),
                TextFormField(
                  controller: _packageDetailsController,
                  decoration: const InputDecoration(
                    labelText: "รายละเอียดสินค้า:",
                  ),
                  validator: (value) => (value == null || value.isEmpty)
                      ? 'กรุณาระบุรายละเอียด'
                      : null,
                ),
                TextFormField(
                  controller: _packageNotesController,
                  decoration: const InputDecoration(
                    labelText: "หมายเหตุเพิ่มเติม:",
                  ),
                ),
                const SizedBox(height: 16),

                // ปุ่มอัปโหลดรูป
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _isSubmitting ? null : _pickImageFromCamera,
                      icon: const Icon(Icons.camera_alt_outlined),
                      label: const Text("ถ่ายรูปพัสดุ"),
                    ),
                    const SizedBox(width: 16),
                    OutlinedButton(
                      onPressed: null,
                      child: Text(
                        _isUploadFinished
                            ? "อัปโหลดเสร็จสิ้น"
                            : "ยังไม่อัปโหลด",
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_pickedImage != null)
                  Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                    ),
                    child: Image.file(_pickedImage!, fit: BoxFit.cover),
                  ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _onConfirmShipment,
                    child: _isSubmitting
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("ยืนยันส่งของ"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddressCard({
    required String address,
    bool isSelected = false,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 8.0),
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.shade50 : Colors.grey.shade100,
          border: Border.all(
            color: isSelected ? Colors.blue.shade700 : Colors.grey.shade300,
          ),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Text(address),
      ),
    );
  }

  @override
  void dispose() {
    _senderPhoneController.dispose();
    _receiverPhoneController.dispose();
    _receiverAddressController.dispose();
    _receiverStateCountryController.dispose();
    _receiverOtherController.dispose();
    _packageQuantityController.dispose();
    _packageDetailsController.dispose();
    _packageNotesController.dispose();
    super.dispose();
  }
}
