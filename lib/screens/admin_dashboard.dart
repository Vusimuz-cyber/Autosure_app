import 'package:autosure_app/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> with TickerProviderStateMixin {
  late AnimationController _masterController;
  late Animation<double> _fadeAnimation;
  
  int _selectedTab = 0;
  final ScrollController _scrollController = ScrollController();
  
  // Firebase Database references
  final DatabaseReference _usersRef = FirebaseDatabase.instance.ref('users');
  final DatabaseReference _policiesRef = FirebaseDatabase.instance.ref('policies');
  final DatabaseReference _claimsRef = FirebaseDatabase.instance.ref('claims');
  final DatabaseReference _applicationsRef = FirebaseDatabase.instance.ref('insurance_applications');
  final DatabaseReference _notificationsRef = FirebaseDatabase.instance.ref('notifications');
  
  // Live data from Firebase
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _policies = [];
  List<Map<String, dynamic>> _claims = [];
  List<Map<String, dynamic>> _applications = [];
  Map<String, dynamic> _stats = {
    'totalUsers': 0,
    'activePolicies': 0,
    'pendingClaims': 0,
    'totalRevenue': 0,
    'pendingApplications': 0,
  };

  @override
  void initState() {
    super.initState();
    
    _masterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _masterController,
      curve: Curves.easeInOut,
    ));
    
    _masterController.forward();

    // Load initial data from Firebase
    _loadDashboardData();
  }

  void _loadDashboardData() {
    _loadUsers();
    _loadPolicies();
    _loadClaims();
    _loadApplications();
    _loadStats();
  }

  List<Map<String, dynamic>> _convertFirebaseDataToList(Map<dynamic, dynamic> data) {
    try {
      return data.entries.map((entry) {
        final key = entry.key?.toString() ?? 'unknown';
        final value = entry.value;
        
        Map<String, dynamic> itemData = {};
        
        if (value is Map<dynamic, dynamic>) {
          itemData = value.map((key, value) => MapEntry(key?.toString() ?? 'unknown', value));
        } else if (value is Map<String, dynamic>) {
          itemData = value;
        }
        
        return {
          'id': key,
          ...itemData,
        };
      }).toList();
    } catch (e) {
      print('Error converting Firebase data: $e');
      return [];
    }
  }

  void _loadUsers() {
    _usersRef.onValue.listen((event) {
      final data = event.snapshot.value;
      if (data != null && data is Map<dynamic, dynamic>) {
        setState(() {
          _users = _convertFirebaseDataToList(data);
        });
      }
    });
  }

  void _loadPolicies() {
    _policiesRef.onValue.listen((event) {
      final data = event.snapshot.value;
      if (data != null && data is Map<dynamic, dynamic>) {
        setState(() {
          _policies = _convertFirebaseDataToList(data);
        });
      }
    });
  }

  void _loadClaims() {
    _claimsRef.onValue.listen((event) {
      final data = event.snapshot.value;
      if (data != null && data is Map<dynamic, dynamic>) {
        setState(() {
          _claims = _convertFirebaseDataToList(data);
        });
      }
    });
  }

  void _loadApplications() {
    _applicationsRef.onValue.listen((event) {
      final data = event.snapshot.value;
      if (data != null && data is Map<dynamic, dynamic>) {
        setState(() {
          _applications = _convertFirebaseDataToList(data);
        });
      }
    });
  }

  void _loadStats() {
    _usersRef.onValue.listen((usersEvent) {
      _policiesRef.onValue.listen((policiesEvent) {
        _claimsRef.onValue.listen((claimsEvent) {
          _applicationsRef.onValue.listen((applicationsEvent) {
            setState(() {
              final users = usersEvent.snapshot.value as Map? ?? {};
              final policies = policiesEvent.snapshot.value as Map? ?? {};
              final claims = claimsEvent.snapshot.value as Map? ?? {};
              final applications = applicationsEvent.snapshot.value as Map? ?? {};
              
              _stats = {
                'totalUsers': users.length,
                'activePolicies': policies.values.where((policy) => policy['status'] == 'approved' || policy['status'] == 'Active').length,
                'pendingClaims': claims.values.where((claim) => claim['status'] == 'Pending').length,
                'totalRevenue': _calculateTotalRevenue(policies),
                'pendingApplications': applications.values.where((app) => app['status'] == 'submitted').length,
              };
            });
          });
        });
      });
    });
  }

  double _calculateTotalRevenue(Map policies) {
    double total = 0;
    policies.forEach((key, value) {
      if (value is Map && value['premiumAmount'] != null) {
        final premium = double.tryParse(value['premiumAmount'].toString()) ?? 0;
        total += premium;
      }
    });
    return total;
  }

  @override
  void dispose() {
    _masterController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleLogout() async {
    try {
      await FirebaseAuth.instance.signOut();
      
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      print('Error during logout: $e');
      _showErrorDialog('Logout failed. Please try again.');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E2A3B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withOpacity(0.2)),
        ),
        title: Text(
          'Error',
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

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E2A3B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withOpacity(0.2)),
        ),
        title: Text(
          'Confirm Logout',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Are you sure you want to logout from the admin panel?',
          style: GoogleFonts.poppins(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(
                color: Colors.white70,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _handleLogout();
            },
            style: TextButton.styleFrom(
              backgroundColor: Colors.redAccent.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Logout',
              style: GoogleFonts.poppins(
                color: Colors.redAccent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Admin management functions
  void _approveApplication(Map<String, dynamic> application) async {
    try {
      final applicationId = application['id'];
      final user = FirebaseAuth.instance.currentUser;
      
      await _applicationsRef.child(applicationId).update({
        'status': 'approved',
        'approvedAt': DateTime.now().millisecondsSinceEpoch,
        'approvedBy': user?.uid,
      });

      final policyId = _policiesRef.push().key;
      final quoteData = _safeCastMap(application['quoteData']);
      final personalInfo = _safeCastMap(application['personalInfo']);
      
      final newPolicy = {
        'id': policyId,
        'userId': application['userId'],
        'userEmail': application['userEmail'],
        'policyNumber': 'POL-${DateTime.now().millisecondsSinceEpoch}',
        'policyType': quoteData['coverageType'] ?? 'Comprehensive',
        'premiumAmount': quoteData['premiums']?['comprehensive'] ?? 0,
        'vehicleModel': '${quoteData['brand']} ${quoteData['model']}',
        'vehicleYear': quoteData['year'],
        'coverDuration': personalInfo['coverDuration'] ?? '12 Months',
        'status': 'approved',
        'startDate': DateTime.now().millisecondsSinceEpoch,
        'endDate': DateTime.now().add(const Duration(days: 365)).millisecondsSinceEpoch,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
        'createdBy': user?.uid,
        'applicationId': applicationId,
      };

      await _policiesRef.child(policyId!).set(newPolicy);
      
      _showSuccessSnackbar('Application approved and policy created successfully!');
    } catch (e) {
      _showErrorSnackbar('Failed to approve application: ${e.toString()}');
    }
  }

  void _rejectApplication(String applicationId, Map<String, dynamic> application) async {
    final TextEditingController reasonController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1E2A3B),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.redAccent.withOpacity(0.3)),
            ),
            title: Row(
              children: [
                Icon(Icons.warning, color: Colors.redAccent, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Reject Application',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Please provide a reason for rejection:',
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: TextField(
                    controller: reasonController,
                    maxLines: 4,
                    style: GoogleFonts.poppins(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'Enter rejection reason...',
                      hintStyle: TextStyle(color: Colors.white54),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(16),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'This reason will be sent to the user.',
                  style: GoogleFonts.poppins(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              TextButton(
                onPressed: () async {
                  if (reasonController.text.trim().isEmpty) {
                    _showErrorSnackbar('Please provide a rejection reason');
                    return;
                  }
                  
                  try {
                    final user = FirebaseAuth.instance.currentUser;
                    
                    // Update application status
                    await _applicationsRef.child(applicationId).update({
                      'status': 'rejected',
                      'rejectedAt': DateTime.now().millisecondsSinceEpoch,
                      'rejectedBy': user?.uid,
                      'rejectionReason': reasonController.text.trim(),
                    });

                    // Create notification for user
                    final notificationId = _notificationsRef.push().key;
                    final notification = {
                      'id': notificationId,
                      'userId': application['userId'],
                      'type': 'application_rejected',
                      'title': 'Application Rejected',
                      'message': 'Your insurance application has been rejected.',
                      'reason': reasonController.text.trim(),
                      'applicationId': applicationId,
                      'timestamp': DateTime.now().millisecondsSinceEpoch,
                      'read': false,
                    };

                    await _notificationsRef.child(notificationId!).set(notification);
                    
                    Navigator.pop(context);
                    _showSuccessSnackbar('Application rejected with reason sent to user!');
                  } catch (e) {
                    _showErrorSnackbar('Failed to reject application: ${e.toString()}');
                  }
                },
                style: TextButton.styleFrom(
                  backgroundColor: Colors.redAccent.withOpacity(0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Reject with Reason',
                  style: GoogleFonts.poppins(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _suspendUser(String userId) {
    _usersRef.child(userId).update({
      'status': 'suspended',
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    });
    _showSuccessSnackbar('User suspended successfully!');
  }

  void _activateUser(String userId) {
    _usersRef.child(userId).update({
      'status': 'active',
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    });
    _showSuccessSnackbar('User activated successfully!');
  }

  void _deleteUser(String userId) async {
    try {
      await _usersRef.child(userId).remove();
      _showSuccessSnackbar('User deleted successfully!');
    } catch (e) {
      _showErrorSnackbar('Failed to delete user: ${e.toString()}');
    }
  }

  void _approveClaim(String claimId) {
    _claimsRef.child(claimId).update({
      'status': 'Approved',
      'processedAt': DateTime.now().millisecondsSinceEpoch,
      'processedBy': FirebaseAuth.instance.currentUser?.uid,
    });
    _showSuccessSnackbar('Claim approved successfully!');
  }

  void _rejectClaim(String claimId, Map<String, dynamic> claim) async {
    final TextEditingController reasonController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1E2A3B),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.redAccent.withOpacity(0.3)),
            ),
            title: Row(
              children: [
                Icon(Icons.warning, color: Colors.redAccent, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Reject Claim',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Please provide a reason for rejection:',
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: TextField(
                    controller: reasonController,
                    maxLines: 4,
                    style: GoogleFonts.poppins(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'Enter rejection reason...',
                      hintStyle: TextStyle(color: Colors.white54),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(16),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'This reason will be sent to the user.',
                  style: GoogleFonts.poppins(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              TextButton(
                onPressed: () async {
                  if (reasonController.text.trim().isEmpty) {
                    _showErrorSnackbar('Please provide a rejection reason');
                    return;
                  }
                  
                  try {
                    final user = FirebaseAuth.instance.currentUser;
                    
                    // Update claim status
                    await _claimsRef.child(claimId).update({
                      'status': 'Rejected',
                      'processedAt': DateTime.now().millisecondsSinceEpoch,
                      'processedBy': user?.uid,
                      'rejectionReason': reasonController.text.trim(),
                    });

                    // Create notification for user
                    final notificationId = _notificationsRef.push().key;
                    final notification = {
                      'id': notificationId,
                      'userId': claim['userId'],
                      'type': 'claim_rejected',
                      'title': 'Claim Rejected',
                      'message': 'Your insurance claim has been rejected.',
                      'reason': reasonController.text.trim(),
                      'claimId': claimId,
                      'timestamp': DateTime.now().millisecondsSinceEpoch,
                      'read': false,
                    };

                    await _notificationsRef.child(notificationId!).set(notification);
                    
                    Navigator.pop(context);
                    _showSuccessSnackbar('Claim rejected with reason sent to user!');
                  } catch (e) {
                    _showErrorSnackbar('Failed to reject claim: ${e.toString()}');
                  }
                },
                style: TextButton.styleFrom(
                  backgroundColor: Colors.redAccent.withOpacity(0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Reject with Reason',
                  style: GoogleFonts.poppins(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Map<String, dynamic> _safeCastMap(dynamic data) {
    if (data is Map<dynamic, dynamic>) {
      return data.map((key, value) => MapEntry(key?.toString() ?? '', value));
    } else if (data is Map<String, dynamic>) {
      return data;
    }
    return <String, dynamic>{};
  }

  String _getUserDisplayName(Map<String, dynamic> user) {
    final personalInfo = _safeCastMap(user['personalInfo']);
    if (personalInfo.isNotEmpty) {
      final firstName = personalInfo['firstName']?.toString() ?? '';
      final lastName = personalInfo['lastName']?.toString() ?? '';
      
      if (firstName.isNotEmpty && lastName.isNotEmpty) {
        return '$firstName $lastName';
      } else if (firstName.isNotEmpty) {
        return firstName;
      } else if (lastName.isNotEmpty) {
        return lastName;
      }
    }
    
    final directFirstName = user['firstName']?.toString() ?? '';
    final directLastName = user['lastName']?.toString() ?? '';
    
    if (directFirstName.isNotEmpty && directLastName.isNotEmpty) {
      return '$directFirstName $directLastName';
    } else if (directFirstName.isNotEmpty) {
      return directFirstName;
    } else if (directLastName.isNotEmpty) {
      return directLastName;
    }
    
    final email = user['email']?.toString() ?? '';
    if (email.isNotEmpty) {
      final emailUsername = email.split('@').first;
      return emailUsername[0].toUpperCase() + emailUsername.substring(1);
    }
    
    return 'Unknown User';
  }

  String _getUserNameById(String userId) {
    final user = _users.firstWhere((user) => user['id'] == userId, orElse: () => <String, dynamic>{});
    return _getUserDisplayName(user);
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

  String _formatCurrency(double amount) {
    return amount.toStringAsFixed(2);
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';
    try {
      final timestamp = int.tryParse(date.toString());
      if (timestamp != null) {
        final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
        return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
      }
      return date.toString();
    } catch (e) {
      return date.toString();
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
      case 'approved':
        return Colors.greenAccent;
      case 'suspended':
      case 'pending':
        return Colors.orangeAccent;
      case 'rejected':
        return Colors.redAccent;
      default:
        return Colors.white70;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Row(
          children: [
            // Sidebar
            _buildSidebar(),
            
            // Main Content
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: _buildMainContentArea(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContentArea() {
    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        // Stats Overview (Only for Dashboard)
        if (_selectedTab == 0) _buildStatsOverview(),
        
        // Main Content based on selected tab
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: _getContentForTab(),
          ),
        ),
        
        // Bottom spacing
        const SliverToBoxAdapter(
          child: SizedBox(height: 40),
        ),
      ],
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(4, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Logo and Title
          Container(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Colors.blueAccent, Colors.lightBlueAccent],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blueAccent.withOpacity(0.4),
                        blurRadius: 20,
                        spreadRadius: 3,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.admin_panel_settings, color: Colors.white, size: 35),
                ),
                const SizedBox(height: 16),
                Text(
                  'Admin Portal',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'AutoSure Management',
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          
          // Navigation Items
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    _buildNavItem(Icons.dashboard, 'Dashboard', 0),
                    _buildNavItem(Icons.people, 'User Management', 1),
                    _buildNavItem(Icons.description, 'Applications', 2),
                    _buildNavItem(Icons.policy, 'Policies', 3),
                    _buildNavItem(Icons.analytics, 'Claims', 4),
                    _buildNavItem(Icons.bar_chart, 'Reports', 5),
                  ],
                ),
              ),
            ),
          ),
          
          // User Info with Logout
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Colors.greenAccent, Colors.green],
                        ),
                      ),
                      child: const Icon(Icons.person, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Admin User',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'Super Administrator',
                            style: GoogleFonts.poppins(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: _showLogoutConfirmation,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.redAccent.withOpacity(0.2),
                            Colors.redAccent.withOpacity(0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.logout, color: Colors.redAccent, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            'Logout',
                            style: GoogleFonts.poppins(
                              color: Colors.redAccent,
                              fontSize: 13,
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
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String title, int index) {
    final isSelected = _selectedTab == index;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        gradient: isSelected
            ? LinearGradient(
                colors: [
                  Colors.blueAccent.withOpacity(0.3),
                  Colors.blueAccent.withOpacity(0.1),
                ],
              )
            : null,
        borderRadius: BorderRadius.circular(10),
        border: isSelected ? Border.all(color: Colors.blueAccent.withOpacity(0.5)) : null,
      ),
      child: ListTile(
        leading: Icon(icon, 
            color: isSelected ? Colors.blueAccent : Colors.white70, 
            size: 20),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            color: isSelected ? Colors.blueAccent : Colors.white70,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
        trailing: isSelected ? const Icon(Icons.arrow_forward_ios, color: Colors.blueAccent, size: 12) : null,
        onTap: () => setState(() => _selectedTab = index),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        dense: true,
      ),
    );
  }

  SliverToBoxAdapter _buildStatsOverview() {
    return SliverToBoxAdapter(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          padding: const EdgeInsets.all(24),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: _getCrossAxisCount(context),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.2,
            ),
            itemCount: 5,
            itemBuilder: (context, index) {
              final stats = [
                _buildStatCard('Total Users', _stats['totalUsers'].toString(), Icons.people, Colors.blueAccent),
                _buildStatCard('Active Policies', _stats['activePolicies'].toString(), Icons.policy, Colors.greenAccent),
                _buildStatCard('Pending Claims', _stats['pendingClaims'].toString(), Icons.description, Colors.orangeAccent),
                _buildStatCard('Revenue', 'R ${_formatCurrency(_stats['totalRevenue'])}', Icons.attach_money, Colors.purpleAccent),
                _buildStatCard('Pending Applications', _stats['pendingApplications'].toString(), Icons.pending_actions, Colors.amberAccent),
              ];
              return stats[index];
            },
          ),
        ),
      ),
    );
  }

  int _getCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1400) return 5;
    if (width > 1100) return 3;
    if (width > 800) return 3;
    if (width > 500) return 2;
    return 1;
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.2),
            color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: GoogleFonts.poppins(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _getContentForTab() {
    switch (_selectedTab) {
      case 0: return _buildDashboard();
      case 1: return _buildUserManagement();
      case 2: return _buildApplications();
      case 3: return _buildPolicies();
      case 4: return _buildClaims();
      case 5: return _buildReports();
      default: return _buildDashboard();
    }
  }

  Widget _buildDashboard() {
    return Container(); // Only stats are shown from the SliverToBoxAdapter
  }

  Widget _buildUserManagement() {
    return _users.isEmpty
        ? _buildEmptyState('No users found', Icons.people)
        : Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Column(
              children: [
                // Table Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.1),
                        Colors.white.withOpacity(0.05),
                    ],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          'User Information',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'Status',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'Policies',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'Actions',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Table Rows
                ..._users.map((user) => _buildUserRow(user)).toList(),
              ],
            ),
          );
  }

  Widget _buildUserRow(Map<String, dynamic> user) {
    final userPolicies = _policies.where((policy) => policy['userId'] == user['id']).toList();
    final status = user['status']?.toString() ?? 'active';
    final displayName = _getUserDisplayName(user);
    final email = user['email']?.toString() ?? 'No email';
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _getStatusColor(status).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                status.toUpperCase(),
                style: GoogleFonts.poppins(
                  color: _getStatusColor(status),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Expanded(
            child: Text(
              userPolicies.length.toString(),
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (status == 'active')
                  IconButton(
                    onPressed: () => _showSuspendConfirmation(user),
                    icon: const Icon(Icons.pause, color: Colors.orangeAccent, size: 22),
                    tooltip: 'Suspend',
                  )
                else
                  IconButton(
                    onPressed: () => _activateUser(user['id']),
                    icon: const Icon(Icons.play_arrow, color: Colors.greenAccent, size: 22),
                    tooltip: 'Activate',
                  ),
                IconButton(
                  onPressed: () => _showDeleteConfirmation(user),
                  icon: const Icon(Icons.delete, color: Colors.redAccent, size: 22),
                    tooltip: 'Delete',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApplications() {
    final pendingApplications = _applications.where((app) => app['status'] == 'submitted').toList();
    final approvedApplications = _applications.where((app) => app['status'] == 'approved').toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Pending Applications Section
        if (pendingApplications.isNotEmpty) ...[
          Text(
            'Pending Applications',
            style: GoogleFonts.poppins(
              color: Colors.orangeAccent,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Column(
            children: pendingApplications.map((application) => _buildApplicationInfo(application)).toList(),
          ),
          const SizedBox(height: 24),
        ],

        // Approved Applications Section
        if (approvedApplications.isNotEmpty) ...[
          Text(
            'Approved Applications',
            style: GoogleFonts.poppins(
              color: Colors.greenAccent,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Column(
            children: approvedApplications.map((application) => _buildApplicationInfo(application, showActions: false)).toList(),
          ),
        ],

        if (pendingApplications.isEmpty && approvedApplications.isEmpty)
          _buildEmptyState('No applications found', Icons.description),
      ],
    );
  }

  Widget _buildApplicationInfo(Map<String, dynamic> application, {bool showActions = true}) {
    final quoteData = _safeCastMap(application['quoteData']);
    final personalInfo = _safeCastMap(application['personalInfo']);
    final status = application['status']?.toString() ?? 'submitted';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.05),
            Colors.white.withOpacity(0.02),
        ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${personalInfo['firstName'] ?? ''} ${personalInfo['lastName'] ?? ''}',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      application['userEmail']?.toString() ?? 'No email',
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getStatusColor(status).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: GoogleFonts.poppins(
                    color: _getStatusColor(status),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Vehicle Information
          Row(
            children: [
              const Icon(Icons.directions_car, color: Colors.blueAccent, size: 16),
              const SizedBox(width: 8),
              Text(
                '${quoteData['brand'] ?? ''} ${quoteData['model'] ?? ''} (${quoteData['year'] ?? ''})',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              const Icon(Icons.attach_money, color: Colors.greenAccent, size: 16),
              const SizedBox(width: 8),
              Text(
                'R${quoteData['value'] ?? '0'}',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Coverage Type
          Row(
            children: [
              const Icon(Icons.security, color: Colors.purpleAccent, size: 16),
              const SizedBox(width: 8),
              Text(
                '${quoteData['coverageType'] ?? 'Comprehensive'} Coverage',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          
          if (showActions) ...[
            const SizedBox(height: 16),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: () => _showApplicationDetails(application),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.blueAccent.withOpacity(0.1),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.visibility, color: Colors.blueAccent, size: 18),
                    label: Text(
                      'View Details',
                      style: GoogleFonts.poppins(
                        color: Colors.blueAccent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextButton.icon(
                    onPressed: () => _approveApplication(application),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.greenAccent.withOpacity(0.1),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.check, color: Colors.greenAccent, size: 18),
                    label: Text(
                      'Approve',
                      style: GoogleFonts.poppins(
                        color: Colors.greenAccent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextButton.icon(
                    onPressed: () => _rejectApplication(application['id'], application),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.redAccent.withOpacity(0.1),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.close, color: Colors.redAccent, size: 18),
                    label: Text(
                      'Reject',
                      style: GoogleFonts.poppins(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPolicies() {
    final activePolicies = _policies.where((policy) => policy['status'] == 'approved' || policy['status'] == 'Active').toList();
    
    return activePolicies.isEmpty
        ? _buildEmptyState('No active policies', Icons.policy)
        : Column(
            children: activePolicies.map((policy) => _buildPolicyInfo(policy)).toList(),
          );
  }

  Widget _buildPolicyInfo(Map<String, dynamic> policy) {
    final userName = _getUserNameById(policy['userId'] ?? '');
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.greenAccent.withOpacity(0.1),
            Colors.greenAccent.withOpacity(0.05),
        ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.greenAccent.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      policy['policyNumber']?.toString() ?? 'No Policy Number',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Owner: $userName',
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.greenAccent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'ACTIVE',
                  style: GoogleFonts.poppins(
                    color: Colors.greenAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Policy Details
          Row(
            children: [
              const Icon(Icons.directions_car, color: Colors.blueAccent, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  policy['vehicleModel']?.toString() ?? 'Unknown Vehicle',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ),
              const Icon(Icons.attach_money, color: Colors.greenAccent, size: 16),
              const SizedBox(width: 8),
              Text(
                'R${_formatCurrency(policy['premiumAmount'] ?? 0)}',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          Row(
            children: [
              const Icon(Icons.security, color: Colors.purpleAccent, size: 16),
              const SizedBox(width: 8),
              Text(
                policy['policyType']?.toString() ?? 'Comprehensive',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              const Icon(Icons.calendar_today, color: Colors.orangeAccent, size: 16),
              const SizedBox(width: 8),
              Text(
                '${policy['coverDuration'] ?? '12 Months'}',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildClaims() {
    final pendingClaims = _claims.where((claim) => claim['status'] == 'Pending').toList();
    final approvedClaims = _claims.where((claim) => claim['status'] == 'Approved').toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Pending Claims Section
        if (pendingClaims.isNotEmpty) ...[
          Text(
            'Pending Claims',
            style: GoogleFonts.poppins(
              color: Colors.orangeAccent,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Column(
            children: pendingClaims.map((claim) => _buildClaimInfo(claim)).toList(),
          ),
          const SizedBox(height: 24),
        ],

        // Approved Claims Section
        if (approvedClaims.isNotEmpty) ...[
          Text(
            'Approved Claims',
            style: GoogleFonts.poppins(
              color: Colors.greenAccent,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Column(
            children: approvedClaims.map((claim) => _buildClaimInfo(claim, showActions: false)).toList(),
          ),
        ],

        if (pendingClaims.isEmpty && approvedClaims.isEmpty)
          _buildEmptyState('No claims found', Icons.analytics),
      ],
    );
  }

  Widget _buildClaimInfo(Map<String, dynamic> claim, {bool showActions = true}) {
    final status = claim['status']?.toString() ?? 'Pending';
    final userName = _getUserNameById(claim['userId'] ?? '');
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.05),
            Colors.white.withOpacity(0.02),
        ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Claim #${claim['id']?.toString().substring(0, 8) ?? 'Unknown'}',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'By: $userName',
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getStatusColor(status).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: GoogleFonts.poppins(
                    color: _getStatusColor(status),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Claim Details
          Row(
            children: [
              const Icon(Icons.description, color: Colors.blueAccent, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  claim['type']?.toString() ?? 'Unknown Type',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ),
              const Icon(Icons.attach_money, color: Colors.greenAccent, size: 16),
              const SizedBox(width: 8),
              Text(
                'R${_formatCurrency(claim['amount'] ?? 0)}',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          if (claim['description'] != null) ...[
            Text(
              'Description: ${claim['description']}',
              style: GoogleFonts.poppins(
                color: Colors.white70,
                fontSize: 14,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
          ],
          
          if (showActions) ...[
            const SizedBox(height: 16),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: () => _showClaimDetails(claim),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.blueAccent.withOpacity(0.1),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.visibility, color: Colors.blueAccent, size: 18),
                    label: Text(
                      'View Details',
                      style: GoogleFonts.poppins(
                        color: Colors.blueAccent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextButton.icon(
                    onPressed: () => _approveClaim(claim['id']),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.greenAccent.withOpacity(0.1),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.check, color: Colors.greenAccent, size: 18),
                    label: Text(
                      'Approve',
                      style: GoogleFonts.poppins(
                        color: Colors.greenAccent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextButton.icon(
                    onPressed: () => _rejectClaim(claim['id'], claim),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.redAccent.withOpacity(0.1),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.close, color: Colors.redAccent, size: 18),
                    label: Text(
                      'Reject',
                      style: GoogleFonts.poppins(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReports() {
    final totalRevenue = _stats['totalRevenue'];
    final activePolicies = _stats['activePolicies'];
    final pendingClaims = _stats['pendingClaims'];
    final totalUsers = _stats['totalUsers'];
    final pendingApplications = _stats['pendingApplications'];
    
    // Calculate metrics for reports
    final averagePremium = activePolicies > 0 ? totalRevenue / activePolicies : 0;
    final approvalRate = _applications.isNotEmpty ? 
        (_applications.where((app) => app['status'] == 'approved').length / _applications.length * 100) : 0;
    final claimApprovalRate = _claims.isNotEmpty ? 
        (_claims.where((claim) => claim['status'] == 'Approved').length / _claims.length * 100) : 0;
    
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Key Metrics
          Text(
            'Key Performance Indicators',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),

          // Stats Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.5,
            ),
            itemCount: 6,
            itemBuilder: (context, index) {
              final stats = [
                _buildCleanStatCard('Total Revenue', 'R ${_formatCurrency(totalRevenue)}', Icons.attach_money, Colors.greenAccent),
                _buildCleanStatCard('Active Policies', activePolicies.toString(), Icons.policy, Colors.blueAccent),
                _buildCleanStatCard('Total Users', totalUsers.toString(), Icons.people, Colors.purpleAccent),
                _buildCleanStatCard('Pending Applications', pendingApplications.toString(), Icons.pending_actions, Colors.orangeAccent),
                _buildCleanStatCard('Pending Claims', pendingClaims.toString(), Icons.description, Colors.redAccent),
                _buildCleanStatCard('Avg Premium', 'R ${_formatCurrency(averagePremium)}', Icons.trending_up, Colors.tealAccent),
              ];
              return stats[index];
            },
          ),

          const SizedBox(height: 32),

          // Charts Section
          Text(
            'Performance Analytics',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),

          // Clean Bar Chart for Policy Distribution
          _buildCleanBarChart(),
          const SizedBox(height: 24),


          const SizedBox(height: 32),

          // Insights Section
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.blueAccent.withOpacity(0.15),
                  Colors.purpleAccent.withOpacity(0.08),
              ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.insights, color: Colors.blueAccent, size: 28),
                    const SizedBox(width: 12),
                    Text(
                      'Business Insights',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildCleanInsightItem('📈', 'Application approval rate: ${approvalRate.toStringAsFixed(1)}%'),
                _buildCleanInsightItem('🛡️', 'Claim approval rate: ${claimApprovalRate.toStringAsFixed(1)}%'),
                _buildCleanInsightItem('💰', 'Average premium per policy: R${_formatCurrency(averagePremium)}'),
                _buildCleanInsightItem('👥', 'Active user conversion rate: ${((activePolicies / totalUsers) * 100).toStringAsFixed(1)}%'),
              ],
            ),
          ),
          
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildCleanStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.15),
            color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: GoogleFonts.poppins(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCleanBarChart() {
    final policyTypes = ['Comprehensive', 'Third Party', 'Theft', 'Accident'];
    final policyCounts = [45, 30, 15, 10]; // Sample data
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blueAccent.withOpacity(0.15),
            Colors.blueAccent.withOpacity(0.05),
        ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bar_chart, color: Colors.blueAccent, size: 24),
              const SizedBox(width: 12),
              Text(
                'Policy Distribution',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(policyTypes.length, (index) {
                final percentage = policyCounts[index];
                final height = (percentage / 50) * 150; // Scale to max 150px
                final colors = [
                  Colors.blueAccent,
                  Colors.greenAccent,
                  Colors.orangeAccent,
                  Colors.purpleAccent,
                ];
                
                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      width: 40,
                      height: height,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            colors[index].withOpacity(0.8),
                            colors[index].withOpacity(0.4),
                          ],
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(8),
                          topRight: Radius.circular(8),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '$percentage%',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: 60,
                      child: Text(
                        policyTypes[index],
                        style: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCleanPieChart(double appRate, double claimRate) {
    final data = [
      {'label': 'Applications', 'value': appRate, 'color': Colors.greenAccent},
      {'label': 'Claims', 'value': claimRate, 'color': Colors.blueAccent},
      {'label': 'Pending', 'value': 100 - ((appRate + claimRate) / 2), 'color': Colors.orangeAccent},
    ];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.purpleAccent.withOpacity(0.15),
            Colors.purpleAccent.withOpacity(0.05),
        ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.purpleAccent.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.pie_chart, color: Colors.purpleAccent, size: 24),
              const SizedBox(width: 12),
              Text(
                'Approval Rates',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              // Simple pie chart visualization
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const SweepGradient(
                    colors: [Colors.greenAccent, Colors.blueAccent, Colors.orangeAccent],
                    stops: [0.3, 0.6, 1.0],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.purpleAccent.withOpacity(0.3),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Center(
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF1E293B),
                    ),
                    child: Center(
                      child: Text(
                        '${((appRate + claimRate) / 2).toStringAsFixed(0)}%',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: data.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: item['color'] as Color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            item['label'] as String,
                            style: GoogleFonts.poppins(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        Text(
                          '${(item['value'] as double).toStringAsFixed(1)}%',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  )).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsOverview(double appRate, double claimRate, double avgPremium) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.greenAccent.withOpacity(0.15),
            Colors.greenAccent.withOpacity(0.05),
        ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.greenAccent.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.analytics, color: Colors.greenAccent, size: 24),
              const SizedBox(width: 12),
              Text(
                'Performance Metrics',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _buildMetricChip('Application Approval', '${appRate.toStringAsFixed(1)}%', Colors.greenAccent),
              _buildMetricChip('Claim Approval', '${claimRate.toStringAsFixed(1)}%', Colors.blueAccent),
              _buildMetricChip('Avg Processing Time', '2.3 days', Colors.orangeAccent),
              _buildMetricChip('Customer Satisfaction', '94%', Colors.purpleAccent),
              _buildMetricChip('Policy Renewal Rate', '88%', Colors.tealAccent),
              _buildMetricChip('Revenue Growth', '+12.5%', Colors.greenAccent),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: GoogleFonts.poppins(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCleanInsightItem(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
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

  Widget _buildEmptyState(String message, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(60),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white30, size: 80),
          const SizedBox(height: 20),
          Text(
            message,
            style: GoogleFonts.poppins(
              color: Colors.white30,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

    void _showSuspendConfirmation(Map<String, dynamic> user) {
    final displayName = _getUserDisplayName(user);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E2A3B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.orangeAccent.withOpacity(0.3)),
        ),
        title: Text(
          'Suspend User',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Are you sure you want to suspend $displayName?',
          style: GoogleFonts.poppins(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(
                color: Colors.white70,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              _suspendUser(user['id']);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(
              backgroundColor: Colors.orangeAccent.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Suspend',
              style: GoogleFonts.poppins(
                color: Colors.orangeAccent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(Map<String, dynamic> user) {
    final displayName = _getUserDisplayName(user);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E2A3B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.redAccent.withOpacity(0.3)),
        ),
        title: Text(
          'Delete User',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Are you sure you want to delete $displayName? This action cannot be undone.',
          style: GoogleFonts.poppins(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(
                color: Colors.white70,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              _deleteUser(user['id']);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(
              backgroundColor: Colors.redAccent.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Delete',
              style: GoogleFonts.poppins(
                color: Colors.redAccent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showApplicationDetails(Map<String, dynamic> application) {
    final quoteData = _safeCastMap(application['quoteData']);
    final personalInfo = _safeCastMap(application['personalInfo']);
    final documents = _safeCastMap(application['documents']);
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF1E2A3B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.blueAccent.withOpacity(0.3)),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Application Details',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildDetailSection('Personal Information', [
                        _buildDetailItem('Full Name', '${personalInfo['firstName'] ?? ''} ${personalInfo['lastName'] ?? ''}'),
                        _buildDetailItem('ID Number', personalInfo['idNumber']?.toString() ?? 'N/A'),
                        _buildDetailItem('Contact', personalInfo['contactNumber']?.toString() ?? 'N/A'),
                        _buildDetailItem('Address', personalInfo['address']?.toString() ?? 'N/A'),
                        _buildDetailItem('Email', application['userEmail']?.toString() ?? 'N/A'),
                        _buildDetailItem('Cover Duration', personalInfo['coverDuration']?.toString() ?? '12 Months'),
                      ]),
                      
                      const SizedBox(height: 16),
                      
                      _buildDetailSection('Vehicle Details', [
                        _buildDetailItem('Brand', quoteData['brand']?.toString() ?? 'N/A'),
                        _buildDetailItem('Model', quoteData['model']?.toString() ?? 'N/A'),
                        _buildDetailItem('Year', quoteData['year']?.toString() ?? 'N/A'),
                        _buildDetailItem('Color', quoteData['color']?.toString() ?? 'N/A'),
                        _buildDetailItem('Registration', quoteData['regNumber']?.toString() ?? 'N/A'),
                        _buildDetailItem('Vehicle Value', 'R${quoteData['value']?.toString() ?? 'N/A'}'),
                        _buildDetailItem('Coverage Type', quoteData['coverageType']?.toString() ?? 'Comprehensive'),
                      ]),
                      
                      const SizedBox(height: 16),
                      
                      _buildDetailSection('Document Status', [
                        _buildDocumentStatusItem('ID Document', documents['id_document'] == true),
                        _buildDocumentStatusItem('Proof of Address', documents['proof_of_address'] == true),
                        _buildDocumentStatusItem('Vehicle Photos', documents['vehicle_photos'] == true),
                        _buildDocumentStatusItem('Vehicle Registration', documents['vehicle_registration'] == true),
                      ]),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.blueAccent.withOpacity(0.1),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      child: Text(
                        'Close',
                        style: GoogleFonts.poppins(
                          color: Colors.blueAccent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            color: Colors.blueAccent,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: GoogleFonts.poppins(
              color: Colors.white70,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentStatusItem(String documentName, bool isUploaded) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            isUploaded ? Icons.check_circle : Icons.warning,
            color: isUploaded ? Colors.greenAccent : Colors.orangeAccent,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              documentName,
              style: GoogleFonts.poppins(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ),
          Text(
            isUploaded ? 'Uploaded' : 'Not Uploaded',
            style: GoogleFonts.poppins(
              color: isUploaded ? Colors.greenAccent : Colors.orangeAccent,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _showClaimDetails(Map<String, dynamic> claim) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF1E2A3B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.blueAccent.withOpacity(0.3)),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Claim Details',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildDetailSection('Claim Information', [
                        _buildDetailItem('Claim ID', claim['id']?.toString() ?? 'N/A'),
                        _buildDetailItem('User Email', claim['userEmail']?.toString() ?? 'N/A'),
                        _buildDetailItem('Claim Type', claim['type']?.toString() ?? 'N/A'),
                        _buildDetailItem('Claim Amount', 'R${_formatCurrency(claim['amount'] ?? 0)}'),
                        _buildDetailItem('Status', claim['status']?.toString() ?? 'Pending'),
                        _buildDetailItem('Description', claim['description']?.toString() ?? 'No description provided'),
                      ]),
                      
                      if (claim['incidentDate'] != null) ...[
                        const SizedBox(height: 16),
                        _buildDetailSection('Incident Details', [
                          _buildDetailItem('Incident Date', _formatDate(claim['incidentDate'])),
                          _buildDetailItem('Incident Location', claim['incidentLocation']?.toString() ?? 'N/A'),
                          _buildDetailItem('Police Report', claim['policeReport']?.toString() ?? 'No'),
                        ]),
                      ],
                      
                      if (claim['documents'] != null && claim['documents'] is Map) ...[
                        const SizedBox(height: 16),
                        _buildDetailSection('Document Status', [
                          _buildDocumentStatusItem('Photos Uploaded', claim['documents']['photos'] == true),
                          _buildDocumentStatusItem('Police Report', claim['documents']['police_report'] == true),
                          _buildDocumentStatusItem('Repair Estimates', claim['documents']['estimates'] == true),
                        ]),
                      ],
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.blueAccent.withOpacity(0.1),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      child: Text(
                        'Close',
                        style: GoogleFonts.poppins(
                          color: Colors.blueAccent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}