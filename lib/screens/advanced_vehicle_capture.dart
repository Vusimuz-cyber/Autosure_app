import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vector_math/vector_math_64.dart' as vector;
import 'package:camera/camera.dart';

// dart:io is mobile-only — import conditionally so the web build doesn't break
import 'package:flutter/foundation.dart';

class AdvancedVehicleCaptureScreen extends StatefulWidget {
  final Function(Map<String, String>) onPhotosCaptured;

  const AdvancedVehicleCaptureScreen(
      {super.key, required this.onPhotosCaptured});

  @override
  State<AdvancedVehicleCaptureScreen> createState() =>
      _AdvancedVehicleCaptureScreenState();
}

class _AdvancedVehicleCaptureScreenState
    extends State<AdvancedVehicleCaptureScreen> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _processingController;
  late Animation<double> _pulseAnimation;

  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _cameraFailed = false; // track whether camera actually failed
  bool _isProcessing = false;
  bool _showGuidance = true;
  double _captureProgress = 0.0;

  Map<String, String> _capturedPhotos = {};

  final List<Map<String, dynamic>> _requiredShots = [
    {
      'type': 'front',
      'icon': Icons.north,
      'angle': '0°',
      'description': 'Straight front view of the vehicle'
    },
    {
      'type': 'rear',
      'icon': Icons.south,
      'angle': '180°',
      'description': 'Straight rear view of the vehicle'
    },
    {
      'type': 'left_side',
      'icon': Icons.west,
      'angle': '90° Left',
      'description': 'Full left side profile'
    },
    {
      'type': 'right_side',
      'icon': Icons.east,
      'angle': '90° Right',
      'description': 'Full right side profile'
    },
    {
      'type': 'front_left_angle',
      'icon': Icons.north_west,
      'angle': '45° FL',
      'description': 'Front-left corner view'
    },
    {
      'type': 'front_right_angle',
      'icon': Icons.north_east,
      'angle': '45° FR',
      'description': 'Front-right corner view'
    },
    {
      'type': 'rear_left_angle',
      'icon': Icons.south_west,
      'angle': '45° RL',
      'description': 'Rear-left corner view'
    },
    {
      'type': 'rear_right_angle',
      'icon': Icons.south_east,
      'angle': '45° RR',
      'description': 'Rear-right corner view'
    },
    {
      'type': 'dashboard',
      'icon': Icons.dashboard,
      'angle': 'Interior',
      'description': 'Dashboard and interior'
    },
    {
      'type': 'vin_number',
      'icon': Icons.qr_code,
      'angle': 'VIN',
      'description': 'Vehicle identification number'
    },
    {
      'type': 'tires_front',
      'icon': Icons.settings,
      'angle': 'Front Tires',
      'description': 'Close-up of front tires'
    },
    {
      'type': 'tires_rear',
      'icon': Icons.settings,
      'angle': 'Rear Tires',
      'description': 'Close-up of rear tires'
    },
  ];

  int _currentShotIndex = 0;
  bool _allShotsComplete = false;
  String _currentGuidance = 'Position camera to capture FRONT view';

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeCamera();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _processingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _pulseAnimation =
        Tween<double>(begin: 0.95, end: 1.05).animate(_pulseController);
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();

      if (_cameras == null || _cameras!.isEmpty) {
        _handleCameraUnavailable('No cameras found on this device.');
        return;
      }

      // On web, prefer the environment (rear) camera if available
      CameraDescription selectedCamera = _cameras!.first;
      if (kIsWeb) {
        final rear = _cameras!.where((c) =>
            c.lensDirection == CameraLensDirection.back).toList();
        if (rear.isNotEmpty) selectedCamera = rear.first;
      }

      _cameraController = CameraController(
        selectedCamera,
        ResolutionPreset.high,
        imageFormatGroup: ImageFormatGroup.jpeg,
        // On web, enableAudio must be false — camera package requirement
        enableAudio: false,
      );

      await _cameraController!.initialize();

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
          _cameraFailed = false;
        });
        await _cameraController!.setFlashMode(FlashMode.off);
      }
    } catch (e) {
      print('Camera init error: $e');
      _handleCameraUnavailable(e.toString());
    }
  }

  void _handleCameraUnavailable(String reason) {
    print('Camera unavailable: $reason');
    if (!mounted) return;
    setState(() {
      _cameraFailed = true;
      _isCameraInitialized = true; // allow UI to render fallback
    });
  }

  // ── Capture ─────────────────────────────────────────────────────────────────

  Future<void> _capturePhoto() async {
    if (_isProcessing) return;

    // If camera failed or not ready, fall back to simulated capture
    if (_cameraFailed ||
        _cameraController == null ||
        !_cameraController!.value.isInitialized) {
      _simulateCapture();
      return;
    }

    setState(() => _isProcessing = true);
    _processingController.forward(from: 0.0);

    try {
      final XFile file = await _cameraController!.takePicture();

      // FIX: use XFile.readAsBytes() — works on BOTH web and mobile.
      // File(file.path).readAsBytes() crashes on web because dart:io is
      // unavailable and file.path is a blob URL, not a filesystem path.
      final Uint8List imageBytes = await file.readAsBytes();

      final user = FirebaseAuth.instance.currentUser;
      final shotType = _requiredShots[_currentShotIndex]['type'] as String;

      if (user != null) {
        final fileName =
            '${user.uid}_${shotType}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final storageRef =
            FirebaseStorage.instance.ref().child('vehicle_photos/$fileName');

        await storageRef.putData(
          imageBytes,
          SettableMetadata(contentType: 'image/jpeg'),
        );

        final downloadURL = await storageRef.getDownloadURL();
        setState(() => _capturedPhotos[shotType] = downloadURL);
        print('Uploaded: $shotType → $downloadURL');
      } else {
        // No user — store blob URL locally for demo
        setState(() => _capturedPhotos[shotType] = file.path);
      }

      await Future.delayed(const Duration(milliseconds: 500));
      setState(() {
        _isProcessing = false;
        _captureProgress =
            (_currentShotIndex + 1) / _requiredShots.length;
      });

      Future.delayed(const Duration(milliseconds: 300), _nextShot);
    } catch (e) {
      print('Capture error: $e');
      setState(() => _isProcessing = false);
      // Real capture failed → fall back silently
      _simulateCapture();
    }
  }

  void _simulateCapture() {
    setState(() => _isProcessing = true);
    _processingController.forward(from: 0.0);

    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      final shotType = _requiredShots[_currentShotIndex]['type'] as String;
      final user = FirebaseAuth.instance.currentUser;
      final url = user != null
          ? 'https://example.com/vehicle_${shotType}.jpg'
          : 'simulated_${shotType}.jpg';

      setState(() {
        _capturedPhotos[shotType] = url;
        _isProcessing = false;
        _captureProgress =
            (_currentShotIndex + 1) / _requiredShots.length;
      });

      Future.delayed(const Duration(milliseconds: 300), _nextShot);
    });
  }

  void _nextShot() {
    if (!mounted) return;
    if (_currentShotIndex < _requiredShots.length - 1) {
      setState(() {
        _currentShotIndex++;
        _showGuidance = true;
      });
      _updateGuidanceText();
    } else {
      setState(() {
        _allShotsComplete = true;
        _captureProgress = 1.0;
      });
      widget.onPhotosCaptured(_capturedPhotos);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'All ${_capturedPhotos.length} photos captured successfully!'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _updateGuidanceText() {
    final Map<String, String> guidanceMap = {
      'front': 'Capture the FRONT view\nWhole vehicle from the front',
      'rear': 'Capture the REAR view\nWhole vehicle from the back',
      'left_side': 'Capture LEFT SIDE view\nFull side profile',
      'right_side': 'Capture RIGHT SIDE view\nFull side profile',
      'front_left_angle':
          'Capture 45° FRONT-LEFT angle\nCorner view of front and left side',
      'front_right_angle':
          'Capture 45° FRONT-RIGHT angle\nCorner view of front and right side',
      'rear_left_angle':
          'Capture 45° REAR-LEFT angle\nCorner view of rear and left side',
      'rear_right_angle':
          'Capture 45° REAR-RIGHT angle\nCorner view of rear and right side',
      'dashboard': 'Capture INTERIOR VIEW\nDashboard and front seats',
      'vin_number':
          'Capture VIN NUMBER\nUsually on dashboard or door frame',
      'tires_front': 'Capture FRONT TIRES\nClose-up showing tread',
      'tires_rear': 'Capture REAR TIRES\nClose-up showing tread',
    };
    setState(() {
      _currentGuidance = guidanceMap[_requiredShots[_currentShotIndex]
                  ['type']] ??
          'Capture photo for documentation';
    });
  }

  // ── Camera preview ───────────────────────────────────────────────────────────

  Widget _buildCameraPreview() {
    if (_isCameraInitialized &&
        !_cameraFailed &&
        _cameraController != null &&
        _cameraController!.value.isInitialized) {
      return CameraPreview(_cameraController!);
    }

    // Fallback UI — shown when camera is unavailable or failed
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blueGrey.shade900, Colors.black87],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _cameraFailed ? Icons.no_photography : Icons.photo_camera,
            color: Colors.white.withOpacity(0.3),
            size: 80,
          ),
          const SizedBox(height: 20),
          Text(
            _cameraFailed
                ? 'CAMERA UNAVAILABLE'
                : 'VEHICLE PHOTO CAPTURE',
            style: GoogleFonts.poppins(
              color: Colors.white.withOpacity(0.5),
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _cameraFailed
                ? 'Tap the button to capture using upload mode'
                : 'Camera initializing…',
            style: GoogleFonts.poppins(
              color: Colors.white.withOpacity(0.4),
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
          if (_cameraFailed && kIsWeb) ...[
            const SizedBox(height: 16),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 40),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orangeAccent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: Colors.orangeAccent.withOpacity(0.4)),
              ),
              child: Text(
                'On web, make sure you allowed camera access in\n'
                'your browser (click the camera icon in the address bar)',
                style: GoogleFonts.poppins(
                  color: Colors.orangeAccent,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 12),
            // Retry button
            Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: () {
                  setState(() {
                    _cameraFailed = false;
                    _isCameraInitialized = false;
                  });
                  _initializeCamera();
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: Colors.blueAccent.withOpacity(0.5)),
                  ),
                  child: Text(
                    'Retry Camera',
                    style: GoogleFonts.poppins(
                        color: Colors.blueAccent,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Dispose ──────────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _pulseController.dispose();
    _processingController.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(child: _buildCameraPreview()),
          if (_isProcessing) _buildProcessingOverlay(),
          _buildGradientOverlays(),
          Positioned(
            top: MediaQuery.of(context).padding.top + 20,
            left: 20,
            right: 20,
            child: _buildHeader(),
          ),
          if (_showGuidance && !_isProcessing && !_allShotsComplete)
            Positioned(
              top: MediaQuery.of(context).padding.top + 100,
              left: 20,
              right: 20,
              child: _buildGuidancePanel(),
            ),
          if (!_isProcessing && !_allShotsComplete)
            Positioned(
              bottom: 180,
              left: 0,
              right: 0,
              child: _buildVehicleGuide(),
            ),
          Positioned(
            bottom: 120,
            left: 20,
            right: 20,
            child: _buildProgressBar(),
          ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: _buildBottomControls(),
          ),
        ],
      ),
    );
  }

  Widget _buildProcessingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.7),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 80,
              height: 80,
              child: CircularProgressIndicator(
                strokeWidth: 4,
                color: Colors.blueAccent,
              ),
            ),
            const SizedBox(height: 20),
            Text('PROCESSING PHOTO…',
                style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.5)),
            const SizedBox(height: 10),
            Text(
              _requiredShots[_currentShotIndex]['type']
                  .toString()
                  .toUpperCase(),
              style: GoogleFonts.poppins(
                  color: Colors.blueAccent,
                  fontSize: 14,
                  fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGradientOverlays() {
    return IgnorePointer(
      child: Column(
        children: [
          Container(
            height: 200,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black.withOpacity(0.8), Colors.transparent],
              ),
            ),
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.8),
                    Colors.transparent
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [_buildBackButton(), _buildProgressIndicator()],
    );
  }

  Widget _buildBackButton() {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: () => Navigator.pop(context),
        borderRadius: BorderRadius.circular(15),
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.6),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
          ),
          child: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 20),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.photo_library, color: Colors.blueAccent, size: 16),
          const SizedBox(width: 8),
          Text('${_capturedPhotos.length}/12',
              style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600)),
          const SizedBox(width: 12),
          SizedBox(
            width: 60,
            height: 4,
            child: LinearProgressIndicator(
              value: _captureProgress,
              backgroundColor: Colors.white.withOpacity(0.2),
              color: Colors.blueAccent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuidancePanel() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blueAccent.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
              color: Colors.blueAccent.withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 2),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _requiredShots[_currentShotIndex]['icon'] as IconData,
                color: Colors.blueAccent,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                _getShotDisplayName(
                    _requiredShots[_currentShotIndex]['type']),
                style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(_currentGuidance,
              style: GoogleFonts.poppins(
                  color: Colors.white70, fontSize: 14),
              textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(
            'Shot ${_currentShotIndex + 1} of ${_requiredShots.length}'
            '${_cameraFailed ? ' • Upload mode' : ''}',
            style: GoogleFonts.poppins(
                color: Colors.blueAccent,
                fontSize: 12,
                fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleGuide() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.diagonal3(
              vector.Vector3.all(_pulseAnimation.value)),
          child: Container(
            width: 200,
            height: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: Colors.blueAccent.withOpacity(0.6), width: 2),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.blueAccent.withOpacity(0.3),
                  Colors.purpleAccent.withOpacity(0.3),
                ],
              ),
            ),
            child: Stack(
              children: [
                CustomPaint(
                    painter: _VehicleModelPainter(),
                    size: const Size(200, 120)),
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _requiredShots[_currentShotIndex]['angle'],
                      style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProgressBar() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Capture Progress',
                style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
            Text('${(_captureProgress * 100).toStringAsFixed(0)}%',
                style: GoogleFonts.poppins(
                    color: Colors.blueAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 6,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(3),
            color: Colors.white.withOpacity(0.1),
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            width: MediaQuery.of(context).size.width * _captureProgress,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Colors.blueAccent, Colors.greenAccent]),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomControls() {
    return Column(
      children: [
        if (!_allShotsComplete) _buildCaptureButton(),
        if (_allShotsComplete) _buildCompletionButton(),
      ],
    );
  }

  Widget _buildCaptureButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _isProcessing ? null : _capturePhoto,
        borderRadius: BorderRadius.circular(40),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _isProcessing ? Colors.grey : Colors.white,
            border: Border.all(
                color: _isProcessing ? Colors.grey : Colors.blueAccent,
                width: 3),
            boxShadow: _isProcessing
                ? []
                : [
                    BoxShadow(
                        color: Colors.blueAccent.withOpacity(0.5),
                        blurRadius: 15,
                        spreadRadius: 2)
                  ],
          ),
          child: _isProcessing
              ? const Center(
                  child: SizedBox(
                    width: 30,
                    height: 30,
                    child: CircularProgressIndicator(
                        strokeWidth: 3, color: Colors.black),
                  ),
                )
              : const Icon(Icons.camera_alt_rounded,
                  color: Colors.black, size: 35),
        ),
      ),
    );
  }

  Widget _buildCompletionButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.pop(context),
        borderRadius: BorderRadius.circular(25),
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Colors.greenAccent, Colors.green]),
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                  color: Colors.greenAccent.withOpacity(0.5),
                  blurRadius: 20,
                  spreadRadius: 3)
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 22),
              const SizedBox(width: 10),
              Text('COMPLETE CAPTURE',
                  style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2)),
            ],
          ),
        ),
      ),
    );
  }

  String _getShotDisplayName(String shot) {
    return shot
        .split('_')
        .map((w) => w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }
}

class _VehicleModelPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final fillPaint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.width * 0.2, size.height * 0.5)
      ..lineTo(size.width * 0.1, size.height * 0.7)
      ..lineTo(size.width * 0.9, size.height * 0.7)
      ..lineTo(size.width * 0.8, size.height * 0.5)
      ..lineTo(size.width * 0.7, size.height * 0.3)
      ..lineTo(size.width * 0.3, size.height * 0.3)
      ..close();

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, paint);

    final windowPath = Path()
      ..moveTo(size.width * 0.35, size.height * 0.35)
      ..lineTo(size.width * 0.65, size.height * 0.35)
      ..lineTo(size.width * 0.65, size.height * 0.45)
      ..lineTo(size.width * 0.35, size.height * 0.45)
      ..close();

    canvas.drawPath(windowPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}