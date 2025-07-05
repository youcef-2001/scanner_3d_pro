import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scanner_3d_pro/features/gallery/widgets/CameraStreamWidget.dart';
import 'package:scanner_3d_pro/shared/widgets/custom_drawer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

const String baseUrl = 'http://192.168.13.1:80';

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
  int scanProgress = 0;
  bool scan_done = false;
  String width_camera = '';
  String height_camera = '';
  double distance = 0.0;

  // Variables pour les contrôles RGB
  // RGB Low
  int redLow = 0;
  int greenLow = 0;
  int blueLow = 0;

  // HSV Low
  int hueLow = 0;
  int saturationLow = 0;
  int valueLow = 0;

  // RGB High
  int redHigh = 255;
  int greenHigh = 255;
  int blueHigh = 255;

  // HSV High
  int hueHigh = 179;
  int saturationHigh = 255;
  int valueHigh = 255;
  bool showRgbControls = false;

  // Nouvelles variables pour la gestion de la caméra
  String cameraConnectionStatus = 'Vérification...';
  Timer? _cameraStatusTimer;
  Timer? _TFLunaTimer;
  int _cameraRetryCount = 0;
  static const int maxCameraRetries = 5;
  String? _lastCameraError;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _startCameraStatusChecking();
    _startDistanceChecking();
  }

  @override
  void dispose() {
    _cameraStatusTimer?.cancel();
    _TFLunaTimer?.cancel();
    super.dispose();
  }

  // === GESTION DES FILTRES RGB ===
  Future<void> _updateRgbFilters() async {
    if (!isCameraConnected || !isDeviceConnected) return;

    try {
      final session = Supabase.instance.client.auth.currentSession;
      final token = session?.accessToken;

      if (token == null) return;

      final response = await http.post(
        Uri.parse('$baseUrl/camera/rgb-filter'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
         // RGB Low
          'redLow': redLow,
          'greenLow': greenLow,
          'blueLow': blueLow,
          // HSV Low
          'hueLow': hueLow,
          'saturationLow': saturationLow,
          'valueLow': valueLow,
          // RGB High
          'redHigh': redHigh,
          'greenHigh': greenHigh,
          'blueHigh': blueHigh,
          // HSV High
          'hueHigh': hueHigh,
          'saturationHigh': saturationHigh,
          'valueHigh': valueHigh,
        }),
      );

      if (response.statusCode != 200) {
        debugPrint('Erreur mise à jour filtres RGB: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Erreur lors de la mise à jour des filtres RGB: $e');
    }
    finally {
      //eviter de faire trop de requêtes sleep
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  void _resetRgbFilters() {
    setState(() {
    // RGB Low
          redLow = 0;
         greenLow = 0;
         blueLow = 0;
          // HSV Low
      hueLow = 0;
         saturationLow = 0;
     valueLow = 0;
          // RGB High
        redHigh = 255;
         greenHigh = 255;
       blueHigh = 255;
          // HSV High
        hueHigh = 255;
           saturationHigh = 255;
           valueHigh = 255;
    });
    _updateRgbFilters();
  }

  void _showRgbControlsDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            bool isRgbMode = showRgbControls;
            return StatefulBuilder(
              builder: (context, setDialogState) {
                // Helper for slider
                Widget buildIntSlider({
                  required String label,
                  required int value,
                  required int min,
                  required int max,
                  required Color color,
                  required ValueChanged<int> onChanged,
                }) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            label,
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              value.toString(),
                              style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Slider(
                        value: value.toDouble(),
                        min: min.toDouble(),
                        max: max.toDouble(),
                        divisions: max - min,
                        activeColor: color,
                        inactiveColor: color.withOpacity(0.2),
                        onChanged: (v) {
                          onChanged(v.round());
                        },
                      ),
                    ],
                  );
                }

                Widget rgbSliders() => Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          "RGB",
                          style: GoogleFonts.poppins(
                            color: Colors.red[200],
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        buildIntSlider(
                          label: "Rouge Min",
                          value: redLow,
                          min: 0,
                          max: 255,
                          color: Colors.red,
                          onChanged: (v) {
                            setDialogState(() => redLow = v);
                            setState(() => redLow = v);
                            _updateRgbFilters();
                          },
                        ),
                        buildIntSlider(
                          label: "Vert Min",
                          value: greenLow,
                          min: 0,
                          max: 255,
                          color: Colors.green,
                          onChanged: (v) {
                            setDialogState(() => greenLow = v);
                            setState(() => greenLow = v);
                            _updateRgbFilters();
                          },
                        ),
                        buildIntSlider(
                          label: "Bleu Min",
                          value: blueLow,
                          min: 0,
                          max: 255,
                          color: Colors.blue,
                          onChanged: (v) {
                            setDialogState(() => blueLow = v);
                            setState(() => blueLow = v);
                            _updateRgbFilters();
                          },
                        ),
                        const Divider(color: Colors.white24, height: 24),
                        buildIntSlider(
                          label: "Rouge Max",
                          value: redHigh,
                          min: 0,
                          max: 255,
                          color: Colors.redAccent,
                          onChanged: (v) {
                            setDialogState(() => redHigh = v);
                            setState(() => redHigh = v);
                            _updateRgbFilters();
                          },
                        ),
                        buildIntSlider(
                          label: "Vert Max",
                          value: greenHigh,
                          min: 0,
                          max: 255,
                          color: Colors.greenAccent,
                          onChanged: (v) {
                            setDialogState(() => greenHigh = v);
                            setState(() => greenHigh = v);
                            _updateRgbFilters();
                          },
                        ),
                        buildIntSlider(
                          label: "Bleu Max",
                          value: blueHigh,
                          min: 0,
                          max: 255,
                          color: Colors.lightBlueAccent,
                          onChanged: (v) {
                            setDialogState(() => blueHigh = v);
                            setState(() => blueHigh = v);
                            _updateRgbFilters();
                          },
                        ),
                      ],
                    );

                Widget hsvSliders() => Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          "HSV",
                          style: GoogleFonts.poppins(
                            color: Colors.orange[200],
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        buildIntSlider(
                          label: "Teinte Min",
                          value: hueLow,
                          min: 0,
                          max: 255,
                          color: Colors.deepOrange,
                          onChanged: (v) {
                            setDialogState(() => hueLow = v);
                            setState(() => hueLow = v);
                            _updateRgbFilters();
                          },
                        ),
                        buildIntSlider(
                          label: "Saturation Min",
                          value: saturationLow,
                          min: 0,
                          max: 255,
                          color: Colors.purple,
                          onChanged: (v) {
                            setDialogState(() => saturationLow = v);
                            setState(() => saturationLow = v);
                            _updateRgbFilters();
                          },
                        ),
                        buildIntSlider(
                          label: "Valeur Min",
                          value: valueLow,
                          min: 0,
                          max: 255,
                          color: Colors.yellow[700]!,
                          onChanged: (v) {
                            setDialogState(() => valueLow = v);
                            setState(() => valueLow = v);
                            _updateRgbFilters();
                          },
                        ),
                        const Divider(color: Colors.white24, height: 24),
                        buildIntSlider(
                          label: "Teinte Max",
                          value: hueHigh,
                          min: 0,
                          max: 255,
                          color: Colors.deepOrangeAccent,
                          onChanged: (v) {
                            setDialogState(() => hueHigh = v);
                            setState(() => hueHigh = v);
                            _updateRgbFilters();
                          },
                        ),
                        buildIntSlider(
                          label: "Saturation Max",
                          value: saturationHigh,
                          min: 0,
                          max: 255,
                          color: Colors.purpleAccent,
                          onChanged: (v) {
                            setDialogState(() => saturationHigh = v);
                            setState(() => saturationHigh = v);
                            _updateRgbFilters();
                          },
                        ),
                        buildIntSlider(
                          label: "Valeur Max",
                          value: valueHigh,
                          min: 0,
                          max: 255,
                          color: Colors.amberAccent,
                          onChanged: (v) {
                            setDialogState(() => valueHigh = v);
                            setState(() => valueHigh = v);
                            _updateRgbFilters();
                          },
                        ),
                      ],
                    );

                return Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFF23272F),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Drag handle
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Container(
                          width: 50,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.grey[700],
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      // Title and mode switch
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 2),
                        child: Row(
                          children: [
                            const Icon(Icons.palette, color: Colors.orange, size: 26),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Réglages Filtres Couleur',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                            // Mode switch button
                            GestureDetector(
                              onTap: () {
                                setDialogState(() {
                                  showRgbControls = !showRgbControls;
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                width: 70,
                                height: 34,
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: showRgbControls
                                      ? Colors.red[300]
                                      : Colors.orange[300],
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.15),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                                child: Stack(
                                  children: [
                                    Align(
                                      alignment: showRgbControls
                                          ? Alignment.centerLeft
                                          : Alignment.centerRight,
                                      child: Container(
                                        width: 26,
                                        height: 26,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          showRgbControls
                                              ? Icons.color_lens
                                              : Icons.gradient,
                                          color: showRgbControls
                                              ? Colors.red[300]
                                              : Colors.orange[300],
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                    Align(
                                      alignment: Alignment.center,
                                      child: Text(
                                        showRgbControls ? "RGB" : "HSV",
                                        style: TextStyle(
                                          color: Colors.black87,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Expanded(
                        child: SingleChildScrollView(
                          controller: scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                          child: showRgbControls ? rgbSliders() : hsvSliders(),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () {
                                _resetRgbFilters();
                                setDialogState(() {});
                              },
                              child: const Text(
                                'Réinitialiser',
                                style: TextStyle(
                                    color: Colors.orange,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 8),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text(
                                'Fermer',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildSliderControl(String label, double value, Color color, Function(double) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                value.toStringAsFixed(2),
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: color,
            inactiveTrackColor: color.withOpacity(0.3),
            thumbColor: color,
            overlayColor: color.withOpacity(0.2),
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
          ),
          child: Slider(
            value: value,
            min: 0.0,
            max: 2.0,
            divisions: 100,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  int i = 0;
  // === GESTION CAMERA ===
  Future<void> _initializeCamera() async {
    await _checkCameraStatus();
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
          final resolution = data['resolution'];
          if (resolution != 'N/A') {
            final parts = resolution.split('X');
            if (parts.length == 2) {
              i++;
              width_camera = parts[0];
              height_camera = parts[1];
              debugPrint('Camera resolution: $width_camera x $height_camera');
            } else {
              debugPrint('Résolution caméra invalide: $resolution');
            }
          } else {
            debugPrint('Aucune résolution fournie par la caméra');
          }
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

  void _handleCameraConnectionError(String error) {
    setState(() {
      _lastCameraError = error;
      if (_cameraRetryCount < maxCameraRetries) {
        cameraConnectionStatus =
            'Reconnexion... (${_cameraRetryCount + 1}/$maxCameraRetries)';
        _cameraRetryCount++;
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

  // === GESTION DEVICE ===
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
          scanProgress = 0;
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
        const SnackBar(
            content: Text(
                'Caméra non connectée - Impossible de démarrer l\'acquisition')),
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
        scan_done = false;
        scanProgress = 0;
      });

      final res = await http.post(
        Uri.parse('$baseUrl/start-acquisition'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "device": "scanner_3d_pro",
          "distance": distance.toString(),
          "userid": Supabase.instance.client.auth.currentUser?.id,
          "username": Supabase.instance.client.auth.currentUser?.userMetadata?['name'] ?? 
                     Supabase.instance.client.auth.currentUser?.email ?? 'Utilisateur',
        }),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        debugPrint('Acquisition lancée: ${data['message']}');

        _ScanProgress();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Acquisition lancée avec succès')),
        );
      } else {
        debugPrint('Erreur startAcquisition: ${res.statusCode} - ${res.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Erreur lors du démarrage de l\'acquisition')),
        );
        setState(() {
          isScanning = false;
          scanProgress = 0;
        });
      }
    } catch (e) {
      debugPrint('Exception startAcquisition: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur inattendue : $e')),
      );
      setState(() {
        isScanning = false;
        scanProgress = 0;
      });
    }
  }

  Future<void> _GetTFLunaDistance() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/tfluna/read'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 2));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          distance = data['distance_cm']?.toDouble() ?? 0.0;
        });
      } else {
        debugPrint('Erreur GetTFLunaDistance: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('Exception GetTFLunaDistance: $e');
    }
  }

  void _startDistanceChecking() {
    _TFLunaTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && isDeviceConnected) {
        _GetTFLunaDistance();
      }
    });
  }

  void _ScanProgress() {
    Timer.periodic(const Duration(milliseconds: 6000), (timer) {
      if (!mounted || !isScanning) {
        timer.cancel();
        return;
      }

      http.get(Uri.parse('$baseUrl/acquisition-status')).then((response) {
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          setState(() {
            scanProgress = data['step'] ?? 0;
            isScanning = data['status'] ?? false;
            scan_done = data['ackDone'] ?? false;
          });

          if (scan_done) {
            timer.cancel();
            _onScanComplete();
          }
        } else {
          debugPrint('Erreur lors de la récupération du statut du scan: ${response.statusCode} - ${response.body}');
        }
      }).catchError((e) {
        debugPrint('Erreur lors de la récupération du statut du scan: $e');
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

  Widget _buildCameraStream() {
    if (!isDeviceConnected) {
      return Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height * 0.52,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.grey[800],
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.device_hub_outlined, size: 70, color: Colors.grey),
              SizedBox(height: 20),
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
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height * 0.52,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.grey[800],
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.camera_alt_outlined,
                  size: 70, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                _lastCameraError != null
                    ? 'Erreur caméra'
                    : 'Caméra non disponible',
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: const Text('Reconnecter'),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        SizedBox(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height * 0.52,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.grey[800],
              ),
              child: AspectRatio(
                aspectRatio: 1.0,
                child: CameraStreamPage(myurl: '$baseUrl/camera/video_feed'),
              ),
            ),
          ),
        ),
        // Bouton RGB flottant
        Positioned(
          right: 16,
          top: 16,
          child: GestureDetector(
            onTap: _showRgbControlsDialog,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child: const Icon(
                Icons.palette,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final userName = user?.userMetadata?['name'] ?? user?.email ?? 'Utilisateur';

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      drawer: const CustomDrawer(),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 25,
        foregroundColor: Colors.white,
        title: Text(
          'Live View',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        actions: [
          Flexible(
            flex: 2,
            child: GestureDetector(
              onTap: connectOrDisconnectDevice,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 200),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: isDeviceConnected
                      ? const Color(0xFF10B981)
                      : isConnecting
                          ? const Color(0xFFFF9800)
                          : const Color(0xFFEF4444),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                margin: const EdgeInsets.only(right: 20),
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // === SECTION CAMERA ===
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: const Color(0xFF2A2A2A),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 6),
                child: Column(
                  children: [
                    // Flux vidéo avec bouton RGB
                    SizedBox(
                      width: double.infinity,
                      child: _buildCameraStream(),
                    ),

                    const SizedBox(height: 8),

                    // Status de la caméra
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 15,
                          height: 15,
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
                              ? 'Résolution: ${width_camera + "x" + height_camera} - Distance TF Luna: ${distance} cm '
                              : 'En attente de connexion caméra...',
                      style: const TextStyle(
                        color: Color.fromARGB(255, 173, 170, 170),
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    // Barre de progression du scan
                    if (isScanning) ...[
                      const SizedBox(height: 16),
                      LinearProgressIndicator(
                        value: scanProgress/4,
                        backgroundColor: Colors.grey[700],
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Scan en cours... ${(scanProgress * 100 / 4).toStringAsFixed(0)}%',
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
                                color: isDeviceConnected
                                    ? Colors.white
                                    : Colors.grey,
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
                      onTap: (isDeviceConnected &&
                              isCameraConnected &&
                              !isScanning)
                          ? startAcquisition
                          : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: (isDeviceConnected &&
                              isCameraConnected &&
                              isScanning)
                            ? const Color(0xFF10B981) // Vert pendant le scan
                            : (isDeviceConnected &&
                              isCameraConnected &&
                              !isScanning)
                              ? const Color(0xFFEF4444)
                              : const Color(0xFF1A1A1A),
                          borderRadius: BorderRadius.circular(8),
                          border: !(isDeviceConnected &&
                                  isCameraConnected &&
                                  !isScanning)
                              ? Border.all(color: Colors.grey[600]!)
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            isScanning ? 'Scanning...' : 'Start Scan',
                            style: TextStyle(
                              color: isScanning
                                ? Colors.white
                                : (isDeviceConnected &&
                                  isCameraConnected &&
                                  !isScanning)
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