class AppRoute{
  final String name;
  final String path;//relative
  AppRoute({required this.name,required this.path});
}

class AppRoutes{
  static AppRoute splashRoute=AppRoute(name: 'splash', path: '/splash');

  static AppRoute errorRoute=AppRoute(name: 'error', path: '/error');

  static AppRoute searchRoute=AppRoute(name: 'search', path: '/search');

  static AppRoute homeRoute=AppRoute(name: 'home', path: '/');
  static AppRoute jsonViewer=AppRoute(name: 'json-preview', path: '/json-preview');
  static AppRoute jsonEditor=AppRoute(name: 'json-editor', path: '/json-editor');

  static AppRoute filesRoute=AppRoute(name: 'files', path: '/files');
  static AppRoute filesListingRoute=AppRoute(name: 'list', path: 'list');
}