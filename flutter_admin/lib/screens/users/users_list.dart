import 'package:flutter/material.dart';

// ── Inline version (used inside UsersScreen without route push) ──────────────
class UsersListInline extends StatefulWidget {
  final VoidCallback onBack;
  const UsersListInline({super.key, required this.onBack});

  @override
  State<UsersListInline> createState() => _UsersListInlineState();
}

class _UsersListInlineState extends State<UsersListInline> {
  final Color ivory = const Color(0xFFFBF4ED);
  final Color cardBg = Colors.white;
  final Color accent = const Color(0xFFB8956A);

  String sortBy = 'A-Z';
  int? hoveredIndex;
  String searchQuery = '';

  final List<Map<String, dynamic>> users = [
    {
      'name': 'John Doe',
      'email': 'john@email.com',
      'status': 'Active',
      'orders': 28,
      'logins': 5,
      'avatar': 'JD',
    },
    {
      'name': 'Ayesha Khan',
      'email': 'ayesha@email.com',
      'status': 'Active',
      'orders': 22,
      'logins': 4,
      'avatar': 'AK',
    },
    {
      'name': 'Ravi Kumar',
      'email': 'ravi@email.com',
      'status': 'Inactive',
      'orders': 10,
      'logins': 1,
      'avatar': 'RK',
    },
    {
      'name': 'Sara Patel',
      'email': 'sara@email.com',
      'status': 'Active',
      'orders': 35,
      'logins': 9,
      'avatar': 'SP',
    },
    {
      'name': 'Liam Chen',
      'email': 'liam@email.com',
      'status': 'Blocked',
      'orders': 5,
      'logins': 0,
      'avatar': 'LC',
    },
    {
      'name': 'Meera Nair',
      'email': 'meera@email.com',
      'status': 'Active',
      'orders': 19,
      'logins': 3,
      'avatar': 'MN',
    },
    {
      'name': 'David Smith',
      'email': 'david@email.com',
      'status': 'Active',
      'orders': 41,
      'logins': 12,
      'avatar': 'DS',
    },
    {
      'name': 'Fatima Al-Sayed',
      'email': 'fatima@email.com',
      'status': 'Inactive',
      'orders': 8,
      'logins': 2,
      'avatar': 'FA',
    },
    {
      'name': 'Carlos Rivera',
      'email': 'carlos@email.com',
      'status': 'Active',
      'orders': 17,
      'logins': 6,
      'avatar': 'CR',
    },
    {
      'name': 'Priya Sharma',
      'email': 'priya@email.com',
      'status': 'Active',
      'orders': 30,
      'logins': 8,
      'avatar': 'PS',
    },
  ];

