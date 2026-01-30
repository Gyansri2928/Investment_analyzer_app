import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/auth_controller.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AuthController());

    // Helper for Text Styles
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      // Gradient Background (Optional, or standard color)
      backgroundColor: isDark
          ? const Color(0xFF1E1E1E)
          : const Color(0xFFF5F7FA),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 500,
            ), // Card max width like web
            child: Card(
              elevation: 5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Obx(
                  () => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // --- 1. HEADER (Logo & Welcome) ---
                      Container(
                        width: 80,
                        height: 80,
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: theme.primaryColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Image.asset(
                          'assets/logo.png', // ✅ Make sure this asset exists!
                          fit: BoxFit.contain,
                          errorBuilder: (c, o, s) => Icon(
                            Icons.home,
                            size: 40,
                            color: theme.primaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Access Property Tools",
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        controller.isLogin.value
                            ? "Welcome back! Please sign in to continue."
                            : "Create an account to save your investment scenarios.",
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // --- 2. TITLE TOGGLE ---
                      Text(
                        controller.isLogin.value
                            ? "Sign In to Your Account"
                            : "Create New Account",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // --- 3. ALERTS (Success / Error) ---
                      if (controller.showSuccess.value)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.green.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  controller.successMessage.value,
                                  style: const TextStyle(color: Colors.green),
                                ),
                              ),
                              InkWell(
                                onTap: () =>
                                    controller.showSuccess.value = false,
                                child: const Icon(
                                  Icons.close,
                                  size: 16,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ),

                      if (controller.errorMessage.value.isNotEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.red.withOpacity(0.3),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.error,
                                    color: Colors.red,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      controller.errorMessage.value,
                                      style: const TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                              // Matches "Resend Verification" button logic
                              if (controller.errorMessage.value.contains(
                                "verify your email",
                              ))
                                Padding(
                                  padding: const EdgeInsets.only(
                                    top: 8,
                                    left: 30,
                                  ),
                                  child: OutlinedButton.icon(
                                    onPressed: controller.resendVerification,
                                    icon: const Icon(
                                      Icons.refresh,
                                      size: 14,
                                      color: Colors.red,
                                    ),
                                    label: const Text(
                                      "Resend Verification Email",
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontSize: 12,
                                      ),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(color: Colors.red),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 5,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),

                      // --- 4. FORM FIELDS ---
                      // Email Input
                      TextField(
                        onChanged: (val) => controller.email.value = val,
                        decoration: const InputDecoration(
                          labelText: "Email Address",
                          prefixIcon: Icon(Icons.email_outlined),
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),

                      // Password Input (With Visibility Toggle)
                      TextField(
                        onChanged: (val) => controller.password.value = val,
                        obscureText: !controller.showPassword.value,
                        decoration: InputDecoration(
                          labelText: "Password",
                          prefixIcon: const Icon(Icons.lock_outline),
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: Icon(
                              controller.showPassword.value
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: controller.togglePasswordVisibility,
                          ),
                        ),
                      ),
                      if (!controller.isLogin.value) ...[
                        const SizedBox(height: 16),
                        TextField(
                          onChanged: (val) =>
                              controller.confirmPassword.value = val,
                          obscureText:
                              !controller.showPassword.value, // Sync visibility
                          decoration: const InputDecoration(
                            labelText: "Retype Password",
                            prefixIcon: Icon(Icons.lock_reset),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Obx(() {
                            if (controller.confirmPassword.value.isEmpty) {
                              return const SizedBox.shrink(); // Hide if empty
                            }
                            final isMatch =
                                controller.password.value ==
                                controller.confirmPassword.value;
                            return Row(
                              children: [
                                Icon(
                                  isMatch ? Icons.check_circle : Icons.cancel,
                                  size: 14,
                                  color: isMatch ? Colors.green : Colors.red,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isMatch
                                      ? "Passwords matched"
                                      : "Passwords do not match",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isMatch ? Colors.green : Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            );
                          }),
                        ),
                      ] else ...[
                        const SizedBox(height: 5),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "Password must be at least 6 characters long",
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ),
                      ],

                      // Forgot Password Link (Only in Login mode)
                      if (controller.isLogin.value)
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: controller.isLoading.value
                                ? null
                                : controller.forgotPassword,
                            icon: const Icon(Icons.vpn_key, size: 14),
                            label: const Text("Forgot Password?"),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                            ),
                          ),
                        ),

                      const SizedBox(height: 24),

                      // --- 5. MAIN BUTTON ---
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: controller.isLoading.value
                              ? null
                              : () {
                                  // 1. Close Keyboard immediately to prevent focus error
                                  FocusManager.instance.primaryFocus?.unfocus();

                                  // 2. Then submit
                                  controller.submit();
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: controller.isLoading.value
                              ? const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    ),
                                    SizedBox(width: 10),
                                    Text("Processing..."),
                                  ],
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      controller.isLogin.value
                                          ? Icons.login
                                          : Icons.person_add,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      controller.isLogin.value
                                          ? "Sign In"
                                          : "Create Account",
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ],
                                ),
                        ),
                      ),

                      // --- 6. INFO ALERT (Sign Up Mode) ---
                      if (!controller.isLogin.value)
                        Container(
                          margin: const EdgeInsets.only(top: 16),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 20,
                                color: Colors.blue,
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  "After signing up, you'll receive a verification email. You must verify before signing in.",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 20),

                      // --- 7. TOGGLE MODE LINK ---
                      TextButton(
                        onPressed: controller.toggleMode,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              controller.isLogin.value
                                  ? Icons.person_add
                                  : Icons.login,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              controller.isLogin.value
                                  ? "Don't have an account? Sign Up"
                                  : "Already have an account? Sign In",
                            ),
                          ],
                        ),
                      ),

                      const Divider(height: 40),

                      // --- 8. FOOTER INFO ---
                      const Wrap(
                        spacing: 10,
                        runSpacing: 5,
                        alignment: WrapAlignment.center,
                        children: [
                          FooterItem(icon: Icons.security, text: "Data Secure"),
                          FooterItem(
                            icon: Icons.info_outline,
                            text: "Use Strong Password",
                          ),
                          FooterItem(
                            icon: Icons.email_outlined,
                            text: "Check Spam Folder",
                          ),
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
  }
}

// Small helper widget for the footer items
class FooterItem extends StatelessWidget {
  final IconData icon;
  final String text;
  const FooterItem({super.key, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: Colors.grey),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }
}
