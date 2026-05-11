import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uber_app/screens/home/navigation_screen.dart';
import 'package:uber_app/screens/user_module/drawer.dart';
import 'package:uber_app/screens/user_module/driver_notification.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uber_app/firebase_options.dart';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uber_app/screens/user_module/user_module.dart';

bool _isNavigating = false;

enum ImageSourceType { camera, gallery }

class TruckType {
  final String id;
  final String name;
  final IconData icon;

  TruckType(this.id, this.name, this.icon);
}

class TripOption {
  final String title;
  final String subtitle;
  final String priceEstimate;
  final IconData icon;

  TripOption(this.title, this.subtitle, this.priceEstimate, this.icon);
}



// class DriverOffer {
//   final String id;
//   final String driverName;
//   final double fare;
//   final double distance;
//   final String truckType;
//   final String? driverId;
//   final String? vehicleNumber;
//   final double? rating;

//   DriverOffer(
//     this.id,
//     this.driverName,
//     this.fare,
//     this.distance,
//     this.truckType, {
//     this.driverId,
//     this.vehicleNumber,
//     this.rating,
//   });

//   Map<String, dynamic> toMap() {
//     return {
//       'id': id,
//       'driverName': driverName,
//       'fare': fare,
//       'distance': distance,
//       'truckType': truckType,
//       'driverId': driverId,
//       'vehicleNumber': vehicleNumber,
//       'rating': rating,
//       'createdAt': FieldValue.serverTimestamp(),
//     };
//   }

//   static DriverOffer fromMap(String id, Map<String, dynamic> data) {
//     return DriverOffer(
//       id,
//       data['driverName'] ?? 'Unknown Driver',
//       (data['fare'] ?? 0.0).toDouble(),
//       (data['distance'] ?? 0.0).toDouble(),
//       data['truckType'] ?? 'Small Truck',
//       driverId: data['driverId'],
//       vehicleNumber: data['vehicleNumber'],
//       rating: (data['rating'] ?? 4.5).toDouble(),
//     );
//   }
// }

class DriverOffer {
  final String id;
  final String driverName;
  final double fare;
  final double distance;
  final String truckType;
  final String? driverId;
  final String? vehicleNumber;
  final double? rating;
  final String status; // 'pending', 'accepted', 'declined', 'cancelled'
  final DateTime? createdAt;