  List<Map<String, dynamic>> get filteredAndSorted {
    var list = users.where((u) {
      final q = searchQuery.toLowerCase();
      return u['name'].toLowerCase().contains(q) ||
          u['email'].toLowerCase().contains(q);
    }).toList();

    switch (sortBy) {
      case 'A-Z':
        list.sort((a, b) => a['name'].compareTo(b['name']));
        break;
      case 'Z-A':
        list.sort((a, b) => b['name'].compareTo(a['name']));
        break;
      case 'Most Active':
        list.sort((a, b) => (b['logins'] as int).compareTo(a['logins'] as int));
        break;
      case 'Least Active':
        list.sort((a, b) => (a['logins'] as int).compareTo(b['logins'] as int));
        break;
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {

    final isMobile = MediaQuery.of(context).size.width < 700;
    final list = filteredAndSorted;

    return Container(
      color: ivory,
      child: Column(
        children: [
          // ── Top bar with back button ───────────────────────────────────
          Container(
            color: cardBg,
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 16 : 24,
              vertical: 14,
            ),
            child: Row(
              children: [
                InkWell(
                  onTap: widget.onBack,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: accent.withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.arrow_back_ios_new, size: 13, color: accent),
                        const SizedBox(width: 6),
                        Text(
                          'Back',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                const Text(
                  'All Users',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade200),

          // ── Body ──────────────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isMobile ? 16 : 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search + Sort row
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 42,
                          child: TextField(
                            onChanged: (v) => setState(() => searchQuery = v),
                            decoration: InputDecoration(
                              hintText: 'Search users...',
                              hintStyle: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade500,
                              ),
                              prefixIcon: Icon(
                                Icons.search,
                                size: 18,
                                color: Colors.grey.shade500,
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 0,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade300,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade300,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: accent,
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      _buildSortDropdown(),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Results count
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Text(
                      '${list.length} users found',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ),

                  // User list
                  if (list.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 60),
                        child: Column(
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 48,
                              color: Colors.grey.shade300,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No users match your search',
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: list.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) =>
                          _buildUserCard(list[index], index, isMobile),
                    ),

                  const SizedBox(height: 16),

                  // Pagination bar
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '1–${list.length} of 1,284',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        Row(
                          children: [
                            _pageBtn(Icons.chevron_left, enabled: false),
                            const SizedBox(width: 4),
                            _pageBtn(Icons.chevron_right, enabled: true),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pageBtn(IconData icon, {required bool enabled}) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: enabled ? () {} : null,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: enabled ? accent.withValues(alpha: 0.1) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: enabled
                ? accent.withValues(alpha: 0.3)
                : Colors.grey.shade200,
          ),
        ),
        child: Icon(
          icon,
          size: 18,
          color: enabled ? accent : Colors.grey.shade400,
        ),
      ),
    );
  }

  Widget _buildSortDropdown() {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: sortBy,
          style: TextStyle(fontSize: 13, color: Colors.grey.shade800),
          icon: Icon(
            Icons.keyboard_arrow_down,
            size: 18,
            color: Colors.grey.shade500,
          ),
          items: ['A-Z', 'Z-A', 'Most Active', 'Least Active'].map((e) {
            return DropdownMenuItem(value: e, child: Text(e));
          }).toList(),
          onChanged: (value) => setState(() => sortBy = value!),
        ),
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user, int index, bool isMobile) {
    final isHovered = hoveredIndex == index;
    final status = user['status'] as String;

    Color statusColor;
    Color statusBg;
    switch (status) {
      case 'Active':
        statusColor = Colors.green.shade700;
        statusBg = Colors.green.shade50;
        break;
      case 'Inactive':
        statusColor = Colors.orange.shade700;
        statusBg = Colors.orange.shade50;
        break;
      case 'Blocked':
        statusColor = Colors.red.shade700;
        statusBg = Colors.red.shade50;
        break;
      default:
        statusColor = Colors.grey.shade700;
        statusBg = Colors.grey.shade100;
    }

    return MouseRegion(
      onEnter: (_) => setState(() => hoveredIndex = index),
      onExit: (_) => setState(() => hoveredIndex = null),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isHovered ? accent : Colors.grey.shade200,
            width: isHovered ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isHovered ? 0.07 : 0.03),
              blurRadius: isHovered ? 12 : 6,
              offset: Offset(0, isHovered ? 4 : 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: isMobile
              ? _mobileCardContent(user, statusColor, statusBg)
              : _desktopCardContent(user, statusColor, statusBg),
        ),
      ),
    );
  }

  Widget _desktopCardContent(
    Map<String, dynamic> user,
    Color statusColor,
    Color statusBg,
  ) {
    return Row(
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: accent.withValues(alpha: 0.18),
          child: Text(
            user['avatar'],
            style: TextStyle(
              color: accent,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(width: 14),

        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user['name'],
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                user['email'],
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
            ],
          ),
        ),

        Expanded(
          child: Column(
            children: [
              Text(
                'Orders',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
              const SizedBox(height: 2),
              Text(
                user['orders'].toString(),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: Column(
            children: [
              Text(
                'Logins',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
              const SizedBox(height: 2),
              Text(
                user['logins'].toString(),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: statusBg,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            user['status'],
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),

        const SizedBox(width: 12),
        Icon(Icons.more_vert, color: Colors.grey.shade400, size: 18),
      ],
    );
  }

  Widget _mobileCardContent(
    Map<String, dynamic> user,
    Color statusColor,
    Color statusBg,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: accent.withValues(alpha: 0.18),
              child: Text(
                user['avatar'],
                style: TextStyle(
                  color: accent,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user['name'],
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    user['email'],
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: statusBg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                user['status'],
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Divider(height: 1, color: Colors.grey.shade100),
        const SizedBox(height: 10),
        Row(
          children: [
            _statPill('Orders', user['orders'].toString()),
            const SizedBox(width: 12),
            _statPill('Logins', user['logins'].toString()),
          ],
        ),
      ],
    );
  }

  Widget _statPill(String label, String value) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

// ── Standalone route version (kept for optional use elsewhere) ────────────────
class UsersList extends StatelessWidget {
  final String title;
  const UsersList({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: UsersListInline(onBack: () => Navigator.pop(context)),
    );
  }
}
