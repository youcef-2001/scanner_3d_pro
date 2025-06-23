import 'package:flutter/material.dart';
import 'package:scanner_3d_pro/shared/widgets/custom_drawer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  void connectDevice() async {
    if (isCameraConnected) {
      setState(() {
        isCameraConnected = false;
        isLaserOn = false;
      });
      return;
    }

    setState(() {
      isConnecting = true;
    });

    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      isCameraConnected = true;
      isConnecting = false;
    });
  }

  void startScan() async {
    if (!isCameraConnected || isScanning) return;

    setState(() {
      isScanning = true;
      isLaserOn = true;
      scanProgress = 0;
    });

    for (int i = 0; i <= 100; i++) {
      await Future.delayed(const Duration(milliseconds: 30));
      setState(() {
        scanProgress = i / 100;
      });
    }

    setState(() {
      isScanning = false;
    });
  }

  void toggleLaser() {
    if (!isCameraConnected) return;
    setState(() {
      isLaserOn = !isLaserOn;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final userName = user?.userMetadata?['name'] ?? user?.email ?? 'Utilisateur';

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      drawer: const CustomDrawer(),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 32),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
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
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: GestureDetector(
                    onTap: connectDevice,
                    child: Container(
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
                          const Text(
                            'Device Connected',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
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
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: const Color(0xFF2A2A2A),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: MediaQuery.of(context).size.width,
                      height: MediaQuery.of(context).size.height * 0.55,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(40),
                        image: DecorationImage(
                          image: NetworkImage(
                            isCameraConnected
                                ? 'https://cdn.builder.io/api/v1/image/assets/TEMP/f2e7761cc87b07c06510fc935fca3ba9fbf39f39?placeholderIfAbsent=true&apiKey=91c478f48c2b4da09ef24f4c421f135c'
                                : 'https://cdn.builder.io/api/v1/image/assets/TEMP/placeholder',
                          ),
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
                      Text('${(scanProgress * 100).toStringAsFixed(0)}%', style: const TextStyle(color: Colors.white))
                    ]
                  ],
                ),
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
                          Icon(
                            isLaserOn ? Icons.light_mode : Icons.block,
                            color: Colors.white,
                          ),
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
            )
          ],
        ),
      ),
    );
  }
}
