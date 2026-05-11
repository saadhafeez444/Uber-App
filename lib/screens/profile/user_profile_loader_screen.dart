import 'package:flutter/material.dart';
import 'package:uber_app/models/profile_model.dart';
import 'package:uber_app/screens/profile/view_driver_profile_screen.dart';
import 'package:uber_app/services/profile_services.dart';


import 'view_user_profile_screen.dart';

import 'view_company_profile_screen.dart';

// class UserProfileLoaderScreen extends StatefulWidget {
//   final String userId;

//   const UserProfileLoaderScreen({Key? key, required this.userId}) : super(key: key);

//   @override
//   State<UserProfileLoaderScreen> createState() => _UserProfileLoaderScreenState();
// }

// class _UserProfileLoaderScreenState extends State<UserProfileLoaderScreen> {
//   late Future<UserProfile> _profileFuture;
//   final ProfileService _profileService = ProfileService();

//   @override
//   void initState() {
//     super.initState();
//     _profileFuture = _profileService.fetchUserProfile(widget.userId);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return FutureBuilder<UserProfile>(
//       future: _profileFuture,
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
         
//           return const Scaffold(
//             body: Center(child: CircularProgressIndicator()),
//           );
//         } else if (snapshot.hasError) {
     
//           return Scaffold(
//             appBar: AppBar(title: const Text('Error')),
//             body: Center(
//               child: Padding(
//                 padding: const EdgeInsets.all(16.0),
//                 child: Text(
//                   'Failed to load profile: ${snapshot.error}',
//                   textAlign: TextAlign.center,
//                   style: const TextStyle(color: Colors.red),
//                 ),
//               ),
//             ),
//           );
//         } else if (snapshot.hasData) {
          
//           final profile = snapshot.data!;
//           final userType = profile.userType;

//           WidgetsBinding.instance.addPostFrameCallback((_) {
//             // if (userType == 'user') {
//             //   Navigator.pushReplacement(
//             //     context,
//             //     MaterialPageRoute(
//             //       builder: (_) => ViewUserProfileScreen(profile: profile),
//             //     ),
//             //   );
//             // } else if (userType == 'driver') {
//             //   Navigator.pushReplacement(
//             //     context,
//             //     MaterialPageRoute(
//             //       builder: (_) => ViewDriverProfileScreen(profile: profile),
//             //     ),
//             //   );
//             // } else if (userType == 'company') {
//             //   Navigator.pushReplacement(
//             //     context,
//             //     MaterialPageRoute(
//             //       builder: (_) => ViewCompanyProfileScreen(profile: profile),
//             //     ),
//             //   );
//             // }
//             if (profile.userType == UserType.user) {
//         Navigator.pushReplacement(
//                 context,
//                 MaterialPageRoute(
//                   builder: (_) => ViewUserProfileScreen(profile: profile),
//                 ),
//               );
// } else if (profile.userType == UserType.driver) {
//          Navigator.pushReplacement(
//                 context,
//                 MaterialPageRoute(
//                   builder: (_) => ViewDriverProfileScreen(profile: profile),
//                 ),
//               );
// } else if (profile.userType == UserType.company) {
//   Navigator.pushReplacement(
//                 context,
//                 MaterialPageRoute(
//                   builder: (_) => ViewCompanyProfileScreen(profile: profile),
//                 ),
//               );
// }
            
            
//              else {
//               ScaffoldMessenger.of(context).showSnackBar(
//                 const SnackBar(content: Text('Unknown user type')),
//               );
//             }
//           });

//           return const Scaffold(
//             body: Center(child: CircularProgressIndicator()),
//           );
//         }

     
//         return const Scaffold(
//           body: Center(child: Text('No profile data available.')),
//         );
//       },
//     );
//   }
// }


import 'package:flutter/material.dart';
import 'package:uber_app/models/profile_model.dart';
import 'package:uber_app/screens/profile/view_driver_profile_screen.dart';
import 'package:uber_app/screens/profile/view_user_profile_screen.dart';
import 'package:uber_app/screens/profile/view_company_profile_screen.dart';
import 'package:uber_app/services/profile_services.dart';

class UserProfileLoaderScreen extends StatefulWidget {
  final String userId;

  const UserProfileLoaderScreen({Key? key, required this.userId})
      : super(key: key);

  @override
  State<UserProfileLoaderScreen> createState() =>
      _UserProfileLoaderScreenState();
}

class _UserProfileLoaderScreenState extends State<UserProfileLoaderScreen> {
  late Future<UserProfile> _profileFuture;
  final ProfileService _profileService = ProfileService();

  @override
  void initState() {
    super.initState();
    _profileFuture = _profileService.fetchUserProfile(widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserProfile>(
      future: _profileFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              "Failed to load profile: ${snapshot.error}",
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Center(child: Text("No profile data available"));
        }

        final profile = snapshot.data!;

        /// 👉 Return the correct screen INSIDE the bottom navigation
        if (profile.userType == UserType.user) {
          return ViewUserProfileScreen(profile: profile);
        } else if (profile.userType == UserType.driver) {
          return ViewDriverProfileScreen(profile: profile);
        } else if (profile.userType == UserType.company) {
          return ViewCompanyProfileScreen(profile: profile);
        }

        return const Center(child: Text("Unknown user type"));
      },
    );
  }
}
