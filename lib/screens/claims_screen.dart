import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ClaimsScreen extends StatefulWidget {
  const ClaimsScreen({super.key});

  @override
  State<ClaimsScreen> createState() => _ClaimsScreenState();
}

class _ClaimsScreenState extends State<ClaimsScreen> with TickerProviderStateMixin {
  late AnimationController _masterController;
  late AnimationController _glowController;
  late AnimationController _particleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  final ScrollController _scrollController = ScrollController();
  final DatabaseReference _claimsRef = FirebaseDatabase.instance.ref('claims');
  final DatabaseReference _policiesRef = FirebaseDatabase.instance.ref('policies');
  final DatabaseReference _usersRef = FirebaseDatabase.instance.ref('users');

  // Form controllers
  final TextEditingController _incidentDateController = TextEditingController();
  final TextEditingController _incidentTimeController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _damageDescriptionController = TextEditingController();
  final TextEditingController _estimatedCostController = TextEditingController();

  // Focus nodes
  final _locationFocusNode = FocusNode();
  final _descriptionFocusNode = FocusNode();
  final _damageFocusNode = FocusNode();
  final _costFocusNode = FocusNode();

  bool _isLocationFocused = false;
  bool _isDescriptionFocused = false;
  bool _isDamageFocused = false;
  bool _isCostFocused = false;

  // Form state
  String _selectedClaimType = 'Accident';
  String _selectedPolicy = '';
  String _selectedSeverity = 'Medium';
  bool _otherPartyInvolved = false;
  bool _policeReportFiled = false;
  bool _termsAgreed = false;
  bool _isSubmitting = false;
  double _scrollOffset = 0.0;
  bool _showFloatingHeader = true;

  // Image handling
  final ImagePicker _imagePicker = ImagePicker();
  List<XFile> _selectedImages = [];

