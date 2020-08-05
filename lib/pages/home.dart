import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttershare/pages/activity_feed.dart';
import 'package:fluttershare/pages/create_account.dart';
import 'package:fluttershare/pages/edit_profile.dart';
import 'package:fluttershare/pages/profile.dart';
import 'package:fluttershare/pages/search.dart';
import 'package:fluttershare/pages/timeline.dart';
import 'package:fluttershare/pages/upload.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:fluttershare/models/user.dart';
import 'package:connectivity/connectivity.dart';

final GoogleSignIn googleSignIn = GoogleSignIn();
final usersRef = Firestore.instance.collection('users');
final StorageReference storageRef = FirebaseStorage.instance.ref();
final postRef = Firestore.instance.collection('posts');
final commentsRef = Firestore.instance.collection('comments');
final activityFeedRef = Firestore.instance.collection('feed');
final followersRef = Firestore.instance.collection('followers');
final followingRef = Firestore.instance.collection('following');
final timelineRef = Firestore.instance.collection('timeline');

final DateTime timestamp = DateTime.now();
User currentUser;
String currentUserDisplayName;
String photoUrlForProfile;

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  bool isAuth = false;
  PageController pageController;
  int pageIndex = 0;
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
  var _connectionStatus = 'Unknown';
  Connectivity connectivity;
  StreamSubscription<ConnectivityResult> subscription;
  bool showTextInternetNotConnected = false;

  @override
  void initState() {
    super.initState();

    connectivity = Connectivity();

    subscription = connectivity.onConnectivityChanged.listen((result) {
      _connectionStatus = result.toString();
      print('Connectivity Status' + _connectionStatus);

      if (result == ConnectivityResult.mobile ||
          result == ConnectivityResult.wifi) {
        setState(() {
          showTextInternetNotConnected = false;
        });
        print('internet is on');

        pageController = PageController();

        // Detects when user signed in
        googleSignIn.onCurrentUserChanged.listen((account) {
          handleSignIn(account);
        }, onError: (error) {
          print('Error signing in : $error');
        });

        // Reauthenticate user when app is reopen

        googleSignIn.signInSilently(suppressErrors: false).then((account) {
          handleSignIn(account);
        }).catchError((error) {
          print('Error signing in : $error');
        });
      } else {
        setState(() {
          showTextInternetNotConnected = true;
        });
        print('Please Enable Your Internet Connection');
      }
    });
  }

  @override
  void dispose() {
    pageController.dispose();
    subscription.cancel();
    super.dispose();
  }

  createUserInFirestore() async {
    //steps :
    // 1) check if user exists in users collection in database (according to their id).

    final GoogleSignInAccount user = googleSignIn.currentUser;

    DocumentSnapshot doc = await usersRef.document(user.id).get();

    if (!doc.exists) {
      // 2) if the user doesn't exist , then we want to take them to the create account page.

      final userName = await Navigator.push(
          context, MaterialPageRoute(builder: (context) => CreateAccount()));

      // 3) get username from create account , use it to make new user document in users collection.

      usersRef.document(user.id).setData({
        'id': user.id,
        'username': userName,
        'photoUrl': user.photoUrl,
        'email': user.email,
        'displayName': user.displayName,
        'bio': '',
        'timestamp': timestamp,
      });

      // make the current user to their own follower (to include their post in timeline)
      // current user ni potani post ne timeline par display karva mate pela tene follower's ma add karva ma avse

      await followersRef
          .document(user.id)
          .collection('userFollowers')
          .document(user.id)
          .setData({});

      doc = await usersRef.document(user.id).get();
    }

    currentUser = User.fromDocument(doc);
    photoUrlForProfile = currentUser.photoUrl;
    currentUserDisplayName = currentUser.displayName;

    print(currentUser);
    print(currentUser.username);
  }

  handleSignIn(GoogleSignInAccount account) async {
    if (account != null) {
      // pela currentuser assigned thase then isAuth ni value set thay e mate await used karva ma avyu
      // nahitar currentuser set nai that e pela isAuth set thay jat.
      await createUserInFirestore();
      // photoUrlForProfile   = currentUser.photoUrl;
      print('User Signed in : $account');
      setState(() {
        isAuth = true;
      });
      // notification mate
      // configurePushNotification();
    } else {
      setState(() {
        isAuth = false;
      });
    }
  }

  // configurePushNotification() {
  //   final GoogleSignInAccount user = googleSignIn.currentUser;
  //   if (Platform.isIOS) getiOSPermission();

  //   _firebaseMessaging.getToken().then((token) {
  //     print("Firebase Messaging Token: $token\n");
  //     usersRef
  //         .document(user.id)
  //         .updateData({"androidNotificationToken": token});
  //   });

  //   _firebaseMessaging.configure(
  //     // onLaunch: (Map<String, dynamic> message) async {},
  //     // onResume: (Map<String, dynamic> message) async {},
  //     onMessage: (Map<String, dynamic> message) async {
  //       print("on message: $message\n");
  //       final String recipientId = message['data']['recipient'];
  //       final String body = message['notification']['body'];
  //       if (recipientId == user.id) {
  //         print("Notification shown!");
  //         SnackBar snackbar = SnackBar(
  //             content: Text(
  //           body,
  //           overflow: TextOverflow.ellipsis,
  //         ));
  //         _scaffoldKey.currentState.showSnackBar(snackbar);
  //       }
  //       print("Notification NOT shown");
  //     },
  //   );
  // }

  getiOSPermission() {
    _firebaseMessaging.requestNotificationPermissions(
        IosNotificationSettings(alert: true, badge: true, sound: true));
    _firebaseMessaging.onIosSettingsRegistered.listen((settings) {
      print("Settings registered: $settings");
    });
  }

  login() {
    googleSignIn.signIn();
  }

  logOut() {
    googleSignIn.signOut();
  }

  onPageChanged(int pageIndex) {
    setState(() {
      this.pageIndex = pageIndex;
    });
  }

  onTap(int pageIndex) {
    pageController.animateToPage(
      pageIndex,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Scaffold buildAuthScreen() {
    // return RaisedButton(
    //   onPressed: logOut,
    //   child: Text('Logout'),
    // );

    return Scaffold(
      key: _scaffoldKey,
      body: PageView(
        children: <Widget>[
          Timeline(currentUser: currentUser),

          ActivityFeed(),
          Upload(currentUser: currentUser),
          Search(),
          Profile(
              profileId: currentUser
                  ?.id), // if current user is not null if its true then pass id
        ],
        controller: pageController,
        onPageChanged: onPageChanged,
        physics: NeverScrollableScrollPhysics(),
      ),
      bottomNavigationBar: CupertinoTabBar(
        currentIndex: pageIndex,
        onTap: onTap,
        activeColor: Theme.of(context).primaryColor,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.whatshot)),
          BottomNavigationBarItem(icon: Icon(Icons.notifications_active)),
          BottomNavigationBarItem(icon: Icon(Icons.photo_camera, size: 35.0)),
          BottomNavigationBarItem(icon: Icon(Icons.search)),
          BottomNavigationBarItem(
            icon: GestureDetector(
              onLongPress: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => EditProfile(
                              currentUserId: currentUser.id,
                            )));
              },
              child: CircleAvatar(
                backgroundImage: photoUrlForProfile == null
                    ? AssetImage('assets/images/user.png')
                    : CachedNetworkImageProvider(photoUrlForProfile),
                radius: 15.0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Scaffold buildUnAuthScreen() {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              Theme.of(context).accentColor,
              Theme.of(context).primaryColor,
            ],
          ),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Text(
              'Post Share',
              style: TextStyle(
                fontFamily: 'Signatra',
                fontSize: 80.0,
                color: Colors.white,
              ),
            ),
            GestureDetector(
              onTap: login,
              child: Container(
                width: 260.0,
                height: 60.0,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/google_signin_button.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 30.0,
            ),
            showTextInternetNotConnected
                ? Text(
                    'Please Enable Your Internet Connection',
                    style: TextStyle(color: Colors.white),
                  )
                : Text(''),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return isAuth ? buildAuthScreen() : buildUnAuthScreen();
  }
}
