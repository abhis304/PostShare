import 'package:flutter/material.dart';
import 'package:fluttershare/widgets/custom_image.dart';
import 'package:fluttershare/widgets/post.dart';
import 'package:fluttershare/pages/post_screen.dart';
class PostTile extends StatelessWidget {
  final Post post;

  PostTile({this.post});
  showPost(context) {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (showPost) => PostScreen(
                  postId: post.postId,
                  userId: post.ownerId,
                )));
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // onTap: showPost(context),
      onTap: (){
        showPost(context);
      },
      child: cachedNetworkImage(post.mediaUrl),
    );
  }
}
