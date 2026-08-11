import 'package:flutter/material.dart';

// --- Model for Inventory Data ---
class InventoryItem {
  final String sku;
  final String name;
  final String category;
  final int stock;
  final double price;

  InventoryItem({
    required this.sku,
    required this.name,
    required this.category,
    required this.stock,
    required this.price,
  });

  // Helper to determine status based on stock
  String get status {
    if (stock <= 0) return 'Out of Stock';
    if (stock < 10) return 'Low Stock';
    return 'In Stock';
  }

  Color get statusColor {
    if (stock <= 0) return Colors.red;
    if (stock < 10) return Colors.orange;
    return Colors.green;
  }
}

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  // --- Dummy Data ---
  final List<InventoryItem> _allInventory = [
    InventoryItem(sku: 'PRD-001', name: 'Cotton T-Shirt', category: 'Apparel', stock: 150, price: 19.99),
    InventoryItem(sku: 'PRD-002', name: 'Denim Jeans', category: 'Apparel', stock: 8, price: 49.99),
    InventoryItem(sku: 'PRD-003', name: 'Running Sneakers', category: 'Footwear', stock: 0, price: 89.99),
    InventoryItem(sku: 'PRD-004', name: 'Leather Wallet', category: 'Accessories', stock: 45, price: 29.99),
    InventoryItem(sku: 'PRD-005', name: 'Sunglasses', category: 'Accessories', stock: 12, price: 59.99),
  ];

  List<InventoryItem> _filteredInventory = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _filteredInventory = _allInventory;
  }

  // --- Search Functionality ---
  void _runFilter(String query) {
    List<InventoryItem> results = [];
    if (query.isEmpty) {
      results = _allInventory;
    } else {
      results = _allInventory
          .where((item) =>
              item.name.toLowerCase().contains(query.toLowerCase()) ||
              item.sku.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }
    setState(() {
      _searchQuery = query;
      _filteredInventory = results;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Inherits your dashboard background
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Header & Summary Stats ---
            const Text(
              'Inventory Management',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                _buildStatCard('Total Items', _allInventory.length.toString(), Icons.inventory_2, Colors.blue),
                const SizedBox(width: 16),
                _buildStatCard('Low Stock', _allInventory.where((i) => i.stock > 0 && i.stock < 10).length.toString(), Icons.warning_amber_rounded, Colors.orange),
                const SizedBox(width: 16),
                _buildStatCard('Out of Stock', _allInventory.where((i) => i.stock <= 0).length.toString(), Icons.error_outline, Colors.red),
              ],
            ),
            const SizedBox(height: 24),

            // --- Search & Actions Row ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  width: 300,
                  child: TextField(
                    onChanged: (value) => _runFilter(value),
                    decoration: InputDecoration(
                      hintText: 'Search by Name or SKU...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Implement Add/Export functionality
                  },
                  icon: const Icon(Icons.download),
                  label: const Text('Export CSV'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // --- Data Table ---
            Expanded(
              child: Card(
                elevation: 2,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: SingleChildScrollView(
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.resolveWith((states) => Colors.grey.shade100),
                      columns: const [
                        DataColumn(label: Text('SKU', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Product Name', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Category', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Stock', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Price', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                      rows: _filteredInventory.map((item) {
                        return DataRow(
                          cells: [
                            DataCell(Text(item.sku)),
                            DataCell(Text(item.name, style: const TextStyle(fontWeight: FontWeight.w500))),
                            DataCell(Text(item.category)),
                            DataCell(Text(item.stock.toString())),
                            DataCell(Text('\$${item.price.toStringAsFixed(2)}')),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: item.statusColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  item.status,
                                  style: TextStyle(color: item.statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              ),
                            ),
                            DataCell(
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                                    onPressed: () {
                                      // TODO: Implement Edit action
                                    },
                                    tooltip: 'Edit',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                    onPressed: () {
                                      // TODO: Implement Delete action
                                    },
                                    tooltip: 'Delete',
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Helper Widget for Summary Cards ---
  Widget _buildStatCard(String title, String count, IconData icon, Color color) {
    return Expanded(
      child: Card(
        elevation: 2,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(count, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}