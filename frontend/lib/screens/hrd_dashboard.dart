import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import 'dashboard_components.dart';

class HrdDashboard extends StatefulWidget {
  const HrdDashboard({super.key, this.api});

  final ApiService? api;

  @override
  State<HrdDashboard> createState() => _HrdDashboardState();
}

class _HrdDashboardState extends State<HrdDashboard> {
  static const _titles = ['Home', 'Persetujuan', 'Laporan', 'Profil'];
  static const _icons = [
    Icons.home_outlined,
    Icons.fact_check_outlined,
    Icons.bar_chart_outlined,
    Icons.person_outline,
  ];

  late final ApiService _api;
  int _selectedIndex = 0;
  bool _editingProfile = false;
  Map<String, dynamic> _profile = {};
  Map<String, dynamic> _dashboard = {};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _api = widget.api ?? context.read<AuthProvider>().api;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadOverview();
    });
  }

  Future<void> _loadOverview() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await Future.wait<Map<String, dynamic>>([
        _api.profile(),
        _api.hrdDashboard(),
      ]);
      if (!mounted) return;
      setState(() {
        _profile = result[0];
        _dashboard = result[1];
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = ApiService.errorMessage(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _logout() async {
    await context.read<AuthProvider>().logout();
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
    }
  }

  Widget _overview() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 40),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _loadOverview,
                icon: const Icon(Icons.refresh),
                label: const Text('Coba lagi'),
              ),
            ],
          ),
        ),
      );
    }
    return HrdHomePanel(
      profile: _profile,
      dashboard: _dashboard,
      onRefresh: _loadOverview,
      onSeeRequests: () => setState(() => _selectedIndex = 1),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _overview(),
      HrdApprovalsPanel(api: _api, onChanged: _loadOverview),
      HrdReportPanel(api: _api, dashboard: _dashboard),
      _editingProfile
          ? ProfilePanel(
              key: const ValueKey('hrd-profile-editor'),
              api: _api,
            )
          : HrdProfilePanel(
              api: _api,
              onEdit: () => setState(() => _editingProfile = true),
              onLogout: _logout,
            ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF1F1F1),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF1F1F1),
        surfaceTintColor: const Color(0xFFF1F1F1),
        titleSpacing: 18,
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.fingerprint, color: Color(0xFF1769FF), size: 25),
            SizedBox(width: 5),
            Text(
              'LookIn',
              style: TextStyle(
                color: Color(0xFF17191D),
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        actions: [
          if (_selectedIndex == 3 && _editingProfile)
            IconButton(
              tooltip: 'Kembali ke profil',
              onPressed: () => setState(() => _editingProfile = false),
              icon: const Icon(Icons.close),
            ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: IndexedStack(index: _selectedIndex, children: pages),
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFFE7F0FF),
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
            if (index != 3) _editingProfile = false;
          });
        },
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

class HrdApprovalsPanel extends StatefulWidget {
  const HrdApprovalsPanel({
    super.key,
    required this.api,
    required this.onChanged,
  });

  final ApiService api;
  final Future<void> Function() onChanged;

  @override
  State<HrdApprovalsPanel> createState() => _HrdApprovalsPanelState();
}

class _HrdApprovalsPanelState extends State<HrdApprovalsPanel> {
  List<Map<String, dynamic>> _requests = [];
  bool _loading = true;
  String? _error;
  String? _savingId;

