import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final user = FirebaseAuth.instance.currentUser;

  Future<DocumentSnapshot<Map<String, dynamic>>> getUserData() {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .get();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: FutureBuilder(
          future: getUserData(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || !snapshot.data!.exists) {
              return const Center(child: Text("Data user tidak ditemukan"));
            }

            final data = snapshot.data!.data()!;

            return Column(
              children: [
                const SizedBox(height: 24),

                /// ===== PROFILE HEADER =====
                CircleAvatar(
                  radius: 50,
                  backgroundImage: data['photoUrl'] != null &&
                          data['photoUrl'] != ''
                      ? NetworkImage(data['photoUrl'])
                      : const AssetImage('assets/img/pp.jpg')
                          as ImageProvider,
                ),

                const SizedBox(height: 12),

                Text(
                  data['name'] ?? '-',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  data['email'] ?? '-',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),

                const SizedBox(height: 24),

                /// ===== MENU LIST =====
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      _profileItem(
                        icon: Icons.person,
                        title: "Data Diri",
                        subtitle: "Ubah data diri disini",
                        onTap: () {},
                      ),
                      _profileItem(
                        icon: Icons.lock,
                        title: "Keamanan dan Privasi",
                        subtitle: "Atur keamanan dan privasi",
                        onTap: () {},
                      ),
                      _profileItem(
                        icon: Icons.info,
                        title: "Tentang VokaPedia",
                        subtitle: "Ketahui lebih dalam tentang VokaPedia",
                        onTap: () {},
                      ),
                      _profileItem(
                        icon: Icons.help_outline,
                        title: "FAQ & Panduan",
                        subtitle: "Lihat panduan penggunaan optimal",
                        onTap: () {},
                      ),
                      _profileItem(
                        icon: Icons.report_problem_outlined,
                        title: "Laporkan Masalah",
                        subtitle: "Laporkan ketika menemukan masalah",
                        onTap: () {},
                      ),
                    ],
                  ),
                ),

                /// ===== LOGOUT =====
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await FirebaseAuth.instance.signOut();
                        Navigator.pushNamedAndRemoveUntil(
                            context, '/login', (route) => false);
                      },
                      icon: const Icon(Icons.logout),
                      label: const Text("Keluar"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// ===== REUSABLE MENU ITEM =====
  Widget _profileItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.white,
          child: Icon(icon, color: Colors.black),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
