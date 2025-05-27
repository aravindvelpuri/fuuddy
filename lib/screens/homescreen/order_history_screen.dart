import 'package:flutter/material.dart';
import 'package:foodie_hub/config/constants.dart'; // Ensure AppColors is defined here

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  int selectedFilter = 0;
  final List<String> filters = ['All Orders', 'Last 30 Days', 'Favorites'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Order History',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 16),

              // Toggle buttons
              Container(
                decoration: BoxDecoration(
                  color: AppColors.inputBorder.withAlpha((0.2 * 255).round()),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: List.generate(filters.length, (index) {
                    final isSelected = selectedFilter == index;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => selectedFilter = index),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primary : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            filters[index],
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 16),

              // Search Bar
              TextField(
                decoration: InputDecoration(
                  hintText: 'Search past orders...',
                  prefixIcon: const Icon(Icons.search, color: AppColors.secondaryText),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.inputBorder),
                  ),
                  filled: true,
                  fillColor: AppColors.inputBackground,
                  hintStyle: const TextStyle(color: AppColors.secondaryText),
                ),
              ),
              const SizedBox(height: 16),

              // Sort Dropdown
              Row(
                children: [
                  const Text(
                    'Sort by: ',
                    style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  DropdownButton<String>(
                    value: 'Recent Orders',
                    underline: const SizedBox(),
                    dropdownColor: Colors.white,
                    iconEnabledColor: AppColors.primary,
                    items: ['Recent Orders', 'Oldest First']
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (_) {},
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Orders
              _buildOrderCard(
                restaurantName: 'Burger King',
                status: 'Delivered',
                statusColor: Colors.green,
                statusIcon: Icons.check_circle,
                dateTime: 'May 15, 2023 • 12:45 PM',
                total: '\$24.97',
                images: ['🍔', '🍕', '🥗'],
              ),
              _buildOrderCard(
                restaurantName: 'Pizza Hut',
                status: 'Cancelled',
                statusColor: Colors.red,
                statusIcon: Icons.cancel,
                dateTime: 'May 14, 2023 • 7:30 PM',
                total: '\$32.50',
                images: ['🍔', '🌮'],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderCard({
    required String restaurantName,
    required String status,
    required Color statusColor,
    required IconData statusIcon,
    required String dateTime,
    required String total,
    required List<String> images,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.inputBorder.withAlpha((0.25 * 255).round()), // Darker card background
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                restaurantName,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
              ),
              Row(
                children: [
                  Icon(statusIcon, color: statusColor, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    status,
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(dateTime, style: const TextStyle(color: AppColors.secondaryText, fontSize: 13)),
          const SizedBox(height: 8),

          // Items
          Row(
            children: images
                .map((emoji) => Padding(
              padding: const EdgeInsets.only(right: 4),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: Colors.white,
                child: Text(emoji, style: const TextStyle(fontSize: 18)),
              ),
            ))
                .toList(),
          ),
          const SizedBox(height: 8),

          // Price
          Text(
            total,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),

          // Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {},
                  child: const Text(
                    'Reorder',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              TextButton(
                onPressed: () {},
                child: const Text(
                  'Rate Order',
                  style: TextStyle(color: AppColors.secondaryText),
                ),
              )
            ],
          ),
        ],
      ),
    );
  }
}
