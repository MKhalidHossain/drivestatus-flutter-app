import 'package:flutter/material.dart';
import 'package:flutter_bighustle/moduls/license/presentation/screen/license_screen.dart';
import 'package:flutter_bighustle/moduls/profile/presentation/screen/profile_screen.dart';
import 'package:flutter_bighustle/moduls/ticket/presentation/screen/ticket_screen.dart';
import 'home_screen.dart';

class BottomNavScreen extends StatefulWidget {
  const BottomNavScreen({super.key});

  @override
  State<BottomNavScreen> createState() => _BottomNavScreenState();
}

class _BottomNavScreenState extends State<BottomNavScreen> {
  int _selectedIndex = 0;
  late final List<Widget> _pages = const [
    HomeScreen(),
    LicenseScreen(),
    TicketScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        backgroundColor: const Color(0xFF121212),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        type: BottomNavigationBarType.fixed,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),

          /// 🔥 IMAGE ICON USED HERE (ONLY CHANGE)
          BottomNavigationBarItem(
            icon: Image.asset(
              'assets/images/clarity_license-outline-badged.png',
              width: 24,
              height: 24,
              color: _selectedIndex == 1 ? Colors.white : Colors.white70,
            ),
            label: 'License',
          ),

          const BottomNavigationBarItem(
            icon: Icon(Icons.confirmation_number_outlined),
            label: 'Ticket',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
