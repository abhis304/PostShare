// import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttershare/models/user.dart';
import 'package:fluttershare/pages/search.dart';
import 'package:fluttershare/widgets/header.dart';
import 'package:fluttershare/pages/home.dart';
import 'package:fluttershare/widgets/progress.dart';

class Followers extends StatefulWidget {
  final String profileId;

  const Followers({this.profileId});
  @override
  _FollowersState createState() => _FollowersState();
}

class _FollowersState extends State<Followers> {
  List<UserResult> userResult = [];

  getFollowing() async {
    QuerySnapshot doc = await followersRef
        .document(widget.profileId)
        .collection('userFollowers')
        .getDocuments();

    doc.documents.forEach((doc) async {
      if (doc.exists) {
        String str = doc.documentID;
        print('following :' + str);

        DocumentSnapshot snapshot = await usersRef.document(str).get();
        if (snapshot.exists) {
          User user = User.fromDocument(snapshot);

          final bool isAuthUser = currentUser.id == user.id;
          final bool isProfileUser = widget.profileId == user.id;

          if (isAuthUser) {
            return;
          } else if (isProfileUser) {
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
      return Center(
          child:
              Text('No Followers')); // if there is no post in the timeline then
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
