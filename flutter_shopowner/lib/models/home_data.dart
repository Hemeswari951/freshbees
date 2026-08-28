class HomeData {
  final String ownerName;
  final String shopName;
  final HomeStats stats;
  final int lowStockCount;
  final PayoutInfo? nextPayout;

  HomeData({
    required this.ownerName,
    required this.shopName,
    required this.stats,
    required this.lowStockCount,
    this.nextPayout,
  });

  factory HomeData.fromJson(Map<String, dynamic> json) {
    return HomeData(
      ownerName: json['owner_name'] ?? '',
      shopName: json['shop_name'] ?? '',
      stats: HomeStats.fromJson(json['stats']),
      lowStockCount: json['low_stock']['count'] ?? 0,
      nextPayout: json['next_payout'] != null
          ? PayoutInfo.fromJson(json['next_payout'])
          : null,
    );
  }
}

class HomeStats {
  final int totalOrders;
  final int ordersChangePercent;
  final double todaysSales;
  final int salesChangePercent;
  final int pendingOrders;
  final int pendingOver24h;
  final double totalRevenue;

  HomeStats({
    required this.totalOrders,
    required this.ordersChangePercent,
    required this.todaysSales,
    required this.salesChangePercent,
    required this.pendingOrders,
    required this.pendingOver24h,
    required this.totalRevenue,
  });

  factory HomeStats.fromJson(Map<String, dynamic> json) {
    return HomeStats(
      totalOrders: json['total_orders'] ?? 0,
      ordersChangePercent: json['orders_change_percent'] ?? 0,
      todaysSales: (json['todays_sales'] ?? 0).toDouble(),
      salesChangePercent: json['sales_change_percent'] ?? 0,
      pendingOrders: json['pending_orders'] ?? 0,
      pendingOver24h: json['pending_over_24h'] ?? 0,
      totalRevenue: (json['total_revenue'] ?? 0).toDouble(),
    );
  }
}

class PayoutInfo {
  final double amount;
  final DateTime requestedAt;

  PayoutInfo({required this.amount, required this.requestedAt});

  factory PayoutInfo.fromJson(Map<String, dynamic> json) {
    return PayoutInfo(
      amount: (json['amount'] ?? 0).toDouble(),
      requestedAt: DateTime.parse(json['requested_at']),
    );
  }
}