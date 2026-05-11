import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uber_app/screens/auth/login_screen.dart';
import 'package:uber_app/screens/auth/splash_screen.dart';
import 'package:uber_app/screens/home/faqs_screen.dart';
import 'package:uber_app/screens/home/navigation_screen.dart';
import 'package:uber_app/screens/home/settings_screen.dart';
import 'package:uber_app/screens/home/support_screen.dart';
import 'package:uber_app/screens/profile/user_profile_loader_screen.dart';
import 'package:uber_app/screens/user_module/driver_notification_firebase.dart';
import 'package:uber_app/screens/user_module/notification_detail_screen.dart';
import 'package:uber_app/screens/user_module/user_module.dart';
import 'package:uber_app/screens/user_module/user_module_firebase.dart';
import 'package:uber_app/services/preference_service.dart';

class AppDrawer extends StatelessWidget {
  final String userId;
  final FirebaseService _firebaseService = FirebaseService();

  AppDrawer({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final userId = _firebaseService.getCurrentUserId();


    Future<void> _handleLogout(BuildContext context) async {
      try {
     
        await FirebaseAuth.instance.signOut();

       
        await PreferenceService.clearPreferences();

        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => SplashScreen()),
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



    return Drawer(
      backgroundColor: Colors.white,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: const Text('Usman Khalid (User)'),
            accountEmail: const Text('usmankhalid@gmail.com'),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, color: Color(0xFF67B546), size: 40),
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF67B546).withOpacity(0.8),
            ),
          ),

          // Notifications with badge
          StreamBuilder<QuerySnapshot>(
            stream: _firebaseService.getUserNotifications(userId),
            builder: (context, snapshot) {
              final unreadCount =
                  snapshot.data?.docs
                      .where((doc) => doc['read'] != true)
                      .length ??
                  0;

              return _buildDrawerItemWithBadge(
                context,
                Icons.notifications,
                'Notifications',
                const NotificationsScreen(),
                unreadCount,
              );
            },
          ),

          // Other drawer items...
          _buildDrawerItem(
            context,
            Icons.history,
            'Request History',
            const RequestHistoryScreen(),
          ),
          // _buildDrawerItem(context, Icons.archive, 'Couriers', const CourierScreen()),
          _buildDrawerItem(
            context,
            Icons.swap_horiz,
            'City to City',
            const DeliveryRequestsList(),
          ),

          _buildDrawerItem(
            context,
            Icons.verified_user,
            'Safety',
            SafetyScreen(),
          ),
          _buildDrawerItem(
            context,
            Icons.settings,
            'Settings',
            SettingsScreen(),
          ),
          _buildDrawerItem(context, Icons.help, 'FAQs', FAQScreen()),
          _buildDrawerItem(context, Icons.support, 'Support', SupportScreen()),
          _buildDrawerItem(
            context,
            Icons.person,
            'Profile',
            UserProfileLoaderScreen(userId: userId),
          ),
          const SizedBox(height: 32),

