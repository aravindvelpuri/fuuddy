import 'package:flutter/material.dart';
import 'package:foodie_hub/config/constants.dart';

class AddressBottomSheet extends StatelessWidget {
  final String currentLocationAddress;
  final bool isCurrentLocationSelected;
  final List<Map<String, dynamic>> savedAddresses;
  final VoidCallback onCurrentLocationTap;
  final Function(Map<String, dynamic>) onSavedAddressTap;
  final VoidCallback onAddNewAddressTap;

  const AddressBottomSheet({super.key,
    required this.currentLocationAddress,
    required this.isCurrentLocationSelected,
    required this.savedAddresses,
    required this.onCurrentLocationTap,
    required this.onSavedAddressTap,
    required this.onAddNewAddressTap,
  });

  IconData _getAddressIcon(String type) {
    switch (type) {
      case 'home':
        return Icons.home;
      case 'work':
        return Icons.work;
      default:
        return Icons.location_on;
    }
  }

  String _getAddressTitle(String type) {
    switch (type) {
      case 'home':
        return 'Home';
      case 'work':
        return 'Work';
      default:
        return 'Other';
    }
  }

  Widget _buildAddressTile({
    required IconData icon,
    required String title,
    required String subtitle,
    bool isDefault = false,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title),
      subtitle: Text(
        subtitle,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: AppColors.secondaryText),
      ),
      trailing: isDefault
          ? Icon(Icons.check, color: AppColors.primary)
          : null,
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Container(
        padding: const EdgeInsets.all(20),
        height: MediaQuery.of(context).size.height * 0.8,
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Select Delivery Location',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: AppColors.textPrimary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            IgnorePointer(
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search for area, street name...',
                  prefixIcon: Icon(Icons.search, color: AppColors.primary),
                  filled: true,
                  fillColor: AppColors.inputBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.inputBorder),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'SAVED ADDRESSES',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.secondaryText,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                children: [
                  if (currentLocationAddress.isNotEmpty)
                    _buildAddressTile(
                      icon: Icons.my_location,
                      title: 'Use current location',
                      subtitle: currentLocationAddress,
                      isDefault: isCurrentLocationSelected,
                      onTap: onCurrentLocationTap,
                    ),
                  ...savedAddresses.map((address) => _buildAddressTile(
                    icon: _getAddressIcon(address['type']),
                    title: _getAddressTitle(address['type']),
                    subtitle: address['formattedAddress'],
                    isDefault: address['isDefault'] == true && !isCurrentLocationSelected,
                    onTap: () => onSavedAddressTap(address),
                  )),
                  ListTile(
                    leading: Icon(Icons.add, color: AppColors.primary),
                    title: const Text('Add new address'),
                    onTap: onAddNewAddressTap,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}