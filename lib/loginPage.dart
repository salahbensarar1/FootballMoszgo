import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:footballtraining/views/adminScreen.dart';
import 'package:footballtraining/views/coachScreen.dart';
import 'package:footballtraining/views/receptionistScreen.dart';

class Loginpage extends StatefulWidget {
  const Loginpage({super.key});

  @override
  State<Loginpage> createState() => _LoginpageState();
}

class _LoginpageState extends State<Loginpage> {
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  bool isLoading = false; // For loading state

  Future<void> loginUser() async {
    setState(() {
      isLoading = true;
    });

    try {
      FirebaseAuth auth = FirebaseAuth.instance;
      UserCredential userCredential = await auth.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      User? user = userCredential.user;

      if (user != null) {
        // 🔹 Query Firestore for user document using email instead of UID
        QuerySnapshot userQuery = await FirebaseFirestore.instance
            .collection('users')
            .where('email', isEqualTo: user.email)
            .limit(1)
            .get();

        if (userQuery.docs.isEmpty) {
          throw Exception("User not found in Firestore.");
        }

        DocumentSnapshot userDoc = userQuery.docs.first;

        // 🔹 Check if "role" field exists
        if (!userDoc.data().toString().contains("role")) {
          throw Exception("Role field missing in Firestore.");
        }

        String role = userDoc['role'];

        // 🔹 Navigate to the correct screen based on role
        if (role == 'admin') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const AdminScreen()),
          );
        } else if (role == 'receptionist') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const ReceptionistScreen()),
          );
        } else if (role == 'coach') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const CoachScreen()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Unauthorized role: $role")),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Login failed: $e")),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }
  // Future<void> loginUser() async {
  //   setState(() {
  //     isLoading = true;
  //   });
  //
  //   try {
  //     // ✅ Ensure Firebase is initialized
  //     FirebaseApp app =
  //         Firebase.app('foottraining-4051b'); // ✅ Use the named Firebase app
  //     FirebaseAuth auth =
  //         FirebaseAuth.instanceFor(app: app); // ✅ Explicitly use this app
  //
  //     UserCredential userCredential = await auth.signInWithEmailAndPassword(
  //       email: emailController.text.trim(),
  //       password: passwordController.text.trim(),
  //     );
  //
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text("Login Successful!")),
  //     );
  //   } on FirebaseAuthException catch (e) {
  //     String message = "Login failed";
  //     if (e.code == 'user-not-found') {
  //       message = "No user found for this email.";
  //     } else if (e.code == 'wrong-password') {
  //       message = "Incorrect password.";
  //     } else if (e.code == 'app-not-initialized') {
  //       message = "Firebase is not initialized.";
  //     }
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text(message)),
  //     );
  //   } finally {
  //     setState(() {
  //       isLoading = false;
  //     });
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.symmetric(vertical: 30),
        width: double.infinity,
        decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [
          Color(0xFFF27121),
          Color(0xFF654ea3),
          Color(0xFfeaafc8),
        ], begin: Alignment.topCenter)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const SizedBox(height: 80),
            const Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    "Login",
                    style: TextStyle(color: Colors.white, fontSize: 40),
                  ),
                  Text(
                    "Welcome back",
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  )
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(60),
                      topRight: Radius.circular(60)),
                ),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(30),
                    child: Column(children: <Widget>[
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: const [
                            BoxShadow(
                                color: Color.fromRGBO(225, 95, 27, .3),
                                blurRadius: 20,
                                offset: Offset(0, 10))
                          ],
                        ),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: <Widget>[
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: const BoxDecoration(
                                  border: Border(
                                      bottom: BorderSide(
                                          color: Color(0xFFEEEEEE)))),
                              child: TextField(
                                controller: emailController,
                                decoration: const InputDecoration(
                                    hintText: "Email or Phone Number",
                                    hintStyle: TextStyle(color: Colors.grey),
                                    border: InputBorder.none),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: const BoxDecoration(
                                  border: Border(
                                      bottom: BorderSide(
                                          color: Color(0xFFEEEEEE)))),
                              child: TextField(
                                controller: passwordController,
                                obscureText: true, // Hide password input
                                decoration: const InputDecoration(
                                    hintText: "Password",
                                    hintStyle: TextStyle(color: Colors.grey),
                                    border: InputBorder.none),
                              ),
                            ),
                            const SizedBox(height: 40),
                            Container(
                              height: 50,
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 50),
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(50),
                                  color: const Color(0xFFF37A2B)),
                              child: Center(
                                child: TextButton(
                                  onPressed: isLoading ? null : loginUser,
                                  child: isLoading
                                      ? const CircularProgressIndicator(
                                          color: Colors.white)
                                      : const Text(
                                          "Login",
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold),
                                        ),
                                ),
                              ),
                            ),
                            TextButton(
                                onPressed: () {},
                                child: Text("Admin Management")),
                          ],
                        ),
                      )
                    ]),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
