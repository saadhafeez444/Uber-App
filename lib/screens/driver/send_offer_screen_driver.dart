
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:uber_app/models/offer_status.dart';
import 'package:uber_app/screens/driver/driver_module.dart' hide kPrimaryBlue;
import 'package:uber_app/screens/driver/send_offer_screen.dart' hide kSecondaryGreen, kBackgroundColor;

class AppNotification {
  final String recipientId; 
  final String senderId; 
  final String message;
  final String type; 
  final DateTime timestamp;

  AppNotification({
    required this.recipientId,
    required this.senderId,
    required this.message,
    required this.type,
    required this.timestamp,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'recipientId': recipientId,
      'senderId': senderId,
      'message': message,
      'type': type,
      'timestamp': timestamp.toIso8601String(),
      'isRead': false,
    };
  }
}

class SendOfferScreen extends StatefulWidget {
  final ShipmentRequest request;
  final DriverProfile driverProfile;
  final MockOfferService offerService; 

  const SendOfferScreen({
    super.key,
    required this.request,
    required this.driverProfile,
        required this.offerService,
  });

  @override
  State<SendOfferScreen> createState() => _SendOfferScreenState();
}

class _SendOfferScreenState extends State<SendOfferScreen> {
 final _formKey = GlobalKey<FormState>();
  final shipmentService = MockShipmentService();
  double? _offeredPrice;
  String _estimatedTime = '4 hours';
  String _message = '';
  bool _termsConfirmed = false;
  bool _isLoading = false;

  final List<String> _timeOptions = [
    '2 hours', '3 hours', '4 hours', '6 hours', '8 hours', '1 day',
  ];

  Future<void> _submitOffer() async {
    if (!_formKey.currentState!.validate() || !_termsConfirmed) {
      if (!_termsConfirmed) {
        _showErrorDialog('Terms and Conditions must be accepted.');
      }
      return;
    }

    _formKey.currentState!.save();

    setState(() { _isLoading = true; });

    try {
      await Future.delayed(const Duration(seconds: 2));

      // Create the new offer
      final newOffer = OfferD(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        driverId: widget.driverProfile.id,
        offeredPrice: _offeredPrice!,
        estimatedTime: _estimatedTime,
        shipment: widget.request, // Use the actual request from the screen
        submissionTime: DateTime.now(),
        status: OfferStatus.pending,
        driverMessage: _message.isNotEmpty ? _message : null,
      );

      // ADD THE OFFER TO THE SERVICE
      widget.offerService.addOffer(newOffer);

      print('OFFER ADDED: ${newOffer.toFirestore()}');

      // Create notification (mock)
      final newNotification = AppNotification(
        recipientId: widget.request.ownerId,
        senderId: widget.driverProfile.id,
        message: '${widget.driverProfile.name} has sent an offer of \$${newOffer.offeredPrice.toStringAsFixed(2)} for shipment ${widget.request.id}.',
        type: 'new_offer',
        timestamp: DateTime.now(),
      );
      print('MOCK NOTIFICATION: ${newNotification.toFirestore()}');

      _showSuccessDialog();

    } catch (e) {
      _showErrorDialog('Failed to send offer. Error: $e');
    } finally {
      setState(() { _isLoading = false; });
    }
  }
  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Offer Sent!', style: TextStyle(color: kSecondaryGreen)),
        content: const Text('Your offer has been successfully submitted to the shipment owner.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Go back to the requests screen
            },
            child: Text('OK', style: TextStyle(color: kPrimaryBlue)),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Submission Failed', style: TextStyle(color: Colors.red)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        leading: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Icon(Icons.arrow_back, color: Colors.white,
          ),
        ),
        title: const Text('Send Offer', style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold)),
        backgroundColor: kPrimaryBlue,
        foregroundColor: Colors.white,
        
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildShipmentDetailsCard(widget.request),
              const SizedBox(height: 20),
              _buildDriverInfo(widget.driverProfile),
              const SizedBox(height: 30),
              const Text('Your Offer Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
              const Divider(),
              _buildPriceInput(),
              const SizedBox(height: 20),
              _buildEstimatedTimePicker(),
              const SizedBox(height: 20),
              _buildMessageField(),
              const SizedBox(height: 30),
              _buildTermsCheckbox(),
              const SizedBox(height: 20),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }
Widget _buildShipmentDetailsCard(ShipmentRequest request) {
 
  final String formattedPickupDate = 
      DateFormat('dd-MMM-yyyy').format(request.requestedPickupDateTime);
  final String formattedPickupTime = 
      DateFormat('hh:mm a').format(request.requestedPickupDateTime);


  return Card(
    color: Colors.white,
    elevation: 6,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    child: Padding(
      padding: const EdgeInsets.all(18.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Shipment Details',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: kPrimaryBlue)),
          const Divider(height: 15),

 
          _buildDetailRow(Icons.calendar_month
          , 'Pickup Date:', formattedPickupDate),
          _buildDetailRow(Icons.access_time, 'Pickup Time:', formattedPickupTime),
          const Divider(height: 15),
     

          _buildDetailRow(Icons.pin_drop, 'Pickup:', request.pickup.address),
          _buildDetailRow(Icons.flag, 'Dropoff:', request.dropoff.address),
          const Divider(height: 15),
          _buildDetailRow(
              Icons.scale, 'Weight:', '${request.weightKg.toStringAsFixed(1)} kg'),
          _buildDetailRow(Icons.square_foot, 'Dimensions:', request.dimensions),
          _buildDetailRow(
              Icons.security, 'Requirements:', request.specialRequirements),
          _buildDetailRow(Icons.type_specimen, 'Type:',
              request.type.toString().split('.').last.toUpperCase()),
          _buildImageRow(request),
        ],
      ),
    ),
  );
}
// Helper function to build a single Expanded image widget
Widget _buildSingleImageWidget(String imageUrl, {bool isAsset = false}) {
  final imageWidget = isAsset
      ? Image.asset(
          imageUrl,
          height: 80,
          fit: BoxFit.fill,
        )
      : Image.asset(
          imageUrl,
          height: 80,
          fit: BoxFit.fill, // Use BoxFit.cover for network images
          errorBuilder: (context, error, stackTrace) => Container(
            // Fallback for failed network load
            height: 80,
            color: Colors.grey[300],
            child: const Center(child: Icon(Icons.broken_image)),
          ),
        );

  return Expanded(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8.0),
        child: imageWidget,
      ),
    ),
  );
}

// Helper widget for building the asset placeholders (used when no images are provided)
Widget _buildAssetImage(String assetPath) {
  return _buildSingleImageWidget(assetPath, isAsset: true);
}


Widget _buildImageRow(ShipmentRequest request) {
  final List<String> images = request.images ?? [];
  final bool hasImages = images.isNotEmpty;

  // List to hold all the image rows (Row widgets)
  final List<Widget> imageRows = [];
  
  if (hasImages) {
    // 1. Logic for service images (chunks of 3)
    
    // Calculate the number of full rows needed
    int numRows = (images.length / 3).ceil();
    
    for (int i = 0; i < numRows; i++) {
      // Define the start and end index for the current row's slice
      final int startIndex = i * 3;
      final int endIndex = (i + 1) * 3;
      
      // Get the subset of images for the current row
      final List<String> currentRowImages = images.sublist(
        startIndex,
        endIndex > images.length ? images.length : endIndex,
      );

      // Convert image URLs to Expanded widgets
      List<Widget> rowChildren = currentRowImages
          .map((imageUrl) => _buildSingleImageWidget(imageUrl))
          .toList();

      // Pad the row with empty Expanded widgets if less than 3 images
      while (rowChildren.length < 3) {
        rowChildren.add(const Expanded(child: SizedBox.shrink()));
      }

      // Add the complete Row to the list of imageRows
      imageRows.add(
        Padding(
          padding: const EdgeInsets.only(top: 8.0), // Add spacing between rows
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: rowChildren,
          ),
        ),
      );
    }
  } else {
    // 2. Logic for static placeholder images (when no images are provided)
    imageRows.add(
      Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildAssetImage('assets/images/img1.jpg'),
            _buildAssetImage('assets/images/img2.jpg'),
            _buildAssetImage('assets/images/img3.jpg'),
          ],
        ),
      ),
    );
  }

  // Return a Column containing all the generated rows
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: imageRows,
    ),
  );
}

