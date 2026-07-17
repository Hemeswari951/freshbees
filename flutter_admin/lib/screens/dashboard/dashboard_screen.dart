import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/shop_service.dart';
import '../../services/customer_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int totalShops = 0;
  int totalCustomers = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadDashboardData();
  }

  Future<void> loadDashboardData() async {
    try {
      final shops = await ShopService.getAllShops();
      final customers = await CustomerService.getCustomers();

      setState(() {
        totalShops = shops.length;
        totalCustomers = customers.length;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF8F6F1), // Ivory
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// Header
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      "Super Admin Dashboard",
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      "Manage your entire platform",
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.calendar_month_outlined),
                      SizedBox(width: 8),
                      Text("Today"),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            /// KPI CARDS
      GridView.count(
  crossAxisCount: 4,
  shrinkWrap: true,
  childAspectRatio: 1.7,
  physics: const NeverScrollableScrollPhysics(),
  crossAxisSpacing: 18,
  mainAxisSpacing: 18,
  children: [
    DashboardCard(
      title: "Total Customers",
      value: isLoading
          ? "Loading..."
          : totalCustomers.toString(),
      icon: Icons.people_alt_outlined,
    ),

  DashboardCard(
    title: "Total Shops",
    value: isLoading
        ? "Loading..."
        : totalShops.toString(),
    icon: Icons.storefront_outlined,
  ),

  const DashboardCard(
    title: "Orders",
    value: "18,420",
    icon: Icons.shopping_bag_outlined,
  ),

  const DashboardCard(
    title: "Revenue",
    value: "₹42.8L",
    icon: Icons.currency_rupee,
  ),

  const DashboardCard(
    title: "Products",
    value: "82,500",
    icon: Icons.inventory_2_outlined,
  ),

  const DashboardCard(
    title: "Payouts",
    value: "₹12.2L",
    icon: Icons.account_balance_wallet_outlined,
  ),

  const DashboardCard(
    title: "Pending Reports",
    value: "29",
    icon: Icons.report_gmailerrorred,
  ),

  const DashboardCard(
    title: "Support Tickets",
    value: "13",
    icon: Icons.support_agent,
  ),
],
      ),
            const SizedBox(height: 30),

            /// ANALYTICS
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Expanded(
                  flex: 3,
                  child: Container(
                    height: 350,
                    padding: const EdgeInsets.all(20),
                    decoration: _boxDecoration(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Revenue Analytics",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),

                        const SizedBox(height: 20),

                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xffF8F6F1),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: const Center(
                              child: Text(
                                "Revenue Chart Here\n(fl_chart)",
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 20),

                Expanded(
                  child: Container(
                    height: 450,
                    padding: const EdgeInsets.all(20),
                    decoration: _boxDecoration(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        const Text(
                          "System Health",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 25),

                        _statusTile("API Server", true),
                        _statusTile("Database", true),
                        _statusTile("Payment Gateway", true),
                        _statusTile("Storage", true),
                        _statusTile("Notification Service", false),

                        const Spacer(),

                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.check_circle,
                                  color: Colors.green),
                              SizedBox(width: 10),
                              Text("98.8% Uptime"),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            /// QUICK ACTIONS

            const Text(
              "Quick Actions",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

            Wrap(
              spacing: 15,
              runSpacing: 15,
              children: [
                _actionButton(context,Icons.person_add, "Add Admin"),
                _actionButton(context,Icons.store, "Approve Shop"),
                _actionButton(context,Icons.campaign, "Send Notification"),
                _actionButton(context,Icons.discount, "Create Offer"),
                _actionButton(context,Icons.category, "Add Category"),
                _actionButton(context,Icons.inventory, "Add Product"),
              ],
            ),

            const SizedBox(height: 30),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: _boxDecoration(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [

                        Text(
                          "Recent Activities",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        SizedBox(height: 20),

                        ActivityTile(
                          title: "New shop approved",
                          subtitle: "Fashion Hub",
                        ),

                        ActivityTile(
                          title: "Admin created",
                          subtitle: "Rahul Sharma",
                        ),

                        ActivityTile(
                          title: "Product reported",
                          subtitle: "iPhone 15 Pro",
                        ),

                        ActivityTile(
                          title: "Large payout processed",
                          subtitle: "₹85,000",
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 20),

                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: _boxDecoration(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [

                        Text(
                          "Platform Insights",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),

                        SizedBox(height: 20),

                        InsightTile(
                          title: "Top Category",
                          value: "Electronics",
                        ),

                        InsightTile(
                          title: "Top Seller",
                          value: "Mobile World",
                        ),

                        InsightTile(
                          title: "Highest Revenue",
                          value: "₹4.2L Today",
                        ),

                        InsightTile(
                          title: "New Customers Today",
                          value: "+482",
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static BoxDecoration _boxDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(.04),
          blurRadius: 15,
          offset: const Offset(0, 5),
        ),
      ],
    );
  }

  static Widget _statusTile(String title, bool online) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        radius: 6,
        backgroundColor: online ? Colors.green : Colors.red,
      ),
      title: Text(title),
      trailing: Text(
        online ? "Online" : "Offline",
        style: TextStyle(
          color: online ? Colors.green : Colors.red,
        ),
      ),
    );
  }

  static Widget _actionButton(
  BuildContext context,
  IconData icon,
  String title,
) {
  return InkWell(
    borderRadius: BorderRadius.circular(18),
    onTap: () {
      if (title == "Add Admin") {
        context.go('/add-admin');
      }
    },
    child: Container(
      width: 180,
      padding: const EdgeInsets.all(18),
      decoration: _boxDecoration(),
      child: Column(
        children: [
          Icon(icon, size: 32),
          const SizedBox(height: 10),
          Text(title),
        ],
      ),
    ),
  );
}
}

class DashboardCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const DashboardCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
     decoration: _DashboardScreenState._boxDecoration(),
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: const Color(0xffF8F6F1),
            child: Icon(icon),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 5),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}

class ActivityTile extends StatelessWidget {
  final String title;
  final String subtitle;

  const ActivityTile({
    super.key,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const CircleAvatar(
        backgroundColor: Color(0xffF8F6F1),
        child: Icon(Icons.history),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
    );
  }
}

class InsightTile extends StatelessWidget {
  final String title;
  final String value;

  const InsightTile({
    super.key,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      trailing: Text(
        value,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}