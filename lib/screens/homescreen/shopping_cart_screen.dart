import 'package:flutter/material.dart';
import 'package:foodie_hub/config/constants.dart';

class ShoppingCartScreen extends StatelessWidget {
  const ShoppingCartScreen({super.key});

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
              // Header
              Row(
                children: const [
                  Icon(Icons.restaurant_menu, color: AppColors.primary),
                  SizedBox(width: 8),
                  Text(
                    'Burger Haven',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                '2 items • \$12 away from free delivery',
                style: TextStyle(color: AppColors.secondaryText),
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: 0.4,
                color: AppColors.primary,
                backgroundColor: AppColors.inputBorder.withAlpha((0.4 * 255).round()),
              ),
              const SizedBox(height: 16),

              // Item cards
              _buildCartItem(
                image: 'assets/food1.png',
                title: 'Double Cheeseburger',
                subtitle: 'Extra cheese, No onion',
                price: '\$9.99',
                tag: 'Bestseller',
                tagColor: Colors.red,
                quantity: 2,
                indicatorColor: Colors.red,
              ),
              _buildCartItem(
                image: 'assets/food1.png',
                title: 'Classic Fries',
                subtitle: 'Large',
                price: '\$4.99',
                tag: 'Meal Deal',
                tagColor: AppColors.secondaryText,
                quantity: 1,
                indicatorColor: Colors.green,
              ),

              const SizedBox(height: 20),
              const Text(
                'Complete your meal!',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),

              // Add-ons - HORIZONTAL SCROLL
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    SizedBox(
                      width: 140,
                      child: _buildAddOn(title: 'Soft Drink', price: '+\$2.49'),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 140,
                      child: _buildAddOn(title: 'Extra Sauce', price: '+\$0.99'),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 140,
                      child: _buildAddOn(title: 'Dessert', price: '+\$3.99'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Price Summary
              _buildPriceRow('Subtotal', '\$19.98'),
              _buildPriceRow('Delivery Fee', '\$3.99', override: 'FREE', overrideColor: Colors.green),
              _buildPriceRow('Taxes', '\$1.20'),
              const Divider(thickness: 1, height: 24),
              _buildPriceRow('Total', '\$21.18', isBold: true),
              const SizedBox(height: 20),

              // Promo Code
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Got a code?',
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.inputBorder),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {},
                    child: const Text('Apply'),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Payment Methods & Info
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.credit_card, size: 24),
                  SizedBox(width: 4),
                  Icon(Icons.credit_card, size: 24),
                  SizedBox(width: 4),
                  Icon(Icons.credit_card, size: 24),
                ],
              ),
              const SizedBox(height: 8),
              const Center(
                child: Text(
                  '3 people bought this recently',
                  style: TextStyle(color: AppColors.secondaryText),
                ),
              ),
              const SizedBox(height: 16),

              // Secure Checkout Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  icon: const Icon(Icons.lock),
                  label: const Text(
                    'Secure Checkout',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onPressed: () {},
                ),
              ),
              const SizedBox(height: 12),

              // Bottom Options
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.schedule, color: Colors.grey),
                    label: Text(
                      'Schedule Order',
                      style: TextStyle(color: Colors.grey[800]),
                    ),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      side: BorderSide(color: AppColors.inputBorder),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.bookmark_border, color: Colors.grey),
                    label: Text(
                      'Save for Later',
                      style: TextStyle(color: Colors.grey[800]),
                    ),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      side: BorderSide(color: AppColors.inputBorder),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCartItem({
    required String image,
    required String title,
    required String subtitle,
    required String price,
    required String tag,
    required Color tagColor,
    required int quantity,
    required Color indicatorColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(image, width: 60, height: 60, fit: BoxFit.cover),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: CircleAvatar(
                  backgroundColor: indicatorColor,
                  radius: 4,
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(color: AppColors.secondaryText, fontSize: 12)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: tagColor..withAlpha((0.1 * 255).round()),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(tag, style: TextStyle(fontSize: 12, color: tagColor)),
                ),
              ],
            ),
          ),
          Column(
            children: [
              Text(price, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.remove, size: 20),
                  const SizedBox(width: 4),
                  Text('$quantity'),
                  const SizedBox(width: 4),
                  const Icon(Icons.add, size: 20),
                ],
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _buildAddOn({required String title, required String price}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(price, style: const TextStyle(color: AppColors.secondaryText)),
          const SizedBox(height: 8),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {},
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String value,
      {bool isBold = false, String? override, Color? overrideColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: AppColors.textPrimary, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Row(
            children: [
              if (override != null)
                Text(
                  value,
                  style: const TextStyle(
                    decoration: TextDecoration.lineThrough,
                    color: Colors.grey,
                    fontSize: 13,
                  ),
                ),
              const SizedBox(width: 4),
              Text(
                override ?? value,
                style: TextStyle(
                  color: overrideColor ?? AppColors.textPrimary,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
