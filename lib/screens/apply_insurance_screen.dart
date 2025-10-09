import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'home_screen.dart';

class ApplyInsuranceScreen extends StatefulWidget {
  const ApplyInsuranceScreen({super.key});

  @override
  State<ApplyInsuranceScreen> createState() => _ApplyInsuranceScreenState();
}

class _ApplyInsuranceScreenState extends State<ApplyInsuranceScreen> with TickerProviderStateMixin {
  late AnimationController _masterController;
  late AnimationController _glowController;
  late AnimationController _particleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  // Form controllers
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  
  // Focus nodes
  final _idFocusNode = FocusNode();
  final _contactFocusNode = FocusNode();
  final _addressFocusNode = FocusNode();
  bool _isIdFocused = false;
  bool _isContactFocused = false;
  bool _isAddressFocused = false;

  // Form state
  bool _infoConfirmed = false;
  bool _termsAgreed = false;
  double _scrollOffset = 0.0;
  bool _showFloatingHeader = true;
  bool _isSubmitting = false;

  // File upload state - simplified for web compatibility
  Map<String, Map<String, dynamic>> _uploadedFiles = {
    'id_document': {'name': '', 'uploaded': false, 'url': ''},
    'proof_of_address': {'name': '', 'uploaded': false, 'url': ''},
    'vehicle_photos': {'name': '', 'uploaded': false, 'url': ''},
    'vehicle_registration': {'name': '', 'uploaded': false, 'url': ''},
  };

  Map<String, double> _uploadProgress = {};

