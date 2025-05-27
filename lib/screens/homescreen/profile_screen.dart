import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:foodie_hub/config/constants.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String userEmail = '';
  String userPhone = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
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
            userEmail = userDoc['email'] ?? '';
            userPhone = userDoc['phone'] ?? '';
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching user data: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const SizedBox(height: 16),
              Center(
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    const CircleAvatar(
                      radius: 48,
                      backgroundColor: AppColors.primary,
                      child: Icon(Icons.person, size: 48, color: Colors.white),
                    ),
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: AppColors.primary,
                      child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Text('John Smith', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppColors.textPrimary)),
              const Text('⭐ Gold Member', style: TextStyle(color: AppColors.primary)),
              const Text('Member since 2022', style: TextStyle(color: AppColors.secondaryText)),

              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: const [
                  _InfoTile(title: 'Points', value: '2,450 pts', icon: Icons.card_giftcard),
                  _InfoTile(title: 'Favorites', value: '12', icon: Icons.favorite),
                  _InfoTile(title: 'Orders', value: '24', icon: Icons.shopping_bag),
                ],
              ),

              const SizedBox(height: 24),
              _ContactInfo(email: userEmail, phone: userPhone),
              const SizedBox(height: 24),

              const _SectionTitle(title: 'Address Book'),
              ListTile(
                leading: const Icon(Icons.home, color: AppColors.primary),
                title: const Text('123 Main Street, Apt 4B', style: TextStyle(color: AppColors.textPrimary)),
                subtitle: const Text('New York, NY 10001', style: TextStyle(color: AppColors.secondaryText)),
                trailing: const Icon(Icons.edit, color: AppColors.secondaryText),
              ),
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add, color: AppColors.primary),
                label: const Text('Add New Address', style: TextStyle(color: AppColors.primary)),
              ),

              const SizedBox(height: 16),
              const _GoldStatusBar(),

              const SizedBox(height: 24),
              const _SectionTitle(title: 'Settings'),
              const _ToggleTile(label: 'Dark Mode'),
              const _ToggleTile(label: 'Push Notifications'),
              const _ToggleTile(label: 'Location Services'),

              const SizedBox(height: 16),
              const Divider(),
              const _LinkTile(label: 'Help Center'),
              const _LinkTile(label: 'Terms of Service'),
              const _LinkTile(label: 'Privacy Policy'),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () {
                  FirebaseAuth.instance.signOut();
                },
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text('Sign Out', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Reusable Widgets

class _InfoTile extends StatelessWidget {
  final String title, value;
  final IconData icon;
  const _InfoTile({required this.title, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        Text(title, style: const TextStyle(color: AppColors.secondaryText)),
      ],
    );
  }
}

class _ContactInfo extends StatelessWidget {
  final String email;
  final String phone;
  const _ContactInfo({required this.email, required this.phone});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      color: AppColors.inputBackground,
      child: ListTile(
        title: Text('+91 $phone', style: const TextStyle(color: AppColors.textPrimary)),
        subtitle: Text(email, style: const TextStyle(color: AppColors.secondaryText)),
        trailing: IconButton(
          icon: const Icon(Icons.edit, color: AppColors.primary),
          onPressed: () {},
        ),
      ),
    );
  }
}

class _GoldStatusBar extends StatelessWidget {
  const _GoldStatusBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.inputBorder,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Gold Status', style: TextStyle(color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: 150 / 200,
            backgroundColor: AppColors.inputBackground,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
          const SizedBox(height: 8),
          const Text('Next reward: Free dessert at 200 points', style: TextStyle(color: AppColors.secondaryText)),
        ],
      ),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  final String label;
  const _ToggleTile({required this.label});

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: Text(label, style: const TextStyle(color: AppColors.textPrimary)),
      value: true,
      onChanged: (val) {},
      activeColor: AppColors.primary,
    );
  }
}

class _LinkTile extends StatelessWidget {
  final String label;
  const _LinkTile({required this.label});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label, style: const TextStyle(color: AppColors.textPrimary)),
      trailing: const Icon(Icons.chevron_right, color: AppColors.secondaryText),
      onTap: () {},
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
      ),
    );
  }
}
