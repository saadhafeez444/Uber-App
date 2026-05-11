import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


import 'package:uber_app/screens/user_module/user_module_firebase.dart';

class DriverOffersScreen extends StatefulWidget {
  final String deliveryRequestId;
  final DeliveryRequest deliveryRequest;

  const DriverOffersScreen({
    Key? key,
    required this.deliveryRequestId,
    required this.deliveryRequest,
  }) : super(key: key);

  @override
  State<DriverOffersScreen> createState() => _DriverOffersScreenState();
}

class _DriverOffersScreenState extends State<DriverOffersScreen> {
  List<DriverOffer> _offers = [];
  DriverOffer? _acceptedOffer;
  bool _isLoading = true;
  final FirebaseService _firebaseService = FirebaseService();

  @override
  void initState() {
    super.initState();
    _loadDriverOffers();
  }

  void _loadDriverOffers() {
    _firebaseService.listenForOffers(widget.deliveryRequestId).listen((snapshot) {
      if (mounted) {
        setState(() {
          _offers = snapshot.docs.map((doc) {
            return DriverOffer.fromMap(doc.id, doc.data());
          }).where((offer) => offer.status == 'pending').toList();
          _isLoading = false;
        });
      }
    }, onError: (error) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      print('Error loading offers: $error');
    });
  }

  void _onAcceptOffer(DriverOffer offer) async {
    try {
      await _firebaseService.acceptOffer(widget.deliveryRequestId, offer.id);
      
      setState(() {
        _acceptedOffer = offer;
      });

      // Show ride accepted bottom sheet
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => RideAcceptedScreen(
          offer: offer,
          onCancel: _onCancelRide,
          onContactDriver: _onContactDriver,
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

  void _onDeclineOffer(DriverOffer offer) async {
    try {
      await _firebaseService.declineOffer(widget.deliveryRequestId, offer.id);
      
      // Remove from local list for immediate UI update
      setState(() {
        _offers.remove(offer);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to decline offer: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _onCancelRide() async {
    if (_acceptedOffer != null) {
      try {
        // You might want to add a cancel method in FirebaseService
        await FirebaseFirestore.instance
            .collection('delivery_requests')
            .doc(widget.deliveryRequestId)
            .update({'status': 'cancelled'});
            
        setState(() {
          _acceptedOffer = null;
        });
      } catch (e) {
        print('Error cancelling ride: $e');
      }
    }
    Navigator.of(context).pop();
  }

  void _onContactDriver() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contact Driver'),
        content: Text('Call ${_acceptedOffer?.driverName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Implement phone call functionality
            },
            child: const Text('Call'),
          ),
        ],
      ),
    );
  }

  void _showRequestDetails() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildRequestDetailsSheet(),
    );
  }

  Widget _buildRequestDetailsSheet() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
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
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
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
                  // Route Details
                  _buildDetailSection(
                    title: "Route Details",
                    icon: Icons.route_rounded,
                    children: [
                      _buildDetailLocationRow(
                        icon: Icons.my_location_rounded,
                        color: Colors.blue,
                        title: "Pickup Location",
                        address: widget.deliveryRequest.pickup.title,
                        subtitle: widget.deliveryRequest.pickup.subtitle,
                      ),
                      const SizedBox(height: 16),
                      _buildDetailLocationRow(
                        icon: Icons.location_on_rounded,
                        color: Colors.red,
                        title: "Destination",
                        address: widget.deliveryRequest.destination.title,
                        subtitle: widget.deliveryRequest.destination.subtitle,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Delivery Information
                  _buildDetailSection(
                    title: "Delivery Information",
                    icon: Icons.info_rounded,
                    children: [
                      _buildDetailItem(
                        icon: Icons.local_shipping_rounded,
                        title: "Truck Type",
                        value: widget.deliveryRequest.truckType,
                      ),
                      _buildDetailItem(
                        icon: Icons.scale_rounded,
                        title: "Load Weight",
                        value: "${widget.deliveryRequest.loadWeight} tons",
                      ),
                      _buildDetailItem(
                        icon: Icons.attach_money_rounded,
                        title: "Offered Fare",
                        value: "Rs${widget.deliveryRequest.fare.toStringAsFixed(0)}",
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: const Color(0xFF67B546)),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF67B546),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailLocationRow({
    required IconData icon,
    required Color color,
    required String title,
    required String address,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                address,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Offers'),
        backgroundColor: const Color(0xFF67B546),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showRequestDetails,
            tooltip: 'Request Details',
          ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _buildContent(),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF67B546)),
          ),
          const SizedBox(height: 16),
          const Text(
            'Looking for driver offers...',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Text(
            'Request ID: ${widget.deliveryRequestId}',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Stack(
      children: [
        // Background
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.grey[50]!,
                Colors.grey[100]!,
              ],
            ),
          ),
        ),

        // Content
        Column(
          children: [
            // Request Info Card
            _buildRequestInfoCard(),
            const SizedBox(height: 16),

            // Offers Section
            Expanded(
              child: _offers.isEmpty
                  ? _buildEmptyState()
                  : _buildOffersList(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRequestInfoCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.local_shipping_rounded,
            color: const Color(0xFF67B546),
            size: 40,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Delivery Request',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${widget.deliveryRequest.pickup.title} → ${widget.deliveryRequest.destination.title}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Rs${widget.deliveryRequest.fare.toStringAsFixed(0)} • ${widget.deliveryRequest.truckType}',
                  style: const TextStyle(
                    color: Color(0xFF67B546),
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.local_offer_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          const Text(
            'No offers yet',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Driver offers will appear here as they become available. Please wait a moment.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _isLoading = true;
              });
              _loadDriverOffers();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF67B546),
            ),
            child: const Text('Refresh Offers', style: TextStyle(color: Colors.white),),
          ),
        ],
      ),
    );
  }

  Widget _buildOffersList() {
    return Column(
      children: [
        // Offers Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(
                Icons.local_offer_rounded,
                color: const Color(0xFF67B546),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '${_offers.length} Driver Offer${_offers.length != 1 ? 's' : ''}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Offers List
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: _offers.map((offer) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: AnimatedDriverOfferNotification(
                  offer: offer,
                  onAccept: () => _onAcceptOffer(offer),
                  onDecline: () => _onDeclineOffer(offer),
                  displayDuration: const Duration(seconds: 30),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}