  DriverOffer(
    this.id,
    this.driverName,
    this.fare,
    this.distance,
    this.truckType, {
    this.driverId,
    this.vehicleNumber,
    this.rating,
    this.status = 'pending',
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'driverName': driverName,
      'fare': fare,
      'distance': distance,
      'truckType': truckType,
      'driverId': driverId,
      'vehicleNumber': vehicleNumber,
      'rating': rating,
      'status': status,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  static DriverOffer fromMap(String id, Map<String, dynamic> data) {
    return DriverOffer(
      id,
      data['driverName'] ?? 'Unknown Driver',
      (data['fare'] ?? 0.0).toDouble(),
      (data['distance'] ?? 0.0).toDouble(),
      data['truckType'] ?? 'Small Truck',
      driverId: data['driverId'],
      vehicleNumber: data['vehicleNumber'],
      rating: (data['rating'] ?? 4.5).toDouble(),
      status: data['status'] ?? 'pending',
      createdAt: data['createdAt'] != null 
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
    );
  }
}




class LocationData {
  final String title;
  final String subtitle;
  final LatLng coordinates;

  LocationData(this.title, this.subtitle, {required this.coordinates});
}
class DeliveryRequest {
  final String? id;
  final String userId;
  final LocationData pickup;
  final LocationData destination;
  final String truckType;
  final double loadWeight;
  final double fare;
  final DateTime deliveryDate;
  final TimeOfDay deliveryTime;
  final String? deliveryNotes;
  final List<String> imageUrls;
  final String status;
  final DateTime createdAt;

  DeliveryRequest({
    this.id,
    required this.userId,
    required this.pickup,
    required this.destination,
    required this.truckType,
    required this.loadWeight,
    required this.fare,
    required this.deliveryDate,
    required this.deliveryTime,
    this.deliveryNotes,
    this.imageUrls = const [],
    this.status = 'pending',
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'pickup': {
        'title': pickup.title,
        'subtitle': pickup.subtitle,
        'latitude': pickup.coordinates.latitude,
        'longitude': pickup.coordinates.longitude,
      },
      'destination': {
        'title': destination.title,
        'subtitle': destination.subtitle,
        'latitude': destination.coordinates.latitude,
        'longitude': destination.coordinates.longitude,
      },
      'truckType': truckType,
      'loadWeight': loadWeight,
      'fare': fare,
      'deliveryDate': Timestamp.fromDate(deliveryDate),
      'deliveryTime': '${deliveryTime.hour}:${deliveryTime.minute}',
      'deliveryNotes': deliveryNotes,
      'imageUrls': imageUrls,
      'status': status,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  static DeliveryRequest fromMap(String id, Map<String, dynamic> data) {
    final pickupData = data['pickup'] ?? {};
    final destinationData = data['destination'] ?? {};

    return DeliveryRequest(
      id: id,
      userId: data['userId'] ?? '',
      pickup: LocationData(
        pickupData['title'] ?? '',
        pickupData['subtitle'] ?? '',
        coordinates: LatLng(
          (pickupData['latitude'] ?? 0.0).toDouble(),
          (pickupData['longitude'] ?? 0.0).toDouble(),
        ),
      ),
      destination: LocationData(
        destinationData['title'] ?? '',
        destinationData['subtitle'] ?? '',
        coordinates: LatLng(
          (destinationData['latitude'] ?? 0.0).toDouble(),
          (destinationData['longitude'] ?? 0.0).toDouble(),
        ),
      ),
      truckType: data['truckType'] ?? '',
      loadWeight: (data['loadWeight'] ?? 0.0).toDouble(),
      fare: (data['fare'] ?? 0.0).toDouble(),
      deliveryDate: (data['deliveryDate'] as Timestamp).toDate(),
      deliveryTime: _parseTime(data['deliveryTime'] ?? '12:00'),
      deliveryNotes: data['deliveryNotes'],
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      status: data['status'] ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  static TimeOfDay _parseTime(String timeString) {
    final parts = timeString.split(':');
    if (parts.length == 2) {
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    }
    return TimeOfDay.now();
  }
}

class FirebaseService {
  
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  // Add this getter for easy access to firestore
  FirebaseFirestore get firestore => _firestore;

// Add this method to FirebaseService class
Stream<QuerySnapshot<Map<String, dynamic>>> getAllDeliveryRequests() {
  return _firestore
      .collection('delivery_requests')
      .where('status', isEqualTo: 'pending') // Only show pending requests
      .orderBy('createdAt', descending: true)
      .snapshots();
}
  Future<void> initializeNotifications() async {
    // Request permission
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
      
      // Get FCM token
      String? token = await _messaging.getToken();
      print('FCM Token: $token');
      
      // Save token to user document in Firestore
      await _saveFCMToken(token);
      
      // Listen for foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      
      // Handle background messages
      FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);
    }
  }

  Future<void> _saveFCMToken(String? token) async {
    if (token == null) return;
    
    final userId = getCurrentUserId();
    await _firestore.collection('users').doc(userId).set({
      'fcmToken': token,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  void _handleForegroundMessage(RemoteMessage message) {
    print('Foreground message: ${message.notification?.title}');
    // You can show a local notification or update UI
  }

  void _handleBackgroundMessage(RemoteMessage message) {
    print('Background message: ${message.notification?.title}');
    // Navigate to specific screen when user taps notification
  }

  // CORRECTED: Store notifications in user-specific collection
  Future<void> sendNewOfferNotification({
    required String deliveryRequestId,
    required DriverOffer offer,
    required String userId,
  }) async {
    try {
      // Store notification in user's notification subcollection
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .add({
        'title': 'New Delivery Offer!',
        'body': '${offer.driverName} sent you an offer for Rs${offer.fare.toStringAsFixed(0)}',
        'type': 'new_offer',
        'deliveryRequestId': deliveryRequestId,
        'offerId': offer.id,
        'driverName': offer.driverName,
        'fare': offer.fare.toString(),
        'truckType': offer.truckType,
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      print('Notification stored for user: $userId');
      
      // Also send push notification
      await _sendPushNotification(userId, offer, deliveryRequestId);
      
    } catch (e) {
      print('Error sending notification: $e');
    }
  }

  Future<void> _sendPushNotification(String userId, DriverOffer offer, String deliveryRequestId) async {
    try {
      // Get user's FCM token
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final String? userFCMToken = userDoc.data()?['fcmToken'];
      
      if (userFCMToken == null) {
        print('User FCM token not found');
        return;
      }

      // This would typically be done via Cloud Functions
      // For now, we'll just store the notification locally
      print('Would send push notification to: $userFCMToken');
      
    } catch (e) {
      print('Error sending push notification: $e');
    }
  }

  // Add this method to get user notifications
  Stream<QuerySnapshot<Map<String, dynamic>>> getUserNotifications(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Add this method to mark notification as read
  Future<void> markNotificationAsRead(String userId, String notificationId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .doc(notificationId)
        .update({'read': true});
  }

  // Add this method to delete notification
  Future<void> deleteNotification(String userId, String notificationId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .doc(notificationId)
        .delete();
  }

  // Add this method to clear all notifications
  Future<void> clearAllNotifications(String userId) async {
    final notifications = await _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .get();
    
    final batch = _firestore.batch();
    for (final doc in notifications.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  // Your existing methods remain the same...
  Future<String> saveDeliveryRequest(DeliveryRequest request) async {
    try {
      final docRef = await _firestore
          .collection('delivery_requests')
          .add(request.toMap());
      return docRef.id;
    } catch (e) {
      print('Error saving delivery request: $e');
      throw e;
    }
  }

  Future<List<String>> uploadImages(
    List<XFile> images,
    String requestId,
  ) async {
    final List<String> downloadUrls = [];

    for (int i = 0; i < images.length; i++) {
      try {
        final file = File(images[i].path);
        final fileName =
            '${requestId}_${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
        final ref = _storage.ref().child('delivery_images/$fileName');

        await ref.putFile(file);
        final downloadUrl = await ref.getDownloadURL();
        downloadUrls.add(downloadUrl);
      } catch (e) {
        print('Error uploading image $i: $e');
      }
    }

    return downloadUrls;
  }

  String getCurrentUserId() {
    return _auth.currentUser?.uid ?? 'anonymous';
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> listenForOffers(
    String requestId,
  ) {
    return _firestore
        .collection('delivery_requests')
        .doc(requestId)
        .collection('offers')
        .snapshots();
  }

  Future<void> acceptOffer(String requestId, String offerId) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final offerRef = _firestore
            .collection('delivery_requests')
            .doc(requestId)
            .collection('offers')
            .doc(offerId);
        transaction.update(offerRef, {'status': 'accepted'});

        final requestRef = _firestore
            .collection('delivery_requests')
            .doc(requestId);
        transaction.update(requestRef, {
          'status': 'accepted',
          'acceptedOfferId': offerId,
          'acceptedAt': FieldValue.serverTimestamp(),
        });
      });
    } catch (e) {
      print('Error accepting offer: $e');
      throw e;
    }
  }

  Future<void> declineOffer(String requestId, String offerId) async {
    try {
      await _firestore
          .collection('delivery_requests')
          .doc(requestId)
          .collection('offers')
          .doc(offerId)
          .update({'status': 'declined'});
    } catch (e) {
      print('Error declining offer: $e');
      throw e;
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getUserDeliveryHistory(
    String userId,
  ) {
    return _firestore
        .collection('delivery_requests')  
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
}




class TruckDeliveryApp extends StatelessWidget {
   final String userId;
  const TruckDeliveryApp({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Truck Delivery App',
      theme: ThemeData(
        primarySwatch: Colors.green,
        primaryColor: const Color(0xFF67B546),
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          color: Colors.white,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.black),
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: const Color(0xFF67B546),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
        ),
        useMaterial3: true,
      ),
      home:  HomePage(userId: userId,),
    );
  }
}

class HomePage extends StatefulWidget {
   final String userId;
  const HomePage({super.key, required this.userId});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  GoogleMapController? _mapController;
  Position? _currentPosition;
  LocationData? _pickupLocation;
  LocationData? _destinationLocation;
  DriverOffer? _activeOffer;
  Timer? _offerTimer;
  String? _rideRequestId;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _offersSubscription;
  late FirebaseAuth _auth;
  final FirebaseService _firebaseService = FirebaseService();

  final List<DriverOffer> _activeOffers = [];
  late DriverOfferManager _offerManager;
  final List<TruckType> _truckTypes = [
    TruckType('small', 'Small Truck', Icons.local_shipping),
    TruckType('medium', 'Medium Truck', Icons.airport_shuttle),
    TruckType('large', 'Heavy Truck', Icons.fire_truck),
    TruckType('courier', 'Courier', Icons.archive),
    TruckType('city', 'City to City', Icons.swap_horiz),
  ];

  TruckType _selectedTruckType = TruckType(
    'small',
    'Small Truck',
    Icons.local_shipping,
  );

  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};

  @override
  void initState() {
    super.initState();

    _offerManager = DriverOfferManager(
      onNewOffer: (offer) {
        if (mounted) {
          setState(() {
            _activeOffers.add(offer);
          });
        }
      },
      onOfferExpired: (offer) {
        if (mounted) {
          setState(() {
            _activeOffers.removeWhere((o) => o.id == offer.id);
          });
        }
      },
    );

    _getCurrentLocation();
    _initFirebase();
  }

  Future<void> _initFirebase() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (e) {
      print('Firebase already initialized: $e');
    }

    _auth = FirebaseAuth.instance;
    if (_auth.currentUser == null) {
      try {
        await _auth.signInAnonymously();
        print('Anonymous user signed in: ${_auth.currentUser?.uid}');
      } catch (e) {
        print('Auth error: $e');

      }
    }
  }

  // UPDATED: Enhanced location selection with Firebase storage
  void _navigateToLocationSearch() async {
    print("🔍 Opening location search");

    try {
      final result = await Navigator.of(context).push<Map<String, dynamic>>(
        MaterialPageRoute(
          builder: (context) => LocationSearchScreen(
            initialPickup:
                _pickupLocation ??
                LocationData(
                  'Current Location',
                  'Your current location',
                  coordinates: LatLng(
                    _currentPosition?.latitude ?? 31.4504,
                    _currentPosition?.longitude ?? 74.0503,
                  ),
                ),
          ),
        ),
      );

      print("🔍 Location search result: $result");

      if (result != null && result['destination'] != null && mounted) {
        print("✅ Location search completed successfully");
        _handleLocationSelect(
          result['pickup'] ?? _pickupLocation!,
          result['destination']!,
        );
      }
    } catch (e) {
      print("❌ Error in location search: $e");
    }
  }

  void _onCurrentLocationTap() {
    print("📍 Current location tapped");

    if (_currentPosition != null) {
      setState(() {
        _pickupLocation = LocationData(
          'Current Location',
          'Your current location',
          coordinates: LatLng(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
            
          ),
        );
      });
    }

    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.9,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
          ),
          child: LocationSearchScreen(
            initialPickup: _pickupLocation!,
            isModal: true,
            onLocationSelect: (pickup, destination) {
              Navigator.of(ctx).pop();
              if (destination != null && mounted) {
                _handleLocationSelect(pickup, destination);
              }
            },
          ),
        );
      },
    );
  }

  void _handleLocationSelect(LocationData pickup, LocationData destination) {
    print("📍 Location selected: ${pickup.title} → ${destination.title}");

    if (!mounted) return;

    setState(() {
      _pickupLocation = pickup;
      _destinationLocation = destination;
    });

    _addDestinationMarker(destination);
    _startTripFlow();
  }

  void _startTripFlow() {
    print("🚀 Starting trip flow");

    if (_pickupLocation == null || _destinationLocation == null) {
      print("❌ Missing pickup or destination");
      return;
    }

    _showTripSelectionSheet();
  }

  // UPDATED: Enhanced trip flow with Firebase
  Future<void> _showTripSelectionSheet() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TripTypeSelectionScreen(
        pickup: _pickupLocation!,
        destination: _destinationLocation!,
        onTripSelected: (option) async {
          Navigator.of(context).pop();
          await Future.delayed(Duration(milliseconds: 200));
          await _showFareNegotiationScreen(option);
        },
      ),
    );
  }


  // UPDATED: Enhanced fare negotiation with Firebase
  Future<void> _showFareNegotiationScreen(TripOption option) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => FareNegotiationScreen(
          tripOption: option,
          pickupLocation: _pickupLocation!,
          destinationLocation: _destinationLocation!,
          onFindDriver: () async {
            Navigator.of(ctx).pop();
            await Future.delayed(Duration(milliseconds: 300));
            _startDriverOffersFlow();
          },
        ),
        fullscreenDialog: true,
      ),
    );
  }

  // UPDATED: Complete Firebase integration for driver offers
  void _startDriverOffersFlow() {
    print("🚀 Starting driver offers flow");

    final tripOption = TripOption(
      'Small Truck Delivery',
      'Delivery only',
      '≈Rs7,550',
      Icons.local_shipping,
    );

    _createRideRequestAndListen(tripOption);
    _showFindingOffersScreen(tripOption);
  }


  Future<void> _createRideRequestAndListen(TripOption option) async {
    try {
      final userId = _firebaseService.getCurrentUserId();
      final rideRef = FirebaseFirestore.instance
          .collection('ride_requests')
          .doc();

      final pickupMap = _pickupLocation != null
          ? {
              'title': _pickupLocation!.title,
              'subtitle': _pickupLocation!.subtitle,
              'lat': _pickupLocation!.coordinates.latitude,
              'lng': _pickupLocation!.coordinates.longitude,
            }
          : null;

      final destMap = _destinationLocation != null
          ? {
              'title': _destinationLocation!.title,
              'subtitle': _destinationLocation!.subtitle,
              'lat': _destinationLocation!.coordinates.latitude,
              'lng': _destinationLocation!.coordinates.longitude,
            }
          : null;

      await rideRef.set({
        'userId': userId,
        'status': 'searching',
        'tripOption': option.title,
        'createdAt': FieldValue.serverTimestamp(),
        'pickup': pickupMap,
        'destination': destMap,
      });

      _rideRequestId = rideRef.id;

      // Listen for real-time offers
      _offersSubscription = rideRef.collection('offers').snapshots().listen((
        snap,
      ) {
        for (final change in snap.docChanges) {
          if (change.type == DocumentChangeType.added) {
            final doc = change.doc;
            final data = doc.data();
            if (data == null) continue;

            final offer = DriverOffer.fromMap(doc.id, data);
            _offerManager.addOffer(offer, const Duration(seconds: 15));

            setState(() {
              _activeOffers.add(offer);
            });
          }
        }
      });

      // Simulate driver offers (remove in production)
      _simulateDriverOffers(rideRef);
    } catch (e) {
      print('Error creating ride request: $e');
      _showSnackbar(context, 'Failed to start ride search');
    }
  }

  void _simulateDriverOffers(DocumentReference rideRef) async {
    try {
      final offersCol = rideRef.collection('offers');

      // Simulate multiple driver offers
      final simulatedOffers = [
        {
          'driverName': 'Muhammad Ali',
          'fare': 7850.0,
          'distance': 3.5,
          'truckType': 'Small Truck Delivery',
          'status': 'pending',
          'driverId': 'driver_001',
          'vehicleNumber': 'LHR-1234',
          'rating': 4.8,
          'createdAt': FieldValue.serverTimestamp(),
        },
        {
          'driverName': 'Ahmed Khan',
          'fare': 8200.0,
          'distance': 2.8,
          'truckType': 'Medium Truck Delivery',
          'status': 'pending',
          'driverId': 'driver_002',
          'vehicleNumber': 'LHR-5678',
          'rating': 4.6,
          'createdAt': FieldValue.serverTimestamp(),
        },
        {
          'driverName': 'Usman Butt',
          'fare': 7500.0,
          'distance': 4.2,
          'truckType': 'Small Truck Delivery',
          'status': 'pending',
          'driverId': 'driver_003',
          'vehicleNumber': 'LHR-9012',
          'rating': 4.9,
          'createdAt': FieldValue.serverTimestamp(),
        },
      ];

      for (int i = 0; i < simulatedOffers.length; i++) {
        await Future.delayed(Duration(seconds: (i + 1) * 3));
        await offersCol.doc('sim-${i + 1}').set(simulatedOffers[i]);
      }
    } catch (e) {
      print('Error creating simulated offers: $e');
    }
  }

  void _showFindingOffersScreen(TripOption option) async {
    print("🔍 Showing finding offers screen");

    try {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (ctx) => FindingOfferScreen(tripOption: option),
          fullscreenDialog: true,
        ),
      );

      if (mounted) {
        print("🎯 Showing driver offers on main screen");
      }
    } catch (e) {
      print("❌ Error in finding offers screen: $e");
    }
  }

  // UPDATED: Enhanced offer handling with Firebase
  void _handleOfferAccept(DriverOffer offer) async {
    try {
      if (_rideRequestId != null) {
        await _firebaseService.acceptOffer(_rideRequestId!, offer.id);
      }

      _offerManager.removeOffer(offer);
      _showRideAcceptedScreen(offer);
    } catch (e) {
      print('Error accepting offer: $e');
      _showSnackbar(context, 'Failed to accept offer');
    }
  }

  void _handleOfferDecline(DriverOffer offer) async {
    try {
      if (_rideRequestId != null) {
        await _firebaseService.declineOffer(_rideRequestId!, offer.id);
      }

      _offerManager.removeOffer(offer);
      _showSnackbar(context, 'Offer from ${offer.driverName} declined');
    } catch (e) {
      print('Error declining offer: $e');
      _showSnackbar(context, 'Failed to decline offer');
    }
  }

  void _showRideAcceptedScreen(DriverOffer offer) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RideAcceptedScreen(
        offer: offer,
        onCancel: () {
          Navigator.of(context).pop();
          _showSnackbar(context, 'Ride cancelled');
        },
        onContactDriver: () {
          _showSnackbar(context, 'Contacting ${offer.driverName}...');
        },
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _offerTimer?.cancel();
    _offersSubscription?.cancel();
    super.dispose();
  }

  // Location and Map Methods (Keep existing functionality)
  Marker? _currentLocationMarker;
  bool _isCurrentLocationVisible = false;

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission denied')),
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location permission permanently denied'),
          ),
        );
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = position;
        _isCurrentLocationVisible = true;
      });

      _addCurrentLocationMarker();

      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(position.latitude, position.longitude),
          16.0,
        ),
      );
    } catch (e) {
      print("Error getting location: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error getting location: $e')));
    }
  }

  void _addCurrentLocationMarker() {
    if (_currentPosition != null) {
      final marker = Marker(
        markerId: const MarkerId('current_location'),
        position: LatLng(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: const InfoWindow(
          title: 'Your Current Location',
          snippet: 'You are here',
        ),
        zIndex: 1000,
      );

      setState(() {
        _currentLocationMarker = marker;
        _markers.removeWhere((m) => m.markerId.value == 'current_location');
        _markers.add(marker);
      });
    }
  }

  void _addDestinationMarker(LocationData destination) {
    setState(() {
      _markers.add(
        Marker(
          markerId: const MarkerId('destination'),
          position: LatLng(
            destination.coordinates.latitude,
            destination.coordinates.longitude,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(title: destination.title),
        ),
      );
    });
  }

  void _testDirectFlow() {
    print("🎯 Testing direct flow");

    final pickup = LocationData(
      'Current Location',
      'Your current location',
      coordinates: LatLng(31.4504, 74.0503),
    );

    final destination = LocationData(
      'Lahore',
      'Pakistan',
      coordinates: const LatLng(31.5497, 74.3436),
    );

    _handleLocationSelect(pickup, destination);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: AppDrawer(userId: widget.userId,),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
              _getCurrentLocation();
            },
            initialCameraPosition: const CameraPosition(
              target: LatLng(31.4504, 74.0503),
              zoom: 14,
            ),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            markers: _markers,
            polylines: _polylines,
            compassEnabled: true,
            zoomControlsEnabled: false,
          ),

          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(top: 8.0, left: 8.0, right: 8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () {
                        _scaffoldKey.currentState!.openDrawer();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.menu,
                          color: Colors.black,
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (_pickupLocation != null)
                      Expanded(
                        child: GestureDetector(
                          onTap: _navigateToLocationSearch,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 5,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.pin_drop,
                                  color: Color(0xFF67B546),
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _pickupLocation!.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const Icon(
                                  Icons.keyboard_arrow_right,
                                  color: Colors.grey,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          MainModalSheet(
            truckTypes: _truckTypes,
            selectedTruckType: _selectedTruckType,
            onTruckTypeSelect: (type) {
              setState(() {
                _selectedTruckType = type;
              });
            },
            onLocationInputTap: _navigateToLocationSearch,
            onCurrentLocationTap: _onCurrentLocationTap,
          ),

          ..._activeOffers
              .map(
                (offer) => Positioned(
                  top: 16.0 + (_activeOffers.indexOf(offer) * 180),
                  left: 0,
                  right: 0,
                  child: AnimatedDriverOfferNotification(
                    offer: offer,
                    onAccept: () => _handleOfferAccept(offer),
                    onDecline: () => _handleOfferDecline(offer),
                    displayDuration: const Duration(seconds: 15),
                  ),
                ),
              )
              .toList(),

          if (_activeOffer != null)
            DriverOfferNotification(
              offer: _activeOffer!,
              onAccept: () {
                setState(() => _activeOffer = null);
                _offerTimer?.cancel();
                _showSnackbar(
                  context,
                  'Offer Accepted from ${_activeOffer!.driverName}',
                );
              },
              onDecline: () {
                setState(() => _activeOffer = null);
                _offerTimer?.cancel();
                _showSnackbar(context, 'Offer Declined');
              },
            ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          const SizedBox(height: 10),
          FloatingActionButton(
            onPressed: _testDirectFlow,
            mini: true,
            child: const Icon(Icons.my_location),
          ),
        ],
      ),
    );
  }

  void _showSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }
}

class FareNegotiationScreen extends StatefulWidget {
  final TripOption tripOption;
  final LocationData pickupLocation;
  final LocationData destinationLocation;
  final VoidCallback onFindDriver;

  const FareNegotiationScreen({
    super.key,
    required this.tripOption,
    required this.pickupLocation,
    required this.destinationLocation,
    required this.onFindDriver,
  });

  @override
  State<FareNegotiationScreen> createState() => _FareNegotiationScreenState();
}

class _FareNegotiationScreenState extends State<FareNegotiationScreen> {
  double _currentFare = 7550.0;
  int _loadCount = 1;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  TextEditingController _notesController = TextEditingController();
  List<XFile> _selectedImages = [];
  bool _isNotesDialogOpen = false;
  final FirebaseService _firebaseService = FirebaseService();

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

Future<void> _saveDeliveryRequest() async {
  try {
    List<String> imageUrls = [];
    if (_selectedImages.isNotEmpty) {
      final tempRequestId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
      imageUrls = await _firebaseService.uploadImages(
        _selectedImages,
        tempRequestId,
      );
    }

    final deliveryRequest = DeliveryRequest(
      userId: _firebaseService.getCurrentUserId(),
      pickup: widget.pickupLocation,
      destination: widget.destinationLocation,
      truckType: widget.tripOption.title,
      loadWeight: _loadCount.toDouble(),
      fare: _currentFare,
      deliveryDate: _selectedDate,
      deliveryTime: _selectedTime,
      deliveryNotes: _notesController.text.isNotEmpty
          ? _notesController.text
          : null,
      imageUrls: imageUrls,
      createdAt: DateTime.now(),
    );

    final requestId = await _firebaseService.saveDeliveryRequest(
      deliveryRequest,
    );
    
    print('Delivery request saved with ID: $requestId');
    _showSnackbar(context, 'Delivery request submitted successfully!');

    // Navigate to DriverOffersScreen with the request data
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DriverOffersScreen(
          deliveryRequestId: requestId,
          deliveryRequest: deliveryRequest,
        ),
      ),
    );

  } catch (e) {
    print('Error saving delivery request: $e');
    _showSnackbar(context, 'Failed to submit delivery request');
  }
}
  // Future<void> _saveDeliveryRequest() async {
  //   try {
  //     List<String> imageUrls = [];
  //     if (_selectedImages.isNotEmpty) {
  //       final tempRequestId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
  //       imageUrls = await _firebaseService.uploadImages(
  //         _selectedImages,
  //         tempRequestId,
  //       );
  //     }

  //     final deliveryRequest = DeliveryRequest(
  //       userId: _firebaseService.getCurrentUserId(),
  //       pickup: widget.pickupLocation,
  //       destination: widget.destinationLocation,
  //       truckType: widget.tripOption.title,
  //       loadWeight: _loadCount.toDouble(),
  //       fare: _currentFare,
  //       deliveryDate: _selectedDate,
  //       deliveryTime: _selectedTime,
  //       deliveryNotes: _notesController.text.isNotEmpty
  //           ? _notesController.text
  //           : null,
  //       imageUrls: imageUrls,
  //       createdAt: DateTime.now(),
  //     );

  //     final requestId = await _firebaseService.saveDeliveryRequest(
  //       deliveryRequest,
  //     );
  //     print('Delivery request saved with ID: $requestId');

  //     _showSnackbar(context, 'Delivery request submitted successfully!');

  //     // Proceed to find drivers
  //     widget.onFindDriver();
  //   } catch (e) {
  //     print('Error saving delivery request: $e');
  //     _showSnackbar(context, 'Failed to submit delivery request');
  //   }
  // }


  Widget _buildImageItem(XFile imageFile, int index) {
    return GestureDetector(
      onTap: () {
  
        _showImagePreview(context, imageFile, index);
      },
      child: Container(
        height: 130, 
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Stack(
          children: [
    
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                File(imageFile.path),
                width: double.infinity,
                height: 130,
                fit: BoxFit.fill,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[200],
                    height: 130,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error, color: Colors.grey[400], size: 30),
                        const SizedBox(height: 4),
                        Text(
                          'Error loading',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            Positioned(
              top: 6,
              right: 6,
              child: GestureDetector(
                onTap: () => _removeImage(index),
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 14),
                ),
              ),
            ),

            // Image number badge
            if (_selectedImages.length > 1)
              Positioned(
                top: 6,
                left: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showImagePreview(BuildContext context, XFile imageFile, int index) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Stack(
          children: [
            Container(
              width: double.infinity,
              height: 400,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.black,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(File(imageFile.path), fit: BoxFit.contain),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            Positioned(
              bottom: 10,
              left: 0,
              right: 0,
              child: Text(
                'Image ${index + 1} of ${_selectedImages.length}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedImagesRow() {
    // Calculate how many rows we need (3 images per row)
    int totalRows = (_selectedImages.length / 3).ceil();

    return Column(
      children: List.generate(totalRows, (rowIndex) {
        int startIndex = rowIndex * 3;
        int endIndex = startIndex + 3;
        if (endIndex > _selectedImages.length) {
          endIndex = _selectedImages.length;
        }

        List<XFile> rowImages = _selectedImages.sublist(startIndex, endIndex);

        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            children: [
              for (int i = 0; i < 3; i++) ...[
                if (i < rowImages.length)
                  Expanded(child: _buildImageItem(rowImages[i], startIndex + i))
                else
                  Expanded(
                    child: Container(), // Empty space for alignment
                  ),
                if (i < 2) const SizedBox(width: 8), // Spacing between images
              ],
            ],
          ),
        );
      }),
    );
  }

  void _showDeliveryNotesDialog(BuildContext context) {
    if (_isNotesDialogOpen) return;

    _isNotesDialogOpen = true;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Delivery Notes',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.grey),
                        onPressed: () {
                          _isNotesDialogOpen = false;
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Add instructions and photos for your delivery',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  const SizedBox(height: 24),

                  // Notes Section
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Colors.grey[50]!, Colors.grey[100]!],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: TextField(
                      controller: _notesController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: 'Enter delivery instructions...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(16),
                        hintStyle: TextStyle(color: Colors.grey),
                      ),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Images Section Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF67B546).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.photo_library,
                          color: Color(0xFF67B546),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Item Photos',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            'Add photos of items to deliver',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Selected Images Grid
                  if (_selectedImages.isNotEmpty) ...[
                    _buildImageGrid(),
                    const SizedBox(height: 16),
                  ],

                  // Add Photos Button
                  Container(
                    width: double.infinity,
                    height: 54,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF67B546).withOpacity(0.9),
                          const Color(0xFF67B546),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF67B546).withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: _pickImages,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.add_photo_alternate,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _selectedImages.isEmpty
                                  ? 'Add Photos'
                                  : 'Add More Photos',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_selectedImages.isNotEmpty)
                    Center(
                      child: Text(
                        '${_selectedImages.length} photo${_selectedImages.length > 1 ? 's' : ''} selected',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ),

                  const SizedBox(height: 24),

                  Container(
                    width: double.infinity,
                    height: 54,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF67B546).withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {});
                        _isNotesDialogOpen = false;
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF67B546),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Save Notes & Photos',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ).then((_) {
      _isNotesDialogOpen = false;
    });
  }

  Widget _buildImageGrid() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!),
      ),
      padding: const EdgeInsets.all(12),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 1,
        ),
        itemCount: _selectedImages.length,
        itemBuilder: (context, index) {
          return Stack(
            children: [
              // Image Container
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    File(_selectedImages[index].path),
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.error, color: Colors.grey),
                      );
                    },
                  ),
                ),
              ),

              // Remove Button
              Positioned(
                top: 4,
                right: 4,
                child: GestureDetector(
                  onTap: () => _removeImage(index),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(4),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                ),
              ),

              // Image Number Badge (for multiple images)
              if (_selectedImages.length > 1)
                Positioned(
                  top: 4,
                  left: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _pickImages() async {
    // Check if the maximum limit of 9 images has already been reached.
    if (_selectedImages.length >= 9) {
      // Show message when limit is reached before showing the dialog
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maximum 9 photos allowed'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    await showDialog<ImageSourceType>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text('Add Photos'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take a Photo'),
                onTap: () {
                  Navigator.pop(context, ImageSourceType.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Select from Gallery'),
                onTap: () {
                  Navigator.pop(context, ImageSourceType.gallery);
                },
              ),
            ],
          ),
        );
      },
    ).then((ImageSourceType? selection) {
      if (selection != null) {
        // Call the function to handle the actual image picking based on selection
        _handleImagePicking(selection);
      }
    });
  }

  Future<void> _handleImagePicking(ImageSourceType source) async {
    try {
      final ImagePicker picker = ImagePicker();
      List<XFile> images = [];

      if (source == ImageSourceType.camera) {
        // 1. Take a Photo (Camera)
        final XFile? image = await picker.pickImage(
          source: ImageSource.camera,
          maxWidth: 1024,
          maxHeight: 1024,
          imageQuality: 85,
        );
        if (image != null) {
          images = [image]; // Wrap single XFile into a list
        }
      } else if (source == ImageSourceType.gallery) {
        // 2. Select from Gallery (Multi-Image)
        final List<XFile>? pickedImages = await picker.pickMultiImage(
          maxWidth: 1024,
          maxHeight: 1024,
          imageQuality: 85,
        );
        if (pickedImages != null) {
          images = pickedImages;
        }
      }

      // Process the selected images (either 1 from camera or N from gallery)
      if (images.isNotEmpty) {
        setState(() {
          // Limit to 9 images maximum, considering already selected images
          int remainingSlots = 9 - _selectedImages.length;
          if (remainingSlots > 0) {
            // Add up to remainingSlots from the newly picked images
            _selectedImages.addAll(images.take(remainingSlots));
          }
          // Note: The maximum limit check is already done in _pickImages.
          // This block primarily adds the selected images.
        });
      }
    } catch (e) {
      print('Error picking images: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error selecting photos'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _removeImage(int index) {
    final removedImage = _selectedImages[index];
    setState(() {
      _selectedImages.removeAt(index);
    });

    // Show undo snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Photo removed'),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'UNDO',
          textColor: const Color(0xFF67B546),
          onPressed: () {
            setState(() {
              _selectedImages.insert(index, removedImage);
            });
          },
        ),
      ),
    );
  }

  String _getDeliveryNotesSubtitle() {
    if (_notesController.text.isEmpty && _selectedImages.isEmpty) {
      return 'Add specific instructions for the driver';
    }

    List<String> parts = [];
    if (_notesController.text.isNotEmpty) {
      parts.add('Notes added');
    }
    if (_selectedImages.isNotEmpty) {
      parts.add(
        '${_selectedImages.length} photo${_selectedImages.length > 1 ? 's' : ''}',
      );
    }

    return parts.join(' • ');
  }

  void _selectDateAndTime(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),

      // 1. Apply a custom theme to the Date Picker
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            // 2. Override the color scheme to force the surface color to white
            colorScheme: const ColorScheme.light(
              surface: Colors.white, // The main background of the calendar area
              onSurface: Colors.black, // The color of text/dates on the surface
              primary: Colors
                  .deepPurple, // The color of the selected date circle/header
              onPrimary: Colors.white, // The color of text on the primary color
            ),
            // Fallback, also set the dialog background to white
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      // --- Time Picker Modification ---
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: _selectedTime,

        // Apply a custom theme to the Time Picker
        builder: (BuildContext context, Widget? child) {
          return Theme(
            data: ThemeData.light().copyWith(
              // Override the color scheme to force the surface color to white
              colorScheme: const ColorScheme.light(
                surface:
                    Colors.white, // The main background of the time picker area
                onSurface:
                    Colors.black, // The color of text/numbers on the surface
                primary: Colors
                    .deepPurple, // The color of the clock hands/selected time circle
                onPrimary: Colors.white,
              ),
              dialogBackgroundColor: Colors.white,
            ),
            child: child!,
          );
        },
      );

      if (pickedTime != null) {
        setState(() {
          _selectedDate = pickedDate;
          _selectedTime = pickedTime;
        });
      }
    }
  }

  void _adjustFare(double amount) {
    setState(() {
      _currentFare = (_currentFare + amount).clamp(50.0, 100000.0);
    });
  }

  void _adjustLoad(int change) {
    setState(() {
      _loadCount = (_loadCount + change).clamp(1, 10);
    });
  }

  @override
  Widget build(BuildContext context) {
    final selectedDateTimeString =
        '${_selectedDate.day}/${_selectedDate.month} ${_selectedTime.format(context)}';

    return Scaffold(
      appBar: AppBar(title: const Text('Specify Delivery Details')),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
        
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: DeliveryRouteDisplay(
                pickup: widget.pickupLocation.title,
                destination: widget.destinationLocation.title,
              ),
            ),
            // Mock Route Map on Top
            SizedBox(
              height: 200,
              child: RouteMap(
                pickupLocation: widget.pickupLocation,
                destinationLocation: widget.destinationLocation,
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Specify load details and your fare',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Load Capacity/Weight Selector
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Load Weight (Tons)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove, color: Colors.grey),
                          onPressed: () => _adjustLoad(-1),
                        ),
                        Text(
                          '$_loadCount',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add, color: Color(0xFF67B546)),
                          onPressed: () => _adjustLoad(1),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Fare Adjustment Widget
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildFareButton(Icons.remove, () => _adjustFare(-100)),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          'Rs${_currentFare.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          'Recommended fare Rs${(7550).toStringAsFixed(0)}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildFareButton(
                    Icons.add,
                    () => _adjustFare(100),
                    color: const Color(0xFF67B546),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Date and Time Picker
            _buildDetailTile(
              Icons.calendar_month_rounded,
              'Date and time',
              selectedDateTimeString,
              () => _selectDateAndTime(context),
            ),

            _buildDetailTile(
              Icons.comment,
              'Delivery Notes',
              _getDeliveryNotesSubtitle(),
              () => _showDeliveryNotesDialog(context),
            ),
            const Divider(height: 1),

            if (_selectedImages.isNotEmpty) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Selected Images (${_selectedImages.length})',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildSelectedImagesRow(),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ],
            const Divider(height: 1),
          ],
        ),
      ),

      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: () {
            _saveDeliveryRequest();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF67B546),
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'Find offers',
            style: TextStyle(fontSize: 18, color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildFareButton(IconData icon, VoidCallback onTap, {Color? color}) {
    // ... [Omitted for brevity, but remains in the original code structure] ...
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: color ?? Colors.grey[200],
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: color != null ? Colors.white : Colors.black),
        onPressed: onTap,
      ),
    );
  }

  Widget _buildDetailTile(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
 
    return ListTile(
      leading: Icon(icon, color: Colors.grey[700]),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
      ),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.grey)),
      trailing: const Icon(Icons.keyboard_arrow_right, size: 18),
      onTap: onTap,
    );
  }

  void _showSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }
}



