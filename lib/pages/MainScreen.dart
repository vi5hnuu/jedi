import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:jedi/routes.dart';
import 'package:jedi/singletons/NotificationService.dart';

class MainScreen extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  MainScreen({
    required this.navigationShell,
    Key? key,
  }) : super(key: key ?? const ValueKey<String>('ScaffoldWithNavBar'));

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final md = MediaQuery.of(context);

    return Scaffold(
      body: widget.navigationShell,
      appBar: AppBar(
        elevation: 5,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Image.asset(
            "assets/logo.webp",
            fit: BoxFit.fitWidth,
            width: 124,
          ),
        ),
        backgroundColor: Colors.black,
        leadingWidth: 112,
        actions: [
          IconButton(onPressed: () => GoRouter.of(context).pushNamed(AppRoutes.searchRoute.name), icon: const Icon(Icons.search)),
          // Padding(
          //   padding: const EdgeInsets.only(right: 8.0, left: 16),
          //   child: CircleAvatar(child: Icon(Icons.person)),
          // )
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.shifting,
        elevation: 5,
        iconSize: 24,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              label: 'Home',
              activeIcon: Icon(Icons.home),
              tooltip: 'Home',
              backgroundColor: Colors.black),
          BottomNavigationBarItem(
              icon: Icon(Icons.folder_copy_outlined),
              label: 'Files',
              activeIcon: Icon(Icons.folder),
              tooltip: 'Files',
              backgroundColor: Colors.black),
          BottomNavigationBarItem(
              icon: Icon(Icons.build_outlined),
              label: 'Tools',
              activeIcon: Icon(Icons.build),
              tooltip: 'Tools',
              backgroundColor: Colors.black),
          BottomNavigationBarItem(
              icon: Icon(Icons.document_scanner_outlined),
              label: 'Scanner',
              activeIcon: Icon(Icons.document_scanner),
              tooltip: 'Scanner',
              backgroundColor: Colors.black),
          BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              label: 'Settings',
              activeIcon: Icon(Icons.settings),
              tooltip: 'Settings',
              backgroundColor: Colors.black),
        ],
        currentIndex: widget.navigationShell.currentIndex,
        onTap: _onTap,
      ),
    );
  }

  void _onTap(int index) {
    if(index==0 || index==4){
     NotificationService.showSnackbar(text: "Comming soon",color: Colors.green);
     return;
    }
    widget.navigationShell.goBranch(index,
        initialLocation: index == widget.navigationShell.currentIndex);
  }
}
