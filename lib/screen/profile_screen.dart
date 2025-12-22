// ignore_for_file: empty_catches, use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vokapedia/screen/auth/login_screen.dart';
import 'package:vokapedia/screen/data_diri_screen.dart';
import 'package:vokapedia/screen/faq_screen.dart';
import 'package:vokapedia/screen/keamanan_privasi_screen.dart';
import 'package:vokapedia/screen/laporkan_masalah_screen.dart';
import 'package:vokapedia/screen/tentang_vocapedia_screen.dart';
import 'package:vokapedia/utils/color_constants.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _userName = 'Nama Pengguna';
  String _userEmail = 'email tidak tersedia';
  String? _userPhotoUrl;
  List<String> _userInterests = [];

  @override
  void initState() {
    super.initState();
    _loadUserProfileData();
  }

  Future<void> _loadUserProfileData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      DocumentSnapshot snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (mounted) {
        setState(() {
          _userEmail = user.email ?? 'email tidak tersedia';
          _userPhotoUrl = user.photoURL;

          if (snap.exists) {
            Map<String, dynamic> data = snap.data() as Map<String, dynamic>;
            _userName = data['name'] ?? user.displayName ?? 'Nama Pengguna';
            _userInterests = List<String>.from(data['interests'] ?? []);
          } else {
            _userName = user.displayName ?? 'Nama Pengguna';
          }
        });
      }
    } catch (e) {}
  }

  void _showInterestDialog() {
    List<String> tempSelected = List.from(_userInterests);
    final List<String> categories = [
      "Materi Belajar",
      "Sastra",
      "Artikel Populer",
      "Artikel Ilmiah",
    ];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text(
                "Atur Minat Baca",
                style: TextStyle(
                  fontFamily: 'PlayfairDisplay',
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Pilih topik favoritmu untuk personalisasi rekomendasi artikel.",
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 15),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: categories.map((cat) {
                      final isSel = tempSelected.contains(cat);
                      return FilterChip(
                        label: Text(cat),
                        selected: isSel,
                        onSelected: (val) {
                          setDialogState(() {
                            val
                                ? tempSelected.add(cat)
                                : tempSelected.remove(cat);
                          });
                        },
                        backgroundColor: Colors.white,
                        selectedColor: AppColors.primaryBlue.withOpacity(0.2),
                        checkmarkColor: AppColors.primaryBlue,
                        shape: StadiumBorder(
                          side: BorderSide(
                            color: isSel
                                ? AppColors.primaryBlue
                                : Colors.grey.shade300,
                          ),
                        ),
                        labelStyle: TextStyle(
                          color: isSel ? AppColors.primaryBlue : Colors.black87,
                          fontSize: 12,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    "Batal",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () async {
                    final user = FirebaseAuth.instance.currentUser;
                    if (user != null) {
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(user.uid)
                          .update({
                            'interests': tempSelected,
                            'hasSetInterests': true,
                          });
                      if (mounted)
                        setState(() => _userInterests = tempSelected);
                    }
                    Navigator.pop(context);
                  },
                  child: const Text(
                    "Simpan",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  Future<void> _showLogoutConfirmation(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: const Text(
            'Keluar',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
          ),
          content: const Text(
            'Apakah kamu yakin ingin keluar dari akun ini?',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _logout(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
              child: const Text('Yakin', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSettingTile({
    required String title,
    required String subtitle,
    required IconData icon,
    VoidCallback? onTap,
    Color? iconColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300, width: 1.0),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 12.0,
              horizontal: 8.0,
            ),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 12.0, left: 4.0),
                  child: Icon(icon, color: iconColor ?? AppColors.black),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.black54),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double topContainerHeight = MediaQuery.of(context).size.height * 0.25;
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        toolbarHeight: 0,
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              height: topContainerHeight,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 5,
                    offset: Offset(0, 1.5),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.only(top: 20.0),
                child: Column(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.grey.shade200,
                          backgroundImage:
                              _userPhotoUrl != null && _userPhotoUrl!.isNotEmpty
                              ? NetworkImage(_userPhotoUrl!)
                              : null,
                          child: _userPhotoUrl == null || _userPhotoUrl!.isEmpty
                              ? Icon(
                                  Icons.person,
                                  size: 50,
                                  color: Colors.grey.shade600,
                                )
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: CircleAvatar(
                            radius: 15,
                            backgroundColor: AppColors.black,
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: const Icon(
                                Icons.edit,
                                size: 15,
                                color: Colors.white,
                              ),
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const DataDiriScreen(),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _userName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _userEmail,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Personalisasi",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  _buildSettingTile(
                    title: "Atur Minat Baca",
                    subtitle: "Sesuaikan topik artikel favoritmu",
                    icon: Icons.favorite,
                    iconColor: AppColors.black,
                    onTap: _showInterestDialog,
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    "Pengaturan Akun",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  _buildSettingTile(
                    title: "Data Diri",
                    subtitle: "Ubah data diri di sini",
                    icon: Icons.person,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const DataDiriScreen()),
                    ),
                  ),
                  _buildSettingTile(
                    title: "Keamanan dan Privasi",
                    subtitle: "Pelajari keamanan dan privasi",
                    icon: Icons.lock,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const KeamananPrivasiScreen(),
                      ),
                    ),
                  ),
                  _buildSettingTile(
                    title: "Tentang VokaPedia",
                    subtitle: "Ketahui lebih dalam tentang VocaPedia",
                    icon: Icons.info,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const TentangVocaPediaScreen(),
                      ),
                    ),
                  ),
                  _buildSettingTile(
                    title: "FAQ & Panduan",
                    subtitle: "Lihat panduan untuk penggunaan optimal",
                    icon: Icons.help,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const FAQScreen()),
                    ),
                  ),
                  _buildSettingTile(
                    title: "Laporkan Masalah",
                    subtitle: "Laporkan ketika menemukan masalah",
                    icon: Icons.error,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const LaporkanMasalahScreen(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _showLogoutConfirmation(context),
                      icon: const Icon(
                        Icons.logout,
                        color: Colors.white,
                        size: 24,
                      ),
                      label: const Text(
                        "Keluar",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
