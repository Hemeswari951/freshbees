import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'users_list.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  final Color ivory  = const Color(0xFFFBF4ED);
  final Color cardBg = Colors.white;
  final Color accent = const Color(0xFFB8956A);

  int? hoveredIndex;

  // ── Internal view state: false = dashboard, true = user list ──────────────
  bool _showUserList = false;

  final List<Map<String, dynamic>> countCards = [
    {
      'title': 'TOTAL USERS',
      'value': '12,847',
      'change': '+3.2%',
      'isUp': true,
      'icon': Icons.people_alt_outlined,
      'live': false,
      'navigable': true,
    },
    {
      'title': 'NEW USERS TODAY',
      'value': '211',
      'change': '+12',
      'isUp': true,
      'icon': Icons.person_add_outlined,
      'live': false,
      'navigable': false,
    },
    {
      'title': 'ACTIVE NOW',
      'value': '1,284',
      'change': 'LIVE',
      'isUp': true,
      'icon': Icons.wifi_tethering,
      'live': true,
      'navigable': false,
    },
    {
      'title': 'BLOCKED USERS',
      'value': '47',
      'change': '-2',
      'isUp': false,
      'icon': Icons.block,
      'live': false,
      'navigable': false,
    },
    {
      'title': 'DELETED USERS',
      'value': '89',
      'change': '+5 this week',
      'isUp': true,
      'icon': Icons.delete_outline,
      'live': false,
      'navigable': false,
    },
  ];

  final Map<String, List<double>> trendData = {
    'Daily Signups':  [120, 145, 132, 178, 165, 198, 211],
    'Daily Logins':   [3200, 3450, 3100, 3680, 3890, 4100, 4567],
    'Blocked Trend':  [52, 50, 49, 51, 48, 49, 47],
    'Deleted Trend':  [12, 15, 11, 18, 14, 16, 13],
  };

  static const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  void _onCardTap(Map<String, dynamic> data) {
    if (data['navigable'] == true) {
      setState(() => _showUserList = true);
    }
  }

  void _goBackToDashboard() {
    setState(() => _showUserList = false);
  }

  @override
  Widget build(BuildContext context) {
    // If user list is active, show it inline (no route push = browser back stays on Users)
    if (_showUserList) {
      return UsersListInline(onBack: _goBackToDashboard);
    }

    final isMobile = MediaQuery.of(context).size.width < 700;

    return Container(
      color: ivory,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────
            Row(
              children: [
                const Text(
                  'Users Dashboard',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                if (!isMobile)
                  SizedBox(
                    width: 260,
                    height: 40,
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search users...',
                        hintStyle: TextStyle(
                            fontSize: 13, color: Colors.grey.shade500),
                        prefixIcon: Icon(Icons.search,
                            size: 18, color: Colors.grey.shade500),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 0),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: accent, width: 1.5),
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 20),

            // ── Count Cards ─────────────────────────────────────────────
            _buildCountCards(isMobile),

            const SizedBox(height: 24),

            // ── Trend Graphs ────────────────────────────────────────────
            const Text(
              '7-Day Trends',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 14),
            _buildTrendGraphs(isMobile),

            const SizedBox(height: 24),

            // ── Quick Actions ───────────────────────────────────────────
            _buildQuickActions(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ── Count Cards ────────────────────────────────────────────────────────────
  Widget _buildCountCards(bool isMobile) {
    // Use LayoutBuilder to compute exact card height and avoid overflow
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final crossCount = isMobile ? 2 : 5;
        final spacing = 12.0;
        final cardWidth =
            (totalWidth - spacing * (crossCount - 1)) / crossCount;
        // Card height: fixed so content always fits
        final cardHeight = isMobile ? cardWidth / 1.3 : cardWidth / 1.5;
        cardHeight.clamp(110.0, 200.0);

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: List.generate(countCards.length, (i) {
            return SizedBox(
              width: cardWidth,
              height: cardHeight.clamp(110.0, 200.0),
              child: _buildCard(countCards[i], i),
            );
          }),
        );
      },
    );
  }

  Widget _buildCard(Map<String, dynamic> data, int index) {
    final hovered   = hoveredIndex == index;
    final isLive    = data['live'] as bool;
    final navigable = data['navigable'] as bool;

    return MouseRegion(
      cursor: navigable ? SystemMouseCursors.click : MouseCursor.defer,
      onEnter: (_) => setState(() => hoveredIndex = index),
      onExit:  (_) => setState(() => hoveredIndex = null),
      child: GestureDetector(
        onTap: () => _onCardTap(data),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hovered ? accent : Colors.grey.shade200,
              width: hovered ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black
                    .withValues(alpha: hovered ? 0.08 : 0.04),
                blurRadius: hovered ? 16 : 8,
                offset: Offset(0, hovered ? 4 : 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            mainAxisSize: MainAxisSize.max,
            children: [
              // Top row — icon + live badge / arrow
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(data['icon'] as IconData,
                        color: accent, size: 15),
                  ),
                  if (isLive)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 5,
                            height: 5,
                            decoration: const BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 3),
                          const Text('LIVE',
                              style: TextStyle(
                                  fontSize: 8,
                                  color: Colors.green,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    )
                  else
                    Icon(
                      Icons.arrow_forward_ios,
                      color: navigable ? accent : Colors.grey.shade300,
                      size: 11,
                    ),
                ],
              ),

              // Title
              Text(
                data['title'] as String,
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              // Value
              Text(
                data['value'] as String,
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w700),
                maxLines: 1,
              ),

              // Change row
              Row(
                children: [
                  Icon(
                    (data['isUp'] as bool)
                        ? Icons.arrow_upward
                        : Icons.arrow_downward,
                    size: 10,
                    color:
                        (data['isUp'] as bool) ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 2),
                  Flexible(
                    child: Text(
                      data['change'] as String,
                      style: TextStyle(
                        fontSize: 10,
                        color: (data['isUp'] as bool)
                            ? Colors.green
                            : Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Trend Graphs ───────────────────────────────────────────────────────────
  Widget _buildTrendGraphs(bool isMobile) {
    final entries = trendData.entries.toList();

    if (isMobile) {
      return Column(
        children: entries
            .map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _buildTrendCard(e.key, e.value),
                ))
            .toList(),
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(
                child: _buildTrendCard(entries[0].key, entries[0].value)),
            const SizedBox(width: 14),
            Expanded(
                child: _buildTrendCard(entries[1].key, entries[1].value)),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
                child: _buildTrendCard(entries[2].key, entries[2].value)),
            const SizedBox(width: 14),
            Expanded(
                child: _buildTrendCard(entries[3].key, entries[3].value)),
          ],
        ),
      ],
    );
  }

  Widget _buildTrendCard(String title, List<double> data) {
    final maxY = data.reduce((a, b) => a > b ? a : b) * 1.2;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text('Last 7 days',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
          const SizedBox(height: 16),
          SizedBox(
            height: 110,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY / 4,
                  getDrawingHorizontalLine: (_) =>
                      FlLine(color: Colors.grey.shade100, strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      interval: 1,
                      getTitlesWidget: (value, _) {
                        final i = value.toInt();
                        if (i < 0 || i >= _days.length) {
                          return const SizedBox.shrink();
                        }
                        return Text(_days[i],
                            style: TextStyle(
                                fontSize: 9, color: Colors.grey.shade500));
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: 6,
                minY: 0,
                maxY: maxY,
                lineBarsData: [
                  LineChartBarData(
                    spots: data
                        .asMap()
                        .entries
                        .map((e) => FlSpot(e.key.toDouble(), e.value))
                        .toList(),
                    isCurved: true,
                    color: accent,
                    barWidth: 2.5,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (_, _, _, _) =>
                          FlDotCirclePainter(
                        radius: 3,
                        color: accent,
                        strokeWidth: 1.5,
                        strokeColor: Colors.white,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: accent.withValues(alpha: 0.08),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Quick Actions ──────────────────────────────────────────────────────────
  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'QUICK ACTIONS',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _chip(Icons.download,             'Export Users'),
              _chip(Icons.notifications_active, 'Send Notification'),
              _chip(Icons.group_add,            'Bulk Add Users'),
              _chip(Icons.analytics,            'Generate Report'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: accent),
          const SizedBox(width: 7),
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade800)),
        ],
      ),
    );
  }
}