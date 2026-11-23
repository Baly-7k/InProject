import 'dart:convert';
import 'dart:io';
import 'package:material_ui/material_ui.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'widgets/custom_dashboard.dart';

class RegisterScreen extends StatefulWidget {
  final User? existingUser;
  const RegisterScreen({super.key, this.existingUser});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final PageController _pageController = PageController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ImagePicker _picker = ImagePicker();

  int _currentPage = 0;
  bool _isSaving = false;
  bool _isAuthenticating = false;

  final _nombreController = TextEditingController();
  final _apellidoPaternoController = TextEditingController();
  final _apellidoMaternoController = TextEditingController();
  final _dniController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _phoneAuthController = TextEditingController();
  final _passController = TextEditingController();
  final _confirmPassController = TextEditingController();
  final _searchProfesionController = TextEditingController();

  String _emailGoogle = '';

  final List<String> _allowedCountryCodes = ['+51', '+1'];
  String _selectedCountryCode = '+51';

  DateTime? _fechaNacimiento;

  bool _isCliente = false;
  bool _isProveedor = false;

  bool _isGoogleLinked = false;
  bool _isPhoneLinked = false;

  final List<String> _categorias = ['Albañilería y obra gruesa', 'Acabados y revestimientos', 'Instalaciones eléctricas', 'Instalaciones sanitarias', 'Carpintería y metalmecánica'];
  String _selectedCategoria = 'Albañilería y obra gruesa';
  final Map<String, List<String>> _puestosPorCategoria = {
    'Albañilería y obra gruesa': ['Albañil', 'Fierrero', 'Encofrador', 'Concretista', 'Tarrajero'],
    'Acabados y revestimientos': ['Pintor', 'Drywallero', 'Empapelador', 'Yesero', 'Ceramista'],
    'Instalaciones eléctricas': ['Electricista', 'Técnico en redes', 'Instalador de alarmas', 'Electricista industrial', 'Técnico en iluminación'],
    'Instalaciones sanitarias': ['Gasfitero', 'Instalador de desagüe', 'Técnico en calefacción', 'Plomero', 'Instalador de grifería'],
    'Carpintería y metalmecánica': ['Carpintero', 'Soldador', 'Herrero', 'Vidriero', 'Estructurero'],
  };

  // CORREGIDO:
  // - _especialidadesSeleccionadas: puestos que DOMINA el CLIENTE (máx 5)
  // - _buscoSeleccionados: puestos que BUSCA CONTRATAR el PROVEEDOR (máx 20)
  List<String> _especialidadesSeleccionadas = [];
  List<String> _buscoSeleccionados = [];
  String _searchPuesto = '';

  File? _fotoPerfil;
  File? _dniAnverso;
  File? _dniReverso;
  File? _docAntecedentes;

  bool _obscurePass = true;
  double _passStrength = 0;
  String _passMessage = '';
  Color _passColor = Colors.grey;

  @override
  void initState() {
    super.initState();
    if (widget.existingUser != null || _auth.currentUser != null) {
      _currentPage = 1;
      _prefillData();
    }
    _loadProgress();
  }

  void _prefillData() {
    final user = widget.existingUser ?? _auth.currentUser;
    if (user != null) {
      if (user.email != null) {
        _emailGoogle = user.email!;
        _isGoogleLinked = true;
      }
      if (user.phoneNumber != null) {
        _telefonoController.text = user.phoneNumber!.replaceAll(_selectedCountryCode, '');
        _isPhoneLinked = true;
      }
    }
  }

  Future<void> _saveProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('reg_page', _currentPage);
    await prefs.setString('reg_nombre', _nombreController.text);
    await prefs.setString('reg_ap_pat', _apellidoPaternoController.text);
    await prefs.setString('reg_ap_mat', _apellidoMaternoController.text);
    await prefs.setString('reg_dni', _dniController.text);
    await prefs.setString('reg_tel', _telefonoController.text);
    await prefs.setString('reg_phone_auth', _phoneAuthController.text);
    await prefs.setString('reg_email', _emailGoogle);
    await prefs.setString('reg_pass', _passController.text);
    await prefs.setString('reg_confirm_pass', _confirmPassController.text);
    await prefs.setBool('reg_is_cliente', _isCliente);
    await prefs.setBool('reg_is_proveedor', _isProveedor);
    await prefs.setBool('reg_is_google_linked', _isGoogleLinked);
    await prefs.setBool('reg_is_phone_linked', _isPhoneLinked);
    await prefs.setString('reg_categoria', _selectedCategoria);
    await prefs.setString('reg_country_code', _selectedCountryCode);
    if (_fechaNacimiento != null) {
      await prefs.setString('reg_fecha', _fechaNacimiento!.toIso8601String());
    }
    await prefs.setStringList('reg_especialidades', _especialidadesSeleccionadas);
    await prefs.setStringList('reg_busco', _buscoSeleccionados);

