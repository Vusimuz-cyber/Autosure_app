import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'get_quote_screen.dart';
import 'apply_insurance_screen.dart';
import 'plans_screen.dart';
import 'admin_dashboard.dart';
import 'login_screen.dart';
import 'claims_screen.dart';

class HomeScreen extends StatefulWidget {
  final String username;

  const HomeScreen({super.key, required this.username});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _masterController;
  late AnimationController _glowController;
  late AnimationController _particleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  
  int _selectedIndex = 0;
  bool _isAdmin = false;
  double _scrollOffset = 0.0;
  bool _showFloatingHeader = true;

  final ScrollController _scrollController = ScrollController();
  final DatabaseReference _policiesRef = FirebaseDatabase.instance.ref('policies');
  final DatabaseReference _usersRef = FirebaseDatabase.instance.ref('users');
  final DatabaseReference _claimsRef = FirebaseDatabase.instance.ref('claims');
  final DatabaseReference _applicationsRef = FirebaseDatabase.instance.ref('insurance_applications');
  final DatabaseReference _notificationsRef = FirebaseDatabase.instance.ref('notifications');
  
  StreamSubscription? _policiesSubscription;
  StreamSubscription? _applicationsSubscription;
  StreamSubscription? _claimsSubscription;
  StreamSubscription? _usersSubscription;
  StreamSubscription? _notificationsSubscription;

  List<Map<String, dynamic>> _userPolicies = [];
  List<Map<String, dynamic>> _userClaims = [];
  List<Map<String, dynamic>> _userApplications = [];
  List<Map<String, dynamic>> _userNotifications = [];
  Map<String, dynamic> _userStats = {
    'activePolicy': 'No Policy',
    'nextRenewal': 'N/A',
    'totalClaims': '0',
  };
  Map<String, dynamic> _userData = {};

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _setupScrollListener();
    _loadUserData();
    _checkAdminStatus();
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
    
