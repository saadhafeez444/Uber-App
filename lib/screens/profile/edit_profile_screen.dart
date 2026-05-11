import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:uber_app/models/profile_model.dart';
import 'package:uber_app/utils/app_colors.dart';
import 'package:uber_app/widgets/profile_image.dart';


class EditProfileScreen extends StatefulWidget {
  final UserProfile profile;

  const EditProfileScreen({Key? key, required this.profile}) : super(key: key);

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late UserProfile _editedProfile;
  final _formKey = GlobalKey<FormState>();
  File? _newProfileImage;
  File? _newLicenseImage;

  @override
  void initState() {
    super.initState();
    _editedProfile = widget.profile;
  }

  void _saveProfile() {
    if (_formKey.currentState!.validate()) {
      // Save profile logic here
      Navigator.pop(context, _editedProfile);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: Text(
          'Edit Profile',
          style: TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.primaryBlue,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.white),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _saveProfile,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primaryBlue,
              AppColors.secondaryBlue,
              AppColors.white,
            ],
            stops: [0, 0.2, 0.2],
          ),
        ),
        child: Column(
          children: [
            // Header Section
            Container(
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  SizedBox(height: 20),
                  ProfileImageWidget(
                    imageUrl: _editedProfile.profileImage,
                    onImageSelected: (image) {
                      setState(() {
                        _newProfileImage = image;
                      });
                    },
                    isEditable: true,
                  ),
                  SizedBox(height: 15),
                  Text(
                    _editedProfile.fullName,
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    _editedProfile.userType == UserType.driver ? 'Driver' : 'User',
                    style: TextStyle(
                      color: AppColors.white.withOpacity(0.9),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            // Form Section
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 20,
                      offset: Offset(0, -5),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(25),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildEditableField(
                          label: 'Full Name',
                          value: _editedProfile.fullName,
                          icon: Icons.person,
                          onChanged: (value) {
                            setState(() {
                              // _editedProfile = _editedProfile.copyWith(fullName: value);
                            });
                          },
                        ),
                        SizedBox(height: 20),
                        _buildEditableField(
                          label: 'Email',
                          value: _editedProfile.email,
                          icon: Icons.email,
                          onChanged: (value) {
                            setState(() {
                              // _editedProfile = _editedProfile.copyWith(email: value);
                            });
                          },
                        ),
                        SizedBox(height: 20),
                        _buildPhoneField(),
                        SizedBox(height: 20),
                        _buildBioField(),
                        if (_editedProfile.userType == UserType.driver) ...[
                          SizedBox(height: 30),
                          _buildDriverInfoSection(),
                        ],
                        SizedBox(height: 40),
                      ],
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

  Widget _buildEditableField({
    required String label,
    required String value,
    required IconData icon,
    required Function(String) onChanged,
  }) {
    return TextFormField(
      initialValue: value,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: AppColors.primaryBlue),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: AppColors.primaryBlue),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: AppColors.primaryBlue, width: 2),
        ),
        prefixIcon: Icon(icon, color: AppColors.primaryBlue),
      ),
    );
  }

  Widget _buildPhoneField() {
    return IntlPhoneField(
      initialValue: _editedProfile.phoneNumber,
      decoration: InputDecoration(
        labelText: 'Phone Number',
        labelStyle: TextStyle(color: AppColors.primaryBlue),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: AppColors.primaryBlue),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: AppColors.primaryBlue, width: 2),
        ),
        prefixIcon: Icon(Icons.phone, color: AppColors.primaryBlue),
      ),
      initialCountryCode: 'US',
      onChanged: (phone) {
        setState(() {
          // _editedProfile = _editedProfile.copyWith(phoneNumber: phone.completeNumber);
        });
      },
    );
  }

  Widget _buildBioField() {
    return TextFormField(
      initialValue: _editedProfile.bio,
      onChanged: (value) {
        setState(() {
          // _editedProfile = _editedProfile.copyWith(bio: value);
        });
      },
      maxLines: 3,
      decoration: InputDecoration(
        labelText: 'Bio',
        labelStyle: TextStyle(color: AppColors.primaryBlue),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: AppColors.primaryBlue),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: AppColors.primaryBlue, width: 2),
        ),
        prefixIcon: Icon(Icons.description, color: AppColors.primaryBlue),
      ),
    );
  }

  Widget _buildDriverInfoSection() {
    final driverInfo = _editedProfile.driverInfo!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Driver Information',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryBlue,
          ),
        ),
        SizedBox(height: 20),
        _buildEditableField(
          label: 'License Number',
          value: driverInfo.licenseNumber,
          icon: Icons.card_membership,
          onChanged: (value) {
            // Update license number logic
          },
        ),
        SizedBox(height: 20),
        _buildEditableField(
          label: 'Vehicle Model',
          value: driverInfo.vehicleModel,
          icon: Icons.directions_car,
          onChanged: (value) {
            // Update vehicle model logic
          },
        ),
        SizedBox(height: 20),
        _buildEditableField(
          label: 'Vehicle Plate',
          value: driverInfo.vehiclePlate,
          icon: Icons.confirmation_number,
          onChanged: (value) {
            // Update vehicle plate logic
          },
        ),
      ],
    );
  }
}