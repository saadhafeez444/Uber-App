
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:uber_app/models/profile_model.dart';
import 'package:uber_app/screens/auth/login_screen.dart';
import 'package:uber_app/screens/auth/splash_screen.dart';
import 'package:uber_app/screens/profile/edit_profile_screen.dart';
import 'package:uber_app/services/preference_service.dart';
import 'package:uber_app/utils/app_colors.dart';
import 'package:uber_app/widgets/ProfileBackgroundPaineter.dart';
import 'package:uber_app/widgets/profile_image.dart';


class ViewUserProfileScreen extends StatefulWidget {
  final UserProfile profile;

  const ViewUserProfileScreen({Key? key, required this.profile}) : super(key: key);

  @override
  State<ViewUserProfileScreen> createState() => _ViewUserProfileScreenState();
}

class _ViewUserProfileScreenState extends State<ViewUserProfileScreen> {


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



  @override
  Widget build(BuildContext context) {

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
                  _buildPersonalInfoCard(),
                  SizedBox(height: 20),
                  SizedBox(height: 20),
                  SizedBox(height: 20),
                  if (widget.profile.bio != null && widget.profile.bio!.isNotEmpty)
                    _buildBioCard(),
                    SizedBox(height: 20,),
                         
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
                        imageUrl: widget.profile.profileImage, 
                        onImageSelected: (image) {},
                        isEditable: false,
                        size: 140,
                      ),
                    ),
                  ),
                  SizedBox(height: 40),
                  Text(
                    widget.profile.fullName,
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
                    padding: EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.white.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      // This part assumes a "Verified User" status or can be made dynamic
                      'Verified User', 
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
            icon: Icon(
              Icons.edit_rounded,
              color: AppColors.white,
              size: 22,
            ),
            onPressed: () {
              
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditProfileScreen(profile: widget.profile),
                ),
              );
            },
          ),
        ),
      ],
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
                    value: widget.profile.email,
                    iconColor: AppColors.primaryBlue,
                  ),
                  SizedBox(height: 20),
                  _buildInfoRow(
                    icon: Icons.phone_rounded,
                    label: 'Phone Number',
                    value: widget.profile.phoneNumber,
                    iconColor: AppColors.primaryBlue,
                  ),
                  if (widget.profile.dateOfBirth != null) ...[
                    SizedBox(height: 20),
                    _buildInfoRow(
                      icon: Icons.cake_rounded,
                      label: 'Date of Birth',
                      value:
                          '${widget.profile.dateOfBirth!.day}/${widget.profile.dateOfBirth!.month}/${widget.profile.dateOfBirth!.year}',
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
                widget.profile.bio!,
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
}