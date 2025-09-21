import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../providers/health_monitoring_provider.dart';
import '../../models/patient_vitals_overview_model.dart';
import '../../core/utils/app_utils.dart';
import 'widgets/health_stats_row.dart';
import 'widgets/vitals_filter_tabs.dart';
import 'widgets/patient_vital_card.dart';
import 'widgets/risk_alert_banner.dart';
import 'widgets/health_trend_chart.dart';

class HealthMonitoringDashboardScreen extends StatefulWidget {
  const HealthMonitoringDashboardScreen({Key? key}) : super(key: key);

  @override
  State<HealthMonitoringDashboardScreen> createState() => _HealthMonitoringDashboardScreenState();
}

class _HealthMonitoringDashboardScreenState extends State<HealthMonitoringDashboardScreen>
    with TickerProviderStateMixin {
  
  late TabController _mainTabController;
  final ScrollController _scrollController = ScrollController();
  bool _showFloatingButton = false;
  String _searchQuery = '';
  bool _isGridView = false;

  @override
  void initState() {
    super.initState();
    _mainTabController = TabController(length: 3, vsync: this);
    
    _scrollController.addListener(() {
      final showButton = _scrollController.offset > 200;
      if (showButton != _showFloatingButton) {
        setState(() {
          _showFloatingButton = showButton;
        });
      }
    });

    // Initialize data loading
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<HealthMonitoringProvider>(context, listen: false).loadVitalsData();
    });
  }

  @override
  void dispose() {
    _mainTabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HealthMonitoringProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          body: NestedScrollView(
            controller: _scrollController,
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                _buildModernSliverAppBar(provider),
                _buildModernSliverTabs(),
              ];
            },
            body: TabBarView(
              controller: _mainTabController,
              children: [
                _buildOverviewTab(provider),
                _buildPatientsTab(provider),
                _buildAnalyticsTab(provider),
              ],
            ),
          ),
          floatingActionButton: _buildFloatingActionButton(provider),
        );
      },
    );
  }

  Widget _buildModernSliverAppBar(HealthMonitoringProvider provider) {
    return SliverAppBar(
      expandedHeight: 140,
      floating: false,
      pinned: true,
      backgroundColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF6366F1),
                Color(0xFF8B5CF6),
                Color(0xFFEC4899),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Text(
                    'Health Monitoring Center',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        color: Colors.white70,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Today • ${_formatDate(DateTime.now())}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.notifications_active,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${provider.getHighRiskPatients().length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: _showSearchDialog,
          ),
        ),
        Container(
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: provider.isLoading ? null : provider.refreshData,
          ),
        ),
        Container(
          margin: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) => _handleMenuAction(value, provider),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'export',
                child: ListTile(
                  leading: Icon(Icons.download),
                  title: Text('Export Data'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: ListTile(
                  leading: Icon(Icons.settings),
                  title: Text('Settings'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'help',
                child: ListTile(
                  leading: Icon(Icons.help),
                  title: Text('Help'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  Widget _buildSliverAppBar(HealthMonitoringProvider provider) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: AppColors.primary,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'स्वास्थ्य निगरानी केंद्र',
          style: AppTextStyles.titleLarge.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.primary,
                AppColors.primary.withOpacity(0.8),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'आज ${AppUtils.formatDate(DateTime.now())}',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      AlertCounterBadge(
                        onTap: () => _navigateToAlerts(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search, color: Colors.white),
          onPressed: _showSearchDialog,
        ),
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white),
          onPressed: provider.isLoading ? null : provider.refreshData,
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          onSelected: (value) => _handleMenuAction(value, provider),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'export',
              child: ListTile(
                leading: Icon(Icons.download),
                title: Text('डेटा निर्यात करें'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'settings',
              child: ListTile(
                leading: Icon(Icons.settings),
                title: Text('सेटिंग्स'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'help',
              child: ListTile(
                leading: Icon(Icons.help),
                title: Text('सहायता'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildModernSliverTabs() {
    return SliverPersistentHeader(
      delegate: _ModernSliverTabBarDelegate(
        TabBar(
          controller: _mainTabController,
          labelColor: const Color(0xFF6366F1),
          unselectedLabelColor: const Color(0xFF64748B),
          indicatorColor: const Color(0xFF6366F1),
          indicatorWeight: 3,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
          tabs: [
            Tab(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.dashboard, size: 18),
                    SizedBox(width: 8),
                    Text('Overview'),
                  ],
                ),
              ),
            ),
            Tab(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.people, size: 18),
                    SizedBox(width: 8),
                    Text('Patients'),
                  ],
                ),
              ),
            ),
            Tab(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.analytics, size: 18),
                    SizedBox(width: 8),
                    Text('Analytics'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      pinned: true,
    );
  }

  Widget _buildSliverTabs() {
    return SliverPersistentHeader(
      delegate: _SliverTabBarDelegate(
        TabBar(
          controller: _mainTabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          labelStyle: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.bold),
          unselectedLabelStyle: AppTextStyles.titleSmall,
          tabs: const [
            Tab(text: 'सिंहावलोकन'),
            Tab(text: 'मरीज़'),
            Tab(text: 'विश्लेषण'),
          ],
        ),
      ),
      pinned: true,
    );
  }

  Widget _buildOverviewTab(HealthMonitoringProvider provider) {
    return RefreshIndicator(
      onRefresh: provider.refreshData,
      child: CustomScrollView(
        slivers: [
          // Risk Alerts Banner
          SliverToBoxAdapter(
            child: RiskAlertBanner(
              maxAlerts: 3,
              onViewAll: _navigateToAlerts,
            ),
          ),
          
          // Health Statistics
          SliverToBoxAdapter(
            child: HealthStatsRow(
              showPercentages: true,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),

          // Quick Insights Section
          SliverToBoxAdapter(
            child: _buildQuickInsights(provider),
          ),

          // Population Trends
          SliverToBoxAdapter(
            child: _buildPopulationTrends(provider),
          ),

          // Recent Patient Updates
          SliverToBoxAdapter(
            child: _buildRecentPatientUpdates(provider),
          ),

          // Bottom padding
          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientsTab(HealthMonitoringProvider provider) {
    final filteredPatients = _getFilteredPatients(provider);
    
    return Column(
      children: [
        // Filter and Search
        VitalsSearchAndFilter(
          onSearchChanged: (query) {
            setState(() {
              _searchQuery = query.toLowerCase();
            });
          },
        ),

        // Filter Tabs
        VitalsFilterTabs(
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),

        // View Toggle
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text(
                '${filteredPatients.length} मरीज़ मिले',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(_isGridView ? Icons.view_list : Icons.view_module),
                onPressed: () {
                  setState(() {
                    _isGridView = !_isGridView;
                  });
                },
                tooltip: _isGridView ? 'सूची दृश्य' : 'ग्रिड दृश्य',
              ),
            ],
          ),
        ),

        // Patient List/Grid
        Expanded(
          child: RefreshIndicator(
            onRefresh: provider.refreshData,
            child: _isGridView 
                ? _buildPatientGrid(filteredPatients)
                : _buildPatientList(filteredPatients),
          ),
        ),
      ],
    );
  }

  Widget _buildAnalyticsTab(HealthMonitoringProvider provider) {
    return RefreshIndicator(
      onRefresh: provider.refreshData,
      child: CustomScrollView(
        slivers: [
          // Population Health Overview
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withOpacity(0.1),
                    AppColors.success.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.analytics, color: AppColors.primary, size: 24),
                      const SizedBox(width: 12),
                      Text(
                        'समुदायिक स्वास्थ्य विश्लेषण',
                        style: AppTextStyles.titleLarge.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildAnalyticsCards(provider),
                ],
              ),
            ),
          ),

          // Vital Signs Trends
          SliverToBoxAdapter(
            child: _buildVitalTrendsSection(provider),
          ),

          // Risk Factors Analysis
          SliverToBoxAdapter(
            child: _buildRiskFactorsAnalysis(provider),
          ),

          // Geographic Insights
          SliverToBoxAdapter(
            child: _buildGeographicInsights(provider),
          ),

          // Bottom padding
          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickInsights(HealthMonitoringProvider provider) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.insights, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'तत्काल अंतर्दृष्टि',
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildInsightCard(
                  'रुझान सुधार',
                  '${provider.getTrendingPatients(TrendDirection.improving).length} मरीज़',
                  Icons.trending_up,
                  AppColors.success,
                  () => _showTrendingPatients(TrendDirection.improving),
                ),
                const SizedBox(width: 12),
                _buildInsightCard(
                  'चिंताजनक रुझान',
                  '${provider.getTrendingPatients(TrendDirection.declining).length} मरीज़',
                  Icons.trending_down,
                  AppColors.error,
                  () => _showTrendingPatients(TrendDirection.declining),
                ),
                const SizedBox(width: 12),
                _buildInsightCard(
                  'पैटर्न डिटेक्शन',
                  '${provider.detectPatientsWithPatterns().length} पैटर्न',
                  Icons.pattern,
                  AppColors.info,
                  () => _showPatternsAnalysis(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightCard(String title, String value, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: AppTextStyles.titleMedium.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPopulationTrends(HealthMonitoringProvider provider) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.show_chart, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'समुदायिक रुझान (30 दिन)',
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => _mainTabController.animateTo(2),
                child: const Text('विस्तृत विश्लेषण'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: VitalType.values.map((vitalType) {
                  return Container(
                    width: 300,
                    margin: const EdgeInsets.only(right: 16),
                    child: HealthTrendChart(
                      vitalType: vitalType,
                      isPopulation: true,
                      days: 30,
                      height: 180,
                      showLegend: false,
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

  Widget _buildRecentPatientUpdates(HealthMonitoringProvider provider) {
    final recentUpdates = provider.allPatients
        .where((p) => DateTime.now().difference(p.lastVitalCheck).inHours < 24)
        .take(5)
        .toList();

    if (recentUpdates.isEmpty) return const SizedBox();

    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.update, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'हालिया अपडेट्स',
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => _mainTabController.animateTo(1),
                child: const Text('सभी देखें'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...recentUpdates.map((patient) => PatientVitalCard(
            patient: patient,
            isCompact: true,
            onTap: () => _navigateToPatientDetail(patient),
          )),
        ],
      ),
    );
  }

  Widget _buildAnalyticsCards(HealthMonitoringProvider provider) {
    final stats = provider.communityStats;
    if (stats == null) return const SizedBox();

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.5,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: [
        _buildAnalyticsCard(
          'औसत अनुपालन',
          '${stats.averageComplianceScore.toStringAsFixed(1)}%',
          Icons.check_circle,
          stats.averageComplianceScore >= 80 ? AppColors.success : AppColors.warning,
        ),
        _buildAnalyticsCard(
          'डेटा कवरेज',
          '${stats.dataCompleteness.toStringAsFixed(1)}%',
          Icons.data_usage,
          AppColors.info,
        ),
        _buildAnalyticsCard(
          'जोखिम वितरण',
          '${stats.riskDistribution.length} श्रेणियां',
          Icons.pie_chart,
          AppColors.primary,
        ),
        _buildAnalyticsCard(
          'रुझान स्कोर',
          '${stats.trendScore.toStringAsFixed(1)}/10',
          Icons.trending_up,
          stats.trendScore >= 7 ? AppColors.success : AppColors.error,
        ),
      ],
    );
  }

  Widget _buildAnalyticsCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outline.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTextStyles.titleLarge.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildVitalTrendsSection(HealthMonitoringProvider provider) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'वाइटल साइन्स ट्रेंड्स',
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...VitalType.values.map((vitalType) => Container(
            margin: const EdgeInsets.only(bottom: 16),
            child: HealthTrendChart(
              vitalType: vitalType,
              isPopulation: true,
              days: 90,
              height: 250,
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildRiskFactorsAnalysis(HealthMonitoringProvider provider) {
    final highRiskPatients = provider.getHighRiskPatients();
    final patientsNeedingAttention = provider.getPatientsNeedingAttention();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning, color: AppColors.error, size: 24),
              const SizedBox(width: 12),
              Text(
                'जोखिम कारक विश्लेषण',
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildRiskMetric(
                  'उच्च जोखिम',
                  highRiskPatients.length.toString(),
                  AppColors.error,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildRiskMetric(
                  'ध्यान चाहिए',
                  patientsNeedingAttention.length.toString(),
                  AppColors.warning,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRiskMetric(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: AppTextStyles.headlineMedium.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildGeographicInsights(HealthMonitoringProvider provider) {
    final insights = provider.getGeographicInsights();
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.info.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.info.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_on, color: AppColors.info, size: 24),
              const SizedBox(width: 12),
              Text(
                'भौगोलिक अंतर्दृष्टि',
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'कुल क्षेत्र: ${insights['totalAreas']}',
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'उच्च जोखिम क्षेत्र: ${insights['areasWithHighRisk']}',
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: 16),
          Text(
            'क्षेत्रवार अनुपालन दर:',
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.medium,
            ),
          ),
          const SizedBox(height: 8),
          ...((insights['averageComplianceByArea'] as Map<String, dynamic>).entries.map((entry) {
            final compliance = entry.value as double;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Text(entry.key, style: AppTextStyles.bodySmall),
                  const Spacer(),
                  Text(
                    '${compliance.toStringAsFixed(1)}%',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: compliance >= 80 ? AppColors.success : AppColors.warning,
                      fontWeight: FontWeight.medium,
                    ),
                  ),
                ],
              ),
            );
          })),
        ],
      ),
    );
  }

  Widget _buildPatientList(List<PatientVitalsOverview> patients) {
    if (patients.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 100),
      itemCount: patients.length,
      itemBuilder: (context, index) {
        return PatientVitalCard(
          patient: patients[index],
          onTap: () => _navigateToPatientDetail(patients[index]),
        );
      },
    );
  }

  Widget _buildPatientGrid(List<PatientVitalsOverview> patients) {
    if (patients.isEmpty) {
      return _buildEmptyState();
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16).copyWith(bottom: 100),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: patients.length,
      itemBuilder: (context, index) {
        return PatientVitalCard(
          patient: patients[index],
          isCompact: true,
          onTap: () => _navigateToPatientDetail(patients[index]),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 64,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            'कोई मरीज़ नहीं मिला',
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'फ़िल्टर बदलें या खोज शब्द सुधारें',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton(HealthMonitoringProvider provider) {
    return AnimatedSlide(
      offset: _showFloatingButton ? Offset.zero : const Offset(0, 2),
      duration: const Duration(milliseconds: 300),
      child: FloatingActionButton.extended(
        onPressed: () => _scrollToTop(),
        icon: const Icon(Icons.keyboard_arrow_up),
        label: const Text('टॉप पर जाएं'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  List<PatientVitalsOverview> _getFilteredPatients(HealthMonitoringProvider provider) {
    var patients = provider.filteredPatients;
    
    if (_searchQuery.isNotEmpty) {
      patients = patients.where((patient) {
        return patient.patientName.toLowerCase().contains(_searchQuery) ||
               patient.patientId.toLowerCase().contains(_searchQuery);
      }).toList();
    }
    
    return patients;
  }

  // Navigation and Action Methods
  void _navigateToPatientDetail(PatientVitalsOverview patient) {
    // Navigate to patient detail screen
    Navigator.pushNamed(
      context,
      '/patient-detail',
      arguments: patient.patientId,
    );
  }

  void _navigateToAlerts() {
    Navigator.pushNamed(context, '/risk-alerts');
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('खोजें'),
        content: TextField(
          onChanged: (value) {
            setState(() {
              _searchQuery = value.toLowerCase();
            });
          },
          decoration: const InputDecoration(
            hintText: 'मरीज़ का नाम या ID दर्ज करें',
            prefixIcon: Icon(Icons.search),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('बंद करें'),
          ),
        ],
      ),
    );
  }

  void _showTrendingPatients(TrendDirection direction) {
    final provider = Provider.of<HealthMonitoringProvider>(context, listen: false);
    final patients = provider.getTrendingPatients(direction);
    
    // Show bottom sheet with trending patients
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Text(
                '${direction == TrendDirection.improving ? 'सुधार रुझान' : 'गिरावट रुझान'} वाले मरीज़',
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: patients.length,
                itemBuilder: (context, index) {
                  return PatientVitalCard(
                    patient: patients[index],
                    isCompact: true,
                    onTap: () => _navigateToPatientDetail(patients[index]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPatternsAnalysis() {
    final provider = Provider.of<HealthMonitoringProvider>(context, listen: false);
    final patientsWithPatterns = provider.detectPatientsWithPatterns();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('पैटर्न विश्लेषण'),
        content: Text('${patientsWithPatterns.length} मरीज़ों में महत्वपूर्ण पैटर्न मिले हैं।'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ठीक है'),
          ),
        ],
      ),
    );
  }

  void _handleMenuAction(String action, HealthMonitoringProvider provider) {
    switch (action) {
      case 'export':
        _exportData(provider);
        break;
      case 'settings':
        Navigator.pushNamed(context, '/settings');
        break;
      case 'help':
        _showHelpDialog();
        break;
    }
  }

  void _exportData(HealthMonitoringProvider provider) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('डेटा निर्यात की सुविधा जल्द ही उपलब्ध होगी'),
        backgroundColor: AppColors.info,
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('सहायता'),
        content: const Text('स्वास्थ्य निगरानी डैशबोर्ड का उपयोग करके आप मरीज़ों के वाइटल्स, रुझान और अलर्ट्स की निगरानी कर सकते हैं।'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('समझ गया'),
          ),
        ],
      ),
    );
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }
}

// Modern custom delegate for sticky tab bar
class _ModernSliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _ModernSliverTabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) => false;
}

// Custom delegate for sticky tab bar
class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _SliverTabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppColors.background,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) => false;
}