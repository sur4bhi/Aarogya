import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../core/routes.dart';
import '../../core/utils/health_utils.dart';
import '../../models/vitals_model.dart';
import '../../providers/auth_provider.dart';

class AshaDashboardScreen extends StatefulWidget {
  const AshaDashboardScreen({super.key});

  @override
  State<AshaDashboardScreen> createState() => _AshaDashboardScreenState();
}

class _AshaDashboardScreenState extends State<AshaDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final ashaId = context.read<AuthProvider>().userId;
    if (ashaId == null) {
      return const Scaffold(
        body: Center(child: Text('Please login as ASHA to view dashboard')),
      );
    }

    final query = FirebaseFirestore.instance
        .collection('users')
        .where('ashaId', isEqualTo: ashaId)
        .where('userType', isEqualTo: 'patient')
        .snapshots();

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
                Color(0xFF059669),
                Color(0xFF10B981),
                Color(0xFF34D399),
              ],
            ),
          ),
        ),
        title: const Text(
          'ASHA Dashboard',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              tooltip: 'Schedule visit',
              icon: const Icon(Icons.calendar_today, color: Colors.white),
              onPressed: () => AppRoutes.navigateToVisitScheduler(context),
            ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: query,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Failed to load patients'),
                  const SizedBox(height: 8),
                  Text(snapshot.error.toString(), style: const TextStyle(color: Colors.red)),
                ],
              ),
            );
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('No patients assigned yet'));
          }

          // Sort by updatedAt in descending order (most recent first)
          docs.sort((a, b) {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;
            final aUpdatedAt = aData['updatedAt'] as Timestamp?;
            final bUpdatedAt = bData['updatedAt'] as Timestamp?;
            
            if (aUpdatedAt == null && bUpdatedAt == null) return 0;
            if (aUpdatedAt == null) return 1;
            if (bUpdatedAt == null) return -1;
            
            return bUpdatedAt.compareTo(aUpdatedAt); // Descending order
          });

          // Limit to 100 patients for performance
          final limitedDocs = docs.take(100).toList();

          return Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingMedium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildModernStatsHeader(limitedDocs),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView.separated(
                    itemCount: limitedDocs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final data = limitedDocs[index].data() as Map<String, dynamic>;
                      final patientId = limitedDocs[index].id;
                      final name = data['name'] ?? 'Patient';
                      final age = data['age'];

                      return _ModernPatientCard(
                        patientId: patientId,
                        name: name,
                        age: (age is int) ? age : null,
                        onTap: () => _navigateToPatientDetails(context, patientId),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildModernStatsHeader(List<QueryDocumentSnapshot> docs) {
    final total = docs.length;
    int abnormal = 0;
    int overdue = 0;

    // Calculate stats
    for (final d in docs) {
      final data = d.data() as Map<String, dynamic>;
      final lastVitalsAt = data['lastVitalsAt'];
      if (lastVitalsAt is Timestamp) {
        final days = DateTime.now().difference(lastVitalsAt.toDate()).inDays;
        if (days >= 7) overdue++;
      }
      if ((data['hasRecentAbnormal'] ?? false) == true) abnormal++;
    }

    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Patient Overview',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _modernStatCard(
                  'Total Patients',
                  total.toString(),
                  Icons.people,
                  const Color(0xFF3B82F6),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _modernStatCard(
                  'Abnormal Vitals',
                  abnormal.toString(),
                  Icons.warning_amber,
                  const Color(0xFFEF4444),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _modernStatCard(
                  'Overdue Checks',
                  overdue.toString(),
                  Icons.schedule,
                  const Color(0xFFF59E0B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _modernStatCard(String label, String value, IconData icon, Color color) {
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
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStatsHeader(List<QueryDocumentSnapshot> docs) {
    final total = docs.length;
    int abnormal = 0;
    int overdue = 0;

    // We do a rough pass using stored fields if present; detailed check per card
    for (final d in docs) {
      final data = d.data() as Map<String, dynamic>;
      final lastVitalsAt = data['lastVitalsAt'];
      if (lastVitalsAt is Timestamp) {
        final days = DateTime.now().difference(lastVitalsAt.toDate()).inDays;
        if (days >= 7) overdue++;
      }
      if ((data['hasRecentAbnormal'] ?? false) == true) abnormal++;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _statChip('Patients', total.toString(), Colors.blue),
        _statChip('Abnormal', abnormal.toString(), Colors.red),
        _statChip('Overdue', overdue.toString(), Colors.orange),
      ],
    );
  }

  Widget _statChip(String label, String value, Color color) {
    return Chip(
      label: Text('$label: $value'),
      backgroundColor: color.withOpacity(0.1),
      side: BorderSide(color: color.withOpacity(0.4)),
      avatar: CircleAvatar(backgroundColor: color, radius: 6),
    );
  }

  void _navigateToPatientDetails(BuildContext context, String patientId) {
    AppRoutes.navigateToPatientDetails(context, patientId: patientId);
  }
}

class _ModernPatientCard extends StatelessWidget {
  final String patientId;
  final String name;
  final int? age;
  final VoidCallback onTap;

  const _ModernPatientCard({
    required this.patientId,
    required this.name,
    required this.age,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF6366F1),
                      Color(0xFF8B5CF6),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.person,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    if (age != null) ..[
                      const SizedBox(height: 4),
                      Text(
                        'Age: $age',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    _ModernLatestVitalsBadge(patientId: patientId),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      tooltip: 'Message',
                      icon: const Icon(
                        Icons.message_outlined,
                        color: Color(0xFF10B981),
                        size: 20,
                      ),
                      onPressed: () {
                        AppRoutes.navigateToAshaChat(context, patientId: patientId);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      tooltip: 'Details',
                      icon: const Icon(
                        Icons.arrow_forward_ios,
                        color: Color(0xFF3B82F6),
                        size: 16,
                      ),
                      onPressed: onTap,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PatientCard extends StatelessWidget {
  final String patientId;
  final String name;
  final int? age;
  final VoidCallback onTap;

  const _PatientCard({
    required this.patientId,
    required this.name,
    required this.age,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              const CircleAvatar(child: Icon(Icons.person)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    if (age != null) Text('Age: $age'),
                    const SizedBox(height: 4),
                    _LatestVitalsBadge(patientId: patientId),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Message',
                icon: const Icon(Icons.message_outlined),
                onPressed: () {
                  // Navigate to ASHA chat
                  AppRoutes.navigateToAshaChat(context, patientId: patientId);
                },
              ),
              IconButton(
                tooltip: 'Details',
                icon: const Icon(Icons.arrow_forward_ios, size: 18),
                onPressed: onTap,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModernLatestVitalsBadge extends StatelessWidget {
  final String patientId;
  const _ModernLatestVitalsBadge({required this.patientId});

  @override
  Widget build(BuildContext context) {
    final vitalsRef = FirebaseFirestore.instance
        .collection('users/$patientId/vitals')
        .orderBy('timestamp', descending: true)
        .limit(1);

    return StreamBuilder<QuerySnapshot>(
      stream: vitalsRef.snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.withOpacity(0.3)),
            ),
            child: const Text(
              'No vitals yet',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        }
        final doc = snapshot.data!.docs.first;
        final latest = VitalsModel.fromFirestore(doc);

        final status = _calculateAlertStatus(latest);
        final timeAgo = _getTimeAgo(latest.timestamp);

        Color color;
        String label;
        IconData icon;
        switch (status) {
          case _AlertType.critical:
            color = const Color(0xFFEF4444);
            label = 'Critical';
            icon = Icons.warning;
            break;
          case _AlertType.warning:
            color = const Color(0xFFF59E0B);
            label = 'Warning';
            icon = Icons.warning_amber;
            break;
          case _AlertType.overdue:
            color = const Color(0xFF6B7280);
            label = 'Overdue';
            icon = Icons.schedule;
            break;
          case _AlertType.normal:
          default:
            color = const Color(0xFF10B981);
            label = 'Normal';
            icon = Icons.check_circle;
        }

        return Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 14,
                    color: color,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    label,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                timeAgo,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        );
      },
    );
  }

  String _getTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  _AlertType _calculateAlertStatus(VitalsModel vitals) {
    // Check critical/warning rules
    if (vitals.type == VitalType.bloodPressure &&
        vitals.systolicBP != null && vitals.diastolicBP != null) {
      final s = vitals.systolicBP!;
      final d = vitals.diastolicBP!;
      if (s >= 180 || d >= 110) return _AlertType.critical;
      if (s >= 140 || d >= 90) return _AlertType.warning;
    }
    if (vitals.type == VitalType.bloodGlucose && vitals.bloodGlucose != null) {
      final g = vitals.bloodGlucose!;
      if (g > 300) return _AlertType.critical;
      if (g > 200) return _AlertType.warning;
    }

    // Check if overdue (older than 7 days)
    if (DateTime.now().difference(vitals.timestamp).inDays >= 7) {
      return _AlertType.overdue;
    }
    return _AlertType.normal;
  }
}

class _LatestVitalsBadge extends StatelessWidget {
  final String patientId;
  const _LatestVitalsBadge({required this.patientId});

  @override
  Widget build(BuildContext context) {
    final vitalsRef = FirebaseFirestore.instance
        .collection('users/$patientId/vitals')
        .orderBy('timestamp', descending: true)
        .limit(1);

    return StreamBuilder<QuerySnapshot>(
      stream: vitalsRef.snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Text('No vitals yet');
        }
        final doc = snapshot.data!.docs.first;
        final latest = VitalsModel.fromFirestore(doc);

        final status = _calculateAlertStatus(latest);
        final timeStr = latest.timestamp.toLocal().toString();

        Color color;
        String label;
        switch (status) {
          case _AlertType.critical:
            color = Colors.red;
            label = 'Critical';
            break;
          case _AlertType.warning:
            color = Colors.orange;
            label = 'Warning';
            break;
          case _AlertType.overdue:
            color = Colors.grey;
            label = 'Overdue';
            break;
          case _AlertType.normal:
          default:
            color = Colors.green;
            label = 'Normal';
        }

        return Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                border: Border.all(color: color.withOpacity(0.4)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Last: $timeStr',
                style: const TextStyle(fontSize: 12, color: Colors.black54),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        );
      },
    );
  }

  _AlertType _calculateAlertStatus(VitalsModel vitals) {
    // Overdue handled if no data; with latest data, check critical/warning rules
    if (vitals.type == VitalType.bloodPressure &&
        vitals.systolicBP != null && vitals.diastolicBP != null) {
      final s = vitals.systolicBP!;
      final d = vitals.diastolicBP!;
      if (s >= 180 || d >= 110) return _AlertType.critical;
      if (s >= 140 || d >= 90) return _AlertType.warning;
    }
    if (vitals.type == VitalType.bloodGlucose && vitals.bloodGlucose != null) {
      final g = vitals.bloodGlucose!;
      if (g > 300) return _AlertType.critical;
      if (g > 200) return _AlertType.warning;
    }

    // Overdue if older than 7 days
    if (DateTime.now().difference(vitals.timestamp).inDays >= 7) {
      return _AlertType.overdue;
    }
    return _AlertType.normal;
  }
}

enum _AlertType { normal, warning, critical, overdue }
