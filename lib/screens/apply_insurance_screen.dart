import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'home_screen.dart';
import 'advanced_vehicle_capture.dart';

class ApplyInsuranceScreen extends StatefulWidget {
  final Map<String, dynamic>? initialQuoteData;
  final Map<String, dynamic>? quoteData; // Add this line

  const ApplyInsuranceScreen({
    super.key,
    this.initialQuoteData,
    this.quoteData, // Add this line
  });

  @override
  State<ApplyInsuranceScreen> createState() => _ApplyInsuranceScreenState();
}

class _ApplyInsuranceScreenState extends State<ApplyInsuranceScreen> {
  // Form controllers
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _coverDurationController = TextEditingController();

  // Form state
  bool _infoConfirmed = false;
  bool _termsAgreed = false;
  bool _isSubmitting = false;
  bool _showQuoteDetails = true;

  // File upload state
  Map<String, bool> _uploadedFiles = {
    'id_document': false,
    'proof_of_address': false,
    'vehicle_photos': false,
    'vehicle_registration': false,
  };

  Map<String, String> _fileNames = {
    'id_document': '',
    'proof_of_address': '',
    'vehicle_photos': '',
    'vehicle_registration': '',
  };

  Map<String, bool> _uploadingFiles = {
    'id_document': false,
    'proof_of_address': false,
    'vehicle_photos': false,
    'vehicle_registration': false,
  };

  final DatabaseReference _applicationsRef = FirebaseDatabase.instance.ref('insurance_applications');
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Cover duration options
  final List<String> _coverDurations = ['12 Months', '6 Months', '3 Months', '1 Month'];

  @override
  void initState() {
    super.initState();
    _initializeFormWithPreviousData();
  }

  void _initializeFormWithPreviousData() {
    if (widget.initialQuoteData != null) {
      final quoteData = widget.initialQuoteData!;
      
    }
  }

  Future<void> _uploadFile(String documentType) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        PlatformFile file = result.files.first;
        
        if (file.size > 5 * 1024 * 1024) {
          _showErrorSnackbar('File too large. Use smaller files (<5MB)');
          return;
        }

        setState(() {
          _uploadingFiles[documentType] = true;
        });

