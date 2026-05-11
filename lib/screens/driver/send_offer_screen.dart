import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uber_app/models/offer_status.dart'; 
import 'dart:async';
import 'dart:math';

import 'package:uber_app/screens/driver/driver_module.dart';

const Color kPrimaryBlue = Color(0xFF2563EB); 
const Color kSecondaryGreen = Color(0xFF10B981); 
const Color kBackgroundColor = Color(0xFFF8F9FA);




class OfferD {
  final String id;
  final String driverId;
  final ShipmentRequest shipment; 
  final double offeredPrice;
  final String estimatedTime;
  final String? driverMessage;
  final DateTime submissionTime;
  OfferStatus status; 

  OfferD({
    required this.id,
    required this.driverId,
    required this.shipment,
    required this.offeredPrice,
    required this.estimatedTime,
    this.driverMessage,
    required this.submissionTime,
    this.status = OfferStatus.pending,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'driverId': driverId,
      'shipmentId': shipment.id,
      'offeredPrice': offeredPrice,
      'estimatedTime': estimatedTime,
      'driverMessage': driverMessage,
      'submissionTime': submissionTime.toIso8601String(),
      'status': status.name,
    };
  }
}


class MockOfferService {
  final String driverId;
  late List<OfferD> _offers;

  final StreamController<List<OfferD>> _offersStreamController =
      StreamController<List<OfferD>>.broadcast();

  Stream<List<OfferD>> get offersStream => _offersStreamController.stream;

  MockOfferService({required this.driverId}) {

    final shipmentService = MockShipmentService();
    _offers = [
      OfferD(
        id: 'O-001',
        driverId: driverId,
        shipment: shipmentService.mockRequestsData[0],
        offeredPrice: 160.00,
        estimatedTime: '3 hours',
        submissionTime: DateTime.now().subtract(const Duration(hours: 5)),
        status: OfferStatus.pending,
      ),
      OfferD(
        id: 'O-002',
        driverId: driverId,
        shipment: shipmentService.mockRequestsData[1],
        offeredPrice: 400.00,
        estimatedTime: '6 hours',
        submissionTime: DateTime.now().subtract(const Duration(days: 1)),
        status: OfferStatus.accepted,
      ),
      OfferD(
        id: 'O-003',
        driverId: driverId,
        shipment: shipmentService.mockRequestsData[2],
        offeredPrice: 100.00,
        estimatedTime: '2 hours',
        submissionTime: DateTime.now().subtract(const Duration(hours: 10)),
        status: OfferStatus.pending,
      ),
      OfferD(
        id: 'O-004',
        driverId: driverId,
        shipment: shipmentService.mockRequestsData[3],
        offeredPrice: 1100.00,
        estimatedTime: '1 day',
        submissionTime: DateTime.now().subtract(const Duration(days: 3)),
        status: OfferStatus.rejected,
      ),
    ];

    _offersStreamController.add(_offers);
  }

  void addOffer(OfferD newOffer) {
    _offers.add(newOffer);
    _offersStreamController.add(_offers);
  }

  Future<void> refreshOffers() async {
    await Future.delayed(const Duration(milliseconds: 1000));
    
    try {
      final pendingToAccept = _offers.firstWhere(
        (o) => o.status == OfferStatus.pending,
      );
      pendingToAccept.status = OfferStatus.accepted;
      print('Mock: Offer ${pendingToAccept.id} status changed to ACCEPTED.');
    } catch (_) {}

    _offersStreamController.add(_offers);
  }

 
  Future<bool> cancelOffer(String offerId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final offerIndex = _offers.indexWhere((o) => o.id == offerId);
    if (offerIndex != -1 && _offers[offerIndex].status == OfferStatus.pending) {
      _offers[offerIndex].status = OfferStatus.cancelled;
      _offersStreamController.add(_offers);

      return true;
    }
    return false;
  }

  void dispose() {
    _offersStreamController.close();
  }
}



class OfferStatusScreen extends StatefulWidget {
  final String driverId;
   final MockOfferService offerService;
    

  const OfferStatusScreen({super.key, required this.driverId,    required this.offerService,});

  @override
  State<OfferStatusScreen> createState() => _OfferStatusScreenState();
}

