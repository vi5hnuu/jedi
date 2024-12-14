import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:jedi/models/file-selection-config.dart';
import 'package:jedi/pages/ErrorPage.dart';
import 'package:jedi/pages/JsonEditor.dart';
import 'package:jedi/pages/JsonViewer.dart';
import 'package:jedi/pages/SearchScreen.dart';
import 'package:jedi/pages/SplashScreen.dart';
import 'package:jedi/pages/FilesScreen.dart';
import 'package:jedi/routes.dart';
import 'package:jedi/singletons/NotificationService.dart';
import 'package:jedi/state/json-files-state/jsonFiles_bloc.dart';
import 'package:jedi/utils/Constants.dart';
import 'package:jedi/utils/StoragePermissions.dart';
import 'package:jedi/widgets/FilesListing.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    systemNavigationBarColor: Constants.green100, // Change to your desired color
    systemNavigationBarIconBrightness:Brightness.light, // Adjust icons if needed
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
        name: AppRoutes.jsonViewer.name,
        path: AppRoutes.jsonViewer.path,
        redirect: (context, state) async{
          if((state.extra is! Map<String,Object>) ||
              ((state.extra as Map<String,Object>)['file'] is! File)) {
            NotificationService.showSnackbar(text: "No Json file passed",color: Colors.red);
            return AppRoutes.errorRoute.path;
          } else if(!await ((state.extra as Map<String,Object>)['file'] as File).exists()){
            NotificationService.showSnackbar(text: "File does not exists",color: Colors.red);
            return AppRoutes.errorRoute.path;
          }
          return null;
        },
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          child: JsonViewer(jsonFile: (state.extra as Map<String,Object>)['file'] as File),
          transitionsBuilder: (context, animation, secondaryAnimation, child) => FadeTransition(opacity: animation, child: child)),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        name: AppRoutes.jsonEditor.name,
        path: AppRoutes.jsonEditor.path,
        redirect: (context, state) async{
          if((state.extra is! Map<String,Object>) ||
              ((state.extra as Map<String,Object>)['file'] is! File)) {
            NotificationService.showSnackbar(text: "No Json file passed",color: Colors.red);
            return AppRoutes.errorRoute.path;
          } else if(!await ((state.extra as Map<String,Object>)['file'] as File).exists()){
            NotificationService.showSnackbar(text: "File does not exists",color: Colors.red);
            return AppRoutes.errorRoute.path;
          }
          return null;
        },
        pageBuilder: (context, state) => CustomTransitionPage<void>(
            key: state.pageKey,
            child: JsonEditor(jsonFile: (state.extra as Map<String,Object>)['file'] as File),
            transitionsBuilder: (context, animation, secondaryAnimation, child) => FadeTransition(opacity: animation, child: child)),
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
        brightness: Brightness.light,
        // Ensures dark mode defaults
        scaffoldBackgroundColor: Constants.green100,
        // Black background
        appBarTheme: AppBarTheme(
          backgroundColor: Constants.green400,
          titleTextStyle: TextStyle(color: Constants.green100, fontSize: 20),
          iconTheme: IconThemeData(color: Constants.green100),
        ),
        textTheme: TextTheme(
          bodySmall: TextStyle(fontFamily: 'oxanium',color: Colors.black), // Primary text color
          bodyMedium: TextStyle(fontFamily: 'oxanium',color: Colors.black), // Secondary text color
          bodyLarge: TextStyle(fontFamily: 'oxanium',color: Colors.black), // AppBar title color
        ),
      ),
      routerConfig: _router,
    ));
  }
}
