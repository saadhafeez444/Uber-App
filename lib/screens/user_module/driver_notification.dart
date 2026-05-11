import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:uber_app/models/driver_offer.dart';

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

    // Start the enter animation
    _controller.forward();

    // Set up auto dismiss timer
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
                // Header with driver info and countdown
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

