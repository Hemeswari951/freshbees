import 'package:flutter/material.dart';
import '../../widgets/app_colors.dart'; // Ensure this matches your project structure

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String _activeTimeframe = 'This Month';
  final List<String> _timeframes = ['Today', 'This Week', 'This Month', 'This Year'];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header & Filters
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'Reports Overview',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.ink,
                ),
              ),
              // Responsive timeframe filter
              Wrap(
                spacing: 8,
                children: _timeframes.map((tf) {
                  final active = tf == _activeTimeframe;
                  return ChoiceChip(
                    label: Text(tf),
                    selected: active,
                    onSelected: (_) => setState(() => _activeTimeframe = tf),
                    selectedColor: AppColors.black,
                    backgroundColor: AppColors.white,
                    labelStyle: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: active ? Colors.white : AppColors.inkSoft,
                    ),
                    side: BorderSide(
                        color: active ? AppColors.black : AppColors.line),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                  );
                }).toList(),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // KPI Grid (Responsive)
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              // Adjust columns based on screen width (Emulator vs Chrome)
              int columns = width < 600 ? 2 : 4;
              final spacing = 16.0;
              final itemWidth = (width - (spacing * (columns - 1))) / columns;

              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  _buildKPICard(
                    title: 'Total Revenue',
                    value: 'Rs. 1,24,500',
                    trend: '+12.5%',
                    isPositive: true,
                    icon: Icons.account_balance_wallet_outlined,
                    width: itemWidth,
                  ),
                  _buildKPICard(
                    title: 'Orders',
                    value: '342',
                    trend: '+5.2%',
                    isPositive: true,
                    icon: Icons.shopping_bag_outlined,
                    width: itemWidth,
                  ),
                  _buildKPICard(
                    title: 'Avg. Order Value',
                    value: 'Rs. 364',
                    trend: '-1.4%',
                    isPositive: false,
                    icon: Icons.receipt_long_outlined,
                    width: itemWidth,
                  ),
                  _buildKPICard(
                    title: 'Conversion Rate',
                    value: '3.8%',
                    trend: '+0.4%',
                    isPositive: true,
                    icon: Icons.insights,
                    width: itemWidth,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          // Main Content Area (Charts / Lists)
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final isDesktop = width > 800;

              if (isDesktop) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 2, child: _buildSalesChartPanel()),
                    const SizedBox(width: 16),
                    Expanded(flex: 1, child: _buildTopProductsPanel()),
                  ],
                );
              }
              // Stack vertically on smaller emulator screens
              return Column(
                children: [
                  _buildSalesChartPanel(),
                  const SizedBox(height: 16),
                  _buildTopProductsPanel(),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildKPICard({
    required String title,
    required String value,
    required String trend,
    required bool isPositive,
    required IconData icon,
    required double width,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.inkSoft,
                ),
              ),
              Icon(icon, size: 20, color: AppColors.inkSoft),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.ink,
              fontFamily: 'JetBrainsMono', // Using the font from your ProductsScreen
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                size: 14,
                color: isPositive ? Colors.green : AppColors.red,
              ),
              const SizedBox(width: 4),
              Text(
                trend,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isPositive ? Colors.green : AppColors.red,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'vs last period',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.inkSoft,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSalesChartPanel() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sales Overview',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 24),
          // Placeholder for a real chart (e.g., using fl_chart package)
          Container(
            height: 250,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.line.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.bar_chart, size: 48, color: AppColors.inkSoft),
                  SizedBox(height: 8),
                  Text(
                    'Chart rendering area\n(Implement fl_chart or similar here)',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.inkSoft, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopProductsPanel() {
    // Dummy data for visual representation
    final topProducts = [
      {'name': 'Floral Summer Dress', 'sales': '124 units', 'revenue': 'Rs. 45k'},
      {'name': 'Classic White Sneaker', 'sales': '98 units', 'revenue': 'Rs. 32k'},
      {'name': 'Denim Jacket', 'sales': '76 units', 'revenue': 'Rs. 28k'},
      {'name': 'Cotton T-Shirt', 'sales': '65 units', 'revenue': 'Rs. 15k'},
    ];

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Top Products',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.more_horiz, color: AppColors.inkSoft),
                onPressed: () {},
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...topProducts.map((product) => Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.line,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.checkroom, size: 20, color: AppColors.inkSoft),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product['name']!,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.ink,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            product['sales']!,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.inkSoft,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      product['revenue']!,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                        fontFamily: 'JetBrainsMono',
                      ),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                foregroundColor: AppColors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: AppColors.line),
                ),
              ),
              child: const Text('View All', style: TextStyle(fontSize: 12.5)),
            ),
          )
        ],
      ),
    );
  }
}