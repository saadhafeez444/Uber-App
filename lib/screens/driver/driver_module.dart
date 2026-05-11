import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import 'dart:math';

import 'package:uber_app/screens/driver/dashboard_screen_driver.dart';
import 'package:uber_app/screens/driver/send_offer_screen.dart';
import 'package:uber_app/screens/driver/send_offer_screen_driver.dart';
import 'package:uber_app/screens/user_module/user_module.dart';


const Color kPrimaryBlue = Color(0xFF2563EB);
const Color kSecondaryGreen = Color(0xFF10B981); 
const Color kBackgroundColor = Color(0xFFF8F9FA);

class Location {
  final double latitude;
  final double longitude;
  final String address;

  Location({required this.latitude, required this.longitude, required this.address});
}



enum ShipmentType { box, pallet, container, document }


class ShipmentRequest {
  final String id;
  final String ownerId; // Needed for notification recipient
  final Location pickup;
  final Location dropoff;
  final double offeredPrice; // Base price
  final double distanceKm;
  final double weightKg;
  final ShipmentType type;
  final String description;
  final String dimensions; // e.g., "1.2m x 1m x 1m"
  final String specialRequirements; // e.g., "Fragile, requires climate control"
  final List<String>? images;

  // New fields for scheduling
  final DateTime requestedPickupDateTime;
  final DateTime requestedDeliveryDateTime;

  ShipmentRequest({
    required this.id,
    required this.ownerId,
    required this.pickup,
    required this.dropoff,
    required this.offeredPrice,
    required this.distanceKm,
    required this.weightKg,
    required this.type,
    required this.description,
    required this.dimensions,
    required this.specialRequirements,
    this.images,
    // Add new fields to the constructor
    required this.requestedPickupDateTime,
    required this.requestedDeliveryDateTime,
  });

  static ShipmentRequest mockSingle = ShipmentRequest(
    id: 'R1004',
    ownerId: 'USER-789',
    pickup: Location(latitude: 0, longitude: 0, address: '123 Tech Campus, SF'),
    dropoff: Location(latitude: 0, longitude: 0, address: '456 Distribution Center, Oakland'),
    offeredPrice: 850.00,
    distanceKm: 25.0,
    weightKg: 250.5,
    type: ShipmentType.pallet,
    description: 'Palletized components for assembly.',
    dimensions: '1.2m x 1m x 1.5m',
    specialRequirements: 'Liftgate required at dropoff.',
    images: [ 
      'https://example.com/images/R1004_pallet_view1.jpg',
      'https://example.com/images/R1004_label_closeup.jpg',
    ],
    // Add mock values for the new fields
    requestedPickupDateTime: DateTime(2025, 12, 1, 10, 0), // Dec 1, 2025 at 10:00 AM
    requestedDeliveryDateTime: DateTime(2025, 12, 1, 14, 30), // Dec 1, 2025 at 2:30 PM
  );
}


class DriverProfile {
  final String id;
  final String name;
  final String avatarUrl;
  final double rating;
  final String vehicleType; // e.g., "Cargo Van"
  final String licensePlate;

  DriverProfile({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.rating,
    required this.vehicleType,
    required this.licensePlate,
  });
  
  static DriverProfile mock = DriverProfile(
    id: 'DRV-123',
    name: 'Alex J.',
    avatarUrl: 'https://placehold.co/100x100/2563EB/FFFFFF?text=AJ',
    rating: 4.8,
    vehicleType: 'Box Truck',
    licensePlate: 'ABC 123',
  );
}

class FilterOptions {
  double radiusKm;
  ShipmentType? selectedType;
  RangeValues weightRangeKg;

  FilterOptions({
    required this.radiusKm,
    this.selectedType,
    required this.weightRangeKg,
  });
}

class MockShipmentService {