// Widget _buildAssetImage(String assetPath) {
//   return Expanded(
//     child: Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 4.0),
//       child: ClipRRect(
//         borderRadius: BorderRadius.circular(8.0),
//         child: Image.asset(
//           assetPath,
//           height: 80,
//           fit: BoxFit.fill,
//         ),
//       ),
//     ),
//   );
// }
 
 
 
  Widget _buildDetailRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
          const SizedBox(width: 4),
          Expanded(child: Text(value, style: const TextStyle(color: Colors.black87))),
        ],
      ),
    );
  }



  Widget _buildDriverInfo(DriverProfile profile) {
    return Card(
      elevation: 4,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Row(
          children: [
            Icon(Icons.person, size: 24, color: kSecondaryGreen),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your Details:',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                Text('Rating: ${profile.rating} ⭐ | ${profile.vehicleType} (${profile.licensePlate})',
                    style: const TextStyle(color: Colors.black54)),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildPriceInput() {
    return TextFormField(
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: _inputDecoration(
        labelText: 'Your Offered Price',
        hintText: 'e.g., 900.00',
        icon: Icons.attach_money,
      ),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
      ],
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your price.';
        }
        final price = double.tryParse(value);
        if (price == null || price <= 0) {
          return 'Price must be a valid positive number.';
        }
        return null;
      },
      onSaved: (value) {
        _offeredPrice = double.tryParse(value ?? '0');
      },
    );
  }

  Widget _buildEstimatedTimePicker() {
    return DropdownButtonFormField<String>(
      decoration: _inputDecoration(
        labelText: 'Estimated Delivery Time',
        icon: Icons.timer,
      ),
      value: _estimatedTime,
      items: _timeOptions.map((String time) {
        return DropdownMenuItem<String>(
          value: time,
          child: Text(time),
        );
      }).toList(),
      onChanged: (String? newValue) {
        if (newValue != null) {
          setState(() {
            _estimatedTime = newValue;
          });
        }
      },
    );
  }

  Widget _buildMessageField() {
    return TextFormField(
      maxLines: 4,
      maxLength: 200,
      decoration: _inputDecoration(
        labelText: 'Message (Optional)',
        hintText: 'Any specific notes for the shipper?',
        icon: Icons.message,
      ),
      onSaved: (value) {
        _message = value ?? '';
      },
    );
  }

  Widget _buildTermsCheckbox() {
    return CheckboxListTile(
      title: const Text(
        'I confirm I agree to the service Terms and Conditions.',
        style: TextStyle(fontSize: 14),
      ),
      value: _termsConfirmed,
      onChanged: (bool? newValue) {
        setState(() {
          _termsConfirmed = newValue ?? false;
        });
      },
      controlAffinity: ListTileControlAffinity.leading,
      dense: true,
      contentPadding: EdgeInsets.zero,
      activeColor: kPrimaryBlue,
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _submitOffer,
        icon: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            : const Icon(Icons.send_rounded, size: 20),
        label: Text(_isLoading ? 'Submitting...' : 'SUBMIT OFFER', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        style: ElevatedButton.styleFrom(
          backgroundColor: kPrimaryBlue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 8,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({required String labelText, String? hintText, required IconData icon}) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      prefixIcon: Icon(icon, color: kPrimaryBlue),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: kPrimaryBlue, width: 2),
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      errorStyle: const TextStyle(color: Colors.red),
    );
  }
}


