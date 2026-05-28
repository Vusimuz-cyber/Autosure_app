import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'apply_insurance_screen.dart';

class GetQuoteScreen extends StatefulWidget {
  const GetQuoteScreen({super.key});

  @override
  State<GetQuoteScreen> createState() => _GetQuoteScreenState();
}

class _GetQuoteScreenState extends State<GetQuoteScreen> with TickerProviderStateMixin {
  late AnimationController _masterController;
  late AnimationController _progressController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _progressAnimation;

  int _currentStep = 0;

  // Text editing controllers
  final TextEditingController _brandController = TextEditingController();
  final TextEditingController _modelController = TextEditingController();
  final TextEditingController _provinceController = TextEditingController();
  final TextEditingController _placeController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();
  final TextEditingController _mileageController = TextEditingController();
  final TextEditingController _valueController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _claimsHistoryController = TextEditingController();
  final TextEditingController _regNumberController = TextEditingController();
  final TextEditingController _colorController = TextEditingController();

  // Form values
  String _parking = 'Garage';
  bool _hasTracker = false;
  bool _hasAlarm = false;
  bool _hasImmobilizer = false;
  bool _married = false;
  bool _peakHours = false;
  String _coverageType = 'Comprehensive';
  String _usage = 'Daily Commute';
  String? _error;

  final List<String> _stepTitles = [
    "Vehicle Details",
    "Driver Profile",
    "Coverage Options",
    "Location & Usage"
  ];

