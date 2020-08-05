import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fluttershare/models/user.dart';
import 'package:fluttershare/pages/edit_profile.dart';
import 'package:fluttershare/pages/followers.dart';
import 'package:fluttershare/pages/following.dart';
// import 'package:fluttershare/pages/following.dart';
import 'package:fluttershare/widgets/header.dart';
import 'package:fluttershare/widgets/post.dart';
import 'package:fluttershare/widgets/post_tile.dart';
import 'package:fluttershare/widgets/progress.dart';
import 'package:fluttershare/pages/home.dart';

// final usersRef = Firestore.instance.collection('users');

User user1;

class Profile extends StatefulWidget {
  final String profileId;
  Profile({this.profileId});

  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  final String currentUserId = currentUser?.id;
  bool isLoading = false;
  int postCount = 0;
  List<Post> posts = [];
  String postOrientation = 'grid';
  int followerCount = 0;
  int followingCount = 0;
  bool isFollowing = false;
  bool isShowProfile = false;

  @override
  void initState() {
    super.initState();
    isShowProfile = currentUserId == widget.profileId;

    getProfilePost();
    getName();
    getFollowers();
    getFollowing();
    checkIfFollowing();
  }

  // checkIfFollowing() async {
  //   DocumentSnapshot doc = await followersRef
  //       .document(widget.profileId)
  //       .collection('userFollowers')
  //       .document(currentUserId)
  //       .get();

  //   setState(() {
  //     isFollowing = doc.exists;
  //   });
  // }

  // getFollowers() async {
  //   QuerySnapshot snapshot = await followersRef
  //       .document(widget.profileId)
  //       .collection('userFollowers')
  //       .getDocuments();

  //   setState(() {
  //     followerCount = snapshot.documents.length;
  //   });
  // }

  // getFollowing() async {
  //   QuerySnapshot snapshot = await followingRef
  //       .document(widget.profileId)
  //       .collection('userFollowing')
  //       .getDocuments();

  //   setState(() {
  //     followingCount = snapshot.documents.length;
  //   });
  // }

  checkIfFollowing() async {
    DocumentSnapshot doc = await followersRef
        .document(widget.profileId)
        .collection('userFollowers')
        .document(currentUserId)
        .get();
    setState(() {
      isFollowing = doc.exists;
      isShowProfile = doc.exists;
    });
  }

  getFollowers() async {
    QuerySnapshot snapshot = await followersRef
        .document(widget.profileId)
        .collection('userFollowers')
        .getDocuments();
    setState(() {
      followerCount = snapshot.documents.length;
    });
  }

  getFollowing() async {
    QuerySnapshot snapshot = await followingRef
        .document(widget.profileId)
        .collection('userFollowing')
        .getDocuments();
    setState(() {
      followingCount = snapshot.documents.length;
    });
  }

  getProfilePost() async {
    setState(() {
      isLoading = true;
    });
    QuerySnapshot snapshot = await postRef
        .document(widget.profileId)
        .collection('userPosts')
        .orderBy('timestamp', descending: true)
        .getDocuments();

    setState(() {
      isLoading = false;
      postCount = snapshot.documents.length;
      posts = snapshot.documents.map((doc) => Post.fromDocument(doc)).toList();
    });
  }