class _OfferStatusScreenState extends State<OfferStatusScreen>
    with SingleTickerProviderStateMixin {
  late final MockOfferService _offerService;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _offerService = widget.offerService;
    _tabController = TabController(length: 3, vsync: this);
    // _offerService = MockOfferService(driverId: widget.driverId);
    // _tabController = TabController(length: 3, vsync: this);
  }
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'My Offers',
        
          style: TextStyle(fontWeight: FontWeight.bold, 
          color: Colors.white
          ),
        ),
        backgroundColor: kPrimaryBlue,
        foregroundColor: Colors.white,
        elevation: 4,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorSize: TabBarIndicatorSize.tab,
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Accepted'),
            Tab(
              text: 'History',
            ), 
          ],
        ),
      ),
     body: StreamBuilder<List<OfferD>>(
  stream: _offerService.offersStream,
  builder: (context, snapshot) {
   
    if (snapshot.hasError) {
      return Center(child: Text('Error: ${snapshot.error}'));
    }

    final allOffers = snapshot.data ?? [];
    final pendingOffers = allOffers
        .where((o) => o.status == OfferStatus.pending)
        .toList();
    final acceptedOffers = allOffers
        .where((o) => o.status == OfferStatus.accepted)
        .toList();
    final historyOffers = allOffers
        .where((o) => o.status == OfferStatus.rejected || 
                      o.status == OfferStatus.cancelled)
        .toList();

    return TabBarView(
      controller: _tabController, // Add this line
      children: [
        _buildOfferList(context, pendingOffers, OfferStatus.pending),
        _buildOfferList(context, acceptedOffers, OfferStatus.accepted),
        _buildOfferList(context, historyOffers, OfferStatus.rejected),
      ],
    );
  },
),
    );
  }

  Widget _buildOfferList(
    BuildContext context,
    List<OfferD> offers,
     
    OfferStatus statusType,
  ) {
    return RefreshIndicator(
      onRefresh: _offerService.refreshOffers,
      color: kPrimaryBlue,
      child: offers.isEmpty
          ? _buildEmptyState(statusType)
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: offers.length,
              itemBuilder: (context, index) {
                return _buildOfferCard(context, offers[index]);
              },
            ),
    );
  }

  Widget _buildEmptyState(OfferStatus statusType) {
    IconData icon;
    String message;
    switch (statusType) {
      case OfferStatus.pending:
        icon = Icons.watch_later_outlined;
        message = "No offers are currently pending review.";
        break;
      case OfferStatus.accepted:
        icon = Icons.check_circle_outline;
        message = "Congratulations! No active accepted offers found.";
        break;
      case OfferStatus.rejected:
      case OfferStatus.cancelled:
      default:
        icon = Icons.history_toggle_off_rounded;
        message = "Your offer history is empty.";
        break;
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 80.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 80, color: Colors.grey.shade400),
              const SizedBox(height: 20),
              Text(
                message,
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              TextButton.icon(
                onPressed: () {
                  // Navigate to Requests screen (Index 1)
                  if (Navigator.of(context).canPop())
                    Navigator.of(context).pop();
                 
                  print("Navigate to Requests screen (Index 1)");
                },
                icon: const Icon(Icons.send_rounded),
                label: const Text('Send New Offer'),
                style: TextButton.styleFrom(foregroundColor: kPrimaryBlue),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOfferCard(BuildContext context, OfferD offer) {
    Color statusColor;
    String statusText;
    switch (offer.status) {
      case OfferStatus.pending:
        statusColor = Colors.amber.shade700;
        statusText = 'Pending Review';
        break;
      case OfferStatus.accepted:
        statusColor = kSecondaryGreen;
        statusText = 'Accepted';
        break;
      case OfferStatus.rejected:
        statusColor = Colors.red.shade700;
        statusText = 'Rejected';
        break;
      case OfferStatus.cancelled:
        statusColor = Colors.grey.shade600;
        statusText = 'Cancelled by Driver';
        break;
    }

    // Determine the transition based on status
    final beginColor = Colors.white;
    final endColor = offer.status == OfferStatus.pending
        ? Colors.white
        : (offer.status == OfferStatus.accepted
              ? kSecondaryGreen.withOpacity(0.05)
              : Colors.red.withOpacity(0.05));

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: statusColor.withOpacity(0.5), width: 1.5),
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        decoration: BoxDecoration(
          color: endColor,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Offered Price
                Text(
                  '\$${offer.offeredPrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: kPrimaryBlue,
                  ),
                ),
                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 15, color: Colors.black12),
            
            _buildDetailRow(
              Icons.pin_drop_outlined,
              'Pickup:',
              offer.shipment.pickup.address.split(',').first,
            ),
            _buildDetailRow(
              Icons.flag_outlined,
              'Dropoff:',
              offer.shipment.dropoff.address.split(',').first,
            ),
            const SizedBox(height: 8),
            _buildDetailRow(
              Icons.timer_outlined,
              'Est. Time:',
              offer.estimatedTime,
            ),
            _buildDetailRow(
              Icons.calendar_month,
              'Submitted:',
              _formatDate(offer.submissionTime),
            ),
            if (offer.status == OfferStatus.pending)
              Padding(
                padding: const EdgeInsets.only(top: 10.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => _showCancelDialog(context, offer),
                      child: Text(
                        'Cancel Offer',
                        style: TextStyle(
                          color: Colors.red.shade600,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                    
                        print('Viewing details for offer ${offer.id}');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimaryBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('View Details'),
                    ),
                  ],
                ),
              ),
            if (offer.status == OfferStatus.accepted)
              Padding(
                padding: const EdgeInsets.only(top: 10.0),
                child: Center(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Action: Navigate to Active Shipment/Job Tracking
                      print('Starting job ${offer.shipment.id}');
                    },
                    icon: const Icon(Icons.directions_run),
                    label: const Text('START SHIPMENT'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kSecondaryGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black54,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(value, style: const TextStyle(color: Colors.black87)),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month} ${_formatTime(date)}';
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _showCancelDialog(BuildContext context, OfferD offer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirm Cancellation'),
        content: Text(
          'Are you sure you want to cancel your pending offer of \$${offer.offeredPrice.toStringAsFixed(2)} for shipment ${offer.shipment.id}?',
        ),

        actions: [
         
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(

              'No, Keep Offer',
              style: TextStyle(color: kPrimaryBlue, ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _cancelOffer(offer.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
            ),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }

  void _cancelOffer(String offerId) async {
    final success = await _offerService.cancelOffer(offerId);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Offer successfully cancelled.'),

          backgroundColor: kSecondaryGreen,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to cancel offer $offerId.'),
          backgroundColor: Colors.red,

        ),
      );
    }
    
  }
}
