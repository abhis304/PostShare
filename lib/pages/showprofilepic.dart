import 'package:flutter/material.dart';
import 'package:fluttershare/pages/home.dart';
import 'package:fluttershare/widgets/header.dart';

class SeeProfilePic extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black54,
      appBar: header(context,
          titleText: currentUser.displayName,
          centerTitle: false,
          removeBackButton: false),
          body: Center(
            
              child: Image.network(currentUser.photoUrl),
          ),
    );
  }
}
