// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController nameC = TextEditingController();
  final TextEditingController emailC = TextEditingController();
  final TextEditingController passC = TextEditingController();
  final TextEditingController confirmPassC = TextEditingController();

  final List<String> availableClasses = ['10', '11', '12'];
  String? selectedClass;

  bool isLoading = false;
  bool _isPassVisible = false;
  bool _isConfirmPassVisible = false;

  @override
  void dispose() {
    nameC.dispose();
    emailC.dispose();
    passC.dispose();
    confirmPassC.dispose();
    super.dispose();
  }

  String _mapToRoman(String number) {
    switch (number) {
      case '10':
        return 'X';
      case '11':
        return 'XI';
      case '12':
        return 'XII';
      default:
        return number;
    }
  }

  Future<void> registerUser() async {
    if (nameC.text.isEmpty ||
        emailC.text.isEmpty ||
        passC.text.isEmpty ||
        confirmPassC.text.isEmpty ||
        selectedClass == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Semua field wajib diisi, termasuk kelas."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (passC.text != confirmPassC.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Password tidak sama. Mohon periksa kembali."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      setState(() => isLoading = true);

      UserCredential userCred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: emailC.text.trim(),
            password: passC.text.trim(),
          );

      String uid = userCred.user!.uid;

      await FirebaseFirestore.instance.collection("users").doc(uid).set({
        "name": nameC.text,
        "email": emailC.text,
        "role": "siswa",
        "kelas": selectedClass,
        "interests": [],
        "hasSetInterests": false,
        "createdAt": FieldValue.serverTimestamp(),
      });

      setState(() => isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Registrasi berhasil! Silakan login.")),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    } on FirebaseAuthException catch (e) {
      setState(() => isLoading = false);
      String errorMessage = "Registrasi gagal: ${e.message}";
      if (e.code == 'weak-password') {
        errorMessage = "Password terlalu lemah.";
      } else if (e.code == 'email-already-in-use') {
        errorMessage = "Email sudah terdaftar.";
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Terjadi kesalahan tak terduga saat registrasi."),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  InputDecoration _getInputDecoration(String label, {Widget? suffixIcon}) {
    return InputDecoration(
      labelText: label,
      floatingLabelBehavior: FloatingLabelBehavior.never,
      filled: true,
      fillColor: Colors.grey.shade100,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(50),
        borderSide: BorderSide.none,
      ),
      suffixIcon: suffixIcon,
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool isVisible,
    required ValueChanged<bool> toggleVisibility,
  }) {
    return TextField(
      controller: controller,
      obscureText: !isVisible,
      decoration: _getInputDecoration(
        label,
        suffixIcon: IconButton(
          icon: Icon(
            isVisible ? Icons.visibility : Icons.visibility_off,
            color: Colors.grey,
          ),
          onPressed: () => toggleVisibility(!isVisible),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          children: [
            const Center(
              child: Text(
                "VokaPedia",
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 40),
            const Text(
              "Daftar",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              "Buat akun baru untuk mulai belajar 🎉",
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
            const SizedBox(height: 30),
            TextField(
              controller: nameC,
              decoration: _getInputDecoration("Nama Lengkap"),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailC,
              decoration: _getInputDecoration("Email"),
            ),
            const SizedBox(height: 16),
            _buildPasswordField(
              controller: passC,
              label: "Password",
              isVisible: _isPassVisible,
              toggleVisibility: (val) => setState(() => _isPassVisible = val),
            ),
            const SizedBox(height: 16),
            _buildPasswordField(
              controller: confirmPassC,
              label: "Konfirmasi Password",
              isVisible: _isConfirmPassVisible,
              toggleVisibility: (val) =>
                  setState(() => _isConfirmPassVisible = val),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: _getInputDecoration("Pilih Kelas"),
              hint: const Text("Pilih Kelas Anda"),
              items: availableClasses.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text('Kelas ${_mapToRoman(value)}'),
                );
              }).toList(),
              onChanged: (val) => setState(() => selectedClass = val),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : registerUser,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50),
                  ),
                ),
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        "Daftar",
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
              ),
            ),
            const SizedBox(height: 40),
            Center(
              child: GestureDetector(
                onTap: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                ),
                child: RichText(
                  text: TextSpan(
                    text: "Sudah punya akun? ",
                    style: TextStyle(color: Colors.grey.shade600),
                    children: const [
                      TextSpan(
                        text: "Masuk",
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
