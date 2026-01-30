import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart'; // Or your Home/Main Page

class AuthController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late Rx<User?> firebaseUser = Rx<User?>(_auth.currentUser);

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  @override
  void onInit() {
    // ✅ 2. Use onInit (Runs before the App builds)
    super.onInit();
    firebaseUser.bindStream(_auth.userChanges());
    emailController.addListener(() => email.value = emailController.text);
    passwordController.addListener(
      () => password.value = passwordController.text,
    );
    confirmPasswordController.addListener(
      () => confirmPassword.value = confirmPasswordController.text,
    );
  }

  @override
  void onClose() {
    // Clean up controllers
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }

  // =========================================================
  // 1. OBSERVABLE STATE (Matching React State)
  // =========================================================
  var email = ''.obs;
  var password = ''.obs;
  var confirmPassword = ''.obs;

  var isLogin = true.obs; // Toggle between Login/Signup
  var showPassword = false.obs; // Toggle password visibility
  var isLoading = false.obs;

  var errorMessage = ''.obs; // For error alerts
  var successMessage = ''.obs; // For success alerts
  var showSuccess = false.obs; // To toggle success alert visibility

  // =========================================================
  // 2. ACTIONS (Matching React Functions)
  // =========================================================

  void toggleMode() {
    isLogin.value = !isLogin.value;
    errorMessage.value = '';
    successMessage.value = '';
    showSuccess.value = false;
    confirmPassword.value = '';
    passwordController.clear();
    confirmPasswordController.clear();
  }

  void togglePasswordVisibility() {
    showPassword.value = !showPassword.value;
  }

  // MATCHING REACT: handleSubmit
  Future<void> submit() async {
    // Reset alerts
    errorMessage.value = '';
    successMessage.value = '';
    showSuccess.value = false;
    isLoading.value = true;

    try {
      if (isLogin.value) {
        // --- LOGIN LOGIC ---
        UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          email: email.value.trim(),
          password: password.value.trim(),
        );

        User? user = userCredential.user;

        if (user != null) {
          if (!user.emailVerified) {
            // ❌ Block access if email not verified
            errorMessage.value =
                'Please verify your email before signing in. Check your inbox.';
            await _auth.signOut();
            isLoading.value = false; // ✅ Safe to stop spinner (staying on page)
          } else {
            // ✅ SUCCESS
            // 1. Close keyboard immediately
            FocusManager.instance.primaryFocus?.unfocus();

            // 2. DO NOT stop the spinner (isLoading = false)
            // 3. DO NOT navigate manually (Get.offAll)
            // The AuthGate in main.dart will detect the user change
            // and switch the screen automatically.
            return;
          }
        }
      } else {
        // --- SIGN UP LOGIC ---
        if (password.value != confirmPassword.value) {
          errorMessage.value = "Passwords do not match.";
          isLoading.value = false;
          return; // Stop execution
        }
        UserCredential userCredential = await _auth
            .createUserWithEmailAndPassword(
              email: email.value.trim(),
              password: password.value.trim(),
            );

        User? user = userCredential.user;
        if (user != null) {
          await user.sendEmailVerification();

          successMessage.value =
              'Account created! Please check your email to verify your account.';
          showSuccess.value = true;

          // Switch to login mode automatically
          isLogin.value = true;
          isLoading.value = false; // ✅ Stop spinner (staying on page)
        }
      }
    } on FirebaseAuthException catch (e) {
      // Error Handling
      String customMessage = "An error occurred. Please try again.";
      switch (e.code) {
        case 'invalid-credential':
        case 'wrong-password':
        case 'user-not-found':
          customMessage = "Incorrect email or password. Please try again.";
          break;
        case 'email-already-in-use':
          customMessage =
              "This email is already registered. Try logging in instead.";
          break;
        case 'weak-password':
          customMessage =
              "Password is too weak. Please use at least 6 characters.";
          break;
        case 'invalid-email':
          customMessage = "Please enter a valid email address.";
          break;
        case 'too-many-requests':
          customMessage = "Too many failed attempts. Please try again later.";
          break;
        default:
          customMessage = e.message ?? customMessage;
      }
      errorMessage.value = customMessage;
      isLoading.value = false; // ✅ Stop spinner on error
    } catch (e) {
      errorMessage.value = e.toString();
      isLoading.value = false; // ✅ Stop spinner on error
    }
    // ❌ FINALLY BLOCK REMOVED to prevent race condition
  }

  // MATCHING REACT: handleForgotPassword
  Future<void> forgotPassword() async {
    if (email.value.isEmpty) {
      errorMessage.value = 'Please enter your email address first';
      return;
    }

    isLoading.value = true;
    errorMessage.value = '';

    try {
      await _auth.sendPasswordResetEmail(email: email.value.trim());
      successMessage.value =
          'Password reset email sent to ${email.value}. Check your inbox!';
      showSuccess.value = true;
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  // MATCHING REACT: handleResendVerification
  Future<void> resendVerification() async {
    // Note: We need a user to send verification.
    // In this flow, we might need to prompt them to login again or handle it if we stored the user credential temp.
    // For simplicity, we assume they just tried to login and failed verification.
    try {
      // Re-sign in temp to get user object (silent login often needed here)
      // Or simply ask user to check spam.
      // If we are strictly following React, we use the currentUser.
      // But since we signed them out in submit() to block access, we can't get currentUser here easily.
      // Strategy: We show a message "Login again to resend" or we keep them logged in but on a "Waiting" screen.

      errorMessage.value =
          "Please sign in again to trigger a new verification email.";
    } catch (e) {
      errorMessage.value = e.toString();
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
    isLoading.value = false;
    email.value = '';
    password.value = '';
    confirmPassword.value = '';
    errorMessage.value = '';
    successMessage.value = '';
    showSuccess.value = false;
    isLogin.value = true;
  }
}
