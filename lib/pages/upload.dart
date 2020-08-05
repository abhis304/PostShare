import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fluttershare/models/user.dart';
import 'package:fluttershare/pages/home.dart';
import 'package:fluttershare/widgets/progress.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as Img;
import 'package:uuid/uuid.dart';

class Upload extends StatefulWidget {
  final User currentUser;

  Upload({this.currentUser});
  @override
  _UploadState createState() => _UploadState();
}

class _UploadState extends State<Upload>
    with AutomaticKeepAliveClientMixin<Upload> {
  File file;
  bool isUpload = false;
  String postId = Uuid().v4();
  TextEditingController locationController = TextEditingController();
  TextEditingController captionController = TextEditingController();
  final DateTime _timestamp = DateTime.now();

  handleTakePhoto() async {
    Navigator.pop(context);
    File file = await ImagePicker.pickImage(
        source: ImageSource.camera, maxHeight: 675, maxWidth: 960);

    setState(() {
      this.file = file;
    });
  }

  handleChooseFromGallery() async {
    Navigator.pop(context);
    File file = await ImagePicker.pickImage(
      source: ImageSource.gallery,
    );

    setState(() {
      this.file = file;
    });
  }

  selectImage(context) {
    return showDialog(
        context: context,
        builder: (context) {
          return SimpleDialog(
            title: Text('Create Post'),
            children: <Widget>[
              SimpleDialogOption(
                child: Text('Photo with Camera'),
                onPressed: handleTakePhoto,
              ),
              SimpleDialogOption(
                child: Text('Image From Gallery'),
                onPressed: handleChooseFromGallery,
              ),
              SimpleDialogOption(
                child: Text('Cancel'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          );
        });
  }

  Container buildSplashScreen(BuildContext context) {
    return Container(
      color: Theme.of(context).accentColor.withOpacity(0.6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          SvgPicture.asset(
            'assets/images/upload.svg',
            height: 200.0,
          ),
          Padding(
            padding: EdgeInsets.only(top: 20.0),
            child: RaisedButton(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Text(
                'Upload Image',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22.0,
                ),
              ),
              color: Colors.deepOrange,
              onPressed: () => selectImage(context),
            ),
          ),
        ],
      ),
    );
  }

  clearImage() {
    setState(() {
      file = null;
    });
  }

  compressImage() async {
    final tempDir = await getTemporaryDirectory();
    final path = tempDir.path;

    Img.Image imageFile = Img.decodeImage(file.readAsBytesSync());

    final compressedImageFile = File('$path/img_$postId')
      ..writeAsBytesSync(Img.encodeJpg(imageFile, quality: 85));

    setState(() {
      file = compressedImageFile;
    });
  }

  // upload post in firebase storage
  Future<String> uploadImage(imageFile) async {
    StorageUploadTask uploadTask =
        storageRef.child('post_$postId.jpg').putFile(imageFile);

    StorageTaskSnapshot storageSnap = await uploadTask.onComplete;

    String downloadUrl = await storageSnap.ref.getDownloadURL();

    return downloadUrl;
  }

  createPostInFirestore(
      {String mediaUrl, String location, String description}) {
    postRef
        .document(widget.currentUser.id)
        .collection('userPosts')
        .document(postId)
        .setData({
      'postId': postId,
      'ownerId': widget.currentUser.id,
      'username': widget.currentUser.username,
      'mediaUrl': mediaUrl,
      'description': description,
      'location': location,
      'timestamp': _timestamp,
      'likes': {},
    });
  }

  handleSubmit() async {
    setState(() {
      isUpload = true;
    });

    await compressImage();
    String mediaUrl = await uploadImage(file);

    createPostInFirestore(
      mediaUrl: mediaUrl,
      location: locationController.text,
      description: captionController.text,
    );

    captionController.clear();
    locationController.clear();
    setState(() {
      file = null;
      isUpload = false;
      postId = Uuid().v4();
    });
  }

  Scaffold buildUploadForm() {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white70,
        leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios,
              color: Colors.black,
            ),
            onPressed: clearImage),
        title: Text(
          'Create post',
          style: TextStyle(color: Colors.black),
        ),
        actions: <Widget>[
          FlatButton(
              onPressed: isUpload ? null : () => handleSubmit(),
              child: Text(
                'Post',
                style: TextStyle(
                  color: Colors.blueAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 20.0,
                ),
              )),
        ],
      ),
      body: ListView(
        children: <Widget>[
          isUpload ? linearProgress() : Text(''),
          Container(
            padding: EdgeInsets.all(5.0),
            height: 220.0,
            width: MediaQuery.of(context).size.width * 0.8,
            child: Center(
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: FileImage(file),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(top: 10.0),
          ),
          ListTile(
            leading: CircleAvatar(
              backgroundImage:
                  CachedNetworkImageProvider(widget.currentUser.photoUrl),
            ),
            title: Container(
              width: 250.0,
              child: TextField(
                controller: captionController,
                decoration: InputDecoration(
                  hintText: 'Write a Caption ...',
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          Divider(),
          ListTile(
            leading: Icon(
              Icons.pin_drop,
              color: Colors.blueAccent,
              size: 35.0,
            ),
            title: Container(
              width: 250.0,
              child: TextField(
                controller: locationController,
                decoration: InputDecoration(
                  hintText: 'Where was this photo taken ?',
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          Container(
            width: 200.0,
            height: 100.0,
            alignment: Alignment.center,
            child: RaisedButton.icon(
              onPressed: getUserLocation,
              icon: Icon(
                Icons.my_location,
                color: Colors.white,
              ),
              label: Text(
                'Use Current Location',
                style: TextStyle(color: Colors.white),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30.0),
              ),
              color: Colors.blue,
            ),
          )
        ],
      ),
    );
  }

  getUserLocation() async {
    Position position = await Geolocator()
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    List<Placemark> placemarks = await Geolocator()
        .placemarkFromCoordinates(position.latitude, position.longitude);

    Placemark placemark = placemarks[0];

    String completeAddress =
        '${placemark.subThoroughfare} ${placemark.thoroughfare}, ${placemark.subLocality} ${placemark.locality}, ${placemark.subAdministrativeArea}, ${placemark.administrativeArea} ${placemark.postalCode}, ${placemark.country}';
    print(completeAddress);

    String formattedAddress = "${placemark.locality}, ${placemark.country}";
    locationController.text = formattedAddress;
  }

  @override
  bool get wantKeepAlive => true;
  // AutomaticKeepAliveClientMixin e mate used thay jyare apde data ne state par save rakhva hoi suppose k hu search par kaik user search karyo then upload page par vayo gayo then pacho search page par avu to search result clear thay jatu so e state rey te mate used thay

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return file == null ? buildSplashScreen(context) : buildUploadForm();
  }
}