        // Simulated upload for now
        await _fastSimulatedUpload(documentType, file.name);
      }
    } catch (e) {
      _showErrorSnackbar('Upload failed');
      setState(() {
        _uploadingFiles[documentType] = false;
      });
    }
  }

  Future<void> _fastSimulatedUpload(String documentType, String fileName) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    setState(() {
      _uploadedFiles[documentType] = true;
      _fileNames[documentType] = fileName;
      _uploadingFiles[documentType] = false;
    });
    
    _showSuccessSnackbar('${_getDocumentDisplayName(documentType)} uploaded!');
  }

  void _launchAdvancedCapture() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdvancedVehicleCaptureScreen(
          onPhotosCaptured: (Map<String, String> photos) {
            if (photos.isNotEmpty) {
              setState(() {
                _uploadedFiles['vehicle_photos'] = true;
                _fileNames['vehicle_photos'] = '12 Vehicle Photos (3D Scanned)';
                _uploadingFiles['vehicle_photos'] = false;
              });
              _showSuccessSnackbar('Vehicle 3D scan completed successfully!');
            }
          },
        ),
      ),
    );
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
      _uploadedFiles[documentType] = false;
      _fileNames[documentType] = '';
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

  bool _isFormValid() {
    // Only require text fields to be filled, documents are optional for submission
    return _idController.text.isNotEmpty &&
           _contactController.text.isNotEmpty &&
           _addressController.text.isNotEmpty &&
           _coverDurationController.text.isNotEmpty &&
           _infoConfirmed && 
           _termsAgreed;
  }

  void _removeQuote() {
    setState(() {
      _showQuoteDetails = false;
    });
    _showSuccessSnackbar('Quote details removed');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 8, 18, 32),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildWelcomeSection(),
                    const SizedBox(height: 30),
                    _buildQuoteCard(),
                    const SizedBox(height: 30),
                    _buildPersonalVerification(),
                    const SizedBox(height: 30),
                    _buildDocumentUploads(),
                    const SizedBox(height: 30),
                    _buildDeclaration(),
                    const SizedBox(height: 40),
                    _buildSubmitButton(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Text(
            "Apply for Insurance",
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blueAccent.withOpacity(0.2),
            Colors.purpleAccent.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.greenAccent.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.rocket_launch, color: Colors.greenAccent, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Finalize Your Application",
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "Complete your application in minutes - Documents can be uploaded later",
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.greenAccent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuoteCard() {
    // Use either quoteData or initialQuoteData
    final quoteData = widget.quoteData ?? widget.initialQuoteData;
    if (quoteData == null || !_showQuoteDetails) return const SizedBox();

    final premiums = quoteData['premiums'] ?? {};
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blueAccent.withOpacity(0.15),
            Colors.purpleAccent.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with remove button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.price_check, color: Colors.blueAccent, size: 18),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Your Insurance Quote",
                    style: GoogleFonts.poppins(
                      color: Colors.blueAccent,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  onTap: _removeQuote,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                    ),
                    child: Icon(Icons.close, color: Colors.redAccent, size: 16),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 15),
          
          // Vehicle Info in a modern layout
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                // Vehicle Icon
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.directions_car, color: Colors.blueAccent, size: 24),
                ),
                const SizedBox(width: 12),
                // Vehicle Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${quoteData['brand']} ${quoteData['model']}",
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${quoteData['year']} • ${quoteData['color']} • ${quoteData['regNumber'] ?? 'N/A'}",
                        style: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        "Value: R${quoteData['value']}",
                        style: GoogleFonts.poppins(
                          color: Colors.greenAccent,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Premium Cards
          if (premiums.isNotEmpty) ...[
            Text(
              "Premium Options",
              style: GoogleFonts.poppins(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                if (premiums['comprehensive'] != null)
                  _buildPremiumChip("Comprehensive", "R${premiums['comprehensive']?.toStringAsFixed(0)}", Colors.blueAccent),
                if (premiums['smart'] != null)
                  _buildPremiumChip("Smart Plan", "R${premiums['smart']?.toStringAsFixed(0)}", Colors.greenAccent),
                if (premiums['third_party'] != null)
                  _buildPremiumChip("Third Party", "R${premiums['third_party']?.toStringAsFixed(0)}", Colors.orangeAccent),
              ],
            ),
          ],
          
          const SizedBox(height: 12),
          
          // Location and Coverage
          Row(
            children: [
              Expanded(
                child: _buildDetailItem(Icons.location_on, "Location", "${quoteData['province']}, ${quoteData['place']}"),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildDetailItem(Icons.security, "Coverage", quoteData['coverageType'] ?? 'Comprehensive'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumChip(String title, String price, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            price,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.blueAccent, size: 14),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 10,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalVerification() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.greenAccent.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.person, color: Colors.greenAccent, size: 18),
            ),
            const SizedBox(width: 8),
            Text(
              "Personal Information",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        _buildAdvancedTextField(_idController, "ID Number", Icons.badge, "Enter your ID or passport number"),
        const SizedBox(height: 12),
        _buildAdvancedTextField(_contactController, "Contact Number", Icons.phone, "Your mobile number"),
        const SizedBox(height: 12),
        _buildAdvancedTextField(_addressController, "Residential Address", Icons.home, "Your full residential address"),
        const SizedBox(height: 12),
        _buildCoverDurationDropdown(),
      ],
    );
  }

  Widget _buildAdvancedTextField(TextEditingController controller, String label, IconData icon, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            color: Colors.white70,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 55,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.1),
                Colors.white.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                alignment: Alignment.center,
                child: Icon(icon, color: Colors.white54, size: 20),
              ),
              Expanded(
                child: TextField(
                  controller: controller,
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: GoogleFonts.poppins(color: Colors.white54, fontSize: 14),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.only(right: 15),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCoverDurationDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Cover Duration",
          style: GoogleFonts.poppins(
            color: Colors.white70,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 55,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.1),
                Colors.white.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                alignment: Alignment.center,
                child: Icon(Icons.calendar_today, color: Colors.white54, size: 20),
              ),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _coverDurationController.text.isEmpty ? null : _coverDurationController.text,
                  items: _coverDurations.map((String duration) {
                    return DropdownMenuItem<String>(
                      value: duration,
                      child: Text(
                        duration,
                        style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
                      ),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _coverDurationController.text = newValue!;
                    });
                  },
                  dropdownColor: const Color.fromARGB(255, 16, 52, 90),
                  style: GoogleFonts.poppins(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "Select cover duration",
                    hintStyle: GoogleFonts.poppins(color: Colors.white54, fontSize: 14),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.only(right: 15),
                  ),
                  icon: Icon(Icons.arrow_drop_down, color: Colors.white70),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentUploads() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.orangeAccent.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.attach_file, color: Colors.orangeAccent, size: 18),
            ),
            const SizedBox(width: 8),
            Text(
              "Document Uploads (Optional)",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          "You can upload these documents now or later - Application can be submitted without them",
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.greenAccent,
          ),
        ),
        const SizedBox(height: 15),
        _buildUploadItem("id_document", "ID Document", Icons.badge, Colors.blueAccent),
        const SizedBox(height: 10),
        _buildUploadItem("proof_of_address", "Proof of Address", Icons.home_work, Colors.greenAccent),
        const SizedBox(height: 10),
        _buildVehiclePhotosUpload(),
        const SizedBox(height: 10),
        _buildUploadItem("vehicle_registration", "Vehicle Registration", Icons.description, Colors.purpleAccent),
      ],
    );
  }

  Widget _buildVehiclePhotosUpload() {
    final isUploaded = _uploadedFiles['vehicle_photos']!;
    final isUploading = _uploadingFiles['vehicle_photos']!;
    final fileName = _fileNames['vehicle_photos']!;

    return Column(
      children: [
        // Regular Upload Option
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orangeAccent.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.camera_alt, color: Colors.orangeAccent, size: 24),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Vehicle Photos",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    if (isUploaded && fileName.isNotEmpty)
                      Text(
                        fileName,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.greenAccent,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (isUploading)
                      Text(
                        "Uploading...",
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.orangeAccent,
                        ),
                      ),
                  ],
                ),
              ),
              if (isUploading)
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.orangeAccent),
                )
              else if (isUploaded)
                Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 22),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _removeFile('vehicle_photos'),
                      child: Icon(Icons.close, color: Colors.red, size: 18),
                    ),
                  ],
                )
              else
                Material(
                  color: Colors.orangeAccent,
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    onTap: () => _uploadFile('vehicle_photos'),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: Text(
                        "Upload",
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        
        // 3D Capture Recommendation
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.purpleAccent.withOpacity(0.2), Colors.blueAccent.withOpacity(0.1)],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.purpleAccent.withOpacity(0.4)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purpleAccent.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.photo_camera, color: Colors.purpleAccent, size: 20),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Recommended: 3D Vehicle Capture",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      "Enhanced documentation for faster processing",
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  onTap: _launchAdvancedCapture,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.purpleAccent, Colors.blueAccent],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.camera_enhance, color: Colors.white, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          "3D SCAN",
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
        ),
      ],
    );
  }

  Widget _buildUploadItem(String documentType, String title, IconData icon, Color color) {
    final isUploaded = _uploadedFiles[documentType]!;
    final isUploading = _uploadingFiles[documentType]!;
    final fileName = _fileNames[documentType]!;

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                if (isUploaded && fileName.isNotEmpty)
                  Text(
                    fileName,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.greenAccent,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (isUploading)
                  Text(
                    "Uploading...",
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.orangeAccent,
                    ),
                  ),
              ],
            ),
          ),
          if (isUploading)
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: color),
            )
          else if (isUploaded)
            Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 22),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _removeFile(documentType),
                  child: Icon(Icons.close, color: Colors.red, size: 18),
                ),
              ],
            )
          else
            Material(
              color: color,
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                onTap: () => _uploadFile(documentType),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Text(
                    "Upload",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDeclaration() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.verified_user, color: Colors.redAccent, size: 18),
            ),
            const SizedBox(width: 8),
            Text(
              "Declaration",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        _buildAdvancedCheckbox(
          "I confirm all information provided is true and accurate to the best of my knowledge",
          _infoConfirmed,
          (value) => setState(() => _infoConfirmed = value ?? false),
        ),
        const SizedBox(height: 10),
        _buildAdvancedCheckbox(
          "I agree to the Terms & Conditions and Privacy Policy of AutoSure Insurance", 
          _termsAgreed,
          (value) => setState(() => _termsAgreed = value ?? false),
        ),
      ],
    );
  }

  Widget _buildAdvancedCheckbox(String title, bool value, ValueChanged<bool?> onChanged) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => onChanged(!value),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: value ? Colors.greenAccent.withOpacity(0.1) : Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: value ? Colors.greenAccent.withOpacity(0.3) : Colors.white.withOpacity(0.1),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: value ? Colors.greenAccent : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: value ? Colors.greenAccent : Colors.white54,
                  ),
                ),
                child: value ? Icon(Icons.check, color: Colors.white, size: 16) : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    color: value ? Colors.greenAccent : Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    final isEnabled = _isFormValid() && !_isSubmitting;
    
    return Column(
      children: [
        if (!isEnabled && !_isSubmitting) 
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orangeAccent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.orangeAccent.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info, color: Colors.orangeAccent, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Fill in all required fields and agree to declarations to submit',
                    style: GoogleFonts.poppins(
                      color: Colors.orangeAccent,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 15),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isEnabled ? _submitApplication : null,
            borderRadius: BorderRadius.circular(15),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                gradient: isEnabled
                    ? const LinearGradient(
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
              child: Center(
                child: _isSubmitting
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            "SUBMITTING...",
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.send_rounded, color: Colors.white, size: 20),
                          const SizedBox(width: 12),
                          Text(
                            "SUBMIT APPLICATION",
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _submitApplication() async {
    if (!_isFormValid()) return;

    setState(() => _isSubmitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Please log in');

      // Generate a unique application ID
      final applicationId = _applicationsRef.push().key;
      
      Map<String, dynamic> applicationData = {
        'personalInfo': {
          'idNumber': _idController.text,
          'contactNumber': _contactController.text,
          'address': _addressController.text,
          'coverDuration': _coverDurationController.text,
        },
        'documents': _uploadedFiles,
        'fileNames': _fileNames,
        'status': 'submitted',
        'submittedAt': DateTime.now().millisecondsSinceEpoch,
        'userId': user.uid,
        'userEmail': user.email ?? 'unknown',
        'applicationId': applicationId,
      };

      // Use either quoteData or initialQuoteData
      final quoteData = widget.quoteData ?? widget.initialQuoteData;
      if (quoteData != null) {
        applicationData['quoteData'] = quoteData;
      }

      // Save under a unique application ID for proper querying
      await _applicationsRef.child(applicationId!).set(applicationData);
      
      _showSuccessSnackbar('🎉 Application submitted successfully!');
      
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen(username: user.displayName ?? 'User')),
          (route) => false,
        );
      }

    } catch (e) {
      _showErrorSnackbar('Submission failed: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}