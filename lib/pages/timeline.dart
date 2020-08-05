
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttershare/models/user.dart';
import 'package:fluttershare/pages/home.dart';
import 'package:fluttershare/pages/search.dart';
import 'package:fluttershare/widgets/header.dart';
import 'package:fluttershare/widgets/post.dart';
import 'package:fluttershare/widgets/progress.dart';

// final usersRef = Firestore.instance.collection('users');

class Timeline extends StatefulWidget {
  final User currentUser;

  Timeline({this.currentUser});

  @override
  _TimelineState createState() => _TimelineState();
}

class _TimelineState extends State<Timeline> {
  List<Post> posts;
  List<String> followingList = [];

  @override
  void initState() {
    super.initState();
    getTimeline();
    getFollowing();
  }

  getTimeline() async {
    QuerySnapshot snapshot = await timelineRef
        .document(widget.currentUser.id)
        .collection('timelinePosts')
        .orderBy('timestamp', descending: true)
        .getDocuments();
    List<Post> posts =
        snapshot.documents.map((doc) => Post.fromDocument(doc)).toList();
    setState(() {
      this.posts = posts;
    });
  }

  getFollowing() async {
    QuerySnapshot snapshot = await followingRef
        .document(currentUser.id)
        .collection('userFollowing')
        .getDocuments();

    setState(() {
      followingList = snapshot.documents.map((doc) => doc.documentID).toList();
    });
  }

  buildTimeline() {
    if (posts == null) {
      return circularProgress();
    } else if (posts.isEmpty) {
      return buildUsersToFollow();  // if there is no post in the timeline then
    } else {
      return ListView(children: posts);
    }
  }

  buildUsersToFollow() {
    return StreamBuilder(
      stream:
          usersRef.orderBy('timestamp', descending: true).limit(20).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return circularProgress();
        }
        List<UserResult> userResults = [];
        snapshot.data.documents.forEach((doc) {
          User user = User.fromDocument(doc);

          // current user no avo joye list ma so.
          final bool isAuthUser = currentUser.id == user.id;
          // remove auth user from recommended list.

          final bool isFollowingUser = followingList.contains(user.id);
          // apde follow karelo user ne list ma nahi batavo (ene pic ek pan upload nai karya hoi ) aa jyre ek pan post timeline par nahi hoi tyare run thase

          if (isAuthUser) {
            return;
          } else if (isFollowingUser) {
            return;
          } else {
            UserResult userResult = UserResult(user: user);
            userResults.add(userResult);
          }
        });

        return Container(
          color: Theme.of(context).accentColor.withOpacity(0.2),
          child: Column(
            children: <Widget>[
              Container(
                padding: EdgeInsets.all(12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Icon(
                      Icons.person_add,
                      color: Theme.of(context).primaryColor,
                    ),
                    SizedBox(width: 8.0),
                    Text(
                      'Users to follow',
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontSize: 30.0,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 5.0,
              ),
              Column(
                children: userResults,
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(context) {
    return Scaffold(
        appBar: header(context,
            isAppTitle: true, removeBackButton: true, centerTitle: true),
        body: RefreshIndicator(
            onRefresh: () => getTimeline(), child: buildTimeline()));
  }
}
