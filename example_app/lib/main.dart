import 'package:flutter/material.dart';
import 'package:flutter_web_snackbar/flutter_web_snackbar.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
            image: DecorationImage(
                image: NetworkImage(
                    'http://images.unsplash.com/photo-1522865080725-2a9ea1fcb94e?ixlib=rb-1.2.1&q=80&fm=jpg&crop=entropy&cs=tinysrgb&w=1080&fit=max'),
                fit: BoxFit.cover)),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          FlutterWebSnackbar(
            title: "Hey Fairy",
            titleText: Text('Text Copied'),
            messageText: Text('Copied to clipboard'),
            backgroundColor: Colors.white,
            borderRadius: 8,
            maxWidth: 300,
            icon: Icon(Icons.info, color: Colors.blue),
            padding: const EdgeInsets.all(8),
            margin: const EdgeInsets.all(8),
            dismissDirection: FlutterWebSnackDismissDirection.HORIZONTAL,
            duration: Duration(seconds: 4),
            snackbarStyle: FlutterWebSnackStyle.FLOATING,
            forwardAnimationCurve: Curves.bounceInOut,
            reverseAnimationCurve: Curves.bounceInOut,
            barBlur: 15,
            snackbarPosition: FlutterWebSnackPosition.BottomRight,
            snackbarAnimations: SnackbarAnimations.FadeInSlideOut,
            animationDuration: Duration(milliseconds: 400),
            message:
                "Lorem Ipsum is simply dummy text of the printing and typesetting industry",
          )..show(context);
        },
      ),
    );
  }
}
