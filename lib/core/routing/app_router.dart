import 'package:flutter/material.dart';
import 'package:gold_signal/dashboard/mainpage.dart';
import '../../dashboard/pages/account_page.dart';
import '../../dashboard/pages/dashboard_page.dart';
import '../../dashboard/pages/portfolio_page.dart';
import '../../dashboard/pages/setting_page.dart';
import '../../dashboard/pages/add_trade.dart';

class AppRouter {
  static const String dashboard = '/';
  static const String account = '/account';
  static const String portfolio = '/portfolio';
  static const String settings = '/settings';
  static const String addTrade = '/addTrade';
  static final delegate = _SimpleRouterDelegate();
  static final parser = _SimpleRouteParser();
}

class _SimpleRouterDelegate extends RouterDelegate<Uri>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<Uri> {
  @override
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  Uri _currentUri = Uri(path: '/');

  // Add navigation logic here to update _currentUri based on user interactions
  void navigateTo(String path) {
    _currentUri = Uri(path: path);
    notifyListeners();
  }

  @override
  Widget build(BuildContext context) {
    List<Page> pages = [];
    switch (_currentUri.path) {
      case AppRouter.dashboard:
        pages.add(const MaterialPage(
            child: MainPage(selectedIndex: 0, child: DashboardPage())));
        break;
      case AppRouter.account:
        pages.add(const MaterialPage(
            child: MainPage(
                selectedIndex: 1,
                child: AccountPage()))); // Replace with AccountPage()
        break;
      case AppRouter.addTrade:
        pages.add(const MaterialPage(
            child: MainPage(selectedIndex: 2, child: AddTrade())));
        break;
      case AppRouter.portfolio:
        pages.add(const MaterialPage(
            child: MainPage(
                selectedIndex: 3,
                child: PortfolioPage()))); // Replace with PortfolioPage()
        break;
      case AppRouter.settings:
        pages.add(const MaterialPage(
            child: MainPage(
                selectedIndex: 4,
                child: SettingsPage()))); // Replace with SettingsPage()
        break;

      default:
        pages.add(const MaterialPage(
            child: MainPage(
                selectedIndex: 0, child: DashboardPage()))); // Fallback
    }
    return Navigator(
      pages: pages,
      key: navigatorKey,
      // ignore: deprecated_member_use
      onPopPage: (route, result) {
        if (!route.didPop(result)) {
          return false;
        }
        // Handle back navigation if needed
        if (_currentUri.path != AppRouter.dashboard) {
          _currentUri = Uri(path: AppRouter.dashboard);
          notifyListeners();
        }
        return true;
      },
    );
  }

  @override
  Future<void> setNewRoutePath(configuration) async {
    _currentUri = configuration.path.isEmpty
        ? Uri(path: AppRouter.dashboard)
        : configuration;
  }
}

class _SimpleRouteParser extends RouteInformationParser<Uri> {
  @override
  Future<Uri> parseRouteInformation(RouteInformation routeInformation) async {
    return routeInformation.uri;
  }

  @override
  RouteInformation restoreRouteInformation(Uri configuration) {
    return RouteInformation(uri: configuration);
  }
}
