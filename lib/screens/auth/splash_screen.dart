import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uber_app/screens/auth/login_screen.dart';
import 'package:uber_app/screens/auth/onboarding_screen.dart';

import 'package:uber_app/utils/app_colors.dart'; 

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
   
    Timer(const Duration(seconds: 3), () {
    
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) =>  OnboardingScreen()),
        
      );
    });
  }

  @override
  Widget build(BuildContext context) {
   
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.white, 
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 30.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10), 
              Row(
                children: [
                  Text(
                    'Truck',
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      color: AppColors.darkBlue,
                    ),
                  ),
                  Text(
                    'Cab',
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 50),

        
              Text(
                'Find the perfect\ntruck to haul your\nload',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  height: 1.2, 
                  color: AppColors.darkText,
                ),
              ),

              const SizedBox(height: 40),

              // 3. Truck Image
              Expanded(
                child: Center(
                  child: Image.asset(
                    'assets/images/truck.png',
                    fit: BoxFit.contain,
                    // Use a slightly smaller width than the screen to give it some padding
                    width: size.width * 0.9, 
                  ),
                ),
              ),
              
              // Spacing before button
              const SizedBox(height: 30),

              // 4. Custom Button (Row of widgets)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(4.0), // Padding to replicate button border
                decoration: BoxDecoration(
                  color: AppColors.lightBlue, // Light background/border
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Left Lock Icon
                    _buildIconCircle(AppColors.primaryBlue),
                    
                    // Center Text Button
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          // Allow immediate navigation on press
                           Navigator.of(context).pushReplacement(
                            MaterialPageRoute(builder: (_) =>  OnboardingScreen()),
                          );
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue, // Darker blue button fill
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          elevation: 0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Get Hauling',
                              style: TextStyle(
                                color: AppColors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              '>>>',
                              style: TextStyle(
                                color: AppColors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Right Lock Icon
                    _buildIconCircle(AppColors.primaryBlue),
                  ],
                ),
              ),
              const SizedBox(height: 10), // Spacing from bottom
            ],
          ),
        ),
      ),
    );
  }

  // Helper function for the lock icons
  Widget _buildIconCircle(Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.lightBlue, width: 4), // Replicate the border effect
      ),
      child: Icon(
        Icons.lock_open_rounded,
        color: color,
        size: 24,
      ),
    );
  }
}