import 'package:flutter/material.dart';

class CustomBottomNavigationBar extends StatelessWidget {
  final int currentPageIndex;
  final ValueChanged<int> onPageSelected;

  const CustomBottomNavigationBar({
    Key? key,
    required this.currentPageIndex,
    required this.onPageSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings),
          label: 'Einstellungen',
        ),
        BottomNavigationBarItem(
          icon: Badge(child: Icon(Icons.info)),
          label: 'Über',
        ),
      ],
      currentIndex: currentPageIndex,
      onTap: onPageSelected,
    );
  }
}
