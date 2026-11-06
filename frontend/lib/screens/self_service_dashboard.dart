import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import 'dashboard_components.dart';

class SelfServiceDashboard extends StatefulWidget {
  const SelfServiceDashboard({
    super.key,
    required this.roleLabel,
    this.canReviewRequests = false,
  });

  final String roleLabel;
  final bool canReviewRequests;

  @override
  State<SelfServiceDashboard> createState() => _SelfServiceDashboardState();
}

class _SelfServiceDashboardState extends State<SelfServiceDashboard> {
  int _selectedIndex = 0;

  static const _titles = ['Presensi', 'Pengajuan', 'Profil'];
  static const _icons = [Icons.access_time, Icons.event_note, Icons.person];

  Future<void> _logout() async {
    await context.read<AuthProvider>().logout();
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final pages = [
      AttendancePanel(api: auth.api),
      RequestsPanel(api: auth.api, canReview: widget.canReviewRequests),
      ProfilePanel(api: auth.api),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('LookIn · ${widget.roleLabel}'),
        actions: [
          IconButton(
            tooltip: 'Keluar',
            onPressed: _logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: IndexedStack(index: _selectedIndex, children: pages),
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
        destinations: List.generate(
          _titles.length,
          (index) => NavigationDestination(
            icon: Icon(_icons[index]),
            label: _titles[index],
          ),
        ),
      ),
    );
  }
}
