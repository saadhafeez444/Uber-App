import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl_phone_field/intl_phone_field.dart';

import 'package:uber_app/models/profile_model.dart';

import 'package:uber_app/screens/profile/view_user_profile_screen.dart';
import 'package:uber_app/utils/app_colors.dart';
import 'package:uber_app/widgets/ProfileBackgroundPaineter.dart';
import 'package:uber_app/widgets/profile_image.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uber_app/models/profile_model.dart';
import 'package:uber_app/utils/app_colors.dart';

import 'package:uber_app/widgets/ProfileBackgroundPaineter.dart';
import 'package:uber_app/widgets/profile_image.dart';

class CreateUserScreen extends StatefulWidget {
  final String userId;
  final String role;

  const CreateUserScreen({super.key, required this.userId, required this.role});
  

  @override
  _CreateUserScreenState createState() => _CreateUserScreenState();
}

class _CreateUserScreenState extends State<CreateUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  
  DateTime? _selectedDate;
  File? _profileImage;

  bool _isLoading = false;

 

  Future<String?> _uploadImage(File imageFile, String userId) async {
    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('user_profiles')
          .child('$userId.jpg');
      
      final uploadTask = storageRef.putFile(imageFile);
      final snapshot = await uploadTask.whenComplete(() {});
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print("Error uploading image: $e");
      // Optionally show a user-friendly error message here
      return null;
    }
  }

  void _submitProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {

        // final userId = FirebaseFirestore.instance.collection('profiles').doc().id;
        String? imageUrl;

        if (_profileImage != null) {
          imageUrl = await _uploadImage(_profileImage!, widget.userId);
        }
        final profile = UserProfile(
          id: widget.userId,
          fullName: _fullNameController.text,
          email: _emailController.text,
          phoneNumber: _phoneController.text,
          dateOfBirth: _selectedDate,
          bio: _bioController.text,
          profileImage: imageUrl, 
          userType: UserType.user, 
          driverInfo: null,
        );

        // 4. Save the user profile data to Firestore
        await FirebaseFirestore.instance
            .collection('profiles')
            .doc(widget.userId)
            .set({
              'id': profile.id,
              'fullName': profile.fullName,
              'email': profile.email,
              'phoneNumber': profile.phoneNumber,
              'dateOfBirth': profile.dateOfBirth?.toIso8601String(),
              'bio': profile.bio,
              'profileImageURL': profile.profileImage, 
              'userType': profile.userType.toString().split('.').last,
            });

        // 5. Navigate to the next screen on success
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ViewUserProfileScreen(profile: profile),
          ),
        );

      } catch (e) {
        print('Firebase Error: $e');
        // Show an error message to the user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save profile. Please try again.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }



  Future<void> _selectDate() async {
   
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

  @override
  Widget build(BuildContext context) {
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
                            imageUrl: null, 
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
                            'Create User Profile',
                            style: TextStyle(
                              color: Colors.white,
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
                              color: Colors.white.withOpacity(0.9),
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
                // Full Name
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
                // Email
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
                // Phone Number
                IntlPhoneField( 
                  controller: _phoneController,
                  // ... (IntlPhoneField styling remains unchanged)
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
                    print(phone.completeNumber);
                  },
                ),
                SizedBox(height: 20),
                // Date of Birth
                _buildDateField(),
                SizedBox(height: 20),
                // Bio
                _buildInputField(
                  controller: _bioController,
                  label: 'Bio (Optional)',
                  icon: Icons.description_outlined,
                  maxLines: 3,
                ),
              ],
            ),
          ),
          SizedBox(height: 40),
          // Create Profile Button
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
              onPressed: _isLoading ? null : _submitProfile, // Disable when loading
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: AppColors.white,
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
}

 