  final List<ShipmentRequest> _internalMockData = [
    ShipmentRequest(
    
      requestedPickupDateTime: DateTime(2025, 11, 20, 10, 0), // 20-Nov-2025 10:00 AM
    requestedDeliveryDateTime:
        DateTime(2025, 11, 20, 14, 0),
      
      images: [
        'assets/images/img1.jpg',
        'assets/images/img2.jpg',
        'assets/images/img3.jpg',
        'assets/images/img4.png',
        'assets/images/img5.jpg',
        'assets/images/img6.jpeg',
        
      ],
      id: 'R1001', ownerId: 'USER-123',
      pickup: Location(latitude: 37.77, longitude: -122.41, address: 'SFO Downtown Hub'),
      dropoff: Location(latitude: 37.80, longitude: -122.42, address: 'Oakland Port Terminal'),
      offeredPrice: 150.00, distanceKm: 8.5, weightKg: 50.0,
      type: ShipmentType.box, description: 'Urgent small parts delivery.',
      dimensions: '0.5m x 0.5m x 0.5m', specialRequirements: 'None',
    ),
    ShipmentRequest(
      requestedPickupDateTime: DateTime(2025, 11, 21, 8, 30), // 21-Nov-2025 08:30 AM
    requestedDeliveryDateTime:
        DateTime(2025, 11, 21, 16, 45),
       images: [
        'assets/images/img7.jpg',
        'assets/images/img8.jpg',
        'assets/images/img9.jpeg',
        'assets/images/img1.jpg',
        'assets/images/img2.jpg',
        'assets/images/img3.jpg',

      ],
      id: 'R1002', ownerId: 'USER-456',
      pickup: Location(latitude: 37.79, longitude: -122.45, address: 'Mission District Warehouse'),
      dropoff: Location(latitude: 37.85, longitude: -122.40, address: 'Richmond Distribution'),
      offeredPrice: 450.00, distanceKm: 25.3, weightKg: 800.0,
      type: ShipmentType.pallet, description: 'Standard wooden pallet of machinery.',
      dimensions: '1.0m x 1.2m x 1.8m', specialRequirements: 'Forklift access required',
    ),
    ShipmentRequest(
      requestedPickupDateTime: DateTime(2025, 11, 22, 11, 0), // 22-Nov-2025 11:00 AM
    requestedDeliveryDateTime:
        DateTime(2025, 11, 22, 13, 15),
       images: [
        'assets/images/img1.jpg',
        'assets/images/img2.jpg',
        'assets/images/img3.jpg',
      ],
      id: 'R1003', ownerId: 'USER-007',
      pickup: Location(latitude: 37.70, longitude: -122.48, address: 'Daly City Freight Yard'),
      dropoff: Location(latitude: 37.78, longitude: -122.40, address: 'Financial District Office'),
      offeredPrice: 85.00, distanceKm: 12.0, weightKg: 1.5,
      type: ShipmentType.document, description: 'Legal papers, time sensitive.',
      dimensions: 'A4 Envelope', specialRequirements: 'Secure transport only',
    ),
    ShipmentRequest(
      requestedPickupDateTime: DateTime(2025, 11, 25, 9, 30), // 25-Nov-2025 09:30 AM
    requestedDeliveryDateTime:
        DateTime(2025, 11, 25, 18, 0),
       images: [
        'assets/images/img1.jpg',
        'assets/images/img2.jpg',
        'assets/images/img3.jpg',
      ],
      id: 'R1004', ownerId: 'USER-789',
      pickup: Location(latitude: 37.81, longitude: -122.39, address: 'Berkeley Research Lab'),
      dropoff: Location(latitude: 37.75, longitude: -122.47, address: 'Sunset IT Hub'),
      offeredPrice: 1200.00, distanceKm: 45.0, weightKg: 5000.0,
      type: ShipmentType.container, description: '20ft shipping container load.',
      dimensions: '6.0m x 2.4m x 2.6m', specialRequirements: 'None',
    ),
  ];
  
  
  List<ShipmentRequest> get mockRequestsData => _internalMockData;


