import 'package:flutter/material.dart';

// Import all screen files
// Common screens
import '../screens/common/splash_screen.dart';
import '../screens/common/language_screen.dart';
import '../screens/common/auth_screen.dart';
import '../screens/common/role_select_screen.dart';

// User screens
import '../screens/user/dashboard_screen.dart';
import '../screens/user/profile_setup_screen.dart';
import '../screens/user/asha_connect_screen.dart';
import '../screens/user/vitals_input_screen.dart';
import '../screens/user/vitals_trends_screen.dart';
import '../screens/user/health_feed_screen.dart';
import '../screens/user/reminders_screen.dart';
import '../screens/user/reports_upload_screen.dart';
import '../screens/user/chat_screen.dart';
import '../screens/user/user_profile_screen.dart';
import '../screens/user/emergency_hub_screen.dart';
import '../screens/user/ai_health_coach_screen.dart';
import '../screens/user/government_services_screen.dart';
import '../screens/user/heart_rate_measure_screen.dart';
import '../screens/user/hemoglobin_estimate_screen.dart';
import '../screens/user/queue_booking_screen.dart';

// ASHA screens
import '../screens/asha/asha_dashboard_screen.dart';
import '../screens/asha/patients_list_screen.dart';
import '../screens/asha/patient_details_screen.dart';
import '../screens/asha/asha_chat_screen.dart';
import '../screens/asha/asha_profile_screen.dart';
import '../screens/asha/visit_scheduler_screen.dart';

class AppRoutes {
  // Route names
  static const String splash = '/';
  static const String language = '/language';
  static const String auth = '/auth';
  static const String roleSelect = '/role-select';
  
  // User routes
  static const String userDashboard = '/user/dashboard';
  static const String profileSetup = '/user/profile-setup';
  static const String ashaConnect = '/user/asha-connect';
  static const String vitalsInput = '/user/vitals-input';
  static const String vitalsTrends = '/user/vitals-trends';
  static const String healthFeed = '/user/health-feed';
  static const String reminders = '/user/reminders';
  static const String reportsUpload = '/user/reports-upload';
  static const String userChat = '/user/chat';
  static const String userProfile = '/user/profile';
  static const String emergencyHub = '/user/emergency';
  static const String aiCoach = '/user/ai-coach';
  static const String governmentServices = '/user/government-services';
  static const String measureHeartRate = '/user/measure-heart-rate';
  static const String estimateHemoglobin = '/user/estimate-hemoglobin';
  static const String queueBooking = '/user/queue-booking';
  
  // ASHA routes
  static const String ashaDashboard = '/asha/dashboard';
  static const String patientsList = '/asha/patients';
  static const String patientDetails = '/asha/patient-details';
  static const String ashaChat = '/asha/chat';
  static const String ashaProfile = '/asha/profile';
  static const String visitScheduler = '/asha/visit-scheduler';
  
  // Route generator
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(
          builder: (_) => const SplashScreen(),
          settings: settings,
        );
        
      case language:
        return MaterialPageRoute(
          builder: (_) => const LanguageScreen(),
          settings: settings,
        );
        
      case auth:
        return MaterialPageRoute(
          builder: (_) => const AuthScreen(),
          settings: settings,
        );
        
      case roleSelect:
        return MaterialPageRoute(
          builder: (_) => const RoleSelectScreen(),
          settings: settings,
        );
        
      // User routes
      case userDashboard:
        return MaterialPageRoute(
          builder: (_) => const UserDashboardScreen(),
          settings: settings,
        );
        
      case profileSetup:
        return MaterialPageRoute(
          builder: (_) => const ProfileSetupScreen(),
          settings: settings,
        );
        
      case ashaConnect:
        return MaterialPageRoute(
          builder: (_) => const AshaConnectScreen(),
          settings: settings,
        );
        
      case vitalsInput:
        return MaterialPageRoute(
          builder: (_) => const VitalsInputScreen(),
          settings: settings,
        );
        
      case vitalsTrends:
        return MaterialPageRoute(
          builder: (_) => const VitalsTrendsScreen(),
          settings: settings,
        );
        
      case healthFeed:
        return MaterialPageRoute(
          builder: (_) => const HealthFeedScreen(),
          settings: settings,
        );
        
      case reminders:
        return MaterialPageRoute(
          builder: (_) => const RemindersScreen(),
          settings: settings,
        );
        
      case reportsUpload:
        return MaterialPageRoute(
          builder: (_) => const ReportsUploadScreen(),
          settings: settings,
        );
        
      case userChat:
        return MaterialPageRoute(
          builder: (_) => const UserChatScreen(),
          settings: settings,
        );
        
      case userProfile:
        return MaterialPageRoute(
          builder: (_) => const UserProfileScreen(),
          settings: settings,
        );
        
      case emergencyHub:
        return MaterialPageRoute(
          builder: (_) => const EmergencyHubScreen(),
          settings: settings,
        );
        
      case aiCoach:
        return MaterialPageRoute(
          builder: (_) => const AiHealthCoachScreen(),
          settings: settings,
        );
        