  List<Map<String, dynamic>> get _pending => _requests
      .where((request) => request['status'] == 'pending')
      .toList();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final requests = await widget.api.requests();
      if (mounted) setState(() => _requests = requests);
    } catch (error) {
      if (mounted) setState(() => _error = ApiService.errorMessage(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _showDetails(
    Map<String, dynamic> item, {
    String? requestedDecision,
  }) async {
    final noteController = TextEditingController();
    final decision = await showDialog<String>(
      context: context,
      builder: (context) {
        final user = item['user'];
        final userName = user is Map
            ? user['name']?.toString() ?? 'Karyawan'
            : 'Karyawan';
        final type = item['type']?.toString() ?? '';
        final start = _approvalDate(item['start_date']);
        final end = _approvalDate(item['end_date']);
        final createdAt = DateTime.tryParse(
          item['created_at']?.toString() ?? '',
        );

        return AlertDialog(
          title: Text(
            requestedDecision == null
                ? 'Detail Pengajuan'
                : requestedDecision == 'approved'
                ? 'Setujui pengajuan?'
                : 'Tolak pengajuan?',
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    child: Text(userName.isEmpty ? '?' : userName[0]),
                  ),
                  title: Text(userName),
                  subtitle: Text(_approvalType(type)),
                ),
                const Divider(),
                _ApprovalDetailRow(
                  label: 'Tanggal',
                  value: end.isEmpty || end == start ? start : '$start – $end',
                ),
                if (type == 'lembur') ...[
                  _ApprovalDetailRow(
                    label: 'Durasi',
                    value:
                        '${item['start_time'] ?? '--:--'} – ${item['end_time'] ?? '--:--'}',
                  ),
                ],
                _ApprovalDetailRow(
                  label: 'Diajukan',
                  value: createdAt == null
                      ? '—'
                      : '${_approvalDate(createdAt.toIso8601String())}, ${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}',
                ),
                _ApprovalDetailRow(
                  label: 'Alasan',
                  value: item['reason']?.toString() ?? '—',
                ),
                const SizedBox(height: 8),
                const Text(
                  'Lampiran',
                  style: TextStyle(
                    color: Color(0xFF667085),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                const Text('Tidak ada lampiran pada pengajuan ini.'),
                const SizedBox(height: 14),
                TextField(
                  controller: noteController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Catatan HRD (opsional)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tutup'),
            ),
            if (requestedDecision == null) ...[
              OutlinedButton(
                onPressed: () => Navigator.pop(context, 'rejected'),
                style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Tolak'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, 'approved'),
                child: const Text('Setujui'),
              ),
            ] else
              FilledButton(
                onPressed: () =>
                    Navigator.pop(context, requestedDecision),
                style: requestedDecision == 'rejected'
                    ? FilledButton.styleFrom(backgroundColor: Colors.red)
                    : null,
                child: Text(
                  requestedDecision == 'approved' ? 'Setujui' : 'Tolak',
                ),
              ),
          ],
        );
      },
    );
    final note = noteController.text.trim();
    noteController.dispose();

    if (decision == null) return;
    await _decide(item, decision, note);
  }

  Future<void> _decide(
    Map<String, dynamic> item,
    String status,
    String note,
  ) async {
    final id = item['id']?.toString();
    if (id == null) {
      _message('ID pengajuan tidak tersedia.', isError: true);
      return;
    }
    setState(() => _savingId = id);
    try {
      final result = await widget.api.decideRequest(id, {
        'status': status,
        'reviewer_note': note,
      });
      if (!mounted) return;
      _message(result['message']?.toString() ?? 'Keputusan tersimpan.');
      await _load();
      await widget.onChanged();
    } catch (error) {
      if (mounted) _message(ApiService.errorMessage(error), isError: true);
    } finally {
      if (mounted) setState(() => _savingId = null);
    }
  }

  void _message(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Theme.of(context).colorScheme.error : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pending = _pending;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Text(
            'Persetujuan',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            '${pending.length} pengajuan menunggu',
            style: const TextStyle(color: Color(0xFF7C8798)),
          ),
          const SizedBox(height: 12),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            Card(
              child: ListTile(
                leading: const Icon(Icons.error_outline, color: Colors.red),
                title: Text(_error!),
                trailing: IconButton(
                  tooltip: 'Coba lagi',
                  onPressed: _load,
                  icon: const Icon(Icons.refresh),
                ),
              ),
            )
          else if (pending.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text('Tidak ada pengajuan yang menunggu persetujuan.'),
              ),
            )
          else
            ...pending.map(_requestCard),
        ],
      ),
    );
  }

  Widget _requestCard(Map<String, dynamic> item) {
    final user = item['user'];
    final name = user is Map
        ? user['name']?.toString() ?? 'Karyawan'
        : 'Karyawan';
    final email = user is Map ? user['email']?.toString() ?? '' : '';
    final type = item['type']?.toString() ?? '';
    final start = _approvalDate(item['start_date']);
    final end = _approvalDate(item['end_date']);
    final dateRange = end.isEmpty || end == start ? start : '$start – $end';
    final id = item['id']?.toString();

    return Card(
      color: Colors.white,
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFFE0EDFF),
                  foregroundColor: const Color(0xFF2460D9),
                  child: Text(name.isEmpty ? '?' : name[0].toUpperCase()),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        email,
                        style: const TextStyle(
                          color: Color(0xFF7C8798),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                _RequestTypeBadge(type: type),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '$dateRange${type == 'lembur' ? ' · ${item['start_time'] ?? ''}–${item['end_time'] ?? ''}' : ''}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              item['reason']?.toString() ?? '',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xFF667085), fontSize: 13),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: id != null && id == _savingId
                        ? null
                        : () => _showDetails(item),
                    child: const Text('Detail'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: id != null && id == _savingId
                        ? null
                        : () => _showDetails(
                            item,
                            requestedDecision: 'rejected',
                          ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                    child: const Text('Tolak'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    onPressed: id != null && id == _savingId
                        ? null
                        : () => _showDetails(
                            item,
                            requestedDecision: 'approved',
                          ),
                    child: const Text('Setujui'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ApprovalDetailRow extends StatelessWidget {
  const _ApprovalDetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Color(0xFF7C8798), fontSize: 12),
        ),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    ),
  );
}

class _RequestTypeBadge extends StatelessWidget {
  const _RequestTypeBadge({required this.type});

  final String type;

  @override
  Widget build(BuildContext context) {
    final color = switch (type) {
      'sakit' => const Color(0xFF7B3FB4),
      'cuti' => const Color(0xFF2460D9),
      'lembur' => const Color(0xFFB05A00),
      _ => const Color(0xFF18734A),
    };
    final background = switch (type) {
      'sakit' => const Color(0xFFF0E2FA),
      'cuti' => const Color(0xFFE0EDFF),
      'lembur' => const Color(0xFFFFE9CF),
      _ => const Color(0xFFDDF5E8),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _approvalType(type),
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}

String _approvalType(String type) => switch (type) {
  'cuti' => 'Cuti',
  'izin' => 'Izin',
  'sakit' => 'Sakit',
  'lembur' => 'Lembur',
  _ => 'Pengajuan',
};

String _approvalDate(dynamic value) {
  final date = DateTime.tryParse(value?.toString() ?? '');
  if (date == null) return '';
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}

class HrdProfilePanel extends StatefulWidget {
  const HrdProfilePanel({
    super.key,
    required this.api,
    required this.onEdit,
    required this.onLogout,
  });

  final ApiService api;
  final VoidCallback onEdit;
  final VoidCallback onLogout;

  @override
  State<HrdProfilePanel> createState() => _HrdProfilePanelState();
}

class _HrdProfilePanelState extends State<HrdProfilePanel> {
  Map<String, dynamic> _profile = {};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final profile = await widget.api.profile();
      if (mounted) setState(() => _profile = profile);
    } catch (error) {
      if (mounted) setState(() => _error = ApiService.errorMessage(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    final name = _profile['name']?.toString() ?? 'HRD';
    final email = _profile['email']?.toString() ?? '';

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 26, 20, 24),
      children: [
        Center(
          child: Column(
            children: [
              CircleAvatar(
                radius: 52,
                backgroundColor: const Color(0xFFE0EDFF),
                foregroundColor: const Color(0xFF2460D9),
                child: Text(
                  name.isEmpty ? '?' : name[0].toUpperCase(),
                  style: const TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                name,
                style: const TextStyle(
                  color: Color(0xFF1769FF),
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                email,
                style: const TextStyle(
                  color: Color(0xFF7C8798),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: 240,
                child: FilledButton(
                  onPressed: widget.onEdit,
                  child: const Text('Edit Profil'),
                ),
              ),
            ],
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          ListTile(
            leading: const Icon(Icons.error_outline, color: Colors.red),
            title: Text(_error!),
            trailing: IconButton(
              tooltip: 'Coba lagi',
              onPressed: _load,
              icon: const Icon(Icons.refresh),
            ),
          ),
        ],
        const SizedBox(height: 24),
        Card(
          color: Colors.white,
          child: Column(
            children: [
              ListTile(
                title: const Text('My Profile'),
                trailing: const Icon(Icons.chevron_right),
                onTap: widget.onEdit,
              ),
              const Divider(height: 1),
              const ListTile(
                title: Text('Settings'),
                trailing: Icon(Icons.chevron_right),
              ),
              const Divider(height: 1),
              const ListTile(
                title: Text('Syarat & Ketentuan'),
                trailing: Icon(Icons.chevron_right),
              ),
              const Divider(height: 1),
              const ListTile(
                title: Text('Kebijakan Privasi'),
                trailing: Icon(Icons.chevron_right),
              ),
              const Divider(height: 1),
              ListTile(
                title: const Text('Log out'),
                trailing: const Icon(Icons.chevron_right),
                onTap: widget.onLogout,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class HrdHomePanel extends StatelessWidget {
  const HrdHomePanel({
    super.key,
    required this.profile,
    required this.dashboard,
    required this.onRefresh,
    required this.onSeeRequests,
  });

  final Map<String, dynamic> profile;
  final Map<String, dynamic> dashboard;
  final Future<void> Function() onRefresh;
  final VoidCallback onSeeRequests;

  @override
  Widget build(BuildContext context) {
    final summary = dashboard['summary'] is Map
        ? Map<String, dynamic>.from(dashboard['summary'] as Map)
        : <String, dynamic>{};
    final notifications = dashboard['notifications'] is List
        ? (dashboard['notifications'] as List)
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList()
        : <Map<String, dynamic>>[];
    final employees = _count(summary['employee_count']);
    final present = _count(summary['present_count']);
    final rate = employees == 0 ? 0.0 : (present / employees).clamp(0.0, 1.0);
    final now = DateTime.now();

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(10, 4, 10, 24),
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 24,
                backgroundColor: Colors.white,
                child: Icon(Icons.person, size: 30, color: Color(0xFF17191D)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_greeting(now.hour)}, ${profile['name'] ?? 'HRD'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF1769FF),
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Divisi SDM',
                      style: TextStyle(color: Color(0xFF7C8798), fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _formattedDate(now),
            style: const TextStyle(color: Color(0xFF00BCEB), fontSize: 13),
          ),
          const SizedBox(height: 3),
          _AttendanceSummaryCard(
            employeeCount: employees,
            presentCount: present,
            rate: rate,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _MetricCard(
                label: 'Cuti',
                count: _count(summary['active_cuti_count']),
                color: const Color(0xFF2855D9),
              ),
              const SizedBox(width: 8),
              _MetricCard(
                label: 'Sakit',
                count: _count(summary['active_sakit_count']),
                color: const Color(0xFF761ACB),
              ),
              const SizedBox(width: 8),
              _MetricCard(
                label: 'Menunggu',
                count: _count(summary['pending_request_count']),
                color: const Color(0xFFF28A00),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Notifikasi terbaru',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
              ),
              TextButton(
                onPressed: onSeeRequests,
                child: const Text(
                  'Lihat semua',
                  style: TextStyle(
                    color: Color(0xFF1769FF),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          if (notifications.isEmpty)
            const Card(
              color: Colors.white,
              child: Padding(
                padding: EdgeInsets.all(14),
                child: Text(
                  'Belum ada notifikasi pengajuan.',
                  style: TextStyle(color: Color(0xFF667085), fontSize: 13),
                ),
              ),
            )
          else
            ...notifications.map(
              (item) => _NotificationCard(item: item, onTap: onSeeRequests),
            ),
        ],
      ),
    );
  }
}

class _AttendanceSummaryCard extends StatelessWidget {
  const _AttendanceSummaryCard({
    required this.employeeCount,
    required this.presentCount,
    required this.rate,
  });

  final int employeeCount;
  final int presentCount;
  final double rate;

  @override
  Widget build(BuildContext context) => Card(
    color: Colors.white,
    elevation: 3,
    shadowColor: Colors.black26,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    margin: EdgeInsets.zero,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 11),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Total karyawan',
                  style: TextStyle(fontSize: 13, color: Color(0xFF17191D)),
                ),
              ),
              const Text(
                'Hadir hari ini',
                style: TextStyle(fontSize: 13, color: Color(0xFF17191D)),
              ),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  '$employeeCount',
                  style: const TextStyle(
                    height: 1.05,
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '$presentCount',
                style: const TextStyle(
                  height: 1.05,
                  color: Color(0xFF176522),
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: LinearProgressIndicator(
              value: rate,
              minHeight: 10,
              backgroundColor: const Color(0xFF92949A),
              color: const Color(0xFF293FDB),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${(rate * 100).round()}% karyawan sudah hadir',
            style: const TextStyle(fontSize: 12, color: Color(0xFF6D7077)),
          ),
        ],
      ),
    ),
  );
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Card(
      color: Colors.white,
      elevation: 3,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(11, 8, 8, 7),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '$count',
              style: const TextStyle(
                fontSize: 30,
                height: 1.05,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.item, required this.onTap});

  final Map<String, dynamic> item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final user = item['user'];
    final name = user is Map
        ? user['name']?.toString() ?? 'Karyawan'
        : 'Karyawan';
    final type = switch (item['type']?.toString()) {
      'cuti' => 'cuti',
      'izin' => 'izin',
      'sakit' => 'izin sakit',
      'lembur' => 'lembur',
      _ => 'pengajuan',
    };
    final status = item['status']?.toString() ?? 'pending';
    final message = status == 'pending'
        ? '$name mengajukan $type'
        : 'Pengajuan $type dari $name ${status == 'approved' ? 'disetujui' : 'ditolak'}';

    return Card(
      color: Colors.white,
      elevation: 2,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          child: Row(
            children: [
              const Icon(Icons.circle, size: 13, color: Color(0xFF2860E8)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _timeAgo(item['created_at']),
                style: const TextStyle(fontSize: 11, color: Color(0xFF9A9DA3)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HrdReportPanel extends StatefulWidget {
  const HrdReportPanel({
    super.key,
    required this.api,
    required this.dashboard,
  });

  final ApiService api;
  final Map<String, dynamic> dashboard;

  @override
  State<HrdReportPanel> createState() => _HrdReportPanelState();
}

class _HrdReportPanelState extends State<HrdReportPanel> {
  late Map<String, dynamic> _dashboard;
  late DateTime _month;
  late DateTime _selectedDate;
  bool _loading = false;
  bool _hasCustomFilters = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _dashboard = widget.dashboard;
    final selectedMonth = DateTime.tryParse(
      '${widget.dashboard['month'] ?? _currentMonthKey()}-01',
    );
    _month = selectedMonth ?? DateTime.now();
    _selectedDate =
        DateTime.tryParse(
          widget.dashboard['status_date']?.toString() ??
              widget.dashboard['date']?.toString() ??
              '',
        ) ??
        DateTime.now();
  }

  String get _monthKey =>
      '${_month.year}-${_month.month.toString().padLeft(2, '0')}';
  String get _dateKey =>
      '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';

  Future<void> _loadReport() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final dashboard = await widget.api.hrdDashboard(
        month: _monthKey,
        date: _dateKey,
      );
      if (mounted) setState(() => _dashboard = dashboard);
    } catch (error) {
      if (mounted) setState(() => _error = ApiService.errorMessage(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _chooseMonth() async {
    final now = DateTime.now();
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _month,
      firstDate: DateTime(2015),
      lastDate: DateTime(now.year, now.month, now.day),
      helpText: 'Pilih periode laporan',
    );
    if (selectedDate == null) return;

    final selectedMonth = DateTime(selectedDate.year, selectedDate.month);
    if (selectedMonth.year == _month.year &&
        selectedMonth.month == _month.month) {
      return;
    }

    final today = DateTime.now();
    final firstOfMonth = DateTime(selectedMonth.year, selectedMonth.month);
    final monthEnd = DateTime(selectedMonth.year, selectedMonth.month + 1, 0);
    final latestDate = monthEnd.isAfter(today) ? today : monthEnd;
    _selectedDate = firstOfMonth.isAfter(latestDate)
        ? latestDate
        : firstOfMonth;
    setState(() {
      _month = selectedMonth;
      _hasCustomFilters = true;
    });
    await _loadReport();
  }

  Future<void> _chooseDate() async {
    final now = DateTime.now();
    final firstDate = DateTime(_month.year, _month.month);
    final monthEnd = DateTime(_month.year, _month.month + 1, 0);
    final lastDate = monthEnd.isAfter(now) ? now : monthEnd;
    final initialDate = _selectedDate.isBefore(firstDate)
        ? firstDate
        : _selectedDate.isAfter(lastDate)
        ? lastDate
        : _selectedDate;
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: 'Pilih tanggal laporan',
    );
    if (selectedDate == null) return;
    setState(() {
      _selectedDate = selectedDate;
      _hasCustomFilters = true;
    });
    await _loadReport();
  }

  @override
  void didUpdateWidget(covariant HrdReportPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_hasCustomFilters &&
        oldWidget.dashboard != widget.dashboard &&
        widget.dashboard['month'] == _monthKey) {
      _dashboard = widget.dashboard;
      _selectedDate =
          DateTime.tryParse(
            widget.dashboard['status_date']?.toString() ??
                widget.dashboard['date']?.toString() ??
                '',
          ) ??
          _selectedDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    final summary = _dashboard['summary'] is Map
        ? Map<String, dynamic>.from(_dashboard['summary'] as Map)
        : <String, dynamic>{};
    final weeklyAttendance = _dashboard['weekly_attendance'] is List
        ? (_dashboard['weekly_attendance'] as List)
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList()
        : <Map<String, dynamic>>[];
    final employees = _dashboard['employee_statuses'] is List
        ? (_dashboard['employee_statuses'] as List)
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList()
        : <Map<String, dynamic>>[];
    final maxAttendance = weeklyAttendance.fold<int>(
      0,
      (maximum, week) => _count(week['count']) > maximum
          ? _count(week['count'])
          : maximum,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        Text(
          'Laporan Kehadiran',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const Text(
          'Rekap seluruh karyawan',
          style: TextStyle(color: Color(0xFF7C8798)),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _ReportFilter(
                label: 'Tanggal',
                value: _reportDateLabel(_selectedDate),
                onTap: _loading ? null : _chooseDate,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ReportFilter(
                label: 'Bulan',
                value: _reportMonthLabel(_month),
                onTap: _loading ? null : _chooseMonth,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ReportFilter(
                label: 'Divisi',
                value: 'Semua',
              ),
            ),
          ],
        ),
        if (_error != null) ...[
          const SizedBox(height: 10),
          Card(
            child: ListTile(
              leading: const Icon(Icons.error_outline, color: Colors.red),
              title: Text(_error!),
            ),
          ),
        ],
        const SizedBox(height: 12),
        Card(
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ringkasan ${_reportMonthLabel(_month)}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 130,
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : weeklyAttendance.isEmpty
                      ? const Center(
                          child: Text('Belum ada data presensi pada periode ini.'),
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: weeklyAttendance.map((week) {
                            final count = _count(week['count']);
                            final height = maxAttendance == 0
                                ? 8.0
                                : (count / maxAttendance * 88).clamp(
                                    8.0,
                                    88.0,
                                  );
                            return Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    '$count',
                                    style: const TextStyle(
                                      color: Color(0xFF667085),
                                      fontSize: 11,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    height: height,
                                    width: 24,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF2862E9),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    week['week']?.toString() ?? '',
                                    style: const TextStyle(
                                      color: Color(0xFF667085),
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 14,
                  runSpacing: 8,
                  children: [
                    _ReportLegend(
                      color: const Color(0xFF2862E9),
                      label:
                          'Presensi tercatat · ${_count(summary['monthly_attendance_count'])}',
                    ),
                    _ReportLegend(
                      color: const Color(0xFFF28A00),
                      label:
                          'Pengajuan masuk · ${_count(summary['monthly_request_count'])}',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Status ${_reportDateLabel(_selectedDate)}',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        const SizedBox(height: 8),
        if (_loading && employees.isEmpty)
          const Center(child: CircularProgressIndicator())
        else if (employees.isEmpty)
          const Card(
            child: ListTile(title: Text('Belum ada karyawan aktif.')),
          )
        else
          ...employees.map((employee) => _EmployeeStatusCard(employee: employee)),
      ],
    );
  }
}

class _ReportFilter extends StatelessWidget {
  const _ReportFilter({
    required this.label,
    required this.value,
    this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Card(
    color: Colors.white,
    margin: EdgeInsets.zero,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(color: Color(0xFF7C8798), fontSize: 11),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                if (onTap != null)
                  const Icon(Icons.keyboard_arrow_down, size: 18),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _ReportLegend extends StatelessWidget {
  const _ReportLegend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 9,
        height: 9,
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
      ),
      const SizedBox(width: 5),
      Text(
        label,
        style: const TextStyle(color: Color(0xFF667085), fontSize: 11),
      ),
    ],
  );
}

class _EmployeeStatusCard extends StatelessWidget {
  const _EmployeeStatusCard({required this.employee});

  final Map<String, dynamic> employee;

  @override
  Widget build(BuildContext context) {
    final name = employee['name']?.toString() ?? 'Karyawan';
    final status = employee['status']?.toString() ?? 'alpa';
    final presentation = switch (status) {
      'hadir' => ('Hadir', const Color(0xFFDDF5E8), const Color(0xFF18734A)),
      'cuti' => ('Cuti', const Color(0xFFE0EDFF), const Color(0xFF2460D9)),
      'sakit' => ('Sakit', const Color(0xFFF0E2FA), const Color(0xFF7B3FB4)),
      'izin' => ('Izin', const Color(0xFFFFE9CF), const Color(0xFFB05A00)),
      _ => ('Belum hadir', const Color(0xFFFFE4E1), const Color(0xFFB42318)),
    };
    final subtitle = [
      employee['email']?.toString() ?? '',
      if (status == 'hadir' && employee['jam_masuk'] != null)
        'Masuk ${employee['jam_masuk']}',
    ].where((part) => part.isNotEmpty).join(' · ');

    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFE0EDFF),
          foregroundColor: const Color(0xFF2460D9),
          child: Text(name.isEmpty ? '?' : name[0].toUpperCase()),
        ),
        title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 11),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: presentation.$2,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            presentation.$1,
            style: TextStyle(
              color: presentation.$3,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

String _currentMonthKey() {
  final now = DateTime.now();
  return '${now.year}-${now.month.toString().padLeft(2, '0')}';
}

String _reportMonthLabel(DateTime date) =>
    '${_monthName(date.month)} ${date.year}';

String _reportDateLabel(DateTime date) =>
    '${date.day} ${_monthName(date.month)}';

int _count(dynamic value) => value is num ? value.toInt() : 0;

String _greeting(int hour) {
  if (hour < 11) return 'Selamat pagi';
  if (hour < 15) return 'Selamat siang';
  if (hour < 18) return 'Selamat sore';
  return 'Selamat malam';
}

String _formattedDate(DateTime date) {
  const weekdays = [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
    'Minggu',
  ];
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];
  return '${weekdays[date.weekday - 1]}, ${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
}

String _monthName(int month) => const [
  'Januari',
  'Februari',
  'Maret',
  'April',
  'Mei',
  'Juni',
  'Juli',
  'Agustus',
  'September',
  'Oktober',
  'November',
  'Desember',
][month - 1];

String _timeAgo(dynamic value) {
  final createdAt = DateTime.tryParse(value?.toString() ?? '');
  if (createdAt == null) return 'Baru';
  final difference = DateTime.now().difference(createdAt);
  if (difference.isNegative || difference.inMinutes < 1) return 'Baru saja';
  if (difference.inMinutes < 60) return '${difference.inMinutes} mnt';
  if (difference.inHours < 24) return '${difference.inHours} jam';
  if (difference.inDays < 7) return '${difference.inDays} hari';
  return '${(difference.inDays / 7).floor()} mgg';
}
