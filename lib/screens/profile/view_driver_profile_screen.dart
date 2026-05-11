// view_driver_profile_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:uber_app/models/profile_model.dart';
import 'package:uber_app/screens/auth/login_screen.dart';
import 'package:uber_app/screens/auth/splash_screen.dart';
import 'package:uber_app/screens/profile/edit_profile_screen.dart';
import 'package:uber_app/screens/profile/view_user_profile_screen.dart';
import 'package:uber_app/services/preference_service.dart';
import 'package:uber_app/utils/app_colors.dart';
import 'package:uber_app/widgets/ProfileBackgroundPaineter.dart';
import 'package:uber_app/widgets/profile_image.dart';

class ViewDriverProfileScreen extends StatefulWidget {
  final UserProfile profile;

  const ViewDriverProfileScreen({Key? key, required this.profile})
    : super(key: key);

  @override
  State<ViewDriverProfileScreen> createState() =>
      _ViewDriverProfileScreenState();
}

class _ViewDriverProfileScreenState extends State<ViewDriverProfileScreen> {
  UserProfile? _currentProfile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _handleLogout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();

      await PreferenceService.clearPreferences();

      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => SplashScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logout failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }




  Future<void> _loadProfileData() async {
    try {
      _currentProfile = widget.profile;

      final freshProfile = await _fetchUserProfile(widget.profile.id);
      setState(() {
        _currentProfile = freshProfile;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading profile: $e');
      setState(() {
        _isLoading = false;

        _currentProfile = widget.profile;
      });
    }
  }

  Future<UserProfile> _fetchUserProfile(String userId) async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('profiles')
          .doc(userId)
          .get();

      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        print('Firestore document data: $data');

        data['id'] = userId;

        return UserProfile.fromMap(data);
      } else {
        throw Exception('Profile not found');
      }
    } catch (e) {
      print('Error fetching profile: $e');
      throw e;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _currentProfile == null) {
      return Scaffold(
        backgroundColor: AppColors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    print('Full Profile Data: ${_currentProfile!.toMap()}');
    print('Profile Image URL from object: ${_currentProfile!.profileImage}');

    return Scaffold(
      backgroundColor: AppColors.white,
      body: CustomScrollView(
        physics: BouncingScrollPhysics(),
        slivers: [
          _buildSliverAppBar(context),
          SliverToBoxAdapter(
            child: Transform.translate(
              offset: Offset(0, -50),
              child: Column(
                children: [
                  SizedBox(height: 35),

                  _buildDriverStatsCard(context),

                  SizedBox(height: 25),

                  _buildPersonalInfoCard(),

                  SizedBox(height: 20),
                  _buildDriverInfoCard(),

                  SizedBox(height: 20),

                  if (_currentProfile!.driverInfo!.certificates.isNotEmpty)
                    _buildCertificatesCard(),

                  SizedBox(height: 20),

                  if (_currentProfile!.bio != null &&
                      _currentProfile!.bio!.isNotEmpty)
                    _buildBioCard(),

                  SizedBox(height: 20),

                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 15),
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        elevation: 0,

                        backgroundColor: AppColors.primaryBlue.withOpacity(0.9),
                      ),

                      onPressed: () async {
                        await _handleLogout(context);
                      },
                      child: Text(
                        'LogOut',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
               
               
               
                  ),

                  SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  SliverAppBar _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 320,
      floating: false,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        background: Stack(
          children: [
            CustomPaint(
              size: Size(MediaQuery.of(context).size.width, 320),
              painter: ProfileBackgroundPainter(
                mainWaveColor: AppColors.primaryBlue,
                circleColor: AppColors.secondaryBlue,
                lightColor: AppColors.lightBlue,
              ),
            ),
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  Transform.translate(
                    offset: Offset(0, 30),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryBlue.withOpacity(0.3),
                            blurRadius: 25,
                            spreadRadius: 5,
                            offset: Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ProfileImageWidget(
                        imageUrl: _currentProfile!.profileImage ?? '',
                        onImageSelected: (image) {},
                        isEditable: false,
                        size: 140,
                      ),
                    ),
                  ),
                  SizedBox(height: 40),
                  Text(
                    _currentProfile!.fullName,
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          color: Colors.black26,
                          blurRadius: 15,
                          offset: Offset(2, 2),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.white.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      'Professional Driver',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        Container(
          margin: EdgeInsets.only(right: 15, top: 10),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [AppColors.primaryBlue, AppColors.secondaryBlue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryBlue.withOpacity(0.4),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(Icons.edit_rounded, color: AppColors.white, size: 22),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      EditProfileScreen(profile: _currentProfile!),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDriverStatsCard(BuildContext context) {
    final driverInfo = _currentProfile!.driverInfo!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primaryBlue.withOpacity(0.9),
              AppColors.secondaryBlue.withOpacity(0.9),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: IntrinsicHeight(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // 1. Rating
              _buildStatItem(
                value: driverInfo.rating.toStringAsFixed(1),
                label: 'Rating',
                icon: Icons.star_rounded,
                color: Colors.amberAccent,
              ),

              // Separator 1
              const VerticalDivider(
                color: Colors.white54,
                thickness: 1,
                indent: 5,
                endIndent: 5,
              ),

              // 2. Total Rides
              _buildStatItem(
                value: driverInfo.totalRides.toString(),
                label: 'Total Rides',
                icon: Icons.directions_car_rounded,
                color: AppColors.white,
              ),

              // Separator 2
              const VerticalDivider(
                color: Colors.white54,
                thickness: 1,
                indent: 5,
                endIndent: 5,
              ),

              // 3. Experience
              _buildStatItem(
                value: '${driverInfo.experienceYears.toStringAsFixed(1)}y',
                label: 'Experience',
                icon: Icons.work_history_rounded,
                color: AppColors.lightBlue,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required String value,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 55,
            height: 55,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.4),
                width: 1.5,
              ),
            ),
            child: Icon(icon, color: color, size: 28),
          ),

          const SizedBox(height: 10),

          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),

          const SizedBox(height: 2),

          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.white.withOpacity(0.7),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoCard() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 15),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          color: AppColors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryBlue.withOpacity(0.1),
                    AppColors.lightBlue,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(25),
                  topRight: Radius.circular(25),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.person_rounded,
                      color: AppColors.white,
                      size: 20,
                    ),
                  ),
                  SizedBox(width: 15),
                  Text(
                    'Personal Information',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: EdgeInsets.all(25),
              child: Column(
                children: [
                  _buildInfoRow(
                    icon: Icons.email_rounded,
                    label: 'Email Address',
                    value: _currentProfile!.email,
                    iconColor: AppColors.primaryBlue,
                  ),
                  SizedBox(height: 20),
                  _buildInfoRow(
                    icon: Icons.phone_rounded,
                    label: 'Phone Number',
                    value: _currentProfile!.phoneNumber,
                    iconColor: AppColors.primaryBlue,
                  ),
                  if (_currentProfile!.dateOfBirth != null) ...[
                    SizedBox(height: 20),
                    _buildInfoRow(
                      icon: Icons.cake_rounded,
                      label: 'Date of Birth',
                      value:
                          '${_currentProfile!.dateOfBirth!.day}/${_currentProfile!.dateOfBirth!.month}/${_currentProfile!.dateOfBirth!.year}',
                      iconColor: AppColors.primaryBlue,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: iconColor.withOpacity(0.3)),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
        ),
        SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textGrey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCertificatesCard() {
    final certificates =
        _currentProfile!.driverInfo!.certificates as List<Certificate>;

    const gradientColors = [Color(0xFFFFB300), Color(0xFFFF8F00)];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: AppColors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.orange.withOpacity(0.2),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: gradientColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: AppColors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.workspace_premium_rounded,
                      color: Color(0xFFFF8F00),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 15),
                  const Text(
                    'Certificates & Training',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.white,
                    ),
                  ),
                ],
              ),
            ),

            certificates.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'No certificates on record.',
                      style: TextStyle(color: Colors.black54),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: certificates.length,
                    itemBuilder: (context, index) {
                      return _buildCertificateExpansionTile(
                        certificates[index],
                        gradientColors[1],
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildCertificateExpansionTile(
    Certificate certificate,
    Color accentColor,
  ) {
    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      iconColor: accentColor,
      collapsedIconColor: accentColor.withOpacity(0.7),
      title: Text(
        certificate.name,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
      subtitle: Text(
        certificate.organization,
        style: TextStyle(fontSize: 13, color: Colors.black54),
      ),
      leading: Icon(
        certificate.isPdf ? Icons.picture_as_pdf_rounded : Icons.badge_rounded,
        color: accentColor,
        size: 28,
      ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow(
                icon: Icons.calendar_today_rounded,
                label: 'Issued Date',
                value:
                    '${certificate.issueDate.day}/${certificate.issueDate.month}/${certificate.issueDate.year}',
                accentColor: accentColor,
              ),
              if (certificate.expiryDate != null)
                _buildDetailRow(
                  icon: Icons.timer_rounded,
                  label: 'Expiry Date',
                  value:
                      '${certificate.expiryDate!.day}/${certificate.expiryDate!.month}/${certificate.expiryDate!.year}',
                  accentColor: accentColor,
                ),

              const SizedBox(height: 15),

              if (certificate.filePath != null || certificate.filePath != null)
                _buildFilePreview(certificate),

              const SizedBox(height: 10),

              if (certificate.filePath != null)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Action to view file
                    },
                    icon: Icon(
                      Icons.visibility_rounded,
                      size: 20,
                      color: AppColors.white,
                    ),
                    label: Text(
                      'View Document',
                      style: TextStyle(color: AppColors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required Color accentColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: accentColor.withOpacity(0.8)),
          const SizedBox(width: 8),
          Text(
            '$label:',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black54,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilePreview(Certificate certificate) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Document Preview',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          height: 150,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: certificate.filePath != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    certificate.filePath!,
                    fit: BoxFit.fill,
                    errorBuilder: (context, error, stackTrace) => const Center(
                      child: Icon(
                        Icons.image_not_supported_rounded,
                        color: Colors.grey,
                        size: 40,
                      ),
                    ),
                  ),
                )
              : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        certificate.isPdf
                            ? Icons.picture_as_pdf_rounded
                            : Icons.insert_drive_file_rounded,
                        color: Colors.orange,
                        size: 40,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        certificate.isPdf
                            ? 'PDF File Available'
                            : 'Document File Available',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildBioCard() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 15),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          color: AppColors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.orange.withOpacity(0.1), AppColors.lightBlue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(25),
                  topRight: Radius.circular(25),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.description_rounded,
                      color: AppColors.white,
                      size: 20,
                    ),
                  ),
                  SizedBox(width: 15),
                  Text(
                    'About Me',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: EdgeInsets.all(25),
              child: Text(
                _currentProfile!.bio!,
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.darkGrey,
                  height: 1.6,
                ),
                textAlign: TextAlign.justify,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDriverInfoCard() {
    final driverInfo = _currentProfile!.driverInfo!;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 15),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          color: AppColors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.secondaryBlue.withOpacity(0.1),
                    AppColors.lightBlue,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(25),
                  topRight: Radius.circular(25),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryBlue,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.directions_car_rounded,
                      color: AppColors.white,
                      size: 20,
                    ),
                  ),
                  SizedBox(width: 15),
                  Text(
                    'Driver Information',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.secondaryBlue,
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: EdgeInsets.all(25),
              child: Column(
                children: [
                  _buildInfoRow(
                    icon: Icons.badge_rounded,
                    label: 'License Number',
                    value: driverInfo.licenseNumber,
                    iconColor: AppColors.primaryBlue,
                  ),
                  SizedBox(height: 20),
                  _buildInfoRow(
                    icon: Icons.work_history_rounded,
                    label: 'Experience',
                    value:
                        '${driverInfo.experienceYears.toStringAsFixed(1)} years',
                    iconColor: AppColors.primaryBlue,
                  ),
                  SizedBox(height: 20),
                  _buildInfoRow(
                    icon: Icons.directions_car_filled_rounded,
                    label: 'Vehicle Model',
                    value: driverInfo.vehicleModel,
                    iconColor: AppColors.primaryBlue,
                  ),
                  SizedBox(height: 20),
                  _buildInfoRow(
                    icon: Icons.confirmation_number_rounded,
                    label: 'Vehicle Plate',
                    value: driverInfo.vehiclePlate,
                    iconColor: AppColors.primaryBlue,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
