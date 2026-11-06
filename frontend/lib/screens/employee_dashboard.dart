import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import 'dashboard_components.dart';

class EmployeeDashboard extends StatefulWidget {
  const EmployeeDashboard({super.key, this.api});

  final ApiService? api;

  @override
  State<EmployeeDashboard> createState() => _EmployeeDashboardState();
}

class _EmployeeDashboardState extends State<EmployeeDashboard> {
  static const _titles = ['Home', 'Riwayat', 'Pengajuan', 'Profil'];
  static const _icons = [
    Icons.home_outlined,
    Icons.calendar_month_outlined,
    Icons.description_outlined,
    Icons.person_outline,
  ];

  late final ApiService _api;
  int _selectedIndex = 0;
  String _requestType = 'cuti';
  int _requestLaunchId = 0;
  bool _editingProfile = false;

  @override
  void initState() {
    super.initState();
    _api = widget.api ?? context.read<AuthProvider>().api;
  }

  void _openRequest(String type) {
    setState(() {
      _requestType = type;
      _requestLaunchId++;
      _selectedIndex = 2;
    });
  }

  Future<void> _logout() async {
    await context.read<AuthProvider>().logout();
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      EmployeeHomePanel(api: _api, onRequest: _openRequest),
      EmployeeHistoryPanel(api: _api),
      EmployeeRequestsPanel(
        key: const ValueKey('employee-requests'),
        api: _api,
        initialRequestType: _requestType,
        requestLaunchId: _requestLaunchId,
      ),
      _editingProfile
          ? ProfilePanel(
              key: const ValueKey('employee-profile-editor'),
              api: _api,
            )
          : EmployeeProfilePanel(
              api: _api,
              onEdit: () => setState(() => _editingProfile = true),
              onLogout: _logout,
            ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
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

class EmployeeProfilePanel extends StatefulWidget {
  const EmployeeProfilePanel({
    super.key,
    required this.api,
    required this.onEdit,
    required this.onLogout,
  });

  final ApiService api;
  final VoidCallback onEdit;
  final VoidCallback onLogout;

  @override
  State<EmployeeProfilePanel> createState() => _EmployeeProfilePanelState();
}

class _EmployeeProfilePanelState extends State<EmployeeProfilePanel> {
  Map<String, dynamic> _profile = {};
  bool _loading = true;
  String? _error;

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

    final name = _profile['name']?.toString() ?? 'Karyawan';
    final email = _profile['email']?.toString() ?? '';

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
      children: [
        Center(
          child: Column(
            children: [
              CircleAvatar(
                radius: 57,
                backgroundColor: const Color(0xFFE7F0FF),
                child: Text(
                  name.isEmpty ? '?' : name[0].toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFF1769FF),
                    fontSize: 42,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                name,
                style: const TextStyle(
                  color: Color(0xFF1769FF),
                  fontSize: 18,
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
              const SizedBox(height: 18),
              SizedBox(
                width: 240,
                child: FilledButton(
                  onPressed: widget.onEdit,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF2862E9),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                  child: const Text('Edit Profil'),
                ),
              ),
            ],
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 16),
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

class EmployeeHomePanel extends StatefulWidget {
  const EmployeeHomePanel({
    super.key,
    required this.api,
    required this.onRequest,
  });

  final ApiService api;
  final ValueChanged<String> onRequest;

  @override
  State<EmployeeHomePanel> createState() => _EmployeeHomePanelState();
}

class EmployeeHistoryPanel extends StatefulWidget {
  const EmployeeHistoryPanel({super.key, required this.api});

  final ApiService api;

  @override
  State<EmployeeHistoryPanel> createState() => _EmployeeHistoryPanelState();
}

class _EmployeeHistoryPanelState extends State<EmployeeHistoryPanel> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime _selectedDate = DateTime.now();
  Map<String, dynamic> _profile = {};
  List<Map<String, dynamic>> _records = [];
  bool _loading = true;
  String? _error;

  String get _monthKey =>
      '${_month.year}-${_month.month.toString().padLeft(2, '0')}';

  Map<String, dynamic>? get _selectedAttendance {
    for (final record in _records) {
      if (record['tanggal']?.toString().startsWith(
            _historyDateKey(_selectedDate),
          ) ??
          false) {
        return record;
      }
    }
    return null;
  }

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
      final profile = await widget.api.profile();
      final records = await widget.api.attendance(_monthKey);
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _records = records;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = ApiService.errorMessage(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _changeMonth(int offset) {
    final nextMonth = DateTime(_month.year, _month.month + offset);
    final now = DateTime.now();
    if (nextMonth.isAfter(DateTime(now.year, now.month))) return;

    _selectMonth(nextMonth);
  }

  void _selectMonth(DateTime month) {
    final now = DateTime.now();
    final lastDay = DateTime(month.year, month.month + 1, 0).day;
    var day = _selectedDate.day.clamp(1, lastDay);
    if (month.year == now.year && month.month == now.month && day > now.day) {
      day = now.day;
    }

    setState(() {
      _month = DateTime(month.year, month.month);
      _selectedDate = DateTime(month.year, month.month, day);
    });
    _load();
  }

  Future<void> _chooseMonthAndYear() async {
    final now = DateTime.now();
    var selectedYear = _month.year;
    var selectedMonth = _month.month;
    final years = List.generate(now.year - 2015 + 1, (index) => 2015 + index);

    final selectedDate = await showDialog<DateTime>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Pilih bulan dan tahun'),
          content: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  isExpanded: true,
                  initialValue: selectedMonth,
                  decoration: const InputDecoration(labelText: 'Bulan'),
                  items: List.generate(
                    now.year == selectedYear ? now.month : 12,
                    (index) => DropdownMenuItem(
                      value: index + 1,
                      child: Text(_historyMonthName(index + 1)),
                    ),
                  ),
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => selectedMonth = value);
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<int>(
                  isExpanded: true,
                  initialValue: selectedYear,
                  decoration: const InputDecoration(labelText: 'Tahun'),
                  items: years
                      .map(
                        (year) =>
                            DropdownMenuItem(value: year, child: Text('$year')),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setDialogState(() {
                      selectedYear = value;
                      if (selectedYear == now.year &&
                          selectedMonth > now.month) {
                        selectedMonth = now.month;
                      }
                    });
                  },
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(context, DateTime(selectedYear, selectedMonth)),
              child: const Text('Pilih'),
            ),
          ],
        ),
      ),
    );

    if (selectedDate != null) _selectMonth(selectedDate);
  }

  void _selectDate(int day) {
    final date = DateTime(_month.year, _month.month, day);
    if (date.isAfter(DateTime.now())) return;
    setState(() => _selectedDate = date);
  }

  @override
  Widget build(BuildContext context) {
    final record = _selectedAttendance;
    final checkIn = record?['jam_masuk'];
    final checkOut = record?['jam_pulang'];
    final workedMinutes = _historyWorkedMinutes(checkIn, checkOut);
    final monthNames = const [
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
    final today = DateTime.now();

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth < 430 ? 5 : 7;
        return ListView(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.person,
                    size: 31,
                    color: Colors.blueGrey.shade800,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_greeting(today.hour)}, ${_profile['name'] ?? 'Karyawan'}',
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
                        'Karyawan',
                        style: TextStyle(
                          color: Color(0xFF7C8798),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  tooltip: 'Bulan sebelumnya',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _changeMonth(-1),
                  icon: const Icon(Icons.chevron_left, size: 18),
                ),
                TextButton(
                  onPressed: _chooseMonthAndYear,
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                  ),
                  child: Text(
                    '${monthNames[_month.month - 1]} ${_month.year}',
                    style: const TextStyle(
                      color: Color(0xFF0787F9),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Bulan berikutnya',
                  visualDensity: VisualDensity.compact,
                  onPressed:
                      _month.year == today.year && _month.month == today.month
                      ? null
                      : () => _changeMonth(1),
                  icon: const Icon(Icons.chevron_right, size: 18),
                ),
              ],
            ),
            const SizedBox(height: 4),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: DateTime(_month.year, _month.month + 1, 0).day,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                crossAxisSpacing: 7,
                mainAxisSpacing: 7,
                mainAxisExtent: 67,
              ),
              itemBuilder: (context, index) {
                final day = index + 1;
                final date = DateTime(_month.year, _month.month, day);
                final isSelected =
                    date.year == _selectedDate.year &&
                    date.month == _selectedDate.month &&
                    date.day == _selectedDate.day;
                final isFuture = date.isAfter(DateTime.now());
                final isSunday = date.weekday == DateTime.sunday;
                return _HistoryDayCard(
                  date: date,
                  selected: isSelected,
                  future: isFuture,
                  sunday: isSunday,
                  onTap: isFuture ? null : () => _selectDate(day),
                );
              },
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              _HistoryErrorCard(message: _error!, onRetry: _load),
            ],
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(14),
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              const SizedBox(height: 28),
              _HistorySummaryCard(
                checkIn: _historyFormattedTime(checkIn),
                checkOut: _historyFormattedTime(checkOut),
                duration: '${workedMinutes ~/ 60}j ${workedMinutes % 60}m',
                hasAttendance: record != null,
              ),
            ],
          ],
        );
      },
    );
  }
}

