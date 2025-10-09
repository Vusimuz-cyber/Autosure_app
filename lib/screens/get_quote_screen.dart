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
  
  // Text editing controllers
  final TextEditingController _makeModelController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();
  final TextEditingController _regNumberController = TextEditingController();
  final TextEditingController _mileageController = TextEditingController();
  final TextEditingController _valueController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _claimsHistoryController = TextEditingController();

  // South African specific data
  final List<String> _saCarMakes = [
    'Toyota', 'Volkswagen', 'Ford', 'Hyundai', 'Nissan',
    'BMW', 'Mercedes-Benz', 'Kia', 'Isuzu', 'Mahindra'
  ];

  final Map<String, List<String>> _saCarModels = {
    'Toyota': ['Hilux', 'Corolla', 'Fortuner', 'RAV4', 'Yaris'],
    'Volkswagen': ['Polo', 'Golf', 'T-Cross', 'Tiguan', 'Amarok'],
    'Ford': ['Ranger', 'EcoSport', 'Figo', 'Focus', 'Everest'],
    'Hyundai': ['i20', 'Creta', 'Tucson', 'Grand i10', 'Venue'],
    'Nissan': ['NP200', 'Navara', 'Qashqai', 'X-Trail', 'Micra'],
    'BMW': ['3 Series', 'X3', 'X5', '1 Series', 'X1'],
    'Mercedes-Benz': ['C-Class', 'A-Class', 'GLC', 'E-Class', 'GLE'],
    'Kia': ['Seltos', 'Picanto', 'Sorento', 'Sportage', 'Rio'],
    'Isuzu': ['D-Max', 'MU-X'],
    'Mahindra': ['Scorpio', 'XUV300', 'Bolero', 'Thar']
  };

  // Removed risk indicators from user-facing dropdown
  final List<String> _saAreas = [
    'Honeydew', 'Sandton', 'Johannesburg CBD', 'Pretoria East', 'Soshanguve', 
    'Durban North', 'Umlazi', 'Cape Town City Bowl', 'Nyanga', 'Stellenbosch', 
    'Port Elizabeth', 'Bloemfontein'
  ];

  final List<String> _saColors = ['White', 'Silver', 'Black', 'Blue', 'Red', 'Grey', 'Other'];

  // Risk mapping for internal calculation only
  final Map<String, double> _areaRiskMultipliers = {
    'Honeydew': 1.0,           // Low risk
    'Sandton': 1.2,            // Medium risk
    'Johannesburg CBD': 1.5,   // High risk
    'Pretoria East': 1.0,      // Low risk
    'Soshanguve': 1.5,         // High risk
    'Durban North': 1.0,       // Low risk
    'Umlazi': 1.5,             // High risk
    'Cape Town City Bowl': 1.2,// Medium risk
    'Nyanga': 1.5,             // High risk
    'Stellenbosch': 1.0,       // Low risk
    'Port Elizabeth': 1.2,     // Medium risk
    'Bloemfontein': 1.0,       // Low risk
  };

  // Form values
  String _selectedMake = '';
  String _selectedModel = '';
  String _location = '';
  String _color = '';
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
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _masterController.forward();
        _progressController.forward();
      }
    });
  }

  // Realistic South African Quote Calculation Logic
  Map<String, double> _calculateQuote() {
    // Base premium calculation based on realistic SA market rates
    final vehicleValue = double.tryParse(_valueController.text) ?? 0;
    final vehicleYear = int.tryParse(_yearController.text) ?? DateTime.now().year;
    final vehicleAge = DateTime.now().year - vehicleYear;
    
    // Base monthly premium calculation (more realistic for SA)
    double baseMonthlyPremium = 0;
    
    if (vehicleValue <= 50000) {
      baseMonthlyPremium = 350; // Small, low-value cars
    } else if (vehicleValue <= 150000) {
      baseMonthlyPremium = 650; // Average family cars
    } else if (vehicleValue <= 300000) {
      baseMonthlyPremium = 950; // Mid-range vehicles
    } else if (vehicleValue <= 500000) {
      baseMonthlyPremium = 1500; // Luxury vehicles
    } else {
      baseMonthlyPremium = 2500; // High-end luxury vehicles
    }
    
    // Adjustments based on factors
    double riskMultiplier = 1.0;
    
    // Driver age factor
    final driverAge = int.tryParse(_ageController.text) ?? 30;
    if (driverAge < 25) riskMultiplier *= 1.6; // Young drivers pay more
    else if (driverAge > 60) riskMultiplier *= 1.3; // Senior drivers
    else if (driverAge >= 25 && driverAge <= 30) riskMultiplier *= 1.2;
    else if (driverAge > 30 && driverAge <= 40) riskMultiplier *= 1.0; // Prime age
    else if (driverAge > 40 && driverAge <= 50) riskMultiplier *= 0.95; // Experienced
    else riskMultiplier *= 1.1;
    
    // Claims history
    final claimsCount = int.tryParse(_claimsHistoryController.text) ?? 0;
    riskMultiplier += (claimsCount * 0.25); // Each claim increases premium
    
    // Location risk (using internal mapping, not visible to user)
    final areaMultiplier = _areaRiskMultipliers[_location] ?? 1.2;
    riskMultiplier *= areaMultiplier;
    
    // Vehicle usage
    if (_usage == 'Daily Commute') riskMultiplier *= 1.15;
    else if (_usage == 'Business Use') riskMultiplier *= 1.4;
    else if (_usage == 'Occasional') riskMultiplier *= 0.9;
    else if (_usage == 'Weekends Only') riskMultiplier *= 0.85;
    
    // Vehicle age adjustment
    if (vehicleAge > 10) riskMultiplier *= 1.3; // Older cars cost more to insure
    else if (vehicleAge > 5) riskMultiplier *= 1.1;
    else if (vehicleAge <= 3) riskMultiplier *= 0.9; // Newer cars get discount
    
    // Security features discounts
    if (_hasTracker) riskMultiplier *= 0.85; // Good discount for tracker
    if (_hasAlarm) riskMultiplier *= 0.95;
    if (_hasImmobilizer) riskMultiplier *= 0.92;
    
    // Parking location
    if (_parking == 'Garage') riskMultiplier *= 0.9;
    else if (_parking == 'Secured Lot') riskMultiplier *= 0.85;
    
    // Peak hours penalty
    if (_peakHours) riskMultiplier *= 1.2;
    
    // Marital status discount
    if (_married) riskMultiplier *= 0.9;
    
    // Apply risk multiplier to base premium
    baseMonthlyPremium *= riskMultiplier;
    
    // Plan type adjustments
    Map<String, double> monthlyPremiums = {};
    
    // Comprehensive Plan (Full coverage)
    double comprehensivePremium = baseMonthlyPremium;
    monthlyPremiums['Comprehensive'] = comprehensivePremium;
    
    // Smart Plan (Balanced coverage - 25% cheaper than comprehensive)
    double smartPremium = baseMonthlyPremium * 0.75;
    monthlyPremiums['Smart'] = smartPremium;
    
    // Third-Party Plan (Basic coverage - 50% cheaper than comprehensive)
    double thirdPartyPremium = baseMonthlyPremium * 0.5;
    monthlyPremiums['Third-Party'] = thirdPartyPremium;
    
    // Ensure minimum realistic premiums for SA market
    monthlyPremiums.updateAll((key, value) {
      return value < 200 ? 200 : value; // Minimum R200 per month
    });
    
    return monthlyPremiums;
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
    final monthlyPremiums = _calculateQuote();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildQuoteResults(monthlyPremiums),
    );
  }

  Widget _buildQuoteResults(Map<String, double> monthlyPremiums) {
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
        child: SingleChildScrollView( // Added SingleChildScrollView to fix overflow
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
              const SizedBox(height: 10),
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
                "R ${monthlyPremiums['Comprehensive']?.toStringAsFixed(0) ?? '0'}/month",
                "Covers accidents, theft, fire, third-party, and natural disasters"
              ),
              const SizedBox(height: 12),
              _buildPlanCard(
                "Smart Plan", 
                Colors.greenAccent, 
                "Best Value", 
                "R ${monthlyPremiums['Smart']?.toStringAsFixed(0) ?? '0'}/month",
                "Balanced coverage with essential protection"
              ),
              const SizedBox(height: 12),
              _buildPlanCard(
                "Third-Party Plan", 
                Colors.orangeAccent, 
                "Essential", 
                "R ${monthlyPremiums['Third-Party']?.toStringAsFixed(0) ?? '0'}/month",
                "Covers damage to other vehicles and property only"
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
                      () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ApplyInsuranceScreen()))
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildActionButton(
                      "Save Quote", 
                      Colors.blueAccent,
                      () => Navigator.pop(context)
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
    _makeModelController.dispose();
    _yearController.dispose();
    _regNumberController.dispose();
    _mileageController.dispose();
    _valueController.dispose();
    _ageController.dispose();
    _claimsHistoryController.dispose();
    
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
            const SizedBox(height: 120),
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
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingHeader() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
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
        _buildDropdownField(
          "Car Make", 
          _selectedMake, 
          _saCarMakes, 
          (value) => setState(() {
            _selectedMake = value ?? '';
            _selectedModel = ''; // Reset model when make changes
          })
        ),
        const SizedBox(height: 15),
        if (_selectedMake.isNotEmpty)
          _buildDropdownField(
            "Car Model", 
            _selectedModel, 
            _saCarModels[_selectedMake] ?? [], 
            (value) => setState(() => _selectedModel = value ?? '')
          ),
        if (_selectedMake.isNotEmpty) const SizedBox(height: 15),
        _buildTextField("Year of Manufacture", _yearController, TextInputType.number),
        const SizedBox(height: 15),
        _buildTextField("Registration Number", _regNumberController, TextInputType.text),
        const SizedBox(height: 15),
        _buildTextField("Current Mileage (km)", _mileageController, TextInputType.number),
        const SizedBox(height: 15),
        _buildTextField("Vehicle Value (R)", _valueController, TextInputType.number),
      ],
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
          ['Comprehensive', 'Third-Party', 'Smart Plan'], 
          (value) => setState(() => _coverageType = value ?? 'Comprehensive')
        ),
        const SizedBox(height: 15),
        _buildDropdownField(
          "Vehicle Color", 
          _color, 
          _saColors, 
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
          _saAreas, 
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

  Widget _buildTextField(String label, TextEditingController controller, TextInputType keyboardType) {
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
            controller: controller,
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