  Column buildCountColumn(String label, int count) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 22.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        Container(
          margin: EdgeInsets.only(top: 4.0),
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.w400,
              fontSize: 15.0,
            ),
          ),
        ),
      ],
    );
  }

  editProfile() {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => EditProfile(currentUserId: currentUserId)));
  }

  Container buildButton({String text, Function function}) {
    return Container(
      padding: EdgeInsets.only(top: 2.0),
      child: FlatButton(
        onPressed: function,
        child: Container(
          width: 210.0,
          height: 26.0,
          child: Text(
            text,
            style: TextStyle(
              color: isFollowing ? Colors.black : Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          alignment: Alignment.center,
          decoration: BoxDecoration(
              color: isFollowing ? Colors.white : Colors.blue,
              border: Border.all(
                color: isFollowing ? Colors.grey : Colors.blue,
              ),
              borderRadius: BorderRadius.circular(5.0)),
        ),
      ),
    );
  }

  buildProfileButton() {
    // viewing your own profile - we should show edit profile button.

    bool isProfileOwner = currentUserId == widget.profileId;

    if (isProfileOwner) {
      return buildButton(
        text: 'Edit Profile',
        function: editProfile,
      );
    } else if (isFollowing) {
      // setState(() {
      //   isShowProfile = true;
      // });
      return buildButton(text: 'Unfollow', function: handleUnfollowUser);
    } else if (!isFollowing) {
      // setState(() {
      //   isShowProfile = false;
      // });
      return buildButton(text: 'Follow', function: handleFollowUser);
    }
  }

  handleUnfollowUser() {
    setState(() {
      isFollowing = false;
      isShowProfile = false;
    });
    // remove follower
    followersRef
        .document(widget.profileId)
        .collection('userFollowers')
        .document(currentUserId)
        .get()
        .then((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });
    // remove following
    followingRef
        .document(currentUserId)
        .collection('userFollowing')
        .document(widget.profileId)
        .get()
        .then((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });
    // delete activity feed item for them
    activityFeedRef
        .document(widget.profileId)
        .collection('feedItems')
        .document(currentUserId)
        .get()
        .then((doc) {
      if (doc.exists) {
        doc.reference.delete();
      }
    });
  }

  handleFollowUser() {
    setState(() {
      isFollowing = true;
      isShowProfile = true;
    });
    // Make auth user follower of THAT user (update THEIR followers collection)
    followersRef
        .document(widget.profileId)
        .collection('userFollowers')
        .document(currentUserId)
        .setData({});
    // Put THAT user on YOUR following collection (update your following collection)
    followingRef
        .document(currentUserId)
        .collection('userFollowing')
        .document(widget.profileId)
        .setData({});
    // add activity feed item for that user to notify about new follower (us)
    activityFeedRef
        .document(widget.profileId)
        .collection('feedItems')
        .document(currentUserId)
        .setData({
      "type": "follow",
      "ownerId": widget.profileId,
      "username": currentUser.username,
      "userId": currentUserId,
      "userProfileImg": currentUser.photoUrl,
      "timestamp": timestamp,
    });
  }

  buildProfileHeader() {
    return FutureBuilder(
      future: usersRef.document(widget.profileId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return circularProgress();
        }
        User user = User.fromDocument(snapshot.data);

        return Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            children: <Widget>[
              Row(
                children: <Widget>[
                  CircleAvatar(
                    radius: 40.0,
                    backgroundColor: Colors.grey,
                    backgroundImage: CachedNetworkImageProvider(user.photoUrl),
                  ),
                  Expanded(
                    flex: 1,
                    child: Column(
                      children: <Widget>[
                        Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: <Widget>[
                            buildCountColumn('Posts', postCount),
                            GestureDetector(
                                // onTap: () => print('followers tapped'),
                                onTap: isShowProfile
                                    ? () {
                                        print('hello 1');
                                        Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) => Followers(
                                                    profileId:
                                                        widget.profileId)));
                                      }
                                    : null,
                                child: buildCountColumn(
                                    'Followers',
                                    followerCount -
                                        1)), // current user ne minus karvo padse so -1 karyu
                            GestureDetector(
                                // onTap: () => print('following tapped'),

                                onTap: isShowProfile
                                    ? () {
                                        print('hello');
                                        Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) => Following(
                                                    profileId:
                                                        widget.profileId)));
                                      }
                                    : null,
                                child: buildCountColumn(
                                    'Following', followingCount)),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: <Widget>[
                            buildProfileButton(),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Container(
                alignment: Alignment.centerLeft,
                padding: EdgeInsets.only(top: 12.0),
                child: Text(
                  user.username,
                  style: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 16.0,
                  ),
                ),
              ),
              Container(
                alignment: Alignment.centerLeft,
                padding: EdgeInsets.only(top: 4.0),
                child: Text(
                  user.displayName,
                  style: TextStyle(
                    color: Colors.black38,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                alignment: Alignment.centerLeft,
                padding: EdgeInsets.only(top: 2.0),
                child: Text(
                  user.bio,
                  style: TextStyle(
                    color: Colors.black45,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  buildProfilePosts() {
    if (isLoading) {
      return circularProgress();
    } else if (posts.isEmpty) {
      return Container(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SvgPicture.asset(
              'assets/images/no_content.svg',
              height: 170.0,
            ),
            Padding(
              padding: EdgeInsets.only(top: 20.0),
              child: Text(
                'No Post',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontSize: 35.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    } else if (postOrientation == 'grid') {
      List<GridTile> gridTiles = [];
      posts.forEach((post) {
        gridTiles.add(GridTile(child: PostTile(post: post)));
      });

      return GridView.count(
        crossAxisCount: 3,
        childAspectRatio: 1.0,
        mainAxisSpacing: 1.5,
        crossAxisSpacing: 1.5,
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        children: gridTiles,
      );
    } else if (postOrientation == 'list') {
      return Column(
        children: posts,
      );
    }
  }

  setPostOrientation(String postOrientation) {
    setState(() {
      this.postOrientation = postOrientation;
    });
  }

  buildTogglePostOrientation() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        IconButton(
            icon: Icon(
              Icons.grid_on,
              color: postOrientation == 'grid'
                  ? Theme.of(context).primaryColor
                  : Colors.grey,
            ),
            onPressed: () => setPostOrientation('grid')),
        IconButton(
            icon: Icon(
              Icons.list,
              color: postOrientation == 'list'
                  ? Theme.of(context).primaryColor
                  : Colors.grey,
            ),
            onPressed: () => setPostOrientation('list')),
      ],
    );
  }

  getName() async {
    DocumentSnapshot snapshot = await usersRef.document(widget.profileId).get();

    user1 = User.fromDocument(snapshot);
  }

  @override
  Widget build(BuildContext context) {
    bool isAuthUser = currentUserId == widget.profileId;

    return Scaffold(
      appBar: header(context,
          removeBackButton: isAuthUser ? true : false,
          titleText: user1 == null ? 'Profile' : user1.displayName),
      body: ListView(
        children: <Widget>[
          buildProfileHeader(),
          Divider(),
          buildTogglePostOrientation(),
          Divider(
            height: 0.0,
          ),
          SizedBox(
            height: 5.0,
          ),
          isShowProfile
              ? buildProfilePosts()
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    SizedBox(
                      height: 120.0,
                    ),
                    Text(
                      'You are not following him/her',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 20.0,
                      ),
                    ),
                  ],
                ),
        ],
      ),
    );
  }
}