class LocationSearchScreen extends StatefulWidget {
  final LocationData initialPickup;

  final bool isModal;
  final Function(LocationData, LocationData?)? onLocationSelect;

  const LocationSearchScreen({
    super.key,
    required this.initialPickup,
    this.isModal = false,
    this.onLocationSelect,
  });

  @override
  State<LocationSearchScreen> createState() => _LocationSearchScreenState();
}
class _LocationSearchScreenState extends State<LocationSearchScreen> {
  late TextEditingController _fromController;
  late TextEditingController _toController;
  LocationData? _selectedPickup;
  LocationData? _selectedDestination;

  @override
  void initState() {
    super.initState();
    _selectedPickup = widget.initialPickup;
    _fromController = TextEditingController(text: widget.initialPickup.title);
    _toController = TextEditingController();
  }

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
  }

  // In LocationSearchScreen class
  Future<void> _navigateToMapPicker() async {
    // Add delay to ensure we're not in build phase
    await Future.delayed(Duration(milliseconds: 100));

    if (!mounted) return;

    try {
      final result = await Navigator.of(context).push<LocationData>(
        MaterialPageRoute(
          builder: (ctx) => EnhancedMapPickerScreen(
            initialCameraPosition:
                _selectedPickup?.coordinates ?? const LatLng(31.4504, 74.0503),
            isSelectingPickup: _toController.text.isEmpty,
          ),
        ),
      );

      if (result != null && mounted) {
        final isDestination = _toController.text.isEmpty;
        _onSearchItemSelected(result, isDestination);
      }
    } catch (e) {
      print("Navigation error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to select location: $e')),
        );
      }
    }
  }

  void _onSearchItemSelected(LocationData location, bool isDestination) {
    if (!mounted) return;

    setState(() {
      if (isDestination) {
        _selectedDestination = location;
        _toController.text = location.title;
      } else {
        _selectedPickup = location;
        _fromController.text = location.title;
      }
    });

    // Auto-complete if both locations are selected
    if (_selectedPickup != null && _selectedDestination != null) {
      // Add delay to ensure state is updated
      Future.delayed(Duration(milliseconds: 100), () {
        if (mounted) {
          _completeLocationSelection();
        }
      });
    }
  }

  void _completeLocationSelection() {
    if (!mounted) return;

    if (widget.isModal && widget.onLocationSelect != null) {
      // Use callback for modal flow
      widget.onLocationSelect!(_selectedPickup!, _selectedDestination);
      Navigator.of(context).pop();
    } else {
      // Return data for non-modal flow
      Navigator.of(
        context,
      ).pop({'pickup': _selectedPickup, 'destination': _selectedDestination});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.isModal
          ? null
          : AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              ),
              title: const Text('Enter your Route'),
              actions: [
                if (_selectedPickup != null && _selectedDestination != null)
                  IconButton(
                    icon: const Icon(Icons.done, color: Color(0xFF67B546)),
                    onPressed: _completeLocationSelection,
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
              ],
            ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildLocationInput(
                  'From',
                  _fromController,
                  Icons.circle,
                  Colors.green,
                ),
                const SizedBox(height: 10),
                _buildLocationInput(
                  'To',
                  _toController,
                  Icons.circle,
                  Colors.red,
                  showClear: true,
                  onChanged: (value) {
                    setState(() {
                      if (value.isEmpty) {
                        _selectedDestination = null;
                      }
                    });
                  },
                ),
              ],
            ),
          ),
          ListTile(
            leading: Icon(Icons.map, color: Colors.blue),
            title: Text('Choose on map'),
            onTap: _navigateToMapPicker,
          ),

          const Divider(),

          Expanded(
            child: ListView(
              children: [
                _buildSearchResultTile(
                  'Lahore',
                  'Pakistan',
                  '168,5 km',
                  () => _onSearchItemSelected(
                    LocationData(
                      'Lahore',
                      'Pakistan',
                      coordinates: const LatLng(31.5497, 74.3436),
                    ),
                    true,
                  ),
                ),
                _buildSearchResultTile(
                  'Shamsheer Town',
                  'Sargodha',
                  '1,6 km',
                  () => _onSearchItemSelected(
                    LocationData(
                      'Shamsheer Town',
                      'Sargodha',
                      coordinates: const LatLng(31.4604, 74.0603),
                    ),
                    true,
                  ),
                ),
                _buildSearchResultTile(
                  'Lahore City',
                  'Pakistan',
                  '166,8 km',
                  () => _onSearchItemSelected(
                    LocationData(
                      'Lahore City',
                      'Pakistan',
                      coordinates: const LatLng(31.5204, 74.3587),
                    ),
                    true,
                  ),
                ),

                ListTile(
                  leading: Icon(Icons.flash_on, color: Colors.orange),
                  title: Text('Quick Select (Test)'),
                  onTap: () {
                    final pickup = widget.initialPickup;
                    final destination = LocationData(
                      'Lahore',
                      'Pakistan',
                      coordinates: const LatLng(31.5497, 74.3436),
                    );

                    if (widget.isModal) {
                      widget.onLocationSelect!(pickup, destination);
                      Navigator.of(context).pop();
                    } else {
                      Navigator.of(
                        context,
                      ).pop({'pickup': pickup, 'destination': destination});
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationInput(
    String label,
    TextEditingController controller,
    IconData icon,
    Color color, {
    bool showClear = false,
    Function(String)? onChanged,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 10),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: label,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              suffixIcon: showClear && controller.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () {
                        controller.clear();
                        setState(() {
                          _selectedDestination = null;
                        });
                        onChanged?.call('');
                      },
                    )
                  : null,
            ),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchResultTile(
    String title,
    String subtitle,
    String distance,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: const Icon(Icons.location_on, color: Colors.grey),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.grey)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(distance, style: const TextStyle(color: Colors.grey)),
          const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
        ],
      ),
      onTap: onTap,
    );
  }
}
class MapPickerScreen extends StatefulWidget {
  final LatLng initialCameraPosition;

