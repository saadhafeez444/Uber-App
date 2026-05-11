import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:uber_app/screens/driver/driver_module.dart';
import 'dart:async';

class ActiveShipment {
  final String id;
  final String clientName;
  final String pickupLocation;
  final String deliveryLocation;
  final double progressPercent;
  final DateTime scheduledDelivery;
  final double currentEarnings;

  ActiveShipment({
    required this.id,
    required this.clientName,
    required this.pickupLocation,
    required this.deliveryLocation,
    required this.progressPercent,
    required this.scheduledDelivery,
    required this.currentEarnings,
  });

  static ActiveShipment mock = ActiveShipment(
    id: "SHIP00123",
    clientName: "Global Logistics Inc.",
    pickupLocation: "123 Market St, SFO",
    deliveryLocation: "456 Commerce Ave, OAK",
    progressPercent: 0.65,
    scheduledDelivery: DateTime.now().add(
      const Duration(hours: 3, minutes: 30),
    ),
    currentEarnings: 85.50,
  );
}

class EarningsSummary {
  final double todayEarnings;
  final int activeShipmentsCount;

  EarningsSummary({
    required this.todayEarnings,
    required this.activeShipmentsCount,
  });

  static EarningsSummary mock = EarningsSummary(
    todayEarnings: 155.00,
    activeShipmentsCount: 2,
  );
}

// --- 2. COLOR & STYLE CONSTANTS ---

const Color kPrimaryBlue = Color(0xFF2563EB); // Tailwind blue-600
const Color kSecondaryGreen = Color(0xFF10B981); // Tailwind emerald-500
const Color kBackgroundColor = Color(0xFFF8F9FA);

// Firebase service is now integrated directly or via standard Firebase calls.

// --- 4. SHIMMER LOADING WIDGET ---

class ShimmerLoading extends StatelessWidget {
  final double width;
  final double height;
  final double radius;