  Future<List<ShipmentRequest>> fetchNearbyRequests(Location currentLocation, double searchRadiusKm) async {
    await Future.delayed(const Duration(milliseconds: 1500));
    return _internalMockData;
  }

  Future<List<ShipmentRequest>> refreshRequests() async {
    await Future.delayed(const Duration(seconds: 1));
    return _internalMockData;
  }

  List<ShipmentRequest> filterRequests({
    required List<ShipmentRequest> requests,
    required FilterOptions options,
    required String searchQuery,
  }) {
    List<ShipmentRequest> results = requests.where((r) => r.distanceKm <= options.radiusKm).toList();

    if (options.selectedType != null) {
      results = results.where((r) => r.type == options.selectedType).toList();
    }

    results = results.where((r) => r.weightKg >= options.weightRangeKg.start && r.weightKg <= options.weightRangeKg.end).toList();

    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      results = results.where((r) => r.dropoff.address.toLowerCase().contains(query)).toList();
    }
    
    return results;
  }
}



class NearbyRequestsScreen extends StatefulWidget {
  final Location currentLocation;
  final double searchRadius;
  final List<ShipmentRequest> nearbyRequests;
  final DriverProfile driverProfile; 
    final MockOfferService offerService; // Add this

  const NearbyRequestsScreen({
    super.key,
    required this.currentLocation,
    required this.searchRadius,
    required this.nearbyRequests,
    required this.driverProfile,
        required this.offerService,
  });

  @override
  State<NearbyRequestsScreen> createState() => _NearbyRequestsScreenState();
}

class _NearbyRequestsScreenState extends State<NearbyRequestsScreen> with SingleTickerProviderStateMixin {
  final MockShipmentService _service = MockShipmentService();
  final TextEditingController _searchController = TextEditingController();
  
  List<ShipmentRequest> _allRequests = [];
  List<ShipmentRequest> _filteredRequests = [];
  
  bool _isLoading = true;
  bool _isFilterPanelExpanded = false;
  