          Container(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () async {
               await _handleLogout(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFCCFF00),
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Log Out',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItemWithBadge(
    BuildContext context,
    IconData icon,
    String title,
    Widget screen,
    int badgeCount,
  ) {
    return Stack(
      children: [
        _buildDrawerItem(context, icon, title, screen),
        if (badgeCount > 0)
          Positioned(
            right: 8,
            top: 12,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
              ),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text(
                badgeCount > 9 ? '9+' : badgeCount.toString(),
                style: const TextStyle(color: Colors.white, fontSize: 10),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDrawerItem(
    BuildContext context,
    IconData icon,
    String title,
    Widget screen,
  ) {
    return ListTile(
      leading: Icon(icon, color: Colors.black),
      title: Text(title),
      onTap: () {
        Navigator.of(context).pop();
        Navigator.of(context).push(MaterialPageRoute(builder: (ctx) => screen));
      },
    );
  }
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  void _loadNotifications() {
    final userId = _firebaseService.getCurrentUserId();

    _firebaseService.getUserNotifications(userId).listen((snapshot) {
      if (mounted) {
        setState(() {
          _notifications = snapshot.docs.map((doc) {
            return {'id': doc.id, ...doc.data()};
          }).toList();
          _isLoading = false;
        });
      }
    });
  }

  void _showNotificationDetails(Map<String, dynamic> notification) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => NotificationDetailsScreen(
        notification: notification,
        onAccept: () => _handleAcceptOffer(notification),
        onDecline: () => _handleDeclineOffer(notification),
      ),
    );
  }

  void _handleAcceptOffer(Map<String, dynamic> notification) async {
    try {
      final deliveryRequestId = notification['deliveryRequestId'];
      final offerId = notification['offerId'];

      await _firebaseService.acceptOffer(deliveryRequestId, offerId);

      // Mark notification as read
      _markAsRead(notification['id']);

      // Show ride accepted screen
      final offer = DriverOffer(
        offerId,
        notification['driverName'] ?? 'Driver',
        double.parse(notification['fare'] ?? '0'),
        double.parse(notification['distance'] ?? '0'),
        notification['truckType'] ?? 'Truck',
      );

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => RideAcceptedScreen(
          offer: offer,
          onCancel: () => Navigator.pop(context),
          onContactDriver: () {
            // Implement contact driver
            print('Contact driver: ${offer.driverName}');
          },
        ),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Offer accepted successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to accept offer: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _handleDeclineOffer(Map<String, dynamic> notification) async {
    try {
      final deliveryRequestId = notification['deliveryRequestId'];
      final offerId = notification['offerId'];

      await _firebaseService.declineOffer(deliveryRequestId, offerId);

      // Remove notification
      _deleteNotification(notification['id']);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Offer declined'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to decline offer: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _markAsRead(String notificationId) {
    final userId = _firebaseService.getCurrentUserId();
    _firebaseService.markNotificationAsRead(userId, notificationId);
  }

  void _deleteNotification(String notificationId) {
    final userId = _firebaseService.getCurrentUserId();
    _firebaseService.deleteNotification(userId, notificationId);
  }

  void _clearAllNotifications() {
    final userId = _firebaseService.getCurrentUserId();
    _firebaseService.clearAllNotifications(userId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF67B546),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_notifications.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded),
              onPressed: _clearAllNotifications,
              tooltip: 'Clear All',
            ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _notifications.isEmpty
          ? _buildEmptyState()
          : _buildNotificationsList(),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFF67B546).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF67B546),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Loading Notifications',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFF67B546).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_off_rounded,
              size: 60,
              color: const Color(0xFF67B546),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Notifications',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'You\'ll see notifications here when drivers send you delivery offers',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList() {
    return Column(
      children: [
        // Header Stats
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [const Color(0xFF67B546), const Color(0xFF4CAF50)],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                'Total',
                _notifications.length.toString(),
                Icons.notifications,
              ),
              _buildStatItem(
                'Unread',
                _notifications
                    .where((n) => n['read'] != true)
                    .length
                    .toString(),
                Icons.mark_email_unread_rounded,
              ),
              _buildStatItem(
                'Offers',
                _notifications
                    .where((n) => n['type'] == 'new_offer')
                    .length
                    .toString(),
                Icons.local_offer_rounded,
              ),
            ],
          ),
        ),

        // Notifications List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _notifications.length,
            itemBuilder: (context, index) {
              final notification = _notifications[index];
              return _buildNotificationCard(notification);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String title, String value, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          title,
          style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    final isRead = notification['read'] == true;
    final type = notification['type'];
    final title = notification['title'] ?? 'New Notification';
    final body = notification['body'] ?? '';
    final timestamp = notification['createdAt'] != null
        ? (notification['createdAt'] as Timestamp).toDate()
        : DateTime.now();

    Color? cardColor;
    IconData icon;

    switch (type) {
      case 'new_offer':
        cardColor = Colors.blue[50];
        icon = Icons.local_offer_rounded;
        break;
      default:
        cardColor = Colors.grey[50];
        icon = Icons.notifications_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _showNotificationDetails(notification),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isRead ? Colors.white : cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isRead
                    ? Colors.grey[200]!
                    : const Color(0xFF67B546).withOpacity(0.3),
                width: isRead ? 1 : 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isRead
                          ? [Colors.grey[300]!, Colors.grey[400]!]
                          : [const Color(0xFF67B546), const Color(0xFF4CAF50)],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 16),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: isRead
                                    ? FontWeight.w500
                                    : FontWeight.bold,
                                color: Colors.grey[800],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (!isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        body,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 14,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatTimestamp(timestamp),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                          const Spacer(),
                          if (type == 'new_offer' && !isRead)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF67B546).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'New Offer',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: const Color(0xFF67B546),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d, y').format(timestamp);
    }
  }
}

class RequestHistoryScreen extends StatelessWidget {
  const RequestHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firebaseService = FirebaseService();
    final userId = firebaseService.getCurrentUserId();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Request History',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF67B546),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: firebaseService.getUserDeliveryHistory(userId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];
          final requests = docs.map((doc) {
            return DeliveryRequest.fromMap(doc.id, doc.data());
          }).toList();

          final totalRides = requests.length;
          final completedRides = requests
              .where((r) => r.status == 'completed')
              .length;
          final cancelledRides = requests
              .where((r) => r.status == 'cancelled')
              .length;

          return Column(
            children: [
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF67B546), Color(0xFF4CAF50)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildSummaryItem(
                      'Total Rides',
                      totalRides.toString(),
                      Icons.directions_car,
                    ),
                    _buildSummaryItem(
                      'Completed',
                      completedRides.toString(),
                      Icons.check_circle,
                    ),
                    _buildSummaryItem(
                      'Cancelled',
                      cancelledRides.toString(),
                      Icons.cancel,
                    ),
                  ],
                ),
              ),

