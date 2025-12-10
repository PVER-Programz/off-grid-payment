import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:wifi_iot/wifi_iot.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';

const MethodChannel _networkChannel = MethodChannel('network/bind');

Future<void> bindToWifi() async {
  try {
    await _networkChannel.invokeMethod('bindToWifi');
    print("Network bind successful");
  } catch (e) {
    print("Bind Error: $e");
  }
}

class QrScanPage extends StatefulWidget {
  const QrScanPage({super.key});

  @override
  State<QrScanPage> createState() => _QrScanPageState();
}

class _QrScanPageState extends State<QrScanPage> {
  final MobileScannerController controller = MobileScannerController();

  bool _scanned = false;
  String status = "Scan a hotspot QR code";

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    await Permission.camera.request();
    await Permission.location.request();
  }

  Map<String, String> _parseWifiQr(String qr) {
    final ssid = RegExp(r'S:([^;]+)').firstMatch(qr)?.group(1) ?? '';
    final password = RegExp(r'P:([^;]+)').firstMatch(qr)?.group(1) ?? '';
    final type = RegExp(r'T:([^;]+)').firstMatch(qr)?.group(1) ?? 'WPA';
    final ip = RegExp(r'IP:([^;]+)').firstMatch(qr)?.group(1) ?? '';

    return {"ssid": ssid, "password": password, "type": type, "server_ip": ip};
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_scanned) return;
    final code = capture.barcodes.first.rawValue;
    if (code == null) return;

    setState(() {
      _scanned = true;
      status = "QR detected...";
    });

    final wifi = _parseWifiQr(code);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await WiFiForIoTPlugin.connect(
        wifi["ssid"]!,
        password: wifi["password"],
        security:
            wifi["type"] == "WEP" ? NetworkSecurity.WEP : NetworkSecurity.WPA,
        joinOnce: true,
      );

      bool connected = false;
      String? deviceIp;

      for (int i = 0; i < 12; i++) {
        deviceIp = await WiFiForIoTPlugin.getIP();
        if (deviceIp != null &&
            deviceIp.isNotEmpty &&
            deviceIp != "0.0.0.0") {
          connected = true;
          break;
        }
        await Future.delayed(const Duration(seconds: 1));
      }

      Navigator.of(context).pop();

      if (!connected) {
        setState(() {
          status = "❌ Could not fully connect.";
          _scanned = false;
        });
        return;
      }

      // ⭐⭐⭐ MOST IMPORTANT: BIND NETWORK ⭐⭐⭐
      setState(() => status = "🔄 Binding network...");
      await bindToWifi();

      setState(() => status = "✅ Connected & Ready!");

      String returnIp =
          wifi["server_ip"]!.isNotEmpty ? wifi["server_ip"]! : deviceIp!;

      Navigator.of(context).pop(returnIp);
    } catch (e) {
      Navigator.of(context).pop();
      setState(() {
        status = "❌ Error: $e";
        _scanned = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const SizedBox(height: 40),
          const Text("Scan Hotspot QR",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          Expanded(
            child: MobileScanner(onDetect: _onDetect),
          ),
          Text(status,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20)
        ],
      ),
    );
  }
}