  // User policies
  List<Map<String, dynamic>> _userPolicies = [];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _setupScrollListener();
    _loadUserPolicies();
    _setCurrentDateTime();
    _setupFocusNodeListeners();
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
  }

  void _setupFocusNodeListeners() {
    _locationFocusNode.addListener(() => setState(() => _isLocationFocused = _locationFocusNode.hasFocus));
    _descriptionFocusNode.addListener(() => setState(() => _isDescriptionFocused = _descriptionFocusNode.hasFocus));
    _damageFocusNode.addListener(() => setState(() => _isDamageFocused = _damageFocusNode.hasFocus));
    _costFocusNode.addListener(() => setState(() => _isCostFocused = _costFocusNode.hasFocus));
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      setState(() {
        _scrollOffset = _scrollController.offset;
        _showFloatingHeader = _scrollOffset < 100;
      });
    });
  }

  void _loadUserPolicies() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _policiesRef.orderByChild('userId').equalTo(user.uid).onValue.listen((event) {
      final data = event.snapshot.value;
      if (data != null && data is Map) {
        setState(() {
          _userPolicies = _convertFirebaseDataToList(data);
          if (_userPolicies.isNotEmpty) {
            _selectedPolicy = _userPolicies.first['id'] ?? '';
          }
        });
      }
    });
  }

  List<Map<String, dynamic>> _convertFirebaseDataToList(Map data) {
    return data.entries.map((entry) {
      final itemData = Map<String, dynamic>.from(entry.value as Map);
      return {
        'id': entry.key,
        ...itemData,
      };
    }).toList();
  }

  void _setCurrentDateTime() {
    final now = DateTime.now();
    _incidentDateController.text = '${now.day}/${now.month}/${now.year}';
    _incidentTimeController.text = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _masterController.dispose();
    _glowController.dispose();
    _particleController.dispose();
    _scrollController.dispose();
    _locationFocusNode.dispose();
    _descriptionFocusNode.dispose();
    _damageFocusNode.dispose();
    _costFocusNode.dispose();
    _incidentDateController.dispose();
    _incidentTimeController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _damageDescriptionController.dispose();
    _estimatedCostController.dispose();
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
              SliverToBoxAdapter(child: _buildMainContent()),
            ],
          ),
          _buildFloatingHeader(),
          Positioned(top: 140, left: 25, child: _buildBackButton()),
          if (_isSubmitting) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.7),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
            ),
            const SizedBox(height: 20),
            Text(
              "Submitting Claim...",
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Please wait while we process your claim",
              style: GoogleFonts.poppins(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ],
        ),
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
              border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
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
                      "Claim Submission",
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
                      colors: [Colors.orangeAccent, Colors.orange],
                    ),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.white, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        "Claim Center",
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
          _buildPolicySelection(),
          const SizedBox(height: 20),
          _buildClaimTypeSelection(),
          const SizedBox(height: 20),
          _buildIncidentDetails(),
          const SizedBox(height: 20),
          _buildDamageDetails(),
          const SizedBox(height: 20),
          _buildEvidenceUpload(),
          const SizedBox(height: 20),
          _buildAdditionalInfo(),
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
                "Submit Insurance Claim",
                style: GoogleFonts.poppins(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Report an incident and get the support you need",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 15),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orangeAccent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.orangeAccent.withOpacity(0.3)),
                ),
                child: Text(
                  "24/7 Claims Support Available",
                  style: GoogleFonts.poppins(
                    color: Colors.orangeAccent,
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

  Widget _buildPolicySelection() {
    return SlideTransition(
      position: _slideAnimation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Select Policy",
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 15),
          _userPolicies.isEmpty
              ? _buildNoPoliciesState()
              : Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.blueAccent.withOpacity(0.2),
                        Colors.blueAccent.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedPolicy,
                      isExpanded: true,
                      icon: Icon(Icons.arrow_drop_down_rounded, color: Colors.white70),
                      dropdownColor: const Color.fromARGB(255, 16, 52, 90),
                      style: GoogleFonts.poppins(color: Colors.white, fontSize: 16),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedPolicy = newValue!;
                        });
                      },
                      items: _userPolicies.map<DropdownMenuItem<String>>((policy) {
                        return DropdownMenuItem<String>(
                          value: policy['id'],
                          child: Text(
                            "${policy['policyNumber']} - ${policy['vehicleModel']}",
                            style: GoogleFonts.poppins(color: Colors.white),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildNoPoliciesState() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.redAccent.withOpacity(0.2),
            Colors.redAccent.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 40),
          const SizedBox(height: 10),
          Text(
            "No Active Policies",
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            "You need an active policy to submit a claim",
            style: GoogleFonts.poppins(
              color: Colors.white70,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildClaimTypeSelection() {
    return SlideTransition(
      position: _slideAnimation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Claim Type",
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 15),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildClaimTypeOption("Accident", Icons.car_crash_rounded, Colors.redAccent),
              _buildClaimTypeOption("Theft", Icons.security_rounded, Colors.orangeAccent),
              _buildClaimTypeOption("Damage", Icons.handyman_rounded, Colors.yellowAccent),
              _buildClaimTypeOption("Fire", Icons.local_fire_department_rounded, Colors.deepOrange),
              _buildClaimTypeOption("Weather", Icons.thunderstorm_rounded, Colors.blueAccent),
              _buildClaimTypeOption("Vandalism", Icons.breakfast_dining_rounded, Colors.purpleAccent),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildClaimTypeOption(String type, IconData icon, Color color) {
    final isSelected = _selectedClaimType == type;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: () => setState(() => _selectedClaimType = type),
        borderRadius: BorderRadius.circular(15),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isSelected
                  ? [color.withOpacity(0.4), color.withOpacity(0.2)]
                  : [Colors.white.withOpacity(0.1), Colors.white.withOpacity(0.05)],
            ),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: isSelected ? color.withOpacity(0.6) : Colors.white.withOpacity(0.2),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: isSelected ? color : Colors.white70, size: 24),
              const SizedBox(height: 8),
              Text(
                type,
                style: GoogleFonts.poppins(
                  color: isSelected ? color : Colors.white70,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIncidentDetails() {
    return SlideTransition(
      position: _slideAnimation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Incident Details",
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: _buildDateTimeField("Date", _incidentDateController, Icons.calendar_today_rounded),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _buildDateTimeField("Time", _incidentTimeController, Icons.access_time_rounded),
              ),
            ],
          ),
          const SizedBox(height: 15),
          _buildPremiumTextField(
            controller: _locationController,
            focusNode: _locationFocusNode,
            isFocused: _isLocationFocused,
            hintText: "Incident Location",
            prefixIcon: Icons.location_on_rounded,
          ),
          const SizedBox(height: 15),
          _buildDescriptionField(),
        ],
      ),
    );
  }

  Widget _buildDateTimeField(String label, TextEditingController controller, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            color: Colors.white70,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.15),
                Colors.white.withOpacity(0.08),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: TextField(
            controller: controller,
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 16),
            decoration: InputDecoration(
              hintText: label,
              hintStyle: GoogleFonts.poppins(color: Colors.white54),
              border: InputBorder.none,
              prefixIcon: Icon(icon, color: Colors.white70, size: 20),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionField() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: _isDescriptionFocused
              ? [
                  Colors.white.withOpacity(0.25),
                  Colors.white.withOpacity(0.15),
                ]
              : [
                  Colors.white.withOpacity(0.15),
                  Colors.white.withOpacity(0.08),
                ],
        ),
        boxShadow: _isDescriptionFocused
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
          color: _isDescriptionFocused ? Colors.blueAccent.withOpacity(0.6) : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: TextField(
        controller: _descriptionController,
        focusNode: _descriptionFocusNode,
        maxLines: 4,
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: "Describe what happened in detail...",
          hintStyle: GoogleFonts.poppins(
            color: Colors.white54,
            fontSize: 16,
          ),
          border: InputBorder.none,
          prefixIcon: Icon(
            Icons.description_rounded,
            color: _isDescriptionFocused ? Colors.blueAccent.shade200 : Colors.white54,
            size: 20,
          ),
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }

  Widget _buildDamageDetails() {
    return SlideTransition(
      position: _slideAnimation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Damage Assessment",
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 15),
          _buildPremiumTextField(
            controller: _damageDescriptionController,
            focusNode: _damageFocusNode,
            isFocused: _isDamageFocused,
            hintText: "Describe the damage to your vehicle",
            prefixIcon: Icons.build_rounded,
          ),
          const SizedBox(height: 15),
          _buildSeveritySelector(),
          const SizedBox(height: 15),
          _buildPremiumTextField(
            controller: _estimatedCostController,
            focusNode: _costFocusNode,
            isFocused: _isCostFocused,
            hintText: "Estimated Repair Cost (\$)",
            prefixIcon: Icons.attach_money_rounded,
            keyboardType: TextInputType.number,
          ),
        ],
      ),
    );
  }

  Widget _buildSeveritySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Damage Severity",
          style: GoogleFonts.poppins(
            color: Colors.white70,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildSeverityOption("Minor", Colors.greenAccent, 0),
            const SizedBox(width: 10),
            _buildSeverityOption("Medium", Colors.orangeAccent, 1),
            const SizedBox(width: 10),
            _buildSeverityOption("Major", Colors.redAccent, 2),
            const SizedBox(width: 10),
            _buildSeverityOption("Total", Colors.purpleAccent, 3),
          ],
        ),
      ],
    );
  }

  Widget _buildSeverityOption(String label, Color color, int index) {
    final isSelected = _selectedSeverity == label;
    return Expanded(
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: () => setState(() => _selectedSeverity = label),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: BoxDecoration(
              color: isSelected ? color.withOpacity(0.3) : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? color : Colors.white.withOpacity(0.2),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    color: isSelected ? color : Colors.white70,
                    fontSize: 10,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEvidenceUpload() {
    return SlideTransition(
      position: _slideAnimation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Evidence & Photos",
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 15),
          Text(
            "Upload photos of the damage (Max 5 images)",
            style: GoogleFonts.poppins(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 10),
          _buildImageGrid(),
          const SizedBox(height: 15),
          Row(
            children: [
              _buildUploadButton("Camera", Icons.camera_alt_rounded, Colors.blueAccent, _takePhoto),
              const SizedBox(width: 10),
              _buildUploadButton("Gallery", Icons.photo_library_rounded, Colors.purpleAccent, _pickImages),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImageGrid() {
    return Container(
      height: 120,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          ..._selectedImages.map((image) => _buildImagePreview(image)),
          if (_selectedImages.length < 5) _buildAddImageButton(),
        ],
      ),
    );
  }

  Widget _buildImagePreview(XFile image) {
    return Container(
      width: 100,
      height: 100,
      margin: const EdgeInsets.only(right: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Stack(
        children: [
          FutureBuilder<File>(
            future: _getImageFile(image),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(snapshot.data!, fit: BoxFit.cover, width: 100, height: 100),
                );
              }
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(child: CircularProgressIndicator(color: Colors.blueAccent)),
              );
            },
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => _removeImage(image),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.close, color: Colors.white, size: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddImageButton() {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: _pickImages,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_photo_alternate_rounded, color: Colors.white70, size: 30),
              const SizedBox(height: 5),
              Text(
                "Add Photo",
                style: GoogleFonts.poppins(
                  color: Colors.white70,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUploadButton(String text, IconData icon, Color color, VoidCallback onTap) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withOpacity(0.3), color.withOpacity(0.1)],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  text,
                  style: GoogleFonts.poppins(
                    color: color,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAdditionalInfo() {
    return SlideTransition(
      position: _slideAnimation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Additional Information",
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 15),
          _buildCheckboxOption(
            "Was there another party involved?",
            _otherPartyInvolved,
            (value) => setState(() => _otherPartyInvolved = value ?? false),
            Icons.people_alt_rounded,
            Colors.blueAccent,
          ),
          const SizedBox(height: 10),
          _buildCheckboxOption(
            "Was a police report filed?",
            _policeReportFiled,
            (value) => setState(() => _policeReportFiled = value ?? false),
            Icons.local_police_rounded,
            Colors.orangeAccent,
          ),
        ],
      ),
    );
  }

  Widget _buildCheckboxOption(String text, bool value, ValueChanged<bool?> onChanged, IconData icon, Color color) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => onChanged(!value),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: value
                  ? [color.withOpacity(0.2), color.withOpacity(0.05)]
                  : [Colors.white.withOpacity(0.1), Colors.white.withOpacity(0.05)],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: value ? color.withOpacity(0.3) : Colors.white.withOpacity(0.1)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: value ? color.withOpacity(0.2) : Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: value ? color : Colors.white70, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  text,
                  style: GoogleFonts.poppins(
                    color: value ? Colors.white : Colors.white70,
                    fontSize: 14,
                    fontWeight: value ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: value ? color : Colors.transparent,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: value ? color : Colors.white54,
                    width: 2,
                  ),
                ),
                child: value
                    ? Icon(Icons.check, color: Colors.white, size: 14)
                    : null,
              ),
            ],
          ),
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
          const SizedBox(height: 15),
          _buildCheckboxOption(
            "I confirm that all information provided is true and accurate to the best of my knowledge",
            _termsAgreed,
            (value) => setState(() => _termsAgreed = value ?? false),
            Icons.verified_user_rounded,
            Colors.greenAccent,
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    final isEnabled = _termsAgreed && _selectedPolicy.isNotEmpty && !_isSubmitting;
    
    return Center(
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: isEnabled ? _submitClaim : null,
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
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.send_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  _isSubmitting ? "SUBMITTING CLAIM..." : "SUBMIT CLAIM",
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

  // Image handling methods
  Future<void> _pickImages() async {
    if (_selectedImages.length >= 5) {
      _showErrorDialog("Maximum 5 images allowed");
      return;
    }

    try {
      final List<XFile> images = await _imagePicker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (images.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(images.take(5 - _selectedImages.length));
        });
      }
    } catch (e) {
      _showErrorDialog("Failed to pick images: $e");
    }
  }

  Future<void> _takePhoto() async {
    if (_selectedImages.length >= 5) {
      _showErrorDialog("Maximum 5 images allowed");
      return;
    }

    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImages.add(image);
        });
      }
    } catch (e) {
      _showErrorDialog("Failed to take photo: $e");
    }
  }

  Future<File> _getImageFile(XFile xfile) async {
    return File(xfile.path);
  }

  void _removeImage(XFile image) {
    setState(() {
      _selectedImages.remove(image);
    });
  }

  // Claim submission
  Future<void> _submitClaim() async {
    if (!_termsAgreed || _selectedPolicy.isEmpty) return;

    setState(() => _isSubmitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not authenticated");

      final selectedPolicy = _userPolicies.firstWhere((policy) => policy['id'] == _selectedPolicy);
      
      final claimId = _claimsRef.push().key!;
      final now = DateTime.now();

      final claimData = {
        'claimId': claimId,
        'userId': user.uid,
        'policyId': _selectedPolicy,
        'policyNumber': selectedPolicy['policyNumber'],
        'claimType': _selectedClaimType,
        'incidentDate': _incidentDateController.text,
        'incidentTime': _incidentTimeController.text,
        'location': _locationController.text.trim(),
        'description': _descriptionController.text.trim(),
        'damageDescription': _damageDescriptionController.text.trim(),
        'severity': _selectedSeverity,
        'estimatedCost': double.tryParse(_estimatedCostController.text) ?? 0.0,
        'otherPartyInvolved': _otherPartyInvolved,
        'policeReportFiled': _policeReportFiled,
        'status': 'Pending',
        'submittedAt': ServerValue.timestamp,
        'imagesCount': _selectedImages.length,
        'vehicleModel': selectedPolicy['vehicleModel'],
        'vehicleYear': selectedPolicy['vehicleYear'],
      };

      await _claimsRef.child(claimId).set(claimData);

      // Show success dialog
      _showSuccessDialog();

    } catch (e) {
      print('Error submitting claim: $e');
      _showErrorDialog('Failed to submit claim. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color.fromARGB(255, 16, 52, 90),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.greenAccent.withOpacity(0.3)),
        ),
        title: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 30),
            const SizedBox(width: 10),
            Text(
              "Claim Submitted",
              style: GoogleFonts.poppins(
                color: Colors.greenAccent,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Your claim has been submitted successfully!",
              style: GoogleFonts.poppins(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Our team will review your claim and contact you within 24 hours.",
              style: GoogleFonts.poppins(
                color: Colors.white60,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // Go back to home screen
            },
            style: TextButton.styleFrom(
              backgroundColor: Colors.greenAccent.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Return Home',
              style: GoogleFonts.poppins(
                color: Colors.greenAccent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color.fromARGB(255, 16, 52, 90),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withOpacity(0.2)),
        ),
        title: Text(
          'Submission Error',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          message,
          style: GoogleFonts.poppins(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              backgroundColor: Colors.blueAccent.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'OK',
              style: GoogleFonts.poppins(
                color: Colors.blueAccent,
                fontWeight: FontWeight.w600,
              ),
            ),
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
    TextInputType keyboardType = TextInputType.text,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
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
        keyboardType: keyboardType,
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