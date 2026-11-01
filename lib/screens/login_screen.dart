import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dashboard_screen.dart';
import '../services/language_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;
  bool obscurePassword = true;

  // =========================================================
  // LOGIN
  // =========================================================

  Future<void> login() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty) {
      showMessage(LanguageService.t("auth_enter_email"));
      return;
    }

    if (password.isEmpty) {
      showMessage(LanguageService.t("auth_enter_password"));
      return;
    }

    if (!isValidEmail(email)) {
      showMessage(LanguageService.t("auth_valid_email"));
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => DashboardScreen(),
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      String message;

      switch (e.code) {
        case 'user-not-found':
        case 'invalid-credential':
          message =
              LanguageService.t("auth_bad_credentials");
          break;

        case 'wrong-password':
          message = LanguageService.t("auth_wrong_password");
          break;

        case 'invalid-email':
          message = LanguageService.t("auth_valid_email");
          break;

        case 'user-disabled':
          message = LanguageService.t("auth_user_disabled");
          break;

        case 'too-many-requests':
          message =
              LanguageService.t("auth_too_many");
          break;

        case 'network-request-failed':
          message =
              LanguageService.t("auth_network");
          break;

        default:
          message =
              LanguageService.t("auth_login_failed");
      }

      showMessage(message);
    } catch (e) {
      if (!mounted) return;
      showMessage(LanguageService.t("auth_generic"));
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // =========================================================
  // REGISTER
  // =========================================================

  Future<void> register() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty) {
      showMessage(LanguageService.t("auth_enter_email"));
      return;
    }

    if (password.isEmpty) {
      showMessage(LanguageService.t("auth_enter_new_password"));
      return;
    }

    if (!isValidEmail(email)) {
      showMessage(LanguageService.t("auth_valid_email"));
      return;
    }

    if (password.length < 6) {
      showMessage(
        LanguageService.t("auth_password_min6"),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (!mounted) return;

      showMessage(
        LanguageService.t("auth_account_created"),
      );

      // Clear password after successful registration.
      passwordController.clear();

    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      String message;

      switch (e.code) {
        case 'email-already-in-use':
          message =
              LanguageService.t("auth_email_in_use");
          break;

        case 'invalid-email':
          message = LanguageService.t("auth_valid_email");
          break;

        case 'weak-password':
          message =
              LanguageService.t("auth_weak_password");
          break;

        case 'operation-not-allowed':
          message =
              LanguageService.t("auth_op_not_allowed");
          break;

        case 'network-request-failed':
          message =
              LanguageService.t("auth_network");
          break;

        default:
          message =
              LanguageService.t("auth_register_failed");
      }

      showMessage(message);
    } catch (e) {
      if (!mounted) return;
      showMessage(LanguageService.t("auth_generic"));
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // =========================================================
  // FORGOT PASSWORD
  // =========================================================

  Future<void> forgotPassword() async {
    final email = emailController.text.trim();

    if (email.isEmpty) {
      showMessage(
        LanguageService.t("auth_enter_registered_email"),
      );
      return;
    }

    if (!isValidEmail(email)) {
      showMessage(
        LanguageService.t("auth_valid_email"),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: email,
      );

      if (!mounted) return;

      showMessage(
        LanguageService.t("auth_reset_sent").replaceAll("{email}", email),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      String message;

      switch (e.code) {
        case 'user-not-found':
          message =
              LanguageService.t("auth_no_account");
          break;

        case 'invalid-email':
          message =
              LanguageService.t("auth_valid_email");
          break;

        case 'network-request-failed':
          message =
              LanguageService.t("auth_network");
          break;

        default:
          message =
              LanguageService.t("auth_reset_failed");
      }

      showMessage(message);
    } catch (e) {
      if (!mounted) return;

      showMessage(
        LanguageService.t("auth_generic"),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // =========================================================
  // EMAIL VALIDATION
  // =========================================================

  bool isValidEmail(String email) {
    return RegExp(
      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
    ).hasMatch(email);
  }

  // =========================================================
  // MESSAGE
  // =========================================================

  void showMessage(String msg) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // =========================================================
  // DISPOSE
  // =========================================================

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xffE8F5E9),
              Color(0xffA5D6A7),
              Color(0xff4CAF50),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),

        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),

            child: Container(
              width: 380,
              padding: const EdgeInsets.all(28),

              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.25),
                borderRadius: BorderRadius.circular(28),

                border: Border.all(
                  color: Colors.white.withOpacity(0.7),
                ),

                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.3),
                    blurRadius: 30,
                    offset: const Offset(0, 15),
                  ),
                ],
              ),

              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [

                  // =================================================
                  // LOGO
                  // =================================================

                  Icon(
                    Icons.grass,
                    size: 70,
                    color: Colors.green.shade900,
                  ),

                  const SizedBox(height: 15),

                  // =================================================
                  // APP NAME
                  // =================================================

                  Text(
                    LanguageService.t("appName"),
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade900,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    LanguageService.t("auth_login"),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 25),

                  // =================================================
                  // EMAIL
                  // =================================================

                  TextField(
                    controller: emailController,

                    keyboardType:
                        TextInputType.emailAddress,

                    decoration: InputDecoration(
                      hintText: LanguageService.t("auth_email_hint"),
                      prefixIcon:
                          const Icon(Icons.email),

                      filled: true,

                      fillColor:
                          Colors.white.withOpacity(0.75),

                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(30),
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // =================================================
                  // PASSWORD
                  // =================================================

                  TextField(
                    controller: passwordController,

                    obscureText: obscurePassword,

                    decoration: InputDecoration(
                      hintText: LanguageService.t("auth_password_hint"),

                      prefixIcon:
                          const Icon(Icons.lock),

                      suffixIcon: IconButton(
                        icon: Icon(
                          obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),

                        onPressed: () {
                          setState(() {
                            obscurePassword =
                                !obscurePassword;
                          });
                        },
                      ),

                      filled: true,

                      fillColor:
                          Colors.white.withOpacity(0.75),

                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(30),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // =================================================
                  // FORGOT PASSWORD
                  // =================================================

                  Align(
                    alignment: Alignment.centerRight,

                    child: TextButton(
                      onPressed:
                          isLoading
                              ? null
                              : forgotPassword,

                      child: Text(
                        LanguageService.t("auth_forgot"),
                        style: TextStyle(
                          color:
                              Colors.green.shade900,

                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // =================================================
                  // LOGIN BUTTON
                  // =================================================

                  SizedBox(
                    width: double.infinity,
                    height: 50,

                    child: ElevatedButton(
                      onPressed:
                          isLoading ? null : login,

                      style:
                          ElevatedButton.styleFrom(
                        backgroundColor:
                            Colors.white,

                        foregroundColor:
                            Colors.green.shade900,

                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(30),
                        ),
                      ),

                      child: isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,

                              child:
                                  CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              LanguageService.t("auth_login"),
                              style: TextStyle(
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // =================================================
                  // REGISTER
                  // =================================================

                  TextButton(
                    onPressed:
                        isLoading ? null : register,

                    child: Text(
                              LanguageService.t("auth_register_prompt"),
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}