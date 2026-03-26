import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import '../theme/app_theme.dart';
import '../models/app_state.dart';
import '../services/database_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _db = DatabaseService();
  final _geminiCtrl = TextEditingController();
  final _openRouterCtrl = TextEditingController();
  final _hfCtrl = TextEditingController();
  final _localModelCtrl = TextEditingController();
  final _customHexCtrl = TextEditingController();
  final _veoCtrl = TextEditingController();
  bool _obscureGemini = true;
  bool _obscureOR = true;
  bool _obscureHF = true;
  bool _obscureVeo = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final gemini = await _db.getSetting('api_key');
    final or = await _db.getSetting('openrouter_key');
    final hf = await _db.getSetting('hf_key');
    final local = await _db.getSetting('local_gguf_path');
    final hex = await _db.getSetting('custom_theme_hex');
    final veo = await _db.getSetting('veo_key');
    if (mounted) {
      setState(() {
        _geminiCtrl.text = gemini ?? '';
        _openRouterCtrl.text = or ?? '';
        _hfCtrl.text = hf ?? '';
        _localModelCtrl.text = local ?? '';
        _customHexCtrl.text = hex ?? '';
        _veoCtrl.text = veo ?? '';
      });
    }
  }

  Future<void> _importGgufModel() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
      );
      if (result == null || result.files.isEmpty || result.files.first.path == null) return;

      final srcPath = result.files.first.path!;
      final fileName = result.files.first.name;

      if (!fileName.toLowerCase().endsWith('.gguf')) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Please select a .gguf model file'),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
        return;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(children: [
              SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
              SizedBox(width: 12),
              Expanded(child: Text('Importing $fileName...')),
            ]),
            backgroundColor: AppTheme.accent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: Duration(seconds: 30),
          ),
        );
      }

      // Copy to app's models directory
      final appDir = await getApplicationSupportDirectory();
      final modelsDir = Directory('${appDir.path}${Platform.pathSeparator}models');
      if (!await modelsDir.exists()) {
        await modelsDir.create(recursive: true);
      }
      final destPath = '${modelsDir.path}${Platform.pathSeparator}$fileName';
      await File(srcPath).copy(destPath);

      // Save as active model path
      await _db.saveSetting('local_gguf_path', destPath);
      _localModelCtrl.text = destPath;

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Model imported! Select "Offline" mode to use it.'),
            backgroundColor: AppTheme.accent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import failed: ${e.toString().replaceFirst("Exception: ", "")}'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  Future<void> _createBackup() async {
    try {
      final data = await _db.exportAllData();
      final jsonStr = const JsonEncoder.withIndent('  ').convert(data);
      final dir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first;
      final file = File('${dir.path}/shadowhub_backup_$timestamp.json');
      await file.writeAsString(jsonStr);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Backup created! Sharing...'),
            backgroundColor: AppTheme.accent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Shadow AI Backup',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Backup failed: ${e.toString().replaceFirst("Exception: ", "")}'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  Future<void> _restoreBackup() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (result == null || result.files.isEmpty || result.files.first.path == null) return;

      final file = File(result.files.first.path!);
      final jsonStr = await file.readAsString();
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;

      if (data['version'] == null || data['projects'] == null) {
        throw Exception('Invalid backup file');
      }

      final count = await _db.importAllData(data);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Restored $count items successfully!'),
            backgroundColor: AppTheme.accent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        _loadSettings();
        AppState().refreshProjects();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Restore failed: ${e.toString().replaceFirst("Exception: ", "")}'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  Future<void> _saveSetting(String key, String value) async {
    await _db.saveSetting(key, value);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Saved'),
          duration: Duration(seconds: 1),
          backgroundColor: AppTheme.accent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  void dispose() {
    _geminiCtrl.dispose();
    _openRouterCtrl.dispose();
    _hfCtrl.dispose();
    _veoCtrl.dispose();
    _localModelCtrl.dispose();
    _customHexCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text('Settings', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        children: [
          _buildCard(
            title: 'APPEARANCE',
            icon: Icons.palette_outlined,
            children: [
              ListTile(
                leading: Icon(Icons.color_lens_outlined, color: AppTheme.accent, size: 22),
                title: Text('Theme', style: TextStyle(color: AppTheme.textPrimary, fontSize: 15)),
                trailing: ValueListenableBuilder<String>(
                  valueListenable: AppState().currentTheme,
                  builder: (context, theme, child) {
                    return Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceAlt,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: DropdownButton<String>(
                        value: AppTheme.availableThemes.contains(theme) ? theme : 'Dark',
                        dropdownColor: AppTheme.surface,
                        style: TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                        underline: SizedBox.shrink(),
                        isDense: true,
                        items: AppTheme.availableThemes.map((t) =>
                          DropdownMenuItem(value: t, child: Text(t)),
                        ).toList(),
                        onChanged: (val) async {
                          if (val != null) {
                            AppState().currentTheme.value = val;
                            await _db.saveSetting('app_theme', val);
                          }
                        },
                      ),
                    );
                  },
                ),
              ),
              ValueListenableBuilder<String>(
                valueListenable: AppState().currentTheme,
                builder: (context, theme, child) {
                  if (theme != 'Custom') return SizedBox.shrink();
                  return _buildKeyField(
                    label: 'Custom Accent Hex (e.g. FF5722)',
                    controller: _customHexCtrl,
                    icon: Icons.tag,
                    obscure: false,
                    onSave: () async {
                      await _saveSetting('custom_theme_hex', _customHexCtrl.text.trim());
                      try {
                        final val = int.parse(_customHexCtrl.text.trim().replaceAll('#', ''), radix: 16);
                        AppTheme.customAccent = Color(0xFF000000 | val);
                        AppState().currentTheme.value = 'Custom';
                      } catch (_) {}
                    },
                  );
                },
              ),
            ],
          ),
          _buildCard(
            title: 'API KEYS',
            icon: Icons.key_outlined,
            children: [
              _buildKeyField(
                label: 'Gemini API Key',
                controller: _geminiCtrl,
                icon: Icons.auto_awesome,
                obscure: _obscureGemini,
                onToggle: () => setState(() => _obscureGemini = !_obscureGemini),
                onSave: () => _saveSetting('api_key', _geminiCtrl.text.trim()),
              ),
              Divider(color: AppTheme.border, height: 1, indent: 16, endIndent: 16),
              _buildKeyField(
                label: 'OpenRouter API Key',
                controller: _openRouterCtrl,
                icon: Icons.router_outlined,
                obscure: _obscureOR,
                onToggle: () => setState(() => _obscureOR = !_obscureOR),
                onSave: () => _saveSetting('openrouter_key', _openRouterCtrl.text.trim()),
              ),
              Divider(color: AppTheme.border, height: 1, indent: 16, endIndent: 16),
              _buildKeyField(
                label: 'Hugging Face Token',
                controller: _hfCtrl,
                icon: Icons.emoji_nature_outlined,
                obscure: _obscureHF,
                onToggle: () => setState(() => _obscureHF = !_obscureHF),
                onSave: () => _saveSetting('hf_key', _hfCtrl.text.trim()),
              ),
              Divider(color: AppTheme.border, height: 1, indent: 16, endIndent: 16),
              _buildKeyField(
                label: 'Video API Key (modelslab.com)',
                controller: _veoCtrl,
                icon: Icons.movie_creation_outlined,
                obscure: _obscureVeo,
                onToggle: () => setState(() => _obscureVeo = !_obscureVeo),
                onSave: () => _saveSetting('veo_key', _veoCtrl.text.trim()),
              ),
            ],
          ),
          _buildCard(
            title: 'LOCAL MODEL',
            icon: Icons.memory,
            children: [
              ListTile(
                leading: Icon(Icons.file_download_outlined, color: AppTheme.accent, size: 22),
                title: Text('Import GGUF Model', style: TextStyle(color: AppTheme.textPrimary, fontSize: 15)),
                subtitle: Text('Pick a .gguf file from your device', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                trailing: Icon(Icons.chevron_right, color: AppTheme.textSecondary, size: 20),
                onTap: _importGgufModel,
              ),
              Divider(color: AppTheme.border, height: 1, indent: 16, endIndent: 16),
              _buildKeyField(
                label: 'Or paste full path to .gguf file',
                controller: _localModelCtrl,
                icon: Icons.folder_open_outlined,
                obscure: false,
                onSave: () => _saveSetting('local_gguf_path', _localModelCtrl.text.trim()),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Text(
                  'On iOS, use "Import GGUF Model" above. On desktop, you can also paste the full file path.',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                ),
              ),
            ],
          ),
          _buildCard(
            title: 'YOUR DATA',
            icon: Icons.storage_outlined,
            children: [
              ListTile(
                leading: Icon(Icons.download_rounded, color: AppTheme.accent, size: 22),
                title: Text('Download Your Data', style: TextStyle(color: AppTheme.textPrimary, fontSize: 15)),
                subtitle: Text('Export all chats, settings & projects as JSON', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                trailing: Icon(Icons.chevron_right, color: AppTheme.textSecondary, size: 20),
                onTap: _createBackup,
              ),
              Divider(color: AppTheme.border, height: 1, indent: 16, endIndent: 16),
              ListTile(
                leading: Icon(Icons.upload_rounded, color: AppTheme.accent, size: 22),
                title: Text('Restore from Backup', style: TextStyle(color: AppTheme.textPrimary, fontSize: 15)),
                subtitle: Text('Import a previously downloaded backup file', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                trailing: Icon(Icons.chevron_right, color: AppTheme.textSecondary, size: 20),
                onTap: _restoreBackup,
              ),
            ],
          ),
          _buildCard(
            title: 'ABOUT',
            icon: Icons.info_outline,
            children: [
              ListTile(
                leading: Icon(Icons.blur_on, color: AppTheme.accent, size: 22),
                title: Text('Shadow AI', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
                subtitle: Text('v1.0.0 — Hybrid AI Chat', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
              ),
              ListTile(
                leading: Icon(Icons.code, color: AppTheme.textSecondary, size: 22),
                title: Text('Powered by Gemini, OpenRouter, HuggingFace, Veo & llama.cpp',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
              ),
            ],
          ),
          SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildKeyField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required bool obscure,
    VoidCallback? onToggle,
    required VoidCallback onSave,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.accent, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              obscureText: obscure,
              style: TextStyle(color: AppTheme.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                labelText: label,
                labelStyle: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                filled: true,
                fillColor: AppTheme.surfaceAlt,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppTheme.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppTheme.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppTheme.accent, width: 1.5),
                ),
                suffixIcon: onToggle != null
                    ? IconButton(
                        icon: Icon(obscure ? Icons.visibility_off : Icons.visibility, size: 18, color: AppTheme.textSecondary),
                        onPressed: onToggle,
                      )
                    : null,
              ),
            ),
          ),
          SizedBox(width: 8),
          Material(
            color: AppTheme.accent,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: onSave,
              child: Padding(
                padding: EdgeInsets.all(10),
                child: Icon(Icons.check, color: Colors.white, size: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required String title, required IconData icon, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 4, bottom: 8, top: 4),
          child: Row(
            children: [
              Icon(icon, size: 16, color: AppTheme.textSecondary),
              SizedBox(width: 6),
              Text(title, style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1)),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.border),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Column(children: children),
          ),
        ),
        SizedBox(height: 24),
      ],
    );
  }
}
