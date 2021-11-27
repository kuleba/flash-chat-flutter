import 'package:flash_chat/screens/welcome_screen.dart';
import 'package:flutter/material.dart';
import 'package:flash_chat/constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final _firestore = FirebaseFirestore.instance;
late User loggedInUser;

class ChatScreen extends StatefulWidget {
  static const String id = 'chat';
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final messageTextController = TextEditingController();
  final _auth = FirebaseAuth.instance;

  String messageText = '';

  void getCurrentUser() async {
    final user = await _auth.currentUser;
    if (user != null) {
      loggedInUser = user;
      //print(loggedInUser.email);
    }
  }

  // void getMassages () async{
  //   final messages = await _firestore.collection('messages').get();
  //   for (var message in messages.docs) {
  //     print(message.data());
  //   }
  // }

  void messagesStream() async {
    await for (var snapshot in _firestore.collection('messages').snapshots()) {
      for (var message in snapshot.docs) {
        print(message.data());
      }
    }
    ;
  }

  @override
  void initState() {
    getCurrentUser();
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: null,
        actions: <Widget>[
          IconButton(
              icon: Icon(Icons.close),
              onPressed: () async {
                await _auth.signOut();
                Navigator.pushNamedAndRemoveUntil(context, WelcomeScreen.id,
                    (route) => false); //Implement logout functionality
              }),
        ],
        title: Text('⚡️Chat'),
        backgroundColor: Colors.lightBlueAccent,
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            MessagesStream(),
            Container(
              decoration: kMessageContainerDecoration,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: messageTextController,
                      style: TextStyle(
                        color: Colors.black,
                      ),
                      onChanged: (value) {
                        messageText = value;
                      },
                      decoration: kMessageTextFieldDecoration,
                    ),
                  ),
                  TextButton(
                    onPressed: ()  {
                      messageTextController.clear();
                       _firestore.collection('messages').add(
                          {'timestamp': FieldValue.serverTimestamp(),'text': messageText, 'sender': loggedInUser.email});
                      //Implement send functionality.
                    },
                    child: Text(
                      'Send',
                      style: kSendButtonTextStyle,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class MessagesStream extends StatelessWidget {
  const MessagesStream({Key? key, }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('messages').orderBy('timestamp').snapshots(),
      builder: (context, snapshot) {
        List<MessageBubble> messageBubbles = [];
        if (!snapshot.hasData) {
          return Center(
            child: CircularProgressIndicator(),
          );
        }
        final messages = snapshot.data!.docs.reversed;

        for (var message in messages) {
          final messageText = message.get('text');
          final messageSender = message.get('sender');
          final messageBubble = MessageBubble(messageSender: messageSender, messageText: messageText);

          messageBubbles.add(messageBubble);
        }

        return Expanded(
          child: ListView(
            reverse: true,
            padding: EdgeInsets.symmetric(horizontal: 10,vertical: 20),
            children: messageBubbles,
          ),
        );
      },
    );
  }
}


class MessageBubble extends StatelessWidget {
  const MessageBubble({Key? key, required this.messageSender, required this.messageText}) : super(key: key);
  final String messageSender;
  final String messageText;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Column(
        crossAxisAlignment: (messageSender==loggedInUser.email) ? CrossAxisAlignment.start : CrossAxisAlignment.end,
        children: [
          Text(messageSender, style: TextStyle(fontSize: 12, color: Colors.black54),),
          Material(
            borderRadius: (messageSender==loggedInUser.email) ?  BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30), topRight:Radius.circular(30)) : BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30), topLeft: Radius.circular(30)),
            elevation: 6,
            color: (messageSender==loggedInUser.email) ? Colors.lightBlueAccent : Colors.white,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 20),
              child: Text(messageText,

                style: TextStyle(fontSize: 20 ,color: (messageSender==loggedInUser.email)?Colors.white:Colors.black54),),
            ),
          ),
        ],
      ),
    );;
  }
}

