import 'dart:async';

import 'package:flutter/material.dart';
import 'package:scopa/card_arc.dart';
import 'package:scopa/main_title.dart';

class SignInMenu extends StatelessWidget {
  const SignInMenu({
    super.key,
    required this.signIn,
  });

  final Future<void> Function() signIn;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 600,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            MainTitle(),
            Hero(tag: 'arc', child: CardArc()),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Color.fromARGB(255, 0, 136, 255),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 25),
                textStyle: TextStyle(fontSize: 20),
              ),
              onPressed: signIn,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(2.0),
                    child: Icon(Icons.account_circle_rounded),
                  ),
                  Text('Sign in with Google'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
