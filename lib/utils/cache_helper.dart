import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CacheHelper {
  static const String dataKey = "TALEBE_CACHE";
  static const String timeKey = "TALEBE_CACHE_TIME";

  static const Duration cacheDuration = Duration(seconds: 10);

  static Future<void> save(List<Map<String, String>> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(dataKey, jsonEncode(data));
    await prefs.setInt(timeKey, DateTime.now().millisecondsSinceEpoch);
  }

  static Future<List<Map<String, String>>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(dataKey);
    if (jsonString == null) return [];

    final decoded = jsonDecode(jsonString) as List;
    return decoded.map((e) => Map<String, String>.from(e)).toList();
  }

  static Future<bool> isExpired() async {
    final prefs = await SharedPreferences.getInstance();
    final time = prefs.getInt(timeKey);
    if (time == null) return true;

    final last = DateTime.fromMillisecondsSinceEpoch(time);
    if (DateTime.now().difference(last) > cacheDuration){
      print("expired " + DateTime.now().toString());
      return true;
    }
    else{
      print("not expired " + DateTime.now().toString());
      return false;
    }
  }
}
