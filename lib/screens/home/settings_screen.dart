import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:uber_app/screens/auth/login_screen.dart';
import 'package:uber_app/screens/home/faqs_screen.dart';
import 'package:uber_app/screens/home/support_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;
  bool _locationTracking = true;
  bool _biometricAuth = false;
  bool _emailNotifications = true;
  bool _smsNotifications = true;
  bool _promotionalOffers = false;
  bool _driverRatings = true;
  bool _autoSavePhotos = false;
  String _selectedLanguage = 'English';
  String _selectedCurrency = 'USD';
  String _selectedDistanceUnit = 'Kilometers';

  final List<String> _languages = [
    'English',
    'Spanish',
    'French',
    'German',
    'Chinese',
  ];
  final List<String> _currencies = ['USD', 'EUR', 'GBP', 'INR', 'CAD', 'AUD'];
  final List<String> _distanceUnits = ['Kilometers', 'Miles'];

  Future<void> _handleLogout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();

      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logout failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: CustomScrollView(
        slivers: [
          // App Bar with Gradient
          SliverAppBar(
            expandedHeight: 180,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Settings',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                  color: Colors.transparent,
                ),
              ),
              centerTitle: true,
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFFFF6B35),
                      const Color(0xFFFF8B35),
                      const Color(0xFFFFA726),
                    ],
                  ),
                ),
                child: const Align(
                  alignment: Alignment.bottomLeft,
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Customize Your Experience',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Manage your account & preferences',
                          style: TextStyle(fontSize: 14, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Settings Content
          SliverList(
            delegate: SliverChildListDelegate([
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    // User Profile Card
                    _buildUserProfileCard(),
                    const SizedBox(height: 25),

                    // Account Settings
                    _buildSectionHeader(
                      'Account Settings',
                      Icons.account_circle,
                    ),
                    _buildSettingsCard(
                      children: [
                        _buildSettingsItem(
                          icon: Icons.person_outline,
                          title: 'Edit Profile',
                          subtitle: 'Update your personal information',
                          onTap: () => _navigateToEditProfile(),
                        ),
                        _buildDivider(),
                        _buildSettingsItem(
                          icon: Icons.phone_android,
                          title: 'Phone Number',
                          subtitle: '+1 (234) 567-8900',
                          onTap: () => _navigateToPhoneSettings(),
                        ),
                        _buildDivider(),
                        _buildSettingsItem(
                          icon: Icons.email_outlined,
                          title: 'Email Address',
                          subtitle: 'hamza@gmail.com',
                          onTap: () => _navigateToEmailSettings(),
                        ),
                        _buildDivider(),
                        _buildSettingsItem(
                          icon: Icons.lock_outline,
                          title: 'Change Password',
                          subtitle: 'Update your login password',
                          onTap: () => _navigateToPasswordSettings(),
                        ),
                      ],
                    ),

                    // App Preferences
                    _buildSectionHeader('App Preferences', Icons.settings),
                    _buildSettingsCard(
                      children: [
                        _buildToggleItem(
                          icon: Icons.notifications_active,
                          title: 'Push Notifications',
                          subtitle: 'Receive app notifications',
                          value: _notificationsEnabled,
                          onChanged: (value) {
                            setState(() {
                              _notificationsEnabled = value;
                            });
                          },
                        ),
                        _buildDivider(),
                        _buildToggleItem(
                          icon: Icons.dark_mode,
                          title: 'Dark Mode',
                          subtitle: 'Switch to dark theme',
                          value: _darkModeEnabled,
                          onChanged: (value) {
                            setState(() {
                              _darkModeEnabled = value;
                            });
                          },
                        ),
                        _buildDivider(),
                        _buildToggleItem(
                          icon: Icons.location_on,
                          title: 'Location Tracking',
                          subtitle: 'Allow location access',
                          value: _locationTracking,
                          onChanged: (value) {
                            setState(() {
                              _locationTracking = value;
                            });
                          },
                        ),
                        _buildDivider(),
                        _buildToggleItem(
                          icon: Icons.fingerprint,
                          title: 'Biometric Authentication',
                          subtitle: 'Use fingerprint/face ID',
                          value: _biometricAuth,
                          onChanged: (value) {
                            setState(() {
                              _biometricAuth = value;
                            });
                          },
                        ),
                      ],
                    ),

                    // Notification Settings
                    _buildSectionHeader(
                      'Notification Settings',
                      Icons.notifications,
                    ),
                    _buildSettingsCard(
                      children: [
                        _buildToggleItem(
                          icon: Icons.email,
                          title: 'Email Notifications',
                          subtitle: 'Receive updates via email',
                          value: _emailNotifications,
                          onChanged: (value) {
                            setState(() {
                              _emailNotifications = value;
                            });
                          },
                        ),
                        _buildDivider(),
                        _buildToggleItem(
                          icon: Icons.sms,
                          title: 'SMS Notifications',
                          subtitle: 'Receive text messages',
                          value: _smsNotifications,
                          onChanged: (value) {
                            setState(() {
                              _smsNotifications = value;
                            });
                          },
                        ),
                        _buildDivider(),
                        _buildToggleItem(
                          icon: Icons.local_offer,
                          title: 'Promotional Offers',
                          subtitle: 'Receive special deals',
                          value: _promotionalOffers,
                          onChanged: (value) {
                            setState(() {
                              _promotionalOffers = value;
                            });
                          },
                        ),
                        _buildDivider(),
                        _buildToggleItem(
                          icon: Icons.star_rate,
                          title: 'Driver Ratings',
                          subtitle: 'Rate your drivers after trips',
                          value: _driverRatings,
                          onChanged: (value) {
                            setState(() {
                              _driverRatings = value;
                            });
                          },
                        ),
                      ],
                    ),

                    // App Settings
                    _buildSectionHeader('App Settings', Icons.apps),
                    _buildSettingsCard(
                      children: [
                        _buildDropdownItem(
                          icon: Icons.language,
                          title: 'Language',
                          subtitle: 'App language',
                          value: _selectedLanguage,
                          items: _languages,
                          onChanged: (value) {
                            setState(() {
                              _selectedLanguage = value!;
                            });
                          },
                        ),
                        _buildDivider(),
                        _buildDropdownItem(
                          icon: Icons.attach_money,
                          title: 'Currency',
                          subtitle: 'Display currency',
                          value: _selectedCurrency,
                          items: _currencies,
                          onChanged: (value) {
                            setState(() {
                              _selectedCurrency = value!;
                            });
                          },
                        ),
                        _buildDivider(),
                        _buildDropdownItem(
                          icon: Icons.straighten,
                          title: 'Distance Unit',
                          subtitle: 'Measurement system',
                          value: _selectedDistanceUnit,
                          items: _distanceUnits,
                          onChanged: (value) {
                            setState(() {
                              _selectedDistanceUnit = value!;
                            });
                          },
                        ),
                        _buildDivider(),
                        _buildToggleItem(
                          icon: Icons.photo,
                          title: 'Auto-save Photos',
                          subtitle: 'Save delivery photos automatically',
                          value: _autoSavePhotos,
                          onChanged: (value) {
                            setState(() {
                              _autoSavePhotos = value;
                            });
                          },
                        ),
                      ],
                    ),

                    // Support & Legal
                    _buildSectionHeader('Support & Legal', Icons.help_outline),
                    _buildSettingsCard(
                      children: [
                        _buildSettingsItem(
                          icon: Icons.question_answer,
                          title: 'FAQs',
                          subtitle: 'Frequently asked questions',
                          onTap: () => _navigateToFAQs(),
                        ),
                        _buildDivider(),
                        _buildSettingsItem(
                          icon: Icons.headset_mic,
                          title: 'Contact Support',
                          subtitle: 'Get help from our team',
                          onTap: () => _navigateToSupport(),
                        ),
                        _buildDivider(),
                        _buildSettingsItem(
                          icon: Icons.privacy_tip,
                          title: 'Privacy Policy',
                          subtitle: 'How we handle your data',
                          onTap: () => _navigateToPrivacyPolicy(),
                        ),
                        _buildDivider(),
                        _buildSettingsItem(
                          icon: Icons.description,
                          title: 'Terms of Service',
                          subtitle: 'App usage terms',
                          onTap: () => _navigateToTerms(),
                        ),
                        _buildDivider(),
                        _buildSettingsItem(
                          icon: Icons.security,
                          title: 'Security',
                          subtitle: 'Security measures & tips',
                          onTap: () => _navigateToSecurity(),
                        ),
                      ],
                    ),

                    // App Version & Actions
                    _buildAppInfoCard(),
                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                           Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LoginScreen(),
                          ),
                        );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFFF6B35),
                          side: const BorderSide(color: Color(0xFFFF6B35)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.logout, size: 20),
                            SizedBox(width: 10),
                            Text(
                              'Logout',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  // User Profile Card Widget
  Widget _buildUserProfileCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [const Color(0xFFFF6B35), const Color(0xFFFF8B35)],
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF6B35).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          // Profile Avatar
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              color: Colors.white.withOpacity(0.2),
            ),
            child: const Icon(Icons.person, size: 40, color: Colors.white),
          ),
          const SizedBox(width: 20),

          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Hamza Khalid',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Premium Member',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),

          // Edit Button
          IconButton(
            onPressed: () => _navigateToEditProfile(),
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.2),
              ),
              child: const Icon(Icons.edit, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  // Section Header Widget
  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(top: 25, bottom: 15),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFF6B35).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFFFF6B35), size: 20),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  // Settings Card Widget
  Widget _buildSettingsCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  // Settings Item Widget
  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFFF6B35).withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: const Color(0xFFFF6B35), size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 16,
          color: Colors.black87,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }

  // Toggle Item Widget
  Widget _buildToggleItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFFF6B35).withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: const Color(0xFFFF6B35), size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 16,
          color: Colors.black87,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: const Color(0xFFFF6B35),
        activeTrackColor: const Color(0xFFFF6B35).withOpacity(0.5),
      ),
    );
  }

  // Dropdown Item Widget
  Widget _buildDropdownItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFFF6B35).withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: const Color(0xFFFF6B35), size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 16,
          color: Colors.black87,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
      ),
      trailing: DropdownButton<String>(
        value: value,
        icon: const Icon(Icons.arrow_drop_down, color: Color(0xFFFF6B35)),
        underline: const SizedBox(),
        onChanged: onChanged,
        items: items.map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value, style: const TextStyle(color: Colors.black87)),
          );
        }).toList(),
      ),
    );
  }

  // Divider Widget
  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Divider(height: 1, color: Colors.grey[300]),
    );
  }

  // App Info Card
  Widget _buildAppInfoCard() {
    return Container(
      margin: const EdgeInsets.only(top: 25),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFFF6B35), Color(0xFFFFA726)],
                  ),
                ),
                child: const Icon(
                  Icons.local_shipping,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(width: 15),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Truck Delivery Pro',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    'Version 2.5.1 • Build 245',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 15),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: [
              _buildInfoButton('Rate App', Icons.star_rate, () => _rateApp()),
              _buildInfoButton('Share App', Icons.share, () => _shareApp()),
              _buildInfoButton(
                'Check Updates',
                Icons.system_update,
                () => _checkForUpdates(),
              ),
              _buildInfoButton(
                'Clear Cache',
                Icons.delete_sweep,
                () => _clearCache(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Info Button Widget
  Widget _buildInfoButton(String text, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: const Color(0xFFFF6B35)),
            const SizedBox(width: 6),
            Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Navigation Methods
  void _navigateToEditProfile() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: const Text('Edit Profile screen would open here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _navigateToPhoneSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Phone Settings'),
        content: const Text('Phone settings screen would open here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _navigateToEmailSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Email Settings'),
        content: const Text('Email settings screen would open here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _navigateToPasswordSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: const Text('Change password screen would open here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _navigateToFAQs() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FAQScreen()),
    );
  }

  void _navigateToSupport() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SupportScreen()),
    );
  }

  void _navigateToPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: const SingleChildScrollView(
          child: Text(
            'Privacy Policy content would be displayed here. This would include information about how we collect, use, and protect your personal data.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _navigateToTerms() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terms of Service'),
        content: const SingleChildScrollView(
          child: Text(
            'Terms of Service content would be displayed here. This would include the rules and guidelines for using our app.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _navigateToSecurity() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Security'),
        content: const SingleChildScrollView(
          child: Text(
            'Security information and tips would be displayed here. Learn how to keep your account secure.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // Action Methods
  void _rateApp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rate Our App'),
        content: const Text(
          'Would you like to rate Truck Delivery App on the store?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Not Now'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Implement actual rating functionality
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B35),
            ),
            child: const Text('Rate Now'),
          ),
        ],
      ),
    );
  }

  void _shareApp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Share App'),
        content: const Text('Share Truck Delivery App with your friends!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Implement share functionality
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B35),
            ),
            child: const Text('Share'),
          ),
        ],
      ),
    );
  }

  void _checkForUpdates() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Check for Updates'),
        content: const Text('Your app is up to date!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _clearCache() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text('Are you sure you want to clear app cache?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cache cleared successfully!'),
                  backgroundColor: Color(0xFFFF6B35),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B35),
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}
