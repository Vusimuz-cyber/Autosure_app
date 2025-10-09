import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'login_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> with TickerProviderStateMixin {
  late AnimationController _masterController;
  late AnimationController _gridController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  int _selectedTab = 0;
  final ScrollController _scrollController = ScrollController();
  
  // Firebase Database references
  final DatabaseReference _usersRef = FirebaseDatabase.instance.ref('users');
  final DatabaseReference _policiesRef = FirebaseDatabase.instance.ref('policies');
  final DatabaseReference _claimsRef = FirebaseDatabase.instance.ref('claims');
  final DatabaseReference _applicationsRef = FirebaseDatabase.instance.ref('insurance_applications');
  
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
    'averageRiskScore': 0,
    'satisfactionRate': 0,
  };

  @override
  void initState() {
    super.initState();
    
    _masterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    
    _gridController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _masterController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _masterController,
      curve: Curves.easeOutBack,
    ));
    
    _masterController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _gridController.forward();
    });

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

  void _loadUsers() {
    _usersRef.onValue.listen((event) {
      final data = event.snapshot.value;
      if (data != null && data is Map) {
        setState(() {
          _users = _convertFirebaseDataToList(data);
        });
      }
    });
  }

  void _loadPolicies() {
    _policiesRef.onValue.listen((event) {
      final data = event.snapshot.value;
      if (data != null && data is Map) {
        setState(() {
          _policies = _convertFirebaseDataToList(data);
        });
      }
    });
  }

  void _loadClaims() {
    _claimsRef.onValue.listen((event) {
      final data = event.snapshot.value;
      if (data != null && data is Map) {
        setState(() {
          _claims = _convertFirebaseDataToList(data);
      });
      }
    });
  }

  void _loadApplications() {
    _applicationsRef.onValue.listen((event) {
      final data = event.snapshot.value;
      if (data != null && data is Map) {
        setState(() {
          _applications = _convertFirebaseDataToList(data);
        });
      }
    });
  }

  void _loadStats() {
    // Calculate stats from live data
    _usersRef.onValue.listen((usersEvent) {
      _policiesRef.onValue.listen((policiesEvent) {
        _claimsRef.onValue.listen((claimsEvent) {
          setState(() {
            final users = usersEvent.snapshot.value as Map? ?? {};
            final policies = policiesEvent.snapshot.value as Map? ?? {};
            final claims = claimsEvent.snapshot.value as Map? ?? {};
            
            _stats = {
              'totalUsers': users.length,
              'activePolicies': policies.values.where((policy) => policy['status'] == 'Active').length,
              'pendingClaims': claims.values.where((claim) => claim['status'] == 'Pending').length,
              'totalRevenue': _calculateTotalRevenue(policies),
              'averageRiskScore': _calculateAverageRiskScore(users),
              'satisfactionRate': _calculateSatisfactionRate(claims),
            };
          });
        });
      });
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

  double _calculateAverageRiskScore(Map users) {
    if (users.isEmpty) return 0;
    double total = 0;
    int count = 0;
    users.forEach((key, value) {
      if (value is Map && value['riskScore'] != null) {
        total += (value['riskScore'] as num).toDouble();
        count++;
      }
    });
    return count > 0 ? total / count : 0;
  }

  double _calculateSatisfactionRate(Map claims) {
    if (claims.isEmpty) return 0;
    final approvedClaims = claims.values.where((claim) => claim['status'] == 'Approved').length;
    final totalProcessedClaims = claims.values.where((claim) => claim['status'] != 'Pending').length;
    return totalProcessedClaims > 0 ? (approvedClaims / totalProcessedClaims) * 100 : 0;
  }

  @override
  void dispose() {
    _masterController.dispose();
    _gridController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleLogout() async {
    try {
      await FirebaseAuth.instance.signOut();
      
      if (mounted) {
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
    } catch (e) {
      print('Error during logout: $e');
      _showErrorDialog('Logout failed. Please try again.');
    }
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
        backgroundColor: const Color.fromARGB(255, 16, 52, 90),
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
  void _approveApplication(String applicationId) {
    _applicationsRef.child(applicationId).update({
      'status': 'Approved',
      'approvedAt': ServerValue.timestamp,
      'approvedBy': FirebaseAuth.instance.currentUser?.uid,
    });
  }

  void _rejectApplication(String applicationId) {
    _applicationsRef.child(applicationId).update({
      'status': 'Rejected',
      'rejectedAt': ServerValue.timestamp,
      'rejectedBy': FirebaseAuth.instance.currentUser?.uid,
    });
  }

  void _updateUserStatus(String userId, String status) {
    _usersRef.child(userId).update({
      'status': status,
      'updatedAt': ServerValue.timestamp,
    });
  }

  void _processClaim(String claimId, String status) {
    _claimsRef.child(claimId).update({
      'status': status,
      'processedAt': ServerValue.timestamp,
      'processedBy': FirebaseAuth.instance.currentUser?.uid,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 10, 20, 35),
      body: Row(
        children: [
          // Sidebar
          _buildSidebar(),
          
          // Main Content
          Expanded(
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                // App Bar
                _buildAppBar(),
                
                // Stats Overview
                _buildStatsOverview(),
                
                // Quick Actions
                _buildQuickActions(),
                
                // Main Content based on selected tab
                _buildMainContent(),
                
                // Bottom spacing
                const SliverToBoxAdapter(
                  child: SizedBox(height: 100),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color.fromARGB(255, 16, 52, 90),
            const Color.fromARGB(255, 8, 26, 45),
          ],
        ),
        border: Border(
          right: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
        ),
      ),
      child: Column(
        children: [
          // Logo and Title
          Container(
            padding: const EdgeInsets.all(30),
            child: Column(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Colors.blueAccent, Colors.lightBlue],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blueAccent.withOpacity(0.5),
                        blurRadius: 15,
                        spreadRadius: 3,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.admin_panel_settings, color: Colors.white, size: 30),
                ),
                const SizedBox(height: 15),
                Text(
                  'Admin Portal',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'AutoSure Management',
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          
          // Navigation Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildNavItem(Icons.dashboard, 'Dashboard', 0),
                _buildNavItem(Icons.people, 'User Management', 1),
                _buildNavItem(Icons.description, 'Applications', 2),
                _buildNavItem(Icons.policy, 'Policies', 3),
                _buildNavItem(Icons.analytics, 'Claims', 4),
                _buildNavItem(Icons.settings, 'System Settings', 5),
              ],
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
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Colors.greenAccent, Colors.green],
                        ),
                      ),
                      child: const Icon(Icons.person, color: Colors.white, size: 20),
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
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _showLogoutConfirmation,
                      icon: Icon(Icons.logout, color: Colors.white70, size: 20),
                      tooltip: 'Logout',
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: _showLogoutConfirmation,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.logout, color: Colors.redAccent, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            'Logout',
                            style: GoogleFonts.poppins(
                              color: Colors.redAccent,
                              fontSize: 14,
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
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        gradient: isSelected
            ? LinearGradient(
                colors: [Colors.blueAccent.withOpacity(0.3), Colors.blueAccent.withOpacity(0.1)],
              )
            : null,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: isSelected ? Colors.blueAccent : Colors.white70, size: 20),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            color: isSelected ? Colors.blueAccent : Colors.white70,
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
        trailing: isSelected ? Icon(Icons.arrow_forward_ios, color: Colors.blueAccent, size: 14) : null,
        onTap: () => setState(() => _selectedTab = index),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  SliverAppBar _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: const Color.fromARGB(255, 16, 52, 90),
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color.fromARGB(255, 16, 52, 90),
                const Color.fromARGB(255, 8, 26, 45),
              ],
            ),
          ),
        ),
        title: SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Text(
              _getTitle(),
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        centerTitle: false,
        titlePadding: const EdgeInsets.only(left: 30, bottom: 16),
      ),
      actions: [
        _buildSearchBar(),
        _buildNotificationButton(),
        _buildQuickActionButton(),
        IconButton(
          onPressed: _showLogoutConfirmation,
          icon: Icon(Icons.logout, color: Colors.white70),
          tooltip: 'Logout',
        ),
        const SizedBox(width: 20),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      width: 300,
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search users, policies, claims...',
          hintStyle: GoogleFonts.poppins(color: Colors.white70),
          prefixIcon: Icon(Icons.search, color: Colors.white70),
          filled: true,
          fillColor: Colors.white.withOpacity(0.1),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20),
        ),
        style: GoogleFonts.poppins(color: Colors.white),
      ),
    );
  }

  Widget _buildNotificationButton() {
    return Stack(
      children: [
        IconButton(
          onPressed: () {},
          icon: Icon(Icons.notifications_none, color: Colors.white70),
        ),
        Positioned(
          right: 8,
          top: 8,
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.redAccent,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionButton() {
    return PopupMenuButton<String>(
      icon: Icon(Icons.add, color: Colors.white70),
      itemBuilder: (context) => [
        PopupMenuItem(value: 'user', child: Text('Add New User')),
        PopupMenuItem(value: 'policy', child: Text('Create Policy')),
        PopupMenuItem(value: 'claim', child: Text('Process Claim')),
        PopupMenuItem(value: 'report', child: Text('Generate Report')),
      ],
    );
  }

  SliverToBoxAdapter _buildStatsOverview() {
    return SliverToBoxAdapter(
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Container(
            padding: const EdgeInsets.all(30),
            child: Wrap(
              spacing: 20,
              runSpacing: 20,
              children: [
                _buildStatCard('Total Users', _stats['totalUsers'].toString(), Icons.people, Colors.blueAccent),
                _buildStatCard('Active Policies', _stats['activePolicies'].toString(), Icons.policy, Colors.greenAccent),
                _buildStatCard('Pending Claims', _stats['pendingClaims'].toString(), Icons.description, Colors.orangeAccent),
                _buildStatCard('Revenue', 'R ${_formatCurrency(_stats['totalRevenue'])}', Icons.attach_money, Colors.purpleAccent),
                _buildStatCard('Risk Score', '${_stats['averageRiskScore'].toStringAsFixed(1)}/10', Icons.security, Colors.redAccent),
                _buildStatCard('Satisfaction', '${_stats['satisfactionRate'].toStringAsFixed(0)}%', Icons.star, Colors.yellowAccent),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.2), color.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 15),
          Text(
            value,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            title,
            style: GoogleFonts.poppins(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  SliverToBoxAdapter _buildQuickActions() {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 15),
            Wrap(
              spacing: 15,
              runSpacing: 15,
              children: [
                _buildActionButton('User Management', Icons.people, Colors.blueAccent),
                _buildActionButton('Applications', Icons.description, Colors.orangeAccent),
                _buildActionButton('Policy Editor', Icons.edit_document, Colors.greenAccent),
                _buildActionButton('Risk Analysis', Icons.analytics, Colors.purpleAccent),
                _buildActionButton('Reports', Icons.bar_chart, Colors.redAccent),
                _buildActionButton('Settings', Icons.settings, Colors.yellowAccent),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String title, IconData icon, Color color) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(15),
        child: Container(
          width: 150,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withOpacity(0.3), color.withOpacity(0.1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 30),
              const SizedBox(height: 10),
              Text(
                title,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  SliverList _buildMainContent() {
    return SliverList(
      delegate: SliverChildListDelegate([
        Container(
          padding: const EdgeInsets.all(30),
          child: _getContentForTab(),
        ),
      ]),
    );
  }

  Widget _getContentForTab() {
    switch (_selectedTab) {
      case 0: return _buildDashboard();
      case 1: return _buildUserManagement();
      case 2: return _buildApplications();
      case 3: return _buildPolicies();
      case 4: return _buildClaims();
      case 5: return _buildSystemSettings();
      default: return _buildDashboard();
    }
  }

  Widget _buildDashboard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Overview Dashboard',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 20),
        
        // Recent Activity
        _buildRecentActivity(),
        const SizedBox(height: 30),
        
        // Performance Metrics
        _buildPerformanceMetrics(),
      ],
    );
  }

  Widget _buildRecentActivity() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white.withOpacity(0.05), Colors.white.withOpacity(0.02)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Activity',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 15),
          _users.isEmpty && _applications.isEmpty
              ? _buildEmptyState('No recent activity', Icons.history)
              : Column(
                  children: _buildActivityItems(),
                ),
        ],
      ),
    );
  }

  List<Widget> _buildActivityItems() {
    final items = <Widget>[];
    
    // Add recent applications
    final recentApplications = _applications.take(3);
    for (final app in recentApplications) {
      items.add(_buildActivityItem(
        'New Application',
        '${app['personalInfo']?['firstName'] ?? 'User'} applied for insurance',
        'Recently',
        Icons.person_add,
        Colors.green,
      ));
    }
    
    // Add recent claims
    final recentClaims = _claims.take(3);
    for (final claim in recentClaims) {
      items.add(_buildActivityItem(
        'Claim Submitted',
        'Claim #${claim['id']} submitted',
        'Recently', 
        Icons.description,
        Colors.orange,
      ));
    }
    
    return items;
  }

  Widget _buildActivityItem(String title, String subtitle, String time, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: GoogleFonts.poppins(
              color: Colors.white54,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceMetrics() {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blueAccent.withOpacity(0.2), Colors.blueAccent.withOpacity(0.05)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Text('Live Performance Metrics', style: GoogleFonts.poppins(color: Colors.white, fontSize: 16)),
                const SizedBox(height: 20),
                _buildMetricsGrid(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricsGrid() {
    return Wrap(
      spacing: 20,
      runSpacing: 20,
      children: [
        _buildMetricItem('New Users Today', _calculateNewUsersToday().toString(), Icons.person_add, Colors.blueAccent),
        _buildMetricItem('Pending Approvals', _applications.where((app) => app['status'] == 'Pending').length.toString(), Icons.pending, Colors.orangeAccent),
        _buildMetricItem('Claims Today', _calculateClaimsToday().toString(), Icons.description, Colors.redAccent),
        _buildMetricItem('Revenue Today', 'R ${_formatCurrency(_calculateRevenueToday())}', Icons.attach_money, Colors.greenAccent),
      ],
    );
  }

  Widget _buildMetricItem(String title, String value, IconData icon, Color color) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            title,
            style: GoogleFonts.poppins(
              color: Colors.white70,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  int _calculateNewUsersToday() {
    final today = DateTime.now();
    return _users.where((user) {
      final createdAt = user['createdAt'];
      if (createdAt == null) return false;
      final userDate = DateTime.fromMillisecondsSinceEpoch(createdAt);
      return userDate.year == today.year && userDate.month == today.month && userDate.day == today.day;
    }).length;
  }

  int _calculateClaimsToday() {
    final today = DateTime.now();
    return _claims.where((claim) {
      final submittedAt = claim['submittedAt'];
      if (submittedAt == null) return false;
      final claimDate = DateTime.fromMillisecondsSinceEpoch(submittedAt);
      return claimDate.year == today.year && claimDate.month == today.month && claimDate.day == today.day;
    }).length;
  }

  double _calculateRevenueToday() {
    final today = DateTime.now();
    double total = 0;
    for (final policy in _policies) {
      final createdAt = policy['createdAt'];
      if (createdAt != null) {
        final policyDate = DateTime.fromMillisecondsSinceEpoch(createdAt);
        if (policyDate.year == today.year && policyDate.month == today.month && policyDate.day == today.day) {
          final premium = double.tryParse(policy['premiumAmount']?.toString() ?? '0') ?? 0;
          total += premium;
        }
      }
    }
    return total;
  }

  Widget _buildUserManagement() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'User Management',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w600,
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {},
              icon: Icon(Icons.add, size: 18),
              label: Text('Add User'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        
        // Users Table
        _users.isEmpty
            ? _buildEmptyState('No users found', Icons.people)
            : Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingTextStyle: GoogleFonts.poppins(color: Colors.white70, fontWeight: FontWeight.w600),
                    dataTextStyle: GoogleFonts.poppins(color: Colors.white),
                    columns: const [
                      DataColumn(label: Text('User ID')),
                      DataColumn(label: Text('Name')),
                      DataColumn(label: Text('Email')),
                      DataColumn(label: Text('Policy')),
                      DataColumn(label: Text('Status')),
                      DataColumn(label: Text('Premium')),
                      DataColumn(label: Text('Risk Level')),
                      DataColumn(label: Text('Actions')),
                    ],
                    rows: _users.map((user) => DataRow(cells: [
                      DataCell(Text(user['id']?.toString().substring(0, 8) ?? 'N/A')),
                      DataCell(Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: _getAvatarColor(user['email'] ?? ''),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                _getInitials(user['firstName'] ?? '', user['lastName'] ?? ''),
                                style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text('${user['firstName'] ?? ''} ${user['lastName'] ?? ''}'),
                        ],
                      )),
                      DataCell(Text(user['email'] ?? 'N/A')),
                      DataCell(Text(user['policyType'] ?? 'No Policy')),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getStatusColor(user['status'] ?? 'Pending').withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            user['status'] ?? 'Pending',
                            style: GoogleFonts.poppins(
                              color: _getStatusColor(user['status'] ?? 'Pending'),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      DataCell(Text('R ${_formatCurrency(user['premiumAmount'] ?? 0)}')),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getRiskColor(user['riskLevel'] ?? 'Medium').withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            user['riskLevel'] ?? 'Medium',
                            style: GoogleFonts.poppins(
                              color: _getRiskColor(user['riskLevel'] ?? 'Medium'),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      DataCell(Row(
                        children: [
                          IconButton(
                            onPressed: () => _updateUserStatus(user['id'], 'Active'),
                            icon: Icon(Icons.check, color: Colors.greenAccent, size: 18),
                          ),
                          IconButton(
                            onPressed: () => _updateUserStatus(user['id'], 'Suspended'),
                            icon: Icon(Icons.block, color: Colors.redAccent, size: 18),
                          ),
                        ],
                      )),
                    ])).toList(),
                  ),
                ),
              ),
      ],
    );
  }

  Widget _buildApplications() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Insurance Applications',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 20),
        
        _applications.isEmpty
            ? _buildEmptyState('No pending applications', Icons.description)
            : Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  children: [
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingTextStyle: GoogleFonts.poppins(color: Colors.white70, fontWeight: FontWeight.w600),
                        dataTextStyle: GoogleFonts.poppins(color: Colors.white),
                        columns: const [
                          DataColumn(label: Text('App ID')),
                          DataColumn(label: Text('Applicant')),
                          DataColumn(label: Text('Email')),
                          DataColumn(label: Text('Vehicle')),
                          DataColumn(label: Text('Applied On')),
                          DataColumn(label: Text('Status')),
                          DataColumn(label: Text('Actions')),
                        ],
                        rows: _applications.map((app) => DataRow(cells: [
                          DataCell(Text(app['id']?.toString().substring(0, 8) ?? 'N/A')),
                          DataCell(Text('${app['personalInfo']?['firstName'] ?? ''} ${app['personalInfo']?['lastName'] ?? ''}')),
                          DataCell(Text(app['personalInfo']?['email'] ?? 'N/A')),
                          DataCell(Text(app['vehicleModel'] ?? 'N/A')),
                          DataCell(Text(_formatDate(app['submittedAt']))),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getStatusColor(app['status'] ?? 'Pending').withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                app['status'] ?? 'Pending',
                                style: GoogleFonts.poppins(
                                  color: _getStatusColor(app['status'] ?? 'Pending'),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          DataCell(Row(
                            children: [
                              if ((app['status'] ?? 'Pending') == 'Pending') ...[
                                IconButton(
                                  onPressed: () => _approveApplication(app['id']),
                                  icon: Icon(Icons.check, color: Colors.greenAccent, size: 18),
                                ),
                                IconButton(
                                  onPressed: () => _rejectApplication(app['id']),
                                  icon: Icon(Icons.close, color: Colors.redAccent, size: 18),
                                ),
                              ],
                              IconButton(
                                onPressed: () {},
                                icon: Icon(Icons.visibility, color: Colors.blueAccent, size: 18),
                              ),
                            ],
                          )),
                        ])).toList(),
                      ),
                    ),
                  ],
                ),
              ),
      ],
    );
  }

  Widget _buildPolicies() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Policy Management',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 20),
        
        _policies.isEmpty
            ? _buildEmptyState('No policies found', Icons.policy)
            : Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  children: [
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingTextStyle: GoogleFonts.poppins(color: Colors.white70, fontWeight: FontWeight.w600),
                        dataTextStyle: GoogleFonts.poppins(color: Colors.white),
                        columns: const [
                          DataColumn(label: Text('Policy ID')),
                          DataColumn(label: Text('User')),
                          DataColumn(label: Text('Type')),
                          DataColumn(label: Text('Premium')),
                          DataColumn(label: Text('Status')),
                          DataColumn(label: Text('Start Date')),
                          DataColumn(label: Text('End Date')),
                        ],
                        rows: _policies.map((policy) => DataRow(cells: [
                          DataCell(Text(policy['id']?.toString().substring(0, 8) ?? 'N/A')),
                          DataCell(Text(policy['userName'] ?? 'N/A')),
                          DataCell(Text(policy['policyType'] ?? 'N/A')),
                          DataCell(Text('R ${_formatCurrency(policy['premiumAmount'] ?? 0)}')),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getStatusColor(policy['status'] ?? 'Active').withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                policy['status'] ?? 'Active',
                                style: GoogleFonts.poppins(
                                  color: _getStatusColor(policy['status'] ?? 'Active'),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          DataCell(Text(_formatDate(policy['startDate']))),
                          DataCell(Text(_formatDate(policy['endDate']))),
                        ])).toList(),
                      ),
                    ),
                  ],
                ),
              ),
      ],
    );
  }

  Widget _buildClaims() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Claims Management',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 20),
        
        _claims.isEmpty
            ? _buildEmptyState('No claims found', Icons.description)
            : Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  children: [
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingTextStyle: GoogleFonts.poppins(color: Colors.white70, fontWeight: FontWeight.w600),
                        dataTextStyle: GoogleFonts.poppins(color: Colors.white),
                        columns: const [
                          DataColumn(label: Text('Claim ID')),
                          DataColumn(label: Text('User')),
                          DataColumn(label: Text('Type')),
                          DataColumn(label: Text('Amount')),
                          DataColumn(label: Text('Status')),
                          DataColumn(label: Text('Submitted')),
                          DataColumn(label: Text('Actions')),
                        ],
                        rows: _claims.map((claim) => DataRow(cells: [
                          DataCell(Text(claim['id']?.toString().substring(0, 8) ?? 'N/A')),
                          DataCell(Text(claim['userName'] ?? 'N/A')),
                          DataCell(Text(claim['type'] ?? 'N/A')),
                          DataCell(Text('R ${_formatCurrency(claim['amount'] ?? 0)}')),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getStatusColor(claim['status'] ?? 'Pending').withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                claim['status'] ?? 'Pending',
                                style: GoogleFonts.poppins(
                                  color: _getStatusColor(claim['status'] ?? 'Pending'),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          DataCell(Text(_formatDate(claim['submittedAt']))),
                          DataCell(Row(
                            children: [
                              if ((claim['status'] ?? 'Pending') == 'Pending') ...[
                                IconButton(
                                  onPressed: () => _processClaim(claim['id'], 'Approved'),
                                  icon: Icon(Icons.check, color: Colors.greenAccent, size: 18),
                                ),
                                IconButton(
                                  onPressed: () => _processClaim(claim['id'], 'Rejected'),
                                  icon: Icon(Icons.close, color: Colors.redAccent, size: 18),
                                ),
                              ],
                              IconButton(
                                onPressed: () {},
                                icon: Icon(Icons.visibility, color: Colors.blueAccent, size: 18),
                              ),
                            ],
                          )),
                        ])).toList(),
                      ),
                    ),
                  ],
                ),
              ),
      ],
    );
  }

  Widget _buildSystemSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'System Settings',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            children: [
              Text(
                'System Configuration Panel',
                style: GoogleFonts.poppins(color: Colors.white70),
              ),
              const SizedBox(height: 20),
              // Settings implementation would go here
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white54, size: 64),
          const SizedBox(height: 16),
          Text(
            message,
            style: GoogleFonts.poppins(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  String _getInitials(String firstName, String lastName) {
    return '${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}'.toUpperCase();
  }

  Color _getAvatarColor(String email) {
    final colors = [
      Colors.blueAccent,
      Colors.purpleAccent,
      Colors.greenAccent,
      Colors.orangeAccent,
      Colors.redAccent,
    ];
    final index = email.hashCode % colors.length;
    return colors[index];
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
      case 'approved':
        return Colors.greenAccent;
      case 'pending':
        return Colors.orangeAccent;
      case 'suspended':
      case 'rejected':
        return Colors.redAccent;
      default:
        return Colors.grey;
    }
  }

  Color _getRiskColor(String riskLevel) {
    switch (riskLevel.toLowerCase()) {
      case 'low':
        return Colors.greenAccent;
      case 'medium':
        return Colors.orangeAccent;
      case 'high':
        return Colors.redAccent;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    if (timestamp is int) {
      final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
      return '${date.day}/${date.month}/${date.year}';
    }
    return timestamp.toString();
  }

  String _formatCurrency(dynamic amount) {
    final value = double.tryParse(amount.toString()) ?? 0;
    return value.toStringAsFixed(0);
  }

  String _getTitle() {
    switch (_selectedTab) {
      case 0:
        return 'Dashboard Overview';
      case 1:
        return 'User Management';
      case 2:
        return 'Applications Center';
      case 3:
        return 'Policy Management';
      case 4:
        return 'Claims Center';
      case 5:
        return 'System Settings';
      default:
        return 'Admin Portal';
    }
  }
}