// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
//
// import '../providers/app_state_provider.dart';
//
//
// import 'package:google_sign_in/google_sign_in.dart';
//
// final GoogleSignIn _googleSignIn = GoogleSignIn(
//   scopes: [
//     'email',
//     'https://www.googleapis.com/auth/fitness.activity.read',
//     'https://www.googleapis.com/auth/fitness.body.read',
//   ],
// );
//
// class LoginScreen extends StatefulWidget {
//   const LoginScreen({super.key});
//
//   @override
//   State<LoginScreen> createState() => _LoginScreenState();
// }
//
// class _LoginScreenState extends State<LoginScreen> {
//   final TextEditingController _emailController = TextEditingController();
//   final TextEditingController _passwordController = TextEditingController();
//   bool _isSignUpMode = false;
//   bool _navigated = false;
//
//   @override
//   void dispose() {
//     _emailController.dispose();
//     _passwordController.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//
//     return Consumer<AppStateProvider>(
//       builder: (context, appState, _) {
//         if (appState.isSignedIn && !_navigated) {
//           _navigated = true;
//           WidgetsBinding.instance.addPostFrameCallback((_) {
//             if (!mounted) {
//               return;
//             }
//             Navigator.of(context).pushReplacementNamed('/home');
//           });
//         }
//
//         return Scaffold(
//           body: Container(
//             decoration: const BoxDecoration(
//               gradient: LinearGradient(
//                 colors: [Color(0xFFEAF8F1), Color(0xFFD4EDE1)],
//                 begin: Alignment.topCenter,
//                 end: Alignment.bottomCenter,
//               ),
//             ),
//             child: SafeArea(
//               child: Center(
//                 child: SingleChildScrollView(
//                   padding: const EdgeInsets.all(24),
//                   child: Card(
//                     child: Padding(
//                       padding: const EdgeInsets.all(20),
//                       child: Column(
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           const Text(
//                             'Welcome to StressSense:\nManage Your Wellness',
//                             textAlign: TextAlign.center,
//                             style: TextStyle(
//                               fontSize: 24,
//                               fontWeight: FontWeight.w600,
//                             ),
//                           ),
//                           const SizedBox(height: 18),
//                           CircleAvatar(
//                             radius: 36,
//                             backgroundColor: theme.colorScheme.primaryContainer,
//                             child: const Icon(
//                               Icons.lock_person_rounded,
//                               size: 40,
//                             ),
//                           ),
//                           const SizedBox(height: 20),
//                           TextField(
//                             controller: _emailController,
//                             keyboardType: TextInputType.emailAddress,
//                             textInputAction: TextInputAction.next,
//                             decoration: const InputDecoration(
//                               prefixIcon: Icon(Icons.person_outline),
//                               hintText: 'Email',
//                             ),
//                           ),
//                           const SizedBox(height: 12),
//                           TextField(
//                             controller: _passwordController,
//                             obscureText: true,
//                             textInputAction: TextInputAction.done,
//                             decoration: const InputDecoration(
//                               prefixIcon: Icon(Icons.lock_outline),
//                               hintText: 'Password',
//                             ),
//                           ),
//                           const SizedBox(height: 16),
//                           SizedBox(
//                             width: double.infinity,
//                             child: FilledButton(
//                               onPressed: appState.isLoading
//                                   ? null
//                                   : () async {
//                                 final appProvider = context
//                                     .read<AppStateProvider>();
//                                 final success = _isSignUpMode
//                                     ? await appProvider.signUpWithEmail(
//                                         email: _emailController.text,
//                                         password: _passwordController.text,
//                                       )
//                                     : await appProvider.loginWithEmail(
//                                         email: _emailController.text,
//                                         password: _passwordController.text,
//                                       );
//                                 if (!context.mounted) {
//                                   return;
//                                 }
//                                 if (success && appProvider.isSignedIn) {
//                                   Navigator.of(
//                                     context,
//                                   ).pushReplacementNamed('/home');
//                                 }
//                               },
//                               child: Text(_isSignUpMode ? 'Sign Up' : 'Login'),
//                             ),
//                           ),
//                           if (appState.statusMessage.isNotEmpty) ...[
//                             const SizedBox(height: 8),
//                             Text(
//                               appState.statusMessage,
//                               textAlign: TextAlign.center,
//                               style: TextStyle(color: theme.colorScheme.error),
//                             ),
//                           ],
//                           const SizedBox(height: 8),
//                           Row(
//                             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                             children: [
//                               TextButton(
//                                 onPressed: appState.isLoading
//                                     ? null
//                                     : () {
//                                         setState(() {
//                                           _isSignUpMode = !_isSignUpMode;
//                                         });
//                                       },
//                                 child: Text(
//                                   _isSignUpMode
//                                       ? 'Already have an account? Login'
//                                       : 'New User? Sign Up',
//                                 ),
//                               ),
//                               const Text('Forget Password?'),
//                             ],
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }
// }


import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isSignUpMode = false;
  bool _navigated = false;

  Future<void> signInWithGoogle() async {
    final appProvider = context.read<AppStateProvider>();
    final success = await appProvider.signInWithGoogle();
    if (!mounted) {
      return;
    }
    if (success) {
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer<AppStateProvider>(
      builder: (context, appState, _) {
        if (appState.isSignedIn && !_navigated) {
          _navigated = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            Navigator.of(context).pushReplacementNamed('/home');
          });
        }

        return Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFEAF8F1), Color(0xFFD4EDE1)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Welcome to StressSense:\nManage Your Wellness',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                            ),
                          ),

                          const SizedBox(height: 18),

                          CircleAvatar(
                            radius: 36,
                            backgroundColor:
                            theme.colorScheme.primaryContainer,
                            child: const Icon(
                              Icons.lock_person_rounded,
                              size: 40,
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Email
                          TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.person_outline),
                              hintText: 'Email',
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Password
                          TextField(
                            controller: _passwordController,
                            obscureText: true,
                            textInputAction: TextInputAction.done,
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.lock_outline),
                              hintText: 'Password',
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Email Login Button
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: appState.isLoading
                                  ? null
                                  : () async {
                                final appProvider =
                                context.read<AppStateProvider>();

                                final success = _isSignUpMode
                                    ? await appProvider.signUpWithEmail(
                                  email: _emailController.text,
                                  password:
                                  _passwordController.text,
                                )
                                    : await appProvider.loginWithEmail(
                                  email: _emailController.text,
                                  password:
                                  _passwordController.text,
                                );

                                if (!context.mounted) return;

                                if (success &&
                                    appProvider.isSignedIn) {
                                  Navigator.of(context)
                                      .pushReplacementNamed('/home');
                                }
                              },
                              child:
                              Text(_isSignUpMode ? 'Sign Up' : 'Login'),
                            ),
                          ),

                          // ✅ Google Button
                          const SizedBox(height: 12),

                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: signInWithGoogle,
                              child: const Text("Continue with Google"),
                            ),
                          ),

                          // Error / Status
                          if (appState.statusMessage.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              appState.statusMessage,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: theme.colorScheme.error,
                              ),
                            ),
                          ],

                          const SizedBox(height: 8),

                          Row(
                            mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                            children: [
                              TextButton(
                                onPressed: appState.isLoading
                                    ? null
                                    : () {
                                  setState(() {
                                    _isSignUpMode =
                                    !_isSignUpMode;
                                  });
                                },
                                child: Text(
                                  _isSignUpMode
                                      ? 'Already have an account? Login'
                                      : 'New User? Sign Up',
                                ),
                              ),
                              const Text('Forget Password?'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
