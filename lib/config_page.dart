import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ConfigPage extends StatefulWidget {
  final VoidCallback onSaved;
  const ConfigPage({super.key, required this.onSaved});

  @override
  State<ConfigPage> createState() => _ConfigPageState();
}

class _ConfigPageState extends State<ConfigPage> {
  String _outputMode = 'android'; // 'android' veya 'windows'
  final _formKey = GlobalKey<FormState>();
  final TextEditingController clientIdController = TextEditingController();
  final TextEditingController clientPassController = TextEditingController();
  final TextEditingController userController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController databaseController = TextEditingController();
  final TextEditingController portController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    clientIdController.text = prefs.getString('clientId') ?? '';
    clientPassController.text = prefs.getString('clientPass') ?? '';
    userController.text = prefs.getString('user') ?? '';
    passwordController.text = prefs.getString('password') ?? '';
    databaseController.text = prefs.getString('database') ?? '';
    portController.text = prefs.getString('port') ?? '';
    _outputMode = prefs.getString('outputMode') ?? 'android';
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
