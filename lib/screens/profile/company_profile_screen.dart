import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:uber_app/models/profile_model.dart';
import 'package:uber_app/screens/profile/create_user_profile_screen.dart';
import 'package:uber_app/screens/profile/view_company_profile_screen.dart';
import 'package:uber_app/utils/app_colors.dart';
import 'package:uber_app/widgets/ProfileBackgroundPaineter.dart';
import 'package:uber_app/widgets/profile_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';


class CompanyProfileScreen extends StatefulWidget {
  final String userId;
  final String role;

  const CompanyProfileScreen({super.key, required this.userId, required this.role});

  

  @override
  _CompanyProfileScreenState createState() => _CompanyProfileScreenState();
}

class _CompanyProfileScreenState extends State<CompanyProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _companyEmailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _regNumController = TextEditingController();
  final TextEditingController _employeesController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();

  String? _selectedTruckCountRange;
  List<Truck> _trucks = [];
  File? _companyLogoImage;
  String? _companyLogoURL;
  List<Certificate> _certificates = [];

  final List<String> _truckCountRanges = [
    '1 - 6 Trucks',
    '7 - 13 Trucks',
    '14 - 21 Trucks',
    'More than 21 Trucks',
  ];

  DateTime? _selectedDate;

  String? _currentUserId;
  bool _isLoading = true;
  bool _isDataLoaded = false; 

  @override
  void initState() {
    super.initState();
    _getCurrentUserAndLoadData();
  }

  Future<void> _getCurrentUserAndLoadData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _currentUserId = user.uid;
      });
      await _loadCompanyProfile();
    } else {
   
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User not found. Cannot load profile.')),
      );
    }
  }

  Future<void> _loadCompanyProfile() async {
    if (_currentUserId == null || _isDataLoaded) return;

    try {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('userProfiles')
          .doc(_currentUserId)
          .get();

      if (docSnapshot.exists && docSnapshot.data()?['userType'] == UserType.company.name) {
        final data = docSnapshot.data()!;
        final companyInfoData = data['companyInfo'] as Map<String, dynamic>?;

        if (companyInfoData != null) {
          setState(() {
            _companyNameController.text = companyInfoData['companyName'] ?? '';
            _companyEmailController.text = companyInfoData['companyEmail'] ?? '';
            _phoneController.text = companyInfoData['companyPhoneNumber'] ?? '';
            _regNumController.text = companyInfoData['registrationNumber'] ?? '';
            _employeesController.text = (companyInfoData['numberOfEmployees'] ?? 0).toString();
            _bioController.text = companyInfoData['companyDescription'] ?? '';
            _fullNameController.text = data['fullName'] ?? ''; // Assuming fullName from UserProfile
            _companyLogoURL = companyInfoData['tradeMarkImageURL'];

            if (companyInfoData['dateOfEstablishment'] != null) {
              // Firestore Timestamps need conversion
              final timestamp = companyInfoData['dateOfEstablishment'];
              _selectedDate = (timestamp as Timestamp).toDate();
            }

            // Trucks Loading (Simplistic - assumes Truck is a simple map)
            final List<dynamic> trucksList = companyInfoData['trucks'] ?? [];
            _trucks = trucksList.map((map) => Truck(
              make: map['make'] ?? 'N/A',
              vin: map['vin'] ?? 'N/A',
              model: map['model'] ?? 'N/A',
              licensePlate: map['licensePlate'] ?? 'N/A',
              capacityTons: (map['capacityTons'] ?? 0.0).toDouble(),
              truckType: map['truckType'] ?? 'General',
                 truckId: map['truckId'] ?? 'N/A',
                 axles:  (map['axles'] ?? 0).toInt(),
            )).toList();
            
            // Certificates Loading (Simplistic - assumes Certificate is a simple map)
            final List<dynamic> certsList = companyInfoData['certificates'] ?? [];
            _certificates = certsList.map((map) => Certificate(
              id: map['id'] ?? 'Unknown Cert', 
             
              filePath:map['filePath'] ?? 'Unknown File',
              name: map['name'] ?? 'Unknown Cert',
              organization: map['organization'] ?? 'N/A',
              issueDate: (map['issueDate'] as Timestamp).toDate(),
               expiryDate:  (map['expiryDate'] as Timestamp).toDate(),
              isPdf: map['isPdf'] ?? false,
            )).toList();

            _isDataLoaded = true;
          });
        }
      }
    } catch (e) {
      print('Error loading profile: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load profile data: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<String?> _uploadLogoImage(File imageFile) async {
    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('company_logos')
          .child('$_currentUserId/logo.jpg');

      final uploadTask = await storageRef.putFile(imageFile);
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print("Error uploading image: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload logo image.')),
      );
      return null;
    }
  }

  void _submitProfile() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedTruckCountRange == null && _trucks.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Please select a truck count range or add truck details.',
            ),
          ),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      String? uploadedLogoUrl = _companyLogoURL;

      
      if (_companyLogoImage != null && !_companyLogoURL!.contains('http')) {
        uploadedLogoUrl = await _uploadLogoImage(_companyLogoImage!);
      }

      if (_currentUserId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User ID not available. Cannot save profile.')),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }


      final companyInfo = CompanyInfo(
        companyName: _companyNameController.text,
        companyEmail: _companyEmailController.text,
        companyDescription: _bioController.text.trim(),
        registrationNumber: _regNumController.text,
        numberOfEmployees: int.tryParse(_employeesController.text) ?? 0,
        tradeMarkImageURL: uploadedLogoUrl, 
        trucks: _trucks,
        numberOfTrucks: _trucks.length,
        companyPhoneNumber: _phoneController.text.isNotEmpty ? _phoneController.text : null,
        dateOfEstablishment: _selectedDate,
        certificates: _certificates,
      );

      final profile = UserProfile(
        id: _currentUserId!, 
        fullName: _fullNameController.text.isNotEmpty
            ? _fullNameController.text
            : _companyNameController.text,
        email: _companyEmailController.text,
        phoneNumber: _phoneController.text,
        dateOfBirth: _selectedDate, 
        bio: _bioController.text,
        profileImage: uploadedLogoUrl, 
        userType: UserType.company,
        driverInfo: null,
        companyInfo: companyInfo,
      );
      try {
        await FirebaseFirestore.instance
            .collection('profiles')
            .doc(_currentUserId)
            .set(profile.toMap(), SetOptions(merge: true));

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Company Profile saved successfully!')),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ViewCompanyProfileScreen(profile: profile),
          ),
        );
      } catch (e) {
        print('Firestore Save Error: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save profile: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.blue.shade50,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppColors.primaryBlue),
              SizedBox(height: 20),
              Text(
                _isDataLoaded ? 'Saving Profile...' : 'Loading Profile...',
                style: TextStyle(color: AppColors.primaryBlue, fontSize: 18),
              ),
            ],
          ),
        ),
      );
    }
    
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            floating: false,
            pinned: true,
            backgroundColor: Colors.blue.shade50,
            flexibleSpace: FlexibleSpaceBar(
              background: ClipRRect(
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                child: Stack(
                  children: [
                    CustomPaint(
                      size: Size(MediaQuery.of(context).size.width, 280),
                      painter: ProfileBackgroundPainter(
                        mainWaveColor: AppColors.primaryBlue,
                        circleColor: AppColors.secondaryBlue,
                        lightColor: AppColors.lightBlue,
                      ),
                    ),
                    Positioned(
                      bottom: 30,
                      left: 0,
                      right: 0,
                      child: Column(
                        children: [
                          ProfileImageWidget(
                            // Use stored URL if available, otherwise null
                            imageUrl: _companyLogoURL, 
                            onImageSelected: (image) {
                              setState(() {
                                _companyLogoImage = image;
                                _companyLogoURL = image.path; // Temporarily set path to indicate it's new/local
                              });
                            },
                            isEditable: true,
                            size: 100,
                          ),
                          SizedBox(height: 15),
                          Text(
                            'Register Company Profile',
                            style: TextStyle(
                              color: AppColors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(
                                  color: Colors.black26,
                                  blurRadius: 10,
                                  offset: Offset(2, 2),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            'Provide your company and fleet details',
                            style: TextStyle(
                              color: AppColors.white.withOpacity(0.9),
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(height: 10),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(top: 10),
              child: Container(
                padding: EdgeInsets.only(top: 15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(25),
                    topRight: Radius.circular(25),
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: _buildFormContent(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
 
  Widget _buildFormContent() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          _buildGlassCard(
            child: Column(
              children: [
                _buildInputField(
                  controller: _companyNameController,
                  label: 'Company Name',
                  icon: Icons.business_rounded,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the company name';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20),
                
                _buildInputField(
                  controller: _companyEmailController,
                  label: 'Company Email Address',
                  icon: Icons.email_outlined,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the company email';
                    }
                    if (!value.contains('@')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20),
                
                IntlPhoneField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    labelText: 'Contact Phone Number',
                    labelStyle: TextStyle(color: AppColors.primaryBlue,
                      fontWeight: FontWeight.w600, ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: AppColors.lightBlue.withOpacity(0.5),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide(
                        color: AppColors.primaryBlue,
                        width: 2,
                      ),
                    ),
                    prefixIcon: Icon(
                      Icons.phone_iphone_rounded,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                  initialCountryCode: 'US',
                  onChanged: (phone) {
                    
                  },
                ),
                SizedBox(height: 20),
                
                _buildInputField(
                  controller: _regNumController,
                  label: 'Business Registration/TRN',
                  icon: Icons.security_rounded,
                  validator: (value) => (value == null || value.isEmpty)
                      ? 'Registration Number is required'
                      : null,
                ),
                SizedBox(height: 20),
                // Number of Employees (New Field)
                _buildInputField(
                  controller: _employeesController,
                  label: 'Number of Employees',
                  icon: Icons.group_outlined,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Employee count is required';
                    }
                    if (int.tryParse(value) == null) {
                      return 'Must be a valid whole number';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20),
                
                _buildDateField(),
                SizedBox(height: 20),
                
                _buildInputField(
                  controller: _bioController,
                  label: 'Company Description (Optional)',
                  icon: Icons.description_outlined,
                  maxLines: 3,
                ),
              ],
            ),
          ),
    
        
          SizedBox(height: 25),
          _buildTruckCountAndDetailsSection(),
          SizedBox(height: 25),
          _buildCertificatesSection(), // Kept for consistency, can hold company compliance certs
          SizedBox(height: 40),

          // --- Submit Button (Updated to use async _submitProfile) ---
          Container(
            width: double.infinity,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [Color(0xFF4C66C3), Color(0xFF4C66C3)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: ElevatedButton(
              onPressed: _submitProfile, // This now runs the async logic
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text(
                'Register Company',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildTruckCountAndDetailsSection() {
    return _buildGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.local_shipping_rounded,
                color: AppColors.primaryOrange,
                size: 28,
              ),
              SizedBox(width: 10),
              Text(
                'Fleet Information',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryOrange,
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          DropdownButtonFormField<String>(
            value: _selectedTruckCountRange,
            hint: Text('Estimate Your Fleet Size' , style: TextStyle(color: AppColors.primaryOrange,),),
            icon: const Icon(Icons.arrow_drop_down),
            elevation: 16,
            style: TextStyle(color: AppColors.primaryBlue),
            decoration: InputDecoration(
              labelText: 'Truck Count Range',
              labelStyle: TextStyle(
                color: AppColors.primaryOrange,
                fontWeight: FontWeight.w600,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              filled: true,
              fillColor: AppColors.lightOrange.withOpacity(0.2),
            ),
            items: _truckCountRanges.map((String value) {
              return DropdownMenuItem<String>(value: value, child: Text(value));
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                _selectedTruckCountRange = newValue;
              });
            },
          ),

          SizedBox(height: 25),
          Text(
            'Individual Truck Details (${_trucks.length} added)',
            style: TextStyle(
              color: AppColors.primaryBlue,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Add details for specific trucks in your fleet.',
            style: TextStyle(color: AppColors.primaryBlue, fontSize: 14),
          ),
          SizedBox(height: 15),

          if (_trucks.isNotEmpty)
            ..._trucks.map((truck) => _buildTruckSummaryCard(truck)).toList(),

          SizedBox(height: 15),

          
          Container(
            width: double.infinity,
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: AppColors.primaryOrange.withOpacity(0.5),
                width: 2,
              ),
            ),
            child: TextButton.icon(
              onPressed: _openAddTruckDialog,
              icon: Icon(
                Icons.add_circle_outline,
                color: AppColors.primaryOrange,
              ),
              label: Text(
                'Add Truck Details',
                style: TextStyle(
                  color: AppColors.primaryOrange,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildTruckSummaryCard(Truck truck) {
    return Container(
      margin: EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: AppColors.lightOrange.withOpacity(0.1),
        border: Border.all(color: AppColors.primaryOrange.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.local_shipping, color: AppColors.primaryOrange, size: 35),
          SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${truck.make} ${truck.model} (${truck.licensePlate})',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryOrange,
                  ),
                ),
                Text(
                  '${truck.capacityTons.toStringAsFixed(1)} Tons | ${truck.truckType}',
                  style: TextStyle(color: AppColors.textGrey, fontSize: 13),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, color: Colors.red.shade700),
            onPressed: () => _removeTruck(truck),
          ),
        ],
      ),
    );
  }


  Widget _buildGlassCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(25),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        color: Colors.white.withOpacity(0.9),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
        border: Border.all(color: Colors.white.withOpacity(0.5), width: 1),
      ),
      child: child,
    );
  }


  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: AppColors.primaryOrange,
          fontWeight: FontWeight.w600,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: AppColors.lightOrange.withOpacity(0.6),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: AppColors.primaryOrange, width: 2.5),
        ),
        prefixIcon: Icon(icon, color: AppColors.primaryOrange),
      ),
    );
  }

  Widget _buildDateField() {

    return GestureDetector(
      onTap: _selectDate,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 15, vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: AppColors.lightBlue.withOpacity(0.5),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_month, color:  AppColors.primaryOrange),
            SizedBox(width: 15),
            Text(
              _selectedDate == null
                  ? 'Date of Establishment'
                  : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: _selectedDate == null
                      ?  AppColors.primaryOrange
                      : Colors.black87,
                  fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCertificatesSection() {

    return _buildGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.workspace_premium_rounded,
                color: AppColors.primaryBlue,
                size: 28,
              ),
              SizedBox(width: 10),
              Text(
                'Certificates',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryBlue,
                ),
              ),
            ],
          ),
          SizedBox(height: 15),
          Text(
            'Add compliance certifications for your business (e.g., insurance, safety audits).',
            style: TextStyle(color: AppColors.textGrey, fontSize: 14),
          ),
          SizedBox(height: 20),
          ..._certificates
              .map((certificate) => _buildCertificateCard(certificate))
              .toList(),
          SizedBox(height: 15),
          Container(
            width: double.infinity,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: AppColors.primaryBlue.withOpacity(0.5),
                width: 2,
                style: BorderStyle.solid,
              ),
            ),
            child: TextButton.icon(
              onPressed: _addCertificate,
              icon: Icon(
                Icons.add_circle_outline_rounded,
                color: AppColors.primaryBlue,
              ),
              label: Text(
                'Add Certificate',
                style: TextStyle(
                  color: AppColors.primaryBlue,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCertificateCard(Certificate certificate) {

    return Container(
      margin: EdgeInsets.only(bottom: 15),
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: AppColors.lightBlue.withOpacity(0.3),
        border: Border.all(color: AppColors.primaryBlue.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(
            certificate.isPdf
                ? Icons.picture_as_pdf_rounded 
                : Icons.image_rounded,
            color: AppColors.primaryBlue,
            size: 40,
          ),
          SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  certificate.name,

                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryBlue,
                  ),
                ),
                SizedBox(height: 5),

                Text(
                  certificate.organization,
                  style: TextStyle(color: AppColors.textGrey, fontSize: 14),
                ),
                SizedBox(height: 5),
                Text(
                  'Issued: ${certificate.issueDate.day}/${certificate.issueDate.month}/${certificate.issueDate.year}',
                  style: TextStyle(color: AppColors.darkGrey, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.delete_outline_rounded, color: Colors.red),
            onPressed: () {
              setState(() {
                _certificates.remove(certificate);
              });
            },
          ),
        ],
      ),
    );
  }


// --- Remaining Unchanged Methods ---

  void _openAddTruckDialog() {
    showDialog(
      context: context,
      builder: (ctx) => TruckDetailsDialog(
        onTruckAdded: (newTruck) {
          setState(() {
            _trucks.add(newTruck);

            _selectedTruckCountRange = null;
          });
        },
      ),
    );
  }

  void _removeTruck(Truck truck) {
    setState(() {
      _trucks.remove(truck);
    });
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _addCertificate() {
    showDialog(
      context: context,
      builder: (context) => CertificateDialog(
        onCertificateAdded: (certificate) {
          setState(() {
            _certificates.add(certificate);
          });
        },
      ),
    );
  }
}

class TruckDetailsDialog extends StatefulWidget {
  final Function(Truck) onTruckAdded;

  const TruckDetailsDialog({Key? key, required this.onTruckAdded})
    : super(key: key);

  @override
  _TruckDetailsDialogState createState() => _TruckDetailsDialogState();
}

class _TruckDetailsDialogState extends State<TruckDetailsDialog> {
  final _truckFormKey = GlobalKey<FormState>();
  final TextEditingController _makeController = TextEditingController();
  final TextEditingController _modelController = TextEditingController();
  final TextEditingController _plateController = TextEditingController();
  final TextEditingController _typeController = TextEditingController();
  final TextEditingController _capacityController = TextEditingController();
  final TextEditingController _axlesController = TextEditingController();
  final TextEditingController _vinController = TextEditingController();

 
  String? _selectedTruckType;
  final List<String> _truckTypes = [
    'Box Truck',
    'Flatbed',
    'Reefer (Refrigerated)',
    'Tanker',
    'Dump Truck',
  ];

  void _saveTruck() {
    if (_truckFormKey.currentState!.validate()) {
      final newTruck = Truck(
        truckId: UniqueKey().toString(),
        make: _makeController.text,
        model: _modelController.text,
        licensePlate: _plateController.text,
        truckType: _selectedTruckType!,
        capacityTons: double.tryParse(_capacityController.text) ?? 0.0,
        axles: int.tryParse(_axlesController.text) ?? 0,
        vin: _vinController.text.isNotEmpty ? _vinController.text : null,
        imageURLs: [],
      );

      widget.onTruckAdded(newTruck);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 15.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25.0)),
      elevation: 20,
      // shadowColor: AppColors.primaryOrange.withOpacity(0.3),
      shadowColor: Color(0xFFEAEAEA),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
          
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryOrange,
                      AppColors.primaryOrange.withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(25),
                    topRight: Radius.circular(25),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Add Truck Details',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.white,
                        fontSize: 20,
                        shadows: [
                          Shadow(
                            blurRadius: 4,
                            color: Colors.black.withOpacity(0.3),
                            offset: const Offset(1, 1),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.white.withOpacity(0.2),
                      ),
                      child: IconButton(
                        icon: Icon(Icons.close, color: AppColors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ],
                ),
              ),

        
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 25,
                ),
                child: Form(
                  key: _truckFormKey,
                  child: Column(
                    children: [
                  
                      Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(
                                bottom: 8.0,
                                left: 5,
                              ),
                              child: Text(
                                'Truck Type *',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primaryOrange,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.2),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: DropdownButtonFormField<String>(
                                value: _selectedTruckType,
                                hint: Text(
                                  'Select Truck Type',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                                icon: Icon(
                                  Icons.arrow_drop_down_circle,
                                  color: AppColors.primaryOrange,
                                ),
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: Colors.white,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 18,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(15),
                                    borderSide: BorderSide.none,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(15),
                                    borderSide: BorderSide(
                                      color: Colors.grey.shade300,
                                      width: 1.5,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(15),
                                    borderSide: BorderSide(
                                      color: AppColors.primaryOrange,
                                      width: 2,
                                    ),
                                  ),
                                ),
                                dropdownColor: Colors.white,
                                items: _truckTypes.map((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(
                                      value,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (String? newValue) {
                                  setState(() {
                                    _selectedTruckType = newValue;
                                  });
                                },
                                validator: (value) => (value == null)
                                    ? 'Truck type is required'
                                    : null,
                                style: TextStyle(
                                  color: Colors.grey[800],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Make
                      _buildAttractiveInputField(
                        controller: _makeController,
                        label: 'Make *',
                        validator: (v) => (v!.isEmpty) ? 'Required' : null,
                      ),

                      _buildAttractiveInputField(
                        controller: _modelController,
                        label: 'Model *',
                        validator: (v) => (v!.isEmpty) ? 'Required' : null,
                      ),

                      // License Plate
                      _buildAttractiveInputField(
                        controller: _plateController,
                        label: 'License Plate *',
                        validator: (v) => (v!.isEmpty) ? 'Required' : null,
                      ),

                      // Axles
                      _buildAttractiveInputField(
                        controller: _axlesController,
                        label: 'Axles *',
                        keyboardType: TextInputType.number,
                        validator: (v) =>
                            (v!.isEmpty || int.tryParse(v) == null)
                            ? 'Valid # required'
                            : null,
                      ),

                      // Capacity
                      _buildAttractiveInputField(
                        controller: _capacityController,
                        label: 'Capacity (Tons) *',
                        keyboardType: TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (v) =>
                            (v!.isEmpty || double.tryParse(v) == null)
                            ? 'Valid weight required'
                            : null,
                      ),

                      // VIN
                      _buildAttractiveInputField(
                        controller: _vinController,
                        label: 'VIN (Optional)',
                        validator: (v) => null,
                      ),

                      const SizedBox(height: 10),

                      // Buttons
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 55,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.redAccent.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                style: TextButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                    side: BorderSide(
                                      color: Colors.redAccent,
                                      width: 2,
                                    ),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 15,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.cancel_outlined,
                                      color: Colors.redAccent,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Cancel',
                                      style: TextStyle(
                                        color: Colors.redAccent,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Container(
                              height: 55,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15),
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFF4C66C3),
                                   Color(0xFF6B8BCC),
                                    // AppColors.primaryOrange,
                                    // AppColors.primaryOrange.withOpacity(0.8),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                // boxShadow: [
                                //   BoxShadow(
                                //     color: AppColors.primaryOrange.withOpacity(
                                //       0.4,
                                //     ),
                                //     blurRadius: 8,
                                //     offset: const Offset(0, 4),
                                //   ),
                                // ],
                              ),
                              child: ElevatedButton(
                                onPressed: _saveTruck,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 15,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.check_circle_outline,
                                      color: AppColors.white,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),

                                    Text(
                                      'Save Truck',
                                      style: TextStyle(
                                        color: AppColors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Enhanced text field with beautiful design
  Widget _buildAttractiveInputField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0, left: 5),
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.primaryOrange,
                fontSize: 14,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextFormField(
              controller: controller,
              keyboardType: keyboardType,
              validator: validator,
              style: TextStyle(
                color: Colors.grey[800],
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 18,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(
                    color: Colors.grey.shade300,
                    width: 1.5,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(
                    color: AppColors.primaryOrange,
                    width: 2,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: const BorderSide(color: Colors.red, width: 1.5),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: const BorderSide(color: Colors.red, width: 2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
