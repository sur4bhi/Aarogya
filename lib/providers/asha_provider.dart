import 'package:flutter/foundation.dart';
import '../core/services/local_storage.dart';
import '../models/user_model.dart';
import '../models/asha_model.dart';
import 'user_provider.dart';

class AshaProvider extends ChangeNotifier {
  final List<Map<String, String>> _catalog = [
    {'id': 'a1', 'name': 'ASHA Priya', 'pin': '411001'},
    {'id': 'a2', 'name': 'ASHA Meera', 'pin': '411002'},
    {'id': 'a3', 'name': 'ASHA Kavita', 'pin': '411003'},
  ];

  List<Map<String, String>> _results = [];
  bool _isLoading = false;
  String? _error;
  AshaModel? _ashaData;

  List<Map<String, String>> get results => List.unmodifiable(_results);
  bool get isLoading => _isLoading;
  String? get error => _error;
  AshaModel? get ashaData => _ashaData;

  Future<void> search(String query) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    await Future<void>.delayed(const Duration(milliseconds: 300));
    try {
      final q = query.toLowerCase();
      _results = _catalog.where((e) {
        return (e['name']!.toLowerCase().contains(q)) || (e['pin']!.contains(q));
      }).toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> connectToAsha({
    required String ashaId,
    required UserProvider userProvider,
  }) async {
    final user = userProvider.currentUser;
    final updated = user.copyWith(connectedAshaId: ashaId, updatedAt: DateTime.now());
    await userProvider.updateUserProfile(updated);
    // Persist a lightweight mapping for offline read if needed
    await LocalStorageService.saveSetting('connected_asha_id', ashaId);
    notifyListeners();
  }

  /// Load ASHA data from local storage or remote source
  Future<void> loadAshaData(String ashaId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // For demo purposes, create a sample ASHA model
      // In a real app, this would fetch from Firestore or API
      _ashaData = AshaModel(
        id: ashaId,
        userId: ashaId,
        name: 'ASHA Worker',
        phoneNumber: '+91 9876543210',
        email: 'asha@example.com',
        licenseNumber: 'ASHA001',
        licenseExpiryDate: DateTime.now().add(const Duration(days: 365)),
        experienceYears: 5,
        isVerified: true,
        verificationDate: DateTime.now(),
        address: 'Sample Address',
        city: 'Sample City',
        state: 'Sample State',
        pincode: '411001',
        latitude: 0.0,
        longitude: 0.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Set ASHA data directly
  void setAshaData(AshaModel ashaModel) {
    _ashaData = ashaModel;
    notifyListeners();
  }

  /// Clear ASHA data
  void clearAshaData() {
    _ashaData = null;
    notifyListeners();
  }
}
