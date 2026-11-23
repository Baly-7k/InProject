import 'dart:convert';
import 'package:material_ui/material_ui.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../main.dart'; // Importamos main para acceder a WelcomeScreen
import '../profile.dart';

class CustomDashboard extends StatefulWidget {
  final String initialRole;
  final List<dynamic> userRoles;
  final Map<String, dynamic> userData;

  const CustomDashboard({
    super.key,
    required this.initialRole,
    required this.userRoles,
    required this.userData,
  });

  @override
  State<CustomDashboard> createState() => _CustomDashboardState();
}

class _CustomDashboardState extends State<CustomDashboard> {
  late String _currentRole;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentRole = widget.initialRole;
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    // ignore: empty_catches
    try { await GoogleSignIn.instance.signOut(); } catch (e) {}
    if (mounted) {
      // CORRECCIÓN: Al cerrar sesión, vamos directo a WelcomeScreen
      Navigator.pushAndRemoveUntil(
        context, 
        MaterialPageRoute(builder: (_) => const WelcomeScreen()), 
        (route) => false
      );
    }
  }

  void _changeRole(String newRole) {
    setState(() {
      _currentRole = newRole;
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser?.uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        Map<String, dynamic> currentData = snapshot.data!.data() as Map<String, dynamic>? ?? widget.userData;
        List<dynamic> currentRoles = currentData['roles'] ?? widget.userRoles;

        ImageProvider? profileImage;
        if (currentData['imagen'] != null && currentData['imagen'].toString().isNotEmpty) {
          // ignore: empty_catches
          try { profileImage = MemoryImage(base64Decode(currentData['imagen'])); } catch (e) {}
        }

        String userName = currentData['nombre'] ?? 'Usuario';

        return Scaffold(
          appBar: AppBar(
            backgroundColor: const Color(0xFFF5A623),
            title: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundImage: profileImage,
                  backgroundColor: Colors.white,
                  child: profileImage == null ? const Icon(Icons.person, color: Colors.grey) : null,
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(userName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    Text(_currentRole.toUpperCase(), style: const TextStyle(fontSize: 12, color: Colors.white70)),
                  ],
                ),
              ],
            ),
            actions: [
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onSelected: (value) {
                  if (value == 'logout') _logout();
                  if (value.startsWith('rol_')) _changeRole(value.replaceFirst('rol_', ''));
                },
                itemBuilder: (BuildContext context) {
                  List<PopupMenuEntry<String>> menuItems = [];
                  
                  for (String role in currentRoles) {
                    if (role != _currentRole) {
                      String rolCapitalizado = role[0].toUpperCase() + role.substring(1);
                      menuItems.add(PopupMenuItem(value: 'rol_$role', child: Text('Cambiar a $rolCapitalizado')));
                    }
                  }
                  if (menuItems.isNotEmpty) menuItems.add(const PopupMenuDivider());
                  
                  menuItems.add(const PopupMenuItem(value: 'logout', child: Text('Cerrar Sesión', style: TextStyle(color: Colors.red))));
                  return menuItems;
                },
              ),
            ],
          ),
          drawer: Drawer(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                UserAccountsDrawerHeader(
                  accountName: Text(userName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  accountEmail: Text(currentData['email'] ?? ''),
                  currentAccountPicture: CircleAvatar(
                    backgroundImage: profileImage,
                    backgroundColor: Colors.white,
                    child: profileImage == null ? const Icon(Icons.person, size: 40, color: Colors.grey) : null,
                  ),
                  decoration: const BoxDecoration(color: Color(0xFFF5A623)),
                ),
                ListTile(
                  leading: const Icon(Icons.dashboard),
                  title: const Text('Inicio'),
                  selected: _selectedIndex == 0,
                  onTap: () { setState(() => _selectedIndex = 0); Navigator.pop(context); },
                ),
                ListTile(
                  leading: const Icon(Icons.work),
                  title: const Text('Mis Proyectos/Trabajos'),
                  selected: _selectedIndex == 1,
                  onTap: () { setState(() => _selectedIndex = 1); Navigator.pop(context); },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.person),
                  title: const Text('Mi Perfil'),
                  onTap: () {
                    Navigator.pop(context);
                    Future.delayed(const Duration(milliseconds: 100), () {
                      if (mounted) Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
                    });
                  },
                ),
              ],
            ),
          ),
          body: _buildBody(currentData),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: (index) => setState(() => _selectedIndex = index),
            selectedItemColor: const Color(0xFFF5A623),
            unselectedItemColor: Colors.grey,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
              BottomNavigationBarItem(icon: Icon(Icons.work), label: 'Trabajos'),
              BottomNavigationBarItem(icon: Icon(Icons.wallet), label: 'Billetera'),
              BottomNavigationBarItem(icon: Icon(Icons.help), label: 'Ayuda'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBody(Map<String, dynamic> currentData) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: Text('Bienvenido ${currentData['nombre']} - Modo $_currentRole'),
      ),
    );
  }
}