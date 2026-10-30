import 'package:flutter/material.dart';
import 'package:scopa/theme.dart';

/// The sign-in button shown under the title before the player signs in.
class SignInMenu extends StatelessWidget {
  const SignInMenu({super.key, required this.signIn, required this.busy});

  final Future<void> Function() signIn;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFF0088FF),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 22),
        textStyle: const TextStyle(fontFamily: fontFamily, fontSize: 18, fontWeight: FontWeight.w800),
      ),
      onPressed: busy ? null : signIn,
      icon: busy
          ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2.5))
          : const Icon(Icons.account_circle_rounded),
      label: const Text('Sign in with Google'),
    );
  }
}
