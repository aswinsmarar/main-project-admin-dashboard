import 'package:admin_app/login.dart';
import 'package:admin_app/main.dart';
import 'package:flutter/material.dart';
import 'package:admin_app/analytics.dart';
import 'package:admin_app/plan.dart';
import 'package:admin_app/language.dart';
import 'package:admin_app/soft_skill.dart';
import 'package:admin_app/technical_skill.dart';
import 'package:admin_app/view_user.dart';
import 'package:admin_app/manage_company.dart';
import 'package:fl_chart/fl_chart.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;
  bool _isSidebarExpanded = true;
  bool _isLoading = false;

  // Stats data
  Map<String, dynamic> _stats = {
    'users': 0,
    'companies': 0,
    'skills': 0,
    'languages': 0,
  };

  // Recent activities
  List<Map<String, dynamic>> _recentActivities = [];

  // User registration trend data
  List<FlSpot> _userRegistrationData = [];

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchStats();
    _fetchRecentActivities();
    _fetchUserRegistrationData();
  }

  Future<void> _fetchStats() async {
    setState(() => _isLoading = true);
    try {
      final usersResponse = await supabase.from('tbl_user').select('id');
      final companiesResponse = await supabase.from('tbl_company').select('id');
      final skillsResponse =
          await supabase.from('tbl_technicalskills').select('id');
      final languagesResponse =
          await supabase.from('tbl_language').select('id');

      setState(() {
        _stats = {
          'users': usersResponse.length ?? 0,
          'companies': companiesResponse.length ?? 0,
          'skills': skillsResponse.length ?? 0,
          'languages': languagesResponse.length ?? 0,
        };
        _isLoading = false;
      });
    } catch (e) {
      print("Error fetching stats: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchRecentActivities() async {
    try {
      final response = await supabase
          .from('tbl_activity_log')
          .select('*')
          .order('created_at', ascending: false)
          .limit(5);

      setState(
          () => _recentActivities = List<Map<String, dynamic>>.from(response));
    } catch (e) {
      print("Error fetching recent activities: $e");
      setState(() {
        _recentActivities = [
          {
            'action': 'New User Registered',
            'created_at': DateTime.now().subtract(const Duration(minutes: 2)),
            'type': 'user_create'
          },
          {
            'action': 'Company Profile Updated',
            'created_at': DateTime.now().subtract(const Duration(hours: 1)),
            'type': 'company_update'
          },
          {
            'action': 'New Technical Skill Added',
            'created_at': DateTime.now().subtract(const Duration(hours: 3)),
            'type': 'skill_create'
          },
          {
            'action': 'User Profile Updated',
            'created_at': DateTime.now().subtract(const Duration(hours: 5)),
            'type': 'user_update'
          },
        ];
      });
    }
  }

  Future<void> _fetchUserRegistrationData() async {
    try {
      final now = DateTime.now();
      List<FlSpot> spots = [];
      for (int i = 5; i >= 0; i--) {
        final month = now.month - i <= 0 ? now.month - i + 12 : now.month - i;
        final year = now.month - i <= 0 ? now.year - 1 : now.year;
        final startDate = DateTime(year, month, 1);
        final endDate = month == now.month ? now : DateTime(year, month + 1, 0);

        final response = await supabase
            .from('tbl_user')
            .select('id')
            .gte('created_at', startDate.toIso8601String())
            .lte('created_at', endDate.toIso8601String());

        spots.add(FlSpot(5 - i.toDouble(), (response.length ?? 0).toDouble()));
      }
      setState(() => _userRegistrationData = spots);
    } catch (e) {
      print("Error fetching user registration data: $e");
      setState(() {
        _userRegistrationData = const [
          FlSpot(0, 3),
          FlSpot(1, 5),
          FlSpot(2, 4),
          FlSpot(3, 7),
          FlSpot(4, 8),
          FlSpot(5, 10),
        ];
      });
    }
  }

  Future<void> _onRefresh() async {
    await Future.wait([
      _fetchStats(),
      _fetchRecentActivities(),
      _fetchUserRegistrationData(),
    ]);
  }

  Future<void> _logout() async {
    try {
      await supabase.auth.signOut();
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const Login(),
          ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to log out')),
      );
    }
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildDashboardHome();
      case 1:
        return const ViewUsersPage();
      case 2:
        return const ViewCompaniesPage();
      case 3:
        return const InsertLanguagePage();
      case 4:
        return const InsertSoftSkillPage();
      case 5:
        return const InsertTechnicalSkillPage();
      case 6:
        return const AnalyticsPage();
      case 7:
        return const InsertSubscriptionPlanPage();
      default:
        return _buildDashboardHome();
    }
  }

  Widget _buildDashboardHome() {
    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: SingleChildScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildStatsCards(),
              const SizedBox(height: 24),
              _buildUserRegistrationChart(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Dashboard Overview',
          style: Theme.of(context)
              .textTheme
              .headlineMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _onRefresh,
          tooltip: 'Refresh',
        ),
      ],
    );
  }

  Widget _buildStatsCards() {
    return GridView.count(
      crossAxisCount: 4,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildStatCard('Total Users', _stats['users'].toString(), Icons.people,
            Colors.blue),
        _buildStatCard('Companies', _stats['companies'].toString(),
            Icons.business, Colors.green),
        _buildStatCard('Technical Skills', _stats['skills'].toString(),
            Icons.code, Colors.orange),
        _buildStatCard('Languages', _stats['languages'].toString(),
            Icons.language, Colors.purple),
      ],
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 16),
            Text(value,
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 8),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      ),
    );
  }

  Color _getActivityColor(String? type) {
    switch (type) {
      case 'user_create':
      case 'user_update':
        return Colors.blue;
      case 'company_create':
      case 'company_update':
        return Colors.green;
      case 'skill_create':
      case 'skill_update':
        return Colors.orange;
      case 'language_create':
      case 'language_update':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getActivityIcon(String? type) {
    switch (type) {
      case 'user_create':
        return Icons.person_add;
      case 'user_update':
        return Icons.person;
      case 'company_create':
        return Icons.business;
      case 'company_update':
        return Icons.business_center;
      case 'skill_create':
      case 'skill_update':
        return Icons.code;
      case 'language_create':
      case 'language_update':
        return Icons.language;
      default:
        return Icons.event_note;
    }
  }

  Widget _buildUserRegistrationChart() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'User Registration Trend',
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 300,
          child: Card(
            elevation: 2,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final now = DateTime.now();
                          final month = now.month - (5 - value.toInt());
                          final adjustedMonth = month <= 0 ? month + 12 : month;
                          final monthNames = [
                            'Jan',
                            'Feb',
                            'Mar',
                            'Apr',
                            'May',
                            'Jun',
                            'Jul',
                            'Aug',
                            'Sep',
                            'Oct',
                            'Nov',
                            'Dec'
                          ];
                          return Text(monthNames[adjustedMonth - 1]);
                        },
                        reservedSize: 22,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) =>
                            Text(value.toInt().toString()),
                        reservedSize: 28,
                      ),
                    ),
                    topTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _userRegistrationData,
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 4,
                      isStrokeCapRound: true,
                      dotData: FlDotData(show: true),
                      belowBarData: BarAreaData(
                          show: true, color: Colors.blue.withOpacity(0.2)),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Skill Sync Admin'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Row(
        children: [
          _buildSidebar(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return NavigationRail(
      extended: _isSidebarExpanded,
      minExtendedWidth: 200,
      selectedIndex: _selectedIndex,
      onDestinationSelected: (int index) =>
          setState(() => _selectedIndex = index),
      leading: IconButton(
        icon:
            Icon(_isSidebarExpanded ? Icons.chevron_left : Icons.chevron_right),
        onPressed: () =>
            setState(() => _isSidebarExpanded = !_isSidebarExpanded),
      ),
      destinations: const [
        NavigationRailDestination(
            icon: Icon(Icons.dashboard), label: Text('Dashboard')),
        NavigationRailDestination(
            icon: Icon(Icons.people), label: Text('Users')),
        NavigationRailDestination(
            icon: Icon(Icons.business), label: Text('Companies')),
        NavigationRailDestination(
            icon: Icon(Icons.language), label: Text('Languages')),
        NavigationRailDestination(
            icon: Icon(Icons.psychology), label: Text('Soft Skills')),
        NavigationRailDestination(
            icon: Icon(Icons.code), label: Text('Technical Skills')),
        NavigationRailDestination(
            icon: Icon(Icons.analytics), label: Text('Analytics')),
        NavigationRailDestination(
            icon: Icon(Icons.subscriptions), label: Text('Subscription Plan')),
      ],
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