  final List<Color> _stepColors = [
    Colors.blueAccent,
    Colors.greenAccent,
    Colors.purpleAccent,
    Colors.orangeAccent
  ];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _masterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _masterController, curve: Curves.easeInOutQuart),
    );

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _masterController, curve: Curves.elasticOut),
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _masterController.forward();
        _progressController.forward();
      }
    });
  }

  // Prepare quote data
  Map<String, dynamic> _prepareQuoteData(Map<String, dynamic> monthlyPremiums) {
    return {
      'brand': _brandController.text,
      'model': _modelController.text,
      'value': _valueController.text,
      'year': _yearController.text,
      'color': _colorController.text,
      'regNumber': _regNumberController.text,
      'province': _provinceController.text,
      'place': _placeController.text,
      'coverageType': _coverageType,
      'premiums': monthlyPremiums,
      'mileage': _mileageController.text,
      'driverAge': _ageController.text,
      'claimsHistory': _claimsHistoryController.text,
      'parking': _parking,
      'security': {
        'tracker': _hasTracker,
        'alarm': _hasAlarm,
        'immobilizer': _hasImmobilizer,
      },
      'usage': _usage,
      'quoteDate': DateTime.now().toIso8601String(),
    };
  }

  // Navigate to ApplyInsuranceScreen with quote data
  void _navigateToApplyScreen(Map<String, dynamic> monthlyPremiums) {
    final quoteData = _prepareQuoteData(monthlyPremiums);
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ApplyInsuranceScreen(quoteData: quoteData),
      ),
    );
  }

  // Save quote locally and show confirmation
  void _saveQuoteLocally(Map<String, dynamic> monthlyPremiums) {
    final quoteData = _prepareQuoteData(monthlyPremiums);
    
    // In a real app, you might save to local storage or database
    // For now, we'll just show a confirmation and keep in memory
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              'Quote saved! You can apply later from your profile',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );

    // Close the quote results modal
    Navigator.pop(context);
  }

  // Show directory of examples
  void _showDirectory() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color.fromARGB(255, 16, 52, 90),
        title: Text(
          "How Premiums Are Calculated",
          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.yellowAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.yellowAccent.withOpacity(0.3)),
                ),
                child: Text(
                  "Formula: Premium = Vehicle Value × All Risk Factors",
                  style: GoogleFonts.poppins(
                    color: Colors.yellowAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 15),
              Text(
                "Brands & Models (from system):",
                style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600),
              ),
              Text(
                "Toyota Hilux, Volkswagen Polo, Ford Ranger, Suzuki Swift, etc.",
                style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 10),
              Text(
                "Provinces & Places (risk-rated):",
                style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600),
              ),
              Text(
                "Provinces: Gauteng, Western Cape, KwaZulu-Natal, etc.\nPlaces: Sandton, Soweto, Khayelitsha, Durban North, etc.",
                style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 10),
              Text(
                "Example Calculations:",
                style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600),
              ),
              Text(
                "• R500k Hilux + High Risk Area = R3,500-R5,000/month\n• R500k Hilux + Low Risk Area = R1,800-R2,500/month\n• R200k Polo + Medium Risk = R900-R1,500/month",
                style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Got It", style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // API call to get quote
  Future<Map<String, dynamic>?> _calculateQuote() async {
    try {
      final vehicleValue = double.tryParse(_valueController.text) ?? 0.0;
      
      // Validate critical inputs
      if (vehicleValue <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please enter a valid vehicle value'))
        );
        return null;
      }
      
      if (_brandController.text.isEmpty || _modelController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please enter vehicle brand and model'))
        );
        return null;
      }

      if (_provinceController.text.isEmpty || _placeController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please enter province and place'))
        );
        return null;
      }

      final response = await http.post(
        Uri.parse('http://localhost:8000/get_quote'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          // BASE CALCULATION INPUT
          'vehicle_value': vehicleValue,
          
          // STATIC RISK MULTIPLIERS (from your CSV data)
          'brand': _brandController.text.trim(),
          'model': _modelController.text.trim(),
          'province': _provinceController.text.trim(),
          'place': _placeController.text.trim(),
          
          // DYNAMIC RISK FACTORS
          'driver_age': int.tryParse(_ageController.text) ?? 30,
          'claims_history': int.tryParse(_claimsHistoryController.text) ?? 0,
          'vehicle_year': int.tryParse(_yearController.text) ?? 2020,
          'annual_mileage': int.tryParse(_mileageController.text) ?? 0,
          'vehicle_usage': _usage.toLowerCase().replaceAll(' ', '_'),
          'parking_type': _parking.toLowerCase().replaceAll(' ', '_'),
          'has_tracker': _hasTracker ? 1 : 0,
          'has_alarm': _hasAlarm ? 1 : 0,
          'has_immobilizer': _hasImmobilizer ? 1 : 0,
          'married': _married ? 1 : 0,
          'peak_hours_usage': _peakHours ? 1 : 0,
          'color': _colorController.text.trim().toLowerCase(),
          'reg_number': _regNumberController.text.trim().toUpperCase(),
          
          // Calculate all three coverage types
          'coverage_type': 'all',
        }),
      ).timeout(const Duration(seconds: 15));
      
      print('API Response: ${response.statusCode} ${response.body}');
      
      if (response.statusCode == 200) {
        setState(() => _error = null);
        return jsonDecode(response.body);
      } else {
        setState(() => _error = 'API Error: ${response.statusCode} ${response.body}');
        return null;
      }
    } catch (e) {
      setState(() => _error = 'Connection error: $e');
      print('API Error: $e');
      return null;
    }
  }

  String? _validateInputs() {
    if (_currentStep == 0) {
      if (_brandController.text.isEmpty) return 'Please enter vehicle brand';
      if (_modelController.text.isEmpty) return 'Please enter vehicle model';
      if (_valueController.text.isEmpty) return 'Please enter vehicle value';
      
      final value = double.tryParse(_valueController.text);
      if (value == null || value < 10000) {
        return 'Please enter a valid vehicle value (minimum R10,000)';
      }
      
      final year = int.tryParse(_yearController.text);
      if (year == null || year < 1990 || year > DateTime.now().year + 1) {
        return 'Please enter a valid vehicle year';
      }
    }
    
    if (_currentStep == 1) {
      if (_ageController.text.isEmpty) return 'Please enter driver age';
      final age = int.tryParse(_ageController.text);
      if (age == null || age < 18 || age > 100) {
        return 'Please enter a valid age (18-100)';
      }
    }
    
    if (_currentStep == 3) {
      if (_provinceController.text.isEmpty) return 'Please enter province';
      if (_placeController.text.isEmpty) return 'Please enter place';
    }
    
    return null;
  }

  void _nextStep() {
    final validationError = _validateInputs();
    if (validationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(validationError),
          backgroundColor: Colors.redAccent,
        )
      );
      return;
    }
    
    if (_currentStep < 3) {
      _progressController.reset();
      setState(() => _currentStep++);
      _progressController.forward();
    } else {
      _showQuoteResults();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _progressController.reset();
      setState(() => _currentStep--);
      _progressController.forward();
    }
  }

  void _showQuoteResults() async {
    final monthlyPremiums = await _calculateQuote();
    if (monthlyPremiums == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildQuoteResults(monthlyPremiums),
    );
  }

  Widget _buildQuoteResults(Map<String, dynamic> monthlyPremiums) {
    return Container(
      margin: const EdgeInsets.all(20),
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
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with close button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "🎉 Your Quote is Ready!",
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withOpacity(0.2)),
                        ),
                        child: Icon(Icons.close, color: Colors.white70, size: 18),
                      ),
                    ),
                  ),
                ],
              ),
              
              // Debug Info Section
              const SizedBox(height: 15),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Calculation Details:",
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Vehicle: ${_brandController.text} ${_modelController.text}",
                      style: GoogleFonts.poppins(color: Colors.white70, fontSize: 11),
                    ),
                    Text(
                      "Value: R${_valueController.text} | Location: ${_provinceController.text}, ${_placeController.text}",
                      style: GoogleFonts.poppins(color: Colors.white70, fontSize: 11),
                    ),
                    Text(
                      "Driver: ${_ageController.text}yrs | Claims: ${_claimsHistoryController.text}",
                      style: GoogleFonts.poppins(color: Colors.white70, fontSize: 11),
                    ),
                    Text(
                      "Security: ${_parking} ${_hasTracker ? '+Tracker' : ''} ${_hasAlarm ? '+Alarm' : ''}",
                      style: GoogleFonts.poppins(color: Colors.white70, fontSize: 11),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 15),
              Text(
                "Monthly Premium Options",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 20),
              _buildPlanCard(
                "Comprehensive Plan",
                Colors.blueAccent,
                "Full Protection",
                "R ${monthlyPremiums['comprehensive']?.toStringAsFixed(0) ?? '0'}/month",
                "Covers accidents, theft, fire, third-party, and natural disasters",
              ),
              const SizedBox(height: 12),
              _buildPlanCard(
                "Smart Plan",
                Colors.greenAccent,
                "Best Value",
                "R ${monthlyPremiums['smart']?.toStringAsFixed(0) ?? '0'}/month",
                "Balanced coverage with essential protection",
              ),
              const SizedBox(height: 12),
              _buildPlanCard(
                "Third-Party Plan",
                Colors.orangeAccent,
                "Essential",
                "R ${monthlyPremiums['third_party']?.toStringAsFixed(0) ?? '0'}/month",
                "Covers damage to other vehicles and property only",
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.greenAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.greenAccent.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lightbulb, color: Colors.greenAccent, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "Based on your profile, we recommend the Smart Plan for optimal coverage and value",
                        style: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),
              Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      "Apply Now",
                      Colors.greenAccent,
                      () => _navigateToApplyScreen(monthlyPremiums),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildActionButton(
                      "Save Quote",
                      Colors.blueAccent,
                      () => _saveQuoteLocally(monthlyPremiums),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlanCard(String title, Color color, String badge, String price, String description) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.verified, color: color, size: 20),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(description, style: GoogleFonts.poppins(color: Colors.white70, fontSize: 10)),
                const SizedBox(height: 8),
                Text(price, style: GoogleFonts.poppins(color: color, fontSize: 16, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(badge, style: GoogleFonts.poppins(color: color, fontSize: 10)),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String text, Color color, VoidCallback onPressed) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [color, color.withOpacity(0.8)]),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Center(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _brandController.dispose();
    _modelController.dispose();
    _provinceController.dispose();
    _placeController.dispose();
    _yearController.dispose();
    _mileageController.dispose();
    _valueController.dispose();
    _ageController.dispose();
    _claimsHistoryController.dispose();
    _regNumberController.dispose();
    _colorController.dispose();
    _masterController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 8, 18, 32),
      body: Stack(
        children: [
          // Background
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topLeft,
                radius: 1.5,
                colors: [
                  Color.fromARGB(255, 16, 52, 90),
                  Color.fromARGB(255, 8, 25, 45),
                  Color.fromARGB(255, 4, 15, 26),
                ],
              ),
            ),
          ),
          
          // Main Content
          SingleChildScrollView(
            padding: const EdgeInsets.all(25.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 60),
                
                // Header with Exit Button
                Row(
                  children: [
                    Expanded(
                      child: _buildFloatingHeader(),
                    ),
                    const SizedBox(width: 10),
                    // Exit Button
                    Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        onTap: () => Navigator.pop(context),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withOpacity(0.2)),
                          ),
                          child: Icon(Icons.close, color: Colors.white70, size: 20),
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 30),
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: _buildProgressHeader(),
                  ),
                ),
                const SizedBox(height: 30),
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: _buildCurrentStepContent(),
                  ),
                ),
                const SizedBox(height: 40),
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: _buildNavigationButtons(),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
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
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Get Your Quote",
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              Expanded(
                child: Text(
                  "Complete the form below to get your personalized insurance options",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.info_outline, color: Colors.white70),
                onPressed: _showDirectory,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressHeader() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(4, (index) {
            final isActive = index == _currentStep;
            final isCompleted = index < _currentStep;

            return Expanded(
              child: Column(
                children: [
                  Text(
                    _stepTitles[index],
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: isActive || isCompleted ? _stepColors[index] : Colors.white54,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            );
          }),
        ),
        Container(
          height: 6,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(3),
          ),
          child: AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, child) {
              return Stack(
                children: [
                  Container(
                    width: double.infinity,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  Container(
                    width: (MediaQuery.of(context).size.width - 50) * ((_currentStep + _progressAnimation.value) / 4),
                    height: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _stepColors[_currentStep],
                          _stepColors[_currentStep].withOpacity(0.7),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 0,
                    bottom: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(5, (index) {
                        final isCompleted = index <= _currentStep;
                        return Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: isCompleted ? _stepColors[index.clamp(0, 3)] : Colors.white.withOpacity(0.3),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withOpacity(0.5),
                              width: 2,
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentStepContent() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _stepColors[_currentStep].withOpacity(0.2)),
      ),
      child: _getStepContent(_currentStep),
    );
  }

  Widget _getStepContent(int step) {
    switch (step) {
      case 0:
        return _buildVehicleDetails();
      case 1:
        return _buildDriverDetails();
      case 2:
        return _buildCoverageDetails();
      case 3:
        return _buildLocationDetails();
      default:
        return const SizedBox();
    }
  }

Widget _buildVehicleDetails() {
  return Column(
    children: [
      _buildTextField("Brand", _brandController, TextInputType.text, hint: "e.g. Volkswagen, BMW"),
      const SizedBox(height: 15),
      _buildTextField("Model", _modelController, TextInputType.text, hint: "e.g. Golf GTI, M3"),
      const SizedBox(height: 15),
      _buildTextField("Registration Number", _regNumberController, TextInputType.text, hint: "e.g. GP123456"),
      const SizedBox(height: 15),
      _buildTextField("Color", _colorController, TextInputType.text, hint: "e.g. White, Black"),
      const SizedBox(height: 15),
      _buildTextField("Year of Manufacture", _yearController, TextInputType.number, hint: "e.g. 2020"),
      const SizedBox(height: 15),
      _buildTextField("Current Mileage (km)", _mileageController, TextInputType.number, hint: "e.g. 15000"),
      const SizedBox(height: 15),
      _buildTextField("Vehicle Value", _valueController, TextInputType.number, hint: "e.g. 500000"),
    ],
  );
}

Widget _buildTextField(String label, TextEditingController controller, TextInputType keyboardType, {String hint = ""}) {
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
        child: TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint.isNotEmpty ? hint : "Enter $label",
            hintStyle: GoogleFonts.poppins(color: Colors.white54, fontSize: 14),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ),
    ],
  );
}

Widget _buildTextFieldWithRecommendations(
  String label, 
  TextEditingController controller, 
  TextInputType keyboardType, {
  required List<String> recommendations,
  String hint = "",
}) {
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
        child: Column(
          children: [
            TextField(
              controller: controller,
              keyboardType: keyboardType,
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: hint.isNotEmpty ? hint : "Enter $label",
                hintStyle: GoogleFonts.poppins(color: Colors.white54, fontSize: 14),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            if (recommendations.isNotEmpty)
              _buildRecommendationChips(controller, recommendations),
          ],
        ),
      ),
    ],
  );
}

