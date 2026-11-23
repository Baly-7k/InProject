import 'dart:convert';
import 'dart:io';
import 'package:material_ui/material_ui.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();
  
  final _nombreController = TextEditingController();
  final _apellidoPaternoController = TextEditingController();
  final _apellidoMaternoController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _passwordController = TextEditingController();
  
  String _email = '';
  DateTime? _fechaNacimiento;
  List<String> _especialidades = [];
  
  File? _newImage;
  String? _currentBase64Image;
  
  File? _newDniAnv;
  String? _currentDniAnv;
  
  File? _newDniRev;
  String? _currentDniRev;
  
  File? _newAntecedentes;
  String? _currentAntecedentes;

  bool _isLoading = true;
  bool _isSaving = false;
  
  bool _tieneTelefono = false;
  bool _tieneGoogle = false;

  // CÓDIGOS PERMITIDOS
  final List<String> _allowedCountryCodes = ['+51', '+1'];
  String _selectedCountryCode = '+51';

  final List<String> _categorias = ['Albañilería y obra gruesa', 'Acabados y revestimientos', 'Instalaciones eléctricas', 'Instalaciones sanitarias', 'Carpintería y metalmecánica'];
  final Map<String, List<String>> _puestosPorCategoria = {
    'Albañilería y obra gruesa': ['Albañil', 'Fierrero', 'Encofrador', 'Concretista', 'Tarrajero'],
    'Acabados y revestimientos': ['Pintor', 'Drywallero', 'Empapelador', 'Yesero', 'Ceramista'],
    'Instalaciones eléctricas': ['Electricista', 'Técnico en redes', 'Instalador de alarmas', 'Electricista industrial', 'Técnico en iluminación'],
    'Instalaciones sanitarias': ['Gasfitero', 'Instalador de desagüe', 'Técnico en calefacción', 'Plomero', 'Instalador de grifería'],
    'Carpintería y metalmecánica': ['Carpintero', 'Soldador', 'Herrero', 'Vidriero', 'Estructurero'],
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        setState(() {
          _nombreController.text = data['nombre'] ?? '';
          _apellidoPaternoController.text = data['apellidoPaterno'] ?? '';
          _apellidoMaternoController.text = data['apellidoMaterno'] ?? '';
          
          String telCompleto = data['telefono'] ?? '';
          // Lógica para separar el código de país del número
          if (telCompleto.startsWith('+51')) {
            _selectedCountryCode = '+51';
            _telefonoController.text = telCompleto.replaceFirst('+51', '');
          } else if (telCompleto.startsWith('+1')) {
            _selectedCountryCode = '+1';
            _telefonoController.text = telCompleto.replaceFirst('+1', '');
          } else {
            _telefonoController.text = telCompleto;
          }

          _email = data['email'] ?? '';
          _especialidades = List<String>.from(data['especialidades'] ?? []);
          
          if (data['fechaNacimiento'] != null) {
            _fechaNacimiento = (data['fechaNacimiento'] as Timestamp).toDate();
          }
          
          _currentBase64Image = data['imagen'];
          _currentDniAnv = data['documentos']?['dni_anverso'];
          _currentDniRev = data['documentos']?['dni_reverso'];
          _currentAntecedentes = data['documentos']?['antecedentes'];
          
          _isLoading = false;
        });
      }
      
      setState(() {
        _tieneTelefono = user.providerData.any((p) => p.providerId == 'phone');
        _tieneGoogle = user.providerData.any((p) => p.providerId == 'google.com');
      });
    }
  }

  Future<void> _changePassword() async {
    if (_passwordController.text.isEmpty || _passwordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('La contraseña debe tener al menos 6 caracteres')));
      return;
    }
    setState(() => _isSaving = true);
    try {
      await _auth.currentUser!.updatePassword(_passwordController.text.trim());
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Contraseña actualizada')));
      _passwordController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al cambiar contraseña: $e')));
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _pickImage(String type, ImageSource source) async {
    FocusScope.of(context).unfocus();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lost_photo_type', type);
    final XFile? photo = await _picker.pickImage(source: source, imageQuality: 30, maxWidth: 800);
    
    if (photo != null) {
      setState(() {
        if (type == 'perfil') _newImage = File(photo.path);
        if (type == 'dni_anverso') _newDniAnv = File(photo.path);
        if (type == 'dni_reverso') _newDniRev = File(photo.path);
        if (type == 'antecedentes') _newAntecedentes = File(photo.path);
      });
      await prefs.remove('lost_photo_type');
    }
  }

  void _showImageSourceOptions(String type) {
    FocusScope.of(context).unfocus();
    showModalBottomSheet(
      context: context,
      builder: (context) => Wrap(
        children: [
          ListTile(leading: const Icon(Icons.camera), title: const Text('Tomar Foto con Cámara'), onTap: () { Navigator.pop(context); _pickImage(type, ImageSource.camera); }),
          ListTile(leading: const Icon(Icons.photo), title: const Text('Elegir de Galería'), onTap: () { Navigator.pop(context); _pickImage(type, ImageSource.gallery); }),
        ],
      ),
    );
  }

  Future<String> _fileToBase64(File? file) async {
    if (file == null) return '';
    final bytes = await file.readAsBytes();
    return base64Encode(bytes);
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        String? base64Image = _currentBase64Image;
        if (_newImage != null) base64Image = await _fileToBase64(_newImage);

        String? base64DniAnv = _currentDniAnv;
        if (_newDniAnv != null) base64DniAnv = await _fileToBase64(_newDniAnv);

        String? base64DniRev = _currentDniRev;
        if (_newDniRev != null) base64DniRev = await _fileToBase64(_newDniRev);

        String? base64Antecedentes = _currentAntecedentes;
        if (_newAntecedentes != null) base64Antecedentes = await _fileToBase64(_newAntecedentes);

        await _firestore.collection('users').doc(user.uid).update({
          'nombre': _nombreController.text.trim(),
          'apellidoPaterno': _apellidoPaternoController.text.trim(),
          'apellidoMaterno': _apellidoMaternoController.text.trim(),
          'telefono': '$_selectedCountryCode${_telefonoController.text.trim()}', // Guardamos código + número
          'fechaNacimiento': _fechaNacimiento != null ? Timestamp.fromDate(_fechaNacimiento!) : null,
          'imagen': base64Image,
          'especialidades': _especialidades,
          'documentos': {
            'dni_anverso': base64DniAnv,
            'dni_reverso': base64DniRev,
            'antecedentes': base64Antecedentes,
          },
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Perfil actualizado exitosamente')));
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al guardar: $e')));
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _editarPuestos() {
    showDialog(
      context: context,
      builder: (context) {
        String selectedCat = _categorias.first;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            List<String> puestosDisp = _puestosPorCategoria[selectedCat] ?? [];
            return AlertDialog(
              title: const Text('Editar Especialidades'),
              content: SizedBox(
                width: double.maxFinite,
                height: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: selectedCat,
                      items: _categorias.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (val) {
                        setDialogState(() => selectedCat = val!);
                      },
                      decoration: const InputDecoration(labelText: 'Categoría', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: puestosDisp.map((puesto) {
                            bool isSelected = _especialidades.contains(puesto);
                            return CheckboxListTile(
                              title: Text(puesto),
                              value: isSelected,
                              onChanged: (val) {
                                setDialogState(() {
                                  if (val == true) {
                                    if (_especialidades.length < 5) {
                                      _especialidades.add(puesto);
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Máximo 5 puestos')));
                                    }
                                  } else {
                                    _especialidades.remove(puesto);
                                  }
                                });
                                setState(() {}); 
                              },
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cerrar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _vincularGoogle() async {
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

      await _auth.currentUser?.linkWithCredential(credential);
      setState(() {
        _tieneGoogle = true;
        _email = googleUser.email;
      });
      await _firestore.collection('users').doc(_auth.currentUser!.uid).update({'email': googleUser.email});
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Google vinculado con éxito')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al vincular Google: $e')));
    }
  }

  Future<void> _vincularTelefono() async {
    if (_telefonoController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ingresa un número de teléfono')));
      return;
    }
    
    // Formatear el número correctamente para E.164
    String cleanPhone = _telefonoController.text.replaceAll(RegExp(r'[^\d]'), ''); // Solo dígitos
    String phoneNumber = '$_selectedCountryCode$cleanPhone';

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _auth.currentUser?.linkWithCredential(credential);
          setState(() => _tieneTelefono = true);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Teléfono vinculado con éxito')));
        },
        verificationFailed: (FirebaseAuthException e) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.message}')));
        },
        codeSent: (String verificationId, int? resendToken) {
          final TextEditingController codeController = TextEditingController();
          showDialog(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: const Text('Código SMS'),
              content: TextField(controller: codeController, keyboardType: TextInputType.number),
              actions: [
                TextButton(
                  onPressed: () async {
                    Navigator.pop(dialogContext);
                    try {
                      PhoneAuthCredential credential = PhoneAuthProvider.credential(verificationId: verificationId, smsCode: codeController.text.trim());
                      await _auth.currentUser?.linkWithCredential(credential);
                      setState(() => _tieneTelefono = true);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Teléfono vinculado con éxito')));
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Código incorrecto')));
                    }
                  },
                  child: const Text('Verificar'),
                ),
              ],
            ),
          );
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al enviar SMS: $e')));
    }
  }

  Widget _buildImagePreview(String? base64, File? newFile, String label, String type) {
    ImageProvider? image;
    if (newFile != null) {
      image = FileImage(newFile);
    } else if (base64 != null && base64.isNotEmpty) {
      // ignore: empty_catches
      try { image = MemoryImage(base64Decode(base64)); } catch (e) {}
    }

    return Column(
      children: [
        GestureDetector(
          onTap: () => _showImageSourceOptions(type),
          child: Container(
            height: 100,
            width: 100,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey),
              image: image != null ? DecorationImage(image: image, fit: BoxFit.cover) : null,
            ),
            child: image == null ? const Icon(Icons.add_a_photo, size: 40) : null,
          ),
        ),
        const SizedBox(height: 5),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    ImageProvider? profileImage;
    if (_newImage != null) {
      profileImage = FileImage(_newImage!);
    } else if (_currentBase64Image != null && _currentBase64Image!.isNotEmpty) {
      // ignore: empty_catches
      try { profileImage = MemoryImage(base64Decode(_currentBase64Image!)); } catch (e) {}
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: GestureDetector(
                onTap: () => _showImageSourceOptions('perfil'),
                child: CircleAvatar(
                  radius: 60,
                  backgroundImage: profileImage,
                  backgroundColor: Colors.grey[300],
                  child: profileImage == null ? const Icon(Icons.camera_alt, size: 40) : null,
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            const Text('Información Personal', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
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
                DateTime? picked = await showDatePicker(context: context, initialDate: _fechaNacimiento ?? DateTime(2000), firstDate: DateTime(1900), lastDate: DateTime.now());
                if (picked != null) setState(() => _fechaNacimiento = picked);
              },
            ),
            const SizedBox(height: 10),
            
            // CAMPO DE TELÉFONO CORREGIDO CON DROPDOWN
            Row(
              children: [
                DropdownButton<String>(
                  value: _selectedCountryCode,
                  items: _allowedCountryCodes.map((code) => DropdownMenuItem(value: code, child: Text(code))).toList(),
                  onChanged: (val) => setState(() => _selectedCountryCode = val!),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _telefonoController, 
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'Teléfono (Sin código de país)', border: OutlineInputBorder())
                  )
                ),
              ],
            ),
            
            const SizedBox(height: 10),
            TextField(
              controller: TextEditingController(text: _email),
              readOnly: true,
              decoration: const InputDecoration(labelText: 'Correo de Google (No editable)', border: OutlineInputBorder(), filled: true, fillColor: Colors.black12),
            ),

            if (!_tieneTelefono || !_tieneGoogle) ...[
              const SizedBox(height: 20),
              const Text('Vincular Cuentas Faltantes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red)),
              const SizedBox(height: 10),
              if (!_tieneGoogle)
                ElevatedButton.icon(
                  onPressed: _vincularGoogle,
                  icon: const Icon(Icons.g_mobiledata, size: 30),
                  label: const Text('Vincular con Google'),
                  style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 55)),
                ),
              if (!_tieneTelefono) ...[
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: _vincularTelefono,
                  icon: const Icon(Icons.phone),
                  label: const Text('Vincular Número de Teléfono'),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D1B2A), foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 55)),
                ),
              ],
            ],

            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Mis Especialidades', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: _editarPuestos),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children: _especialidades.map((esp) => Chip(label: Text(esp.toString()))).toList(),
            ),

            const SizedBox(height: 20),
            const Text('Mis Documentos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildImagePreview(_currentDniAnv, _newDniAnv, 'DNI Anverso', 'dni_anverso'),
                _buildImagePreview(_currentDniRev, _newDniRev, 'DNI Reverso', 'dni_reverso'),
                _buildImagePreview(_currentAntecedentes, _newAntecedentes, 'Antecedentes', 'antecedentes'),
              ],
            ),

            const SizedBox(height: 30),
            const Text('Cambiar Contraseña', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            TextField(controller: _passwordController, obscureText: true, decoration: const InputDecoration(labelText: 'Nueva Contraseña', border: OutlineInputBorder())),
            const SizedBox(height: 10),
            ElevatedButton(onPressed: _isSaving ? null : _changePassword, child: const Text('Actualizar Contraseña')),
            
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _isSaving ? null : _saveProfile,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D1B2A), minimumSize: const Size(double.infinity, 55)),
              child: _isSaving ? const CircularProgressIndicator(color: Colors.white) : const Text('Guardar Cambios de Perfil', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}