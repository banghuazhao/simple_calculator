import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesHelper {
  static SharedPreferences? localStorage;
  static Future init() async {
    localStorage = await SharedPreferences.getInstance();
  }
}

class BgmHelper {
  final String KEY = "BgmHelper_Key";

  BgmHelper._privateConstructor() {}

  static final BgmHelper instance = BgmHelper._privateConstructor();

  bool get playBgm {
    bool temp = SharedPreferencesHelper.localStorage?.getBool(KEY) ?? true;
    return temp;
  }

  set(bool playBGM) {
    SharedPreferencesHelper.localStorage?.setBool(KEY, playBGM);
  }
}
