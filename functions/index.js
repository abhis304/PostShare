const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();


// listen when any follwer's is created.
exports.onCreateFollower = functions.firestore
  .document('/followers/{userId}/userFollowers/{followerId}')
  .onCreate(async (snapshot, context) => {
    console.log('follower created', snapshot.id);
    const userId = context.params.userId;
    const followerId = context.params.followerId;

    // user id means k jene follow karyo hoi teni id.
    // follower id means k jene follow karyo eni id (own id).

    // 1) create followed user's posts ref. (jene follow karyo eni badhi post)

    const followedUserRef = admin
      .firestore()
      .collection('posts')
      .doc(userId)
      .collection('userPosts');

    // 2) create following user's timeline ref (own)

    const timelinePostsRef = admin
      .firestore()
      .collection('timeline')
      .doc(followerId)
      .collection('timelinePosts');


    // 3) get followed user's post

    const querySnapshot = await followedUserRef.get();

    // 4) Add each user post to following user's (own) timeline.


    querySnapshot.forEach(doc => {
      if (doc.exists) {
        const postId = doc.id;
        const postData = doc.data();

        timelinePostsRef.doc(postId).set(postData);
      }

    });

  });


// jyare user unfollow kare tyare teni post ne timeline mathi delete karva mate.

exports.onDeleteFollower = functions
  .firestore
  .document('/followers/{userId}/userFollowers/{followerId}')
  .onDelete(async (snapshot, context) => {
    console.log('follower deleted', snapshot.id);
    const userId = context.params.userId;
    const followerId = context.params.followerId;


    const timelinePostsRef = admin
      .firestore()
      .collection('timeline')
      .doc(followerId)
      .collection('timelinePosts')
      .where('ownerId', "==", userId);


    const querySnapshot = await timelinePostsRef.get();

    querySnapshot.forEach(doc => {
      if (doc.exists) {
        doc.ref.delete();
      }
    });
  });


// when a post is created, add post to timeline of each follower (of post owner)
exports.onCreatePost = functions.firestore
  .document("/posts/{userId}/userPosts/{postId}")
  .onCreate(async (snapshot, context) => {
    const postCreated = snapshot.data();
    const userId = context.params.userId;
    const postId = context.params.postId;

    // 1) Get all the followers of the user who made the post
    const userFollowersRef = admin
      .firestore()
      .collection("followers")
      .doc(userId)
      .collection("userFollowers");

    const querySnapshot = await userFollowersRef.get();
    // 2) Add new post to each follower's timeline
    querySnapshot.forEach(doc => {
      const followerId = doc.id;

      admin
        .firestore()
        .collection("timeline")
        .doc(followerId)
        .collection("timelinePosts")
        .doc(postId)
        .set(postCreated);
    });
  });

exports.onUpdatePost = functions.firestore
  .document("/posts/{userId}/userPosts/{postId}")
  .onUpdate(async (change, context) => {
    const postUpdated = change.after.data();
    const userId = context.params.userId;
    const postId = context.params.postId;

    // 1) Get all the followers of the user who made the post
    const userFollowersRef = admin
      .firestore()
      .collection("followers")
      .doc(userId)
      .collection("userFollowers");

    const querySnapshot = await userFollowersRef.get();
    // 2) Update each post in each follower's timeline
    querySnapshot.forEach(doc => {
      const followerId = doc.id;

      admin
        .firestore()
        .collection("timeline")
        .doc(followerId)
        .collection("timelinePosts")
        .doc(postId)
        .get()
        .then(doc => {
          if (doc.exists) {
            doc.ref.update(postUpdated);
          }
        });
    });
  });

exports.onDeletePost = functions.firestore
  .document("/posts/{userId}/userPosts/{postId}")
  .onDelete(async (snapshot, context) => {
    const userId = context.params.userId;
    const postId = context.params.postId;

    // 1) Get all the followers of the user who made the post
    const userFollowersRef = admin
      .firestore()
      .collection("followers")
      .doc(userId)
      .collection("userFollowers");

    const querySnapshot = await userFollowersRef.get();
    // 2) Delete each post in each follower's timeline
    querySnapshot.forEach(doc => {
      const followerId = doc.id;

      admin
        .firestore()
        .collection("timeline")
        .doc(followerId)
        .collection("timelinePosts")
        .doc(postId)
        .get()
        .then(doc => {
          if (doc.exists) {
            doc.ref.delete();
          }
        });
    });
  });


exports.onCreateActivityFeedItem = functions.firestore
  .document("/feed/{userId}/feedItems/{activityFeedItem}")
  .onCreate(async (snapshot, context) => {
    console.log("Activity Feed Item Created", snapshot.data());

    // 1) Get user connected to the feed
    const userId = context.params.userId;

    const userRef = admin.firestore().doc(`users/${userId}`);
    const doc = await userRef.get();

    // 2) Once we have user, check if they have a notification token; send notification, if they have a token
    const androidNotificationToken = doc.data().androidNotificationToken;
    const createdActivityFeedItem = snapshot.data();
    if (androidNotificationToken) {
      sendNotification(androidNotificationToken, createdActivityFeedItem);
    } else {
      console.log("No token for user, cannot send notification");
    }

    function sendNotification(androidNotificationToken, activityFeedItem) {
      let body;

      // 3) switch body value based off of notification type
      switch (activityFeedItem.type) {
        case "comment":
          body = `${activityFeedItem.username} replied: ${
            activityFeedItem.commentData
            }`;
          break;
        case "like":
          body = `${activityFeedItem.username} liked your post`;
          break;
        case "follow":
          body = `${activityFeedItem.username} started following you`;
          break;
        default:
          break;
      }

      // 4) Create message for push notification
      const message = {
        notification: { body },
        token: androidNotificationToken,
        data: { recipient: userId }
      };

      // 5) Send message with admin.messaging()
      admin
        .messaging()
        .send(message)
        .then(response => {
          // Response is a message ID string
          console.log("Successfully sent message", response);
        })
        .catch(error => {
          console.log("Error sending message", error);
        });
    }
  });