    _masterController.forward();
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      setState(() {
        _scrollOffset = _scrollController.offset;
        _showFloatingHeader = _scrollOffset < 100;
      });
    });
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

  void _loadUserData() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _policiesSubscription = _policiesRef.orderByChild('userId').equalTo(user.uid).onValue.listen((event) {
      final data = event.snapshot.value;
      if (mounted && data != null && data is Map<dynamic, dynamic>) {
        setState(() {
          _userPolicies = _convertFirebaseDataToList(data);
          _updateUserStats();
        });
      }
    });

    _applicationsSubscription = _applicationsRef.orderByChild('userId').equalTo(user.uid).onValue.listen((event) {
      final data = event.snapshot.value;
      if (mounted && data != null && data is Map<dynamic, dynamic>) {
        setState(() {
          _userApplications = _convertFirebaseDataToList(data);
        });
      }
    });

    _claimsSubscription = _claimsRef.orderByChild('userId').equalTo(user.uid).onValue.listen((event) {
      final data = event.snapshot.value;
      if (mounted && data != null && data is Map<dynamic, dynamic>) {
        setState(() {
          _userClaims = _convertFirebaseDataToList(data);
          _updateUserStats();
        });
      }
    });

    _usersSubscription = _usersRef.child(user.uid).onValue.listen((event) {
      final data = event.snapshot.value;
      if (mounted && data != null && data is Map<dynamic, dynamic>) {
        setState(() {
          _userData = data.map((key, value) => MapEntry(key?.toString() ?? '', value));
        });
      }
    });

    _notificationsSubscription = _notificationsRef
      .orderByChild('userId')
      .equalTo(user.uid)
      .onValue
      .listen((event) {
      final data = event.snapshot.value;
      if (mounted && data != null && data is Map<dynamic, dynamic>) {
        setState(() {
          _userNotifications = _convertFirebaseDataToList(data);
        });
      }
    });
  }

  void _checkAdminStatus() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _usersRef.child(user.uid).onValue.listen((event) {
      final data = event.snapshot.value;
      if (mounted && data != null && data is Map<dynamic, dynamic>) {
        final userData = data.map((key, value) => MapEntry(key?.toString() ?? '', value));
        setState(() {
          _isAdmin = userData['isAdmin'] == true || userData['role'] == 'admin';
        });
      }
    });
  }

  void _updateUserStats() {
    final activePolicy = _userPolicies.firstWhere(
      (policy) => policy['status'] == 'Active' || policy['status'] == 'approved',
      orElse: () => <String, dynamic>{},
    );

    final totalClaims = _userClaims.length;

    setState(() {
      _userStats = {
        'activePolicy': activePolicy.isNotEmpty
            ? (activePolicy['policyType']?.toString() ??
               activePolicy['quoteData']?['coverageType']?.toString() ??
               'Active Policy')
            : 'No Policy',
        'nextRenewal': _getNextRenewalDate(activePolicy),
        'totalClaims': totalClaims.toString(),
      };
    });
  }

  String _getNextRenewalDate(Map<String, dynamic> policy) {
    if (policy.isEmpty) return 'N/A';
    
    final endDate = policy['endDate'];
    if (endDate == null) return 'N/A';
    
    try {
      final date = DateTime.fromMillisecondsSinceEpoch(int.tryParse(endDate.toString()) ?? 0);
      final now = DateTime.now();
      
      if (date.isBefore(now)) return 'Expired';
      
      final difference = date.difference(now).inDays;
      return '$difference days';
    } catch (e) {
      return 'N/A';
    }
  }

  @override
  void dispose() {
    _masterController.dispose();
    _glowController.dispose();
    _particleController.dispose();
    _scrollController.dispose();
    
    _policiesSubscription?.cancel();
    _applicationsSubscription?.cancel();
    _claimsSubscription?.cancel();
    _usersSubscription?.cancel();
    _notificationsSubscription?.cancel();
    
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _logout() {
    Navigator.pushAndRemoveUntil(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const LoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, -1.0);
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

  void _navigateToAdmin() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const AdminDashboard(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutQuart;
          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          return SlideTransition(position: animation.drive(tween), child: child);
        },
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
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
              SliverToBoxAdapter(child: _getCurrentScreen()),
            ],
          ),
          _buildFloatingHeader(),
        ],
      ),
      bottomNavigationBar: _buildMinimalNavigationBar(),
    );
  }

  Widget _getCurrentScreen() {
    switch (_selectedIndex) {
      case 0:
        return _buildHomeScreen();
      case 1:
        return _buildPoliciesScreen();
      case 2:
        return _buildNotificationsScreen();
      case 3:
        return _buildProfileScreen();
      default:
        return _buildHomeScreen();
    }
  }

  Widget _buildHomeScreen() {
    return Padding(
      padding: const EdgeInsets.all(25.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeSection(),
          const SizedBox(height: 30),
          _buildInsuranceOverview(),
          const SizedBox(height: 30),
          _buildKnowledgeHub(),
          const SizedBox(height: 30),
          _buildServicesGrid(),
          const SizedBox(height: 30),
          _buildRecentActivity(),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildPoliciesScreen() {
    // Filter applications to only show pending ones
    final pendingApplications = _userApplications.where((app) {
      final status = app['status']?.toString().toLowerCase();
      return status != 'approved' && status != 'active' && status != 'rejected';
    }).toList();

    // Filter policies to only show active/approved ones
    final activePolicies = _userPolicies.where((policy) {
      final status = policy['status']?.toString().toLowerCase();
      return status == 'active' || status == 'approved';
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(25.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "My Policies",
            style: GoogleFonts.poppins(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "Manage your insurance policies and applications",
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 30),
          
          if (pendingApplications.isNotEmpty) ...[
            Text(
              "Pending Applications",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.orangeAccent,
              ),
            ),
            const SizedBox(height: 15),
            ...pendingApplications.map((application) => _buildApplicationCard(application)).toList(),
            const SizedBox(height: 25),
          ],
          
          Text(
            "Active Policies",
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.greenAccent,
            ),
          ),
          const SizedBox(height: 15),
          
          if (activePolicies.isEmpty && pendingApplications.isEmpty) 
            _buildNoPoliciesState()
          else if (activePolicies.isEmpty)
            _buildNoActivePoliciesState()
          else 
            ...activePolicies.map((policy) => _buildPolicyCard(policy)).toList(),
        ],
      ),
    );
  }

  Widget _buildNotificationsScreen() {
    // Create a map to store unique notifications by type and ID
    final Map<String, Map<String, dynamic>> uniqueNotifications = {};

    // Process claims rejections
    for (final claim in _userClaims.where((claim) => claim['status']?.toString().toLowerCase() == 'rejected')) {
      final key = 'claim_${claim['id']}';
      uniqueNotifications[key] = {
        'type': 'claim',
        'id': claim['id'],
        'title': 'Claim Rejected',
        'message': claim['rejectionReason']?.toString() ?? 'Your claim was rejected by the admin.',
        'timestamp': claim['processedAt'] ?? claim['updatedAt'],
        'icon': Icons.description,
        'color': Colors.redAccent,
        'originalData': claim,
      };
    }

    // Process application rejections
    for (final app in _userApplications.where((app) => app['status']?.toString().toLowerCase() == 'rejected')) {
      final key = 'application_${app['id']}';
      uniqueNotifications[key] = {
        'type': 'application',
        'id': app['id'],
        'title': 'Application Rejected',
        'message': app['rejectionReason']?.toString() ?? 'Your application was rejected by the admin.',
        'timestamp': app['rejectedAt'] ?? app['updatedAt'],
        'icon': Icons.person,
        'color': Colors.redAccent,
        'originalData': app,
      };
    }

    // Process other notifications
    for (final notification in _userNotifications.where((notification) => 
        notification['type']?.toString().contains('rejected') ?? false)) {
      final key = 'notification_${notification['id']}';
      uniqueNotifications[key] = {
        'type': notification['type'],
        'id': notification['id'],
        'title': notification['title'] ?? 'Notification',
        'message': notification['reason'] ?? notification['message'] ?? 'Your request was rejected.',
        'timestamp': notification['timestamp'],
        'icon': Icons.notifications,
        'color': Colors.redAccent,
        'originalData': notification,
      };
    }

    // Convert to list and sort by timestamp
    final allNotifications = uniqueNotifications.values.toList()
      ..sort((a, b) => (b['timestamp'] ?? 0).compareTo(a['timestamp'] ?? 0));

    return Padding(
      padding: const EdgeInsets.all(25.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Notifications",
            style: GoogleFonts.poppins(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "Notifications and updates",
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 30),
          
          if (allNotifications.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                children: [
                  Icon(Icons.notifications_none, color: Colors.white54, size: 40),
                  const SizedBox(height: 10),
                  Text(
                    "No Notifications",
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "You're all caught up! No notifications at the moment.",
                    style: GoogleFonts.poppins(
                      color: Colors.white54,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            Column(
              children: allNotifications.map((notification) => _buildRejectionNotificationCard(
                notification['title'] as String,
                notification['message'] as String,
                notification['icon'] as IconData,
                notification['color'] as Color,
                _formatTimestamp(notification['timestamp']),
                notification['type'] as String,
                notification['id'] as String,
                notification['originalData'] as Map<String, dynamic>,
              )).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildRejectionNotificationCard(String title, String message, IconData icon, Color color, String time, String type, String id, Map<String, dynamic> originalData) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.2), Colors.white.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      message,
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.access_time, color: Colors.white54, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          time,
                          style: GoogleFonts.poppins(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    onTap: () => _reapplyForQuote(originalData),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.blueAccent.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.refresh, color: Colors.blueAccent, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            "Reapply",
                            style: GoogleFonts.poppins(
                              color: Colors.blueAccent,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  onTap: () => _deleteNotification(type, id),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                    ),
                    child: Icon(Icons.delete, color: Colors.redAccent, size: 20),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

void _reapplyForQuote(Map<String, dynamic> originalData) {
  final quoteData = _safeCastMap(originalData['quoteData']);
  
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => ApplyInsuranceScreen(
        initialQuoteData: quoteData,
      ),
    ),
  );
}

  void _deleteNotification(String type, String id) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Show confirmation dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color.fromARGB(255, 16, 52, 90),
          title: Text(
            "Delete Notification",
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          content: Text(
            "Are you sure you want to delete this notification?",
            style: GoogleFonts.poppins(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "Cancel",
                style: GoogleFonts.poppins(color: Colors.white70),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                
                // Delete from appropriate collection
                if (type == 'claim') {
                  await _claimsRef.child(id).remove();
                } else if (type == 'application') {
                  await _applicationsRef.child(id).remove();
                } else {
                  await _notificationsRef.child(id).remove();
                }
                
                _showSuccessSnackbar('Notification deleted successfully');
              },
              child: Text(
                "Delete",
                style: GoogleFonts.poppins(color: Colors.redAccent),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      _showErrorSnackbar('Failed to delete notification: ${e.toString()}');
    }
  }

  Widget _buildProfileScreen() {
    final user = FirebaseAuth.instance.currentUser;
    
    return Padding(
      padding: const EdgeInsets.all(25.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "My Profile",
            style: GoogleFonts.poppins(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "Manage your personal information",
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 30),
          
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.1),
                  Colors.white.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Colors.blueAccent, Colors.lightBlue],
                    ),
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 20),
                
                _buildProfileInfoItem("Full Name", "${_userData['firstName'] ?? ''} ${_userData['lastName'] ?? ''}".trim()),
                _buildProfileInfoItem("Email", user?.email ?? "Not provided"),
                _buildProfileInfoItem("Phone", _userData['phoneNumber']?.toString() ?? "Not provided"),
                _buildProfileInfoItem("Member Since", _formatDate(_userData['createdAt'])),
                _buildProfileInfoItem("User ID", user?.uid.substring(0, 8) ?? "N/A"),
              ],
            ),
          ),
          
          const SizedBox(height: 25),
          
          Text(
            "Account Actions",
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 15),
          
          _buildProfileActionCard(
            "Update Personal Information",
            "Edit your name, phone number, and contact details",
            Icons.edit,
            Colors.blueAccent,
            () => _updatePersonalInfo(),
          ),
          const SizedBox(height: 12),
          _buildProfileActionCard(
            "Reset Password",
            "Send password reset email",
            Icons.lock,
            Colors.greenAccent,
            () => _handleResetPassword(),
          ),
        ],
      ),
    );
  }

  void _updatePersonalInfo() {
    final TextEditingController firstNameController = TextEditingController(text: _userData['firstName']?.toString() ?? '');
    final TextEditingController lastNameController = TextEditingController(text: _userData['lastName']?.toString() ?? '');
    final TextEditingController phoneController = TextEditingController(text: _userData['phoneNumber']?.toString() ?? '');
    final TextEditingController emailController = TextEditingController(text: FirebaseAuth.instance.currentUser?.email ?? '');

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: const Color.fromARGB(255, 16, 52, 90),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: Colors.white.withOpacity(0.2)),
            ),
            title: Row(
              children: [
                const Icon(Icons.person, color: Colors.blueAccent),
                const SizedBox(width: 10),
                Text(
                  "Update Personal Information",
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildProfileTextField(
                    "First Name",
                    firstNameController,
                    Icons.person_outline,
                    TextInputType.name,
                  ),
                  const SizedBox(height: 16),
                  _buildProfileTextField(
                    "Last Name",
                    lastNameController,
                    Icons.person_outline,
                    TextInputType.name,
                  ),
                  const SizedBox(height: 16),
                  _buildProfileTextField(
                    "Phone Number",
                    phoneController,
                    Icons.phone,
                    TextInputType.phone,
                  ),
                  const SizedBox(height: 16),
                  _buildProfileTextField(
                    "Email",
                    emailController,
                    Icons.email,
                    TextInputType.emailAddress,
                    enabled: false,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Note: Email cannot be changed directly. Contact support for email changes.",
                    style: GoogleFonts.poppins(
                      color: Colors.orangeAccent,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
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
                  if (firstNameController.text.isEmpty || lastNameController.text.isEmpty) {
                    _showErrorDialog('Please fill in all required fields');
                    return;
                  }

                  setDialogState(() {});

                  try {
                    await _updateUserProfile(
                      firstName: firstNameController.text,
                      lastName: lastNameController.text,
                      phoneNumber: phoneController.text,
                    );
                    
                    if (mounted) {
                      Navigator.pop(context);
                      _showSuccessDialog('Profile updated successfully!');
                    }
                  } catch (e) {
                    if (mounted) {
                      _showErrorDialog('Failed to update profile: ${e.toString()}');
                    }
                  }
                },
                style: TextButton.styleFrom(
                  backgroundColor: Colors.blueAccent.withOpacity(0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Update',
                  style: GoogleFonts.poppins(
                    color: Colors.blueAccent,
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

  Widget _buildProfileTextField(String label, TextEditingController controller, IconData icon, TextInputType keyboardType, {bool enabled = true}) {
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
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: TextField(
            controller: controller,
            enabled: enabled,
            keyboardType: keyboardType,
            style: GoogleFonts.poppins(color: Colors.white),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: Colors.white54, size: 20),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              hintStyle: GoogleFonts.poppins(color: Colors.white54),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _updateUserProfile({
    required String firstName,
    required String lastName,
    required String phoneNumber,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final updates = {
      'firstName': firstName,
      'lastName': lastName,
      'phoneNumber': phoneNumber,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    };

    await _usersRef.child(user.uid).update(updates);
    
    if (mounted) {
      setState(() {
        _userData = {
          ..._userData,
          ...updates,
        };
      });
    }
  }

  void _handleResetPassword() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) {
      _showErrorDialog('No email associated with this account.');
      return;
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color.fromARGB(255, 16, 52, 90),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withOpacity(0.2)),
        ),
        title: Text(
          'Reset Password',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'We will send a password reset link to ${user.email}',
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
              FirebaseAuth.instance.sendPasswordResetEmail(email: user.email!).then((_) {
                _showSuccessDialog('Password reset email sent. Please check your inbox.');
              }).catchError((error) {
                _showErrorDialog('Failed to send reset email: ${error.toString()}');
              });
            },
            style: TextButton.styleFrom(
              backgroundColor: Colors.blueAccent.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Send',
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

  void _showInsuranceGuide(String title, List<String> content) {
    showDialog(
      context: context,
      builder: (context) => InsuranceGuideDialog(
        title: title,
        content: content,
      ),
    );
  }

  Widget _buildKnowledgeHub() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Insurance Guide", style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w600, color: Colors.white)),
        const SizedBox(height: 15),
        SizedBox(
          height: 150,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildKnowledgeCard(
                "Get Started Guide", 
                "Step-by-step process to get insured.", 
                Icons.play_arrow, 
                "5 min read",
                () => _showInsuranceGuide(
                  "Get Started Guide",
                  [
                    "Welcome to AutoSure Insurance! Getting insured is a simple 6-step process:",
                    "1. View Plans: Explore our range of insurance plans tailored to your needs",
                    "2. Get a Quote: Provide basic information about yourself, vehicle, driving history and place of residence",
                    "3. Apply Online: Fill out the application form with personal and vehicle details",
                    "4. Choose Coverage: Select from our comprehensive, third-party, or smart plan policies",
                    "5. Submit Documents: Upload required documents like driver's license and vehicle registration",
                    "6. Submit Application: Review and submit your application for processing",
                  ]
                )
              ),
              _buildKnowledgeCard(
                "Claim Process", 
                "Guide on how to submit and track claims.", 
                Icons.description, 
                "3 min read",
                () => _showInsuranceGuide(
                  "Claim Process Guide",
                  [
                    "Filing a claim with AutoSure is straightforward:",
                    "Immediate Steps After an Incident:",
                    "- Ensure everyone's safety first",
                    "- Contact emergency services if needed",
                    "- Exchange information with other parties",
                    "- Take photos of the scene and damage",
                    "Claim Submission Process:",
                    "1. Log into your AutoSure account",
                    "2. Navigate to the Claims section",
                    "3. Fill out the claim form with incident details",
                    "4. Upload supporting documents and photos",
                    "5. Submit and receive your claim reference number",
                  ]
                )
              ),
              _buildKnowledgeCard(
                "Policy Renewal", 
                "Seamless renewal process guide.", 
                Icons.autorenew, 
                "2 min read",
                () => _showInsuranceGuide(
                  "Policy Renewal Guide",
                  [
                    "Keep your coverage uninterrupted with our easy renewal process:",
                    "Renewal Timeline:",
                    "- You'll receive renewal notices 30 days before expiry",
                    "- Early renewal is available 45 days before expiry",
                    "- Grace period: 15 days after expiry date",
                    "Renewal Process:",
                    "1. Review your current policy details",
                    "2. Update any personal or vehicle information if needed",
                    "3. Choose your coverage options and make adjustments",
                    "4. Submit the renewal application",
                  ]
                )
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildKnowledgeCard(String title, String subtitle, IconData icon, String duration, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 280,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [Colors.white.withOpacity(0.1), Colors.white.withOpacity(0.05)]),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                Icon(icon, color: Colors.blueAccent, size: 20),
                const Spacer(),
                Text(duration, style: GoogleFonts.poppins(color: Colors.white54, fontSize: 10)),
              ]),
              const SizedBox(height: 8),
              Text(title, style: GoogleFonts.poppins(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Expanded(
                child: Text(
                  subtitle, 
                  style: GoogleFonts.poppins(color: Colors.white70, fontSize: 11), 
                  maxLines: 3, 
                  overflow: TextOverflow.ellipsis
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServicesGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Quick Services", style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w600, color: Colors.white)),
        const SizedBox(height: 15),
        Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildServiceRectangularItem("View Plans", Icons.auto_awesome, Colors.purpleAccent, 
                    () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PlansScreen()))
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildServiceRectangularItem("Get Quote", Icons.request_quote, Colors.blueAccent, 
                    () => Navigator.push(context, MaterialPageRoute(builder: (context) => const GetQuoteScreen()))
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildServiceRectangularItem("Apply Now", Icons.car_rental, Colors.greenAccent, 
                    () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ApplyInsuranceScreen()))
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildServiceRectangularItem("Submit Claim", Icons.description, Colors.orangeAccent, 
                    () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ClaimsScreen()))
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildServiceRectangularItem(String title, IconData icon, Color color, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 100,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withOpacity(0.3), color.withOpacity(0.1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 24),
                  const Spacer(),
                  Icon(Icons.arrow_forward_ios_rounded, color: color.withOpacity(0.7), size: 16),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: GoogleFonts.poppins(
                  color: Colors.white, 
                  fontSize: 16,
                  fontWeight: FontWeight.w600
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildApplicationCard(Map<String, dynamic> application) {
    final quoteData = _safeCastMap(application['quoteData']);
    final status = application['status']?.toString() ?? 'Submitted';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orangeAccent.withOpacity(0.2), Colors.white.withOpacity(0.05)]
        ),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.orangeAccent.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "APP-${application['id']?.toString().substring(0, 8) ?? 'APPLICATION'}",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orangeAccent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: GoogleFonts.poppins(
                    color: Colors.orangeAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          
          if (quoteData.isNotEmpty) ...[
            Text(
              "Vehicle: ${quoteData['brand']} ${quoteData['model']} (${quoteData['year']})",
              style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14),
            ),
            Text(
              "Cover: ${quoteData['coverageType'] ?? 'Comprehensive'}",
              style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14),
            ),
          ],
          
          const SizedBox(height: 15),
          
          Row(
            children: [
              Icon(Icons.access_time, color: Colors.orangeAccent, size: 14),
              const SizedBox(width: 6),
              Text(
                "Submitted: ${_formatApplicationDate(application['submittedAt'])}",
                style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
          
          const SizedBox(height: 15),
          
          Row(
            children: [
              _buildApplicationActionButton(
                "View Details", 
                Icons.visibility, 
                Colors.blueAccent, 
                () => _viewApplicationDetails(application)
              ),
              const SizedBox(width: 10),
              _buildApplicationActionButton(
                "Track Status", 
                Icons.track_changes, 
                Colors.orangeAccent, 
                () => _trackApplication(application)
              ),
            ],
          ),
        ],
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

  Widget _buildApplicationActionButton(String text, IconData icon, Color color, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 6),
              Text(
                text,
                style: GoogleFonts.poppins(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatApplicationDate(dynamic timestamp) {
    if (timestamp == null) return 'Recently';
    try {
      if (timestamp is int) {
        final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
        return '${date.day}/${date.month}/${date.year}';
      }
      return timestamp.toString();
    } catch (e) {
      return 'Recently';
    }
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    try {
      if (timestamp is int) {
        final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
        return '${date.year}';
      }
      return timestamp.toString();
    } catch (e) {
      return 'N/A';
    }
  }

  Widget _buildNoActivePoliciesState() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Icon(Icons.pending_actions, color: Colors.orangeAccent, size: 40),
          const SizedBox(height: 10),
          Text(
            "Application Under Review",
            style: GoogleFonts.poppins(
              color: Colors.orangeAccent,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Your application is being processed.",
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

  void _viewApplicationDetails(Map<String, dynamic> application) {
    final quoteData = _safeCastMap(application['quoteData']);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color.fromARGB(255, 16, 52, 90),
        title: Text(
          "Application Details",
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildApplicationDetailItem("Status", application['status']?.toString() ?? 'Submitted'),
              _buildApplicationDetailItem("Application ID", "APP-${application['id']?.toString().substring(0, 8)}"),
              _buildApplicationDetailItem("Submitted", _formatApplicationDate(application['submittedAt'])),
              
              if (quoteData.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  "Vehicle Information:",
                  style: GoogleFonts.poppins(
                    color: Colors.blueAccent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                _buildApplicationDetailItem("Vehicle", "${quoteData['brand']} ${quoteData['model']}"),
                _buildApplicationDetailItem("Year", quoteData['year']?.toString() ?? 'N/A'),
                _buildApplicationDetailItem("Coverage", quoteData['coverageType']?.toString() ?? 'Comprehensive'),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "CLOSE",
              style: GoogleFonts.poppins(color: Colors.blueAccent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApplicationDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            "$label: ",
            style: GoogleFonts.poppins(
              color: Colors.white70,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(color: Colors.white),
          ),
        ],
      ),
    );
  }

  void _trackApplication(Map<String, dynamic> application) {
    final status = application['status']?.toString() ?? 'submitted';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color.fromARGB(255, 16, 52, 90),
        title: Text(
          "Application Status",
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatusStep("Submitted", true, Icons.check_circle, Colors.greenAccent),
            _buildStatusStep("Under Review", status == 'review', Icons.hourglass_top, Colors.orangeAccent),
            _buildStatusStep("Approved", status == 'approved', Icons.verified, Colors.blueAccent),
            _buildStatusStep("Policy Issued", status == 'active', Icons.policy, Colors.greenAccent),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("OK", style: GoogleFonts.poppins(color: Colors.blueAccent)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusStep(String label, bool isCompleted, IconData icon, Color color) {
    return ListTile(
      leading: Icon(
        isCompleted ? icon : Icons.radio_button_unchecked,
        color: isCompleted ? color : Colors.white30,
      ),
      title: Text(
        label,
        style: GoogleFonts.poppins(
          color: isCompleted ? color : Colors.white70,
          fontWeight: isCompleted ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildPolicyCard(Map<String, dynamic> policy) {
    final isActive = policy['status'] == 'Active' || policy['status'] == 'approved';
    final isExpired = _isPolicyExpired(policy);
    final paymentPending = policy['paymentStatus'] == 'Pending';
    final policyType = policy['policyType'] ?? policy['quoteData']?['coverageType'] ?? 'Comprehensive';
    final premiumAmount = policy['premiumAmount'] ?? policy['quoteData']?['premiums']?[policyType.toLowerCase()] ?? 0.00;
    final vehicleModel = policy['vehicleModel'] ?? '${policy['quoteData']?['brand']} ${policy['quoteData']?['model']}';
    final vehicleYear = policy['vehicleYear'] ?? policy['quoteData']?['year'];

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [isActive ? Colors.greenAccent.withOpacity(0.2) : Colors.orangeAccent.withOpacity(0.2), Colors.white.withOpacity(0.05)]),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: isActive ? Colors.greenAccent.withOpacity(0.3) : Colors.orangeAccent.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(policy['policyNumber']?.toString() ?? 'POL-${policy['id']}', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: _getPolicyStatusColor(policy['status']?.toString()).withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
              child: Text(
                _getPolicyStatusText(policy['status']?.toString()),
                style: GoogleFonts.poppins(color: _getPolicyStatusColor(policy['status']?.toString()), fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ]),
          const SizedBox(height: 10),
          Text("Vehicle: $vehicleModel ($vehicleYear)", style: GoogleFonts.poppins(color: Colors.white70)),
          Text("Premium: R${premiumAmount is double ? premiumAmount.toStringAsFixed(2) : premiumAmount.toString()}", style: GoogleFonts.poppins(color: Colors.white70)),
          Text("Coverage: $policyType", style: GoogleFonts.poppins(color: Colors.white70)),
          
          const SizedBox(height: 15),
          
          Row(children: [
            if (paymentPending) ...[
              _buildPolicyActionButton("Pay Now", Icons.payment, Colors.greenAccent, () => _makePayment(policy)),
              const SizedBox(width: 10),
            ],
            if (isActive && !isExpired) ...[
              _buildPolicyActionButton("View Details", Icons.visibility, Colors.blueAccent, () => _viewPolicyDetails(policy)),
              const SizedBox(width: 10),
              _buildPolicyActionButton("Cancel", Icons.cancel, Colors.redAccent, () => _cancelPolicy(policy)),
            ],
            if (isExpired) ...[
              _buildPolicyActionButton("Renew", Icons.autorenew, Colors.greenAccent, () => _renewPolicy(policy)),
              const SizedBox(width: 10),
              _buildPolicyActionButton("View Details", Icons.visibility, Colors.blueAccent, () => _viewPolicyDetails(policy)),
            ],
            if (policy['status'] == 'pending') 
              _buildPolicyActionButton("Track", Icons.track_changes, Colors.orangeAccent, () => _trackPolicy(policy)),
          ]),
        ],
      ),
    );
  }

  String _getPolicyStatusText(String? status) {
    switch (status?.toLowerCase()) {
      case 'active': return 'ACTIVE';
      case 'approved': return 'ACTIVE';
      case 'pending': return 'PENDING';
      case 'cancelled': return 'CANCELLED';
      case 'expired': return 'EXPIRED';
      case 'submitted': return 'UNDER REVIEW';
      default: return 'UNKNOWN';
    }
  }

  String _formatPolicyDate(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    try {
      if (timestamp is int) {
        final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
        return '${date.day}/${date.month}/${date.year}';
      }
      return timestamp.toString();
    } catch (e) {
      return 'N/A';
    }
  }

  bool _isPolicyExpired(Map<String, dynamic> policy) {
    final endDate = policy['endDate'];
    if (endDate == null) return false;
    try {
      return DateTime.fromMillisecondsSinceEpoch(int.tryParse(endDate.toString()) ?? 0).isBefore(DateTime.now());
    } catch (e) {
      return false;
    }
  }

  Widget _buildPolicyActionButton(String text, IconData icon, Color color, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Text(text, style: GoogleFonts.poppins(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
          ]),
        ),
      ),
    );
  }

  Color _getPolicyStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'active': return Colors.greenAccent;
      case 'approved': return Colors.greenAccent;
      case 'pending': return Colors.orangeAccent;
      case 'cancelled': return Colors.redAccent;
      case 'expired': return Colors.yellowAccent;
      default: return Colors.grey;
    }
  }

  void _trackPolicy(Map<String, dynamic> policy) {
    final status = policy['status']?.toString() ?? 'pending';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color.fromARGB(255, 16, 52, 90),
        title: Text(
          "Policy Status",
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildPolicyStatusStep("Application Submitted", status != 'pending', Icons.check_circle, Colors.greenAccent),
            _buildPolicyStatusStep("Under Review", status == 'review' || status == 'approved', Icons.hourglass_top, Colors.orangeAccent),
            _buildPolicyStatusStep("Approved", status == 'approved' || status == 'active', Icons.verified, Colors.blueAccent),
            _buildPolicyStatusStep("Policy Active", status == 'active', Icons.policy, Colors.greenAccent),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("OK", style: GoogleFonts.poppins(color: Colors.blueAccent)),
          ),
        ],
      ),
    );
  }

  Widget _buildPolicyStatusStep(String label, bool isCompleted, IconData icon, Color color) {
    return ListTile(
      leading: Icon(
        isCompleted ? icon : Icons.radio_button_unchecked,
        color: isCompleted ? color : Colors.white30,
        size: 20,
      ),
      title: Text(
        label,
        style: GoogleFonts.poppins(
          color: isCompleted ? color : Colors.white70,
          fontWeight: isCompleted ? FontWeight.w600 : FontWeight.normal,
          fontSize: 14,
        ),
      ),
    );
  }

  void _cancelPolicy(Map<String, dynamic> policy) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color.fromARGB(255, 16, 52, 90),
        title: Text("Cancel Policy", style: GoogleFonts.poppins(color: Colors.white)),
        content: Text(
          "Are you sure you want to cancel policy ${policy['policyNumber']}?",
          style: GoogleFonts.poppins(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("NO", style: GoogleFonts.poppins(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () {
              _performCancelPolicy(policy);
              Navigator.pop(context);
            },
            child: Text("YES, CANCEL", style: GoogleFonts.poppins(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  void _performCancelPolicy(Map<String, dynamic> policy) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await _policiesRef.child(policy['id']).update({
        'status': 'cancelled',
        'cancelledAt': DateTime.now().millisecondsSinceEpoch,
      });

      _showSuccessSnackbar('Policy cancelled successfully');
    } catch (e) {
      _showErrorSnackbar('Failed to cancel policy: ${e.toString()}');
    }
  }

  void _renewPolicy(Map<String, dynamic> policy) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color.fromARGB(255, 16, 52, 90),
        title: Text("Renew Policy", style: GoogleFonts.poppins(color: Colors.white)),
        content: Text(
          "Would you like to renew policy ${policy['policyNumber']}?",
          style: GoogleFonts.poppins(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("NOT NOW", style: GoogleFonts.poppins(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () {
              _performRenewPolicy(policy);
              Navigator.pop(context);
            },
            child: Text("RENEW", style: GoogleFonts.poppins(color: Colors.greenAccent)),
          ),
        ],
      ),
    );
  }

  void _performRenewPolicy(Map<String, dynamic> policy) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final now = DateTime.now();
      final newEndDate = now.add(const Duration(days: 365));

      await _policiesRef.child(policy['id']).update({
        'status': 'active',
        'endDate': newEndDate.millisecondsSinceEpoch,
        'renewedAt': now.millisecondsSinceEpoch,
      });

      _showSuccessSnackbar('Policy renewed successfully');
    } catch (e) {
      _showErrorSnackbar('Failed to renew policy: ${e.toString()}');
    }
  }

  void _viewPolicyDetails(Map<String, dynamic> policy) {
    final quoteData = _safeCastMap(policy['quoteData']);
    final policyType = policy['policyType'] ?? quoteData['coverageType'] ?? 'Comprehensive';
    final premiumAmount = policy['premiumAmount'] ?? quoteData['premiums']?[policyType.toLowerCase()] ?? 0.00;
    final vehicleModel = policy['vehicleModel'] ?? '${quoteData['brand']} ${quoteData['model']}';
    final vehicleYear = policy['vehicleYear'] ?? quoteData['year'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color.fromARGB(255, 16, 52, 90),
        title: Text("Policy Details", style: GoogleFonts.poppins(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildPolicyDetailItem("Policy Number", policy['policyNumber']?.toString() ?? 'N/A'),
              _buildPolicyDetailItem("Status", _getPolicyStatusText(policy['status']?.toString())),
              _buildPolicyDetailItem("Vehicle", "$vehicleModel ($vehicleYear)"),
              _buildPolicyDetailItem("Coverage", policyType),
              _buildPolicyDetailItem("Premium", "R${premiumAmount is double ? premiumAmount.toStringAsFixed(2) : premiumAmount.toString()}"),
              if (policy['startDate'] != null) 
                _buildPolicyDetailItem("Start Date", _formatPolicyDate(policy['startDate'])),
              if (policy['endDate'] != null)
                _buildPolicyDetailItem("End Date", _formatPolicyDate(policy['endDate'])),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("CLOSE", style: GoogleFonts.poppins(color: Colors.blueAccent)),
          ),
        ],
      ),
    );
  }

  Widget _buildPolicyDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$label: ",
            style: GoogleFonts.poppins(
              color: Colors.white70,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  void _makePayment(Map<String, dynamic> policy) {
    _showSuccessDialog("Payment feature is coming soon!");
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

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color.fromARGB(255, 16, 52, 90),
        title: Text(
          'Success',
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        content: Text(
          message,
          style: GoogleFonts.poppins(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("OK", style: GoogleFonts.poppins(color: Colors.blueAccent)),
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
        title: Text(
          'Error',
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        content: Text(
          message,
          style: GoogleFonts.poppins(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("OK", style: GoogleFonts.poppins(color: Colors.blueAccent)),
          ),
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
            gradient: LinearGradient(colors: [Colors.white.withOpacity(0.15), Colors.white.withOpacity(0.08)]),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Hi there!", style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.w700, color: Colors.white)),
              const SizedBox(height: 5),
              Text("Welcome back, ${widget.username}", style: GoogleFonts.poppins(fontSize: 16, color: Colors.white70)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInsuranceOverview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Insurance Overview", style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w600, color: Colors.white)),
        const SizedBox(height: 15),
        Column(
          children: [
            _buildOverviewItem("Active Policy", _userStats['activePolicy']!, Icons.shield, Colors.greenAccent, _getPolicySubtitle(_userStats['activePolicy']!)),
            const SizedBox(height: 12),
            _buildOverviewItem("Next Renewal", _userStats['nextRenewal']!, Icons.calendar_month, Colors.orangeAccent, _getRenewalSubtitle(_userStats['nextRenewal']!)),
            const SizedBox(height: 12),
            _buildOverviewItem("Total Claims", _userStats['totalClaims']!, Icons.description, Colors.blueAccent, "${_getApprovedClaimsCount()} Approved"),
          ],
        ),
      ],
    );
  }

  String _getPolicySubtitle(String policy) {
    return policy == 'No Policy' ? 'Apply Now' : 'Active Coverage';
  }

  String _getRenewalSubtitle(String renewal) {
    if (renewal == 'N/A') return 'No Active Policy';
    if (renewal == 'Expired') return 'Renew Required';
    return 'Days remaining';
  }

  int _getApprovedClaimsCount() {
    return _userClaims.where((claim) => claim['status'] == 'Approved').length;
  }

  Widget _buildOverviewItem(String title, String value, IconData icon, Color color, String subtitle) {
    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [color.withOpacity(0.2), color.withOpacity(0.05)], begin: Alignment.centerLeft, end: Alignment.centerRight),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withOpacity(0.2), shape: BoxShape.circle), child: Icon(icon, color: color, size: 22)),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(value, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                      Text(title, style: GoogleFonts.poppins(fontSize: 14, color: Colors.white70)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                  child: Text(subtitle, style: GoogleFonts.poppins(fontSize: 10, color: Colors.white70)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNoPoliciesState() {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.white.withOpacity(0.1), Colors.white.withOpacity(0.05)]),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Icon(Icons.policy, color: Colors.white54, size: 50),
          const SizedBox(height: 15),
          Text("No Active Policies", style: GoogleFonts.poppins(fontSize: 18, color: Colors.white, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ApplyInsuranceScreen())),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [Colors.greenAccent, Colors.green]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text("Apply for Insurance", style: GoogleFonts.poppins(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Recent Activity", style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w600, color: Colors.white)),
        const SizedBox(height: 15),
        _userClaims.isEmpty && _userPolicies.isEmpty
            ? _buildNoActivityState()
            : Column(children: _buildActivityItems()),
      ],
    );
  }

  Widget _buildNoActivityState() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(children: [
        Icon(Icons.history, color: Colors.white54, size: 40),
        const SizedBox(height: 10),
        Text("No Recent Activity", style: GoogleFonts.poppins(color: Colors.white70, fontSize: 16)),
      ]),
    );
  }

  List<Widget> _buildActivityItems() {
    final items = <Widget>[];
    
    final recentPolicies = _userPolicies.take(2);
    for (final policy in recentPolicies) {
      items.add(_buildActivityItem(
        "Policy ${policy['status'] == 'Active' ? 'Activated' : 'Created'}",
        "Policy ${policy['policyNumber']} for ${policy['vehicleModel']}",
        _formatTimestamp(policy['createdAt']),
        policy['status'] == 'Active' ? Icons.check_circle : Icons.policy,
        policy['status'] == 'Active' ? Colors.green : Colors.blue,
      ));
    }
    
    final recentClaims = _userClaims.take(2);
    for (final claim in recentClaims) {
      items.add(_buildActivityItem(
        "Claim ${claim['status']}",
        "Claim #${claim['id']?.toString().substring(0, 8)}",
        _formatTimestamp(claim['submittedAt']),
        Icons.description,
        _getClaimStatusColor(claim['status']?.toString()),
      ));
    }
    
    return items;
  }

  Color _getClaimStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'approved': return Colors.green;
      case 'pending': return Colors.orange;
      case 'rejected': return Colors.red;
      default: return Colors.blue;
    }
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Recently';
    try {
      if (timestamp is int) {
        final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
        final now = DateTime.now();
        final difference = now.difference(date);
        
        if (difference.inDays > 0) return '${difference.inDays} days ago';
        if (difference.inHours > 0) return '${difference.inHours} hours ago';
        if (difference.inMinutes > 0) return '${difference.inMinutes} minutes ago';
        return 'Just now';
      }
      return timestamp.toString();
    } catch (e) {
      return 'Recently';
    }
  }

  Widget _buildActivityItem(String title, String subtitle, String time, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: [
        Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.2), shape: BoxShape.circle), child: Icon(icon, color: color, size: 18)),
        const SizedBox(width: 15),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: GoogleFonts.poppins(color: Colors.white, fontSize: 14)),
          Text(subtitle, style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12)),
        ])),
        Text(time, style: GoogleFonts.poppins(color: Colors.white54, fontSize: 11)),
      ]),
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
                child: _QuantumParticle(size: 2 + (i % 3).toDouble(), delay: i * 0.5, controller: _particleController),
              ),
          ],
        );
      },
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
                    Text("AutoSure", style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 1.1)),
                    Text(_getHeaderSubtitle(), style: GoogleFonts.poppins(fontSize: 12, color: Colors.white70)),
                  ],
                ),
                Row(
                  children: [
                    if (_isAdmin) ...[
                      _buildAdminButton(),
                      const SizedBox(width: 8),
                    ],
                    _buildLogoutButton(),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getHeaderSubtitle() {
    switch (_selectedIndex) {
      case 0: return "Premium Protection";
      case 1: return "Policy Management";
      case 2: return "Notifications";
      case 3: return "Profile Settings";
      default: return "Premium Protection";
    }
  }

  Widget _buildAdminButton() {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: _navigateToAdmin,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [Colors.purpleAccent, Colors.purple]),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            children: [
              const Icon(Icons.admin_panel_settings, color: Colors.white, size: 14),
              const SizedBox(width: 4),
              Text("Admin", style: GoogleFonts.poppins(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: _logout,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [Colors.redAccent, Colors.red]),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            children: [
              const Icon(Icons.logout, color: Colors.white, size: 14),
              const SizedBox(width: 4),
              Text("Logout", style: GoogleFonts.poppins(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileInfoItem(String label, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileActionCard(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withOpacity(0.2), color.withOpacity(0.05)],
            ),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, color: color, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMinimalNavigationBar() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 10, left: 20, right: 20),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 15, spreadRadius: 1)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(Icons.home_rounded, "Home", 0),
          _buildNavItem(Icons.policy_rounded, "Policies", 1),
          _buildNavItem(Icons.notifications_rounded, "Notifications", 2),
          _buildNavItem(Icons.person_rounded, "Profile", 3),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: () => _onItemTapped(index),
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, color: isSelected ? Colors.blueAccent : Colors.white70, size: 22),
            const SizedBox(height: 2),
            Text(label, style: GoogleFonts.poppins(color: isSelected ? Colors.blueAccent : Colors.white70, fontSize: 10, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal)),
          ]),
        ),
      ),
    );
  }
}

