// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:vokapedia/utils/color_constants.dart';

class DataDiriScreen extends StatefulWidget {
  const DataDiriScreen({super.key});

  @override
  State<DataDiriScreen> createState() => _DataDiriScreenState();
}

class _DataDiriScreenState extends State<DataDiriScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _hobbyController = TextEditingController();
  final TextEditingController _birthDateController = TextEditingController();

  String? _selectedGender;
  DateTime? _selectedDate;

  final User? user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (user == null) return;

    String email = user!.email ?? '';
    String? name = user!.displayName;

    try {
      DocumentSnapshot snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();

      if (snap.exists) {
        final data = snap.data() as Map<String, dynamic>;
        name ??= data['name'];
        _addressController.text = data['address'] ?? '';
        _hobbyController.text = data['hobby'] ?? '';
        _selectedGender = data['gender'];
        _birthDateController.text = data['birthDate'] ?? '';
        if (data['birthDate'] != null && data['birthDate'].toString().isNotEmpty) {
          _selectedDate = DateTime.tryParse(data['birthDate']);
        }
      }
    } catch (_) {}

    setState(() {
      _nameController.text =
          name ?? (email.isNotEmpty ? email.split('@')[0] : '');
      _emailController.text = email;
    });
  }

  Future<void> _saveData() async {
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .set({
      'name': _nameController.text.trim(),
      'email': _emailController.text.trim(),
      'address': _addressController.text.trim(),
      'hobby': _hobbyController.text.trim(),
      'gender': _selectedGender ?? '',
      'birthDate': _birthDateController.text.trim(),
    }, SetOptions(merge: true));

    await user!.updateDisplayName(_nameController.text.trim());

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data berhasil disimpan')),
      );
    }
  }

  Future<void> _pickBirthDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.black,
              onPrimary: Colors.white,
              onSurface: AppColors.black,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _birthDateController.text =
            DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  InputDecoration _inputDecoration() {
    return const InputDecoration(
      border: OutlineInputBorder(),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(
          color: AppColors.black,
          width: 1.5,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: const Text(
          'Data Diri',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.black,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
           

            const Text('Nama Lengkap'),
            const SizedBox(height: 6),
            TextField(
              controller: _nameController,
              decoration: _inputDecoration(),
            ),

            const SizedBox(height: 16),
            const Text('Email'),
            const SizedBox(height: 6),
            TextField(
              controller: _emailController,
              enabled: false,
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),

            const SizedBox(height: 16),
            const Text('Jenis Kelamin'),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: _selectedGender,
              hint: const Text('Pilih jenis kelamin'),
              items: const [
                DropdownMenuItem(
                    value: 'Laki-laki', child: Text('Laki-laki')),
                DropdownMenuItem(
                    value: 'Perempuan', child: Text('Perempuan')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedGender = value;
                });
              },
              decoration: _inputDecoration(),
            ),

            const SizedBox(height: 16),
            const Text('Tanggal Lahir'),
            const SizedBox(height: 6),
            TextField(
              controller: _birthDateController,
              readOnly: true,
              onTap: _pickBirthDate,
              decoration: _inputDecoration().copyWith(
                suffixIcon: const Icon(Icons.calendar_today),
              ),
            ),

            const SizedBox(height: 16),
            const Text('Alamat'),
            const SizedBox(height: 6),
            TextField(
              controller: _addressController,
              decoration: _inputDecoration(),
            ),

            const SizedBox(height: 16),
            const Text('Hobi'),
            const SizedBox(height: 6),
            TextField(
              controller: _hobbyController,
              decoration: _inputDecoration(),
            ),

            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  'Simpan',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
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