  const MapPickerScreen({super.key, required this.initialCameraPosition});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}
class _MapPickerScreenState extends State<MapPickerScreen> {
  GoogleMapController? _mapController;
  LatLng? _selectedLocation;
  String _currentAddress = 'Select a location';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
            },
            initialCameraPosition: CameraPosition(
              target: widget.initialCameraPosition,
              zoom: 14,
            ),
            onTap: (LatLng position) {
              _onMapTapped(position);
            },
            myLocationEnabled: true,
            markers: _selectedLocation != null
                ? {
                    Marker(
                      markerId: const MarkerId('selected_location'),
                      position: _selectedLocation!,
                      icon: BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueRed,
                      ),
                    ),
                  }
                : {},
          ),

          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 5,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.black),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Expanded(
                      child: Text(
                        _currentAddress,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
            ),
          ),
          const Center(
            child: Icon(Icons.location_on, size: 48, color: Colors.red),
          ),

          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: ElevatedButton(
              onPressed: _selectedLocation != null
                  ? () {
                      Navigator.of(context).pop(
                        LocationData(
                          _currentAddress,
                          'Selected location',
                          coordinates: _selectedLocation!,
                        ),
                      );
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF67B546),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Done',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onMapTapped(LatLng position) async {
    setState(() {
      _selectedLocation = position;
    });
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark placemark = placemarks.first;
        setState(() {
          _currentAddress = '${placemark.street}, ${placemark.locality}';
        });
      }
    } catch (e) {
      print("Error getting address: $e");
      setState(() {
        _currentAddress =
            'Lat: ${position.latitude.toStringAsFixed(4)}, Lon: ${position.longitude.toStringAsFixed(4)}';
      });
    }
  }
}
class FindingOfferScreen extends StatefulWidget {
  final TripOption tripOption;

