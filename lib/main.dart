import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:jedi/models/file-selection-config.dart';
import 'package:jedi/pages/ErrorPage.dart';
import 'package:jedi/pages/MainScreen.dart';
import 'package:jedi/pages/SearchScreen.dart';
import 'package:jedi/pages/SplashScreen.dart';
import 'package:jedi/pages/tab-widgets/FilesScreen.dart';
import 'package:jedi/pages/tab-widgets/HomeScreen.dart';
import 'package:jedi/routes.dart';
import 'package:jedi/singletons/NotificationService.dart';
import 'package:jedi/state/json-files-state/jsonFiles_bloc.dart';
import 'package:jedi/utils/StoragePermissions.dart';
import 'package:jedi/widgets/FilesListing.dart';
import 'package:jedi/widgets/FilesManagement.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _homeNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'home');
final GlobalKey<NavigatorState> _filesNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'files');
final GlobalKey<NavigatorState> _toolsNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'tools');
final GlobalKey<NavigatorState> _scannerNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'scanner');
final GlobalKey<NavigatorState> _settingsNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'settings');

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    systemNavigationBarColor: Colors.black, // Change to your desired color
    systemNavigationBarIconBrightness:
        Brightness.light, // Adjust icons if needed
  ));
  runApp(NestedTabNavigationExampleApp());
}

class NestedTabNavigationExampleApp extends StatelessWidget {
  NestedTabNavigationExampleApp({super.key});

  final GoRouter _router = GoRouter(
    debugLogDiagnostics: true,
    navigatorKey: _rootNavigatorKey, //navigator = 1
    initialLocation: AppRoutes.splashRoute.path,
    redirect: (context, state) async {
      final granted=await StoragePermissions.isStoragePermissionGranted();
      if(granted) return null;
      return AppRoutes.errorRoute.path;
    },
    routes: [
      GoRoute(
        name: AppRoutes.splashRoute.name,
        path: AppRoutes.splashRoute.path,
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          child: const SplashScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        name: AppRoutes.errorRoute.name,
        path: AppRoutes.errorRoute.path,
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          child: Errorpage(reason: state.extra is Map<String,Object> ? ((state.extra as Map)['reason'] ?? ErrorReason.STORAGE_PERMISSION_DENIED) : ErrorReason.STORAGE_PERMISSION_DENIED,),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        name: AppRoutes.searchRoute.name,
        path: AppRoutes.searchRoute.path,
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          child: SearchScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      ),
      GoRoute(
        redirect: (context, state) {
          if(state.extra is! FileSelectionConfig) return AppRoutes.errorRoute.path;
        },
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.fileManagement.path,
        name: AppRoutes.fileManagement.name,
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          child: FilesManagement(config: state.extra as FileSelectionConfig),
          transitionsBuilder: (context, animation, secondaryAnimation, child) => FadeTransition(opacity: animation, child: child),
        ),
      ),
      StatefulShellRoute.indexedStack(
        parentNavigatorKey: _rootNavigatorKey,
        builder: (BuildContext context, GoRouterState state,
            StatefulNavigationShell navigationShell) {
          return MainScreen(navigationShell: navigationShell);
        },
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            navigatorKey: _homeNavigatorKey,
            routes: <RouteBase>[
              GoRoute(
                // The screen to display as the root in the first tab of the
                // bottom navigation bar.
                path: AppRoutes.homeRoute.path,
                name: AppRoutes.homeRoute.name,
                builder: (BuildContext context, GoRouterState state) =>
                    const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _filesNavigatorKey,
            initialLocation: AppRoutes.filesRoute.path,
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.filesRoute.path,
                name: AppRoutes.filesRoute.name,
                builder: (BuildContext context, GoRouterState state) => const FilesScreen(),
                routes: [
                  GoRoute(
                    path: AppRoutes.filesListingRoute.path,
                    name: AppRoutes.filesListingRoute.name,
                    pageBuilder: (context, state){
                      final config=state.extra as FileSelectionConfig;
                      return CustomTransitionPage<void>(
                        key: state.pageKey,
                        child: FilesListing(config: config),
                        transitionsBuilder: (context, animation, secondaryAnimation, child) => FadeTransition(opacity: animation, child: child),
                      );
                    },
                  ),
                ]
              ),
            ],
          ),
        ],
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(providers: [
      BlocProvider(lazy: true,create: (context) => JsonFilesBloc()),
    ], child: MaterialApp.router(
      scaffoldMessengerKey: NotificationService.messengerKey,
      title: 'Pdf craft',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        canvasColor: Colors.white,
        brightness: Brightness.dark,
        // Ensures dark mode defaults
        scaffoldBackgroundColor: Colors.black,
        // Black background
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.black,
          titleTextStyle: TextStyle(color: Colors.white, fontSize: 20),
          iconTheme: IconThemeData(color: Colors.white),
        ),
        textTheme: TextTheme(
          bodySmall: TextStyle(color: Colors.white), // Primary text color
          bodyMedium: TextStyle(color: Colors.white), // Secondary text color
          bodyLarge: TextStyle(color: Colors.white), // AppBar title color
        ),
      ),
      routerConfig: _router,
    ));
  }
}
