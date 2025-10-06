import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
  
  // Sample data
  final List<Map<String, dynamic>> _users = [
    {
      'id': 'USR001',
      'name': 'John Smith',
      'email': 'john@example.com',
      'policy': 'Comprehensive',
      'status': 'Active',
      'premium': '\$1,200',
      'claims': 2,
      'riskLevel': 'Low',
      'lastLogin': '2 hours ago',
      'avatarColor': Colors.blue,
    },
    {
      'id': 'USR002', 
      'name': 'Sarah Johnson',
      'email': 'sarah@example.com',
      'policy': 'Third Party',
      'status': 'Pending',
      'premium': '\$800',
      'claims': 0,
      'riskLevel': 'Medium',
      'lastLogin': '1 day ago',
      'avatarColor': Colors.purple,
    },
    {
      'id': 'USR003',
      'name': 'Mike Chen',
      'email': 'mike@example.com', 
      'policy': 'Comprehensive',
      'status': 'Active',
      'premium': '\$1,500',
      'claims': 1,
      'riskLevel': 'Low',
      'lastLogin': '5 minutes ago',
      'avatarColor': Colors.green,
    },
    {
      'id': 'USR004',
      'name': 'Emma Davis',
      'email': 'emma@example.com',
      'policy': 'Third Party',
      'status': 'Suspended',
      'premium': '\$600',
      'claims': 3,
      'riskLevel': 'High',
      'lastLogin': '1 week ago',
      'avatarColor': Colors.orange,
    },
  ];

  final List<Map<String, dynamic>> _claims = [
    {
      'id': 'CLM001',
      'user': 'John Smith',
      'type': 'Accident',
      'status': 'Processing',
      'amount': '\$5,000',
      'date': '2024-01-15',
      'priority': 'High',
      'assignedTo': 'James Wilson',
    },
    {
      'id': 'CLM002',
      'user': 'Emma Davis', 
      'type': 'Theft',
      'status': 'Approved',
      'amount': '\$15,000',
      'date': '2024-01-10',
      'priority': 'Critical',
      'assignedTo': 'Sarah Brown',
    },
    {
      'id': 'CLM003',
      'user': 'Mike Chen',
      'type': 'Damage',
      'status': 'Pending',
      'amount': '\$2,500',
      'date': '2024-01-14',
      'priority': 'Medium',
      'assignedTo': 'Unassigned',
    },
  ];

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
      // AuthWrapper will automatically show WelcomeScreen
    } catch (e) {
      print('Error during logout: $e');
    }
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
                _buildNavItem(Icons.description, 'Claims Center', 2),
                _buildNavItem(Icons.policy, 'Policy Control', 3),
                _buildNavItem(Icons.analytics, 'Analytics', 4),
                _buildNavItem(Icons.settings, 'System Settings', 5),
                _buildNavItem(Icons.security, 'Risk Management', 6),
                _buildNavItem(Icons.notifications, 'Alerts Center', 7),
              ],
            ),
          ),
          
          // User Info
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
            ),
            child: Row(
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
                  onPressed: _handleLogout,
                  icon: Icon(Icons.logout, color: Colors.white70, size: 20),
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
                _buildStatCard('Total Users', '1,247', Icons.people, Colors.blueAccent, '+12%'),
                _buildStatCard('Active Policies', '984', Icons.policy, Colors.greenAccent, '+5%'),
                _buildStatCard('Pending Claims', '23', Icons.description, Colors.orangeAccent, '-3%'),
                _buildStatCard('Revenue', '\$248K', Icons.attach_money, Colors.purpleAccent, '+18%'),
                _buildStatCard('Risk Score', '7.2/10', Icons.security, Colors.redAccent, '-2%'),
                _buildStatCard('Satisfaction', '94%', Icons.star, Colors.yellowAccent, '+1%'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, String trend) {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              Text(
                trend,
                style: GoogleFonts.poppins(
                  color: trend.startsWith('+') ? Colors.greenAccent : Colors.redAccent,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
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
                _buildActionButton('Claims Center', Icons.description, Colors.orangeAccent),
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
      case 0: // Dashboard
        return _buildDashboard();
      case 1: // User Management
        return _buildUserManagement();
      case 2: // Claims Center
        return _buildClaimsCenter();
      case 3: // Policy Control
        return _buildPolicyControl();
      case 4: // Analytics
        return _buildAnalytics();
      case 5: // System Settings
        return _buildSystemSettings();
      case 6: // Risk Management
        return _buildRiskManagement();
      case 7: // Alerts Center
        return _buildAlertsCenter();
      default:
        return _buildDashboard();
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
          Column(
            children: _buildActivityItems(),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildActivityItems() {
    return [
      _buildActivityItem('New user registration', 'John Doe signed up', '2 min ago', Icons.person_add, Colors.green),
      _buildActivityItem('Claim submitted', 'Accident claim #CLM045', '15 min ago', Icons.description, Colors.orange),
      _buildActivityItem('Policy renewal', 'Policy #POL1289 renewed', '1 hour ago', Icons.autorenew, Colors.blue),
      _buildActivityItem('Risk alert', 'High risk detected - User #USR204', '2 hours ago', Icons.warning, Colors.red),
    ];
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
                Text('Performance Chart Placeholder', style: GoogleFonts.poppins(color: Colors.white)),
                const SizedBox(height: 100),
                // Would be replaced with actual chart library
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(child: Text('Interactive Chart', style: GoogleFonts.poppins(color: Colors.white70))),
                ),
              ],
            ),
          ),
        ),
      ],
    );
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
        Container(
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
                DataColumn(label: Text('Claims')),
                DataColumn(label: Text('Risk Level')),
                DataColumn(label: Text('Last Login')),
                DataColumn(label: Text('Actions')),
              ],
              rows: _users.map((user) => DataRow(cells: [
                DataCell(Text(user['id'])),
                DataCell(Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: user['avatarColor'],
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          user['name'].split(' ').map((n) => n[0]).join(),
                          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(user['name']),
                  ],
                )),
                DataCell(Text(user['email'])),
                DataCell(Text(user['policy'])),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(user['status']).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      user['status'],
                      style: GoogleFonts.poppins(
                        color: _getStatusColor(user['status']),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                DataCell(Text(user['premium'])),
                DataCell(Text(user['claims'].toString())),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getRiskColor(user['riskLevel']).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      user['riskLevel'],
                      style: GoogleFonts.poppins(
                        color: _getRiskColor(user['riskLevel']),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                DataCell(Text(user['lastLogin'])),
                DataCell(Row(
                  children: [
                    IconButton(
                      onPressed: () {},
                      icon: Icon(Icons.edit, color: Colors.blueAccent, size: 18),
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: Icon(Icons.visibility, color: Colors.greenAccent, size: 18),
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: Icon(Icons.delete, color: Colors.redAccent, size: 18),
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

  Widget _buildClaimsCenter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Claims Center',
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
                'Claims Management Interface',
                style: GoogleFonts.poppins(color: Colors.white70),
              ),
              const SizedBox(height: 20),
              // Claims table implementation would go here
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingTextStyle: GoogleFonts.poppins(color: Colors.white70, fontWeight: FontWeight.w600),
                  dataTextStyle: GoogleFonts.poppins(color: Colors.white),
                  columns: const [
                    DataColumn(label: Text('Claim ID')),
                    DataColumn(label: Text('User')),
                    DataColumn(label: Text('Type')),
                    DataColumn(label: Text('Status')),
                    DataColumn(label: Text('Amount')),
                    DataColumn(label: Text('Date')),
                    DataColumn(label: Text('Priority')),
                    DataColumn(label: Text('Assigned To')),
                  ],
                  rows: _claims.map((claim) => DataRow(cells: [
                    DataCell(Text(claim['id'])),
                    DataCell(Text(claim['user'])),
                    DataCell(Text(claim['type'])),
                    DataCell(Text(claim['status'])),
                    DataCell(Text(claim['amount'])),
                    DataCell(Text(claim['date'])),
                    DataCell(Text(claim['priority'])),
                    DataCell(Text(claim['assignedTo'])),
                  ])).toList(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPolicyControl() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Policy Control',
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
                'Policy Management Interface',
                style: GoogleFonts.poppins(color: Colors.white70),
              ),
              const SizedBox(height: 20),
              // Policy management implementation would go here
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAnalytics() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Analytics & Reports',
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
                'Advanced Analytics Dashboard',
                style: GoogleFonts.poppins(color: Colors.white70),
              ),
              const SizedBox(height: 20),
              // Analytics charts implementation would go here
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

  Widget _buildRiskManagement() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Risk Management',
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
                'Risk Analysis Interface',
                style: GoogleFonts.poppins(color: Colors.white70),
              ),
              const SizedBox(height: 20),
              // Risk management implementation would go here
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAlertsCenter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Alerts Center',
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
                'Real-time Notifications Center',
                style: GoogleFonts.poppins(color: Colors.white70),
              ),
              const SizedBox(height: 20),
              // Alerts implementation would go here
            ],
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active': return Colors.greenAccent;
      case 'pending': return Colors.orangeAccent;
      case 'suspended': return Colors.redAccent;
      default: return Colors.grey;
    }
  }

  Color _getRiskColor(String riskLevel) {
    switch (riskLevel.toLowerCase()) {
      case 'low': return Colors.greenAccent;
      case 'medium': return Colors.orangeAccent;
      case 'high': return Colors.redAccent;
      default: return Colors.grey;
    }
  }

  String _getTitle() {
    switch (_selectedTab) {
      case 0: return 'Dashboard Overview';
      case 1: return 'User Management';
      case 2: return 'Claims Center';
      case 3: return 'Policy Control';
      case 4: return 'Analytics & Reports';
      case 5: return 'System Settings';
      case 6: return 'Risk Management';
      case 7: return 'Alerts Center';
      default: return 'Admin Portal';
    }
  }
}