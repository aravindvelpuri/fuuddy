import 'dart:developer';
import 'dart:math' show cos;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:foodie_hub/screens/homescreen/order_history_screen.dart';
import 'package:foodie_hub/screens/homescreen/profile_screen.dart';
import 'package:foodie_hub/screens/homescreen/shopping_cart_screen.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:foodie_hub/config/constants.dart';
import 'home_content_body.dart';
import 'custom_bottom_nav_bar.dart';
import 'address_bottom_sheet.dart';
import 'add_address_bottom_sheet.dart';

// Import statements remain unchanged...

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
  bool isCurrentLocationSelected = false;
  List<DocumentSnapshot> restaurants = [];
  List<DocumentSnapshot> categories = [];
  bool isRestaurantLoading = true;
  bool isCategoryLoading = true;

  int _selectedIndex = 0;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      HomeContentBody(
        userName: userName,
        selectedAddress: selectedAddress,
        isLoading: isLoading,
        isAddressLoading: isAddressLoading,
        onAddressTap: _showAddressBottomSheet,
        isCategoryLoading: isCategoryLoading,
        categories: categories,
        isRestaurantLoading: isRestaurantLoading,
        restaurants: restaurants,
      ),
      const OrderHistoryScreen(),
      const ShoppingCartScreen(),
      const ProfileScreen(),
    ];
    _fetchUserData();
    _getCurrentLocation();
    _fetchCategories();
  }

  void _updateHomeContentBody() {
    setState(() {
      _screens[0] = HomeContentBody(
        userName: userName,
        selectedAddress: selectedAddress,
        isLoading: isLoading,
        isAddressLoading: isAddressLoading,
        onAddressTap: _showAddressBottomSheet,
        isCategoryLoading: isCategoryLoading,
        categories: categories,
        isRestaurantLoading: isRestaurantLoading,
        restaurants: restaurants,
      );
    });
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          selectedAddress = 'Location service disabled';
          _updateHomeContentBody();
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            selectedAddress = 'Location permission denied';
            _updateHomeContentBody();
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          selectedAddress = 'Location permission permanently denied';
          _updateHomeContentBody();
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
        String currentAddress =
            '${place.street}, ${place.locality}, ${place.administrativeArea}';
        setState(() {
          currentLocationAddress = currentAddress;
          if (savedAddresses.isEmpty) {
            selectedAddress = currentAddress;
            isCurrentLocationSelected = true;
          }
          _updateHomeContentBody();
        });
        _fetchNearbyRestaurants(position);
      }
    } catch (e) {
      log('Error getting location: $e');
      setState(() {
        selectedAddress = 'Unable to get location';
        _updateHomeContentBody();
      });
    }
  }

  Future<void> _fetchNearbyRestaurants(Position position) async {
    setState(() {
      isRestaurantLoading = true;
      _updateHomeContentBody();
    });

    try {
      const radiusInM = 10000;
      double lat = position.latitude;
      double lng = position.longitude;
      double latDelta = radiusInM / 111320;
      double lngDelta = radiusInM / (111320 * cos(lat * (3.141592653589793 / 180.0)));

      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('restaurants')
          .where('location.latitude', isGreaterThanOrEqualTo: lat - latDelta)
          .where('location.latitude', isLessThanOrEqualTo: lat + latDelta)
          .where('location.longitude', isGreaterThanOrEqualTo: lng - lngDelta)
          .where('location.longitude', isLessThanOrEqualTo: lng + lngDelta)
          .where('isActive', isEqualTo: true)
          .limit(10)
          .get();

      setState(() {
        restaurants = snapshot.docs;
        _updateHomeContentBody();
      });
    } catch (e) {
      log('Error fetching restaurants: $e');
    } finally {
      setState(() {
        isRestaurantLoading = false;
        _updateHomeContentBody();
      });
    }
  }

  Future<void> _fetchCategories() async {
    setState(() {
      isCategoryLoading = true;
      _updateHomeContentBody();
    });

    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('categories')
          .where('isActive', isEqualTo: true)
          .orderBy('order')
          .limit(8)
          .get();

      setState(() {
        categories = snapshot.docs;
        _updateHomeContentBody();
      });
    } catch (e) {
      log('Error fetching categories: $e');
    } finally {
      setState(() {
        isCategoryLoading = false;
        _updateHomeContentBody();
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
            _updateHomeContentBody();
          });
        }
        await _fetchSavedAddresses(user.uid);
      }
    } catch (e) {
      log('Error fetching user data: $e');
    } finally {
      setState(() {
        isLoading = false;
        _updateHomeContentBody();
      });
    }
  }

  Future<void> _fetchSavedAddresses(String userId) async {
    setState(() {
      isAddressLoading = true;
      _updateHomeContentBody();
    });

    try {
      QuerySnapshot addressSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('addresses')
          .orderBy('isDefault', descending: true)
          .get();

      List<Map<String, dynamic>> addresses = addressSnapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
          .toList();

      setState(() {
        savedAddresses = addresses;
        if (addresses.isNotEmpty) {
          selectedAddress = addresses.firstWhere(
                (address) => address['isDefault'] == true,
            orElse: () => addresses.first,
          )['formattedAddress'];
          isCurrentLocationSelected = false;
        }
        _updateHomeContentBody();
      });
    } catch (e) {
      log('Error fetching addresses: $e');
    } finally {
      setState(() {
        isAddressLoading = false;
        _updateHomeContentBody();
      });
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
      builder: (BuildContext context) {
        return AddressBottomSheet(
          currentLocationAddress: currentLocationAddress,
          isCurrentLocationSelected: isCurrentLocationSelected,
          savedAddresses: savedAddresses,
          onCurrentLocationTap: () {
            setState(() {
              selectedAddress = currentLocationAddress;
              isCurrentLocationSelected = true;
              _updateHomeContentBody();
            });
            Navigator.pop(context);
            if (currentPosition != null) {
              _fetchNearbyRestaurants(currentPosition!);
            }
          },
          onSavedAddressTap: (address) {
            setState(() {
              selectedAddress = address['formattedAddress'];
              isCurrentLocationSelected = false;
              _updateHomeContentBody();
            });
            Navigator.pop(context);
            if (address['latitude'] != null && address['longitude'] != null) {
              _fetchNearbyRestaurants(
                Position(
                  latitude: address['latitude'],
                  longitude: address['longitude'],
                  timestamp: DateTime.now(),
                  accuracy: 0,
                  altitude: 0,
                  heading: 0,
                  speed: 0,
                  speedAccuracy: 0,
                  altitudeAccuracy: 0.0,
                  headingAccuracy: 0.0,
                  floor: null,
                  isMocked: false,
                ),
              );
            }
          },
          onAddNewAddressTap: _showAddAddressBottomSheet,
        );
      },
    );
  }

  void _showAddAddressBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return AddAddressBottomSheet(
          onSaveAddress: (address, landmark, type, isDefault) async {
            try {
              final user = FirebaseAuth.instance.currentUser;
              if (user == null) return;

              if (isDefault) {
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

              List<Location> locations = await locationFromAddress(address);
              GeoPoint? addressGeoPoint;
              if (locations.isNotEmpty) {
                addressGeoPoint = GeoPoint(
                  locations.first.latitude,
                  locations.first.longitude,
                );
              }

              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .collection('addresses')
                  .add({
                'formattedAddress': address,
                'landmark': landmark,
                'type': type,
                'isDefault': isDefault,
                'latitude': addressGeoPoint?.latitude,
                'longitude': addressGeoPoint?.longitude,
                'createdAt': FieldValue.serverTimestamp(),
              });

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
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        backgroundColor: AppColors.background,
        extendBody: true,
        body: _screens[_selectedIndex],
        bottomNavigationBar: CustomBottomNavBar(
          selectedIndex: _selectedIndex,
          onItemSelected: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
        ),
      ),
    );
  }
}
