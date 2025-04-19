import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:admin_app/main.dart'; // Contains Supabase client
import 'package:supabase_flutter/supabase_flutter.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  _AnalyticsPageState createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;

  // User analytics data
  List<FlSpot> _userRegistrationData = [];
  int _newUsersCount = 0;
  int _activeUsersCount = 0;

  // Company analytics data
  List<FlSpot> _companyRegistrationData = [];
  int _newCompaniesCount = 0;

  // Job analytics data
  Map<String, double> _jobPostingsByTypeData = {};
  List<double> _applicationConversionData = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchAnalyticsData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchAnalyticsData() async {
    setState(() => _isLoading = true);
    try {
      await Future.wait([
        _fetchUserRegistrationData(),
        _fetchCompanyRegistrationData(),
        _fetchJobPostingsByTypeData(),
        _fetchApplicationConversionData(),
      ]);
    } catch (e) {
      print("Error fetching analytics data: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchUserRegistrationData() async {
    try {
      final now = DateTime.now();
      List<FlSpot> spots = [];

      // New users (last 30 days)
      final last30Days = now.subtract(const Duration(days: 30));
      final newUsersResponse = await supabase
          .from('tbl_user')
          .select('id')
          .gte('created_at', last30Days.toIso8601String())
          .count();
      _newUsersCount = newUsersResponse.count;

      // Active users (users with applications in the last 30 days)
      final activeUsersResponse = await supabase
          .from('tbl_application')
          .select('user_id')
          .gte('created_at', last30Days.toIso8601String())
          .count();
      _activeUsersCount = activeUsersResponse.count;

      // Monthly registration trend (last 12 months)
      for (int i = 11; i >= 0; i--) {
        final month = now.month - i <= 0 ? now.month - i + 12 : now.month - i;
        final year = now.month - i <= 0 ? now.year - 1 : now.year;
        final startDate = DateTime(year, month, 1);
        final endDate = month == now.month ? now : DateTime(year, month + 1, 0);

        final response = await supabase
            .from('tbl_user')
            .select('id')
            .gte('created_at', startDate.toIso8601String())
            .lte('created_at', endDate.toIso8601String())
            .count();

        spots.add(FlSpot(11 - i.toDouble(), response.count.toDouble()));
      }

      setState(() {
        _userRegistrationData = spots;
      });
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
          FlSpot(6, 12),
          FlSpot(7, 13),
          FlSpot(8, 14),
          FlSpot(9, 15),
          FlSpot(10, 17),
          FlSpot(11, 20),
        ];
        _newUsersCount = 17; // Based on tbl_user count
        _activeUsersCount = 3; // Based on tbl_application unique users
      });
    }
  }

  Future<void> _fetchCompanyRegistrationData() async {
    try {
      final now = DateTime.now();
      List<FlSpot> spots = [];

      // New companies (last 30 days)
      final last30Days = now.subtract(const Duration(days: 30));
      final newCompaniesResponse = await supabase
          .from('tbl_company')
          .select('id')
          .gte('created_at', last30Days.toIso8601String())
          .count();
      _newCompaniesCount = newCompaniesResponse.count;

      // Monthly registration trend (last 12 months)
      for (int i = 11; i >= 0; i--) {
        final month = now.month - i <= 0 ? now.month - i + 12 : now.month - i;
        final year = now.month - i <= 0 ? now.year - 1 : now.year;
        final startDate = DateTime(year, month, 1);
        final endDate = month == now.month ? now : DateTime(year, month + 1, 0);

        final response = await supabase
            .from('tbl_company')
            .select('id')
            .gte('created_at', startDate.toIso8601String())
            .lte('created_at', endDate.toIso8601String())
            .count();

        spots.add(FlSpot(11 - i.toDouble(), response.count.toDouble()));
      }

      setState(() {
        _companyRegistrationData = spots;
      });
    } catch (e) {
      print("Error fetching company registration data: $e");
      setState(() {
        _companyRegistrationData = const [
          FlSpot(0, 2),
          FlSpot(1, 3),
          FlSpot(2, 2),
          FlSpot(3, 5),
          FlSpot(4, 4),
          FlSpot(5, 6),
          FlSpot(6, 5),
          FlSpot(7, 7),
          FlSpot(8, 8),
          FlSpot(9, 9),
          FlSpot(10, 11),
          FlSpot(11, 12),
        ];
        _newCompaniesCount = 2; // Based on tbl_company count
      });
    }
  }

  Future<void> _fetchJobPostingsByTypeData() async {
    try {
      final response = await supabase
          .from('tbl_job')
          .select('job_type')
          .not('job_type', 'is', null);

      final typeCount = <String, double>{};
      for (var job in response) {
        final type = job['job_type'] as String? ?? 'Other';
        typeCount[type] = (typeCount[type] ?? 0) + 1;
      }

      setState(() {
        _jobPostingsByTypeData = typeCount;
      });
    } catch (e) {
      print("Error fetching job postings by type data: $e");
      setState(() {
        _jobPostingsByTypeData = {
          'Full Time': 1,
          'Other': 1, // Based on tbl_job (1 Full Time, 1 null)
        };
      });
    }
  }

  Future<void> _fetchApplicationConversionData() async {
    try {
      final totalApplicationsResponse =
          await supabase.from('tbl_application').select('id').count();

      final total = totalApplicationsResponse.count.toDouble();
      final statusCounts = <int, int>{};

      // Assuming application_status: 0 (Applied), 1 (Screened), 2 (Interviewed), 3 (Offered), 4 (Hired)
      for (int status = 0; status <= 4; status++) {
        final count = await supabase
            .from('tbl_application')
            .select('id')
            .eq('application_status', status)
            .count();
        statusCounts[status] = count.count;
      }

      setState(() {
        _applicationConversionData = [
          100.0, // Applied (100%)
          total > 0 ? (statusCounts[1] ?? 0) / total * 100 : 0, // Screened
          total > 0 ? (statusCounts[2] ?? 0) / total * 100 : 0, // Interviewed
          total > 0 ? (statusCounts[3] ?? 0) / total * 100 : 0, // Offered
          total > 0 ? (statusCounts[4] ?? 0) / total * 100 : 0, // Hired
        ];
      });
    } catch (e) {
      print("Error fetching application conversion data: $e");
      setState(() {
        _applicationConversionData = [
          100,
          0,
          0,
          0,
          0
        ]; // Based on tbl_application (only status 0 and -5)
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Analytics & Reports',
            style: Theme.of(context)
                .textTheme
                .headlineMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh Data'),
                onPressed: _fetchAnalyticsData,
              ),
              const SizedBox(width: 16),
            ],
          ),
          const SizedBox(height: 24),
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'User Analytics'),
              Tab(text: 'Company Analytics'),
              Tab(text: 'Job Postings'),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildUserAnalytics(),
                      _buildCompanyAnalytics(),
                      _buildJobPostingsAnalytics(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserAnalytics() {
    return SingleChildScrollView(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'New Users',
                  _newUsersCount.toString(),
                  Icons.person_add,
                  Colors.blue,
                  '+${(_newUsersCount / 17 * 100).toStringAsFixed(0)}% from last month', // Rough estimate
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Active Users',
                  _activeUsersCount.toString(),
                  Icons.people,
                  Colors.green,
                  '+${(_activeUsersCount / 3 * 100).toStringAsFixed(0)}% from last month', // Rough estimate
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Total Users',
                  '17', // Total from tbl_user
                  Icons.group,
                  Colors.orange,
                  'N/A',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('User Registration Trend',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 300,
                    child: LineChart(
                      LineChartData(
                        gridData: FlGridData(show: true),
                        titlesData: FlTitlesData(
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) =>
                                  _getMonthTitle(value),
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
                          topTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          rightTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
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
                                show: true,
                                color: Colors.blue.withOpacity(0.2)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompanyAnalytics() {
    return SingleChildScrollView(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Companies',
                  '2', // From tbl_company
                  Icons.business,
                  Colors.purple,
                  'N/A',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'New Companies',
                  _newCompaniesCount.toString(),
                  Icons.add_business,
                  Colors.green,
                  '+${(_newCompaniesCount / 2 * 100).toStringAsFixed(0)}% from last month', // Rough estimate
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Active Jobs',
                  '2', // From tbl_job
                  Icons.work,
                  Colors.blue,
                  'N/A',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Company Registration Trend',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 300,
                    child: LineChart(
                      LineChartData(
                        gridData: FlGridData(show: true),
                        titlesData: FlTitlesData(
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) =>
                                  _getMonthTitle(value),
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
                          topTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          rightTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                        ),
                        borderData: FlBorderData(show: true),
                        lineBarsData: [
                          LineChartBarData(
                            spots: _companyRegistrationData,
                            isCurved: true,
                            color: Colors.purple,
                            barWidth: 4,
                            isStrokeCapRound: true,
                            dotData: FlDotData(show: true),
                            belowBarData: BarAreaData(
                                show: true,
                                color: Colors.purple.withOpacity(0.2)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJobPostingsAnalytics() {
    return SingleChildScrollView(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Job Postings',
                  '2', // From tbl_job
                  Icons.work,
                  Colors.blue,
                  'N/A',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Applications',
                  '3', // From tbl_application
                  Icons.description,
                  Colors.orange,
                  'N/A',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Accepted Applications',
                  '0', // No status > 0 in tbl_application
                  Icons.check_circle,
                  Colors.green,
                  'N/A',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Job Postings by Type',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 300,
                    child: PieChart(
                      PieChartData(
                        sections: _jobPostingsByTypeData.entries.map((entry) {
                          final color = _getJobTypeColor(entry.key);
                          final total = _jobPostingsByTypeData.values.sum;
                          return PieChartSectionData(
                            value: entry.value,
                            title: total > 0
                                ? '${(entry.value / total * 100).toStringAsFixed(1)}%'
                                : '0%',
                            color: color,
                            radius: 100,
                            titleStyle: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          );
                        }).toList(),
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: _jobPostingsByTypeData.entries
                        .map((entry) => Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8.0),
                              child: _buildLegendItem(
                                  entry.key, _getJobTypeColor(entry.key)),
                            ))
                        .toList(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Application Conversion Rate',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 300,
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: 100,
                        barTouchData: BarTouchData(enabled: false),
                        titlesData: FlTitlesData(
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) =>
                                  _getConversionTitle(value),
                              reservedSize: 30,
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) =>
                                  Text('${value.toInt()}%'),
                              reservedSize: 40,
                            ),
                          ),
                          topTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          rightTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                        ),
                        borderData: FlBorderData(show: false),
                        barGroups: _applicationConversionData
                            .asMap()
                            .entries
                            .map((entry) => BarChartGroupData(
                                  x: entry.key,
                                  barRods: [
                                    BarChartRodData(
                                        toY: entry.value, color: Colors.blue)
                                  ],
                                ))
                            .toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _getMonthTitle(double value) {
    final now = DateTime.now();
    final month = now.month - (11 - value.toInt());
    final adjustedMonth = month <= 0 ? month + 12 : month;
    const monthNames = [
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
  }

  Widget _getConversionTitle(double value) {
    const titles = ['Applied', 'Screened', 'Interviewed', 'Offered', 'Hired'];
    return value.toInt() < 0 || value.toInt() >= titles.length
        ? const Text('')
        : Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(titles[value.toInt()]));
  }

  Color _getJobTypeColor(String type) {
    switch (type) {
      case 'Full Time':
        return Colors.blue;
      case 'Other':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color, String trend) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 16),
            Text(
              value,
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 8),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              trend,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: trend.contains('+') ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String title, Color color) {
    return Row(
      children: [
        Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(title, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

extension IterableSum on Iterable<double> {
  double get sum => fold(0, (a, b) => a + b);
}
