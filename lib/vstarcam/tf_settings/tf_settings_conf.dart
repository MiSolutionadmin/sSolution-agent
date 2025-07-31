import 'package:get/get.dart';
import 'package:flutter/material.dart';
// import 'package:ssolution_mms/tf_settings/tf_settings_bind.dart';
// import 'package:ssolution_mms/tf_settings/tf_settings_page.dart';

// import '../app_routes.dart';
import '../../routes/app_routes.dart';
import 'tf_settings_bind.dart';
import 'tf_settings_page.dart';

class TFSettingsConf {
  static final GetPage getPage = GetPage(
      name: AppRoutes.tfSettings,
      page: () => TFSettingsPage(),
      binding: TFSettingsBind());

  static GetPageRoute? _pageRoute;

  /// 用于代码进行页面导航
  /// `Get.to()`
  static Widget getWidget(BuildContext context) {
    if (_pageRoute == null) {
      _pageRoute = getPage.createRoute(context) as GetPageRoute?;
    }
    return _pageRoute?.buildPage(context, _pageRoute!.createAnimation(),
            _pageRoute!.createAnimation()) ??
        Container();
  }

  static void dispose() {
    // _pageRoute?.dispose();
    _pageRoute = null;
  }
}
