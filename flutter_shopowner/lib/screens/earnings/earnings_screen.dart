import 'package:flutter/material.dart';
import '../../widgets/app_colors.dart'; // Ensure this matches your project structure

class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  String _activeTab = 'All Transactions';
  final List<String> _tabs = ['All Transactions', 'Payouts', 'Refunds'];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'Earnings & Payouts',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.ink,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  // Handle withdrawal logic
                },
                icon: const Icon(Icons.account_balance_wallet, size: 16),
                label: const Text('Withdraw Funds'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.black,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  textStyle: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Overview Cards (Responsive)
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              int columns = width < 700 ? 2 : 4;
              const spacing = 16.0;
              final itemWidth = (width - (spacing * (columns - 1))) / columns;

              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  _buildSummaryCard(
                    title: 'Available to Withdraw',
                    value: 'Rs. 42,500',
                    icon: Icons.check_circle_outline,
                    iconColor: Colors.green,
                    width: itemWidth,
                    highlight: true,
                  ),
                  _buildSummaryCard(
                    title: 'Pending Clearance',
                    value: 'Rs. 12,350',
                    icon: Icons.hourglass_empty,
                    iconColor: AppColors.gold,
                    width: itemWidth,
                  ),
                  _buildSummaryCard(
                    title: 'Net Earnings (Month)',
                    value: 'Rs. 84,200',
                    icon: Icons.trending_up,
                    iconColor: AppColors.blue,
                    width: itemWidth,
                  ),
                  _buildSummaryCard(
                    title: 'Withdrawn (All Time)',
                    value: 'Rs. 3,15,000',
                    icon: Icons.account_balance,
                    iconColor: AppColors.inkSoft,
                    width: itemWidth,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 32),

          // Transactions Panel
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.white,
              border: Border.all(color: AppColors.line),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Panel Header & Tabs
                Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Transaction History',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        children: _tabs.map((tab) {
                          final active = tab == _activeTab;
                          return ChoiceChip(
                            label: Text(tab),
                            selected: active,
                            onSelected: (_) => setState(() => _activeTab = tab),
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
                ),
                const Divider(height: 1, color: AppColors.line),
                
                // Transactions List
                _buildTransactionList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
    required double width,
    bool highlight = false,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: highlight ? AppColors.black : AppColors.white,
        border: Border.all(color: highlight ? AppColors.black : AppColors.line),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: highlight ? Colors.white70 : AppColors.inkSoft,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(icon, size: 20, color: highlight ? Colors.white : iconColor),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: highlight ? Colors.white : AppColors.ink,
              fontFamily: 'JetBrainsMono',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionList() {
    // Dummy Data
    final transactions = [
      {'id': '#ORD-8472', 'date': 'Aug 03, 2026', 'type': 'Sale', 'amount': '+ Rs. 1,250', 'status': 'Cleared'},
      {'id': '#ORD-8471', 'date': 'Aug 02, 2026', 'type': 'Sale', 'amount': '+ Rs. 890', 'status': 'Pending'},
      {'id': '#PAY-104', 'date': 'Aug 01, 2026', 'type': 'Payout', 'amount': '- Rs. 25,000', 'status': 'Completed'},
      {'id': '#ORD-8465', 'date': 'Jul 30, 2026', 'type': 'Refund', 'amount': '- Rs. 450', 'status': 'Deducted'},
      {'id': '#ORD-8460', 'date': 'Jul 28, 2026', 'type': 'Sale', 'amount': '+ Rs. 3,400', 'status': 'Cleared'},
    ];

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: transactions.length,
      separatorBuilder: (context, index) => const Divider(height: 1, color: AppColors.line),
      itemBuilder: (context, index) {
        final t = transactions[index];
        final isPositive = t['amount']!.startsWith('+');
        
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          child: Row(
            children: [
              // Icon based on type
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: t['type'] == 'Sale' 
                      ? AppColors.greenSoft 
                      : (t['type'] == 'Payout' ? AppColors.blueSoft : AppColors.redSoft),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  t['type'] == 'Sale' 
                      ? Icons.arrow_downward 
                      : (t['type'] == 'Payout' ? Icons.account_balance : Icons.refresh),
                  size: 18,
                  color: t['type'] == 'Sale' 
                      ? Colors.green 
                      : (t['type'] == 'Payout' ? AppColors.blue : AppColors.red),
                ),
              ),
              const SizedBox(width: 16),
              
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${t['type']} ${t['id']}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      t['date']!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.inkSoft,
                      ),
                    ),
                  ],
                ),
              ),

              // Amount & Status
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    t['amount']!,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isPositive ? Colors.green : AppColors.ink,
                      fontFamily: 'JetBrainsMono',
                    ),
                  ),
                  const SizedBox(height: 6),
                  _StatusBadge(status: t['status']!),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Local Status Badge specific to Earnings
// ─────────────────────────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    
    switch (status) {
      case 'Cleared':
      case 'Completed':
        bg = AppColors.greenSoft;
        fg = const Color(0xFF2F5A44);
        break;
      case 'Pending':
        bg = const Color(0xFFFBEBD2); // Matches pending/gold style
        fg = const Color(0xFF966A1B);
        break;
      case 'Deducted':
        bg = AppColors.redSoft;
        fg = const Color(0xFF8C3F32);
        break;
      default:
        bg = AppColors.line;
        fg = AppColors.inkSoft;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(
        status,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }
}