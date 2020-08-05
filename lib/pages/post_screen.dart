import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttershare/pages/home.dart';
import 'package:fluttershare/widgets/header.dart';
import 'package:fluttershare/widgets/progress.dart';
import 'package:fluttershare/widgets/post.dart';

class PostScreen extends StatefulWidget {
  final String userId;
  final String postId;

  const PostScreen({this.userId, this.postId});

  @override
  _PostScreenState createState() => _PostScreenState();
}

class _PostScreenState extends State<PostScreen> {
  List<Post> _posts;

  getPost() async {
    DocumentSnapshot doc = await postRef
        .document(widget.userId)
        .collection('userPosts')
        .document(widget.postId)
        .get();

    Post post = Post.fromDocument(doc);

    Timestamp time = post.timestamp;

    print('timestamp' + time.toString());

    QuerySnapshot snapshot = await postRef
        .document(widget.userId)
        .collection('userPosts')
        .where('timestamp', isLessThanOrEqualTo: time)
        .orderBy('timestamp', descending: true)
        .getDocuments();

    if (doc.exists) {
      List<Post> posts =
          snapshot.documents.map((doc) => Post.fromDocument(doc)).toList();

      setState(() {
        this._posts = posts;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // return FutureBuilder(
    //   future: postRef
    //       .document(widget.userId)
    //       .collection('userPosts')
    //       .document(widget.postId)
    //       .get(),
    //   builder: (context, snapshot) {
    //     if (!snapshot.hasData) {
    //       return circularProgress();
    //     }
    //     Post post = Post.fromDocument(snapshot.data);
    //     return Scaffold(
    //       appBar: header(context, titleText: post.description),
    //       body: ListView(
    //         children: <Widget>[
    //           Container(
    //             child: post,
    //           ),
    //         ],
    //       ),
    //     );
    //   },
    // );

    getPost();

    return Scaffold(
      appBar: header(context,
          titleText: 'Posts', centerTitle: false, removeBackButton: false),
      body: _posts == null ? circularProgress() : ListView(children: _posts),
    );
  }
}
