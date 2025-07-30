import '../vstarcam/cloudplay/cloud_play_conf.dart';
import '../vstarcam/linkable_revise/linkable_revise_conf.dart';
import '../vstarcam/main/main_conf.dart';
import '../vstarcam/play/play_conf.dart';
import '../vstarcam/settings_alarm/custom_detect_time/custom_detect_time_conf.dart';
import '../vstarcam/settings_alarm/detect_area_draw/detect_area_draw_conf.dart';
import '../vstarcam/settings_alarm/settings_conf.dart';
import '../vstarcam/settings_normal/settings_normal_conf.dart';
import '../vstarcam/tf_play/tf_play_conf.dart';
import '../vstarcam/tf_settings/tf_settings_conf.dart';

class AppRoutes {
  static const settings = '/settings';
  static const main = '/main';
  static const play = '/play';
  static const cloudplay = '/cloudplay';
  static const tfPlay = '/tf_play';
  static const tfSettings = '/tf_settings';
  static const normalSetting = '/normal_setting';
  static const areaDraw = '/area_draw';
  static const linkable = '/linkable';
  static const customDetectTime = '/custom_detect_time';
}

class AppPages {
  static void disposePages() {
    MainConf.dispose();
    PlayConf.dispose();
    SettingsConf.dispose();
    CloudPlayConf.dispose();
    TFPlayConf.dispose();
    SettingsNormalConf.dispose();
    DetectAreaDrawConf.dispose();
    LinkableReviseConf.dispose();
    CustomDetectTimeConf.dispose();
    TFSettingsConf.dispose();
  }

  static final pages = [
    MainConf.getPage,
    PlayConf.getPage,
    SettingsConf.getPage,
    CloudPlayConf.getPage,
    TFPlayConf.getPage,
    SettingsNormalConf.getPage,
    DetectAreaDrawConf.getPage,
    LinkableReviseConf.getPage,
    CustomDetectTimeConf.getPage,
    TFSettingsConf.getPage,
  ];
}