    // Rutas de las fotos ya tomadas
    await prefs.setString('reg_foto_perfil', _fotoPerfil?.path ?? '');
    await prefs.setString('reg_dni_anverso', _dniAnverso?.path ?? '');
    await prefs.setString('reg_dni_reverso', _dniReverso?.path ?? '');
    await prefs.setString('reg_antecedentes', _docAntecedentes?.path ?? '');
  }

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      int savedPage = prefs.getInt('reg_page') ?? 0;
      if ((widget.existingUser != null || _auth.currentUser != null) && savedPage == 0) {
        _currentPage = 1;
      } else {
        _currentPage = savedPage;
      }
      _nombreController.text = prefs.getString('reg_nombre') ?? '';
      _apellidoPaternoController.text = prefs.getString('reg_ap_pat') ?? '';
      _apellidoMaternoController.text = prefs.getString('reg_ap_mat') ?? '';
      _dniController.text = prefs.getString('reg_dni') ?? '';
      if (_telefonoController.text.isEmpty) _telefonoController.text = prefs.getString('reg_tel') ?? '';
      _phoneAuthController.text = prefs.getString('reg_phone_auth') ?? '';
      _emailGoogle = prefs.getString('reg_email') ?? '';
      _passController.text = prefs.getString('reg_pass') ?? '';
      _confirmPassController.text = prefs.getString('reg_confirm_pass') ?? '';
      _isCliente = prefs.getBool('reg_is_cliente') ?? false;
      _isProveedor = prefs.getBool('reg_is_proveedor') ?? false;
      _isGoogleLinked = prefs.getBool('reg_is_google_linked') ?? false;
      _isPhoneLinked = prefs.getBool('reg_is_phone_linked') ?? false;
      _selectedCategoria = prefs.getString('reg_categoria') ?? _selectedCategoria;
      _selectedCountryCode = prefs.getString('reg_country_code') ?? _selectedCountryCode;

      String? fechaStr = prefs.getString('reg_fecha');
      if (fechaStr != null) _fechaNacimiento = DateTime.tryParse(fechaStr);

      List<String>? esp = prefs.getStringList('reg_especialidades');
      if (esp != null) _especialidadesSeleccionadas = esp;

      List<String>? busco = prefs.getStringList('reg_busco');
      if (busco != null) _buscoSeleccionados = busco;

      // Restaurar fotos desde prefs
      final pPerfil = prefs.getString('reg_foto_perfil');
      if (pPerfil != null && pPerfil.isNotEmpty && File(pPerfil).existsSync()) {
        _fotoPerfil = File(pPerfil);
      }
      final pAnv = prefs.getString('reg_dni_anverso');
      if (pAnv != null && pAnv.isNotEmpty && File(pAnv).existsSync()) {
        _dniAnverso = File(pAnv);
      }
      final pRev = prefs.getString('reg_dni_reverso');
      if (pRev != null && pRev.isNotEmpty && File(pRev).existsSync()) {
        _dniReverso = File(pRev);
      }
      final pAnt = prefs.getString('reg_antecedentes');
      if (pAnt != null && pAnt.isNotEmpty && File(pAnt).existsSync()) {
        _docAntecedentes = File(pAnt);
      }
    });

    // Reconstruir barra de fuerza
    if (_passController.text.isNotEmpty) {
      _checkPasswordStrength(_passController.text);
    }

    if (_pageController.hasClients) {
      _pageController.jumpToPage(_currentPage);
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_pageController.hasClients) _pageController.jumpToPage(_currentPage);
      });
    }

    // Fallback: solo si NO había rutas guardadas
    final needsLostData = _fotoPerfil == null &&
        _dniAnverso == null &&
        _dniReverso == null &&
        _docAntecedentes == null;
    if (needsLostData) {
      final LostDataResponse response = await _picker.retrieveLostData();
      if (!response.isEmpty && response.file != null) {
        final String? lostType = prefs.getString('lost_photo_type');
        setState(() {
          if (lostType == 'perfil') _fotoPerfil = File(response.file!.path);
          if (lostType == 'dni_anverso') _dniAnverso = File(response.file!.path);
          if (lostType == 'dni_reverso') _dniReverso = File(response.file!.path);
          if (lostType == 'antecedentes') _docAntecedentes = File(response.file!.path);
        });
        await prefs.remove('lost_photo_type');
        await _saveProgress();
      }
    }
  }

  Future<void> _takePhoto(String type, ImageSource source) async {
    FocusScope.of(context).unfocus();
    await _saveProgress();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lost_photo_type', type);

    final XFile? photo = await _picker.pickImage(source: source, imageQuality: 30, maxWidth: 800);

    if (photo != null) {
      setState(() {
        if (type == 'perfil') _fotoPerfil = File(photo.path);
        if (type == 'dni_anverso') _dniAnverso = File(photo.path);
        if (type == 'dni_reverso') _dniReverso = File(photo.path);
        if (type == 'antecedentes') _docAntecedentes = File(photo.path);
      });
      await prefs.remove('lost_photo_type');
      await _saveProgress();
    }
  }

  Future<void> _vincularCuentaGoogle() async {
    setState(() => _isAuthenticating = true);
    try {
      await GoogleSignIn.instance.initialize();
      final GoogleSignInAccount googleUser = await GoogleSignIn.instance.authenticate();
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      const List<String> scopes = <String>['email'];
      final GoogleSignInClientAuthorization authorization = await googleUser.authorizationClient.authorizeScopes(scopes);

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: authorization.accessToken,
        idToken: googleAuth.idToken,
      );

      User? user = _auth.currentUser;
      if (user != null) {
        await user.linkWithCredential(credential);
        await Future.delayed(const Duration(seconds: 1));
        setState(() {
          _isGoogleLinked = true;
          _emailGoogle = googleUser.email;
        });
        _showError('¡Cuenta de Google vinculada con éxito!');
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'provider-already-linked') {
        setState(() => _isGoogleLinked = true);
        _showError('La cuenta de Google ya está vinculada.');
      } else {
        _showError('Error al vincular con Google: ${e.message}');
      }
    } catch (e) {
      _showError('Error al vincular con Google: $e');
    } finally {
      setState(() => _isAuthenticating = false);
    }
  }

  Future<void> _vincularTelefono() async {
    if (_phoneAuthController.text.isEmpty) {
      _showError('Ingresa un número de teléfono');
      return;
    }

    String cleanPhone = _phoneAuthController.text.replaceAll(RegExp(r'[^\d]'), '');
    String phoneNumber = '$_selectedCountryCode$cleanPhone';

    setState(() => _isAuthenticating = true);
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _auth.currentUser?.linkWithCredential(credential);
          setState(() {
            _isPhoneLinked = true;
            _telefonoController.text = _phoneAuthController.text.trim();
          });
          _showError('¡Teléfono vinculado con éxito!');
          setState(() => _isAuthenticating = false);
        },
        verificationFailed: (FirebaseAuthException e) {
          _showError('Error: ${e.message}');
          setState(() => _isAuthenticating = false);
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() => _isAuthenticating = false);
          _showCodeDialog(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
      );
    } catch (e) {
      _showError('Error al enviar SMS: $e');
      setState(() => _isAuthenticating = false);
    }
  }

  void _showCodeDialog(String verificationId) {
    final TextEditingController codeController = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Ingresa el código SMS'),
        content: TextField(controller: codeController, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: '123456')),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _isAuthenticating = true);
              try {
                PhoneAuthCredential credential = PhoneAuthProvider.credential(verificationId: verificationId, smsCode: codeController.text.trim());
                await _auth.currentUser?.linkWithCredential(credential);
                setState(() {
                  _isPhoneLinked = true;
                  _telefonoController.text = _phoneAuthController.text.trim();
                });
                _showError('¡Teléfono vinculado con éxito!');
              } catch (e) {
                _showError('Código incorrecto o error al vincular');
              } finally {
                setState(() => _isAuthenticating = false);
              }
            },
            child: const Text('Verificar'),
          ),
        ],
      ),
    );
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isAuthenticating = true);
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

      DocumentSnapshot doc = await _firestore.collection('users').doc(userCredential.user!.uid).get();
      if (doc.exists && (doc.data() as Map<String, dynamic>)['roles'] != null) {
        List<dynamic> roles = (doc.data() as Map<String, dynamic>)['roles'];
        _redirectToDashboard(userCredential.user!, roles);
      } else {
        setState(() {
          if (userCredential.user!.email != null) {
            _emailGoogle = userCredential.user!.email!;
            _isGoogleLinked = true;
          }
          if (userCredential.user!.displayName != null) {
            List<String> names = userCredential.user!.displayName!.split(' ');
            _nombreController.text = names.first;
            if (names.length > 1) _apellidoPaternoController.text = names.sublist(1).join(' ');
          }
          _currentPage = 1;
        });
        _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.ease);
      }
    } catch (e) {
      _showError('Error al iniciar con Google: $e');
    } finally {
      setState(() => _isAuthenticating = false);
    }
  }

  Future<void> _sendCode() async {
    if (_phoneAuthController.text.isEmpty) return;

    String cleanPhone = _phoneAuthController.text.replaceAll(RegExp(r'[^\d]'), '');
    String phoneNumber = '$_selectedCountryCode$cleanPhone';

    setState(() => _isAuthenticating = true);
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          UserCredential userCredential = await _auth.signInWithCredential(credential);
          await _handlePhoneSignIn(userCredential.user!);
        },
        verificationFailed: (FirebaseAuthException e) {
          _showError('Error: ${e.message}');
          setState(() => _isAuthenticating = false);
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() => _isAuthenticating = false);
          _showCodeDialogForLogin(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
      );
    } catch (e) {
      _showError('Error al enviar SMS: $e');
      setState(() => _isAuthenticating = false);
    }
  }

  void _showCodeDialogForLogin(String verificationId) {
    final TextEditingController codeController = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Ingresa el código SMS'),
        content: TextField(controller: codeController, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: '123456')),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _isAuthenticating = true);
              try {
                PhoneAuthCredential credential = PhoneAuthProvider.credential(verificationId: verificationId, smsCode: codeController.text.trim());
                UserCredential userCredential = await _auth.signInWithCredential(credential);
                await _handlePhoneSignIn(userCredential.user!);
              } catch (e) {
                _showError('Código incorrecto');
              } finally {
                setState(() => _isAuthenticating = false);
              }
            },
            child: const Text('Verificar'),
          ),
        ],
      ),
    );
  }

  Future<void> _handlePhoneSignIn(User user) async {
    DocumentSnapshot doc = await _firestore.collection('users').doc(user.uid).get();
    if (doc.exists && (doc.data() as Map<String, dynamic>)['roles'] != null) {
      List<dynamic> roles = (doc.data() as Map<String, dynamic>)['roles'];
      _redirectToDashboard(user, roles);
    } else {
      setState(() {
        _telefonoController.text = user.phoneNumber!.replaceAll(_selectedCountryCode, '');
        _currentPage = 1;
      });
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.ease);
    }
  }

  void _checkPasswordStrength(String value) {
    double strength = 0;
    if (value.length >= 6) strength += 0.2;
    if (value.contains(RegExp(r'[A-Z]'))) strength += 0.2;
    if (value.contains(RegExp(r'[a-z]'))) strength += 0.2;
    if (value.contains(RegExp(r'[0-9]'))) strength += 0.2;
    if (value.contains(RegExp(r'[!@#\$&*~]'))) strength += 0.2;

    setState(() {
      _passStrength = strength;
      if (value.isEmpty) {
        _passMessage = ''; _passColor = Colors.grey;
      } else if (strength <= 0.4) {
        _passMessage = 'Débil'; _passColor = Colors.red;
      } else if (strength <= 0.8) {
        _passMessage = 'Media'; _passColor = Colors.orange;
      } else {
        _passMessage = 'Fuerte'; _passColor = Colors.green;
      }
    });
  }

  Future<String> _fileToBase64(File? file) async {
    if (file == null) return '';
    final bytes = await file.readAsBytes();
    return base64Encode(bytes);
  }

  void _validateAndJump(int page, String errorMessage) {
    _showError(errorMessage);
    _pageController.jumpToPage(page);
    setState(() => _currentPage = page);
    _saveProgress();
  }

  Future<void> _saveData() async {
    if (!_isCliente && !_isProveedor) { _validateAndJump(3, 'Selecciona al menos un rol'); return; }
    if (_nombreController.text.isEmpty || _dniController.text.isEmpty || _fechaNacimiento == null) { _validateAndJump(1, 'Completa los datos personales'); return; }
    if (_passController.text.length < 6) { _validateAndJump(2, 'La contraseña debe tener al menos 6 caracteres'); return; }
    if (_passController.text != _confirmPassController.text) { _validateAndJump(2, 'Las contraseñas no coinciden'); return; }

    // Validación dinámica de fotos
    int dniPageIndex = 4;
    if (_isCliente || _isProveedor) {
      dniPageIndex = 5;
    }

    if (_fotoPerfil == null || _dniAnverso == null || _dniReverso == null) {
      _validateAndJump(dniPageIndex, 'Debes subir las fotos requeridas (DNI y Perfil)');
      return;
    }

    setState(() => _isSaving = true);
    try {
      User? user = _auth.currentUser;
      if (user == null) throw Exception("No hay usuario autenticado.");

      await _firestore.collection('users').doc(user.uid).set({
        'email': _emailGoogle,
        'telefono': '$_selectedCountryCode${_telefonoController.text.trim()}',
        'nombre': _nombreController.text.trim(),
        'apellidoPaterno': _apellidoPaternoController.text.trim(),
        'apellidoMaterno': _apellidoMaternoController.text.trim(),
        'fechaNacimiento': Timestamp.fromDate(_fechaNacimiento!),
        'dni': _dniController.text.trim(),
        'roles': FieldValue.arrayUnion([if (_isCliente) 'cliente', if (_isProveedor) 'proveedor']),
        // CORREGIDO: 'especialidades' = puestos que DOMINA el CLIENTE
        // CORREGIDO: 'busco' = puestos que BUSCA CONTRATAR el PROVEEDOR
        'especialidades': _especialidadesSeleccionadas,
        'busco': _buscoSeleccionados,
        'imagen': await _fileToBase64(_fotoPerfil),
        'documentos': {
          'dni_anverso': await _fileToBase64(_dniAnverso),
          'dni_reverso': await _fileToBase64(_dniReverso),
          'antecedentes': await _fileToBase64(_docAntecedentes),
        },
        'uids': FieldValue.arrayUnion([user.uid]),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      if (mounted) {
        _showError('Registro completado con éxito');
        DocumentSnapshot updatedDoc = await _firestore.collection('users').doc(user.uid).get();
        List<dynamic> updatedRoles = (updatedDoc.data() as Map<String, dynamic>)['roles'] ?? [];
        if (updatedRoles.length > 1) {
          _showRoleSelectionDialog(updatedRoles, user);
        } else {
          _redirectToDashboard(user, updatedRoles);
        }
      }
    } catch (e) {
      _showError('Error: $e');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _showRoleSelectionDialog(List<dynamic> roles, User user) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Selecciona tu modo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: roles.map((role) {
            return ListTile(
              title: Text(role.toString().toUpperCase()),
              leading: Icon(role == 'cliente' ? Icons.work : Icons.person),
              onTap: () {
                Navigator.pop(context);
                _redirectToDashboard(user, [role]);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  Future<void> _redirectToDashboard(User user, List<dynamic> roles) async {
    DocumentSnapshot doc = await _firestore.collection('users').doc(user.uid).get();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => CustomDashboard(
        initialRole: roles.first.toString(),
        userRoles: roles,
        userData: doc.data() as Map<String, dynamic>,
      )),
      (route) => false,
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nombreController.dispose();
    _apellidoPaternoController.dispose();
    _apellidoMaternoController.dispose();
    _dniController.dispose();
    _telefonoController.dispose();
    _phoneAuthController.dispose();
    _passController.dispose();
    _confirmPassController.dispose();
    _searchProfesionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Lista base de páginas
    List<Widget> pages = [
      _buildAuthPage(),
      _buildPersonalDataPage(),
      _buildPasswordPage(),
      _buildRolesPage(),
    ];

    // Añadir página de Preferencias (Especialidades o Busco) si es necesario
    if (_isCliente || _isProveedor) {
      pages.add(_buildPreferenciasPage());
    }

    pages.addAll([
      _buildDNIPage(),
      _buildSelfiePage(),
    ]);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Completar Registro'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_currentPage == 0) {
              Navigator.pop(context);
            } else {
              _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.ease);
            }
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (index) { setState(() => _currentPage = index); _saveProgress(); },
              children: pages,
            ),
          ),
          if (_currentPage > 0) _buildBottomNavigation(pages.length),
        ],
      ),
    );
  }

  Widget _buildAuthPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          const Icon(Icons.security, size: 80, color: Color(0xFFF5A623)),
          const SizedBox(height: 20),
          const Text('Paso 1: Crea tu cuenta', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: _isAuthenticating ? null : _signInWithGoogle,
            icon: const Icon(Icons.g_mobiledata, size: 30),
            label: const Text('Continuar con Google'),
            style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 55)),
          ),
          const SizedBox(height: 24),
          const Text('O ingresa tu número de teléfono'),
          const SizedBox(height: 8),
          Row(
            children: [
              SizedBox(
                width: 90,
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedCountryCode,
                  isExpanded: true,
                  items: _allowedCountryCodes
                      .map((code) => DropdownMenuItem(value: code, child: Text(code)))
                      .toList(),
                  onChanged: (val) { setState(() => _selectedCountryCode = val!); _saveProgress(); },
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _phoneAuthController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Número de teléfono',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _isAuthenticating ? null : _sendCode,
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D1B2A), minimumSize: const Size(double.infinity, 55)),
            child: _isAuthenticating ? const CircularProgressIndicator(color: Colors.white) : const Text('Enviar código SMS', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalDataPage() {
    Widget botonVinculacion;
    if (!_isGoogleLinked) {
      botonVinculacion = ElevatedButton.icon(
        onPressed: _isAuthenticating ? null : _vincularCuentaGoogle,
        icon: const Icon(Icons.g_mobiledata, size: 30),
        label: const Text('Vincular con Google'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          minimumSize: const Size(double.infinity, 55),
          side: const BorderSide(color: Colors.grey),
        ),
      );
    } else if (!_isPhoneLinked) {
      botonVinculacion = Column(
        children: [
          const Text('Tu cuenta de Google está vinculada. Ahora vincula tu teléfono:', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Row(
            children: [
              SizedBox(
                width: 90,
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedCountryCode,
                  isExpanded: true,
                  items: _allowedCountryCodes
                      .map((code) => DropdownMenuItem(value: code, child: Text(code)))
                      .toList(),
                  onChanged: (val) { setState(() => _selectedCountryCode = val!); _saveProgress(); },
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _phoneAuthController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Número de teléfono',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: _isAuthenticating ? null : _vincularTelefono,
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D1B2A), minimumSize: const Size(double.infinity, 55)),
            child: _isAuthenticating ? const CircularProgressIndicator(color: Colors.white) : const Text('Vincular Número de Teléfono', style: TextStyle(color: Colors.white)),
          ),
        ],
      );
    } else {
      botonVinculacion = Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.green[100], borderRadius: BorderRadius.circular(8)),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 10),
            Expanded(
              child: Text('Cuenta de Google y Teléfono vinculados', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          const Text('Información Personal', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          TextField(controller: _nombreController, decoration: const InputDecoration(labelText: 'Nombre', border: OutlineInputBorder())),
          const SizedBox(height: 10),
          TextField(controller: _apellidoPaternoController, decoration: const InputDecoration(labelText: 'Apellido Paterno', border: OutlineInputBorder())),
          const SizedBox(height: 10),
          TextField(controller: _apellidoMaternoController, decoration: const InputDecoration(labelText: 'Apellido Materno', border: OutlineInputBorder())),
          const SizedBox(height: 10),
          ListTile(
            title: Text(_fechaNacimiento == null ? 'Fecha de Nacimiento' : '${_fechaNacimiento!.day}/${_fechaNacimiento!.month}/${_fechaNacimiento!.year}'),
            trailing: const Icon(Icons.calendar_today),
            onTap: () async {
              FocusScope.of(context).unfocus();
              DateTime? picked = await showDatePicker(context: context, initialDate: DateTime(2000), firstDate: DateTime(1900), lastDate: DateTime.now());
              if (picked != null) setState(() => _fechaNacimiento = picked);
            },
          ),
          const SizedBox(height: 10),

          if (!_isGoogleLinked) ...[
            Row(
              children: [
                SizedBox(
                  width: 90,
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedCountryCode,
                    isExpanded: true,
                    items: _allowedCountryCodes
                        .map((code) => DropdownMenuItem(value: code, child: Text(code)))
                        .toList(),
                    onChanged: (val) { setState(() => _selectedCountryCode = val!); _saveProgress(); },
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _telefonoController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Teléfono',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
          ] else if (!_isPhoneLinked) ...[
          ] else ...[
            TextField(controller: _telefonoController, readOnly: true, decoration: const InputDecoration(labelText: 'Teléfono (Vinculado)', border: OutlineInputBorder(), filled: true, fillColor: Colors.black12)),
          ],

          const SizedBox(height: 10),
          TextField(controller: _dniController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'DNI', border: OutlineInputBorder())),

          const SizedBox(height: 30),
          botonVinculacion,
        ],
      ),
    );
  }

  Widget _buildPasswordPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          const Text('Crea tu Contraseña', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          TextField(
            controller: _passController,
            obscureText: _obscurePass,
            onChanged: _checkPasswordStrength,
            decoration: InputDecoration(
              labelText: 'Contraseña',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(_obscurePass ? Icons.visibility : Icons.visibility_off),
                onPressed: () => setState(() => _obscurePass = !_obscurePass),
              ),
            ),
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(value: _passStrength, color: _passColor, backgroundColor: Colors.grey[300]),
          const SizedBox(height: 5),
          Text(_passMessage, style: TextStyle(color: _passColor, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          TextField(
            controller: _confirmPassController,
            obscureText: _obscurePass,
            decoration: const InputDecoration(labelText: 'Confirmar Contraseña', border: OutlineInputBorder()),
          ),
        ],
      ),
    );
  }

  Widget _buildRolesPage() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          const Text('¿Cómo usarás la app?', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          CheckboxListTile(title: const Text('Soy Cliente (Busco trabajo)'), value: _isCliente, onChanged: (val) { setState(() => _isCliente = val!); _saveProgress(); }),
          CheckboxListTile(title: const Text('Soy Proveedor (Busco contratar trabajadores)'), value: _isProveedor, onChanged: (val) { setState(() => _isProveedor = val!); _saveProgress(); }),
        ],
      ),
    );
  }

  // PÁGINA DE PREFERENCIAS DINÁMICA (CORREGIDA)
  Widget _buildPreferenciasPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Si es Proveedor, muestra "Busco" (puestos que necesita contratar) -> MÁX 20
          if (_isProveedor) ...[
            const Text('¿Qué trabajadores estás buscando?', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const Text('Selecciona hasta 20 puestos que necesites contratar.'),
            const SizedBox(height: 10),
            _buildSelectorPuestos(_buscoSeleccionados, true, maxSeleccion: 20),
            const SizedBox(height: 30),
          ],
          // Si es Cliente, muestra "Especialidades" (lo que domina) -> MÁX 5
          if (_isCliente) ...[
            const Text('Puedo trabajar como:', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const Text('Selecciona hasta 5 puestos que domines.'),
            const SizedBox(height: 10),
            _buildSelectorPuestos(_especialidadesSeleccionadas, false, maxSeleccion: 5),
          ],
        ],
      ),
    );
  }

  // Helper para construir el selector de puestos
  // maxSeleccion: 5 para Cliente (especialidades), 20 para Proveedor (busco)
  Widget _buildSelectorPuestos(List<String> listaSeleccionada, bool esBusco, {int maxSeleccion = 5}) {
    List<String> puestosFiltrados = _puestosPorCategoria[_selectedCategoria]!
        .where((p) => p.toLowerCase().contains(_searchPuesto.toLowerCase()))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          initialValue: _selectedCategoria,
          isExpanded: true,
          items: _categorias.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
          onChanged: (val) { setState(() => _selectedCategoria = val!); _saveProgress(); },
          decoration: const InputDecoration(labelText: 'Categoría', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _searchProfesionController,
          decoration: const InputDecoration(labelText: 'Buscar puesto...', prefixIcon: Icon(Icons.search), border: OutlineInputBorder()),
          onChanged: (val) => setState(() => _searchPuesto = val),
        ),
        const SizedBox(height: 10),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: puestosFiltrados.length,
          itemBuilder: (context, index) {
            String puesto = puestosFiltrados[index];
            bool isSelected = listaSeleccionada.contains(puesto);
            return CheckboxListTile(
              title: Text(puesto),
              value: isSelected,
              onChanged: (bool? selected) {
                setState(() {
                  if (selected == true) {
                    if (listaSeleccionada.length < maxSeleccion) {
                      listaSeleccionada.add(puesto);
                    } else {
                      _showError('Máximo $maxSeleccion puestos');
                    }
                  } else {
                    listaSeleccionada.remove(puesto);
                  }
                  _saveProgress();
                });
              },
            );
          },
        ),
        Text('Seleccionados: ${listaSeleccionada.length}/$maxSeleccion', style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildDNIPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          const Text('Documentos', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _buildPhotoBox('DNI Anverso', _dniAnverso, 'dni_anverso')),
              const SizedBox(width: 10),
              Expanded(child: _buildPhotoBox('DNI Reverso', _dniReverso, 'dni_reverso')),
            ],
          ),
          const SizedBox(height: 20),
          _buildPhotoBox('Antecedentes (Opcional)', _docAntecedentes, 'antecedentes'),
        ],
      ),
    );
  }

  Widget _buildSelfiePage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          const Text('Foto de Perfil', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          CircleAvatar(radius: 80, backgroundColor: Colors.grey[300], backgroundImage: _fotoPerfil != null ? FileImage(_fotoPerfil!) : null, child: _fotoPerfil == null ? const Icon(Icons.camera_alt, size: 50) : null),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(onPressed: () => _takePhoto('perfil', ImageSource.camera), icon: const Icon(Icons.camera), label: const Text('Cámara')),
              const SizedBox(width: 10),
              ElevatedButton.icon(onPressed: () => _takePhoto('perfil', ImageSource.gallery), icon: const Icon(Icons.photo), label: const Text('Galería')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoBox(String label, File? image, String type) {
    return GestureDetector(
      onTap: () => _showPhotoOptions(type),
      child: Container(
        height: 120,
        decoration: BoxDecoration(color: Colors.grey[200], border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(10)),
        child: image != null ? ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.file(image, fit: BoxFit.cover, width: double.infinity)) : Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.add_a_photo, size: 40), Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12))]),
      ),
    );
  }

  void _showPhotoOptions(String type) {
    FocusScope.of(context).unfocus();
    showModalBottomSheet(
      context: context,
      builder: (context) => Wrap(
        children: [
          ListTile(leading: const Icon(Icons.camera), title: const Text('Tomar Foto'), onTap: () { Navigator.pop(context); _takePhoto(type, ImageSource.camera); }),
          ListTile(leading: const Icon(Icons.photo), title: const Text('Elegir de Galería'), onTap: () { Navigator.pop(context); _takePhoto(type, ImageSource.gallery); }),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation(int totalPages) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_currentPage > 1) TextButton(onPressed: () => _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.ease), child: const Text('Atrás')) else const SizedBox(width: 60),
          Text('$_currentPage de ${totalPages - 1}'), // Ajuste visual
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D1B2A)),
            onPressed: _isSaving ? null : () {
              if (_currentPage < totalPages - 1) {
                _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.ease);
              } else {
                _saveData();
              }
            },
            child: _isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white)) : Text(_currentPage == totalPages - 1 ? 'Finalizar' : 'Siguiente', style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}