import 'dart:async';
import 'package:flutter/material.dart';
import '../../widgets/t_colors.dart';
import '../../models/customer_model.dart';
import '../../services/customer_service.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  // ---- Dashboard cards ----
  DashboardStats? dashboardStats;
  bool isDashboardLoading = true;

  // ---- Customer list ----
  List<Customer> customers = [];
  bool isListLoading = true;
  String? listError;

  // ---- Filters ----
  String selectedCard = 'TOTAL CUSTOMERS';
  String searchQuery = '';
  Timer? _debounce;
  String cityFilter = 'All Cities';
  String statusFilter = 'All Status';
  String sortBy = 'A-Z';
  int? hoveredIndex;

  // ---- Detail panel ----
  Customer? selectedCustomer;
  bool showDetailPanel = false;
  bool isDetailLoading = false;
  bool isSavingStatus = false;
  bool? pendingIsBlocked; // user's choice inside the panel, before Save

  // NOTE: there's no "distinct cities" endpoint yet, so this stays a fixed
  // list for now. Later you could add GET /api/admin/customers/cities to
  // populate this dynamically.
  final cities = [
    'All Cities',
    'Chennai',
    'Bangalore',
    'Salem',
    'London',
    'Shanghai',
  ];
  final statuses = ['All Status', 'Unblocked', 'Blocked'];
  final sortOptions = ['A-Z', 'Z-A', 'Newest', 'Oldest'];

  @override
  void initState() {
    super.initState();
    _loadDashboard();
    _loadCustomers();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  // =========================================================
  // API CALLS
  // =========================================================

  Future<void> _loadDashboard() async {
    setState(() => isDashboardLoading = true);
    try {
      final stats = await CustomerService.getDashboard();
      setState(() {
        dashboardStats = stats;
        isDashboardLoading = false;
      });
    } catch (e) {
      setState(() => isDashboardLoading = false);
      // Dashboard failing shouldn't block the rest of the screen; the
      // cards will just show a dash if this errors.
    }
  }

  // Card title -> "type" query param your backend expects
  String? _typeForSelectedCard() {
    switch (selectedCard) {
      case 'NEW CUSTOMERS TODAY':
        return 'today';
      case 'BLOCKED CUSTOMERS':
        return 'blocked';
      default:
        return null; // TOTAL CUSTOMERS -> no type filter, i.e. everyone
    }
  }

  Future<void> _loadCustomers() async {
    setState(() {
      isListLoading = true;
      listError = null;
    });

    try {
      final result = await CustomerService.getCustomers(
        type: _typeForSelectedCard(),
        search: searchQuery.isNotEmpty ? searchQuery : null,
        city: cityFilter != 'All Cities' ? cityFilter : null,
        status: statusFilter == 'Blocked'
            ? 'blocked'
            : statusFilter == 'Unblocked'
            ? 'unblocked'
            : null,
      );
      setState(() {
        customers = result;
        isListLoading = false;
      });
    } catch (e) {
      setState(() {
        listError = 'Could not load customers. Is the server running?';
        isListLoading = false;
      });
    }
  }

  Future<void> _openCustomerPanel(Customer customer) async {
    setState(() {
      selectedCustomer = customer;
      pendingIsBlocked = customer.isBlocked;
      showDetailPanel = true;
      isDetailLoading = true;
    });

    // Fetch the full record fresh from the server (so gender/dob/state/etc.
    // are populated — the list endpoint returns a slimmer set of columns).
    try {
      final full = await CustomerService.getCustomerById(customer.customerId);
      setState(() {
        selectedCustomer = full;
        pendingIsBlocked = full.isBlocked;
        isDetailLoading = false;
      });
    } catch (e) {
      setState(() => isDetailLoading = false);
      _showSnack('Could not load full details, showing list data.', isError: true);
    }
  }

  void _closeCustomerPanel() {
    setState(() {
      showDetailPanel = false;
      selectedCustomer = null;
      pendingIsBlocked = null;
    });
  }

  // Quick block/unblock straight from the popup menu on a list row
  Future<void> _quickUpdateStatus(Customer customer, bool newIsBlocked) async {
    try {
      final updated = await CustomerService.updateCustomerStatus(
        customer.customerId,
        newIsBlocked,
      );
      setState(() {
        final idx = customers.indexWhere(
          (c) => c.customerId == customer.customerId,
        );
        if (idx != -1) customers[idx].isBlocked = updated.isBlocked;
      });
      _loadDashboard(); // counts may have shifted
      _showSnack(
        'Customer ${updated.isBlocked ? "blocked" : "unblocked"} successfully!',
      );
    } catch (e) {
      _showSnack('Failed to update status. Please try again.', isError: true);
    }
  }

  // Save button inside the detail panel
  Future<void> _saveCustomerChanges() async {
    if (selectedCustomer == null || pendingIsBlocked == null) return;

    setState(() => isSavingStatus = true);
    try {
      final updated = await CustomerService.updateCustomerStatus(
        selectedCustomer!.customerId,
        pendingIsBlocked!,
      );
      setState(() {
        final idx = customers.indexWhere(
          (c) => c.customerId == updated.customerId,
        );
        if (idx != -1) customers[idx].isBlocked = updated.isBlocked;
        isSavingStatus = false;
        showDetailPanel = false;
        selectedCustomer = null;
      });
      _loadDashboard();
      _showSnack('Changes saved successfully!');
    } catch (e) {
      setState(() => isSavingStatus = false);
      _showSnack('Failed to save changes. Please try again.', isError: true);
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  // =========================================================
  // FILTER / SEARCH HANDLERS
  // =========================================================

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      setState(() => searchQuery = value);
      _loadCustomers();
    });
  }

  void _onCardTap(String title) {
    setState(() => selectedCard = title);
    _loadCustomers();
  }

  void _onCityChanged(String? value) {
    setState(() => cityFilter = value!);
    _loadCustomers();
  }

  void _onStatusChanged(String? value) {
    setState(() => statusFilter = value!);
    _loadCustomers();
  }

  // Sorting happens client-side on whatever the server returned
  List<Customer> get sortedCustomers {
    final list = List<Customer>.from(customers);
    if (sortBy == 'A-Z') {
      list.sort((a, b) => a.fullName.compareTo(b.fullName));
    } else if (sortBy == 'Z-A') {
      list.sort((a, b) => b.fullName.compareTo(a.fullName));
    } else if (sortBy == 'Newest') {
      list.sort(
        (a, b) => (b.createdAt ?? DateTime(1970)).compareTo(
          a.createdAt ?? DateTime(1970),
        ),
      );
    } else if (sortBy == 'Oldest') {
      list.sort(
        (a, b) => (a.createdAt ?? DateTime(1970)).compareTo(
          b.createdAt ?? DateTime(1970),
        ),
      );
    }
    return list;
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;
    final list = sortedCustomers;

    return Scaffold(
      backgroundColor: TColors.cream,
      body: Stack(
        children: [
          Positioned.fill(
            child: RefreshIndicator(
              onRefresh: () async {
                await Future.wait([_loadDashboard(), _loadCustomers()]);
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(isMobile ? 16 : 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selectedCard,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: TColors.black,
                      ),
                    ),
                    const SizedBox(height: 20),

                    _buildCards(isMobile),
                    const SizedBox(height: 20),

                    _buildSearchFilters(isMobile),
                    const SizedBox(height: 20),

                    if (isListLoading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 60),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (listError != null)
                      _errorState(listError!)
                    else if (list.isEmpty)
                      _emptyState()
                    else
                      Column(
                        children: list
                            .asMap()
                            .entries
                            .map(
                              (e) => _customerCard(e.value, e.key, isMobile),
                            )
                            .toList(),
                      ),
                  ],
                ),
              ),
            ),
          ),

          AnimatedPositioned(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic,
            right: showDetailPanel && selectedCustomer != null ? 16 : -540,
            top: 16,
            bottom: 16,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: showDetailPanel ? 1.0 : 0.0,
              child: Container(
                width:
                    (MediaQuery.of(context).size.width *
                            (isMobile ? 0.85 : 0.35))
                        .clamp(340.0, 460.0),
                decoration: BoxDecoration(
                  color: TColors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.14),
                      blurRadius: 32,
                      offset: const Offset(-8, 12),
                    ),
                  ],
                ),
                child: selectedCustomer != null
                    ? _buildCustomerDetailPanel()
                    : const SizedBox.shrink(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // DASHBOARD CARDS
  // =========================================================

  Widget _buildCards(bool isMobile) {
    final cards = [
      {
        'title': 'TOTAL CUSTOMERS',
        'value': dashboardStats?.totalCustomers,
        'icon': Icons.people_alt_outlined,
      },
      {
        'title': 'NEW CUSTOMERS TODAY',
        'value': dashboardStats?.newCustomersToday,
        'icon': Icons.person_add_outlined,
      },
      {
        'title': 'BLOCKED CUSTOMERS',
        'value': dashboardStats?.blockedCustomers,
        'icon': Icons.block,
      },
    ];

    return LayoutBuilder(
      builder: (context, c) {
        final count = isMobile ? 1 : 3;
        final w = (c.maxWidth - 12 * (count - 1)) / count;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: cards.map((card) {
            final sel = selectedCard == card['title'];
            final value = card['value'] as int?;
            return SizedBox(
              width: w,
              child: InkWell(
                onTap: () => _onCardTap(card['title'] as String),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: TColors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: sel ? TColors.brown : TColors.border,
                      width: sel ? 2 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: TColors.black.withValues(alpha: sel ? 0.08 : 0.04),
                        blurRadius: sel ? 16 : 8,
                        offset: Offset(0, sel ? 4 : 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: TColors.brown.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              card['icon'] as IconData,
                              color: TColors.brown,
                              size: 18,
                            ),
                          ),
                          if (sel)
                            const Icon(
                              Icons.check_circle,
                              color: TColors.brown,
                              size: 18,
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        card['title'] as String,
                        style: const TextStyle(
                          fontSize: 11,
                          color: TColors.brownLight,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      isDashboardLoading
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              value != null ? '$value' : '—',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: TColors.black,
                              ),
                            ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  // =========================================================
  // SEARCH + FILTERS
  // =========================================================

  Widget _buildSearchFilters(bool isMobile) {
    final searchField = SizedBox(
      height: 42,
      child: TextField(
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          hintText: isMobile
              ? 'Search customers...'
              : 'Search by name, email or phone...',
          hintStyle: const TextStyle(fontSize: 13, color: TColors.brownLight),
          prefixIcon: const Icon(
            Icons.search,
            size: 18,
            color: TColors.brownLight,
          ),
          filled: true,
          fillColor: TColors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: TColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: TColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: TColors.brown, width: 1.5),
          ),
        ),
      ),
    );

    if (isMobile) {
      return Column(
        children: [
          searchField,
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _dropdown(cityFilter, cities, _onCityChanged),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _dropdown(statusFilter, statuses, _onStatusChanged),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _dropdown(
                  'Sort: $sortBy',
                  sortOptions.map((e) => 'Sort: $e').toList(),
                  (v) => setState(
                    () => sortBy = v!.replaceFirst('Sort: ', ''),
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(flex: 4, child: searchField),
        const SizedBox(width: 12),
        _dropdown(cityFilter, cities, _onCityChanged),
        const SizedBox(width: 8),
        _dropdown(statusFilter, statuses, _onStatusChanged),
        const SizedBox(width: 8),
        _dropdown(
          'Sort by: $sortBy',
          sortOptions.map((e) => 'Sort by: $e').toList(),
          (v) => setState(() => sortBy = v!.replaceFirst('Sort by: ', '')),
        ),
      ],
    );
  }

  Widget _dropdown(
    String value,
    List<String> items,
    ValueChanged<String?> onChanged,
  ) => Container(
    height: 42,
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: BoxDecoration(
      color: TColors.white,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: TColors.border),
    ),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: value,
        style: const TextStyle(fontSize: 13, color: TColors.black),
        icon: const Icon(
          Icons.keyboard_arrow_down,
          size: 18,
          color: TColors.brownLight,
        ),
        items: items
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
        onChanged: onChanged,
      ),
    ),
  );

  // =========================================================
  // CUSTOMER LIST ROW
  // =========================================================

  Widget _avatar(Customer u, double radius) {
    if (u.profileImage != null && u.profileImage!.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: TColors.brown.withValues(alpha: 0.18),
        backgroundImage: NetworkImage(u.profileImage!),
        onBackgroundImageError: (_, _) {}, // falls back silently
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: TColors.brown.withValues(alpha: 0.18),
      child: Text(
        u.initials,
        style: TextStyle(
          color: TColors.brown,
          fontWeight: FontWeight.bold,
          fontSize: radius * 0.65,
        ),
      ),
    );
  }

  Widget _customerCard(Customer u, int i, bool isMobile) {
    final hover = hoveredIndex == i;
    final isBlocked = u.isBlocked;
    Color c = isBlocked ? Colors.red : Colors.green.shade700;
    Color bg = isBlocked ? Colors.red.withValues(alpha: 0.1) : Colors.green.shade50;

    return MouseRegion(
      onEnter: (_) => setState(() => hoveredIndex = i),
      onExit: (_) => setState(() => hoveredIndex = null),
      child: InkWell(
        onTap: () => _openCustomerPanel(u),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(16),
          transform: Matrix4.identity()
            ..translate(0.0, hover ? -6.0 : 0.0, 0.0),
          decoration: BoxDecoration(
            color: TColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hover ? TColors.brown.withValues(alpha: 0.6) : TColors.border,
              width: hover ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: TColors.black.withValues(alpha: hover ? 0.14 : 0.05),
                blurRadius: hover ? 22 : 8,
                offset: Offset(0, hover ? 10 : 3),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  _avatar(u, 20),
                  const SizedBox(width: 16),
                  Expanded(
                    child: isMobile
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                u.fullName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                  color: TColors.black,
                                ),
                              ),
                              Text(
                                u.email,
                                style: const TextStyle(
                                  color: TColors.brownLight,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                u.phone,
                                style: const TextStyle(
                                  color: TColors.brownLight,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Text(
                                  u.fullName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                    color: TColors.black,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 4,
                                child: Text(
                                  u.email,
                                  style: const TextStyle(
                                    color: TColors.brownLight,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: Text(
                                  u.phone,
                                  style: const TextStyle(
                                    color: TColors.brownLight,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                  PopupMenuButton<bool>(
                    onSelected: (newIsBlocked) =>
                        _quickUpdateStatus(u, newIsBlocked),
                    itemBuilder: (ctx) => [
                      PopupMenuItem(
                        value: false,
                        child: Text(
                          'Unblock Customer',
                          style: TextStyle(color: Colors.green.shade700),
                        ),
                      ),
                      PopupMenuItem(
                        value: true,
                        child: const Text(
                          'Block Customer',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            u.statusLabel,
                            style: TextStyle(
                              color: c,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.arrow_drop_down, size: 16, color: c),
                        ],
                      ),
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

  Widget _stat(String l, String v) => Column(
    children: [
      Text(l, style: const TextStyle(fontSize: 11, color: TColors.brownLight)),
      const SizedBox(height: 4),
      Text(
        v,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: TColors.black,
        ),
      ),
    ],
  );

  Widget _emptyState() => const Center(
    child: Padding(
      padding: EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          Icon(Icons.search_off, size: 48, color: TColors.border),
          SizedBox(height: 12),
          Text(
            'No customers found',
            style: TextStyle(color: TColors.brownLight, fontSize: 14),
          ),
        ],
      ),
    ),
  );

  Widget _errorState(String message) => Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: TColors.brownLight, fontSize: 14),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: _loadCustomers,
            child: const Text('Retry'),
          ),
        ],
      ),
    ),
  );

  // =========================================================
  // DETAIL PANEL
  // =========================================================

  Widget _buildCustomerDetailPanel() {
    final customer = selectedCustomer!;
    final isBlocked = pendingIsBlocked ?? customer.isBlocked;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: TColors.border)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Customer Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: TColors.black,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: TColors.brownLight),
                onPressed: _closeCustomerPanel,
              ),
            ],
          ),
        ),
        Expanded(
          child: isDetailLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _avatar(customer, 32),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Wrap(
                                  crossAxisAlignment:
                                      WrapCrossAlignment.center,
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: [
                                    Text(
                                      customer.fullName,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: TColors.black,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isBlocked
                                            ? Colors.red.withValues(alpha: 0.1)
                                            : Colors.green.shade50,
                                        borderRadius: BorderRadius.circular(
                                          12,
                                        ),
                                      ),
                                      child: Text(
                                        isBlocked ? 'Blocked' : 'Unblocked',
                                        style: TextStyle(
                                          color: isBlocked
                                              ? Colors.red
                                              : Colors.green.shade700,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Customer • Joined on ${customer.createdAt != null ? _formatDate(customer.createdAt!) : '—'}',
                                  style: const TextStyle(
                                    color: TColors.brownLight,
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  'Last login: ${customer.lastLogin != null ? _formatDateTime(customer.lastLogin!) : '—'}',
                                  style: const TextStyle(
                                    color: TColors.brownLight,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _sectionTitle('Contact Information'),
                      const SizedBox(height: 12),
                      _detailRow('First Name', customer.firstName),
                      _detailRow('Last Name', customer.lastName),
                      _detailRow('Email', customer.email),
                      _detailRow('Phone', customer.phone),
                      _detailRow('Gender', customer.gender ?? '—'),
                      _detailRow('Date of Birth', customer.dateOfBirth ?? '—'),
                      _detailRow(
                        'City',
                        [
                          customer.city,
                          customer.state,
                        ].where((e) => e != null && e.isNotEmpty).join(', ').isEmpty
                            ? '—'
                            : [customer.city, customer.state]
                                  .where((e) => e != null && e.isNotEmpty)
                                  .join(', '),
                      ),
                      const SizedBox(height: 24),
                      // =======================
                      // ---- STATIC "Saved Addresses" block (placeholder) ----
                      // TODO: wire this to real data once you add an
                      // `addresses` table + endpoint. For now it's just
                      // hardcoded so the UI matches the design.
                      _sectionTitle('Saved Addresses'),
                      const SizedBox(height: 12),
                      _staticAddressCard(
                        icon: Icons.home,
                        type: 'Home',
                        isPrimary: true,
                        street: 'Flat 402, Sea Breeze Apartments, Bandra West',
                        cityLine: 'Mumbai, Maharashtra 400050',
                      ),
                      _staticAddressCard(
                        icon: Icons.location_on_outlined,
                        type: 'Office',
                        isPrimary: false,
                        street: 'Gigaplex Tech Park, Tower R1, Airoli',
                        cityLine: 'Navi Mumbai, Maharashtra 400708',
                      ),
                      const SizedBox(height: 12),
                      // End of Address code
                      // =======================
                      _sectionTitle('Account Status'),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () =>
                                  setState(() => pendingIsBlocked = false),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color: !isBlocked
                                      ? Colors.green.shade700
                                      : TColors.border,
                                ),
                                backgroundColor: !isBlocked
                                    ? Colors.green.shade50
                                    : TColors.white,
                              ),
                              child: Text(
                                'Unblock Customer',
                                style: TextStyle(
                                  color: !isBlocked
                                      ? Colors.green.shade700
                                      : TColors.black,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () =>
                                  setState(() => pendingIsBlocked = true),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color: isBlocked
                                      ? Colors.red
                                      : TColors.border,
                                ),
                                backgroundColor: isBlocked
                                    ? Colors.red.withValues(alpha: 0.1)
                                    : TColors.white,
                              ),
                              child: Text(
                                'Block Customer',
                                style: TextStyle(
                                  color: isBlocked
                                      ? Colors.red
                                      : TColors.black,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
        ),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: TColors.border)),
          ),
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: isSavingStatus ? null : _saveCustomerChanges,
              style: ElevatedButton.styleFrom(
                backgroundColor: TColors.brown,
                foregroundColor: TColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: isSavingStatus
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: TColors.white,
                      ),
                    )
                  : const Text(
                      'Save Changes',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(String title) => Text(
    title,
    style: const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w700,
      color: TColors.black,
    ),
  );

  Widget _detailRow(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: TColors.brownLight, fontSize: 13),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: TColors.black,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    ),
  );

// =======================
// ---------------------
//       ADDRESS PART - IN FUTURE NEED TO CHANGE DYNAMICALLY 
// -----------------------
Widget _staticAddressCard({
    required IconData icon,
    required String type,
    required bool isPrimary,
    required String street,
    required String cityLine,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isPrimary ? TColors.cream : TColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isPrimary ? TColors.brown.withValues(alpha: 0.5) : TColors.border,
          width: isPrimary ? 1.5 : 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: isPrimary ? TColors.brown : TColors.brownLight,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      type,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: TColors.black,
                      ),
                    ),
                    if (isPrimary) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1.5,
                        ),
                        decoration: BoxDecoration(
                          color: TColors.brown.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Primary',
                          style: TextStyle(
                            color: TColors.brown,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(street, style: const TextStyle(fontSize: 13, color: TColors.black)),
                Text(cityLine, style: const TextStyle(fontSize: 12, color: TColors.brownLight)),
              ],
            ),
          ),
        ],
      ),
    );
  }
// ----------------------
// ========================-


  String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _formatDateTime(DateTime d) {
    final hour = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final period = d.hour >= 12 ? 'PM' : 'AM';
    return '${_formatDate(d)} ${hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')} $period';
  }
}