  final ScrollController _scrollController = ScrollController();
  final DatabaseReference _applicationsRef = FirebaseDatabase.instance.ref('insurance_applications');
  final FirebaseStorage _storage = FirebaseStorage.instance;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _setupScrollListener();
  }

  void _initializeControllers() {
    _masterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _masterController, curve: Curves.easeInOutQuart),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _masterController, curve: Curves.elasticOut),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _masterController,
      curve: Curves.easeOutBack,
    ));

    _masterController.forward();

    // Focus node listeners
    _idFocusNode.addListener(() {
      if (mounted) {
        setState(() {
          _isIdFocused = _idFocusNode.hasFocus;
        });
      }
    });
    
    _contactFocusNode.addListener(() {
      if (mounted) {
        setState(() {
          _isContactFocused = _contactFocusNode.hasFocus;
        });
      }
    });
    
    _addressFocusNode.addListener(() {
      if (mounted) {
        setState(() {
          _isAddressFocused = _addressFocusNode.hasFocus;
        });
      }
    });
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      setState(() {
        _scrollOffset = _scrollController.offset;
        _showFloatingHeader = _scrollOffset < 100;
      });
    });
  }

  // Web-compatible file upload methods
  Future<void> _uploadFile(String documentType) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf', 'doc', 'docx'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        PlatformFile file = result.files.first;
        
        // Check file size (max 10MB)
        if (file.size > 10 * 1024 * 1024) {
          _showErrorSnackbar('File size must be less than 10MB');
          return;
        }

        // Check if we have bytes (web-compatible)
        if (file.bytes == null) {
          _showErrorSnackbar('Could not read file. Please try again.');
          return;
        }

        setState(() {
          _uploadedFiles[documentType] = {
            'name': file.name,
            'uploaded': false,
            'url': ''
          };
        });

        // Start upload to Firebase Storage
        await _startFileUpload(documentType, file);
      }
    } catch (e) {
      _showErrorSnackbar('Failed to pick file: $e');
    }
  }

  Future<void> _startFileUpload(String documentType, PlatformFile file) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showErrorSnackbar('Please log in to upload files');
        return;
      }

      String fileName = '${user.uid}_${documentType}_${DateTime.now().millisecondsSinceEpoch}.${_getFileExtension(file.name)}';
      Reference storageRef = _storage.ref().child('insurance_applications/$fileName');
      
      // Use bytes directly for web compatibility
      final UploadTask uploadTask = storageRef.putData(
        file.bytes!,
        SettableMetadata(contentType: _getMimeType(file.name)),
      );

      setState(() {
        _uploadProgress[documentType] = 0.0;
      });

      // Listen to upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        setState(() {
          _uploadProgress[documentType] = snapshot.bytesTransferred / snapshot.totalBytes;
        });
      });

      // Wait for upload to complete
      TaskSnapshot snapshot = await uploadTask;
      
      // Get download URL
      String downloadURL = await snapshot.ref.getDownloadURL();
      
      // Update file state
      setState(() {
        _uploadedFiles[documentType] = {
          'name': file.name,
          'uploaded': true,
          'url': downloadURL
        };
        _uploadProgress[documentType] = 1.0;
      });

      // Store file info in Realtime Database
      await _applicationsRef.child(user.uid).child('documents').child(documentType).set({
        'fileName': file.name,
        'fileUrl': downloadURL,
        'uploadedAt': DateTime.now().millisecondsSinceEpoch,
        'fileSize': file.size,
      });

      _showSuccessSnackbar('${_getDocumentDisplayName(documentType)} uploaded successfully!');

    } catch (e) {
      _showErrorSnackbar('Upload failed: $e');
      setState(() {
        _uploadedFiles[documentType] = {'name': '', 'uploaded': false, 'url': ''};
        _uploadProgress[documentType] = 0.0;
      });
    }
  }

  String _getFileExtension(String fileName) {
    return fileName.split('.').last.toLowerCase();
  }

  String _getMimeType(String fileName) {
    final extension = _getFileExtension(fileName);
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      default:
        return 'application/octet-stream';
    }
  }

  String _getDocumentDisplayName(String documentType) {
    switch (documentType) {
      case 'id_document': return "ID Document";
      case 'proof_of_address': return "Proof of Address";
      case 'vehicle_photos': return "Vehicle Photos";
      case 'vehicle_registration': return "Vehicle Registration";
      default: return "Document";
    }
  }

  void _removeFile(String documentType) {
    setState(() {
      _uploadedFiles[documentType] = {'name': '', 'uploaded': false, 'url': ''};
      _uploadProgress[documentType] = 0.0;
    });
    _showSuccessSnackbar('${_getDocumentDisplayName(documentType)} removed');
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  bool _areRequiredDocumentsUploaded() {
    return _uploadedFiles['id_document']!['uploaded'] && 
           _uploadedFiles['proof_of_address']!['uploaded'] && 
           _uploadedFiles['vehicle_photos']!['uploaded'];
  }

  bool _isFormValid() {
    return _idController.text.isNotEmpty &&
           _contactController.text.isNotEmpty &&
           _addressController.text.isNotEmpty &&
           _infoConfirmed &&
           _termsAgreed &&
           _areRequiredDocumentsUploaded();
  }

  @override
  void dispose() {
    _masterController.dispose();
    _glowController.dispose();
    _particleController.dispose();
    _scrollController.dispose();
    _idController.dispose();
    _contactController.dispose();
    _addressController.dispose();
    _idFocusNode.dispose();
    _contactFocusNode.dispose();
    _addressFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 8, 18, 32),
      body: Stack(
        children: [
          _buildAdvancedBackground(),
          _buildQuantumParticles(),
          CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              const SliverAppBar(
                expandedHeight: 120,
                floating: false,
                pinned: false,
                snap: false,
                elevation: 0,
                backgroundColor: Colors.transparent,
                automaticallyImplyLeading: false,
              ),
              SliverToBoxAdapter(
                child: _buildMainContent(),
              ),
            ],
          ),
          _buildFloatingHeader(),
          Positioned(
            top: 140,
            left: 25,
            child: _buildBackButton(),
          ),
          if (_isSubmitting) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildFloatingHeader() {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      top: _showFloatingHeader ? 40 : -100,
      left: 0,
      right: 0,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color.fromARGB(255, 16, 52, 90).withOpacity(0.95),
                  const Color.fromARGB(255, 8, 26, 45).withOpacity(0.9),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "AutoSure",
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 1.1,
                      ),
                    ),
                    Text(
                      "Apply for Insurance",
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blueAccent, Colors.lightBlue],
                    ),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.security, color: Colors.white, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        "Step 2/2",
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton() {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(15),
          child: InkWell(
            onTap: () => Navigator.maybePop(context),
            borderRadius: BorderRadius.circular(15),
            child: Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.15),
                    Colors.white.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blueAccent.withOpacity(0.3),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return Padding(
      padding: const EdgeInsets.all(25.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeSection(),
          const SizedBox(height: 30),
          _buildPersonalVerification(),
          const SizedBox(height: 30),
          _buildDocumentUploads(),
          const SizedBox(height: 30),
          _buildDeclaration(),
          const SizedBox(height: 40),
          _buildSubmitButton(),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.15),
                Colors.white.withOpacity(0.08),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Finalize Application",
                style: GoogleFonts.poppins(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Complete your insurance application with secure verification",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 15),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.greenAccent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.greenAccent.withOpacity(0.3)),
                ),
                child: Text(
                  "Step 2 of 2 - Final Verification",
                  style: GoogleFonts.poppins(
                    color: Colors.greenAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPersonalVerification() {
    return SlideTransition(
      position: _slideAnimation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Personal Verification",
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          _buildPremiumTextField(
            controller: _idController,
            focusNode: _idFocusNode,
            isFocused: _isIdFocused,
            hintText: "ID Number or Passport Number",
            prefixIcon: Icons.badge_rounded,
          ),
          const SizedBox(height: 15),
          _buildPremiumTextField(
            controller: _contactController,
            focusNode: _contactFocusNode,
            isFocused: _isContactFocused,
            hintText: "Contact Number",
            prefixIcon: Icons.phone_rounded,
          ),
          const SizedBox(height: 15),
          _buildPremiumTextField(
            controller: _addressController,
            focusNode: _addressFocusNode,
            isFocused: _isAddressFocused,
            hintText: "Residential Address",
            prefixIcon: Icons.home_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required bool isFocused,
    required String hintText,
    required IconData prefixIcon,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isFocused
              ? [
                  Colors.white.withOpacity(0.25),
                  Colors.white.withOpacity(0.15),
                ]
              : [
                  Colors.white.withOpacity(0.15),
                  Colors.white.withOpacity(0.08),
                ],
        ),
        boxShadow: isFocused
            ? [
                BoxShadow(
                  color: Colors.blueAccent.withOpacity(0.4),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
        border: Border.all(
          color: isFocused ? Colors.blueAccent.withOpacity(0.6) : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: GoogleFonts.poppins(
            color: Colors.white54,
            fontSize: 16,
          ),
          border: InputBorder.none,
          prefixIcon: Icon(
            prefixIcon,
            color: isFocused ? Colors.blueAccent.shade200 : Colors.white54,
            size: 20,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        ),
      ),
    );
  }

  Widget _buildDocumentUploads() {
    return SlideTransition(
      position: _slideAnimation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Document Uploads",
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "Supported formats: JPG, PNG, PDF, DOC (Max 10MB)",
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.white54,
            ),
          ),
          const SizedBox(height: 20),
          _buildUploadItem("id_document", "ID/Driver's License", Icons.badge_rounded, Colors.blueAccent),
          const SizedBox(height: 12),
          _buildUploadItem("proof_of_address", "Proof of Address", Icons.home_work_rounded, Colors.greenAccent),
          const SizedBox(height: 12),
          _buildUploadItem("vehicle_photos", "Vehicle Photos", Icons.camera_alt_rounded, Colors.orangeAccent),
          const SizedBox(height: 12),
          _buildUploadItem("vehicle_registration", "Vehicle Registration", Icons.description_rounded, Colors.purpleAccent, optional: true),
        ],
      ),
    );
  }

  Widget _buildUploadItem(String documentType, String title, IconData icon, Color color, {bool optional = false}) {
    final isUploading = _uploadProgress[documentType] != null && _uploadProgress[documentType]! < 1.0;
    final hasFile = _uploadedFiles[documentType]!['uploaded'];
    final progress = _uploadProgress[documentType] ?? 0.0;
    final fileName = _uploadedFiles[documentType]!['name'];

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.2), color.withOpacity(0.05)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      if (optional)
                        Text(
                          "Optional",
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.white54,
                          ),
                        ),
                      if (hasFile && !isUploading)
                        Text(
                          fileName,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                if (isUploading)
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 3,
                      color: color,
                    ),
                  )
                else if (hasFile)
                  Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 20),
                      const SizedBox(width: 8),
                      Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        child: InkWell(
                          onTap: () => _removeFile(documentType),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            child: Icon(Icons.close, color: Colors.red, size: 16),
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: () => _uploadFile(documentType),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [color, color.withOpacity(0.7)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.upload_rounded, color: Colors.white, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              "Upload",
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            if (isUploading) ...[
              const SizedBox(height: 10),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.white.withOpacity(0.1),
                color: color,
                borderRadius: BorderRadius.circular(5),
              ),
              const SizedBox(height: 5),
              Text(
                '${(progress * 100).toStringAsFixed(1)}%',
                style: GoogleFonts.poppins(
                  color: Colors.white70,
                  fontSize: 10,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDeclaration() {
    return SlideTransition(
      position: _slideAnimation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Declaration",
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          _buildDeclarationItem(
            "I confirm all information is true and accurate",
            _infoConfirmed,
            Icons.verified_rounded,
            Colors.greenAccent,
            (value) => setState(() => _infoConfirmed = value ?? false),
          ),
          const SizedBox(height: 12),
          _buildDeclarationItem(
            "I agree to the Terms & Conditions",
            _termsAgreed,
            Icons.description_rounded,
            Colors.blueAccent,
            (value) => setState(() => _termsAgreed = value ?? false),
          ),
        ],
      ),
    );
  }

  Widget _buildDeclarationItem(String title, bool value, IconData icon, Color color, ValueChanged<bool?> onChanged) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: () => onChanged(!value),
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: value
                  ? [color.withOpacity(0.3), color.withOpacity(0.1)]
                  : [Colors.white.withOpacity(0.1), Colors.white.withOpacity(0.05)],
            ),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: value ? color.withOpacity(0.3) : Colors.white.withOpacity(0.1)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: value ? color.withOpacity(0.2) : Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: value ? color : Colors.white54,
                  size: 20,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    color: value ? Colors.white : Colors.white70,
                    fontSize: 14,
                    fontWeight: value ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: value ? color : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: value ? color : Colors.white54,
                    width: 2,
                  ),
                ),
                child: value
                    ? Icon(Icons.check, color: Colors.white, size: 16)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    final isEnabled = _isFormValid() && !_isSubmitting;
    
    return Center(
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: isEnabled ? _submitApplication : null,
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: isEnabled
                  ? LinearGradient(
                      colors: [Colors.greenAccent, Colors.green],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : LinearGradient(
                      colors: [Colors.grey.shade600, Colors.grey.shade400],
                    ),
              boxShadow: isEnabled
                  ? [
                      BoxShadow(
                        color: Colors.greenAccent.withOpacity(0.5),
                        blurRadius: 20,
                        spreadRadius: 3,
                      ),
                    ]
                  : null,
            ),
            child: _isSubmitting
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "SUBMIT APPLICATION",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Future<void> _submitApplication() async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not logged in');

      // Prepare document URLs
      Map<String, dynamic> documents = {};
      _uploadedFiles.forEach((key, value) {
        if (value['uploaded']) {
          documents[key] = {
            'fileName': value['name'],
            'fileUrl': value['url'],
            'uploadedAt': DateTime.now().millisecondsSinceEpoch,
          };
        }
      });

      // Save application data to Firebase
      await _applicationsRef.child(user.uid).set({
        'personalInfo': {
          'idNumber': _idController.text,
          'contactNumber': _contactController.text,
          'address': _addressController.text,
        },
        'documents': documents,
        'status': 'pending',
        'submittedAt': DateTime.now().millisecondsSinceEpoch,
        'userId': user.uid,
      });

      _showSuccessSnackbar('Application submitted successfully!');
      
      // Navigate to home screen after success
      await Future.delayed(const Duration(seconds: 2));
      
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const HomeScreen(username: 'User'),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              const begin = Offset(0.0, 1.0);
              const end = Offset.zero;
              const curve = Curves.easeInOutQuart;
              var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
              return SlideTransition(position: animation.drive(tween), child: child);
            },
            transitionDuration: const Duration(milliseconds: 800),
          ),
          (route) => false,
        );
      }

    } catch (e) {
      _showErrorSnackbar('Failed to submit application: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.7),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.greenAccent),
            ),
            const SizedBox(height: 20),
            Text(
              "Submitting Application...",
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedBackground() {
    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0.5, _glowController.value - 0.5),
              radius: 2.0,
              colors: [
                const Color.fromARGB(255, 16, 52, 90).withOpacity(0.9),
                const Color.fromARGB(255, 8, 25, 45),
                const Color.fromARGB(255, 4, 15, 26),
              ],
              stops: const [0.1, 0.6, 1.0],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuantumParticles() {
    return AnimatedBuilder(
      animation: _particleController,
      builder: (context, child) {
        return Stack(
          children: [
            for (int i = 0; i < 6; i++)
              Positioned(
                left: (i * 120) % MediaQuery.of(context).size.width,
                top: (i * 100) % MediaQuery.of(context).size.height,
                child: _QuantumParticle(
                  size: 2 + (i % 3).toDouble(),
                  delay: i * 0.5,
                  controller: _particleController,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _QuantumParticle extends StatelessWidget {
  final double size;
  final double delay;
  final AnimationController controller;

  const _QuantumParticle({
    required this.size,
    required this.delay,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final animationValue = (controller.value + delay) % 1.0;
        return Opacity(
          opacity: 0.2 + animationValue * 0.3,
          child: Transform.translate(
            offset: Offset(
              (animationValue * 2 - 1) * 40,
              (animationValue * 3 - 1.5) * 25,
            ),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.blueAccent.withOpacity(0.6),
                    Colors.lightBlue.withOpacity(0.2),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}