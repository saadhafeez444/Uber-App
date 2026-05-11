import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class NearbyRequestsScreen extends StatefulWidget {
  final Location currentLocation;
  final double searchRadius;
  final DriverProfile driverProfile;

  const NearbyRequestsScreen({
    super.key,
    required this.currentLocation,
    required this.searchRadius,
    required this.driverProfile,
  });

  @override
  State<NearbyRequestsScreen> createState() => _NearbyRequestsScreenState();
}

class _NearbyRequestsScreenState extends State<NearbyRequestsScreen> 
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<DeliveryRequest> _allRequests = [];
  List<DeliveryRequest> _filteredRequests = [];
  
  bool _isLoading = true;
  bool _isFilterPanelExpanded = false;
  
  late FilterOptions _currentFilters;
  String _searchQuery = '';
  
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  StreamSubscription<QuerySnapshot>? _requestsSubscription;

  @override
  void initState() {
    super.initState();
    _currentFilters = FilterOptions(
      radiusKm: widget.searchRadius,
      weightRangeKg: const RangeValues(0, 10000),
    );
    _fetchRealTimeRequests();

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
    _requestsSubscription?.cancel();
    super.dispose();
  }

  // UPDATED: Fetch real-time requests from Firebase
  void _fetchRealTimeRequests() {
    setState(() {
      _isLoading = true;
    });

    _requestsSubscription = _firestore
        .collection('delivery_requests')
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((QuerySnapshot snapshot) {
      final requests = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return DeliveryRequest.fromMap(doc.id, data);
      }).toList();

      if (mounted) {
        setState(() {
          _allRequests = requests;
          _isLoading = false;
          _applyFilters();
        });
      }
    }, onError: (error) {
      print('Error fetching requests: $error');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  Future<void> _handleRefresh() async {
    // For real-time updates, we don't need manual refresh
    // but we can trigger a re-filter
    setState(() {
      _applyFilters();
    });
  }

  void _applyFilters() {
    setState(() {
      _filteredRequests = _allRequests.where((request) {
        // Search filter
        final matchesSearch = _searchQuery.isEmpty ||
            request.pickup.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            request.destination.title.toLowerCase().contains(_searchQuery.toLowerCase());
        
        // Weight filter
        final matchesWeight = request.loadWeight >= _currentFilters.weightRangeKg.start &&
            request.loadWeight <= _currentFilters.weightRangeKg.end;
        
        // Truck type filter
        final matchesType = _currentFilters.selectedType == null ||
            request.truckType.toLowerCase().contains(_currentFilters.selectedType!.toLowerCase());

        return matchesSearch && matchesWeight && matchesType;
      }).toList();
    });
  }
  
  void _resetFilters() {
    setState(() {
      _currentFilters = FilterOptions(
        radiusKm: 20.0,
        weightRangeKg: const RangeValues(0, 10000),
        selectedType: null,
      );
      _searchController.clear();
      _applyFilters();
    });
  }

  void _toggleFilterPanel() {
    setState(() {
      _isFilterPanelExpanded = !_isFilterPanelExpanded;
    });
  }

  // UPDATED: Submit offer to Firebase
  Future<void> _submitOffer(DeliveryRequest request, double offerAmount) async {
    try {
      final driverId = _auth.currentUser?.uid ?? widget.driverProfile.id;
      
      final offerData = {
        'driverId': driverId,
        'driverName': widget.driverProfile.name,
        'fare': offerAmount,
        'distance': _calculateDistance(request),
        'truckType': widget.driverProfile.vehicleType,
        'vehicleNumber': widget.driverProfile.vehicleNumber,
        'rating': widget.driverProfile.rating,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection('delivery_requests')
          .doc(request.id)
          .collection('offers')
          .add(offerData);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Offer submitted for Rs${offerAmount.toStringAsFixed(0)}'),
          backgroundColor: Colors.green,
        ),
      );

    } catch (e) {
      print('Error submitting offer: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit offer: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  double _calculateDistance(DeliveryRequest request) {
    // Simple distance calculation (you can use more accurate methods)
    final latDiff = request.pickup.coordinates.latitude - widget.currentLocation.latitude;
    final lngDiff = request.pickup.coordinates.longitude - widget.currentLocation.longitude;
    return (latDiff * latDiff + lngDiff * lngDiff).abs() * 100; // Approximate km
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Nearby Delivery Requests', 
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 2,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          _buildSearchBarAndFilter(),
          _buildStatsHeader(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _handleRefresh,
              color: const Color(0xFF67B546),
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF67B546)),
                      ),
                    )
                  : _filteredRequests.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.local_shipping, size: 60, color: Colors.grey.shade400),
                              const SizedBox(height: 16),
                              Text(
                                'No delivery requests found',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Try adjusting your filters or check back later',
                                style: TextStyle(color: Colors.grey.shade500),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton(
                                onPressed: _resetFilters,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF67B546),
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Reset Filters'),
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

  Widget _buildStatsHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.grey.shade50,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${_filteredRequests.length} requests found',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          Text(
            'Radius: ${_currentFilters.radiusKm.toStringAsFixed(0)}km',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
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
                    hintText: 'Search by location...',
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF67B546)),
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
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              InkWell(
                onTap: _toggleFilterPanel,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _isFilterPanelExpanded ? const Color(0xFF67B546) : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300)
                  ),
                  child: Icon(
                    Icons.filter_list,
                    color: _isFilterPanelExpanded ? Colors.white : const Color(0xFF67B546),
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

  Widget _buildFilterPanel() {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Search Radius: ${_currentFilters.radiusKm.toStringAsFixed(0)} km',
            style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
          ),
          Slider(
            value: _currentFilters.radiusKm,
            min: 5,
            max: 100,
            divisions: 19,
            activeColor: const Color(0xFF67B546),
            inactiveColor: const Color(0xFF67B546).withOpacity(0.3),
            label: '${_currentFilters.radiusKm.toStringAsFixed(0)} km',
            onChanged: (double value) {
              setState(() {
                _currentFilters.radiusKm = value;
                _applyFilters();
              });
            },
          ),
          const SizedBox(height: 16),
          Text(
            'Weight Range: ${_currentFilters.weightRangeKg.start.toStringAsFixed(0)} kg - '
            '${_currentFilters.weightRangeKg.end.toStringAsFixed(0)} kg',
            style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
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
            activeColor: const Color(0xFF67B546),
            inactiveColor: const Color(0xFF67B546).withOpacity(0.3),
            onChanged: (RangeValues values) {
              setState(() {
                _currentFilters.weightRangeKg = values;
                _applyFilters();
              });
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: 'Truck Type',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            value: _currentFilters.selectedType,
            hint: const Text('All Types'),
            items: const [
              DropdownMenuItem(value: 'Small Truck', child: Text('Small Truck')),
              DropdownMenuItem(value: 'Medium Truck', child: Text('Medium Truck')),
              DropdownMenuItem(value: 'Heavy Truck', child: Text('Heavy Truck')),
              DropdownMenuItem(value: 'Courier', child: Text('Courier')),
            ],
            onChanged: (String? newValue) {
              setState(() {
                _currentFilters.selectedType = newValue;
                _applyFilters();
              });
            },
            isExpanded: true,
          ),
          const SizedBox(height: 16),
          Center(
            child: ElevatedButton(
              onPressed: _resetFilters,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey.shade300,
                foregroundColor: Colors.black87,
              ),
              child: const Text('Reset All Filters'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestCard(DeliveryRequest request) {
    final distance = _calculateDistance(request);
    
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Card(
        color: Colors.white,
        margin: const EdgeInsets.only(bottom: 16),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with price and distance
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF67B546).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Rs${request.fare.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF67B546),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.grey, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '${distance.toStringAsFixed(1)} km away',
                        style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Pickup Location
              _buildLocationDetail(
                Icons.arrow_circle_up, 
                'Pickup:', 
                request.pickup.title, 
                Colors.green
              ),
              
              const SizedBox(height: 12),
              
              // Destination Location
              _buildLocationDetail(
                Icons.arrow_circle_down, 
                'Destination:', 
                request.destination.title, 
                Colors.red
              ),
              
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),
              
              // Details row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildDetailChip(Icons.local_shipping, 'Type: ${request.truckType}'),
                  _buildDetailChip(Icons.scale, 'Weight: ${request.loadWeight.toStringAsFixed(1)} tons'),
                ],
              ),
              
              if (request.deliveryNotes != null && request.deliveryNotes!.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildDetailChip(Icons.note, 'Notes: ${request.deliveryNotes!}'),
              ],
              
              const SizedBox(height: 20),
              
              // Action Button
              Center(
                child: ElevatedButton.icon(
                  onPressed: () {
                    _animationController.forward().then((_) => _animationController.reverse());
                    _showOfferDialog(request);
                  },
                  icon: const Icon(Icons.send_rounded, size: 20),
                  label: const Text('SEND OFFER', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF67B546),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showOfferDialog(DeliveryRequest request) {
    double offerAmount = request.fare;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text(
              'Submit Offer',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Offer for ${request.pickup.title} to ${request.destination.title}',
                  style: TextStyle(color: Colors.grey.shade600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Rs${offerAmount.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF67B546),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle, color: Colors.red),
                            onPressed: () {
                              setState(() {
                                offerAmount = (offerAmount - 100).clamp(50, double.infinity);
                              });
                            },
                          ),
                          const SizedBox(width: 20),
                          IconButton(
                            icon: const Icon(Icons.add_circle, color: Color(0xFF67B546)),
                            onPressed: () {
                              setState(() {
                                offerAmount = offerAmount + 100;
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('CANCEL', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _submitOffer(request, offerAmount);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF67B546),
                  foregroundColor: Colors.white,
                ),
                child: const Text('SUBMIT OFFER'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLocationDetail(IconData icon, String title, String address, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black54),
              ),
              const SizedBox(height: 4),
              Text(
                address,
                style: const TextStyle(fontSize: 16, color: Colors.black87),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF67B546)),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(fontSize: 12, color: Colors.black87),
          ),
        ],
      ),
    );
  }
}



// Supporting Classes
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

class LocationData {
  final String title;
  final String subtitle;
  final LatLng coordinates;

  LocationData(this.title, this.subtitle, {required this.coordinates});
}

class Location {
  final double latitude;
  final double longitude;
  final String address;

  const Location({
    required this.latitude,
    required this.longitude,
    required this.address,
  });
}

class DriverProfile {
  final String id;
  final String name;
  final String vehicleType;
  final String vehicleNumber;
  final double rating;

  const DriverProfile({
    required this.id,
    required this.name,
    required this.vehicleType,
    required this.vehicleNumber,
    required this.rating,
  });
}

class FilterOptions {
  double radiusKm;
  RangeValues weightRangeKg;
  String? selectedType;

  FilterOptions({
    required this.radiusKm,
    required this.weightRangeKg,
    this.selectedType,
  });
}