              // History List
              Expanded(
                child: requests.isEmpty
                    ? _buildEmptyHistory()
                    : ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: requests.map((request) {
                          return _buildHistoryCard(context, request);
                        }).toList(),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyHistory() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_rounded, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            'No delivery history',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Your delivery requests will appear here',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(BuildContext context, DeliveryRequest request) {
    final dateStr = DateFormat('dd MMM, hh:mm a').format(request.createdAt);
    final isCancelled = request.status == 'cancelled';
    final isCompleted = request.status == 'completed';

    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (request.status) {
      case 'completed':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = 'Completed';
        break;
      case 'cancelled':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        statusText = 'Cancelled';
        break;
      case 'accepted':
        statusColor = Colors.blue;
        statusIcon = Icons.local_shipping;
        statusText = 'In Progress';
        break;
      default:
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        statusText = 'Pending';
    }

    return GestureDetector(
      onTap: () => _showRequestDetails(context, request),
      child: Card(
        elevation: 3,
        color: Colors.white,
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.withOpacity(0.2)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Leading Icon
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Icon(statusIcon, color: statusColor, size: 24),
                ),
                const SizedBox(width: 12),

                // Main Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              dateStr,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                                fontSize: 14,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: statusColor.withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              statusText,
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Pickup Location
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              request.pickup.title,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Dropoff Location
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              request.destination.title,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),

                      if (isCancelled) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.info, color: Colors.red, size: 16),
                            const SizedBox(width: 8),
                            const Text(
                              'You cancelled this ride',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // Price Section
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Rs${request.fare.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: isCancelled
                            ? Colors.grey
                            : const Color(0xFF67B546),
                      ),
                    ),
                    if (isCompleted) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Paid',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showRequestDetails(BuildContext context, DeliveryRequest request) {
    final dateStr = DateFormat('MMMM d, y - hh:mm a').format(request.createdAt);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF67B546),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(25),
                  topRight: Radius.circular(25),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "Request Details",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Basic Info
                    _buildDetailItem(
                      'Request Date',
                      dateStr,
                      Icons.calendar_today,
                    ),
                    _buildDetailItem(
                      'Status',
                      _getStatusText(request.status),
                      Icons.info,
                    ),
                    _buildDetailItem(
                      'Truck Type',
                      request.truckType,
                      Icons.local_shipping,
                    ),
                    _buildDetailItem(
                      'Load Weight',
                      '${request.loadWeight} tons',
                      Icons.scale,
                    ),
                    _buildDetailItem(
                      'Fare',
                      'Rs${request.fare.toStringAsFixed(0)}',
                      Icons.attach_money,
                    ),

                    const SizedBox(height: 20),

                    // Locations
                    _buildLocationSection(
                      'Pickup Location',
                      request.pickup,
                      Colors.green,
                    ),
                    const SizedBox(height: 16),
                    _buildLocationSection(
                      'Destination',
                      request.destination,
                      Colors.red,
                    ),

                    if (request.deliveryNotes != null &&
                        request.deliveryNotes!.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      _buildNotesSection(request.deliveryNotes!),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String title, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF67B546), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSection(
    String title,
    LocationData location,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            location.title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          if (location.subtitle.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              location.subtitle,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNotesSection(String notes) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Delivery Notes',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.orange,
            ),
          ),
          const SizedBox(height: 8),
          Text(notes, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'accepted':
        return 'Accepted';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'Pending';
    }
  }

  Widget _buildSummaryItem(String title, String value, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          title,
          style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12),
        ),
      ],
    );
  }
}

class SafetyScreen extends StatelessWidget {
  const SafetyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Safety')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Emergency Call Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Call Emergency',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.phone, color: Colors.white),
                    label: const Text(
                      '15',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'How you\'re protected',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            // Safety Features Grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.5,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              children: [
                _buildSafetyCard('Proactive safety support', Icons.security),
                _buildSafetyCard('Driver Verification', Icons.verified_user),
                _buildSafetyCard('Protecting your privacy', Icons.lock),
                _buildSafetyCard(
                  'Staying safe on every delivery',
                  Icons.local_shipping,
                ),
                _buildSafetyCard(
                  'Accidents: Steps to take',
                  Icons.warning_amber,
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Support and Contacts
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildContactButton(
                  'Support',
                  Icons.headset_mic,
                  Colors.blueGrey,
                ),
                _buildContactButton(
                  'Emergency Contacts',
                  Icons.people,
                  Colors.red,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSafetyCard(String title, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: const Color(0xFF67B546), size: 30),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildContactButton(String title, IconData icon, Color color) {
    return TextButton.icon(
      onPressed: () {},
      icon: Icon(icon, color: color),
      label: Text(title, style: TextStyle(color: color)),
    );
  }
}

class CityToCityScreen extends StatelessWidget {
  const CityToCityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('City to City Delivery')),
      body: Center(
        child: Text(
          'City to City long-haul delivery module.',
          style: TextStyle(color: Colors.grey[600]),
        ),
      ),
    );
  }
}
