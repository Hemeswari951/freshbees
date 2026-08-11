import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/home_data.dart';
import '../../services/home_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<HomeData> homeFuture;

  @override
  void initState() {
    super.initState();
    homeFuture = HomeService().getHome();
  }

  Future<void> _refresh() async {
    setState(() {
      homeFuture = HomeService().getHome();
    });
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isDesktop = screenWidth > 900;

    return Scaffold(
      body: SafeArea(
        child: FutureBuilder<HomeData>(
          future: homeFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Failed to load: ${snapshot.error}"),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _refresh,
                      child: const Text("Retry"),
                    ),
                  ],
                ),
              );
            }

            final data = snapshot.data!;

            return RefreshIndicator(
              onRefresh: _refresh,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(isDesktop ? 10 : 5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Metric Cards Grid - FROM BACKEND
                    _buildMetricsGrid(isDesktop, data),
                    const SizedBox(height: 6),

                    // 2. Alerts and Payouts Banner Row - FROM BACKEND
                    _buildAlertsAndPayouts(isDesktop, data),
                    const SizedBox(height: 15),

                    // 3. Main content splitter
                    isDesktop
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildBestSellersSection(isDesktop),
                                    const SizedBox(height: 24),
                                    _buildStoreOverviewSection(),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 24),
                              Expanded(
                                flex: 2,
                                child: _buildRecentOrdersSection(),
                              ),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildBestSellersSection(isDesktop),
                              const SizedBox(height: 24),
                              _buildRecentOrdersSection(),
                              const SizedBox(height: 24),
                              _buildStoreOverviewSection(),
                            ],
                          ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMetricsGrid(bool isDesktop, HomeData data) {
    final stats = data.stats;

    final List<Map<String, dynamic>> metrics = [
      {
        'title': 'Total orders',
        'value': '${stats.totalOrders}',
        'sub':
            '${stats.ordersChangePercent >= 0 ? "↑" : "↓"} ${stats.ordersChangePercent.abs()}% vs last week',
        'subColor': stats.ordersChangePercent >= 0
            ? Colors.green[700]
            : Colors.red[700],
        'icon': Icons.shopping_bag_outlined,
        'iconBg': const Color(0xFFFAF3EE),
        'iconColor': const Color(0xFF7A5C43),
      },
      {
        'title': "Today's sales",
        'value': '₹${stats.todaysSales.toStringAsFixed(0)}',
        'sub':
            '${stats.salesChangePercent >= 0 ? "↑" : "↓"} ${stats.salesChangePercent.abs()}% vs yesterday',
        'subColor': stats.salesChangePercent >= 0
            ? Colors.green[700]
            : Colors.red[700],
        'icon': Icons.currency_rupee_rounded,
        'iconBg': const Color(0xFFFAF3EE),
        'iconColor': const Color(0xFF7A5C43),
      },
      {
        'title': 'Pending orders',
        'value': '${stats.pendingOrders}',
        'sub': '${stats.pendingOver24h} over 24 hrs',
        'subColor': Colors.red[700],
        'icon': Icons.inventory_2_outlined,
        'iconBg': const Color(0xFFFAF3EE),
        'iconColor': const Color(0xFF7A5C43),
      },
      {
        'title': 'Total revenue',
        'value': '₹${stats.totalRevenue.toStringAsFixed(0)}',
        'sub': 'This month',
        'subColor': Colors.grey[600],
        'icon': Icons.analytics_outlined,
        'iconBg': const Color(0xFFFAF3EE),
        'iconColor': const Color(0xFF7A5C43),
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isDesktop ? 4 : 2,
        crossAxisSpacing: isDesktop ? 12 : 10,
        mainAxisSpacing: isDesktop ? 12 : 10,
        childAspectRatio: isDesktop ? 2.0 : 1.7,
      ),
      itemCount: metrics.length,
      itemBuilder: (context, index) {
        final item = metrics[index];
        return Container(
          padding: EdgeInsets.all(isDesktop ? 12 : 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(isDesktop ? 12 : 8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: item['iconBg'],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  item['icon'],
                  color: item['iconColor'],
                  size: isDesktop ? 18 : 16,
                ),
              ),
              SizedBox(width: isDesktop ? 15 : 8),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  // mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      item['title'],
                      style: TextStyle(
                        fontSize: isDesktop ? 14 : 12,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 6),

                    Text(
                      item['value'],
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E1E1E),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 4),

                    Text(
                      item['sub'],
                      style: TextStyle(
                        fontSize: isDesktop ? 12 : 10,
                        color: item['subColor'],
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAlertsAndPayouts(bool isDesktop, HomeData data) {
    final Widget? alertWidget = data.lowStockCount > 0
        ? Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF0F2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFFD2D7)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Color(0xFFB3261E),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${data.lowStockCount} products low on stock',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF8C1D18),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Tap to view and restock.',
                        style: TextStyle(
                          color: Color(0xFF8C1D18),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF8C1D18),
                ),
              ],
            ),
          )
        : null;

    final Widget? payoutWidget = data.nextPayout != null
        ? Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF322013),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4C3524),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet_outlined,
                    color: Color(0xFFE6C5A9),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Next payout',
                        style: TextStyle(
                          color: Color(0xFFC4A48A),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '₹${data.nextPayout!.amount.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF322013),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onPressed: () {
                    // TODO: navigate to Payouts screen
                  },
                  child: const Text(
                    'View Payouts',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ],
            ),
          )
        : null;

    if (alertWidget == null && payoutWidget == null) {
      return const SizedBox.shrink();
    }

    if (alertWidget == null) return payoutWidget!;
    if (payoutWidget == null) return alertWidget;

    if (isDesktop) {
      return Row(
        children: [
          Expanded(child: alertWidget),
          const SizedBox(width: 16),
          Expanded(child: payoutWidget),
        ],
      );
    } else {
      return Column(
        children: [alertWidget, const SizedBox(height: 12), payoutWidget],
      );
    }
  }

  // ============================================================
  // Best Sellers - STATIC UI (backend not connected yet)
  // TODO: Replace hardcoded 'items' list with data.bestSellers
  // Mobile: horizontal scroll | Desktop: side-by-side Row
  // ============================================================
  Widget _buildBestSellersSection(bool isDesktop) {
    final List<Map<String, dynamic>> items = [
      {
        'name': 'Linen shirt',
        'sales': '24 sold',
        'perf': '18%',
        'img':
            'https://images.unsplash.com/photo-1596755094514-f87e34085b2c?auto=format&fit=crop&w=200&q=80',
      },
      {
        'name': 'Cotton kurti',
        'sales': '19 sold',
        'perf': '14%',
        'img':
            'https://images.unsplash.com/photo-1610030469983-98e550d6193c?auto=format&fit=crop&w=200&q=80',
      },
      {
        'name': 'Denim jacket',
        'sales': '15 sold',
        'perf': '10%',
        'img':
            'https://images.unsplash.com/photo-1576995853123-5a10305d93c0?auto=format&fit=crop&w=200&q=80',
      },
    ];

    Widget buildCard(Map<String, dynamic> product) {
      return Card(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  product['img'],
                  height: 100,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      Container(color: Colors.grey[200], height: 100),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                product['name'],
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                product['sales'],
                style: const TextStyle(color: Colors.grey, fontSize: 11),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFE2F6EA),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '📈 ${product['perf']}',
                  style: const TextStyle(
                    color: Color(0xFF137E43),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Best sellers this week'),
        const SizedBox(height: 12),
        isDesktop
            ? Row(
                children: items
                    .map(
                      (product) => Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: buildCard(product),
                        ),
                      ),
                    )
                    .toList(),
              )
            : SizedBox(
                height: 200,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: items.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 10),
                  itemBuilder: (context, index) =>
                      SizedBox(width: 140, child: buildCard(items[index])),
                ),
              ),
      ],
    );
  }

  // ============================================================
  // Recent Orders - STATIC UI (backend not connected yet)
  // TODO: Replace hardcoded 'orders' list with data.recentOrders
  // ============================================================
  Widget _buildRecentOrdersSection() {
    final List<Map<String, dynamic>> orders = [
      {
        'id': '#ORD12345',
        'customer': 'John Doe',
        'items': '2 items',
        'status': 'New',
        'statusColor': Colors.orange[800],
        'statusBg': const Color(0xFFFFF3E0),
        'price': '₹1,299',
        'time': '10 min ago',
        'img':
            'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=100&q=80',
      },
      {
        'id': '#ORD12341',
        'customer': 'Divya R',
        'items': '1 item',
        'status': 'Pending 26h',
        'statusColor': Colors.red[800],
        'statusBg': const Color(0xFFFFEBEE),
        'price': '₹899',
        'time': 'yesterday',
        'img':
            'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=100&q=80',
      },
      {
        'id': '#ORD12343',
        'customer': 'Rahul Verma',
        'items': '1 item',
        'status': 'Shipped',
        'statusColor': Colors.green[800],
        'statusBg': const Color(0xFFE8F5E9),
        'price': '₹899',
        'time': '3 hrs ago',
        'img':
            'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=100&q=80',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Recent orders'),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: orders.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final order = orders[index];
            return Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      order['img'],
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey[200],
                        width: 44,
                        height: 44,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                order['id'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: order['statusBg'],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                order['status'],
                                style: TextStyle(
                                  color: order['statusColor'],
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${order['customer']} • ${order['items']}',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 11,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        order['price'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        order['time'],
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildStoreOverviewSection() {
    final List<Map<String, dynamic>> tools = [
      {
        'label': 'Products',
        'icon': Icons.local_offer_outlined,
        'route': '/products',
      },
      {
        'label': 'Orders',
        'icon': Icons.shopping_basket_outlined,
        'route': '/orders',
      },
      {
        'label': 'Inventory',
        'icon': Icons.inventory_2_outlined,
        'route': '/inventory',
      },
      {
        'label': 'Reports',
        'icon': Icons.bar_chart_outlined,
        'route': '/reports',
      },
      {
        'label': 'Customers',
        'icon': Icons.people_outline,
      },
      {
        'label': 'Earnings',
        'icon': Icons.account_balance_wallet_outlined,
        'route': '/earnings',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Store overview', showViewAll: false),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.3,
          ),
          itemCount: tools.length,
          itemBuilder: (context, index) {
            final tool = tools[index];
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: InkWell(
                onTap: () {
                  final route = tool['route'];

                  if (route != null) {
                    context.go(route);
                  }
                },
                borderRadius: BorderRadius.circular(12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      tool['icon'],
                      color: const Color(0xFF7A5C43),
                      size: 22,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      tool['label'],
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                        color: Color(0xFF1E1E1E),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, {bool showViewAll = true}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E1E1E),
          ),
        ),
        if (showViewAll)
          TextButton(
            onPressed: () {
              // TODO: navigate to relevant list screen
            },
            child: const Text(
              'View all',
              style: TextStyle(
                color: Color(0xFF9E2A2B),
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
      ],
    );
  }
}
