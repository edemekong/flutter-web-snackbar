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
      backgroundColor: Colors.red,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          FlutterWebSnackbar(
            title: "Hey Fairy",
            titleText: Text('Text Copied'),
            messageText: Text('Copied to clipboard'),
            backgroundColor: Colors.white,
            borderRadius: 14,
            maxWidth: 300,
            icon: Icon(Icons.info, color: Colors.blue),
            padding: const EdgeInsets.all(8),
            margin: const EdgeInsets.all(8),
            dismissDirection: FlutterWebSnackDismissDirection.HORIZONTAL,
            duration: Duration(seconds: 4),
            snackbarStyle: FlutterWebSnackStyle.FLOATING,
            forwardAnimationCurve: Curves.easeIn,
            reverseAnimationCurve: Curves.easeOut,
            barBlur: 15,
            snackbarPosition: FlutterWebSnackPosition.BottomRight,
            animationDuration: Duration(milliseconds: 400),
            message:
                "Lorem Ipsum is simply dummy text of the printing and typesetting industry",
          )..show(context);
        },
      ),
    );
  }
}
