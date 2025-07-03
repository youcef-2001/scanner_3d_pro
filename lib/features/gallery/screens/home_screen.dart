import 'package:flutter/material.dart';
import 'package:scanner_3d_pro/features/gallery/widgets/CameraStreamWidget.dart';
import 'package:scanner_3d_pro/shared/widgets/custom_drawer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

const String baseUrl = 'http://192.168.13.1:80'; // ajuste selon ton réseau

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
  
  // Nouvelles variables pour la gestion de la caméra
  String cameraConnectionStatus = 'Vérification...';
  Timer? _cameraStatusTimer;
  int _cameraRetryCount = 0;
  static const int maxCameraRetries = 5;
  String? _lastCameraError;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _startCameraStatusChecking();
  }

  @override
  void dispose() {
    _cameraStatusTimer?.cancel();
    super.dispose();
  }
  int  i = 0;
  // === GESTION CAMERA ===
  Future<void> _initializeCamera() async {
    await _checkCameraStatus();

    if (!isCameraConnected) {
      await startCamera();
    }
  }

  Future<void> _checkCameraStatus() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/camera/status'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          isCameraConnected = data['connected'] ?? false;
          cameraConnectionStatus = data['status'] ?? 'unknown';
          _cameraRetryCount = 0;
          _lastCameraError = null;
        });
      } else {
        _handleCameraConnectionError('Statut HTTP: ${response.statusCode}');
      }
    } catch (e) {
      _handleCameraConnectionError('Erreur de connexion caméra: $e');
    }
  }

  Future<void> startCamera() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/camera/start'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            isCameraConnected = true;
            cameraConnectionStatus = 'active';
            _lastCameraError = null;
          });
        }
      }
    } catch (e) {
      _handleCameraConnectionError('Erreur de démarrage caméra: $e');
    }
  }
  

  void _handleCameraConnectionError(String error) {
    setState(() {
      _lastCameraError = error;
      if (_cameraRetryCount < maxCameraRetries) {
        cameraConnectionStatus = 'Reconnexion... (${_cameraRetryCount + 1}/$maxCameraRetries)';
        _cameraRetryCount++;
        // Retry after a delay
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) _checkCameraStatus();
        });
      } else {
        isCameraConnected = false;
        cameraConnectionStatus = 'Connexion échouée';
      }
    });
    debugPrint('Camera connection error: $error');
  }

  void _startCameraStatusChecking() {
    _cameraStatusTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      if (mounted && isDeviceConnected) {
        _checkCameraStatus();
      }
    });
  }

  Future<void> _retryCameraConnection() async {
    setState(() {
      _cameraRetryCount = 0;
      _lastCameraError = null;
    });
    await _initializeCamera();
  }

  // === GESTION DEVICE (code existant) ===
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
        });
        
        // Démarrer la vérification de la caméra après connexion du device
        await _initializeCamera();
      } else {
        debugPrint('Erreur connectDevice : ${res.body}');
      }
    } catch (e) {
      debugPrint('Erreur connexion : $e');
    } finally {
      setState(() => isConnecting = false);
    }
  }

  Future<void> disconnectDevice() async {
    try {
      final session = Supabase.instance.client.auth.currentSession;
      final token = session?.accessToken;

      if (token == null) throw Exception('Token Supabase manquant');

      final res = await http.post(
        Uri.parse('$baseUrl/deconnecter'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (res.statusCode == 200) {
        setState(() {
          isDeviceConnected = false;
          isLaserOn = false;
          isCameraConnected = false;
          isScanning = false;
          scanProgress = 0.0;
          cameraConnectionStatus = 'Déconnecté';
        });
      } else {
        debugPrint('Erreur disconnectDevice: ${res.statusCode} - ${res.body}');
      }
    } catch (e) {
      debugPrint('Erreur lors de la déconnexion : $e');
    }
  }

  Future<void> connectOrDisconnectDevice() async {
    if (isDeviceConnected) {
      await disconnectDevice();
    } else {
      await connectDevice();
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
    if (!isCameraConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Caméra non connectée - Impossible de démarrer l\'acquisition')),
      );
      return;
    }

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
        
        // Simuler le progrès du scan
        _simulateScanProgress();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Acquisition lancée avec succès')),
        );
      } else {
        debugPrint('Erreur startAcquisition: ${res.statusCode} - ${res.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors du démarrage de l\'acquisition')),
        );
        setState(() {
          isScanning = false;
          scanProgress = 0.0;
        });
      }
    } catch (e) {
      debugPrint('Exception startAcquisition: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur inattendue : $e')),
      );
      setState(() {
        isScanning = false;
        scanProgress = 0.0;
      });
    }
  }

  void _simulateScanProgress() {
    Timer.periodic(const Duration(milliseconds: 200), (timer) {
      if (!mounted || !isScanning) {
        timer.cancel();
        return;
      }

      setState(() {
        scanProgress += 0.02;
        if (scanProgress >= 1.0) {
          scanProgress = 1.0;
          isScanning = false;
          timer.cancel();
          _onScanComplete();
        }
      });
    });
  }

  void _onScanComplete() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Scan terminé avec succès!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  // === WIDGET CAMERA STREAM ===
  Widget _buildCameraStream() {
    if (!isDeviceConnected) {
      return Container(
        width: double.infinity,
        height: 300,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(40),
          color: Colors.grey[800],
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.device_hub_outlined, size: 60, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Connectez votre device',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    if (!isCameraConnected) {
      return Container(
        width: double.infinity,
        height: 300,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(40),
          color: Colors.grey[800],
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.camera_alt_outlined, size: 60, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                _lastCameraError != null ? 'Erreur caméra' : 'Caméra non disponible',
                style: const TextStyle(color: Colors.grey, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                cameraConnectionStatus,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
                textAlign: TextAlign.center,
              ),
              if (_cameraRetryCount >= maxCameraRetries) ...[
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _retryCameraConnection,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: const Text('Reconnecter'),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: AspectRatio(
        aspectRatio: 1.0, // Format carré pour 1280x1280
        child: CameraStreamWidget(streamUrl: '$baseUrl/stream'),
      ),
    );
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
                      onTap: connectOrDisconnectDevice,
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
              
              // === SECTION CAMERA (améliorée) ===
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: const Color(0xFF2A2A2A),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                child: Column(
                  children: [
                    // Flux vidéo
                    SizedBox(
                      width: double.infinity,
                      child: _buildCameraStream(),
                     
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Status de la caméra avec indicateur
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: !isDeviceConnected 
                                ? Colors.grey 
                                : isCameraConnected 
                                    ? const Color(0xFF10B981) 
                                    : const Color(0xFFEF4444),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          !isDeviceConnected
                              ? 'Device Disconnected'
                              : isCameraConnected 
                                  ? 'Camera Active' 
                                  : 'Camera Disconnected',
                          style: TextStyle(
                            color: !isDeviceConnected
                                ? Colors.grey
                                : isCameraConnected 
                                    ? const Color(0xFF10B981) 
                                    : const Color(0xFFEF4444),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Description du statut
                    Text(
                      !isDeviceConnected
                          ? 'Connectez votre device pour commencer'
                          : isCameraConnected 
                              ? 'Résolution: 1280x1280 - Prêt à scanner' 
                              : 'En attente de connexion caméra...',
                      style: const TextStyle(
                        color: Color(0xFF666666),
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    // Barre de progression du scan
                    if (isScanning) ...[
                      const SizedBox(height: 16),
                      LinearProgressIndicator(
                        value: scanProgress,
                        backgroundColor: Colors.grey[700],
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Scan en cours... ${(scanProgress * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // === BOUTONS CONTROLES ===
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: isDeviceConnected ? toggleLaser : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: !isDeviceConnected
                              ? const Color(0xFF1A1A1A)
                              : isLaserOn 
                                  ? Colors.red 
                                  : const Color(0xFF333333),
                          borderRadius: BorderRadius.circular(8),
                          border: !isDeviceConnected
                              ? Border.all(color: Colors.grey[600]!)
                              : null,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isLaserOn ? Icons.light_mode : Icons.block,
                              color: isDeviceConnected ? Colors.white : Colors.grey,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isLaserOn ? 'Laser ON' : 'Laser OFF',
                              style: TextStyle(
                                color: isDeviceConnected ? Colors.white : Colors.grey,
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
                      onTap: (isDeviceConnected && isCameraConnected && !isScanning) 
                          ? startAcquisition 
                          : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: (isDeviceConnected && isCameraConnected && !isScanning)
                              ? const Color(0xFFEF4444)
                              : const Color(0xFF1A1A1A),
                          borderRadius: BorderRadius.circular(8),
                          border: !(isDeviceConnected && isCameraConnected && !isScanning)
                              ? Border.all(color: Colors.grey[600]!)
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            isScanning ? 'Scanning...' : 'Start Scan',
                            style: TextStyle(
                              color: (isDeviceConnected && isCameraConnected && !isScanning)
                                  ? Colors.white
                                  : Colors.grey,
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