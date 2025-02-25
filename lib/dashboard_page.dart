import 'package:admin_app/language.dart';
import 'package:admin_app/manage_company.dart';
import 'package:admin_app/soft_skill.dart';
import 'package:admin_app/technical_skill.dart';
import 'package:admin_app/view_user.dart';
import 'package:flutter/material.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;
  static const List<Widget> _widgetOptions = <Widget>[
    InsertLanguagePage(),
    InsertSoftSkillPage(),
    InsertTechnicalSkillPage(),
    ViewUsersPage(),
    ViewCompaniesPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
      ),
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: _onItemTapped,
            labelType: NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.language),
                label: Text('Languages'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.psychology),
                label: Text('Soft Skills'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.code),
                label: Text('Technical Skills'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.people),
                label: Text('Users'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.business),
                label: Text('Companies'),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: Center(
              child: _widgetOptions.elementAt(_selectedIndex),
            ),
          ),
        ],
      ),
    );
  }
}

