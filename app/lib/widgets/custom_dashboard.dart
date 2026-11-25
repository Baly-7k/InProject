import 'dart:convert';

import 'package:material_ui/material_ui.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../main.dart'; // Importamos main para acceder a WelcomeScreen
import '../profile.dart';
import '../panel/dashboard_views.dart';

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
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {
      // Firebase ya cerró la sesión aunque Google no tenga una sesión activa.
    }
    if (mounted) {
      // Al cerrar sesión, vamos directo a WelcomeScreen
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
        (route) => false,
      );
    }
  }

  void _changeRole(String newRole) {
    setState(() {
      _currentRole = newRole;
      _selectedIndex = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const WelcomeScreen();
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('InProject')),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'No pudimos cargar tu perfil. Revisa tu conexión y los permisos de acceso.',
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: _logout,
                      child: const Text('Volver al inicio de sesión'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        Map<String, dynamic> currentData =
            snapshot.data!.data() as Map<String, dynamic>? ?? widget.userData;
        List<dynamic> currentRoles = currentData['roles'] ?? widget.userRoles;

        ImageProvider? profileImage;
        if (currentData['imagen'] != null &&
            currentData['imagen'].toString().isNotEmpty) {
          try {
            profileImage = MemoryImage(base64Decode(currentData['imagen']));
          } catch (_) {
            // Conservar el avatar predeterminado si la imagen está dañada.
          }
        }

        String userName = currentData['nombre'] ?? 'Usuario';

        return Scaffold(
          appBar: AppBar(
            backgroundColor: panelNavy,
            foregroundColor: Colors.white,
            title: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundImage: profileImage,
                  backgroundColor: Colors.white,
                  child: profileImage == null
                      ? const Icon(Icons.person, color: Colors.grey)
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        _currentRole.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onSelected: (value) {
                  if (value == 'logout') _logout();
                  if (value.startsWith('rol_')) {
                    _changeRole(value.replaceFirst('rol_', ''));
                  }
                },
                itemBuilder: (BuildContext context) {
                  List<PopupMenuEntry<String>> menuItems = [];

                  for (String role in currentRoles) {
                    if (role != _currentRole) {
                      String rolCapitalizado =
                          role[0].toUpperCase() + role.substring(1);
                      menuItems.add(
                        PopupMenuItem(
                          value: 'rol_$role',
                          child: Text('Cambiar a $rolCapitalizado'),
                        ),
                      );
                    }
                  }
                  if (menuItems.isNotEmpty) {
                    menuItems.add(const PopupMenuDivider());
                  }

                  menuItems.add(
                    const PopupMenuItem(
                      value: 'logout',
                      child: Text(
                        'Cerrar Sesión',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  );
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
                  accountName: Text(
                    userName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  accountEmail: Text(currentData['email'] ?? ''),
                  currentAccountPicture: CircleAvatar(
                    backgroundImage: profileImage,
                    backgroundColor: Colors.white,
                    child: profileImage == null
                        ? const Icon(Icons.person, size: 40, color: Colors.grey)
                        : null,
                  ),
                  decoration: const BoxDecoration(color: Color(0xFFF5A623)),
                ),
                ListTile(
                  leading: const Icon(Icons.dashboard),
                  title: const Text('Inicio'),
                  selected: _selectedIndex == 0,
                  onTap: () {
                    setState(() => _selectedIndex = 0);
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.work),
                  title: const Text('Mis Proyectos/Trabajos'),
                  selected: _selectedIndex == 1,
                  onTap: () {
                    setState(() => _selectedIndex = 1);
                    Navigator.pop(context);
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.person),
                  title: const Text('Mi Perfil'),
                  onTap: () {
                    Navigator.pop(context);
                    Future.delayed(const Duration(milliseconds: 100), () {
                      // CORRECCIÓN: Le pasamos el _currentRole al ProfileScreen
                      if (mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                ProfileScreen(currentRole: _currentRole),
                          ),
                        );
                      }
                    });
                  },
                ),
              ],
            ),
          ),
          body: _buildBody(currentData),
          bottomNavigationBar: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            currentIndex: _selectedIndex,
            onTap: (index) => setState(() => _selectedIndex = index),
            selectedItemColor: panelNavy,
            unselectedItemColor: Colors.grey,
            items: panelDestinations,
          ),
        );
      },
    );
  }

  Widget _buildBody(Map<String, dynamic> currentData) {
    return DashboardSection(
      index: _selectedIndex,
      userName: currentData['nombre']?.toString() ?? 'Usuario',
      onNavigate: (index) => setState(() => _selectedIndex = index),
    );
  }
}
