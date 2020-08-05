import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttershare/models/user.dart';
import 'package:fluttershare/pages/search.dart';
import 'package:fluttershare/widgets/header.dart';
import 'package:fluttershare/pages/home.dart';
import 'package:fluttershare/widgets/progress.dart';

class PostLike extends StatefulWidget {
  final String postId;
  final String ownerId;

  const PostLike({this.postId, this.ownerId});
  @override
  _PostLikeState createState() => _PostLikeState();
}

class _PostLikeState extends State<PostLike> {
  List<UserResult> userResult = [];

  getLikerName() async {
    DocumentSnapshot snapshot = await postRef
        .document(widget.ownerId)
        .collection('userPosts')
        .document(widget.postId)
        .get();

    if (snapshot.exists) {
      dynamic doc = snapshot.data;

      Map map = doc['likes'];

      // map.forEach((k, v) {
      //   print('{ key: $k, value: $v }');
      // });

      map.keys.forEach((key) async {
        if (doc['likes'][key] == true) {
          print('true value: ' + key);

          DocumentSnapshot snapshot = await usersRef.document(key).get();

          if (snapshot.exists) {
            User user = User.fromDocument(snapshot);

            print('user is' + user.id);
            UserResult userResults = UserResult(user: user);
            setState(() {
              userResult.add(userResults);
            });
          }
        }
      });
      // map.values.forEach((v) => print(v));
    }
  }

  buildLikesShow() {
    if (userResult == null) {
      return circularProgress();
    } else if (userResult.isEmpty) {
      return Center(
          child: Text('No Likes')); // if there is no post in the timeline then
    } else {
      return ListView(children: userResult);
    }
  }

  @override
  void initState() {
    super.initState();
    getLikerName();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: header(context,
          titleText: 'Likes', centerTitle: false, removeBackButton: false),
      body: buildLikesShow(),
    );
  }
}
