import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../constants.dart';

class LocalStorageService {
  static late SharedPreferences _prefs;
  static late Box _userBox;
  static late Box _vitalsBox;
  static late Box _remindersBox;
  static late Box _reportsBox;
  static late Box _settingsBox;
  static bool _hiveInitialized = false;
  
  // Initialize storage
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    
    // Initialize Hive boxes
    await Hive.initFlutter();
    _hiveInitialized = true;
    _userBox = await Hive.openBox('user_data');
    _vitalsBox = await Hive.openBox('vitals_data');
    _remindersBox = await Hive.openBox('reminders_data');
    _reportsBox = await Hive.openBox('reports_data');
    _settingsBox = await Hive.openBox('settings_data');
  }

  static Future<void> _ensureHiveInitialized() async {
    if (!_hiveInitialized) {
      await Hive.initFlutter();
      _hiveInitialized = true;
    }
  }
  
  // SharedPreferences methods for simple key-value storage
  
  // String operations
  static Future<void> setString(String key, String value) async {
    await _prefs.setString(key, value);
  }
  
  static String? getString(String key) {
    return _prefs.getString(key);
  }
  
  // Integer operations
  static Future<void> setInt(String key, int value) async {
    await _prefs.setInt(key, value);
  }
  
  static int? getInt(String key) {
    return _prefs.getInt(key);
  }
  
  // Boolean operations
  static Future<void> setBool(String key, bool value) async {
    await _prefs.setBool(key, value);
  }
  
  static bool? getBool(String key) {
    return _prefs.getBool(key);
  }
  
  // Double operations
  static Future<void> setDouble(String key, double value) async {
    await _prefs.setDouble(key, value);
  }
  
  static double? getDouble(String key) {
    return _prefs.getDouble(key);
  }
  
  // List operations
  static Future<void> setStringList(String key, List<String> value) async {
    await _prefs.setStringList(key, value);
  }
  
  static List<String>? getStringList(String key) {
    return _prefs.getStringList(key);
  }
  
  // Alias method for convenience
  static Future<void> saveStringList(String key, List<String> value) async {
    await setStringList(key, value);
  }
  
  // Remove key
  static Future<void> remove(String key) async {
    await _prefs.remove(key);
  }
  
  // Clear all preferences
  static Future<void> clearPreferences() async {
    await _prefs.clear();
  }
  
  // Check if key exists
  static bool containsKey(String key) {
    return _prefs.containsKey(key);
  }
  
  // Hive operations for complex data storage
  
  // User data operations
  static Future<void> saveUserData(String key, Map<String, dynamic> userData) async {
    await _userBox.put(key, userData);
  }
  
  static Map<String, dynamic>? getUserData(String key) {
    final data = _userBox.get(key);
    return data != null ? Map<String, dynamic>.from(data) : null;
  }
  
  static Future<void> deleteUserData(String key) async {
    await _userBox.delete(key);
  }
  
  static List<String> getUserDataKeys() {
    return _userBox.keys.cast<String>().toList();
  }
  
  // Vitals data operations
  static Future<void> saveVitalsRecord(String key, Map<String, dynamic> vitalsData) async {
    await _vitalsBox.put(key, vitalsData);
  }
  
  static Map<String, dynamic>? getVitalsRecord(String key) {
    final data = _vitalsBox.get(key);
    return data != null ? Map<String, dynamic>.from(data) : null;
  }
  
  static List<Map<String, dynamic>> getAllVitalsRecords() {
    return _vitalsBox.values
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }
  
  static Future<void> deleteVitalsRecord(String key) async {
    await _vitalsBox.delete(key);
  }
  
  static Future<void> clearAllVitals() async {
    await _vitalsBox.clear();
  }
  
  // Get vitals records within date range
  static List<Map<String, dynamic>> getVitalsInDateRange(
    DateTime startDate,
    DateTime endDate,
  ) {
    final allVitals = getAllVitalsRecords();
    return allVitals.where((vital) {
      final timestamp = DateTime.parse(vital['timestamp']);
      return timestamp.isAfter(startDate) && timestamp.isBefore(endDate);
    }).toList();
  }
  
  // Reminders data operations
  static Future<void> saveReminder(String key, Map<String, dynamic> reminderData) async {
    await _remindersBox.put(key, reminderData);
  }
  
  static Map<String, dynamic>? getReminder(String key) {
    final data = _remindersBox.get(key);
    return data != null ? Map<String, dynamic>.from(data) : null;
  }
  
  static List<Map<String, dynamic>> getAllReminders() {
    return _remindersBox.values
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }
  
  static Future<void> deleteReminder(String key) async {
    await _remindersBox.delete(key);
  }
  
  static Future<void> clearAllReminders() async {
    await _remindersBox.clear();
  }
  
  // Get active reminders
  static List<Map<String, dynamic>> getActiveReminders() {
    final allReminders = getAllReminders();
    return allReminders.where((reminder) => reminder['isActive'] == true).toList();
  }
  
  // Reports data operations
  static Future<void> saveReport(String key, Map<String, dynamic> reportData) async {
    await _reportsBox.put(key, reportData);
  }
  
  static Map<String, dynamic>? getReport(String key) {
    final data = _reportsBox.get(key);
    return data != null ? Map<String, dynamic>.from(data) : null;
  }
  
  static List<Map<String, dynamic>> getAllReports() {
    return _reportsBox.values
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }
  
  static Future<void> deleteReport(String key) async {
    await _reportsBox.delete(key);
  }
  
  static Future<void> clearAllReports() async {
    await _reportsBox.clear();
  }
  
  // Settings operations
  static Future<void> saveSetting(String key, dynamic value) async {
    await _settingsBox.put(key, value);
  }
  
  static dynamic getSetting(String key, {dynamic defaultValue}) {
    return _settingsBox.get(key, defaultValue: defaultValue);
  }
  
  static Future<void> deleteSetting(String key) async {
    await _settingsBox.delete(key);
  }
  
  static Map<String, dynamic> getAllSettings() {
    final Map<String, dynamic> settings = {};
    for (final key in _settingsBox.keys) {
      settings[key.toString()] = _settingsBox.get(key);
    }
    return settings;
  }
  
  // App-specific convenience methods
  
  // Authentication token
  static Future<void> saveAuthToken(String token) async {
    await setString(AppConstants.userTokenKey, token);
  }
  
  static String? getAuthToken() {
    return getString(AppConstants.userTokenKey);
  }
  
  static Future<void> clearAuthToken() async {
    await remove(AppConstants.userTokenKey);
  }
  
  // User profile
  static Future<void> saveUserProfile(Map<String, dynamic> profile) async {
    await saveUserData(AppConstants.userDataKey, profile);
  }
  
  static Map<String, dynamic>? getUserProfile() {
    return getUserData(AppConstants.userDataKey);
  }
  
  static Future<void> clearUserProfile() async {
    await deleteUserData(AppConstants.userDataKey);
  }
  
  // Language preference
  static Future<void> saveLanguage(String languageCode) async {
    await setString(AppConstants.languageKey, languageCode);
  }
  
  static String getLanguage() {
    return getString(AppConstants.languageKey) ?? 'en';
  }
  
  // Theme preference
  static Future<void> saveThemeMode(String themeMode) async {
    await setString(AppConstants.themeKey, themeMode);
  }
  
  static String getThemeMode() {
    return getString(AppConstants.themeKey) ?? 'system';
  }
  
  // First time app launch
  static Future<void> setFirstTimeLaunch(bool isFirstTime) async {
    await setBool('first_time_launch', isFirstTime);
  }
  
  static bool isFirstTimeLaunch() {
    return getBool('first_time_launch') ?? true;
  }
  
  // Onboarding completion
  static Future<void> setOnboardingCompleted(bool completed) async {
    await setBool('onboarding_completed', completed);
  }
  
  static bool isOnboardingCompleted() {
    return getBool('onboarding_completed') ?? false;
  }
  
  // Last sync timestamp
  static Future<void> saveLastSyncTime(DateTime timestamp) async {
    await setString('last_sync_time', timestamp.toIso8601String());
  }
  
  static DateTime? getLastSyncTime() {
    final timeString = getString('last_sync_time');
    return timeString != null ? DateTime.parse(timeString) : null;
  }
  
  // Offline data management
  static Future<void> saveOfflineData(String key, Map<String, dynamic> data) async {
    await _ensureHiveInitialized();
    final offlineBox = await Hive.openBox('offline_data');
    await offlineBox.put(key, data);
  }
  
  static Future<Map<String, dynamic>?> getOfflineData(String key) async {
    await _ensureHiveInitialized();
    final offlineBox = await Hive.openBox('offline_data');
    final data = offlineBox.get(key);
    return data != null ? Map<String, dynamic>.from(data) : null;
  }
  
  static Future<List<Map<String, dynamic>>> getAllOfflineData() async {
    await _ensureHiveInitialized();
    final offlineBox = await Hive.openBox('offline_data');
    return offlineBox.values
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }
  
  static Future<void> clearOfflineData() async {
    await _ensureHiveInitialized();
    final offlineBox = await Hive.openBox('offline_data');
    await offlineBox.clear();
  }
  
  // Cache management
  static Future<void> saveToCache(String key, Map<String, dynamic> data, {Duration? expiry}) async {
    await _ensureHiveInitialized();
    final cacheBox = await Hive.openBox('cache_data');
    final cacheData = {
      'data': data,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'expiry': expiry?.inMilliseconds,
    };
    await cacheBox.put(key, cacheData);
  }
  
  static Future<Map<String, dynamic>?> getFromCache(String key) async {
    await _ensureHiveInitialized();
    final cacheBox = await Hive.openBox('cache_data');
    final cacheData = cacheBox.get(key);
    
    if (cacheData == null) return null;
    
    final timestamp = cacheData['timestamp'] as int;
    final expiry = cacheData['expiry'] as int?;
    
    if (expiry != null) {
      final expiryTime = timestamp + expiry;
      if (DateTime.now().millisecondsSinceEpoch > expiryTime) {
        await cacheBox.delete(key);
        return null;
      }
    }
    
    return Map<String, dynamic>.from(cacheData['data']);
  }
  
  static Future<void> clearCache() async {
    await _ensureHiveInitialized();
    final cacheBox = await Hive.openBox('cache_data');
    await cacheBox.clear();
  }
  
  // Clear all data
  static Future<void> clearAllData() async {
    await clearPreferences();
    await _userBox.clear();
    await _vitalsBox.clear();
    await _remindersBox.clear();
    await _reportsBox.clear();
    await _settingsBox.clear();
    await clearOfflineData();
    await clearCache();
  }
  
  // Get storage statistics
  static Map<String, int> getStorageStats() {
    return {
      'userDataCount': _userBox.length,
      'vitalsCount': _vitalsBox.length,
      'remindersCount': _remindersBox.length,
      'reportsCount': _reportsBox.length,
      'settingsCount': _settingsBox.length,
    };
  }
}
