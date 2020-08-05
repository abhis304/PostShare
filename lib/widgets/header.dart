import 'package:flutter/material.dart';

header(context,
    {bool isAppTitle = false,
    String titleText,
    removeBackButton = false,
    bool centerTitle = false}) {
  return AppBar(
    automaticallyImplyLeading: removeBackButton ? false : true,
    title: Text(
      isAppTitle ? 'Post Share' : titleText,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: Colors.white,
        fontFamily: isAppTitle ? 'Signatra' : "",
        fontSize: isAppTitle ? 40.0 : 22.0,
      ),
    ),
    centerTitle: centerTitle ? true : false,
    backgroundColor: Theme.of(context).accentColor,
  );
}
