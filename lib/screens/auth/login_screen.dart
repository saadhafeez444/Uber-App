import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:uber_app/models/profile_model.dart';
import 'package:uber_app/screens/auth/forgot_password_screen.dart';
import 'package:uber_app/screens/auth/signup_screen.dart';
import 'package:uber_app/screens/home/navigation_screen.dart';
import 'package:uber_app/screens/user_module/user_module_firebase.dart';
import 'package:uber_app/services/preference_service.dart';
import 'package:uber_app/widgets/LoginBackgroundPainter.dart';

const Color primaryBlue = Color(0xFF4C66C3);

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoggingIn = false;
  UserRole? _selectedRole;

  void _showErrorSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  // New function to show the attractive verification error dialog
  void _showVerificationErrorDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true, // Allow dismissal by tapping outside
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          elevation: 10.0,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(
                  Icons.lock_person_outlined,
                  color: Colors.red,
                  size: 60,
                ),
                const SizedBox(height: 16.0),
                const Text(
                  'Verification Required',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: primaryBlue,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8.0),
                Text(
                  'Your email address (${_emailController.text.trim()}) has not been verified yet.',
                  style: const TextStyle(fontSize: 16, color: Colors.black54),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8.0),
                const Text(
                  'Please check your inbox (and spam folder) for the verification link.',
                  style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24.0),
                // Re-send Verification Button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                  ),
                  onPressed: () async {
                    Navigator.of(dialogContext).pop(); // Close dialog first
                    await FirebaseAuth.instance.currentUser
                        ?.sendEmailVerification();
                    _showErrorSnackbar(
                      context,
                      'Verification email re-sent! Check your inbox.',
                    );
                  },
                  child: const Text(
                    'Re-send Email',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8.0),
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text(
                    'Close',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  // You'll need to import your PreferenceService here
// import 'path_to_your_preference_service.dart';

Future<void> _handleLogin(BuildContext context) async {
  if (!_formKey.currentState!.validate()) return;

  setState(() {
    _isLoggingIn = true;
  });
  // 
  try {
    final userCredential = await _auth.signInWithEmailAndPassword(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );

    final user = userCredential.user;
    if (user == null) {
      throw Exception("Authentication failed, user is null.");
    }

    await user.reload();
    final reloadedUser = _auth.currentUser;
    if (reloadedUser != null && !reloadedUser.emailVerified) {
      // 1. Clear SharedPreferences state first
      await PreferenceService.clearPreferences(); 
      await _auth.signOut();
      if (mounted) {
        _showVerificationErrorDialog(context);
      }
      return;
    }

    final userDoc = await _firestore
        .collection('profiles')
        .doc(user.uid)
        .get();

    if (!userDoc.exists) {
      throw Exception(
        "User profile data not found in 'profiles' collection.",
      );
    }

    final data = userDoc.data()!;
    final String userType = data['userType'];

    // *** NEW: Save login state and user details to SharedPreferences ***
    await PreferenceService.setLoggedIn(true);
    await PreferenceService.setUserDetails(user.uid, userType);
    // ******************************************************************

    Widget destinationScreen;

    if (userType == 'driver') {
      destinationScreen = NavigationScreen(userId: user.uid);
    } else if (userType == 'user') {
      destinationScreen = TruckDeliveryApp(userId: user.uid);
    } else if (userType == 'company') {
      destinationScreen = TruckDeliveryApp(userId: user.uid);
    } else {
      throw Exception("Invalid user type: $userType");
    }

    _showLoginSuccessDialog(context, 'You have successfully logged in!');

    Future.delayed(const Duration(milliseconds: 1500), () {
      Navigator.of(context, rootNavigator: true).pop();

      // We no longer need to navigate here, the main.dart handles it after the app restarts/is opened.
      // However, for immediate navigation after login, we'll keep this:
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => destinationScreen));
    });
  } on FirebaseAuthException catch (e) {
    String errorMessage = 'Login Failed: Invalid credentials.';
    if (e.code == 'user-not-found' || e.code == 'wrong-password') {
      errorMessage = 'Invalid email or password.';
    } else if (e.code == 'invalid-email') {
      errorMessage = 'The email address is not valid.';
    }
    _showErrorSnackbar(context, errorMessage);
  } catch (e) {
    _showErrorSnackbar(
      context,
      'An unexpected error occurred: ${e.toString()}',
    );
  } finally {
    if (mounted) {
      setState(() {
        _isLoggingIn = false;
      });
    }
  }
}

  // Future<void> _handleLogin(BuildContext context) async {
  //   if (!_formKey.currentState!.validate()) return;

  //   setState(() {
  //     _isLoggingIn = true;
  //   });

  //   try {
  //     final userCredential = await _auth.signInWithEmailAndPassword(
  //       email: _emailController.text.trim(),
  //       password: _passwordController.text.trim(),
  //     );

  //     final user = userCredential.user;
  //     if (user == null) {
  //       throw Exception("Authentication failed, user is null.");
  //     }

  //     await user.reload();
  //     final reloadedUser = _auth.currentUser;
  //     if (reloadedUser != null && !reloadedUser.emailVerified) {
  //       await _auth.signOut();
  //       if (mounted) {
  //         _showVerificationErrorDialog(context);
  //       }
  //       return;
  //     }

  //     final userDoc = await _firestore
  //         .collection('profiles')
  //         .doc(user.uid)
  //         .get();

  //     if (!userDoc.exists) {
  //       throw Exception(
  //         "User profile data not found in 'profiles' collection.",
  //       );
  //     }

  //     final data = userDoc.data()!;
  //     final String userType = data['userType'];

  //     Widget destinationScreen;

  //     if (userType == 'driver') {
  //       destinationScreen = NavigationScreen(userId: user.uid,);
  //     } else if (userType == 'user') {
  //       destinationScreen = TruckDeliveryApp(userId: user.uid);
  //     } else if (userType == 'company') {
  //       destinationScreen = TruckDeliveryApp(userId: user.uid);
  //     } else {
  //       throw Exception("Invalid user type: $userType");
  //     }

  //     _showLoginSuccessDialog(context, 'You have successfully logged in!');

  //     Future.delayed(const Duration(milliseconds: 1500), () {
  //       Navigator.of(context, rootNavigator: true).pop();

  //       Navigator.of(
  //         context,
  //       ).pushReplacement(MaterialPageRoute(builder: (_) => destinationScreen));
  //     });
  //   } on FirebaseAuthException catch (e) {
  //     String errorMessage = 'Login Failed: Invalid credentials.';
  //     if (e.code == 'user-not-found' || e.code == 'wrong-password') {
  //       errorMessage = 'Invalid email or password.';
  //     } else if (e.code == 'invalid-email') {
  //       errorMessage = 'The email address is not valid.';
  //     }
  //     _showErrorSnackbar(context, errorMessage);
  //   } catch (e) {
  //     _showErrorSnackbar(
  //       context,
  //       'An unexpected error occurred: ${e.toString()}',
  //     );
  //   } finally {
  //     if (mounted) {
  //       setState(() {
  //         _isLoggingIn = false;
  //       });
  //     }
  //   }
  // }




  void _showLoginSuccessDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          elevation: 10.0,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(
                  Icons.check_circle_outline,
                  color: Colors.green,
                  size: 60,
                ),
                const SizedBox(height: 16.0),
                Text(
                  _emailController.text,
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 8.0),
                const Text(
                  'Welcome Back!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: primaryBlue,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8.0),
                Text(
                  message,
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30.0),
                          side: const BorderSide(color: primaryBlue),
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                      },
                      child: const Text(
                        'Close',
                        style: TextStyle(
                          color: primaryBlue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30.0),
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                      },
                      child: const Text(
                        'Continue',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: LoginBackgroundPainter(
                mainWaveColor: const Color(0xFF4C66C3),
                circleColor: const Color(0xFF6B8BCC),
                lightColor: const Color(0xFFEAEAEA),
              ),
            ),
          ),
          Positioned(
            top: 50,
            left: 20,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.6,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30.0),
                  topRight: Radius.circular(30.0),
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      const Text(
                        'Welcome Back!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 28,
                        ),
                      ),
                      const SizedBox(height: 32.0),
                      _buildTextFormField(
                        context: context,
                        controller: _emailController,
                        labelText: 'Email',
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16.0),
                      _buildTextFormField(
                        context: context,
                        controller: _passwordController,
                        labelText: 'Password',
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a password';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16.0),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const ForgotPasswordScreen(),
                              ),
                            );
                          },
                          child: const Text(
                            'Forgot Password?',
                            style: TextStyle(color: primaryBlue),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24.0),
                      _buildLoginButton(context),
                      const SizedBox(height: 24.0),
                      Text(
                        'Or login with',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 16.0),
                      _buildSocialIcons(context),
                      const SizedBox(height: 24.0),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (context) => const SignUpScreen(),
                            ),
                          );
                        },
                        child: Text.rich(
                          TextSpan(
                            text: 'Don\'t have an account? ',
                            style: Theme.of(context).textTheme.bodyMedium,
                            children: [
                              TextSpan(
                                text: 'Sign up',
                                style: Theme.of(context).textTheme.bodyMedium!
                                    .copyWith(
                                      color: primaryBlue,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Helper Widgets (Unchanged) ---
  Widget _buildTextFormField({
    required BuildContext context,
    required TextEditingController controller,
    required String labelText,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: Theme.of(context).textTheme.bodyLarge,
      decoration: InputDecoration(
        hintText: 'Enter $labelText',
        hintStyle: Theme.of(context).inputDecorationTheme.hintStyle,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 15,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30.0),
          borderSide: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1.0,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30.0),
          borderSide: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1.0,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30.0),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.secondary,
            width: 2.0,
          ),
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildLoginButton(BuildContext context) {
    return _isLoggingIn
        ? _buildShimmerButton()
        : ElevatedButton(
            onPressed: _isLoggingIn ? null : () => _handleLogin(context),
            style: _buttonStyle(),
            child: const Text(
              'Login',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          );
  }

  Widget _buildShimmerButton() {
    return Shimmer.fromColors(
      baseColor: primaryBlue.withOpacity(0.3),
      highlightColor: Colors.white.withOpacity(0.1),
      child: ElevatedButton(
        onPressed: null,
        style: _buttonStyle(),
        child: const Text(
          'Logging In...',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  ButtonStyle _buttonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: primaryBlue,
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.0)),
      elevation: 5,
    );
  }

  Widget _buildSocialIcons(BuildContext context) {
    final iconColor = Theme.of(context).textTheme.bodyLarge!.color;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildSocialIcon(
          const Icon(Icons.facebook, color: Colors.blue, size: 40),
          context,
        ),
        _buildSocialIcon(
          Icon(Icons.apple, color: iconColor, size: 40),
          context,
        ),
        _buildSocialIcon(
          const Icon(Icons.g_mobiledata, color: Colors.red, size: 40),
          context,
        ),
        _buildSocialIcon(
          const Icon(Icons.flutter_dash, color: Colors.lightBlue, size: 40),
          context,
        ),
      ],
    );
  }

  Widget _buildSocialIcon(Widget icon, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: Container(
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).dividerColor),
          shape: BoxShape.circle,
        ),
        child: icon,
      ),
    );
  }
}