Widget _buildGlassCard({required Widget child}) {
  return Container(
    padding: EdgeInsets.all(10),
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












class MockPickedFile {
  final String path;
  MockPickedFile({required this.path});
}

class MockImagePicker {
  Future<MockPickedFile?> pickImage({required ImageSource source}) async {
   
    return MockPickedFile(path: 'assets/certificate_document.pdf');
  }
}

class CertificateDialog extends StatefulWidget {
  final Function(Certificate) onCertificateAdded;

  const CertificateDialog({Key? key, required this.onCertificateAdded})
      : super(key: key);

  @override
  _CertificateDialogState createState() => _CertificateDialogState();
}

class _CertificateDialogState extends State<CertificateDialog> {

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _orgController = TextEditingController();
  DateTime? _issueDate;
  DateTime? _expiryDate;
  File? _certificateFile; 
  bool _isPdf = false;
  
  final MockImagePicker _picker = MockImagePicker();


  Widget _buildStyledCard({required Widget child}) {
    return Container(
      constraints: BoxConstraints(maxWidth: 450),
      child: Card(
        color: Colors.white,
        elevation: 15, 
        shadowColor: AppColors.primaryBlue.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24), 
        ),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Using a SingleChildScrollView to prevent overflow on small screens
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Center(
        child: SingleChildScrollView(
          // Replacing the original _buildGlassCard with the new styled card
          child: _buildStyledCard(
            child: Padding(
              padding: const EdgeInsets.all(32.0), // Generous Padding for spacing
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Add New Credential',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primaryBlue,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Fill in the details for your new professional certificate.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  SizedBox(height: 30),
                  _buildInputField(
                    _nameController,
                    'Certificate Name',
                    Icons.badge_outlined,
                  ),
                  SizedBox(height: 20), // Adjusted spacing
                  _buildInputField(
                    _orgController,
                    'Issuing Organization',
                    Icons.business_rounded,
                  ),
                  SizedBox(height: 20),
                  _buildDateField(
                    'Issue Date',
                    _issueDate,
                    (date) => _issueDate = date,
                  ),
                  SizedBox(height: 20),
                  _buildDateField(
                    'Expiry Date (Optional)',
                    _expiryDate,
                    (date) => _expiryDate = date,
                  ),
                  SizedBox(height: 20),
                  _buildFileUpload(),
                  SizedBox(height: 30), // Extra spacing before buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton( // Professional OutlinedButton for Cancel
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primaryBlue,
                            side: BorderSide(color: AppColors.primaryBlue, width: 2),
                            padding: EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: Text('Cancel', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                      SizedBox(width: 15),
                      Expanded(
                        child: ElevatedButton( // Gorgeous, elevated button for Add
                          onPressed: _addCertificate,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryBlue,
                            foregroundColor: Colors.white,
                            elevation: 8,
                            shadowColor: AppColors.primaryBlue.withOpacity(0.5),
                            padding: EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: Text('Add Certificate', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(
    TextEditingController controller,
    String label,
    IconData icon,
  ) {
    return Material(
      elevation: 5, // Soft elevation for input field
      shadowColor: Colors.black.withOpacity(0.1),
      borderRadius: BorderRadius.circular(16),
      child: TextFormField(
        controller: controller,
        cursorColor: AppColors.primaryBlue,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w500),
          prefixIcon: Icon(icon, color: AppColors.primaryBlue.withOpacity(0.8)),
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none, // Hide default border for cleaner look
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: AppColors.primaryBlue, width: 2),
          ),
        ),
      ),
    );
  }


  Widget _buildDateField(
    String label,
    DateTime? date,
    Function(DateTime) onDateSelected,
  ) {
    return Material(
      elevation: 5,
      shadowColor: AppColors.infoCyan.withOpacity(0.1),
      borderRadius: BorderRadius.circular(16),
      child: GestureDetector(
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: date ?? DateTime.now(),
            firstDate: DateTime(2000),
            lastDate: DateTime(2100),
            builder: (context, child) {
              return Theme(
                data: ThemeData.light().copyWith(
                  colorScheme: ColorScheme.light(
                    primary: AppColors.primaryBlue, 
                    onPrimary: Colors.white,
                    onSurface: Colors.black87,
                  ),
                  textButtonTheme: TextButtonThemeData(
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primaryBlue,
                    ),
                  ),
                ),
                child: child!,
              );
            },
          );
          if (picked != null) {
            setState(() {
              // This is the required logic from the original snippet:
              onDateSelected(picked);
            });
          }
        },
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 18), // Good internal padding
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey.shade200),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(Icons.calendar_month, color: AppColors.primaryBlue),
              SizedBox(width: 15),
              Text(
                date == null ? label : 'Selected: ${date.day}/${date.month}/${date.year}',
                style: TextStyle(
                  color: date == null ? Colors.grey.shade500 : Colors.black87,
                  fontWeight: date == null ? FontWeight.normal : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

 
  Widget _buildFileUpload() {
    return GestureDetector(
      onTap: () async {
     
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
      
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'], 
      );

      if (result != null && result.files.single.path != null) {
        final pickedFilePlatform = result.files.single;

        setState(() {
          // Assign the picked file object
          _certificateFile = File(pickedFilePlatform.path!); 
          
          // Check if the file is a PDF
          _isPdf = pickedFilePlatform.extension?.toLowerCase() == 'pdf';
        });
      }
    },
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _certificateFile == null ? AppColors.lightBlue : AppColors.primaryBlue.withOpacity(0.05),
          border: Border.all(
            color: _certificateFile == null ? Colors.grey.shade300 : AppColors.primaryBlue,
            width: _certificateFile == null ? 1 : 2,
          ),
          borderRadius: BorderRadius.circular(16), // Consistent border radius
        ),
        child: Row(
          children: [
            Icon(
              _certificateFile == null ? Icons.cloud_upload_outlined : Icons.check_circle_rounded,
              color: _certificateFile == null ? AppColors.primaryBlue : Colors.green.shade600,
              size: 32,
            ),
            SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _certificateFile == null
                        ? 'Click to Upload Document'
                        : 'File Ready for Submission',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    _certificateFile == null
                        ? 'Accepted formats: Image or PDF'
                        : _certificateFile!.path.split('/').last,
                    style: TextStyle(
                      fontSize: 13,
                      color: _certificateFile == null ? Colors.grey.shade600 : AppColors.primaryBlue,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addCertificate() {
    if (_nameController.text.isEmpty ||
        _orgController.text.isEmpty ||
        _issueDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please fill all required fields (Name, Organization, Issue Date).',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating, // Floating behavior is cleaner
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    final certificate = Certificate(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text,
      organization: _orgController.text,
      issueDate: _issueDate!,
      expiryDate: _expiryDate,
      filePath: _certificateFile?.path,
      isPdf: _isPdf,
    );

    widget.onCertificateAdded(certificate);
    Navigator.pop(context);
  }
}

