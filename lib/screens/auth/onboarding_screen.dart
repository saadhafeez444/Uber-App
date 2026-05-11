import 'dart:async';

import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:uber_app/models/onboarding_model.dart';
import 'package:uber_app/screens/auth/login_screen.dart';
import 'package:uber_app/widgets/onboarding_page_widget.dart';


class OnboardingScreen extends StatefulWidget {
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  PageController pageController = PageController();
  int _currentIndex = 0;
  Timer? _autoScrollTimer;
  bool _isScrollingPaused = false;
  bool _isScrollingForward = true;

List<ModelClass> onBoardingData = [
 
  ModelClass(
    image: 'assets/images/onboarding_1 copy.png',
    name: 'Welcome to TruckCab!',

    description:
      'Discover and book highly skilled, trusted artisans for every corner of your home — whether it’s fixing a leak, installing new fixtures, painting walls, or carrying out full renovations. Kariger makes it simple, fast, and reliable to get the job done right, every time.',
  ),

 
  ModelClass(
    image: 'assets/images/onboarding_2.png',
    name: 'Verified Drivers, Secure Routes',
    
    description:
      'Every driver on TruckCab is carefully vetted, background-checked, and rated by real cargo owners. You can hire with complete confidence, knowing your shipment is in the hands of top-tier logistics professionals who value safety and timely delivery.'
  ),
  ModelClass(
    image: 'assets/images/onboarding_3.png',
    name: 'Instant Quotes & Real-time Tracking', 

    description:
      '''Booking your haul has never been easier — select your cargo type, compare instant quotes from verified haulers, and confirm in just a few clicks. Track your truck's journey in real time and enjoy a transparent, stress-free shipping experience from pickup to drop-off.''', 
  ),

  
  ModelClass(
    image: 'assets/images/onboarding_4.png',
    name: 'Secured Payments & 24/7 Support', 

    description:
      '''Finalizing your transaction is fast and secure — choose from various payment methods and receive immediate confirmation. Our dedicated logistics support team is available around the clock to assist with any questions, ensuring a smooth delivery process every mile of the way.''', 
  ),
];
 
  @override
  void initState() {
    super.initState();
    pageController.addListener(() {
      setState(() {
        _currentIndex = pageController.page?.round() ?? 0;
      });
    });
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _autoScrollTimer = Timer.periodic(Duration(seconds: 3), (timer) {
      if (!_isScrollingPaused) {
        int nextPage;
        if (_isScrollingForward) {
          nextPage = _currentIndex + 1;
          if (nextPage >= onBoardingData.length) {
           
            nextPage = onBoardingData.length - 1;
            _isScrollingForward = false;
          }
        } else {
          nextPage = _currentIndex - 1;
          if (nextPage < 0) {
         
            nextPage = 0;
            _isScrollingForward = true;
          }
        }
        pageController.animateToPage(
          nextPage,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeIn,
        );
      }
    });
  }

  void _pauseAutoScroll() {
    setState(() {
      _isScrollingPaused = true;
    });
    _autoScrollTimer?.cancel();
  }

  void _resumeAutoScroll() {
    setState(() {
      _isScrollingPaused = false;
    });
    _startAutoScroll();
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _currentIndex == 0
          ? AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => LoginScreen()),
                    );
                  },
                  child: Text(
                    'Skip',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: primaryBlue,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            )
          : AppBar(
              backgroundColor: Colors.white,
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => LoginScreen()),
                    );
                  },
                  child: Text(
                    'Skip',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: primaryBlue,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
              leading: Padding(
                padding: EdgeInsets.only(left: 20),
                child: IconButton(
                  onPressed: () {
                    pageController.previousPage(
                      duration: Duration(milliseconds: 300),
                      curve: Curves.easeIn,
                    );
                  },
                  icon: Icon(Icons.arrow_back, color: primaryBlue),
                ),
              ),
            ),
      body: GestureDetector(
        onTap: () {
          if (_isScrollingPaused) {
            _resumeAutoScroll();
          } else {
            _pauseAutoScroll();
          }
        },
        child: _getBody(context),
      ),
    );
  }

  Widget _getBody(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: PageView.builder(
            itemCount: onBoardingData.length,
            controller: pageController,
            itemBuilder: (context, index) {
              return ModelElements(modelClass: onBoardingData[index]);
            },
          ),
        ),
        SmoothPageIndicator(
          controller: pageController,
          count: onBoardingData.length,
          effect: ExpandingDotsEffect(
            dotHeight: 10,
            dotWidth: 10,
            dotColor: Color(0xff209CEE),
          ),
          onDotClicked: (index) {},
        ),
        _buildBottomButtons(),
      ],
    );
  }

  Widget _buildBottomButtons() {
    return Column(
      children: [
        Column(
          children: [
            SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Container(
                width: double.infinity,
                  height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    if (_currentIndex == 2) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => LoginScreen()),
                      );
                    } else {
                      pageController.nextPage(
                        duration: Duration(milliseconds: 300),
                        curve: Curves.easeIn,
                      );
                    }
                  },
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _currentIndex == onBoardingData.length - 1
                              ? 'FINISH'
                              : 'NEXT',
                          style: TextStyle(
                            fontSize: 20,
                            fontFamily: 'Sans',
                            fontWeight: FontWeight.w600,
                            color: Color(0xffFFFFFF),
                          ),
                        ),
                        SizedBox(width: 15),

                        Padding(
                          padding: EdgeInsets.only(top: 3),
                          child: Icon(
                            _currentIndex == onBoardingData.length - 1
                                ? Icons.arrow_forward
                                : Icons.arrow_forward,
                            size: 24,
                            color: Color(0xffFFFFFF),
                          ),
                        ),
                      ],
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 0,
                    backgroundColor: primaryBlue,
                  ),
                ),
              ),
            ),

            SizedBox(height: 10),
          ],
        ),
      ],
    );
  }
}