// class LoginScreen extends StatefulWidget {
//   const LoginScreen({super.key});

//   @override
//   State<LoginScreen> createState() => _LoginScreenState();
// }

// class _LoginScreenState extends State<LoginScreen> {



//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
//   final _emailController = TextEditingController();
//   final _passwordController = TextEditingController();
//   final _formKey = GlobalKey<FormState>();
//   bool _isLoggingIn = false;


//   void _showErrorSnackbar(BuildContext context, String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: Colors.red,
//       ),
//     );
//   }


//   Future<void> _handleLogin(BuildContext context) async {
//     if (!_formKey.currentState!.validate()) {
//       return;
//     }

//     setState(() {
//       _isLoggingIn = true;
//     });

//     try {

//       final userCredential = await _auth.signInWithEmailAndPassword(
//         email: _emailController.text.trim(),
//         password: _passwordController.text.trim(),
//       );

//       final user = userCredential.user;
//       if (user == null) {
//         throw Exception("Authentication failed, user is null.");
//       }

//      final userDoc = await _firestore.collection('profiles').doc(user.uid).get();
//       if (!userDoc.exists) {
//         throw Exception("User profile data not found in Firestore.");
//       }
//       final userProfile = UserProfile.fromMap(userDoc.data()!,);

//       _showLoginSuccessDialog(context, 'You have successfully logged in!');