  late FilterOptions _currentFilters;
  String _searchQuery = '';
  
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _currentFilters = FilterOptions(
      radiusKm: widget.searchRadius,
      weightRangeKg: const RangeValues(0, 10000),
    );
    _fetchRequests();

    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
        _applyFilters();
      });
    });
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(_animationController);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchRequests() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final requests = await _service.fetchNearbyRequests(
        widget.currentLocation, 
        widget.searchRadius,
      );
      setState(() {
        _allRequests = requests;
        _isLoading = false;
        _applyFilters();
      });
    } catch (e) {
      print('Error fetching requests: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handleRefresh() async {
    final requests = await _service.refreshRequests();
    setState(() {
      _allRequests = requests;
      _applyFilters();
    });
  }

  void _applyFilters() {
    setState(() {
      _filteredRequests = _service.filterRequests(
        requests: _allRequests,
        options: _currentFilters,
        searchQuery: _searchQuery,
      );
    });
  }
  
  void _resetFilters() {
    setState(() {
      _currentFilters = FilterOptions(
        radiusKm: 20.0,
        weightRangeKg: const RangeValues(0, 10000),
        selectedType: null,
      );
      _applyFilters();
    });
  }

  void _toggleFilterPanel() {
    setState(() {
      _isFilterPanelExpanded = !_isFilterPanelExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Nearby Requests', style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold)),
        backgroundColor: kPrimaryBlue,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      body: Column(
        children: [
          _buildSearchBarAndFilter(),
          _buildMapPlaceholder(context),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _handleRefresh,
              color: kPrimaryBlue,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: kPrimaryBlue))
                  : _filteredRequests.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.location_off, size: 60, color: Colors.grey.shade400),
                              const SizedBox(height: 10),
                              Text('No requests found.', style: TextStyle(color: Colors.grey.shade600)),
                              Text('Try adjusting your filters.', style: TextStyle(color: Colors.grey.shade600)),
                              TextButton(
                                onPressed: _resetFilters, 
                                child: const Text('Reset Filters', style: TextStyle(color: kPrimaryBlue)),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16.0),
                          itemCount: _filteredRequests.length,
                          itemBuilder: (context, index) {
                            return _buildRequestCard(_filteredRequests[index]);
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSearchBarAndFilter() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: Colors.white,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by destination...',
                    prefixIcon: const Icon(Icons.search, color: kPrimaryBlue),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.grey),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: kBackgroundColor,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 10),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              InkWell(
                onTap: _toggleFilterPanel,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _isFilterPanelExpanded ? kPrimaryBlue : kBackgroundColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300)
                  ),
                  child: Icon(
                    Icons.filter_list,
                    color: _isFilterPanelExpanded ? Colors.white : kPrimaryBlue,
                  ),
                ),
              ),
            ],
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: _isFilterPanelExpanded ? _buildFilterPanel() : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildMapPlaceholder(BuildContext context) {
  
  final Location pickup = Location(
    latitude: 31.5497, 
    longitude: 74.3436, 
    address: 'Lahore, Punjab, Pakistan', 
  );

  final Location destination = Location(
    latitude: 33.6844, 
    longitude: 73.0479, 
    address: 'Islamabad, Capital Territory, Pakistan',
  );

  return Container(
    height: 200,
    width: double.infinity,
    decoration: BoxDecoration(
      border: Border(bottom: BorderSide(color: Colors.grey.shade300, width: 1)),
    ),
    child: RouteMap(
      pickupLocation: pickup,
      destinationLocation: destination,
    ),
  );
}


  Widget _buildFilterPanel() {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Search Radius: ${_currentFilters.radiusKm.toStringAsFixed(0)} km',
              style: const TextStyle(fontWeight: FontWeight.w600)),
          Slider(
            value: _currentFilters.radiusKm,
            min: 5,
            max: 100,
            divisions: 19,
            activeColor: kPrimaryBlue,
            inactiveColor: kPrimaryBlue.withOpacity(0.3),
            label: '${_currentFilters.radiusKm.toStringAsFixed(0)} km',
            onChanged: (double value) {
              setState(() {
                _currentFilters.radiusKm = value;
                _applyFilters();
              });
            },
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<ShipmentType>(
            decoration: InputDecoration(
              labelText: 'Shipment Type',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            value: _currentFilters.selectedType,
            hint: const Text('All Types'),
            items: ShipmentType.values.map((type) {
              return DropdownMenuItem(
                value: type,
                child: Text(type.toString().split('.').last.toUpperCase()),
              );
            }).toList(),
            onChanged: (ShipmentType? newValue) {
              setState(() {
                _currentFilters.selectedType = newValue;
                _applyFilters();
              });
            },
            isExpanded: true,
          ),
          const SizedBox(height: 10),
          Text(
            'Weight Range: ${_currentFilters.weightRangeKg.start.toStringAsFixed(0)} kg - '
            '${_currentFilters.weightRangeKg.end.toStringAsFixed(0)} kg',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          RangeSlider(
            values: _currentFilters.weightRangeKg,
            min: 0,
            max: 10000,
            divisions: 100,
            labels: RangeLabels(
              _currentFilters.weightRangeKg.start.toStringAsFixed(0),
              _currentFilters.weightRangeKg.end.toStringAsFixed(0),
            ),
            activeColor: kSecondaryGreen,
            inactiveColor: kSecondaryGreen.withOpacity(0.3),
            onChanged: (RangeValues values) {
              setState(() {
                _currentFilters.weightRangeKg = values;
                _applyFilters();
              });
            },
          ),
          Center(
            child: TextButton(
              onPressed: _resetFilters,
              child: const Text('Reset All Filters', style: TextStyle(color: kPrimaryBlue)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestCard(ShipmentRequest request) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Card(

        color: Colors.white,
        margin: const EdgeInsets.only(bottom: 16),
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: kSecondaryGreen.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '\$${request.offeredPrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: kSecondaryGreen,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.directions_car, color: Colors.grey, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        '${request.distanceKm.toStringAsFixed(1)} km away',
                        style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ],
              ),
              const Divider(height: 20),
              _buildLocationDetail(Icons.south_east, 'Pickup:', request.pickup.address, Colors.red.shade400),
              const SizedBox(height: 12),
              _buildLocationDetail(Icons.north_east, 'Dropoff:', request.dropoff.address, kPrimaryBlue),
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildDetailChip(Icons.unarchive, 'Type: ${request.type.toString().split('.').last.toUpperCase()}'),
                  _buildDetailChip(Icons.scale, 'Weight: ${request.weightKg.toStringAsFixed(1)} kg'),
                ],
              ),
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // --- CALLING THE SendOfferScreen HERE ---
                    _animationController.forward().then((_) => _animationController.reverse());
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SendOfferScreen(
                          request: request, // Pass the specific request data
                          driverProfile: widget.driverProfile, 
                            offerService: widget.offerService,
                        ),
                      ),
                    );
                    // ----------------------------------------
                  },
                  icon: const Icon(Icons.send_rounded, size: 20),
                  label: const Text('SEND OFFER', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 6,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationDetail(IconData icon, String title, String address, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black54),
              ),
              const SizedBox(height: 2),
              Text(
                address,
                style: const TextStyle(fontSize: 15, color: Colors.black87),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: kBackgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: kPrimaryBlue),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(fontSize: 12, color: Colors.black87),
          ),
        ],
      ),
    );
  }
}








