import 'package:flutter/material.dart';
import 'package:uber_app/screens/driver/dashboard_screen_driver.dart';
import 'package:uber_app/screens/driver/driver_delivery_requests.dart';
import 'package:uber_app/screens/driver/driver_module.dart'
    hide kBackgroundColor, kPrimaryBlue, kSecondaryGreen;
import 'package:uber_app/screens/driver/send_offer_screen.dart'
    hide kBackgroundColor, kPrimaryBlue, kSecondaryGreen, FilterOptions;
import 'package:uber_app/screens/profile/user_profile_loader_screen.dart';
import 'package:uber_app/screens/user_module/driver_notification_firebase.dart';

class NavigationScreen extends StatefulWidget {
  final int initialCardIndex;
  final String userId;

  const NavigationScreen({
    Key? key,
    this.initialCardIndex = 0,
    required this.userId,
  }) : super(key: key);

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  int selectedIndex = 0;
  late MockOfferService offerService;
   

  
  
  @override
  void initState() {
    super.initState();
    selectedIndex = widget.initialCardIndex;
    

    final mockProfile = DriverProfile.mock;
    offerService = MockOfferService(driverId: mockProfile.id);
  }

  Widget _getCurrentScreen() {
    final mockProfile = DriverProfile.mock;
    final mockEarnings = EarningsSummary.mock;
    final mockShipments = [ActiveShipment.mock];
    final mockService = MockShipmentService();
    final mockRequests = mockService.mockRequestsData;

    final mockLocation = Location(
      latitude: 37.7749,
      longitude: -122.4194,
      address: "101 Market Street, San Francisco",
    );

    switch (selectedIndex) {
      case 0:
        return DriverDashboardScreen(
          driverId: "D-12345",
          driverProfile: mockProfile,
          activeShipments: mockShipments,
          earnings: mockEarnings,
        );

      case 1:
        
        return const DriverDeliveryRequestsList();

      case 2:
        return const EarningsScreen();

      // case 3:
      //   return OfferStatusScreen(
      //     driverId: mockProfile.id,
      //     offerService: offerService,
      //   );

      case 3:
        return UserProfileLoaderScreen(userId: widget.userId);

      default:
        return DriverDashboardScreen(
          driverId: "D-12345",
          driverProfile: mockProfile,
          activeShipments: mockShipments,
          earnings: mockEarnings,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: _getCurrentScreen(),

      bottomNavigationBar: BottomNavigationBar(
        elevation: 0,
        backgroundColor: Colors.white,
        currentIndex: selectedIndex,

        onTap: (val) {
          setState(() {
            selectedIndex = val;
          });
        },

        items: [
          BottomNavigationBarItem(
            icon: Icon(
              Icons.home,
              size: 25,
              color: selectedIndex == 0 ? Colors.red : Colors.black,
            ),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.dashboard,
              size: 25,
              color: selectedIndex == 1 ? Colors.red : Colors.black,
            ),
            label: 'Requests',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.plus_one,
              size: 25,
              color: selectedIndex == 2 ? Colors.red : Colors.black,
            ),
            label: 'Earnings',
          ),
          // BottomNavigationBarItem(
          //   icon: Icon(
          //     Icons.grid_view_rounded,
          //     size: 25,
          //     color: selectedIndex == 3 ? Colors.red : Colors.black,
          //   ),
          //   label: 'More',
          // ),
        
        
          BottomNavigationBarItem(
            icon: Icon(
              Icons.account_circle,
              size: 25,
              color: selectedIndex == 3 ? Colors.red : Colors.black,
            ),
            label: 'Profile',
          ),
        ],

        selectedItemColor: Colors.red,
        unselectedItemColor: Colors.black,
        selectedLabelStyle: const TextStyle(fontSize: 10, color: Colors.red),
        unselectedLabelStyle: const TextStyle(
          fontSize: 10,
          color: Colors.black,
        ),
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}


