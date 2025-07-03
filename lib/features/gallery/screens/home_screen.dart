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
  bool isDeviceConnected = false;
  bool isConnecting = false;
  bool isLaserOn = false;
  bool isScanning = false;
  double scanProgress = 0;

  Future<void> connectDevice() async {
    setState(() => isConnecting = true);

    try {
      final session = Supabase.instance.client.auth.currentSession;
      final token = session?.accessToken;

      if (token == null) throw Exception('Token Supabase manquant');

      final res = await http.post(
        Uri.parse('$baseUrl/appairer'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          "device": "scanner_3d_pro",
        }),
      );

      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        setState(() {
          isDeviceConnected = true;
          isLaserOn = (json['laser'] == 'on');
          isCameraConnected = true; // ✅ Affichage de la caméra live activé
        });
      } else {
        debugPrint('Erreur connectDevice : ${res.body}');
      }
    } catch (e) {
      debugPrint('Erreur connexion : $e');
    } finally {
      setState(() => isConnecting = false);
    }
  }

  Future<void> toggleLaser() async {
    if (!isDeviceConnected) {
      debugPrint('Le device n\'est pas connecté');
      return;
    }

    try {
      final session = Supabase.instance.client.auth.currentSession;
      final token = session?.accessToken;

      if (token == null) {
        debugPrint('Token Supabase introuvable');
        return;
      }

      final endpoint = isLaserOn ? '/laser/off' : '/laser/on';

      final res = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (res.statusCode == 200) {
        setState(() => isLaserOn = !isLaserOn);
        debugPrint('Laser toggled: ${isLaserOn ? "ON" : "OFF"}');
      } else {
        debugPrint('Erreur laser toggle: ${res.statusCode} - ${res.body}');
      }
    } catch (e) {
      debugPrint('Exception toggleLaser: $e');
    }
  }

  Future<void> startAcquisition() async {
    try {
      final session = Supabase.instance.client.auth.currentSession;
      final token = session?.accessToken;

      if (token == null) {
        debugPrint('Token Supabase introuvable');
        return;
      }

      setState(() {
        isScanning = true;
        scanProgress = 0.0;
      });

      final res = await http.post(
        Uri.parse('$baseUrl/start-acquisition'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        debugPrint('Acquisition lancée: ${data['message']}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Acquisition lancée avec succès')),
        );
      } else {
        debugPrint('Erreur startAcquisition: ${res.statusCode} - ${res.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du démarrage de l\'acquisition')),
        );
      }
    } catch (e) {
      debugPrint('Exception startAcquisition: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur inattendue : $e')),
      );
    } finally {
      setState(() {
        isScanning = false;
        scanProgress = 0.0;
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
                          color: isDeviceConnected
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
                                    : isDeviceConnected
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
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return const Center(child: CircularProgressIndicator());
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  return const Center(
                                    child: Text(
                                      'Erreur de flux vidéo',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  );
                                },
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
                      onTap: startAcquisition,
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