//       Future.delayed(const Duration(milliseconds: 1500), () {

//         Navigator.of(context, rootNavigator: true).pop();
        
//         Navigator.of(context).pushReplacement(
//           MaterialPageRoute(
//             // builder: (context) => UserProfileLoaderScreen(userId: user.uid,),
//              builder: (context) => TruckDeliveryApp(userId: user.uid,),
//           ),
//         );
//       });
      
//     } on FirebaseAuthException catch (e) {
//       String errorMessage = 'Login Failed: Invalid credentials.';
//       if (e.code == 'user-not-found' || e.code == 'wrong-password') {
//          errorMessage = 'Invalid email or password.';
//       } else if (e.code == 'invalid-email') {
//          errorMessage = 'The email address is not valid.';
//       }
//       _showErrorSnackbar(context, errorMessage);
      
//     } catch (e) {
      
//       _showErrorSnackbar(context, 'An unexpected error occurred: ${e.toString()}');
//     } finally {

//       if(mounted) {
//         setState(() {
//           _isLoggingIn = false;
//         });
//       }
//     }
//   }
  



//   void _showLoginSuccessDialog(BuildContext context, String message) {
    
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (BuildContext dialogContext) {
//         return Dialog(
//           backgroundColor: Colors.white,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(20.0),
//           ),
//           elevation: 10.0,
//           child: Padding(
//             padding: const EdgeInsets.all(24.0),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: <Widget>[
//                 const Icon(
//                   Icons.check_circle_outline,
//                   color: Colors.green,
//                   size: 60,
//                 ),
//                 const SizedBox(height: 16.0),
//                 Text(
//                   _emailController.text,
//                   style: const TextStyle(fontSize: 16, color: Colors.grey),
//                 ),
//                 const SizedBox(height: 8.0),
//                 const Text(
//                   'Welcome Back!',
//                   style: TextStyle(
//                     fontSize: 20,
//                     fontWeight: FontWeight.bold,
//                     color: primaryBlue,
//                   ),
//                   textAlign: TextAlign.center,
//                 ),
//                 const SizedBox(height: 8.0),
//                 Text(
//                   message,
//                   style: const TextStyle(fontSize: 16),
//                   textAlign: TextAlign.center,
//                 ),
//                 const SizedBox(height: 24.0),
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                   children: [
//                     TextButton(
//                       style: TextButton.styleFrom(
//                         padding: const EdgeInsets.symmetric(
//                           horizontal: 20,
//                           vertical: 10,
//                         ),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(30.0),
//                           side: const BorderSide(color: primaryBlue),
//                         ),
//                       ),
//                       onPressed: () {
//                         Navigator.of(dialogContext).pop();
//                       },
//                       child: const Text(
//                         'Close',
//                         style: TextStyle(
//                           color: primaryBlue,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                     ),
//                     ElevatedButton(
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: primaryBlue,
//                         padding: const EdgeInsets.symmetric(
//                           horizontal: 20,
//                           vertical: 10,
//                         ),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(30.0),
//                         ),
//                       ),
                    
//                       onPressed: () {
                     
//                          Navigator.of(dialogContext).pop();
//                       }, 
//                       child: const Text(
//                         'Continue',
//                         style: TextStyle(
//                           color: Colors.white,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }

//   @override
//   void dispose() {
//     _emailController.dispose();
//     _passwordController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {

//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: Stack(
//         children: [
//           Positioned.fill(
//             child: CustomPaint(
//               painter: LoginBackgroundPainter(
//                 mainWaveColor: const Color(0xFF4C66C3),
//                 circleColor: const Color(0xFF6B8BCC),
//                 lightColor: const Color(0xFFEAEAEA),
//               ),
//             ),
//           ),
//           Positioned(
//             top: 50,
//             left: 20,
//             child: IconButton(
//               icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
//               onPressed: () {
//                 Navigator.of(context).pop();
//               },
//             ),
//           ),

//           Align(
//             alignment: Alignment.bottomCenter,
//             child: Container(
//               height: MediaQuery.of(context).size.height * 0.6,
//               decoration: const BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.only(
//                   topLeft: Radius.circular(30.0),
//                   topRight: Radius.circular(30.0),
//                 ),
//               ),
//               child: SingleChildScrollView(
//                 padding: const EdgeInsets.all(24.0),
//                 child: Form(
//                   key: _formKey,
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.stretch,
//                     children: <Widget>[
//                       const Text(
//                         'Welcome Back!',
//                         textAlign: TextAlign.center,
//                         style: TextStyle(
//                             fontWeight: FontWeight.bold, fontSize: 28),
//                       ),
//                       const SizedBox(height: 32.0),
//                       _buildTextFormField(
//                         context: context,
//                         controller: _emailController,
//                         labelText: 'Email',
//                         keyboardType: TextInputType.emailAddress,
//                         validator: (value) {
//                           if (value == null || value.isEmpty) {
//                             return 'Please enter your email';
//                           }
//                           return null;
//                         },
//                       ),
//                       const SizedBox(height: 16.0),
//                       _buildTextFormField(
//                         context: context,
//                         controller: _passwordController,
//                         labelText: 'Password',
//                         obscureText: true,
//                         validator: (value) {
//                           if (value == null || value.isEmpty) {
//                             return 'Please enter a password';
//                           }
//                           return null;
//                         },
//                       ),
//                       const SizedBox(height: 16.0),
//                       Align(
//                         alignment: Alignment.centerRight,
//                         child: TextButton(
//                           onPressed: () {
//                              Navigator.push(
//               context,
//               MaterialPageRoute(
//                   builder: (context) => const ForgotPasswordScreen()),
//             );
//                           },
//                           child: const Text(
//                             'Forgot Password?',
//                             style: TextStyle(color: Colors.blue),
//                           ),
//                         ),
//                       ),
//                       const SizedBox(height: 24.0),
//                       _buildLoginButton(context),
//                       const SizedBox(height: 24.0),
//                       Text(
//                         'Or login with',
//                         textAlign: TextAlign.center,
//                         style: Theme.of(context).textTheme.bodyMedium,
//                       ),
//                       const SizedBox(height: 16.0),
//                       _buildSocialIcons(context),
//                       const SizedBox(height: 24.0),
//                       TextButton(
//                         onPressed: () {
//                           Navigator.of(context).pushReplacement(
//                             MaterialPageRoute(
//                               builder: (context) => const SignUpScreen(),
//                             ),
//                           );
//                         },
//                         child: Text.rich(
//                           TextSpan(
//                             text: 'Don\'t have an account? ',
//                             style: Theme.of(context).textTheme.bodyMedium,
//                             children: [
//                               TextSpan(
//                                 text: 'Sign up',
//                                 style: Theme.of(context).textTheme.bodyMedium!
//                                     .copyWith(
//                                       color: Colors.blue,
//                                       fontWeight: FontWeight.bold,
//                                     ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // --- Helper Widgets (Unchanged) ---
//   Widget _buildTextFormField({
//     required BuildContext context,
//     required TextEditingController controller,
//     required String labelText,
//     TextInputType keyboardType = TextInputType.text,
//     bool obscureText = false,
//     String? Function(String?)? validator,
//   }) {
//     // ... (Your existing _buildTextFormField implementation)
//     return TextFormField(
//       controller: controller,
//       obscureText: obscureText,
//       keyboardType: keyboardType,
//       style: Theme.of(context).textTheme.bodyLarge,
//       decoration: InputDecoration(
//         hintText: 'Enter $labelText',
//         hintStyle: Theme.of(context).inputDecorationTheme.hintStyle,
//         contentPadding: const EdgeInsets.symmetric(
//           horizontal: 20,
//           vertical: 15,
//         ),
//         border: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(30.0),
//           borderSide: BorderSide(
//             color: Theme.of(context).dividerColor,
//             width: 1.0,
//           ),
//         ),
//         enabledBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(30.0),
//           borderSide: BorderSide(
//             color: Theme.of(context).dividerColor,
//             width: 1.0,
//           ),
//         ),
//         focusedBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(30.0),
//           borderSide: BorderSide(
//             color: Theme.of(context).colorScheme.secondary,
//             width: 2.0,
//           ),
//         ),
//       ),
//       validator: validator,
//     );
//   }

//   Widget _buildLoginButton(BuildContext context) {
//     return _isLoggingIn
//         ? _buildShimmerButton()
//         : ElevatedButton(
            
//             onPressed: _handleLogin == null ? null : () => _handleLogin(context), 
//             style: _buttonStyle(),
//             child: const Text(
//               'Login',
//               style: TextStyle(
//                 color: Colors.white,
//                 fontWeight: FontWeight.bold,
//                 fontSize: 18,
//               ),
//             ),
//           );
//   }

//   Widget _buildShimmerButton() {
//     return Shimmer.fromColors(
//       baseColor: primaryBlue.withOpacity(0.3),
//       highlightColor: Colors.white.withOpacity(0.1),
//       child: ElevatedButton(
//         onPressed: null, 
//         style: _buttonStyle(),
//         child: const Text(
//           'Logging In...',
//           style: TextStyle(color: Colors.white),
//         ),
//       ),
//     );
//   }

//   ButtonStyle _buttonStyle() {
//     return ElevatedButton.styleFrom(
//       backgroundColor: primaryBlue,
//       padding: const EdgeInsets.symmetric(vertical: 16.0),
//       shape:
//           RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.0)),
//       elevation: 5,
//     );
//   }

//   Widget _buildSocialIcons(BuildContext context) {
//     final iconColor = Theme.of(context).textTheme.bodyLarge!.color;
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.center,
//       children: [
//         _buildSocialIcon(
//           const Icon(Icons.facebook, color: Colors.blue, size: 40),
//           context,
//         ),
//         _buildSocialIcon(
//           Icon(Icons.apple, color: iconColor, size: 40),
//           context,
//         ),
//         _buildSocialIcon(
//           const Icon(Icons.g_mobiledata, color: Colors.red, size: 40),
//           context,
//         ),
//         _buildSocialIcon(
//           const Icon(Icons.flutter_dash, color: Colors.lightBlue, size: 40),
//           context,
//         ),
//       ],
//     );
//   }

//   Widget _buildSocialIcon(Widget icon, BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 10.0),
//       child: Container(
//         padding: const EdgeInsets.all(8.0),
//         decoration: BoxDecoration(
//           border: Border.all(color: Theme.of(context).dividerColor),
//           shape: BoxShape.circle,
//         ),
//         child: icon,
//       ),
//     );
//   }
// }