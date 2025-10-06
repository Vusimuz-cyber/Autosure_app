import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
  String _makeModel = '';
  String _year = '';
  String _regNumber = '';
  String _mileage = '';
  String _value = '';
  String _location = '';
  String _color = '';
  String _age = '';
  String _claimsHistory = '0';
  String _parking = 'Street';
  bool _peakHours = false;
  bool _hasTracker = false;
  bool _hasAlarm = false;
  bool _hasImmobilizer = false;
  bool _married = false;
  String _coverageType = 'Comprehensive';
  String _usage = 'Daily Commute';

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
    
    // Trigger animations after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _masterController.forward();
        _progressController.forward();
      }
    });
  }

  void _nextStep() {
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

  void _showQuoteResults() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildQuoteResults(),
    );
  }

  Widget _buildQuoteResults() {
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "🎉 Your Quote is Ready!",
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 15),
            
            _buildPlanCard("Comprehensive Plan", Colors.blueAccent, "Full Protection"),
            const SizedBox(height: 10),
            _buildPlanCard("Smart Plan", Colors.greenAccent, "Best Value"),
            const SizedBox(height: 10),
            _buildPlanCard("Third-Party Plan", Colors.orangeAccent, "Essential Coverage"),
            
            const SizedBox(height: 20),
            Text(
              "💡 Based on your information, we recommend the Smart Plan for optimal coverage",
              style: GoogleFonts.poppins(
                color: Colors.white70,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 25),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    "Apply Now", 
                    Colors.greenAccent, 
                    () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ApplyInsuranceScreen()))
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildActionButton(
                    "Save Details", 
                    Colors.blueAccent,
                    () => Navigator.pop(context)
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard(String title, Color color, String badge) {
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
                Text("Complete coverage tailored to your needs", 
                    style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12)),
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
    _masterController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 8, 18, 32),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 120), // Space for floating header
            _buildFloatingHeader(),
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
            const SizedBox(height: 20), // Extra space for scrolling
          ],
        ),
      ),
    );
  }


  Widget _buildFloatingHeader() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 0), // Removed margins to test
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
          Text(
            "Complete the form below to get your personalized insurance options",
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildProgressHeader() {
    return Column(
      children: [
        // Step Titles
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
        
        // Progress Bar
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
                  // Background
                  Container(
                    width: double.infinity,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  
                  // Progress
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
                  
                  // Step Indicators
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
        _buildTextField("Make and Model", _makeModel, (value) => setState(() => _makeModel = value)),
        const SizedBox(height: 15),
        _buildTextField("Year of Manufacture", _year, (value) => setState(() => _year = value), TextInputType.number),
        const SizedBox(height: 15),
        _buildTextField("Registration Number", _regNumber, (value) => setState(() => _regNumber = value)),
        const SizedBox(height: 15),
        _buildTextField("Current Mileage (km)", _mileage, (value) => setState(() => _mileage = value), TextInputType.number),
        const SizedBox(height: 15),
        _buildTextField("Vehicle Value", _value, (value) => setState(() => _value = value), TextInputType.number),
      ],
    );
  }

  Widget _buildDriverDetails() {
    return Column(
      children: [
        _buildTextField("Driver Age", _age, (value) => setState(() => _age = value), TextInputType.number),
        const SizedBox(height: 15),
        _buildTextField("Claims in Last 3 Years", _claimsHistory, (value) => setState(() => _claimsHistory = value), TextInputType.number),
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
          ['Comprehensive', 'Third-Party', 'Smart Plan'], 
          (value) => setState(() => _coverageType = value ?? 'Comprehensive')
        ),
        const SizedBox(height: 15),
        _buildDropdownField(
          "Vehicle Color", 
          _color, 
          ['Silver', 'White', 'Black', 'Blue', 'Red', 'Other'], 
          (value) => setState(() => _color = value ?? '')
        ),
        const SizedBox(height: 15),
        _buildDropdownField(
          "Parking Location", 
          _parking, 
          ['Street', 'Garage', 'Secured Lot'], 
          (value) => setState(() => _parking = value ?? 'Street')
        ),
        const SizedBox(height: 15),
        _buildCheckboxOption("Drive during peak hours (18:00-21:00)", _peakHours, (value) => setState(() => _peakHours = value ?? false)),
        const SizedBox(height: 10),
        _buildCheckboxOption("GPS Tracker installed", _hasTracker, (value) => setState(() => _hasTracker = value ?? false)),
        const SizedBox(height: 10),
        _buildCheckboxOption("Alarm system installed", _hasAlarm, (value) => setState(() => _hasAlarm = value ?? false)),
        const SizedBox(height: 10),
        _buildCheckboxOption("Immobilizer installed", _hasImmobilizer, (value) => setState(() => _hasImmobilizer = value ?? false)),
      ],
    );
  }

  Widget _buildLocationDetails() {
    return Column(
      children: [
        _buildDropdownField(
          "Location Area", 
          _location, 
          ['Honeydew', 'Umlazi', 'Nyanga', 'Johannesburg CBD', 'Pretoria', 'Durban', 'Cape Town', 'Other'], 
          (value) => setState(() => _location = value ?? '')
        ),
        const SizedBox(height: 15),
        _buildDropdownField(
          "Vehicle Usage", 
          _usage, 
          ['Daily Commute', 'Business Use', 'Occasional', 'Weekends Only'], 
          (value) => setState(() => _usage = value ?? 'Daily Commute')
        ),
      ],
    );
  }

  Widget _buildTextField(String label, String value, ValueChanged<String> onChanged, [TextInputType? keyboardType]) {
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
          child: TextField(
            controller: TextEditingController(text: value),
            onChanged: onChanged,
            keyboardType: keyboardType,
            style: GoogleFonts.poppins(color: Colors.white),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 15),
              border: InputBorder.none,
              hintText: "Enter $label",
              hintStyle: GoogleFonts.poppins(color: Colors.white54),
            ),
          ),
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