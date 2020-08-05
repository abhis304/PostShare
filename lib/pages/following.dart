// import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttershare/models/user.dart';
import 'package:fluttershare/pages/search.dart';
import 'package:fluttershare/widgets/header.dart';
import 'package:fluttershare/pages/home.dart';
import 'package:fluttershare/widgets/progress.dart';

class Following extends StatefulWidget {
  final String profileId;

  const Following({this.profileId});
  @override
  _FollowingState createState() => _FollowingState();
}

class _FollowingState extends State<Following> {
  List<UserResult> userResult = [];

    getFollowing() async {
    QuerySnapshot doc = await followingRef
        .document(widget.profileId)
        .collection('userFollowing')
        .getDocuments();

    doc.documents.forEach((doc) async {
      if (doc.exists) {
        String str = doc.documentID;
        print('following :' + str);

        DocumentSnapshot snapshot = await usersRef.document(str).get();
        if (snapshot.exists) {
          User user = User.fromDocument(snapshot);

          final bool isAuthUser = currentUser.id == user.id;

          if (isAuthUser) {
            return;
          } 
            print('user is' + user.id);
            UserResult userResults = UserResult(user: user);
            setState(() {
            userResult.add(userResults);

            });
          
        }
      }
    });
  }

  buildFollowingList() {
    if (userResult == null) {
      return circularProgress();
    } else if (userResult.isEmpty) {
      return Center(child: Text('No Following')); // if there is no post in the timeline then
    } else {
      return ListView(children: userResult);
    }
  }

  @override
  void initState() {
    super.initState();
    getFollowing();
  }

  @override
  Widget build(BuildContext context) {
    // getFollowing();

    return Scaffold(
      appBar: header(context,
          titleText: 'Following', centerTitle: false, removeBackButton: false),
      body: buildFollowingList(),
    );
  }
}