class EarningsScreen extends StatelessWidget {
  const EarningsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Earnings')),
      body: const Center(child: Text('Detailed Earnings Report Screen (Index 2)')),
    );
  }
}

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('More Options')),
      body: const Center(child: Text('More/Settings Screen (Index 3)')),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: const Center(child: Text('Driver Profile Details (Index 4)')),
    );
  }
}



// Change LocationData to Location
class RouteMap extends StatefulWidget {
  final Location pickupLocation;
  final Location destinationLocation;

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
    // 💡 Call the new setup function
    _setupCoordinates(); 
  }

  // --- NEW: Directly use the coordinates ---
  void _setupCoordinates() {
    // 1. Get LatLng from the provided Location objects
    _pickupLatLng = LatLng(
      widget.pickupLocation.latitude,
      widget.pickupLocation.longitude,
    );
    _destinationLatLng = LatLng(
      widget.destinationLocation.latitude,
      widget.destinationLocation.longitude,
    );

    // 2. Proceed with map setup
    _setupMap();
  }

  // --- ORIGINAL _setupMap (Modified to use widget.address for InfoWindow) ---
  void _setupMap() {
    setState(() {
      _markers = {
        Marker(
          markerId: const MarkerId('pickup'),
          position: _pickupLatLng!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          // 💡 Use widget.pickupLocation.address for InfoWindow title
          infoWindow: InfoWindow(title: 'Pickup: ${widget.pickupLocation.address}'),
        ),
        Marker(
          markerId: const MarkerId('destination'),
          position: _destinationLatLng!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          // 💡 Use widget.destinationLocation.address for InfoWindow title
          infoWindow: InfoWindow(title: 'Destination: ${widget.destinationLocation.address}'),
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

   void _fitMapToMarkers() {
    if (_mapController != null && _pickupLatLng != null && _destinationLatLng != null) {
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
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: GoogleMap(
        onMapCreated: (controller) {
          _mapController = controller;
          _fitMapToMarkers();
        },
        initialCameraPosition: CameraPosition(
          target: _pickupLatLng ?? const LatLng(37.42796133580664, -122.085749655962),
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



  // The rest of the functions (_fitMapToMarkers and build) remain the same.

  // NOTE: The function _convertAddressesToCoordinates and _setupMapWithDefaults 
  // are no longer needed and should be removed.
}