      case governmentServices:
        return MaterialPageRoute(
          builder: (_) => const GovernmentServicesScreen(),
          settings: settings,
        );
        
      case measureHeartRate:
        return MaterialPageRoute(
          builder: (_) => const HeartRateMeasureScreen(),
          settings: settings,
        );
        
      case estimateHemoglobin:
        return MaterialPageRoute(
          builder: (_) => const HemoglobinEstimateScreen(),
          settings: settings,
        );
        
      case queueBooking:
        return MaterialPageRoute(
          builder: (_) => const QueueBookingScreen(),
          settings: settings,
        );
        
      // ASHA routes
      case ashaDashboard:
        return MaterialPageRoute(
          builder: (_) => const AshaDashboardScreen(),
          settings: settings,
        );
        
      case patientsList:
        return MaterialPageRoute(
          builder: (_) => const PatientsListScreen(),
          settings: settings,
        );
        
      case patientDetails:
        return MaterialPageRoute(
          builder: (_) => const PatientDetailsScreen(),
          settings: settings,
        );
        
      case ashaChat:
        return MaterialPageRoute(
          builder: (_) => const ASHAChatScreen(),
          settings: settings,
        );
        
      case ashaProfile:
        return MaterialPageRoute(
          builder: (_) => const AshaProfileScreen(),
          settings: settings,
        );
        
      case visitScheduler:
        return MaterialPageRoute(
          builder: (_) => const VisitSchedulerScreen(),
          settings: settings,
        );
        
      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(
              child: Text('Page not found'),
            ),
          ),
          settings: settings,
        );
    }
  }
  
  // Navigation helpers
  static void navigateToSplash(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(context, splash, (route) => false);
  }
  
  static void navigateToLanguage(BuildContext context) {
    Navigator.pushNamed(context, language);
  }
  
  static void navigateToAuth(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(context, auth, (route) => false);
  }
  
  static void navigateToRoleSelect(BuildContext context) {
    debugPrint('AppRoutes: Navigating to Role Select');
    Navigator.pushReplacementNamed(context, roleSelect);
  }
  
  static void navigateToUserDashboard(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(context, userDashboard, (route) => false);
  }
  
  static void navigateToAshaDashboard(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(context, ashaDashboard, (route) => false);
  }
  
  static void navigateToProfileSetup(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(context, profileSetup, (route) => false);
  }
  
  static void navigateToAshaConnect(BuildContext context) {
    Navigator.pushNamed(context, ashaConnect);
  }
  
  static void navigateToVitalsInput(BuildContext context) {
    Navigator.pushNamed(context, vitalsInput);
  }
  
  static void navigateToVitalsTrends(BuildContext context) {
    Navigator.pushNamed(context, vitalsTrends);
  }
  
  static void navigateToHealthFeed(BuildContext context) {
    Navigator.pushNamed(context, healthFeed);
  }
  
  static void navigateToReminders(BuildContext context) {
    Navigator.pushNamed(context, reminders);
  }
  
  static void navigateToReportsUpload(BuildContext context) {
    Navigator.pushNamed(context, reportsUpload);
  }
  
  static void navigateToUserChat(BuildContext context, {String? ashaId}) {
    Navigator.pushNamed(
      context, 
      userChat,
      arguments: {'ashaId': ashaId},
    );
  }
  
  static void navigateToUserProfile(BuildContext context) {
    Navigator.pushNamed(context, userProfile);
  }
  
  static void navigateToEmergencyHub(BuildContext context) {
    Navigator.pushNamed(context, emergencyHub);
  }
  
  static void navigateToAiCoach(BuildContext context) {
    Navigator.pushNamed(context, aiCoach);
  }
  
  static void navigateToGovernmentServices(BuildContext context) {
    Navigator.pushNamed(context, governmentServices);
  }
  
  static void navigateToMeasureHeartRate(BuildContext context) {
    Navigator.pushNamed(context, measureHeartRate);
  }
  
  static void navigateToEstimateHemoglobin(BuildContext context) {
    Navigator.pushNamed(context, estimateHemoglobin);
  }
  
  static void navigateToQueueBooking(BuildContext context) {
    Navigator.pushNamed(context, queueBooking);
  }
  
  static void navigateToPatientsList(BuildContext context) {
    Navigator.pushNamed(context, patientsList);
  }
  
  static void navigateToPatientDetails(BuildContext context, {required String patientId}) {
    Navigator.pushNamed(
      context, 
      patientDetails,
      arguments: {'patientId': patientId},
    );
  }
  
  static void navigateToAshaChat(BuildContext context, {required String patientId}) {
    Navigator.pushNamed(
      context, 
      ashaChat,
      arguments: {'patientId': patientId},
    );
  }
  
  static void navigateToAshaProfile(BuildContext context) {
    Navigator.pushNamed(context, ashaProfile);
  }
  
  static void navigateToVisitScheduler(BuildContext context) {
    Navigator.pushNamed(context, visitScheduler);
  }
}
