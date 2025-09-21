import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../providers/smart_notification_provider.dart';
import '../../models/patient_alert_model.dart';
import '../../core/utils/app_utils.dart';
import 'widgets/alert_card.dart';
import 'widgets/alert_filter_tabs.dart';
import 'widgets/emergency_alert_banner.dart';

class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({Key? key}) : super(key: key);

  @override
  State<NotificationCenterScreen> createState() => _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen>
    with TickerProviderStateMixin {

  late TabController _tabController;
  String _searchQuery = '';
  AlertSeverity? _selectedSeverity;
  AlertCategory? _selectedCategory;
  bool _showOnlyUnread = false;
  bool _isSelectionMode = false;
  Set<String> _selectedAlerts = <String>{};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SmartNotificationSystem>(
      builder: (context, notificationSystem, child) {
        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          body: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                _buildModernSliverAppBar(notificationSystem),
                _buildModernSliverTabs(),
              ];
            },
            body: TabBarView(
              controller: _tabController,
              children: [
                _buildActiveAlertsTab(notificationSystem),
                _buildEmergencyTab(notificationSystem),
                _buildHistoryTab(notificationSystem),
              ],
            ),
          ),
          floatingActionButton: _buildFloatingActionButton(notificationSystem),
        );
      },
    );
  }

  Widget _buildModernSliverAppBar(SmartNotificationSystem notificationSystem) {
    return SliverAppBar(
      expandedHeight: 180,
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
                Color(0xFF3B82F6),
                Color(0xFF1D4ED8),
                Color(0xFF1E40AF),
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
                    'Notification Center',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
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
                              '${notificationSystem.totalAlerts} Active',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (notificationSystem.hasEmergency)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDC2626).withOpacity(0.9),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.emergency,
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${notificationSystem.emergencyAlerts.length} Emergency',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      const Spacer(),
                      _buildModernQuickStats(notificationSystem),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      actions: [
        if (_isSelectionMode) ...[
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.select_all, color: Colors.white),
              onPressed: _selectAll,
              tooltip: 'Select All',
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.clear, color: Colors.white),
              onPressed: _clearSelection,
              tooltip: 'Clear Selection',
            ),
          ),
        ] else ...[
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.search, color: Colors.white),
              onPressed: _showSearchDialog,
              tooltip: 'Search',
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.filter_list, color: Colors.white),
              onPressed: _showFilterDialog,
              tooltip: 'Filter',
            ),
          ),
        ],
        Container(
          margin: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) => _handleMenuAction(value, notificationSystem),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'mark_all_read',
                child: ListTile(
                  leading: Icon(Icons.mark_email_read, size: 18),
                  title: Text('Mark All as Read'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'bulk_actions',
                child: ListTile(
                  leading: Icon(Icons.checklist, size: 18),
                  title: Text('Bulk Actions'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: ListTile(
                  leading: Icon(Icons.settings, size: 18),
                  title: Text('Alert Settings'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildModernQuickStats(SmartNotificationSystem notificationSystem) {
    return Row(
      children: [
        _buildModernStatChip(
          '${notificationSystem.criticalAlerts.length}',
          'Critical',
          const Color(0xFFDC2626),
        ),
        const SizedBox(width: 8),
        _buildModernStatChip(
          '${notificationSystem.unreadAlerts}',
          'Unread',
          const Color(0xFFF59E0B),
        ),
      ],
    );
  }

  Widget _buildModernStatChip(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(SmartNotificationSystem notificationSystem) {
    return SliverAppBar(
      expandedHeight: 160,
      floating: false,
      pinned: true,
      backgroundColor: AppColors.primary,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'नोटिफिकेशन केंद्र',
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
                              '${notificationSystem.totalAlerts} सक्रिय अलर्ट',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                            if (notificationSystem.hasEmergency)
                              Row(
                                children: [
                                  Icon(
                                    Icons.emergency,
                                    color: Colors.red[300],
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${notificationSystem.emergencyAlerts.length} आपातकालीन',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: Colors.red[300],
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                      _buildQuickStats(notificationSystem),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      actions: [
        if (_isSelectionMode) ...[
          IconButton(
            icon: const Icon(Icons.select_all, color: Colors.white),
            onPressed: _selectAll,
            tooltip: 'सभी चुनें',
          ),
          IconButton(
            icon: const Icon(Icons.clear, color: Colors.white),
            onPressed: _clearSelection,
            tooltip: 'चुनाव हटाएं',
          ),
        ] else ...[
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: _showSearchDialog,
            tooltip: 'खोजें',
          ),
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.white),
            onPressed: _showFilterDialog,
            tooltip: 'फ़िल्टर',
          ),
        ],
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          onSelected: (value) => _handleMenuAction(value, notificationSystem),
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'mark_all_read',
              child: ListTile(
                leading: Icon(Icons.mark_email_read, size: 18),
                title: Text('सभी पढ़े गए के रूप में चिह्नित करें'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            PopupMenuItem(
              value: 'bulk_actions',
              child: ListTile(
                leading: Icon(Icons.checklist, size: 18),
                title: Text('बल्क एक्शन मोड'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            PopupMenuItem(
              value: 'settings',
              child: ListTile(
                leading: Icon(Icons.settings, size: 18),
                title: Text('अलर्ट सेटिंग्स'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickStats(SmartNotificationSystem notificationSystem) {
    return Row(
      children: [
        _buildStatChip(
          '${notificationSystem.criticalAlerts.length}',
          'गंभीर',
          AppColors.error,
        ),
        const SizedBox(width: 8),
        _buildStatChip(
          '${notificationSystem.unreadAlerts}',
          'अपठित',
          AppColors.warning,
        ),
      ],
    );
  }

  Widget _buildStatChip(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: AppTextStyles.titleSmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernSliverTabs() {
    return SliverPersistentHeader(
      delegate: _ModernSliverTabBarDelegate(
        TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF3B82F6),
          unselectedLabelColor: const Color(0xFF64748B),
          indicatorColor: const Color(0xFF3B82F6),
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
                    Icon(Icons.notifications_active, size: 18),
                    SizedBox(width: 8),
                    Text('Active'),
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
                    Icon(Icons.emergency, size: 18),
                    SizedBox(width: 8),
                    Text('Emergency'),
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
                    Icon(Icons.history, size: 18),
                    SizedBox(width: 8),
                    Text('History'),
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
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          labelStyle: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.bold),
          unselectedLabelStyle: AppTextStyles.titleSmall,
          tabs: const [
            Tab(text: 'सक्रिय अलर्ट'),
            Tab(text: 'आपातकाल'),
            Tab(text: 'इतिहास'),
          ],
        ),
      ),
      pinned: true,
    );
  }

  Widget _buildActiveAlertsTab(SmartNotificationSystem notificationSystem) {
    final filteredAlerts = _getFilteredAlerts(notificationSystem.activeAlerts);

    return RefreshIndicator(
      onRefresh: () async {
        // Refresh alerts - in real app would sync with server
        await Future.delayed(const Duration(seconds: 1));
      },
      child: Column(
        children: [
          // Emergency banner if any
          if (notificationSystem.hasEmergency)
            EmergencyAlertBanner(
              alerts: notificationSystem.emergencyAlerts,
              onTap: () => _tabController.animateTo(1),
            ),

          // Filter tabs
          AlertFilterTabs(
            selectedSeverity: _selectedSeverity,
            selectedCategory: _selectedCategory,
            showOnlyUnread: _showOnlyUnread,
            onSeverityChanged: (severity) {
              setState(() {
                _selectedSeverity = severity;
              });
            },
            onCategoryChanged: (category) {
              setState(() {
                _selectedCategory = category;
              });
            },
            onUnreadToggle: (showUnread) {
              setState(() {
                _showOnlyUnread = showUnread;
              });
            },
          ),

          // Alerts list
          Expanded(
            child: filteredAlerts.isEmpty
                ? _buildEmptyState()
                : _buildAlertsList(filteredAlerts, notificationSystem),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyTab(SmartNotificationSystem notificationSystem) {
    final emergencyAlerts = notificationSystem.emergencyAlerts;

    return RefreshIndicator(
      onRefresh: () async {
        await Future.delayed(const Duration(seconds: 1));
      },
      child: emergencyAlerts.isEmpty
          ? _buildEmptyEmergencyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: emergencyAlerts.length,
              itemBuilder: (context, index) {
                return AlertCard(
                  alert: emergencyAlerts[index],
                  isSelected: _selectedAlerts.contains(emergencyAlerts[index].alertId),
                  isSelectionMode: _isSelectionMode,
                  onTap: () => _navigateToAlertDetail(emergencyAlerts[index]),
                  onLongPress: () => _toggleSelection(emergencyAlerts[index].alertId),
                  onActionTaken: (action) => _handleAlertAction(
                    emergencyAlerts[index],
                    action,
                    notificationSystem,
                  ),
                );
              },
            ),
    );
  }

  Widget _buildHistoryTab(SmartNotificationSystem notificationSystem) {
    final historyAlerts = notificationSystem.state.alertHistory;

    return RefreshIndicator(
      onRefresh: () async {
        await Future.delayed(const Duration(seconds: 1));
      },
      child: historyAlerts.isEmpty
          ? _buildEmptyHistoryState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: historyAlerts.length,
              itemBuilder: (context, index) {
                return AlertCard(
                  alert: historyAlerts[index],
                  isHistoryMode: true,
                  onTap: () => _navigateToAlertDetail(historyAlerts[index]),
                );
              },
            ),
    );
  }

  Widget _buildAlertsList(List<PatientAlert> alerts, SmartNotificationSystem notificationSystem) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: alerts.length,
      itemBuilder: (context, index) {
        final alert = alerts[index];
        return AlertCard(
          alert: alert,
          isSelected: _selectedAlerts.contains(alert.alertId),
          isSelectionMode: _isSelectionMode,
          onTap: () => _navigateToAlertDetail(alert),
          onLongPress: () => _toggleSelection(alert.alertId),
          onActionTaken: (action) => _handleAlertAction(alert, action, notificationSystem),
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
            Icons.notifications_none,
            size: 64,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            'कोई अलर्ट नहीं',
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'सभी मरीज़ सुरक्षित हैं',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyEmergencyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.emergency,
            size: 64,
            color: AppColors.success,
          ),
          const SizedBox(height: 16),
          Text(
            'कोई आपातकाल नहीं',
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.success,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'सभी मरीज़ स्थिर स्थिति में हैं',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyHistoryState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 64,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            'कोई इतिहास नहीं',
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'हल किए गए अलर्ट यहाँ दिखेंगे',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton(SmartNotificationSystem notificationSystem) {
    if (_isSelectionMode && _selectedAlerts.isNotEmpty) {
      return FloatingActionButton.extended(
        onPressed: () => _showBulkActionsDialog(notificationSystem),
        icon: const Icon(Icons.playlist_add_check),
        label: Text('${_selectedAlerts.length} चयनित'),
        backgroundColor: AppColors.primary,
      );
    }

    return FloatingActionButton(
      onPressed: () => Navigator.pushNamed(context, '/alert-settings'),
      child: const Icon(Icons.settings),
      backgroundColor: AppColors.primary,
      tooltip: 'अलर्ट सेटिंग्स',
    );
  }

  // Helper Methods
  List<PatientAlert> _getFilteredAlerts(List<PatientAlert> alerts) {
    var filteredAlerts = alerts;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filteredAlerts = filteredAlerts.where((alert) {
        return alert.patientName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               alert.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               alert.message.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Apply severity filter
    if (_selectedSeverity != null) {
      filteredAlerts = filteredAlerts.where((alert) => alert.severity == _selectedSeverity).toList();
    }

    // Apply category filter
    if (_selectedCategory != null) {
      filteredAlerts = filteredAlerts.where((alert) => alert.alertCategory == _selectedCategory).toList();
    }

    // Apply unread filter
    if (_showOnlyUnread) {
      filteredAlerts = filteredAlerts.where((alert) => !alert.isRead).toList();
    }

    // Sort by priority and timestamp
    filteredAlerts.sort((a, b) {
      // First by priority
      final priorityComparison = a.priority.index.compareTo(b.priority.index);
      if (priorityComparison != 0) return priorityComparison;
      
      // Then by timestamp (newest first)
      return b.timestamp.compareTo(a.timestamp);
    });

    return filteredAlerts;
  }

  void _navigateToAlertDetail(PatientAlert alert) {
    Navigator.pushNamed(
      context,
      '/alert-detail',
      arguments: alert.alertId,
    );
  }

  void _toggleSelection(String alertId) {
    setState(() {
      if (_selectedAlerts.contains(alertId)) {
        _selectedAlerts.remove(alertId);
      } else {
        _selectedAlerts.add(alertId);
      }

      // Exit selection mode if no alerts selected
      if (_selectedAlerts.isEmpty) {
        _isSelectionMode = false;
      }
    });
  }

  void _selectAll() {
    final notificationSystem = Provider.of<SmartNotificationSystem>(context, listen: false);
    setState(() {
      _selectedAlerts = Set.from(notificationSystem.activeAlerts.map((alert) => alert.alertId));
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedAlerts.clear();
      _isSelectionMode = false;
    });
  }

  void _handleAlertAction(PatientAlert alert, String action, SmartNotificationSystem notificationSystem) {
    switch (action) {
      case 'acknowledge':
        notificationSystem.acknowledgeAlert(alert.alertId);
        break;
      case 'resolve':
        _showResolveDialog(alert, notificationSystem);
        break;
      case 'dismiss':
        notificationSystem.dismissAlert(alert.alertId);
        break;
    }
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('खोजें'),
        content: TextField(
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
          decoration: const InputDecoration(
            hintText: 'मरीज़ का नाम या अलर्ट टेक्स्ट दर्ज करें',
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

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('फ़िल्टर'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Severity filter
            DropdownButtonFormField<AlertSeverity>(
              value: _selectedSeverity,
              decoration: const InputDecoration(labelText: 'गंभीरता'),
              items: AlertSeverity.values.map((severity) {
                return DropdownMenuItem(
                  value: severity,
                  child: Text(_getSeverityText(severity)),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedSeverity = value;
                });
              },
            ),
            const SizedBox(height: 16),

            // Category filter
            DropdownButtonFormField<AlertCategory>(
              value: _selectedCategory,
              decoration: const InputDecoration(labelText: 'श्रेणी'),
              items: AlertCategory.values.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(_getCategoryText(category)),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value;
                });
              },
            ),
            const SizedBox(height: 16),

            // Unread filter
            CheckboxListTile(
              title: const Text('केवल अपठित'),
              value: _showOnlyUnread,
              onChanged: (value) {
                setState(() {
                  _showOnlyUnread = value ?? false;
                });
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _selectedSeverity = null;
                _selectedCategory = null;
                _showOnlyUnread = false;
              });
              Navigator.pop(context);
            },
            child: const Text('साफ करें'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('लागू करें'),
          ),
        ],
      ),
    );
  }

  void _showResolveDialog(PatientAlert alert, SmartNotificationSystem notificationSystem) {
    String action = '';
    String notes = '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('अलर्ट हल करें - ${alert.title}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              onChanged: (value) => action = value,
              decoration: const InputDecoration(
                labelText: 'की गई कार्रवाई',
                hintText: 'उदा: डॉक्टर को फोन किया',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              onChanged: (value) => notes = value,
              decoration: const InputDecoration(
                labelText: 'नोट्स (वैकल्पिक)',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('रद्द करें'),
          ),
          ElevatedButton(
            onPressed: () {
              if (action.isNotEmpty) {
                notificationSystem.resolveAlert(alert.alertId, action, notes);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('अलर्ट हल कर दिया गया'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
            child: const Text('हल करें'),
          ),
        ],
      ),
    );
  }

  void _showBulkActionsDialog(SmartNotificationSystem notificationSystem) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${_selectedAlerts.length} अलर्ट्स के लिए कार्रवाई'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.mark_email_read),
              title: const Text('सभी को पढ़ा हुआ मार्क करें'),
              onTap: () {
                for (final alertId in _selectedAlerts) {
                  notificationSystem.acknowledgeAlert(alertId);
                }
                _clearSelection();
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.clear),
              title: const Text('सभी को खारिज करें'),
              onTap: () {
                for (final alertId in _selectedAlerts) {
                  notificationSystem.dismissAlert(alertId);
                }
                _clearSelection();
                Navigator.pop(context);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('रद्द करें'),
          ),
        ],
      ),
    );
  }

  void _handleMenuAction(String action, SmartNotificationSystem notificationSystem) {
    switch (action) {
      case 'mark_all_read':
        for (final alert in notificationSystem.activeAlerts) {
          notificationSystem.acknowledgeAlert(alert.alertId);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('सभी अलर्ट पढ़े गए के रूप में चिह्नित किए गए'),
            backgroundColor: AppColors.success,
          ),
        );
        break;
      case 'bulk_actions':
        setState(() {
          _isSelectionMode = !_isSelectionMode;
          if (!_isSelectionMode) {
            _selectedAlerts.clear();
          }
        });
        break;
      case 'settings':
        Navigator.pushNamed(context, '/alert-settings');
        break;
    }
  }

  String _getSeverityText(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.critical:
        return 'गंभीर';
      case AlertSeverity.high:
        return 'उच्च';
      case AlertSeverity.medium:
        return 'मध्यम';
      case AlertSeverity.low:
        return 'कम';
    }
  }

  String _getCategoryText(AlertCategory category) {
    switch (category) {
      case AlertCategory.criticalVitals:
        return 'गंभीर वाइटल्स';
      case AlertCategory.missedCheckIn:
        return 'छूटी हुई जांच';
      case AlertCategory.emergencySOS:
        return 'आपातकाल SOS';
      case AlertCategory.medicationAdherence:
        return 'दवा अनुपालन';
      case AlertCategory.appointmentReminder:
        return 'अपॉइंटमेंट रिमाइंडर';
      case AlertCategory.patternConcern:
        return 'पैटर्न चिंता';
    }
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