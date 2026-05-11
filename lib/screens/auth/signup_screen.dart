import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:uber_app/screens/auth/forgot_password_screen.dart';
import 'package:uber_app/screens/auth/login_screen.dart';

import 'package:uber_app/screens/profile/company_profile_screen.dart';
import 'package:uber_app/screens/profile/create_driver_profile_screen.dart';
import 'package:uber_app/screens/profile/create_user_profile_screen.dart';
import 'package:uber_app/widgets/SignUpBackgroundPainter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

const Color primaryBlue = Color(0xFF4C66C3);


enum UserRole { driver, user, company }

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _agreedToTerms = false;
  final _formKey = GlobalKey<FormState>();
  UserRole? _selectedRole;
  bool _isSigningUp = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // --- NEW: Custom Error Dialog ---
  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
          title: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red, size: 28),
              SizedBox(width: 10),
              Text('Sign Up Error', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text(message, style: const TextStyle(fontSize: 16)),
          actions: <Widget>[
            TextButton(
              child: const Text('OK', style: TextStyle(color: primaryBlue, fontWeight: FontWeight.bold)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showSuccessDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User must tap button
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
          title: const Row(
            children: [
              Icon(Icons.check_circle_outline, color: Colors.green, size: 28),
              SizedBox(width: 10),
              Text('Sign Up Successful!', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
            ],
          ),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                  'Your account has been created successfully. ',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 5),
                Text(
                  'Please check your email for a verification link to activate your account.',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Continue', style: TextStyle(color: primaryBlue, fontWeight: FontWeight.bold)),
              onPressed: () {
                Navigator.of(context).pop(); // Dismiss success dialog
              },
            ),
          ],
        );
      },
    );
  }

  void _handleSignUp(BuildContext context) async {
    // Replaced SnackBar calls with Dialog calls
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      _showErrorDialog(context, 'Passwords do not match!');
      return;
    }
    if (_selectedRole == null) {
      _showErrorDialog(context, 'Please select your user role.');
      return;
    }
    if (!_agreedToTerms) {
      _showErrorDialog(context, 'You must agree to the terms and conditions.');
      return;
    }

    setState(() {
      _isSigningUp = true;
    });

    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final user = userCredential.user;
      if (user == null) {
        throw Exception("User was not created by Firebase Auth.");
      }

      // *** START: NEW REQUIREMENT: EMAIL VERIFICATION ***
      await user.sendEmailVerification();
      // *** END: NEW REQUIREMENT: EMAIL VERIFICATION ***

      final userId = user.uid;
      String roleName = _selectedRole.toString().split('.').last;

      // 1. Create a basic user record in 'users' collection with role (keyed by Auth UID)
      await _firestore.collection('users').doc(userId).set({
        'uid': userId,
        'email': _emailController.text.trim(),
        'fullName': _nameController.text.trim(),
        'role': roleName,
        'isVerified': false, // Add verification status
        'createdAt': FieldValue.serverTimestamp(),
      });

      setState(() {
        _isSigningUp = false;
      });

     
      await _showSuccessDialog(context); 
      Widget destinationScreen;

      if (_selectedRole == UserRole.driver) {
        destinationScreen = CreateDriverScreen(userId: userId, role: roleName);
      } else if (_selectedRole == UserRole.user) {
        destinationScreen = CreateUserScreen(userId: userId, role: roleName);
      } else if (_selectedRole == UserRole.company) {
        destinationScreen = CompanyProfileScreen(userId: userId, role: roleName);
      } else {
        _showErrorDialog(context, 'Account created, but role is invalid.');
        return;
      }

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => destinationScreen,
        ),
      );
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Sign up failed.';
      if (e.code == 'email-already-in-use') {
        errorMessage = 'The email address is already in use by another account.';
      } else if (e.code == 'weak-password') {
        errorMessage = 'The password provided is too weak.';
      } else {
        errorMessage = e.message ?? errorMessage;
      }
      _showErrorDialog(context, errorMessage); // *** REPLACED SNACKBAR WITH DIALOG ***
      setState(() {
        _isSigningUp = false;
      });
    } catch (e) {
      _showErrorDialog(
          context, 'An unexpected error occurred: ${e.toString()}'); // *** REPLACED SNACKBAR WITH DIALOG ***
      setState(() {
        _isSigningUp = false;
      });
    }
  }

 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: SignUpBackgroundPainter(
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
                Navigator.pop(context);
              },
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.75,
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
                      Text(
                        'Get Started',
                        textAlign: TextAlign.center,
                        style: Theme.of(
                          context,
                        ).textTheme.headlineSmall!.copyWith(color: primaryBlue),
                      ),
                      const SizedBox(height: 32.0),
                      _buildTextFormField(
                        context: context,
                        controller: _nameController,
                        labelText: 'Full Name',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16.0),
                      _buildTextFormField(
                        context: context,
                        controller: _emailController,
                        labelText: 'Email',
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                            return 'Enter a valid email address';
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
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16.0),
                      _buildTextFormField(
                        context: context,
                        controller: _confirmPasswordController,
                        labelText: 'Confirm Password',
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please confirm your password';
                          }
                          // Password matching check is handled in _handleSignUp
                          return null;
                        },
                      ),
                      const SizedBox(height: 16.0),
                      _buildRoleDropdown(context),
                      const SizedBox(height: 16.0),
                      _buildTermsCheckbox(context),
                      const SizedBox(height: 24.0),
                      _buildSignUpButton(context),
                      const SizedBox(height: 24.0),
                      Text(
                        'Sign up with',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 16.0),
                      _buildSocialIcons(context),
                      const SizedBox(height: 24.0),
                      _buildSignInText(context),
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

  // --- Utility Widgets (Unchanged) ---
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

  Widget _buildRoleDropdown(BuildContext context) {
    return DropdownButtonFormField<UserRole>(
      value: _selectedRole,
      style: Theme.of(context).textTheme.bodyLarge,
      dropdownColor: Theme.of(context).cardColor,
      decoration: InputDecoration(
        labelText: "Select Role",
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
      items: const [
        DropdownMenuItem(value: UserRole.driver, child: Text('Driver')),
        DropdownMenuItem(value: UserRole.user, child: Text('User')),
        DropdownMenuItem(value: UserRole.company, child: Text('Company')),
      ],
      onChanged: (UserRole? newValue) {
        setState(() {
          _selectedRole = newValue;
        });
      },
      validator: (value) {
        if (value == null) {
          return 'Please select a role';
        }
        return null;
      },
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
          'Signing Up...',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildSignUpButton(BuildContext context) {
    if (_isSigningUp) return _buildShimmerButton();

    return ElevatedButton(
      onPressed: _isSigningUp ? null : () => _handleSignUp(context),
      style: _buttonStyle(),
      child: _isSigningUp
          ? const SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),
            )
          : const Text(
              'Sign Up',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
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

  Widget _buildSignInText(BuildContext context) {
    return Column(
      children: [
        // Sign In Button
        TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
            );
          },
          child: Text.rich(
            TextSpan(
              text: 'Already have an account? ',
              style: Theme.of(context).textTheme.bodyMedium,
              children: [
                TextSpan(
                  text: 'Sign in',
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        color: primaryBlue,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTermsCheckbox(BuildContext context) {
    return Row(
      children: [
        Checkbox(
          value: _agreedToTerms,
          onChanged: (bool? newValue) {
            setState(() {
              _agreedToTerms = newValue!;
            });
          },
          activeColor: primaryBlue,
        ),
        Expanded(
          child: Text.rich(
            TextSpan(
              text: 'I agree to the processing of ',
              style: Theme.of(context).textTheme.bodyMedium,
              children: [
                TextSpan(
                  text: 'Personal data',
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        color: primaryBlue,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}


// enum UserRole { driver, user, company }

// class SignUpScreen extends StatefulWidget {
//   const SignUpScreen({super.key});

//   @override
//   State<SignUpScreen> createState() => _SignUpScreenState();
// }

// class _SignUpScreenState extends State<SignUpScreen> {
//   final _nameController = TextEditingController();
//   final _emailController = TextEditingController();
//   final _passwordController = TextEditingController();
//   final _confirmPasswordController = TextEditingController();
//   bool _agreedToTerms = false;
//   final _formKey = GlobalKey<FormState>();
//   UserRole? _selectedRole;
//   bool _isSigningUp = false;
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
// @override
//   void dispose() {
//     _nameController.dispose();
//     _emailController.dispose();
//     _passwordController.dispose();
//     _confirmPasswordController.dispose();
//     super.dispose();
//   }

//   void _handleSignUp(BuildContext context) async {

//     if (!_formKey.currentState!.validate()) {
//       return;
//     }

//     if (_passwordController.text != _confirmPasswordController.text) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//             content: Text('Passwords do not match!'),
//             backgroundColor: Colors.red),
//       );
//       return;
//     }

//     if (_selectedRole == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//             content: Text('Please select your user role.'),
//             backgroundColor: Colors.red),
//       );
//       return;
//     }

//     if (!_agreedToTerms) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//             content: Text('You must agree to the terms and conditions.'),
//             backgroundColor: Colors.red),
//       );
//       return;
//     }

//   setState(() {
//       _isSigningUp = true;
//     });

//    try {
//     final userCredential = await _auth.createUserWithEmailAndPassword(
//       email: _emailController.text.trim(),
//       password: _passwordController.text.trim(),
//     );

//     final user = userCredential.user;
//     if (user == null) {
//       throw Exception("User was not created by Firebase Auth.");
//     }
    
//     final userId = user.uid; // Key: Get the Auth User ID
//     String roleName = _selectedRole.toString().split('.').last;
    
//     // 1. Create a basic user record in 'users' collection with role (keyed by Auth UID)
//     await _firestore.collection('users').doc(userId).set({
//       'uid': userId,
//       'email': _emailController.text.trim(),
//       'fullName': _nameController.text.trim(),
//       'role': roleName,
//       'createdAt': FieldValue.serverTimestamp(),
//     });

//     setState(() {
//       _isSigningUp = false;
//     });

//     // 2. KEY CHANGE: Direct, role-based navigation to profile setup
//     Widget destinationScreen;

//     if (_selectedRole == UserRole.driver) {
//       destinationScreen = CreateDriverScreen(userId: userId, role: roleName);
//     } else if (_selectedRole == UserRole.user) {
//       destinationScreen = CreateUserScreen(userId: userId, role: roleName);
//     } else if (_selectedRole == UserRole.company) {
//       destinationScreen = CompanyProfileScreen(userId: userId, role: roleName);
//     } else {
//       // Fallback or error if role is somehow missing
//       _showErrorSnackbar(context, 'Account created, but role is invalid.');
//       return; 
//     }
    
//     // Use pushReplacement to prevent returning to the sign-up screen
//     Navigator.of(context).pushReplacement(
//       MaterialPageRoute(
//         builder: (context) => destinationScreen,
//       ),
//     );

//   } on FirebaseAuthException catch (e) {
//     // ... (Error handling remains the same) ...
//     _showErrorSnackbar(context, e.toString());
//     setState(() {
//       _isSigningUp = false; 
//     });
//   } catch (e) {
//     // ... (General error handling remains the same) ...
//     _showErrorSnackbar(context, 'An unexpected error occurred: ${e.toString()}');
//     setState(() {
//       _isSigningUp = false; 
//     });
//   }
// }



// void _showErrorSnackbar(BuildContext context, String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text(message), backgroundColor: Colors.red),
//     );
//   }
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: Stack(
//         children: [
  
//           Positioned.fill(
//             child: CustomPaint(
//               painter: SignUpBackgroundPainter(
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
//                 Navigator.pop(context);
//               },
//             ),
//           ),
        
//           Align(
//             alignment: Alignment.bottomCenter,
//             child: Container(
//               height: MediaQuery.of(context).size.height * 0.75,
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
//                       Text(
//                         'Get Started',
//                         textAlign: TextAlign.center,
//                         style: Theme.of(
//                           context,
//                         ).textTheme.headlineSmall!.copyWith(color: primaryBlue),
//                       ),
//                       const SizedBox(height: 32.0),
                
//                       _buildTextFormField(
//                         context: context,
//                         controller: _nameController,
//                         labelText: 'Full Name',
//                         validator: (value) {
//                           if (value == null || value.isEmpty) {
//                             return 'Please enter your name';
//                           }
//                           return null;
//                         },
//                       ),
//                       const SizedBox(height: 16.0),
                    
//                       _buildTextFormField(
//                         context: context,
//                         controller: _emailController,
//                         labelText: 'Email',
//                         keyboardType: TextInputType.emailAddress,
//                         validator: (value) {
//                           if (value == null || value.isEmpty) {
//                             return 'Please enter your email';
//                           }
                     
//                           if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
//                             return 'Enter a valid email address';
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
//                           if (value.length < 6) {
//                             return 'Password must be at least 6 characters';
//                           }
//                           return null;
//                         },
//                       ),
//                       const SizedBox(height: 16.0),
                      
//                       _buildTextFormField(
//                         context: context,
//                         controller: _confirmPasswordController,
//                         labelText: 'Confirm Password',
//                         obscureText: true,
//                         validator: (value) {
//                           if (value == null || value.isEmpty) {
//                             return 'Please confirm your password';
//                           }
                       
//                           return null;
//                         },
//                       ),
//                       const SizedBox(height: 16.0),

//                       _buildRoleDropdown(context),

//                       const SizedBox(height: 16.0),
                  
//                       _buildTermsCheckbox(context),
//                       const SizedBox(height: 24.0),

                    
//                       _buildSignUpButton(context),
//                       const SizedBox(height: 24.0),

//                       Text(
//                         'Sign up with',
//                         textAlign: TextAlign.center,
//                         style: Theme.of(context).textTheme.bodyMedium,
//                       ),
//                       const SizedBox(height: 16.0),
//                       _buildSocialIcons(context),
//                       const SizedBox(height: 24.0),
//                       _buildSignInText(context),
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



//   Widget _buildTextFormField({
//     required BuildContext context,
//     required TextEditingController controller,
//     required String labelText,
//     TextInputType keyboardType = TextInputType.text,
//     bool obscureText = false,
//     String? Function(String?)? validator,
//   }) {
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

//   Widget _buildRoleDropdown(BuildContext context) {
//     return DropdownButtonFormField<UserRole>(
//       value: _selectedRole,
//       style: Theme.of(context).textTheme.bodyLarge,
//       dropdownColor: Theme.of(context).cardColor,
//       decoration: InputDecoration(
//         labelText: "Select Role",
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
//       items: const [
//         DropdownMenuItem(value: UserRole.driver, child: Text('Driver')),
//         DropdownMenuItem(value: UserRole.user, child: Text('User')),
//         // --- FIXED BUG: Changed value from UserRole.user to UserRole.company ---
//         DropdownMenuItem(value: UserRole.company, child: Text('Company')),
//         // ----------------------------------------------------------------------
//       ],
//       onChanged: (UserRole? newValue) {
//         setState(() {
//           _selectedRole = newValue;
//         });
//       },
//       validator: (value) {
//         if (value == null) {
//           return 'Please select a role';
//         }
//         return null;
//       },
//     );
//   }

//   Widget _buildShimmerButton() {
//     return Shimmer.fromColors(
//       baseColor: primaryBlue.withOpacity(0.3),
//       highlightColor: Colors.white.withOpacity(0.1),
//       child: ElevatedButton(
//         onPressed: null,
//         style: _buttonStyle(),
//         child: const Text(
//           'Signing Up...',
//           style: TextStyle(color: Colors.white),
//         ),
//       ),
//     );
//   }

//   Widget _buildSignUpButton(BuildContext context) {
//     if (_isSigningUp) return _buildShimmerButton();

//     return ElevatedButton(
//       onPressed: _isSigningUp ? null : () => _handleSignUp(context),
//       style: _buttonStyle(),
//       child: _isSigningUp
//           ? const SizedBox(
//               height: 24,
//               width: 24,
//               child: CircularProgressIndicator(
//                 color: Colors.white,
//                 strokeWidth: 3,
//               ),
//             )
//           : const Text(
//               'Sign Up',
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.white,
//               ),
//             ),
//     );
//   }

//   ButtonStyle _buttonStyle() {
//     return ElevatedButton.styleFrom(
//       backgroundColor: primaryBlue,
//       padding: const EdgeInsets.symmetric(vertical: 16.0),
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.0)),
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

//   Widget _buildSignInText(BuildContext context) {
//     return TextButton(
//       onPressed: () {
//         Navigator.push(
//           context,
//           MaterialPageRoute(builder: (context) => const LoginScreen()),
//         );
//       },
//       child: Text.rich(
//         TextSpan(
//           text: 'Already have an account? ',
//           style: Theme.of(context).textTheme.bodyMedium,
//           children: [
//             TextSpan(
//               text: 'Sign in',
//               style: Theme.of(context).textTheme.bodyMedium!.copyWith(
//                     color: primaryBlue,
//                     fontWeight: FontWeight.bold,
//                   ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildTermsCheckbox(BuildContext context) {
//     return Row(
//       children: [
//         Checkbox(
//           value: _agreedToTerms,
//           onChanged: (bool? newValue) {
//             setState(() {
//               _agreedToTerms = newValue!;
//             });
//           },
//           activeColor: primaryBlue,
//         ),
//         Expanded(
//           child: Text.rich(
//             TextSpan(
//               text: 'I agree to the processing of ',
//               style: Theme.of(context).textTheme.bodyMedium,
//               children: [
//                 TextSpan(
//                   text: 'Personal data',
//                   style: Theme.of(context).textTheme.bodyMedium!.copyWith(
//                         color: primaryBlue,
//                         fontWeight: FontWeight.bold,
//                       ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ],
//     );
//   }

// }