Widget _buildRecommendationChips(TextEditingController controller, List<String> recommendations) {
  return Container(
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: Colors.black.withOpacity(0.3),
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(12),
        bottomRight: Radius.circular(12),
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Suggestions:",
          style: GoogleFonts.poppins(
            color: Colors.white54,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: recommendations.take(5).map((recommendation) {
            return Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(15),
              child: InkWell(
                onTap: () {
                  controller.text = recommendation;
                },
                borderRadius: BorderRadius.circular(15),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
                  ),
                  child: Text(
                    recommendation,
                    style: GoogleFonts.poppins(
                      color: Colors.blueAccent,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    ),
  );
}

  Widget _buildDriverDetails() {
    return Column(
      children: [
        _buildTextField("Driver Age", _ageController, TextInputType.number),
        const SizedBox(height: 15),
        _buildTextField("Claims in Last 3 Years", _claimsHistoryController, TextInputType.number),
        const SizedBox(height: 15),
        _buildCheckboxOption("Married", _married, (value) => setState(() => _married = value ?? false)),
      ],
    );
  }

  Widget _buildCoverageDetails() {
    return Column(
      children: [
        _buildDropdownField(
          "Coverage Type",
          _coverageType,
          ['Comprehensive', 'Smart', 'Third-Party'],
          (value) => setState(() => _coverageType = value ?? 'Comprehensive'),
        ),
        const SizedBox(height: 15),
        _buildDropdownField(
          "Parking Location",
          _parking,
          ['Garage', 'Street', 'Carport'],
          (value) => setState(() => _parking = value ?? 'Garage'),
        ),
        const SizedBox(height: 15),
        _buildCheckboxOption("GPS Tracker installed", _hasTracker, (value) => setState(() => _hasTracker = value ?? false)),
        const SizedBox(height: 10),
        _buildCheckboxOption("Alarm system installed", _hasAlarm, (value) => setState(() => _hasAlarm = value ?? false)),
        const SizedBox(height: 10),
        _buildCheckboxOption("Immobilizer installed", _hasImmobilizer, (value) => setState(() => _hasImmobilizer = value ?? false)),
        const SizedBox(height: 10),
        _buildCheckboxOption("Drive during peak hours (18:00-21:00)", _peakHours, (value) => setState(() => _peakHours = value ?? false)),
      ],
    );
  }

  Widget _buildLocationDetails() {
    return Column(
      children: [
        _buildTextField("Province ", _provinceController, TextInputType.text),
        const SizedBox(height: 15),
        _buildTextField("Place/Suburb", _placeController, TextInputType.text),
        const SizedBox(height: 15),
        _buildDropdownField(
          "Vehicle Usage",
          _usage,
          ['Daily Commute', 'Business','Occasional'],
          (value) => setState(() => _usage = value ?? 'Daily Commute'),
        ),
      ],
    );
  }

  Widget _buildDropdownField(String label, String value, List<String> items, ValueChanged<String?> onChanged) {
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
          height: 50,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: DropdownButtonFormField<String>(
            value: value.isEmpty ? null : value,
            items: items.map((String item) {
              return DropdownMenuItem<String>(
                value: item,
                child: Text(item, style: GoogleFonts.poppins(color: Colors.white)),
              );
            }).toList(),
            onChanged: onChanged,
            dropdownColor: const Color.fromARGB(255, 16, 52, 90),
            style: GoogleFonts.poppins(color: Colors.white),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 15),
              border: InputBorder.none,
              hintText: "Select $label",
              hintStyle: GoogleFonts.poppins(color: Colors.white54),
            ),
            icon: Icon(Icons.arrow_drop_down, color: Colors.white70),
          ),
        ),
      ],
    );
  }

  Widget _buildCheckboxOption(String label, bool value, ValueChanged<bool?> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Checkbox(
            value: value,
            onChanged: onChanged,
            fillColor: MaterialStateProperty.resolveWith<Color>((Set<MaterialState> states) {
              return _stepColors[_currentStep];
            }),
          ),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Row(
      children: [
        if (_currentStep > 0) ...[
          Expanded(
            child: _buildNavigationButton("Back", Colors.grey, _previousStep),
          ),
          const SizedBox(width: 15),
        ],
        Expanded(
          child: _buildNavigationButton(
            _currentStep == 3 ? "Get Quote" : "Continue",
            _stepColors[_currentStep],
            _nextStep,
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationButton(String text, Color color, VoidCallback onPressed) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [color, color.withOpacity(0.8)]),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Center(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}