import 'package:get/get.dart';

import '../modules/about/bindings/about_binding.dart';
import '../modules/about/views/about_view.dart';
import '../modules/blog/bindings/blog_binding.dart';
import '../modules/blog/views/blog_view.dart';
import '../modules/bottom_navigationbar/bindings/bottom_navigationbar_binding.dart';
import '../modules/bottom_navigationbar/views/bottom_navigationbar_view.dart';
import '../modules/crossing/bindings/crossing_binding.dart';
import '../modules/crossing/views/crossing_view.dart';
import '../modules/crossing_detail/bindings/crossing_detail_binding.dart';
import '../modules/crossing_detail/views/crossing_detail_view.dart';
import '../modules/login/bindings/login_binding.dart';
import '../modules/login/views/login_view.dart';
import '../modules/news/bindings/news_binding.dart';
import '../modules/news/views/news_view.dart';
import '../modules/register/bindings/register_binding.dart';
import '../modules/register/views/register_view.dart';
import '../modules/setting/bindings/setting_binding.dart';
import '../modules/setting/views/setting_view.dart';
import '../modules/splash/controllers/splash_controller.dart';
import '../modules/splash/views/splash_view.dart';

part 'app_routes.dart';

class AppPages {
  AppPages._();

  static const INITIAL = Routes.HOME;

  static final routes = [
    GetPage(
      name: _Paths.SPLASH,
      page: () => const SplashView(),
      binding: BindingsBuilder(() {
        Get.put(SplashController());
      }),
    ),
    GetPage(
      name: _Paths.LOGIN,
      page: () => const LoginView(),
      binding: LoginBinding(),
    ),
    GetPage(
      name: _Paths.REGISTER,
      page: () => const RegisterView(),
      binding: RegisterBinding(),
    ),
    GetPage(
      name: _Paths.CROSSING,
      page: () => CrossingView(),
      binding: CrossingBinding(),
    ),
    GetPage(
      name: _Paths.CROSSING_DETAIL,
      page: () => const CrossingDetailView(),
      binding: CrossingDetailBinding(),
    ),
    GetPage(
      name: _Paths.BOTTOM_NAVIGATIONBAR,
      page: () => const BottomNavigationbarView(),
      binding: BottomNavigationbarBinding(),
    ),
    GetPage(
      name: _Paths.SETTING,
      page: () => const SettingView(),
      binding: SettingBinding(),
    ),
    GetPage(
      name: _Paths.ABOUT,
      page: () => const AboutView(),
      binding: AboutBinding(),
    ),
    GetPage(
      name: _Paths.NEWS,
      page: () => const NewsView(),
      binding: NewsBinding(),
    ),
    GetPage(
      name: _Paths.BLOG,
      page: () => const BlogView(),
      binding: BlogBinding(),
    ),
  ];
}
