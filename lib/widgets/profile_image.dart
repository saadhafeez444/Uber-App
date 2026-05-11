import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uber_app/screens/auth/login_screen.dart' as AppColors;


import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';


// class ProfileImageWidget extends StatefulWidget {
//   final String? imageUrl;
//   final Function(File) onImageSelected;
//   final bool isEditable;
//   final double size;

//   const ProfileImageWidget({
//     Key? key,
//     this.imageUrl,
//     required this.onImageSelected,
//     this.isEditable = false,
//     this.size = 120,
//   }) : super(key: key);

//   @override
//   _ProfileImageWidgetState createState() => _ProfileImageWidgetState();
// }

// class _ProfileImageWidgetState extends State<ProfileImageWidget> {
//   File? _selectedImage;

//   Future<void> _pickImage() async {
//     if (!widget.isEditable) return;

//     final picker = ImagePicker();
//     final pickedFile = await picker.pickImage(source: ImageSource.gallery);

//     if (pickedFile != null) {
//       setState(() {
//         _selectedImage = File(pickedFile.path);
//       });
//       widget.onImageSelected(_selectedImage!);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: _pickImage,
//       child: Stack(
//         alignment: Alignment.center,
//         children: [
//           // Outer glow effect
//           Container(
//             width: widget.size + 8,
//             height: widget.size + 8,
//             decoration: BoxDecoration(
//               shape: BoxShape.circle,
//               gradient: LinearGradient(
//                 colors: [
//                   AppColors.primaryBlue.withOpacity(0.3),
//                   Color(0xFF6A82EB),
//                 ],
//                 begin: Alignment.topLeft,
//                 end: Alignment.bottomRight,
//               ),
//             ),
//           ),
          
//           // Main profile image container
//           Container(
//             width: widget.size,
//             height: widget.size,
//             decoration: BoxDecoration(
//               shape: BoxShape.circle,
//               border: Border.all(
//                 color: Colors.white,
//                 width: 4,
//               ),
//               boxShadow: [
//                 BoxShadow(
//                   color: AppColors.primaryBlue.withOpacity(0.4),
//                   blurRadius: 15,
//                   offset: Offset(0, 6),
//                   spreadRadius: 1,
//                 ),
//               ],
//             ),
//             child: ClipOval(
//               child: _buildProfileImage(),
//             ),
//           ),
          
//           // Edit button overlay
//           if (widget.isEditable)
//             Positioned(
//               bottom: 0,
//               right: 0,
//               child: Container(
//                 width: 36,
//                 height: 36,
//                 decoration: BoxDecoration(
//                   gradient: LinearGradient(
//                     colors: [AppColors.primaryBlue, Color(0xFF6A82EB)],
//                     begin: Alignment.topLeft,
//                     end: Alignment.bottomRight,
//                   ),
//                   shape: BoxShape.circle,
//                   border: Border.all(color: Colors.white, width: 3),
//                   boxShadow: [
//                     BoxShadow(
//                       color: AppColors.primaryBlue.withOpacity(0.3),
//                       blurRadius: 8,
//                       offset: Offset(0, 3),
//                     ),
//                   ],
//                 ),
//                 child: Icon(
//                   Icons.camera_alt_rounded,
//                   color: Colors.white,
//                   size: 18,
//                 ),
//               ),
//             ),
//         ],
//       ),
//     );
//   }

//   Widget _buildProfileImage() {
//     if (_selectedImage != null) {
//       return Image.file(_selectedImage!, fit: BoxFit.cover);
//     } else if (widget.imageUrl != null && widget.imageUrl!.isNotEmpty) {
//       return CachedNetworkImage(
//         imageUrl: widget.imageUrl!,
//         fit: BoxFit.cover,
//         placeholder: (context, url) => Container(
//           decoration: BoxDecoration(
//             gradient: LinearGradient(
//               colors: [Color(0xFFE8ECFF), AppColors.primaryBlue.withOpacity(0.1)],
//               begin: Alignment.topLeft,
//               end: Alignment.bottomRight,
//             ),
//           ),
//           child: Icon(
//             Icons.person_rounded,
//             size: widget.size * 0.5,
//             color: AppColors.primaryBlue,
//           ),
//         ),
//         errorWidget: (context, url, error) => Container(
//           decoration: BoxDecoration(
//             gradient: LinearGradient(
//               colors: [Color(0xFFE8ECFF), AppColors.primaryBlue.withOpacity(0.1)],
//               begin: Alignment.topLeft,
//               end: Alignment.bottomRight,
//             ),
//           ),
//           child: Icon(
//             Icons.person_rounded,
//             size: widget.size * 0.5,
//             color: AppColors.primaryBlue,
//           ),
//         ),
//       );
//     } else {
//       return Container(
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
            
//             colors: [Color(0xFFE8ECFF), AppColors.primaryBlue.withOpacity(0.1)],
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//           ),
//         ),
//         child: Icon(
//           Icons.person_rounded,
//           size: widget.size * 0.5,
//           color: AppColors.primaryBlue,
//         ),
//       );
//     }
//   }
// }

class ProfileImageWidget extends StatefulWidget {
  final String? imageUrl;
  final Function(File) onImageSelected;
  final bool isEditable;
  final double size;

  const ProfileImageWidget({
    Key? key,
    this.imageUrl,
    required this.onImageSelected,
    this.isEditable = false,
    this.size = 120,
  }) : super(key: key);

  @override
  _ProfileImageWidgetState createState() => _ProfileImageWidgetState();
}

class _ProfileImageWidgetState extends State<ProfileImageWidget> {
  File? _selectedImage;

  Future<void> _pickImage() async {
    if (!widget.isEditable) return;

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
      widget.onImageSelected(_selectedImage!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _pickImage,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer glow effect
          Container(
            width: widget.size + 8,
            height: widget.size + 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryBlue.withOpacity(0.3),
                  Color(0xFF6A82EB),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          
          // Main profile image container
          Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white,
                width: 4,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryBlue.withOpacity(0.4),
                  blurRadius: 15,
                  offset: Offset(0, 6),
                  spreadRadius: 1,
                ),
              ],
            ),
            child: ClipOval(
              child: _buildProfileImage(),
            ),
          ),
          
          // Edit button overlay
          if (widget.isEditable)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primaryBlue, Color(0xFF6A82EB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryBlue.withOpacity(0.3),
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.camera_alt_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProfileImage() {
    // Priority 1: Selected image from gallery
    if (_selectedImage != null) {
      return Image.file(_selectedImage!, fit: BoxFit.cover);
    } 
    // Priority 2: Firebase Storage URL
    else if (widget.imageUrl != null && widget.imageUrl!.isNotEmpty) {
      // Clean up the URL if needed (remove any extra spaces or formatting issues)
      String cleanUrl = widget.imageUrl!.trim();
      
      return CachedNetworkImage(
        imageUrl: cleanUrl,
        fit: BoxFit.cover,
        placeholder: (context, url) => _buildPlaceholder(),
        errorWidget: (context, url, error) {
          print('Error loading profile image: $error');
          print('URL: $cleanUrl');
          return _buildPlaceholder();
        },
      );
    } 
    // Priority 3: Placeholder
    else {
      return _buildPlaceholder();
    }
  }

  Widget _buildPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFE8ECFF), AppColors.primaryBlue.withOpacity(0.1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Icon(
        Icons.person_rounded,
        size: widget.size * 0.5,
        color: AppColors.primaryBlue,
      ),
    );
  }
}