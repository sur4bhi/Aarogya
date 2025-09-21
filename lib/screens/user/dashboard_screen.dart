import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../core/routes.dart';
import '../../models/vitals_model.dart';
import '../../widgets/common/offline_banner.dart';
import '../../widgets/user/vitals_card.dart';
import '../../widgets/user/health_article_card.dart';
import '../../providers/vitals_provider.dart';
import '../../providers/connectivity_provider.dart';
import '../../core/services/sync_service.dart';
import '../../core/services/local_storage.dart';
import '../../providers/language_provider.dart';
import '../../l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/services/sos_alert_service.dart';
import '../../core/services/location_service.dart';
import '../../providers/user_provider.dart';

/// User Dashboard
/// - Shows greeting, quick actions, vitals summary, health feed preview.
/// - Pull-to-refresh triggers `UserProvider.refreshDashboard()` and/or `SyncService.forceSync()`.
/// - OfflineBanner appears when offline via `ConnectivityProvider`.
class UserDashboardScreen extends StatefulWidget {
  const UserDashboardScreen({super.key});

  @override
  State<UserDashboardScreen> createState() => _UserDashboardScreenState();
}

class _UserDashboardScreenState extends State<UserDashboardScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Load vitals on first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VitalsProvider>().loadVitalsHistory();
    });
  }

  Widget _sosFab(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          colors: [
            Color(0xFFDC2626),
            Color(0xFFEF4444),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFDC2626).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        onPressed: () => _triggerSos(context),
        backgroundColor: Colors.transparent,
        elevation: 0,
        icon: const Icon(
          Icons.warning_amber_rounded,
          color: Colors.white,
          size: 24,
        ),
        label: const Text(
          'SOS',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Future<void> _triggerSos(BuildContext context) async {
    final userProvider = context.read<UserProvider>();
    var user = userProvider.currentUser;
    final vitalsProvider = context.read<VitalsProvider>();
    final latest = vitalsProvider.latestVitals;

    final latestVitalsMap = <String, String>{};
    if (latest != null) {
      if (latest.type == VitalType.bloodPressure && latest.systolicBP != null && latest.diastolicBP != null) {
        latestVitalsMap['BP'] = latest.bloodPressureString;
      }
      if (latest.type == VitalType.bloodGlucose && latest.bloodGlucose != null) {
        latestVitalsMap['Glucose'] = '${latest.bloodGlucose!.toStringAsFixed(0)} mg/dL';
      }
      if (latest.type == VitalType.weight && latest.weight != null) {
        latestVitalsMap['Weight'] = '${latest.weight!.toStringAsFixed(1)} kg';
      }
    }

    final locationUrl = await LocationService.getCurrentLocationUrl();
    final message = SosAlertService.buildSosMessage(
      name: user.name,
      latestVitals: latestVitalsMap.isEmpty ? null : latestVitalsMap,
      locationUrl: locationUrl,
    );

    // Save and show confirmation locally
    await SosAlertService.saveLastSos({
      'userName': user.name,
      'emergencyContactPhone': user.emergencyContactPhone,
      'message': message,
      'createdAt': DateTime.now().toIso8601String(),
    });

    await SosAlertService.showLocalConfirmation(summary: 'Emergency alert prepared');

    // Ensure we have an emergency contact phone; prompt if missing
    String? phone = user.emergencyContactPhone;
    if (phone == null || phone.isEmpty) {
      phone = await _promptEmergencyContact(context);
      // Refresh local user snapshot after save
      user = userProvider.currentUser;
    }

    if (phone != null && phone.isNotEmpty) {
      final uri = SosAlertService.buildSmsDeeplink(phoneNumbers: [phone], body: message);
      try {
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        } else {
          _showSnackBar(context, 'Could not open SMS app');
        }
      } catch (e) {
        _showSnackBar(context, 'Failed to launch SMS: $e');
      }
    } else {
      _showSnackBar(context, 'No emergency contact phone configured');
    }
  }

  void _showSnackBar(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<String?> _promptEmergencyContact(BuildContext context) async {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    String? result;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 12,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Add Emergency Contact', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Phone (10 digits)'),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () async {
                      final name = nameCtrl.text.trim();
                      final phone = phoneCtrl.text.trim();
                      if (phone.length != 10) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(content: Text('Please enter a valid 10-digit phone number')),
                        );
                        return;
                      }
                      final userProv = context.read<UserProvider>();
                      final updated = userProv.currentUser.copyWith(
                        emergencyContactName: name.isEmpty ? null : name,
                        emergencyContactPhone: phone,
                        updatedAt: DateTime.now(),
                      );
                      await userProv.updateUserProfile(updated);
                      result = phone;
                      if (context.mounted) Navigator.pop(ctx);
                    },
                    child: const Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );

    return result;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<VitalsProvider>().loadVitalsHistory();
      if (SyncService.isOnline) {
        SyncService.forceSync();
      }
    }
  }

  Future<void> _refresh() async {
    await context.read<VitalsProvider>().loadVitalsHistory();
    if (SyncService.isOnline) {
      await SyncService.forceSync();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOnline = context.watch<ConnectivityProvider>().isOnline;
    final l10n = AppLocalizations.of(context)!;
    final greeting = l10n.hello;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
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
        ),
        title: Text(
          '$greeting, User',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
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
              tooltip: l10n.language,
              icon: const Icon(Icons.translate, color: Colors.white),
              onPressed: () => _openLanguageSelector(context),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              tooltip: 'Sync now',
              icon: const Icon(Icons.sync, color: Colors.white),
              onPressed: () async {
                try {
                  await context.read<VitalsProvider>().forceSync();
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.syncedSuccessfully)),
                  );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${l10n.syncFailed}: $e')),
                  );
                }
              },
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              tooltip: 'Profile',
              onPressed: () => AppRoutes.navigateToUserProfile(context),
              icon: const CircleAvatar(
                radius: 14,
                backgroundColor: Colors.white,
                child: Icon(Icons.person, size: 18, color: Color(0xFF6366F1)),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          OfflineBanner(isOnline: isOnline),
          _buildSyncStatusBanner(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppDimensions.paddingMedium),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _quickActions(context),
                    const SizedBox(height: 16),
                    _vitalsSummary(context),
                    const SizedBox(height: 16),
                    _healthFeedPreview(context),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: _sosFab(context),
    );
  }

  Widget _quickActions(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 4,
            childAspectRatio: 0.85,
            mainAxisSpacing: 16,
            crossAxisSpacing: 12,
            children: [
              _quickAction(
                context,
                icon: Icons.monitor_heart,
                label: AppLocalizations.of(context)!.addVitals,
                color: const Color(0xFF10B981),
                onTap: () => AppRoutes.navigateToVitalsInput(context),
              ),
              _quickAction(
                context,
                icon: Icons.upload_file,
                label: AppLocalizations.of(context)!.uploadReport,
                color: const Color(0xFF3B82F6),
                onTap: () => AppRoutes.navigateToReportsUpload(context),
              ),
              _quickAction(
                context,
                icon: Icons.group_add,
                label: AppLocalizations.of(context)!.connectAsha,
                color: const Color(0xFF8B5CF6),
                onTap: () => AppRoutes.navigateToAshaConnect(context),
              ),
              _quickAction(
                context,
                icon: Icons.access_alarm,
                label: AppLocalizations.of(context)!.reminders,
                color: const Color(0xFFF59E0B),
                onTap: () => AppRoutes.navigateToReminders(context),
              ),
              _quickAction(
                context,
                icon: Icons.favorite,
                label: AppLocalizations.of(context)!.heartRate,
                color: const Color(0xFFEF4444),
                onTap: () => AppRoutes.navigateToMeasureHeartRate(context),
              ),
              _quickAction(
                context,
                icon: Icons.warning_amber_rounded,
                label: 'Emergency',
                color: const Color(0xFFDC2626),
                onTap: () => AppRoutes.navigateToEmergencyHub(context),
              ),
              _quickAction(
                context,
                icon: Icons.psychology_alt_outlined,
                label: 'AI Coach',
                color: const Color(0xFF6366F1),
                onTap: () => AppRoutes.navigateToAiCoach(context),
              ),
              _quickAction(
                context,
                icon: Icons.account_balance_outlined,
                label: 'Govt Services',
                color: const Color(0xFF059669),
                onTap: () => AppRoutes.navigateToGovernmentServices(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _quickAction(BuildContext context,
      {required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: color.withOpacity(0.1),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Color(0xFF475569),
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _vitalsSummary(BuildContext context) {
    return Consumer<VitalsProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: Padding(
            padding: EdgeInsets.all(16.0),
            child: CircularProgressIndicator(),
          ));
        }

        final history = provider.vitalsHistory;

        String bpValue = '--';
        String glucoseValue = '--';
        String weightValue = '--';
        String hrValue = '--';

        // Find latest BP
        VitalsModel? latestBp;
        try {
          latestBp = history.firstWhere(
            (v) => v.type == VitalType.bloodPressure && v.systolicBP != null && v.diastolicBP != null,
          );
        } catch (_) {
          final l = provider.latestVitals;
          if (l != null && l.type == VitalType.bloodPressure && l.systolicBP != null && l.diastolicBP != null) {
            latestBp = l;
          }
        }
        if (latestBp != null) {
          bpValue = latestBp.bloodPressureString;
        }

        // Find latest glucose
        VitalsModel? latestGlucose;
        try {
          latestGlucose = history.firstWhere(
            (v) => v.type == VitalType.bloodGlucose && v.bloodGlucose != null,
          );
        } catch (_) {
          final l = provider.latestVitals;
          if (l != null && l.type == VitalType.bloodGlucose && l.bloodGlucose != null) {
            latestGlucose = l;
          }
        }
        if (latestGlucose != null) {
          glucoseValue = latestGlucose.bloodGlucose!.toStringAsFixed(0);
        }

        // Find latest weight
        VitalsModel? latestWeight;
        try {
          latestWeight = history.firstWhere(
            (v) => v.type == VitalType.weight && v.weight != null,
          );
        } catch (_) {
          final l = provider.latestVitals;
          if (l != null && l.type == VitalType.weight && l.weight != null) {
            latestWeight = l;
          }
        }
        if (latestWeight != null) {
          weightValue = latestWeight.weight!.toStringAsFixed(1);
        }

        // Find latest heart rate
        VitalsModel? latestHr;
        try {
          latestHr = history.firstWhere(
            (v) => v.type == VitalType.heartRate && v.heartRate != null,
          );
        } catch (_) {
          final l = provider.latestVitals;
          if (l != null && l.type == VitalType.heartRate && l.heartRate != null) {
            latestHr = l;
          }
        }
        if (latestHr != null) {
          hrValue = latestHr.heartRate!.toStringAsFixed(0);
        }

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppLocalizations.of(context)!.latestVitals,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: TextButton(
                      onPressed: () => AppRoutes.navigateToVitalsTrends(context),
                      child: Text(
                        AppLocalizations.of(context)!.seeTrends,
                        style: const TextStyle(
                          color: Color(0xFF6366F1),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _modernVitalsCard(
                            title: AppLocalizations.of(context)!.bloodPressure,
                            value: bpValue,
                            unit: 'mmHg',
                            icon: Icons.favorite,
                            color: const Color(0xFFEF4444),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _modernVitalsCard(
                            title: AppLocalizations.of(context)!.bloodSugar,
                            value: glucoseValue,
                            unit: 'mg/dL',
                            icon: Icons.water_drop,
                            color: const Color(0xFF3B82F6),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _modernVitalsCard(
                            title: AppLocalizations.of(context)!.weight,
                            value: weightValue,
                            unit: 'kg',
                            icon: Icons.monitor_weight,
                            color: const Color(0xFF10B981),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _modernVitalsCard(
                            title: AppLocalizations.of(context)!.heartRate,
                            value: hrValue,
                            unit: 'bpm',
                            icon: Icons.favorite,
                            color: const Color(0xFFEC4899),
                            footer: _HeartRateSparkline(values: history
                                .where((v) => v.type == VitalType.heartRate && v.heartRate != null)
                                .take(20)
                                .map((v) => v.heartRate!)
                                .toList()),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _modernVitalsCard({
    required String title,
    required String value,
    required String unit,
    required IconData icon,
    required Color color,
    Widget? footer,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: color,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
          if (footer != null) ...[
            const SizedBox(height: 8),
            footer,
          ],
        ],
      ),
    );
  }

  Widget _healthFeedPreview(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)!.healthFeed,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: TextButton(
                  onPressed: () => AppRoutes.navigateToHealthFeed(context),
                  child: Text(
                    AppLocalizations.of(context)!.seeAll,
                    style: const TextStyle(
                      color: Color(0xFF6366F1),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _modernHealthArticleCard(
            title: '5 Tips for a Healthy Heart',
            summary: 'Simple lifestyle habits can significantly improve your heart health.',
            icon: Icons.favorite,
            color: const Color(0xFFEF4444),
          ),
          const SizedBox(height: 12),
          _modernHealthArticleCard(
            title: 'Understanding Blood Pressure',
            summary: 'Know your numbers and why they matter for your overall health.',
            icon: Icons.monitor_heart,
            color: const Color(0xFF3B82F6),
          ),
        ],
      ),
    );
  }

  Widget _modernHealthArticleCard({
    required String title,
    required String summary,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: color.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  summary,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: Colors.grey[400],
          ),
        ],
      ),
    );
  }

  Widget _buildSyncStatusBanner() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: Future(() => LocalStorageService.getAllVitalsRecords()),
      builder: (context, snapshot) {
        final connectivity = context.watch<ConnectivityProvider>();
        if (!connectivity.isOnline) {
          return Container(
            width: double.infinity,
            color: Colors.orange.withOpacity(0.15),
            padding: const EdgeInsets.all(8),
            child: Text(
              AppLocalizations.of(context)!.offlineBanner,
              textAlign: TextAlign.center,
            ),
          );
        }
        if (!snapshot.hasData) return const SizedBox.shrink();
        final pending = snapshot.data!
            .where((e) => (e['needsSync'] == true))
            .length;
        if (pending == 0) return const SizedBox.shrink();
        return Container(
          width: double.infinity,
          color: Colors.blue.withOpacity(0.1),
          padding: const EdgeInsets.all(8),
          child: Text(
            AppLocalizations.of(context)!.pendingSyncItems(pending),
            textAlign: TextAlign.center,
          ),
        );
      },
    );
  }

  void _openLanguageSelector(BuildContext context) {
    final current = context.read<LanguageProvider>().languageCode;
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        final l10n = AppLocalizations.of(ctx)!;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.flag),
                title: Text(l10n.english),
                trailing: current == 'en' ? const Icon(Icons.check) : null,
                onTap: () async {
                  await context.read<LanguageProvider>().setLanguage('en');
                  if (!mounted) return;
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.languageChanged)),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.flag),
                title: Text(l10n.hindi),
                trailing: current == 'hi' ? const Icon(Icons.check) : null,
                onTap: () async {
                  await context.read<LanguageProvider>().setLanguage('hi');
                  if (!mounted) return;
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.languageChanged)),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.flag),
                title: Text(l10n.marathi),
                trailing: current == 'mr' ? const Icon(Icons.check) : null,
                onTap: () async {
                  await context.read<LanguageProvider>().setLanguage('mr');
                  if (!mounted) return;
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.languageChanged)),
                  );
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }
}

class _HeartRateSparkline extends StatelessWidget {
  final List<double> values;
  const _HeartRateSparkline({required this.values});

  @override
  Widget build(BuildContext context) {
    if (values.length < 2) return const SizedBox.shrink();
    return SizedBox(
      height: 28,
      child: CustomPaint(
        painter: _SparklinePainter(values),
        size: const Size(double.infinity, 28),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> values;
  _SparklinePainter(this.values);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.purple
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..isAntiAlias = true;

    final minV = values.reduce((a, b) => a < b ? a : b);
    final maxV = values.reduce((a, b) => a > b ? a : b);
    final range = (maxV - minV).abs() < 1e-6 ? 1.0 : (maxV - minV);

    final path = Path();
    for (int i = 0; i < values.length; i++) {
      final x = i * (size.width / (values.length - 1));
      final norm = (values[i] - minV) / range;
      final y = size.height - norm * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    // Baseline
    final basePaint = Paint()
      ..color = Colors.purple.withOpacity(0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    final midY = size.height / 2;
    canvas.drawLine(Offset(0, midY), Offset(size.width, midY), basePaint);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