  const FindingOfferScreen({super.key, required this.tripOption});

  @override
  State<FindingOfferScreen> createState() => _FindingOfferScreenState();
}

class _FindingOfferScreenState extends State<FindingOfferScreen> {
  GoogleMapController? _mapController;
  DriverOffer? _incomingOffer;
  Timer? _offerGenerationTimer;
  Timer? _screenTimeoutTimer;
  bool _isSearching = true;

  @override
  void initState() {
    super.initState();
    _startSearching();
  }

  void _startSearching() {
    setState(() => _isSearching = true);
    _offerGenerationTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _incomingOffer = DriverOffer(
            'incoming-1',
            'Driver Name A',
            7900.0,
            3.2,
            widget.tripOption.title,
          );
          _isSearching = false;
        });

        _screenTimeoutTimer = Timer(const Duration(seconds: 8), () {
          if (mounted && _incomingOffer != null) {
            Navigator.of(context).pop();
          }
        });
      }
    });
  }

  void _handleOfferAction(bool accepted) {
    _offerGenerationTimer?.cancel();
    _screenTimeoutTimer?.cancel();
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _offerGenerationTimer?.cancel();
    _screenTimeoutTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
            },
            initialCameraPosition: const CameraPosition(
              target: LatLng(31.4504, 74.0503),
              zoom: 14,
            ),
            myLocationEnabled: true,
            zoomControlsEnabled: false,
          ),

          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.1),
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isSearching)
                    const Column(
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFFCCFF00),
                          ),
                        ),
                        SizedBox(height: 20),
                        Text(
                          'Searching for offers...',
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),

          if (_incomingOffer != null)
            Positioned(
              top: 50,
              left: 10,
              right: 10,
              child: DriverOfferNotification(
                offer: _incomingOffer!,
                onAccept: () => _handleOfferAction(true),
                onDecline: () => _handleOfferAction(false),
              ),
            ),

          Positioned(
            top: 50,
            left: 10,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
              style: IconButton.styleFrom(backgroundColor: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }
}

