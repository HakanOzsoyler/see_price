import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ConfigPage extends StatefulWidget {
  final VoidCallback onSaved;
  const ConfigPage({super.key, required this.onSaved});

  @override
  State<ConfigPage> createState() => _ConfigPageState();
}

class _ConfigPageState extends State<ConfigPage> {
  static const String _logoImagePreferenceKey = 'logoImageBase64';
  final ImagePicker _imagePicker = ImagePicker();
  String _outputMode = 'android'; // 'android' veya 'windows'
  bool _kioskMode = false;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController clientIdController = TextEditingController();
  final TextEditingController clientPassController = TextEditingController();
  final TextEditingController userController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController databaseController = TextEditingController();
  final TextEditingController portController = TextEditingController();
  Uint8List? _logoImageBytes;
  String? _logoImageError;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final logoImageBase64 = prefs.getString(_logoImagePreferenceKey);
    Uint8List? logoImageBytes;

    if (logoImageBase64 != null && logoImageBase64.isNotEmpty) {
      try {
        logoImageBytes = base64Decode(logoImageBase64);
      } catch (_) {
        logoImageBytes = null;
      }
    }

    if (!mounted) {
      return;
    }

    setState(() {
      clientIdController.text = prefs.getString('clientId') ?? '';
      clientPassController.text = prefs.getString('clientPass') ?? '';
      userController.text = prefs.getString('user') ?? '';
      passwordController.text = prefs.getString('password') ?? '';
      databaseController.text = prefs.getString('database') ?? '';
      portController.text = prefs.getString('port') ?? '';
      _outputMode = prefs.getString('outputMode') ?? 'android';
      _kioskMode = prefs.getBool('kioskMode') ?? false;
      _logoImageBytes = logoImageBytes;
      _logoImageError = null;
    });
  }

  Future<void> _pickLogoImage(ImageSource source) async {
    try {
      final pickedImage = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1400,
      );

      if (pickedImage == null) {
        return;
      }

      final imageBytes = await pickedImage.readAsBytes();
      if (!mounted) {
        return;
      }

      setState(() {
        _logoImageBytes = imageBytes;
        _logoImageError = null;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _logoImageError = 'Logo görseli seçilemedi.';
      });
    }
  }

  void _clearLogoImage() {
    setState(() {
      _logoImageBytes = null;
      _logoImageError = null;
    });
  }

  Future<void> _savePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('clientId', clientIdController.text);
    await prefs.setString('clientPass', clientPassController.text);
    await prefs.setString('user', userController.text);
    await prefs.setString('password', passwordController.text);
    await prefs.setString('database', databaseController.text);
    await prefs.setString('port', portController.text);
    await prefs.setString('outputMode', _outputMode);
    await prefs.setBool('kioskMode', _kioskMode);
    if (_logoImageBytes != null) {
      await prefs.setString(_logoImagePreferenceKey, base64Encode(_logoImageBytes!));
    } else {
      await prefs.remove(_logoImagePreferenceKey);
    }
    widget.onSaved();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ayarlar')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const SizedBox(height: 8),
              const Text('Çalışma Modu', style: TextStyle(fontWeight: FontWeight.bold)),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('Android (API ile)'),
                      value: 'android',
                      groupValue: _outputMode,
                      onChanged: (v) => setState(() => _outputMode = v!),
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('Windows (Klavye/Enter)'),
                      value: 'windows',
                      groupValue: _outputMode,
                      onChanged: (v) => setState(() => _outputMode = v!),
                    ),
                  ),
                ],
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Kiosk Modu'),
                subtitle: const Text('Tam ekran, sistem UI gizleme ve ekranı açık tutma'),
                value: _kioskMode,
                onChanged: (value) => setState(() => _kioskMode = value),
              ),
              const SizedBox(height: 24),
              const Text('Ana Ekran Logosu', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.black.withOpacity(0.08)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.black.withOpacity(0.08)),
                        ),
                        alignment: Alignment.center,
                        child: _logoImageBytes != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.memory(
                                  _logoImageBytes!,
                                  fit: BoxFit.contain,
                                  gaplessPlayback: true,
                                ),
                              )
                            : const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.image_outlined, size: 44, color: Colors.grey),
                                  SizedBox(height: 8),
                                  Text('Varsayılan logo kullanılacak'),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _pickLogoImage(ImageSource.gallery),
                            icon: const Icon(Icons.photo_library_outlined),
                            label: const Text('Galeriden Seç'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _pickLogoImage(ImageSource.camera),
                            icon: const Icon(Icons.photo_camera_outlined),
                            label: const Text('Kameradan Çek'),
                          ),
                        ),
                      ],
                    ),
                    if (_logoImageBytes != null) ...[
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _clearLogoImage,
                        child: const Text('Logoyu Kaldır'),
                      ),
                    ],
                    if (_logoImageError != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _logoImageError!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ],
                  ],
                ),
              ),
              TextFormField(
                controller: clientIdController,
                decoration: const InputDecoration(labelText: 'clientId'),
                validator: (v) => v == null || v.isEmpty ? 'Zorunlu' : null,
              ),
              TextFormField(
                controller: clientPassController,
                decoration: const InputDecoration(labelText: 'clientPass'),
                validator: (v) => v == null || v.isEmpty ? 'Zorunlu' : null,
              ),
              TextFormField(
                controller: userController,
                decoration: const InputDecoration(labelText: 'user'),
                validator: (v) => v == null || v.isEmpty ? 'Zorunlu' : null,
              ),
              TextFormField(
                controller: passwordController,
                decoration: const InputDecoration(labelText: 'password'),
                obscureText: true,
                validator: (v) => v == null || v.isEmpty ? 'Zorunlu' : null,
              ),
              TextFormField(
                controller: databaseController,
                decoration: const InputDecoration(labelText: 'database'),
                validator: (v) => v == null || v.isEmpty ? 'Zorunlu' : null,
              ),
              TextFormField(
                controller: portController,
                decoration: const InputDecoration(labelText: 'port'),
                keyboardType: TextInputType.number,
                validator: (v) => v == null || v.isEmpty ? 'Zorunlu' : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _savePrefs();
                  }
                },
                child: const Text('Kaydet'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
