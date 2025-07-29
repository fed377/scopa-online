import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:scopa/utils.dart';

class FinishedMenu extends StatelessWidget {
  const FinishedMenu({
    super.key,
    required this.data,
    required this.p,
    required this.op,
    required this.cb,
  });

  final Stream<DocumentSnapshot<Map<String, dynamic>>> data;
  final String p;
  final String op;
  final void Function() cb;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
        stream: data,
        builder: (context, snapshot) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: pad([
              Row(
                mainAxisSize: MainAxisSize.min,
                children: pad([
                  Text('Your Score: ${snapshot.data!['${p}Score']}'),
                  Text("Opponents' Score: ${snapshot.data!['${op}Score']}"),
                ]),
              ),
              FilledButton(onPressed: cb, child: Text('Restart game (round ${snapshot.data!['round'] + 1})')),
            ]),
          );
        });
  }
}