class MockGoogleMap extends StatelessWidget {
  final LatLng center;

  const MockGoogleMap({super.key, required this.center});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[200],
      alignment: Alignment.center,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Mock Map Background with coordinates reference
          Text(
            'Google Maps Placeholder\nLat: ${center.latitude}, Lon: ${center.longitude}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, color: Colors.grey),
          ),
          // Mock Map Pin/Marker (e.g., current location pin)
          const Positioned(
            top: 250,
            child: Icon(
              Icons.location_on,
              size: 48,
              color: Color(0xFF67B546), // Green pin for current location
            ),
          ),
        ],
      ),
    );
  }
}

class MainModalSheet extends StatelessWidget {
  final List<TruckType> truckTypes;
  final TruckType selectedTruckType;
  final Function(TruckType) onTruckTypeSelect;
  final VoidCallback onLocationInputTap;
  final VoidCallback onCurrentLocationTap;

  const MainModalSheet({
    super.key,
    required this.truckTypes,
    required this.selectedTruckType,
    required this.onTruckTypeSelect,
    required this.onLocationInputTap,
    required this.onCurrentLocationTap,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.25,
      maxChildSize: 0.9,
      snap: true,
      builder: (context, scrollController) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(25.0)),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10.0,
                  spreadRadius: 2.0,
                ),
              ],
            ),
            child: SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.only(top: 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 16),

                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      children: [
                        TruckTypeChip(
                          type: TruckType(
                            'current',
                            'Current',
                            Icons.my_location,
                          ),
                          isSelected: false,
                          onTap: onCurrentLocationTap,
                        ),
                        const SizedBox(width: 12),
                        ...truckTypes.map((type) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 12.0),
                            child: TruckTypeChip(
                              type: type,
                              isSelected: type.id == selectedTruckType.id,
                              onTap: () => onTruckTypeSelect(type),
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  GestureDetector(
                    onTap: onLocationInputTap,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16.0),
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.search, color: Colors.grey),
                          SizedBox(width: 10),
                          Text(
                            'Where to & for how much?',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Saved Locations/Popular Destinations (Mock Data)
                  _buildDestinationTile(
                    'Shamseer Town',
                    'Sargodha',
                    Icons.access_time,
                  ),
                  _buildDestinationTile(
                    'Daewoo Terminal',
                    'Sargodha',
                    Icons.access_time,
                  ),
                  _buildDestinationTile(
                    'University of Sargodha',
                    'Sargodha',
                    Icons.location_on,
                  ),
                  const SizedBox(height: 20),
                  // Other Options (Request a Truck / Send a Courier)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      children: [
                        _buildOtherOptionTile(
                          context,
                          'Share your delivery',
                          'With other users, you pay per seat',
                          Icons.group,
                        ),
                        _buildOtherOptionTile(
                          context,
                          'Request a Large Truck',
                          'Request specific vehicle size',
                          Icons.fire_truck,
                        ),
                        _buildOtherOptionTile(
                          context,
                          'Send a courier',
                          'Delivery to another city',
                          Icons.archive,
                        ),
                        // Toll road warning (as seen in the video)
                        Container(
                          margin: const EdgeInsets.only(top: 20, bottom: 20),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD6F6E9),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Color(0xFF67B546),
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Toll roads aren\'t included in the fare. Please pay them separately',
                                  style: TextStyle(color: Color(0xFF67B546)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDestinationTile(String title, String subtitle, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.grey)),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 14,
        color: Colors.grey,
      ),
      onTap: () {
        // Handle selection of a saved location
      },
    );
  }

  Widget _buildOtherOptionTile(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[200]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.black, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ],
            ),
          ),
          const Icon(Icons.keyboard_arrow_right, color: Colors.grey),
        ],
      ),
    );
  }
}

class TruckTypeChip extends StatelessWidget {
  final TruckType type;
  final bool isSelected;
  final VoidCallback onTap;

  const TruckTypeChip({
    super.key,
    required this.type,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFD6F6E9) : Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: isSelected ? const Color(0xFF67B546) : Colors.grey[200]!,
                width: 2,
              ),
            ),
            child: Icon(
              type.icon,
              color: isSelected ? const Color(0xFF67B546) : Colors.grey[600],
              size: 30,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            type.name.split(' ').first,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? Colors.black : Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }
}

