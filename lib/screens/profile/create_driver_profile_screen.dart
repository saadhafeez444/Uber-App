import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:uber_app/models/profile_model.dart';
import 'package:uber_app/screens/profile/create_user_profile_screen.dart';
import 'package:uber_app/screens/profile/view_driver_profile_screen.dart';
import 'package:uber_app/utils/app_colors.dart';
import 'package:uber_app/widgets/ProfileBackgroundPaineter.dart';
import 'package:uber_app/widgets/profile_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';


class CreateDriverScreen extends StatefulWidget {
  final String userId;
  final String role;

  const CreateDriverScreen({super.key, required this.userId, required this.role});
 

  @override
  _CreateDriverScreenState createState() => _CreateDriverScreenState();
}

class _CreateDriverScreenState extends State<CreateDriverScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _licenseController = TextEditingController();
  final TextEditingController _experienceController = TextEditingController();
  final TextEditingController _vehicleModelController = TextEditingController();
  final TextEditingController _vehiclePlateController = TextEditingController();
  final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

  DateTime? _selectedDate;
  
  File? _licenseImage;
  List<Certificate> _certificates = [];
  bool _isLoading = false; 
File? _profileImage;
  Future<String> _uploadFile(File file, String ref) async {
    try {
      final storageRef = FirebaseStorage.instance.ref().child(ref);
      await storageRef.putFile(file);
      final downloadUrl = await storageRef.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading file: $e');
     
      return '';
    }
  }

  Future<void> _uploadImageAndSaveProfile() async {
    if (!_formKey.currentState!.validate() || _isLoading) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final userId = currentUserId;
  
      if (userId == null) {
        throw Exception("User not logged in.");
      }

      String? profileImageUrl = _profileImage != null
          ? await _uploadFile(_profileImage!, 'profile_images/$userId/profile.jpg')
          : null;

      String? licenseImageUrl = _licenseImage != null
          ? await _uploadFile(_licenseImage!, 'driver_docs/$userId/license.jpg')
          : ''; 
      final driverInfo = DriverInfo(
        licenseNumber: _licenseController.text,
        licenseImage: licenseImageUrl ?? '',
        experienceYears: double.tryParse(_experienceController.text) ?? 0.0,
        vehicleModel: _vehicleModelController.text,
        vehiclePlate: _vehiclePlateController.text,
        rating: 0.0,
        totalRides: 0,
        certificates: _certificates,
      );

      
      final userProfile = UserProfile(
        id: userId, 
        fullName: _fullNameController.text,
        email: _emailController.text,
        phoneNumber: _phoneController.text,
        dateOfBirth: _selectedDate,
        bio: _bioController.text,
        profileImage: profileImageUrl, 
        userType: UserType.driver,
        driverInfo: driverInfo,
        companyInfo: null, 
      );

     
      await FirebaseFirestore.instance
          .collection('profiles') 
          .doc(userId) 
          .set(userProfile.toMap()); 

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile created successfully!')),
      );

    
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ViewDriverProfileScreen(profile: userProfile),
        ),
      );
    } catch (e) {
      print('Profile submission failed: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create profile: $e')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }





  void _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: AppColors.primaryBlue))
          : CustomScrollView(
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
                                  imageUrl: _profileImage?.path, 
                                  onImageSelected: (image) {
                                    setState(() {
                                      _profileImage = image;
                                    });
                                  },
                                  isEditable: true,
                                  size: 100,
                                ),
                              
                              
                              
                                SizedBox(height: 15),
                                Text(
                                  'Create Driver Profile',
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
                                  'Complete your profile to get started',
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
                  controller: _fullNameController,
                  label: 'Full Name',
                  icon: Icons.person_outline_rounded,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your full name';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20),
                _buildInputField(
                  controller: _emailController,
                  label: 'Email Address',
                  icon: Icons.email_outlined,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
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
                    labelText: 'Phone Number',
                    labelStyle: TextStyle(color: AppColors.primaryBlue),
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
                _buildDateField(),
                SizedBox(height: 20),
                _buildInputField(
                  controller: _bioController,
                  label: 'Bio (Optional)',
                  icon: Icons.description_outlined,
                  maxLines: 3,
                ),
              ],
            ),
          ),
  
          SizedBox(height: 25),
          _buildDriverSection(),
    
          SizedBox(height: 40),
          Container(
            width: double.infinity,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [AppColors.primaryBlue, AppColors.secondaryBlue],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryBlue.withOpacity(0.4),
                  blurRadius: 15,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: _isLoading ? null : _uploadImageAndSaveProfile, 
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: _isLoading
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                      ),
                    )
                  : Text(
                      'Create Profile',
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
            Icon(Icons.calendar_today_rounded, color: AppColors.primaryBlue),
            SizedBox(width: 15),
            Text(
              _selectedDate == null
                  ? 'Select Date of Birth'
                  : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
              style: TextStyle(
                color: _selectedDate == null
                    ? AppColors.primaryBlue
                    : Colors.black87,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildDriverSection() {
    return Column(
      children: [
        _buildGlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.directions_car_filled_rounded,
                    color: AppColors.primaryBlue,
                    size: 28,
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Driver Information',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              _buildInputField(
                controller: _licenseController,
                label: 'License Number',
                icon: Icons.badge_outlined,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter license number';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              _buildInputField(
                controller: _experienceController,
                label: 'Experience (Years)',
                icon: Icons.work_history_outlined,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter experience years';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              _buildInputField(
                controller: _vehicleModelController,
                label: 'Vehicle Model',
                icon: Icons.directions_car_outlined,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter vehicle model';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              _buildInputField(
                controller: _vehiclePlateController,
                label: 'Vehicle Plate',
                icon: Icons.confirmation_number_outlined,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter vehicle plate';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              _buildLicenseUpload(),
            ],
          ),
        ),
        SizedBox(height: 25),
        _buildCertificatesSection(),
      ],
    );
  }

  Widget _buildLicenseUpload() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Driver License',
          style: TextStyle(
            color: AppColors.primaryBlue,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        SizedBox(height: 10),
        GestureDetector(
          onTap: () async {
            final picker = ImagePicker();
            final pickedFile = await picker.pickImage(
              source: ImageSource.gallery,
            );
            if (pickedFile != null) {
              setState(() {
                _licenseImage = File(pickedFile.path);
              });
            }
          },
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              color: AppColors.lightBlue.withOpacity(0.3),
              border: Border.all(
                color: AppColors.primaryBlue.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _licenseImage == null
                      ? Icons.upload_file_rounded
                      : Icons.check_circle_rounded,
                  color: _licenseImage == null
                      ? AppColors.primaryBlue
                      : Colors.green,
                  size: 30,
                ),
                SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _licenseImage == null
                            ? 'Upload License Image'
                            : 'License Uploaded Successfully',
                        style: TextStyle(
                          color: AppColors.primaryBlue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        _licenseImage == null
                            ? 'Tap to upload your driver license'
                            : 'Ready for verification',
                        style: TextStyle(
                          color: AppColors.textGrey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
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
                'Certificates & Training',
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
            'Add your professional certificates and training documents',
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

}

 

Widget _buildGlassCard({required Widget child}) {
  return Container(
    padding: EdgeInsets.all(15),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(25),
      color: Colors.white,
      boxShadow: [
        BoxShadow(color: Colors.black26, blurRadius: 30, offset: Offset(0, 20)),
      ],
    ),
    child: child,
  );
}