class InsuranceGuideDialog extends StatefulWidget {
  final String title;
  final List<String> content;

  const InsuranceGuideDialog({super.key, required this.title, required this.content});

  @override
  State<InsuranceGuideDialog> createState() => _InsuranceGuideDialogState();
}

class _InsuranceGuideDialogState extends State<InsuranceGuideDialog> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _startTextAnimation();
  }

  void _startTextAnimation() {
    _animationController.forward().then((_) {
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted && _currentIndex < widget.content.length - 1) {
          setState(() {
            _currentIndex++;
            _animationController.reset();
            _animationController.forward();
          });
        }
      });
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color.fromARGB(255, 16, 52, 90),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(25),
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.title,
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white70),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (int i = 0; i <= _currentIndex; i++)
                      AnimatedOpacity(
                        opacity: i == _currentIndex ? 1.0 : 0.7,
                        duration: const Duration(milliseconds: 500),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            widget.content[i],
                            style: GoogleFonts.poppins(
                              color: i == _currentIndex ? Colors.white : Colors.white70,
                              fontSize: 14,
                              fontWeight: i == _currentIndex ? FontWeight.w500 : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    if (_currentIndex < widget.content.length - 1)
                      Padding(
                        padding: const EdgeInsets.only(top: 20),
                        child: Row(
                          children: [
                            Icon(Icons.arrow_downward, color: Colors.blueAccent, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              "More information loading...",
                              style: GoogleFonts.poppins(
                                color: Colors.blueAccent,
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Step ${_currentIndex + 1} of ${widget.content.length}",
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
                if (_currentIndex < widget.content.length - 1)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _currentIndex++;
                        _animationController.reset();
                        _animationController.forward();
                      });
                    },
                    child: Text(
                      "Next Step",
                      style: GoogleFonts.poppins(
                        color: Colors.blueAccent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuantumParticle extends StatelessWidget {
  final double size;
  final double delay;
  final AnimationController controller;

  const _QuantumParticle({required this.size, required this.delay, required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final animationValue = (controller.value + delay) % 1.0;
        return Opacity(
          opacity: 0.2 + animationValue * 0.3,
          child: Transform.translate(
            offset: Offset((animationValue * 2 - 1) * 40, (animationValue * 3 - 1.5) * 25),
            child: Container(
              width: size, height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [Colors.blueAccent.withOpacity(0.6), Colors.lightBlue.withOpacity(0.2)]),
              ),
            ),
          ),
        );
      },
    );
  }
}