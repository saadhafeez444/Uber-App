import 'package:flutter/material.dart';
import 'package:uber_app/models/onboarding_model.dart';
import 'package:uber_app/screens/auth/login_screen.dart';


class ModelElements extends StatelessWidget {
  final ModelClass modelClass;

  const ModelElements({super.key, required this.modelClass});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child:Container(
            width: MediaQuery.of(context).size.width * 1, height: 210,
            decoration: BoxDecoration(
          
                image: DecorationImage(
                    image: AssetImage(modelClass.image.toString()), fit: BoxFit.fill),
                borderRadius: BorderRadius.circular(14)
            ),
          ),
        ),
        SizedBox(
          height: 20,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 35),
          child: Center(
            child: Text(
              modelClass.name.toString(),
              style: TextStyle(
                fontFamily: 'Sans',
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: primaryBlue),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        SizedBox(
          height: 8,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Center(
            child: Text(
              modelClass.description.toString(),
              style: TextStyle(
                  fontFamily: 'Sans',
                  fontSize: 15,
                  color: primaryBlue),
              textAlign: TextAlign.justify,
            ),
          ),
        ),
      ],
    );
  }
}