class MapScreen extends StatefulWidget {
  final LatLng initialCameraPosition;

  const MapScreen({super.key, required this.initialCameraPosition});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  LocationData _currentMapLocation = LocationData(
    'Gulberg III, Block N',
    'Lahore',
    coordinates: const LatLng(31.4504, 74.0503),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Mock Google Map (takes up the whole screen)
          MockGoogleMap(center: widget.initialCameraPosition),

          // Central Map Pin (Crosshair)
          const Center(
            child: Icon(Icons.location_on, size: 48, color: Colors.red),
          ),

          // Current Pin Location Display (Top Bar, like in done.jpg)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 5,
                      blurStyle: BlurStyle.normal,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.black),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Expanded(
                      child: Text(
                        _currentMapLocation.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(
                      width: 48,
                    ), // Spacer to align with back button
                  ],
                ),
              ),
            ),
          ),

          // "Done" Button (Bottom, like in done.jpg)
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: ElevatedButton(
              onPressed: () {
                // Return selected location
                Navigator.of(context).pop(_currentMapLocation);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF67B546),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Done',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TripTypeSelectionScreen extends StatelessWidget {
  final LocationData pickup;
  final LocationData destination;
  final Function(TripOption) onTripSelected;

  final List<TripOption> _deliveryOptions = [
    TripOption(
      'Small Truck Delivery',
      'Delivery only',
      '≈Rs7,550',
      Icons.local_shipping,
    ),
    TripOption(
      'Medium Truck Delivery',
      'Larger capacity, flexible rates',
      '≈Rs10,000',
      Icons.airport_shuttle,
    ),
    TripOption(
      'Heavy Truck Delivery',
      'For heavy machinery or goods',
      'Negotiable',
      Icons.fire_truck,
    ),
    TripOption(
      'Send a Courier',
      'Delivery to another city',
      'View options',
      Icons.archive,
    ),
  ];

  TripTypeSelectionScreen({
    super.key,
    required this.pickup,
    required this.destination,
    required this.onTripSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9, // Almost full screen
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      child: Column(
        children: [
          // Drag Handle
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          // Route display on top
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: DeliveryRouteDisplay(
              pickup: pickup.title,
              destination: destination.title,
            ),
          ),
          // Map section with route (simulated)
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              child: RouteMap(
                pickupLocation: pickup,
                destinationLocation: destination,
              ),
            ),
          ),
          // Selection list
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'What delivery do you need?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 10),
                ..._deliveryOptions
                    .map((option) => _buildTripOptionTile(option))
                    .toList(),
              ],
            ),
          ),
          // Next Button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () {
                // Use a small delay to prevent navigation conflicts
                Future.delayed(Duration(milliseconds: 100), () {
                  onTripSelected(_deliveryOptions.first);
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF67B546),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Next',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTripOptionTile(TripOption option) {
    return GestureDetector(
      onTap: () => onTripSelected(option),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
        ),
        child: Row(
          children: [
            Icon(option.icon, color: Colors.black, size: 28),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    option.subtitle,
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),
            ),
            Text(
              option.priceEstimate,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

class MockRouteMap extends StatelessWidget {
  const MockRouteMap({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Mock Route Line
          CustomPaint(size: Size.infinite, painter: RoutePainter()),
          // Start Point
          const Positioned(
            top: 50,
            left: 50,
            child: Icon(Icons.circle, color: Colors.green, size: 12),
          ),
          // End Point
          const Positioned(
            bottom: 50,
            right: 50,
            child: Icon(Icons.circle, color: Colors.red, size: 12),
          ),
        ],
      ),
    );
  }
}

class RouteMap extends StatefulWidget {
  final LocationData pickupLocation;
  final LocationData destinationLocation;

  const RouteMap({
    super.key,
    required this.pickupLocation,
    required this.destinationLocation,
  });

  @override
  State<RouteMap> createState() => _RouteMapState();
}

class _RouteMapState extends State<RouteMap> {
  GoogleMapController? _mapController;
  LatLng? _pickupLatLng;
  LatLng? _destinationLatLng;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _convertAddressesToCoordinates();
  }

  Future<void> _convertAddressesToCoordinates() async {
    try {
      // Convert pickup address to coordinates
      final pickupPlacemarks = await locationFromAddress(
        widget.pickupLocation.title,
      );
      if (pickupPlacemarks.isNotEmpty) {
        _pickupLatLng = LatLng(
          pickupPlacemarks.first.latitude,
          pickupPlacemarks.first.longitude,
        );
      }

      // Convert destination address to coordinates
      final destinationPlacemarks = await locationFromAddress(
        widget.destinationLocation.title,
      );
      if (destinationPlacemarks.isNotEmpty) {
        _destinationLatLng = LatLng(
          destinationPlacemarks.first.latitude,
          destinationPlacemarks.first.longitude,
        );
      }

      if (_pickupLatLng != null && _destinationLatLng != null) {
        _setupMap();
      }
    } catch (e) {
      print('Error converting addresses: $e');
      _setupMapWithDefaults();
    }
  }

  void _setupMap() {
    setState(() {
      _markers = {
        Marker(
          markerId: const MarkerId('pickup'),
          position: _pickupLatLng!,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
          infoWindow: InfoWindow(
            title: 'Pickup: ${widget.pickupLocation.title}',
          ),
        ),
        Marker(
          markerId: const MarkerId('destination'),
          position: _destinationLatLng!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(
            title: 'Destination: ${widget.destinationLocation.title}',
          ),
        ),
      };

      _polylines = {
        Polyline(
          polylineId: const PolylineId('route'),
          points: [_pickupLatLng!, _destinationLatLng!],
          color: const Color(0xFF67B546),
          width: 4,
        ),
      };

      _isLoading = false;
    });

    // Fit map to show both markers
    _fitMapToMarkers();
  }

  void _setupMapWithDefaults() {
    // Fallback to default coordinates if address conversion fails
    setState(() {
      _pickupLatLng = const LatLng(37.42796133580664, -122.085749655962);
      _destinationLatLng = const LatLng(37.4219999, -122.0840575);
      _setupMap();
    });
  }

  

  void _fitMapToMarkers() {
    if (_mapController != null &&
        _pickupLatLng != null &&
        _destinationLatLng != null) {
      final bounds = LatLngBounds(
        southwest: LatLng(
          _pickupLatLng!.latitude < _destinationLatLng!.latitude
              ? _pickupLatLng!.latitude
              : _destinationLatLng!.latitude,
          _pickupLatLng!.longitude < _destinationLatLng!.longitude
              ? _pickupLatLng!.longitude
              : _destinationLatLng!.longitude,
        ),
        northeast: LatLng(
          _pickupLatLng!.latitude > _destinationLatLng!.latitude
              ? _pickupLatLng!.latitude
              : _destinationLatLng!.latitude,
          _pickupLatLng!.longitude > _destinationLatLng!.longitude
              ? _pickupLatLng!.longitude
              : _destinationLatLng!.longitude,
        ),
      );

      _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.grey[100],
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: Color(0xFF67B546)),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!)),
      child: GoogleMap(
        onMapCreated: (controller) {
          _mapController = controller;
          _fitMapToMarkers();
        },
        initialCameraPosition: CameraPosition(
          target:
              _pickupLatLng ??
              const LatLng(37.42796133580664, -122.085749655962),
          zoom: 14,
        ),
        markers: _markers,
        polylines: _polylines,
        myLocationEnabled: true,
        myLocationButtonEnabled: false,
        zoomControlsEnabled: false,
      ),
    );
  }
}

class RoutePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(size.width * 0.1, size.height * 0.1)
      ..cubicTo(
        size.width * 0.4,
        size.height * 0.05,
        size.width * 0.6,
        size.height * 0.95,
        size.width * 0.9,
        size.height * 0.9,
      );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class DeliveryRouteDisplay extends StatelessWidget {
  final String pickup;
  final String destination;

  const DeliveryRouteDisplay({
    super.key,
    required this.pickup,
    required this.destination,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.circle, color: Colors.green, size: 10),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                pickup,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
        Container(
          height: 10,
          width: 2,
          color: Colors.grey,
          margin: const EdgeInsets.only(left: 4, top: 2, bottom: 2),
        ),
        Row(
          children: [
            const Icon(Icons.circle, color: Colors.red, size: 10),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                destination,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class DriverOfferNotification extends StatelessWidget {
  final DriverOffer offer;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const DriverOfferNotification({
    super.key,
    required this.offer,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 6.0,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF67B546), width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.amber,
                  child: Text(
                    offer.driverName[0],
                    style: const TextStyle(color: Colors.black),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'New Offer from ${offer.driverName}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '${offer.truckType} - ${offer.distance.toStringAsFixed(1)}km away',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Text(
                  'Rs${offer.fare.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Color(0xFF67B546),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: onDecline,
                  child: const Text(
                    'DECLINE',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: onAccept,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF67B546),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'ACCEPT',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}



class AnimatedDriverOfferNotification extends StatefulWidget {
  final DriverOffer offer;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  final Duration displayDuration;

  const AnimatedDriverOfferNotification({
    super.key,
    required this.offer,
    required this.onAccept,
    required this.onDecline,
    this.displayDuration = const Duration(seconds: 15),
  });

  @override
  State<AnimatedDriverOfferNotification> createState() =>
      _AnimatedDriverOfferNotificationState();
}

class _AnimatedDriverOfferNotificationState
    extends State<AnimatedDriverOfferNotification>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  Timer? _autoDismissTimer;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();

    _autoDismissTimer = Timer(widget.displayDuration, () {
      _dismissNotification();
    });
  }

  void _dismissNotification() {
    if (_controller.status != AnimationStatus.dismissed) {
      _controller.reverse().then((_) {
        if (mounted) {
          widget.onDecline();
        }
      });
    }
  }

  void _acceptOffer() {
    _autoDismissTimer?.cancel();
    _controller.reverse().then((_) {
      if (mounted) {
        widget.onAccept();
      }
    });
  }

  void _declineOffer() {
    _autoDismissTimer?.cancel();
    _dismissNotification();
  }

  @override
  void dispose() {
    _autoDismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        margin: const EdgeInsets.all(16.0),
        child: Material(
          elevation: 8.0,
          borderRadius: BorderRadius.circular(16.0),
          child: Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(color: const Color(0xFF67B546), width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
             
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.amber[100],
                      child: Text(
                        widget.offer.driverName[0],
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'New Offer from ${widget.offer.driverName}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            '${widget.offer.truckType} • ${widget.offer.distance.toStringAsFixed(1)}km away',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    CountdownTimer(
                      duration: widget.displayDuration,
                      onTimerEnd: _dismissNotification,
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Fare and vehicle details
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Rs${widget.offer.fare.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                            color: Color(0xFF67B546),
                          ),
                        ),
                        Text(
                          'Estimated fare',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.local_shipping,
                            color: Colors.grey[600],
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            widget.offer.truckType,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _declineOffer,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('DECLINE'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _acceptOffer,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF67B546),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'ACCEPT',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CountdownTimer extends StatefulWidget {
  final Duration duration;
  final VoidCallback onTimerEnd;

  const CountdownTimer({
    super.key,
    required this.duration,
    required this.onTimerEnd,
  });

  @override
  State<CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(duration: widget.duration, vsync: this);

    _animation = Tween<double>(begin: 1.0, end: 0.0).animate(_controller)
      ..addListener(() {
        setState(() {});
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          widget.onTimerEnd();
        }
      });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 30,
          height: 30,
          child: CircularProgressIndicator(
            value: _animation.value,
            strokeWidth: 3,
            backgroundColor: Colors.grey[300],
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF67B546)),
          ),
        ),
        Text(
          '${(widget.duration.inSeconds * _animation.value).ceil()}',
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}



class DriverOfferManager {
  final List<DriverOffer> _offers = [];
  final Function(DriverOffer) onNewOffer;
  final Function(DriverOffer) onOfferExpired;

  DriverOfferManager({required this.onNewOffer, required this.onOfferExpired});

  void addOffer(DriverOffer offer, Duration duration) {
    _offers.add(offer);
    onNewOffer(offer);

    // Auto remove after duration
    Future.delayed(duration, () {
      if (_offers.contains(offer)) {
        _offers.remove(offer);
        onOfferExpired(offer);
      }
    });
  }

  void removeOffer(DriverOffer offer) {
    _offers.remove(offer);
    onOfferExpired(offer);
  }

  List<DriverOffer> get activeOffers => List.from(_offers);
}

class RideAcceptedScreen extends StatelessWidget {
  final DriverOffer offer;
  final VoidCallback onCancel;
  final VoidCallback onContactDriver;

  const RideAcceptedScreen({
    super.key,
    required this.offer,
    required this.onCancel,
    required this.onContactDriver,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 10),
            width: 40,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
          ),

          const SizedBox(height: 20),

          const Icon(Icons.check_circle, color: Color(0xFF67B546), size: 60),

          const SizedBox(height: 16),

          const Text(
            'Ride Accepted!',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 8),

          Text(
            'Your driver is on the way',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),

          const SizedBox(height: 30),

          // Driver info card
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.amber[100],
                  radius: 30,
                  child: Text(
                    offer.driverName[0],
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        offer.driverName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        offer.truckType,

                        style: TextStyle(color: Colors.grey[600]),
                      ),

                      const SizedBox(height: 8),

                      Row(
                        children: [
                          Icon(Icons.star, color: Colors.amber[400], size: 16),
                          const SizedBox(width: 4),
                          const Text(
                            '4.8',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${offer.distance.toStringAsFixed(1)} km away',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                IconButton(
                  icon: const Icon(Icons.phone, color: Color(0xFF67B546)),
                  onPressed: onContactDriver,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Fare and ETA info
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildInfoColumn('Fare', 'Rs${offer.fare.toStringAsFixed(0)}'),
                _buildInfoColumn('ETA', '15-20 min'),
                _buildInfoColumn('Vehicle', 'Truck'),
              ],
            ),
          ),

          const Spacer(),

          // Action buttons
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onCancel,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Cancel Ride'),
                  ),
                ),

                const SizedBox(width: 16),

                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // Track ride functionality
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF67B546),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Track Ride',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoColumn(String title, String value) {
    return Column(
      children: [
        Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}



class EnhancedMapPickerScreen extends StatefulWidget {
  final LatLng initialCameraPosition;
  final bool isSelectingPickup;

  const EnhancedMapPickerScreen({
    super.key,
    required this.initialCameraPosition,
    required this.isSelectingPickup,
  });

  @override
  State<EnhancedMapPickerScreen> createState() =>
      _EnhancedMapPickerScreenState();
}

class _EnhancedMapPickerScreenState extends State<EnhancedMapPickerScreen> {
  GoogleMapController? _mapController;
  LatLng? _selectedLocation;
  String _currentAddress = 'Select a location';
  bool _isPickup = true;

  @override
  void initState() {
    super.initState();
    _isPickup = widget.isSelectingPickup;
  }

  void _toggleSelectionType() {
    setState(() {
      _isPickup = !_isPickup;
    });
  }

  void _selectLocation() {
    if (_selectedLocation != null && mounted) {
      final selectedLocation = LocationData(
        _currentAddress,
        _isPickup ? 'Pickup location' : 'Destination location',
        coordinates: _selectedLocation!,
      );

      print("📍 Selected location: $_currentAddress");
      Navigator.of(context).pop(selectedLocation);
    }
  }

  // Fix the back button

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
            },
            initialCameraPosition: CameraPosition(
              target: widget.initialCameraPosition,
              zoom: 14,
            ),
            onTap: (LatLng position) {
              _onMapTapped(position);
            },
            myLocationEnabled: true,
            markers: _selectedLocation != null
                ? {
                    Marker(
                      markerId: const MarkerId('selected_location'),
                      position: _selectedLocation!,
                      icon: BitmapDescriptor.defaultMarkerWithHue(
                        _isPickup
                            ? BitmapDescriptor.hueGreen
                            : BitmapDescriptor.hueRed,
                      ),
                    ),
                  }
                : {},
          ),

          // Top Bar with Selection Toggle
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Column(
                children: [
                  // Selection Toggle
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 100),
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 5,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              if (!_isPickup) _toggleSelectionType();
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: _isPickup
                                    ? const Color(0xFF67B546)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Center(
                                child: Text(
                                  'From',
                                  style: TextStyle(
                                    color: _isPickup
                                        ? Colors.white
                                        : Colors.black,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              if (_isPickup) _toggleSelectionType();
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: !_isPickup
                                    ? const Color(0xFF67B546)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Center(
                                child: Text(
                                  'To',
                                  style: TextStyle(
                                    color: !_isPickup
                                        ? Colors.white
                                        : Colors.black,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Address Display
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 5,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.black,
                          ),
                          onPressed: () {
                            if (mounted) {
                              Navigator.of(context).pop();
                            }
                          },
                        ),

                        Expanded(
                          child: Text(
                            _currentAddress,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Center Crosshair with colored icon
          Center(
            child: Icon(
              Icons.location_on,
              size: 48,
              color: _isPickup ? Colors.green : Colors.red,
            ),
          ),

          // Done Button
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: ElevatedButton(
              onPressed: _selectedLocation != null ? _selectLocation : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF67B546),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Select ${_isPickup ? 'Pickup' : 'Destination'}',
                style: const TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onMapTapped(LatLng position) async {
    setState(() {
      _selectedLocation = position;
    });

    // Get address from coordinates
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark placemark = placemarks.first;
        setState(() {
          _currentAddress = '${placemark.street}, ${placemark.locality}';
        });
      }
    } catch (e) {
      print("Error getting address: $e");
      setState(() {
        _currentAddress =
            'Lat: ${position.latitude.toStringAsFixed(4)}, Lon: ${position.longitude.toStringAsFixed(4)}';
      });
    }
  }
}

class NavigationUtils {
  static Future<T?> safePush<T>(BuildContext context, Widget page) async {
    await Future.delayed(Duration(milliseconds: 100));
    if (!context.mounted) return null;

    return await Navigator.of(
      context,
    ).push<T>(MaterialPageRoute(builder: (context) => page));
  }

  static void safePop<T>(BuildContext context, [T? result]) {
    if (context.mounted) {
      Navigator.of(context).pop(result);
    }
  }
}