  const ShimmerLoading({
    super.key,
    required this.width,
    required this.height,
    this.radius = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}

class DriverDashboardScreen extends StatefulWidget {
  final String driverId;
  final DriverProfile driverProfile;
  final List<ActiveShipment> activeShipments;
  final EarningsSummary earnings;

  const DriverDashboardScreen({
    super.key,
    required this.driverId,
    required this.driverProfile,
    required this.activeShipments,
    required this.earnings,
  });

  @override
  State<DriverDashboardScreen> createState() => _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends State<DriverDashboardScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<DocumentSnapshot>? _profileStream;
  Stream<QuerySnapshot>? _shipmentsStream;

  GoogleMapController? _mapController;
  final TextEditingController _searchController = TextEditingController();
  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      _profileStream = _firestore.collection('profiles').doc(uid).snapshots();
      // Fetch shipments where this driver is assigned (assuming 'driverId' field exists in delivery_requests)
      _shipmentsStream = _firestore
          .collection('delivery_requests')
          .where('driverId', isEqualTo: uid)
          .where('status', isEqualTo: 'accepted')
          .snapshots();
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: _profileStream,
      builder: (context, profileSnapshot) {
        final profileData =
            profileSnapshot.data?.data() as Map<String, dynamic>?;
        final driverName = profileData?['fullName'] ?? 'Driver';
        final avatarUrl = profileData?['profileImage'] ?? '';
        final driverRating = (profileData?['driverInfo']?['rating'] ?? 0.0)
            .toDouble();

        return Scaffold(
          backgroundColor: kBackgroundColor,
          appBar: _buildCustomAppBar(driverName, avatarUrl),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const SizedBox(height: 8),
                // Statistics Cards
                _buildStatsRow(driverRating),
                const SizedBox(height: 32),
                // Quick Actions
                _buildSectionHeader("Quick Actions", Icons.flash_on),
                const SizedBox(height: 12),
                _buildQuickActions(),
                const SizedBox(height: 32),
                // Live Active Shipment
                _buildSectionHeader(
                  "Live Active Shipment",
                  Icons.local_shipping,
                ),
                const SizedBox(height: 12),
                _buildMapActiveShipmentCard(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildCustomAppBar(String name, String avatarUrl) {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: Colors.white,
      elevation: 0,
      title: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: kPrimaryBlue.withOpacity(0.1),
            backgroundImage: avatarUrl.isNotEmpty
                ? NetworkImage(avatarUrl)
                : null,
            child: avatarUrl.isEmpty
                ? const Icon(Icons.person, color: kPrimaryBlue)
                : null,
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome back,',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                name.split(' ').first,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_none, color: Colors.black87),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: kPrimaryBlue, size: 24),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow(double rating) {
    return StreamBuilder<QuerySnapshot>(
      stream: _shipmentsStream,
      builder: (context, shipmentSnapshot) {
        final activeCount = shipmentSnapshot.data?.docs.length ?? 0;

        // Mocking earnings for now as it usually requires a separate calculation or field
        final todayEarnings = 155.00;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildStatCard(
                label: "Today's Earnings",
                value: "\$${todayEarnings.toStringAsFixed(2)}",
                icon: Icons.paid,
                color: kPrimaryBlue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                label: "Active Shipments",
                value: "$activeCount",
                icon: Icons.inventory_2,
                color: kSecondaryGreen,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                label: "Driver Rating",
                value: "${rating.toStringAsFixed(1)} \u2605", // Star emoji
                icon: Icons.star_rate_rounded,
                color: const Color(0xFFFFC107), // Amber for rating
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCardShimmer() {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerLoading(width: 28, height: 28, radius: 14),
          const SizedBox(height: 8),
          ShimmerLoading(width: 60, height: 20),
          const SizedBox(height: 4),
          ShimmerLoading(width: 80, height: 12),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      {
        'label': 'View Nearby Requests',
        'icon': Icons.my_location,
        'color': kPrimaryBlue,
      },
      {
        'label': 'Active Shipments',
        'icon': Icons.list_alt,
        'color': kSecondaryGreen,
      },
      {
        'label': 'Earnings History',
        'icon': Icons.history,
        'color': const Color(0xFFF97316),
      }, // Orange
      {
        'label': 'Profile',
        'icon': Icons.person,
        'color': const Color(0xFF6366F1),
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.5,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final action = actions[index];
        return InkWell(
          onTap: () {
            // Placeholder action
            print('${action['label']} tapped');
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.05),
                  spreadRadius: 1,
                  blurRadius: 3,
                ),
              ],
            ),
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: (action['color'] as Color).withOpacity(0.1),
                  child: Icon(
                    action['icon'] as IconData,
                    color: action['color'] as Color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    action['label'] as String,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMapActiveShipmentCard() {
    return StreamBuilder<QuerySnapshot>(
      stream: _shipmentsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildShipmentCardShimmer();
        }

        final docs = snapshot.data?.docs ?? [];

        // Update markers based on active shipments
        _markers.clear();
        for (var doc in docs) {
          final data = doc.data() as Map<String, dynamic>;
          final pickup = data['pickup'];
          if (pickup != null) {
            _markers.add(
              Marker(
                markerId: MarkerId(doc.id),
                position: LatLng(pickup['latitude'], pickup['longitude']),
                infoWindow: InfoWindow(
                  title: 'Shipment: ${doc.id}',
                  snippet: pickup['title'],
                ),
              ),
            );
          }
        }

        return Container(
          height: 350,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 2,
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                GoogleMap(
                  onMapCreated: _onMapCreated,
                  initialCameraPosition: const CameraPosition(
                    target: LatLng(
                      31.5204,
                      74.3587,
                    ), // Default to Lahore or current location
                    zoom: 12,
                  ),
                  markers: _markers,
                  myLocationEnabled: true,
                  zoomControlsEnabled: false,
                ),
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: "Search shipments...",
                        prefixIcon: const Icon(
                          Icons.search,
                          color: kPrimaryBlue,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 15,
                        ),
                      ),
                      onSubmitted: (value) {
                        // Search logic here
                      },
                    ),
                  ),
                ),
                // if (docs.isEmpty)
                //   Container(
                //     color: Colors.black.withOpacity(0.05),
                //     child: Center(
                //       child: Column(
                //         mainAxisAlignment: MainAxisAlignment.center,
                //         children: [
                //           Icon(
                //             Icons.map_outlined,
                //             size: 50,
                //             color: Colors.grey.shade400,
                //           ),
                //           const SizedBox(height: 12),
                //           Text(
                //             "No active shipments to display.",
                //             style: TextStyle(
                //               color: Colors.grey.shade600,
                //               fontWeight: FontWeight.w500,
                //             ),
                //           ),
                //         ],
                //       ),
                //     ),
                //   ),
            
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildShipmentCardShimmer() {
    return Container(
      height: 350,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerLoading(width: 150, height: 16),
          const SizedBox(height: 20),
          ShimmerLoading(width: double.infinity, height: 200),
          const SizedBox(height: 20),
          ShimmerLoading(width: 100, height: 16),
          const SizedBox(height: 10),
          ShimmerLoading(width: double.infinity, height: 12),
        ],
      ),
    );
  }

  Widget _buildLocationRow(
    IconData icon,
    String title,
    String location,
    Color color,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              location,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      selectedItemColor: kPrimaryBlue,
      unselectedItemColor: Colors.grey.shade600,
      showUnselectedLabels: true,
      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Requests'),
        BottomNavigationBarItem(
          icon: Icon(Icons.account_balance_wallet),
          label: 'Earnings',
        ),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ],
      onTap: (index) {
        print('Bottom nav tapped: $index');
      },
    );
  }
}
