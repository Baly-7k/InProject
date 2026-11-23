import 'package:material_ui/material_ui.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'register.dart';
import 'widgets/custom_dashboard.dart';
import 'main.dart'; 

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _phoneController = TextEditingController();
  bool _isLoading = false;

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      await GoogleSignIn.instance.initialize();
      final GoogleSignInAccount googleUser = await GoogleSignIn.instance.authenticate();
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      const List<String> scopes = <String>['email'];
      final GoogleSignInClientAuthorization authorization = await googleUser.authorizationClient.authorizeScopes(scopes);

      final credential = GoogleAuthProvider.credential(
        accessToken: authorization.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await _auth.signInWithCredential(credential);
      await _resolveAndNavigate(userCredential.user!);
    } catch (e) {
      _showError('Error al iniciar con Google: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendCode() async {
    if (_phoneController.text.isEmpty) {
      _showError('Ingresa un número de teléfono');
      return;
    }
    setState(() => _isLoading = true);
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: '+51${_phoneController.text.trim()}',
        verificationCompleted: (PhoneAuthCredential credential) async {
          UserCredential userCredential = await _auth.signInWithCredential(credential);
          await _resolveAndNavigate(userCredential.user!);
        },
        verificationFailed: (FirebaseAuthException e) {
          _showError('Error de verificación: ${e.message}');
          setState(() => _isLoading = false);
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() => _isLoading = false);
          _showCodeDialog(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
      );
    } catch (e) {
      _showError('Error al enviar SMS: $e');
      setState(() => _isLoading = false);
    }
  }

  void _showCodeDialog(String verificationId) {
    final TextEditingController codeController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Ingresa el código SMS'),
        content: TextField(controller: codeController, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: '123456')),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              setState(() => _isLoading = true);
              try {
                PhoneAuthCredential credential = PhoneAuthProvider.credential(verificationId: verificationId, smsCode: codeController.text.trim());
                UserCredential userCredential = await _auth.signInWithCredential(credential);
                await _resolveAndNavigate(userCredential.user!);
              } catch (e) {
                _showError('Código incorrecto');
              } finally {
                setState(() => _isLoading = false);
              }
            },
            child: const Text('Verificar'),
          ),
        ],
      ),
    );
  }

  Future<void> _resolveAndNavigate(User user) async {
    DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
    
    if (userDoc.exists) {
      _promptPasswordAndNavigate(userDoc);
    } else {
      QuerySnapshot query = await _firestore.collection('users')
          .where('email', isEqualTo: user.email)
          .limit(1)
          .get();
          
      if (query.docs.isEmpty) {
        query = await _firestore.collection('users')
            .where('telefono', isEqualTo: user.phoneNumber)
            .limit(1)
            .get();
      }

      if (query.docs.isNotEmpty) {
        _promptPasswordAndNavigate(query.docs.first);
      } else {
        if (!mounted) return;
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => RegisterScreen(existingUser: user)));
      }
    }
  }

  Future<void> _promptPasswordAndNavigate(DocumentSnapshot userDoc) async {
    Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
    
    if (data.containsKey('uids') && (data['uids'] as List).length > 1) {
      final TextEditingController passController = TextEditingController();
      bool obscure = true;

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Ingresa tu contraseña'),
              content: TextField(
                controller: passController,
                obscureText: obscure,
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  suffixIcon: IconButton(
                    icon: Icon(obscure ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => obscure = !obscure),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    try {
                      AuthCredential cred = EmailAuthProvider.credential(
                        email: data['email'], 
                        password: passController.text
                      );
                      await _auth.currentUser?.reauthenticateWithCredential(cred);
                      Navigator.pop(dialogContext);
                      _navigateToDashboard(userDoc);
                    } catch (e) {
                      _showError('Contraseña incorrecta');
                    }
                  },
                  child: const Text('Aceptar'),
                ),
              ],
            );
          },
        ),
      );
    } else {
      _navigateToDashboard(userDoc);
    }
  }

  void _navigateToDashboard(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    List<dynamic> roles = data['roles'] ?? [];
    if (roles.isNotEmpty && mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(
        builder: (_) => CustomDashboard(
          initialRole: roles.first.toString(),
          userRoles: roles,
          userData: data,
        )
      ));
    }
  }

  void _showForgotPasswordDialog() {
    final TextEditingController emailController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Recuperar Contraseña'),
        content: TextField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(labelText: 'Correo Electrónico', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
          TextButton(
            onPressed: () async {
              if (emailController.text.isNotEmpty) {
                try {
                  await _auth.sendPasswordResetEmail(email: emailController.text.trim());
                  Navigator.pop(dialogContext);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Correo enviado. Revisa tu bandeja.')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              }
            },
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Iniciar Sesión'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back), 
          onPressed: () => Navigator.pushAndRemoveUntil(
            context, 
            MaterialPageRoute(builder: (_) => const WelcomeScreen()), 
            (route) => false
          )
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _signInWithGoogle,
              icon: const Icon(Icons.g_mobiledata, size: 30),
              label: const Text('Continuar con Google'),
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 55)),
            ),
            const SizedBox(height: 24),
            const Text('O ingresa tu número de teléfono'),
            const SizedBox(height: 8),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(prefixText: '+51 ', border: OutlineInputBorder(), labelText: 'Número de teléfono'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _sendCode,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D1B2A), minimumSize: const Size(double.infinity, 55)),
              child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Enviar código', style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: _showForgotPasswordDialog,
              child: const Text('¿Olvidaste tu contraseña?', style: TextStyle(color: Colors.blue)),
            ),
          ],
        ),
      ),
    );
  }
}