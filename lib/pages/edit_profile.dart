import 'dart:io';
import 'package:fluttershare/pages/showprofilepic.dart';
import 'package:path_provider/path_provider.dart';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import "package:flutter/material.dart";
import 'package:fluttershare/models/user.dart';
import 'package:fluttershare/pages/home.dart';
import 'package:fluttershare/widgets/progress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as Img;

class EditProfile extends StatefulWidget {
  final String currentUserId;

  const EditProfile({this.currentUserId});

  @override
  _EditProfileState createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  File file;
  bool isLoading = false;
  User user;
  TextEditingController displayNameController = TextEditingController();
  TextEditingController bioController = TextEditingController();
  bool _displayNameValid = true;
  bool _bioValid = true;

  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    getUser();
  }

  getUser() async {
    setState(() {
      isLoading = true;
    });

    DocumentSnapshot doc = await usersRef.document(widget.currentUserId).get();
    user = User.fromDocument(doc);

    displayNameController.text = user.displayName;
    bioController.text = user.bio;

    setState(() {
      isLoading = false;
    });
  }

  Column buildDisplayNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: EdgeInsets.only(top: 12.0),
          child: Text(
            'Display Name',
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
        ),
        TextField(
          controller: displayNameController,
          decoration: InputDecoration(
            errorText: _displayNameValid ? null : 'Display Name too short',
            hintText: 'Update Display Name',
          ),
        ),
      ],
    );
  }

  Column buildBioField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: EdgeInsets.only(top: 12.0),
          child: Text(
            'Bio',
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
        ),
        TextField(
          controller: bioController,
          decoration: InputDecoration(
            hintText: 'Update Bio',
            errorText: _bioValid ? null : 'Bio is too Long',
          ),
        ),
      ],
    );
  }

  updateProfileData() {
    print(displayNameController.text);
    print(bioController.text);

    setState(() {
      displayNameController.text.trim().length < 3 ||
              displayNameController.text.isEmpty
          ? _displayNameValid = false
          : _displayNameValid = true;

      bioController.text.trim().length > 100
          ? _bioValid = false
          : _bioValid = true;
    });

    if (_displayNameValid && _bioValid) {
      usersRef.document(widget.currentUserId).updateData({
        'displayName': displayNameController.text,
        'bio': bioController.text,
      });

      SnackBar snackBar =
          SnackBar(content: Text('Profile Updated ${user.username}'));

      _scaffoldKey.currentState.showSnackBar(snackBar);
    }
  }

  logOutUser() async {
    await googleSignIn.signOut();
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => Home()));
  }

  compressImage() async {
    final tempDir = await getTemporaryDirectory();
    final path = tempDir.path;

    Img.Image imageFile = Img.decodeImage(file.readAsBytesSync());

    final compressedImageFile = File('$path/img_${currentUser.id}')
      ..writeAsBytesSync(Img.encodeJpg(imageFile, quality: 20));

    setState(() {
      file = compressedImageFile;
    });
  }

  // update profile pic in firebase storage
  Future<String> uploadImage(imageFile) async {
    StorageUploadTask uploadTask = storageRef
        .child('profilepics/${currentUser.id.toString()}.jpg')
        .putFile(imageFile);

    StorageTaskSnapshot storageSnap = await uploadTask.onComplete;

    String downloadUrl = await storageSnap.ref.getDownloadURL();

    return downloadUrl;
  }

  editPhoto(BuildContext context) async {
    File file = await ImagePicker.pickImage(source: ImageSource.gallery);

    setState(() {
      this.file = file;
    });
    Navigator.pop(context);

    await compressImage();

    String downloadUrl = await uploadImage(file);

    print('Updated Profile Pic Url ' + downloadUrl);

    usersRef.document(currentUser.id).updateData({
      'photoUrl': downloadUrl,
    }).catchError((error) {
      print('error is' + error);
    });
  }

  handleProfilePhoto(BuildContext context) {
    return showDialog(
        context: context,
        builder: (context) {
          return SimpleDialog(
            title: Text('View or Update Photo'),
            children: <Widget>[
              SimpleDialogOption(
                onPressed: () {
                  print(' see photo ');
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => SeeProfilePic()));
                },
                child: Text(
                  'View Photo',
                  style: TextStyle(color: Colors.red),
                ),
              ),
              SimpleDialogOption(
                onPressed: () => editPhoto(context),
                child: Text(
                  'Edit Photo',
                  style: TextStyle(color: Colors.red),
                ),
              ),
              SimpleDialogOption(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
              ),
            ],
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        backgroundColor: Colors.white,
        centerTitle: true,
        title: Text(
          'Edit Profile',
          style: TextStyle(color: Colors.black),
        ),
        actions: <Widget>[
          IconButton(
              icon: Icon(
                Icons.done,
                size: 30.0,
                color: Colors.green,
              ),
              onPressed: () => Navigator.pop(context)),
        ],
      ),
      body: isLoading
          ? circularProgress()
          : ListView(
              children: <Widget>[
                Container(
                  child: Column(
                    children: <Widget>[
                      Padding(
                        padding: EdgeInsets.only(
                          top: 16.0,
                          bottom: 8.0,
                        ),
                        child: GestureDetector(
                          onTap: () => handleProfilePhoto(context),
                          child: CircleAvatar(
                            radius: 50.0,
                            backgroundImage:
                                CachedNetworkImageProvider(user.photoUrl),
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Column(
                          children: <Widget>[
                            buildDisplayNameField(),
                            buildBioField(),
                          ],
                        ),
                      ),
                      RaisedButton(
                        onPressed: updateProfileData,
                        child: Text(
                          'Update Profile',
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontSize: 18.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(16.0),
                        child: FlatButton.icon(
                          onPressed: logOutUser,
                          icon: Icon(
                            Icons.cancel,
                            color: Colors.red,
                          ),
                          label: Text(
                            'logout',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 18.0,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
