import 'package:flutter/material.dart';
import '../../core/constants.dart';
import 'asha_dashboard_screen.dart';
import '../health_feed_screen.dart';
import '../chat_list_screen.dart';
import 'asha_patients_screen.dart';
import 'asha_profile_screen.dart';

class ASHAMainScreen extends StatefulWidget {
  const ASHAMainScreen({super.key});

  @override
  State<ASHAMainScreen> createState() => _ASHAMainScreenState();
}

class _ASHAMainScreenState extends State<ASHAMainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const ASHADashboardScreen(),
    const HealthFeedScreen(),
    const ChatListScreen(),
    const ASHAPatientsScreen(),
    const ASHAProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.1, 0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
        child: _pages[_selectedIndex],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            selectedItemColor: const Color(0xFF059669),
            unselectedItemColor: const Color(0xFF64748B),
            currentIndex: _selectedIndex,
            elevation: 0,
            selectedFontSize: 12,
            unselectedFontSize: 12,
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w500,
            ),
            onTap: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            items: [
              BottomNavigationBarItem(
                icon: _buildNavIcon(Icons.dashboard_outlined, Icons.dashboard, 0),
                label: 'Dashboard',
              ),
              BottomNavigationBarItem(
                icon: _buildNavIcon(Icons.article_outlined, Icons.article, 1),
                label: 'Health Feed',
              ),
              BottomNavigationBarItem(
                icon: _buildNavIcon(Icons.chat_bubble_outline, Icons.chat_bubble, 2),
                label: 'Chat',
              ),
              BottomNavigationBarItem(
                icon: _buildNavIcon(Icons.people_outline, Icons.people, 3),
                label: 'Patients',
              ),
              BottomNavigationBarItem(
                icon: _buildNavIcon(Icons.person_outline, Icons.person, 4),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavIcon(IconData outlineIcon, IconData filledIcon, int index) {
    final isSelected = _selectedIndex == index;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: EdgeInsets.all(isSelected ? 8 : 4),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF059669).withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        isSelected ? filledIcon : outlineIcon,
        size: isSelected ? 24 : 20,
      ),
    );
  }
}