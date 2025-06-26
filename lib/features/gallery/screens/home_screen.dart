import 'package:flutter/material.dart';
import 'package:scanner_3d_pro/shared/widgets/custom_drawer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

const String baseUrl = 'http://192.168.13.1:5000'; // ajuste selon ton réseau

class LiveDisabled extends StatefulWidget {
  const LiveDisabled({Key? key}) : super(key: key);

  @override
  State<LiveDisabled> createState() => _LiveDisabledState();
}

class _LiveDisabledState extends State<LiveDisabled> {
  bool isCameraConnected = false;
  bool isConnecting = false;
  bool isLaserOn = false;
  bool isScanning = false;
  double scanProgress = 0;

  Future<void> connectDevice() async {
    setState(() => isConnecting = true);
    try {
      final res = await http.get(Uri.parse('$baseUrl/laser/status'));
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        setState(() {
          isCameraConnected = true;
          isLaserOn = (json['status'] == 'on');
        });
      }
    } catch (e) {
      debugPrint('Erreur connexion : $e');
    } finally {
      setState(() => isConnecting = false);
    }
  }

  Future<void> toggleLaser() async {
    if (!isCameraConnected) return;
    try {
      final endpoint = isLaserOn ? '/laser/off' : '/laser/on';
      final res = await http.post(Uri.parse('$baseUrl$endpoint'));
      if (res.statusCode == 200) {
        setState(() => isLaserOn = !isLaserOn);
      }
    } catch (e) {
      debugPrint('Erreur toggle laser : $e');
    }
  }

  Future<void> startScan() async {
    if (!isCameraConnected || isScanning) return;

    setState(() {
      isScanning = true;
      scanProgress = 0;
      isLaserOn = true;
    });

    try {
      final session = Supabase.instance.client.auth.currentSession;
      final token = session?.accessToken;
      if (token == null) throw Exception('Token non trouvé');

      final res = await http.post(
        Uri.parse('$baseUrl/scan/start'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        debugPrint('Scan terminé, répertoire: ${data['directory']}');
      } else {
        debugPrint('Erreur démarrage scan : ${res.body}');
      }

      // Simuler progression
      for (int i = 0; i <= 100; i++) {
        await Future.delayed(const Duration(milliseconds: 30));
        setState(() => scanProgress = i / 100);
      }
    } catch (e) {
      debugPrint('Erreur startScan : $e');
    } finally {
      setState(() {
        isScanning = false;
        isLaserOn = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final userName = user?.userMetadata?['name'] ?? user?.email ?? 'Utilisateur';

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      drawer: const CustomDrawer(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            image: const DecorationImage(
                              image: NetworkImage(
                                'https://cdn.builder.io/api/v1/image/assets/TEMP/b3a41f38f7854aaa0820549c34ec57392c4d4d71?placeholderIfAbsent=true&apiKey=91c478f48c2b4da09ef24f4c421f135c',
                              ),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Text(
                              'Welcome back',
                              style: TextStyle(
                                color: Color(0xFF888888),
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Flexible(
                    flex: 2,
                    child: GestureDetector(
                      onTap: connectDevice,
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 160),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: isCameraConnected
                              ? const Color(0xFF10B981)
                              : isConnecting
                                  ? const Color(0xFFFF9800)
                                  : const Color(0xFFEF4444),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            isConnecting
                                ? const SizedBox(
                                    width: 12,
                                    height: 12,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Icon(Icons.circle, size: 8, color: Colors.white),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                isConnecting
                                    ? 'Connecting...'
                                    : isCameraConnected
                                        ? 'Disconnect'
                                        : 'Connect Device',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: const Color(0xFF2A2A2A),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 250,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(40),
                        child: isCameraConnected
                            ? Image.network(
                                '$baseUrl/camera/video_feed',
                                fit: BoxFit.cover,
                              )
                            : Image.network(
                                'https://cdn.builder.io/api/v1/image/assets/TEMP/placeholder',
                                fit: BoxFit.cover,
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isCameraConnected ? 'Camera Active' : 'No Camera Found',
                      style: TextStyle(
                        color: isCameraConnected ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isCameraConnected ? 'Ready to scan' : 'Connect your device to start scanning',
                      style: const TextStyle(
                        color: Color(0xFF666666),
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (isScanning) ...[
                      const SizedBox(height: 16),
                      LinearProgressIndicator(value: scanProgress, color: Colors.green),
                      const SizedBox(height: 8),
                      Text('${(scanProgress * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(color: Colors.white)),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: toggleLaser,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isLaserOn ? Colors.red : const Color(0xFF333333),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(isLaserOn ? Icons.light_mode : Icons.block, color: Colors.white),
                            const SizedBox(width: 6),
                            Text(
                              isLaserOn ? 'Laser ON' : 'Laser OFF',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: startScan,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: Text(
                            'Start Scan',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