class _HistoryDayCard extends StatelessWidget {
  const _HistoryDayCard({
    required this.date,
    required this.selected,
    required this.future,
    required this.sunday,
    required this.onTap,
  });

  final DateTime date;
  final bool selected;
  final bool future;
  final bool sunday;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    const weekdays = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];
    final textColor = future
        ? const Color(0xFFB3BAC3)
        : sunday
        ? const Color(0xFFE34242)
        : const Color(0xFF24262A);

    return Material(
      color: selected ? const Color(0xFFA8D6F8) : const Color(0xFFF7F7F7),
      borderRadius: BorderRadius.circular(5),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(5),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              weekdays[date.weekday - 1],
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: textColor),
            ),
            const SizedBox(height: 4),
            Text(
              date.day.toString().padLeft(2, '0'),
              style: TextStyle(fontSize: 12, color: textColor),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistorySummaryCard extends StatelessWidget {
  const _HistorySummaryCard({
    required this.checkIn,
    required this.checkOut,
    required this.duration,
    required this.hasAttendance,
  });

  final String checkIn;
  final String checkOut;
  final String duration;
  final bool hasAttendance;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: const [
        BoxShadow(
          color: Color(0x22000000),
          blurRadius: 4,
          offset: Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HistoryTimeRow(
                    label: 'Jam Masuk',
                    value: checkIn,
                    icon: Icons.login,
                    color: const Color(0xFF08A84A),
                    background: const Color(0xFFDDFBE8),
                  ),
                  const SizedBox(height: 10),
                  _HistoryTimeRow(
                    label: 'Jam Pulang',
                    value: checkOut,
                    icon: Icons.logout,
                    color: const Color(0xFFF04444),
                    background: const Color(0xFFFFE3E3),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.access_time, size: 26, color: Colors.black87),
            const SizedBox(width: 6),
            SizedBox(
              width: 100,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Total Jam Kerja',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Color(0xFF667085), fontSize: 12),
                  ),
                  Text(
                    hasAttendance ? duration : '--:--',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF1769FF),
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _HistoryTimeRow extends StatelessWidget {
  const _HistoryTimeRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.background,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(color: background, shape: BoxShape.circle),
        child: Icon(icon, color: color, size: 19),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xFF667085), fontSize: 12),
            ),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF1769FF),
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class _HistoryErrorCard extends StatelessWidget {
  const _HistoryErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: const Icon(Icons.error_outline, color: Colors.red),
      title: Text(message),
      trailing: IconButton(
        tooltip: 'Coba lagi',
        onPressed: onRetry,
        icon: const Icon(Icons.refresh),
      ),
    ),
  );
}

