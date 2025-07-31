import 'package:mms/utils/device_manager.dart';
// import 'package:vsdk_example/utils/device_manager.dart';

class Manager {
  /// 单例
  static Manager? _instance;

  /// 将构造函数指向单例
  factory Manager() => getIns();

  ///获取单例
  static Manager getIns() {
    if (_instance == null) {
      _instance = new Manager._internal();
    }
    return _instance!;
  }

  Map<String, DeviceManager> deviceMap = {};
  String currentUid = "";

  setDeviceMap(String uid, DeviceManager manager) {
    deviceMap[uid] = manager;
  }

  DeviceManager? getDeviceManager({String id = ""}) {
    String uid = "";
    if (id.length == 0) {
      uid = getCurrentUid();
    } else {
      uid = id;
    }
    if (uid.length == 0) return null;
    if (deviceMap.containsKey(uid)) {
      return deviceMap[uid];
    } else {
      setDeviceMap(uid, DeviceManager());
      return deviceMap[uid];
    }
  }

  setCurrentUid(String uid) {
    currentUid = uid;
  }

  getCurrentUid() {
    return currentUid;
  }

  Manager._internal() {
    deviceMap.clear();
    currentUid = "";
  }
}
