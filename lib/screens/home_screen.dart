import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:foodie_hub/config/constants.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String userName = 'Hello!';
  String selectedAddress = 'Fetching location...';
  bool isLoading = true;
  bool isAddressLoading = false;
  List<Map<String, dynamic>> savedAddresses = [];
  Position? currentPosition;
  String currentLocationAddress = '';

  // Address form controllers
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _landmarkController = TextEditingController();
  String _selectedAddressType = 'home';
  bool _isDefaultAddress = false;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _addressController.dispose();
    _landmarkController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          selectedAddress = 'Location service disabled';
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            selectedAddress = 'Location permission denied';
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          selectedAddress = 'Location permission permanently denied';
        });
        return;
      }

      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        currentPosition = position;
      });

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        String currentAddress = '${place.street}, ${place.locality}, ${place.administrativeArea}';
        setState(() {
          currentLocationAddress = currentAddress;
          if (savedAddresses.isEmpty) {
            selectedAddress = currentAddress;
          }
        });
      }
    } catch (e) {
      log('Error getting location: $e');
      setState(() {
        selectedAddress = 'Unable to get location';
      });
    }
  }

  Future<void> _fetchUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          setState(() {
            userName = userDoc['fullName'] ?? 'Hello!';
          });
        }

        await _fetchSavedAddresses(user.uid);
      }
    } catch (e) {
      log('Error fetching user data: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _fetchSavedAddresses(String userId) async {
    setState(() {
      isAddressLoading = true;
    });

    try {
      QuerySnapshot addressSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('addresses')
          .orderBy('isDefault', descending: true) // Default addresses first
          .get();

      List<Map<String, dynamic>> addresses = addressSnapshot.docs
          .map((doc) => {
        'id': doc.id,
        ...doc.data() as Map<String, dynamic>,
      })
          .toList();

      setState(() {
        savedAddresses = addresses;
        if (addresses.isNotEmpty) {
          selectedAddress = addresses.firstWhere(
                (address) => address['isDefault'] == true,
            orElse: () => addresses.first,
          )['formattedAddress'];
        }
      });
    } catch (e) {
      log('Error fetching addresses: $e');
    } finally {
      setState(() {
        isAddressLoading = false;
      });
    }
  }

  Future<void> _saveAddress() async {
    if (_addressController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid address')),
      );
      return;
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // If this is being set as default, unset any existing default
      if (_isDefaultAddress) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('addresses')
            .where('isDefault', isEqualTo: true)
            .get()
            .then((snapshot) {
          for (var doc in snapshot.docs) {
            doc.reference.update({'isDefault': false});
          }
        });
      }

      // Add the new address
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('addresses')
          .add({
        'formattedAddress': _addressController.text,
        'landmark': _landmarkController.text,
        'type': _selectedAddressType,
        'isDefault': _isDefaultAddress,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Refresh addresses
      await _fetchSavedAddresses(user.uid);

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Address saved successfully')),
      );
    } catch (e) {
      log('Error saving address: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save address')),
      );
    }
  }

  void _showAddressBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return _buildAddressBottomSheet();
      },
    );
  }

  Widget _buildAddressBottomSheet() {
    return Container(
      padding: const EdgeInsets.all(20),
      height: MediaQuery.of(context).size.height * 0.8,
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Delivery Location',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
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
                  ListTile(
                    leading: Icon(Icons.my_location, color: AppColors.primary),
                    title: const Text('Use current location'),
                    subtitle: Text(
                      currentLocationAddress,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: AppColors.secondaryText),
                    ),
                    onTap: () {
                      setState(() {
                        selectedAddress = currentLocationAddress;
                      });
                      Navigator.pop(context);
                    },
                  ),
                ...savedAddresses.map((address) => ListTile(
                  leading: Icon(
                    address['type'] == 'home'
                        ? Icons.home
                        : address['type'] == 'work'
                        ? Icons.work
                        : Icons.location_on,
                    color: AppColors.primary,
                  ),
                  title: Text(
                    address['type'] == 'home'
                        ? 'Home'
                        : address['type'] == 'work'
                        ? 'Work'
                        : 'Other',
                  ),
                  subtitle: Text(
                    address['formattedAddress'],
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: AppColors.secondaryText),
                  ),
                  trailing: address['isDefault'] == true
                      ? Icon(Icons.check, color: AppColors.primary)
                      : null,
                  onTap: () {
                    setState(() {
                      selectedAddress = address['formattedAddress'];
                    });
                    Navigator.pop(context);
                  },
                )),
                ListTile(
                  leading: Icon(Icons.add, color: AppColors.primary),
                  title: const Text('Add new address'),
                  onTap: _showAddAddressBottomSheet,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddAddressBottomSheet() {
    // Clear previous inputs
    _addressController.clear();
    _landmarkController.clear();
    _selectedAddressType = 'home';
    _isDefaultAddress = false;

    Navigator.pop(context); // Close the previous bottom sheet
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add New Address',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _addressController,
                  decoration: InputDecoration(
                    labelText: 'Complete Address*',
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors.inputBorder),
                    ),
                  ),
                  maxLines: 3,
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _landmarkController,
                  decoration: InputDecoration(
                    labelText: 'Landmark (Optional)',
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors.inputBorder),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedAddressType,
                  decoration: InputDecoration(
                    labelText: 'Address Type',
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors.inputBorder),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(
                        value: 'home', child: Text('Home Address')),
                    DropdownMenuItem(
                        value: 'work', child: Text('Work Address')),
                    DropdownMenuItem(
                        value: 'other', child: Text('Other Address')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedAddressType = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Checkbox(
                      value: _isDefaultAddress,
                      onChanged: (value) {
                        setState(() {
                          _isDefaultAddress = value ?? false;
                        });
                      },
                      activeColor: AppColors.primary,
                    ),
                    Text(
                      'Set as default address',
                      style: TextStyle(color: AppColors.textPrimary),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Cancel',
                        style: TextStyle(color: AppColors.primary),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _saveAddress,
                      child: const Text('Save Address'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isLoading ? 'Hello!' : 'Hello, $userName!',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.location_on,
                              size: 16, color: AppColors.primary),
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: _showAddressBottomSheet,
                            child: SizedBox(
                              width: MediaQuery.of(context).size.width * 0.5,
                              child: Text(
                                isAddressLoading
                                    ? 'Loading addresses...'
                                    : selectedAddress,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.secondaryText,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: Icon(Icons.keyboard_arrow_down,
                                size: 16, color: AppColors.primary),
                            onPressed: _showAddressBottomSheet,
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(Icons.notifications_none,
                        color: AppColors.textPrimary),
                    onPressed: () {},
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Search Bar
              TextField(
                decoration: InputDecoration(
                  hintText: 'Search for restaurants, cuisines, or dishes',
                  prefixIcon: Icon(Icons.search, color: AppColors.primary),
                  filled: true,
                  fillColor: AppColors.inputBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide(color: AppColors.inputBorder),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
              const SizedBox(height: 20),

              // Promo Banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.local_offer, color: AppColors.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Get 30% OFF your first order!',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Use code: WELCOME30',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.chevron_right, color: AppColors.primary),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Categories
              Text(
                'Categories',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 100,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildCategory('Sushi', Icons.restaurant),
                    _buildCategory('Burgers', Icons.fastfood),
                    _buildCategory('Pizza', Icons.local_pizza),
                    _buildCategory('Asian', Icons.ramen_dining),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Featured Restaurants
              Text(
                'Featured Restaurants',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                      child: _buildRestaurantCard(
                          'Burger Haven', '15–25 min • \$3.99 delivery', '4.8 (200+)')),
                  const SizedBox(width: 16),
                  Expanded(
                      child: _buildRestaurantCard(
                          'Popular Pizza Palace', '20–35 min • \$', '4.6 (150+)')),
                ],
              ),
              const SizedBox(height: 24),

              // Filter Section
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('Under 30 min'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Cuisine'),
                    const SizedBox(width: 8),
                    _buildFilterChip('★ 4.0+'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Free Delivery'),
                    const SizedBox(width: 8),
                    _buildFilterChip('New'),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Trending Nearby
              Text(
                'Trending Nearby',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              _buildTrendingRestaurant(
                  'Taco Fiesta', 'Mexican • 20–30 min', '4.5 (150+)', '\$2.99'),
              const SizedBox(height: 12),
              _buildTrendingRestaurant(
                  'Sushi Master', 'Japanese • 25–35 min', '4.7 (180+)', '\$3.99'),
              const SizedBox(height: 12),
              _buildTrendingRestaurant(
                  'Pasta Paradise', 'Italian • 15–25 min', '4.6 (120+)', '\$1.99'),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.secondaryText,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt),
            label: 'Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Cart',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildCategory(String name, IconData icon) {
    return Container(
      width: 80,
      margin: const EdgeInsets.only(right: 16),
      child: Column(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: AppColors.inputBackground,
            child: Icon(icon, size: 30, color: AppColors.primary),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRestaurantCard(String name, String details, String rating) {
    return Card(
      color: AppColors.inputBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.inputBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              name,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              details,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.secondaryText,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.star, size: 16, color: Colors.orange),
                const SizedBox(width: 4),
                Text(
                  rating,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.secondaryText,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    return Chip(
      label: Text(
        label,
        style: TextStyle(color: AppColors.textPrimary),
      ),
      backgroundColor: AppColors.inputBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: AppColors.inputBorder),
      ),
    );
  }

  Widget _buildTrendingRestaurant(
      String name, String details, String rating, String price) {
    return Card(
      color: AppColors.inputBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.inputBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    details,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.secondaryText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 16, color: Colors.orange),
                      const SizedBox(width: 4),
                      Text(
                        rating,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Text(
              price,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}