String _historyDateKey(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

String _historyMonthName(int month) => const [
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

String _historyFormattedTime(dynamic value) {
  final time = value?.toString();
  if (time == null || time.isEmpty) return '--:--';
  final parts = time.split(':');
  if (parts.length < 2) return time;
  final hour = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);
  if (hour == null || minute == null) return time;
  final suffix = hour >= 12 ? 'PM' : 'AM';
  final displayHour = hour % 12 == 0 ? 12 : hour % 12;
  return '${displayHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $suffix';
}

int _historyWorkedMinutes(dynamic checkIn, dynamic checkOut) {
  final start = _historyTimeMinutes(checkIn);
  final end = _historyTimeMinutes(checkOut);
  if (start == null || end == null) return 0;
  return end >= start ? end - start : end + 24 * 60 - start;
}

int? _historyTimeMinutes(dynamic value) {
  final parts = value?.toString().split(':');
  if (parts == null || parts.length < 2) return null;
  final hour = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);
  if (hour == null || minute == null) return null;
  return hour * 60 + minute;
}

class _EmployeeHomePanelState extends State<EmployeeHomePanel> {
  DateTime _now = DateTime.now();
  Timer? _clockTimer;
  Map<String, dynamic> _profile = {};
  Map<String, dynamic>? _todayAttendance;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final profile = await widget.api.profile();
      final now = DateTime.now();
      final month = '${now.year}-${now.month.toString().padLeft(2, '0')}';
      final records = await widget.api.attendance(month);
      final todayKey = _dateKey(now);
      final today = records.cast<Map<String, dynamic>?>().firstWhere(
        (record) =>
            record?['tanggal']?.toString().startsWith(todayKey) ?? false,
        orElse: () => null,
      );
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _todayAttendance = today;
        _now = now;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = ApiService.errorMessage(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _record(String action) async {
    setState(() => _saving = true);
    try {
      await widget.api.recordAttendance(action);
      if (!mounted) return;
      _message(
        action == 'check-in'
            ? 'Presensi Masuk Berhasil'
            : 'Presensi Pulang Berhasil',
      );
      await _load();
    } catch (error) {
      if (mounted) _message(ApiService.errorMessage(error), isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
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
    final attendance = _todayAttendance;
    final hasCheckedIn = attendance != null;
    final hasCheckedOut =
        attendance != null && attendance['jam_pulang'] != null;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 25,
              backgroundColor: Colors.white,
              child: Icon(
                Icons.person,
                size: 31,
                color: Colors.blueGrey.shade800,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_greeting(_now.hour)}, ${_profile['name'] ?? 'Karyawan'}',
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
                    'Karyawan',
                    style: TextStyle(color: Color(0xFF7C8798), fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 36),
        Text(
          _formattedDate(_now),
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFF00BCEB), fontSize: 14),
        ),
        const SizedBox(height: 8),
        Text(
          '${_now.hour.toString().padLeft(2, '0')}:${_now.minute.toString().padLeft(2, '0')}',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF0787F9),
            fontSize: 52,
            height: 1,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_on, size: 16, color: Color(0xFF667085)),
            SizedBox(width: 4),
            Text(
              'Lokasi kantor',
              style: TextStyle(color: Color(0xFF667085), fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 28),
        Row(
          children: [
            Expanded(
              child: _AttendanceAction(
                label: 'Clock In',
                icon: Icons.login,
                color: const Color(0xFF08A84A),
                background: const Color(0xFFDDFBE8),
                enabled:
                    !_loading && _error == null && !_saving && !hasCheckedIn,
                onTap: () => _record('check-in'),
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: _AttendanceAction(
                label: 'Clock Out',
                icon: Icons.logout,
                color: const Color(0xFFF04444),
                background: const Color(0xFFFFE3E3),
                enabled:
                    !_loading &&
                    _error == null &&
                    !_saving &&
                    hasCheckedIn &&
                    !hasCheckedOut,
                onTap: () => _record('check-out'),
              ),
            ),
          ],
        ),
        if (_saving)
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
        if (_error != null) ...[
          const SizedBox(height: 16),
          _EmployeeErrorCard(message: _error!, onRetry: _load),
        ],
        const SizedBox(height: 24),
        Row(
          children: [
            _QuickAction(
              label: 'Cuti',
              icon: Icons.work_outline,
              onTap: () => widget.onRequest('cuti'),
            ),
            _QuickAction(
              label: 'Izin',
              icon: Icons.description_outlined,
              onTap: () => widget.onRequest('izin'),
            ),
            _QuickAction(
              label: 'Sakit',
              icon: Icons.sick_outlined,
              onTap: () => widget.onRequest('sakit'),
            ),
            _QuickAction(
              label: 'Lembur',
              icon: Icons.night_shelter_outlined,
              onTap: () => widget.onRequest('lembur'),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Text(
          'Aktivitas Hari Ini',
          style: TextStyle(color: Color(0xFF667085), fontSize: 13),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              _ActivityRow(
                label: 'Jam Masuk',
                time: _formattedTime(attendance?['jam_masuk']),
                icon: Icons.login,
                color: const Color(0xFF08A84A),
                background: const Color(0xFFDDFBE8),
              ),
              const Divider(height: 20, color: Color(0xFFF0F2F5)),
              _ActivityRow(
                label: 'Jam Pulang',
                time: _formattedTime(attendance?['jam_pulang']),
                icon: Icons.logout,
                color: const Color(0xFFF04444),
                background: const Color(0xFFFFE3E3),
              ),
            ],
          ),
        ),
        if (_loading)
          const Padding(
            padding: EdgeInsets.only(top: 14),
            child: Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }
}

class _AttendanceAction extends StatelessWidget {
  const _AttendanceAction({
    required this.label,
    required this.icon,
    required this.color,
    required this.background,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final Color background;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(28),
    child: InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(28),
      child: SizedBox(
        height: 126,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: enabled ? background : const Color(0xFFF0F2F5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: enabled ? color : const Color(0xFF98A2B3),
                size: 26,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: enabled ? const Color(0xFF9A4A4A) : Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Expanded(
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        children: [
          Container(
            height: 64,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(17),
            ),
            child: Center(
              child: Icon(icon, size: 34, color: const Color(0xFF15191F)),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(color: Color(0xFF667085), fontSize: 12),
          ),
        ],
      ),
    ),
  );
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({
    required this.label,
    required this.time,
    required this.icon,
    required this.color,
    required this.background,
  });

  final String label;
  final String time;
  final IconData icon;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(color: background, shape: BoxShape.circle),
        child: Icon(icon, color: color, size: 18),
      ),
      const SizedBox(width: 14),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Color(0xFF667085), fontSize: 12),
          ),
          const SizedBox(height: 1),
          Text(
            time,
            style: const TextStyle(
              color: Color(0xFF1769FF),
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    ],
  );
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

String _formattedTime(dynamic value) {
  final time = value?.toString();
  if (time == null || time.isEmpty) return '--:--';
  final parts = time.split(':');
  if (parts.length < 2) return time;
  final hour = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);
  if (hour == null || minute == null) return time;
  final suffix = hour >= 12 ? 'PM' : 'AM';
  final displayHour = hour % 12 == 0 ? 12 : hour % 12;
  return '${displayHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $suffix';
}

String _dateKey(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

String _greeting(int hour) {
  if (hour < 11) return 'Selamat pagi';
  if (hour < 15) return 'Selamat siang';
  if (hour < 18) return 'Selamat sore';
  return 'Selamat malam';
}

class _EmployeeErrorCard extends StatelessWidget {
  const _EmployeeErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: const Icon(Icons.error_outline, color: Colors.red),
      title: Text(message),
      trailing: IconButton(
        tooltip: 'Coba lagi',
        onPressed: onRetry,
        icon: const Icon(Icons.refresh),
      ),
    ),
  );
}
