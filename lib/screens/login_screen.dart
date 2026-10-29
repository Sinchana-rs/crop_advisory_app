import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dashboard_screen.dart';

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
      showMessage("Please enter your email address.");
      return;
    }

    if (password.isEmpty) {
      showMessage("Please enter your password.");
      return;
    }

    if (!isValidEmail(email)) {
      showMessage("Please enter a valid email address.");
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
              "No account found with this email or the password is incorrect.";
          break;

        case 'wrong-password':
          message = "Incorrect password. Please try again.";
          break;

        case 'invalid-email':
          message = "Please enter a valid email address.";
          break;

        case 'user-disabled':
          message = "This account has been disabled.";
          break;

        case 'too-many-requests':
          message =
              "Too many login attempts. Please try again later.";
          break;

        case 'network-request-failed':
          message =
              "Network error. Please check your internet connection.";
          break;

        default:
          message =
              "Login failed. Please check your email and password.";
      }

      showMessage(message);
    } catch (e) {
      if (!mounted) return;
      showMessage("Something went wrong. Please try again.");
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
      showMessage("Please enter your email address.");
      return;
    }

    if (password.isEmpty) {
      showMessage("Please enter a password.");
      return;
    }

    if (!isValidEmail(email)) {
      showMessage("Please enter a valid email address.");
      return;
    }

    if (password.length < 6) {
      showMessage(
        "Password must contain at least 6 characters.",
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
        "Account created successfully. You can now login.",
      );

      // Clear password after successful registration.
      passwordController.clear();

    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      String message;

      switch (e.code) {
        case 'email-already-in-use':
          message =
              "An account already exists with this email. Please login.";
          break;

        case 'invalid-email':
          message = "Please enter a valid email address.";
          break;

        case 'weak-password':
          message =
              "Password is too weak. Use at least 6 characters.";
          break;

        case 'operation-not-allowed':
          message =
              "Email/password registration is not enabled in Firebase.";
          break;

        case 'network-request-failed':
          message =
              "Network error. Please check your internet connection.";
          break;

        default:
          message =
              "Registration failed. Please try again.";
      }

      showMessage(message);
    } catch (e) {
      if (!mounted) return;
      showMessage("Something went wrong. Please try again.");
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
        "Please enter your registered email first.",
      );
      return;
    }

    if (!isValidEmail(email)) {
      showMessage(
        "Please enter a valid email address.",
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
        "Password reset email sent to $email",
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      String message;

      switch (e.code) {
        case 'user-not-found':
          message =
              "No account is registered with this email.";
          break;

        case 'invalid-email':
          message =
              "Please enter a valid email address.";
          break;

        case 'network-request-failed':
          message =
              "Network error. Please check your internet connection.";
          break;

        default:
          message =
              "Unable to send password reset email.";
      }

      showMessage(message);
    } catch (e) {
      if (!mounted) return;

      showMessage(
        "Something went wrong. Please try again.",
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
                    "AgriSense AI",
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade900,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    "Login",
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
                      hintText: "Email ID",
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
                      hintText: "Password",

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
                        "Forgot Password?",
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
                          : const Text(
                              "Login",
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

                    child: const Text(
                      "Don't have an account? Register",
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