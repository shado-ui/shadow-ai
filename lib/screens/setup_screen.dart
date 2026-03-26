import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _orController = TextEditingController();
  final _geminiController = TextEditingController();
  final _hfController = TextEditingController();
  bool _hasOpenRouter = false;
  bool _hasGemini = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkKeys();
  }

  Future<void> _checkKeys() async {
    final or = await DatabaseService().getSetting('openrouter_key');
    final gem = await DatabaseService().getSetting('api_key');
    setState(() {
      _hasOpenRouter = or != null && or.trim().isNotEmpty;
      _hasGemini = gem != null && gem.trim().isNotEmpty;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _orController.dispose();
    _geminiController.dispose();
    _hfController.dispose();
    super.dispose();
  }

  Future<void> _saveKeys() async {
    final orKey = _orController.text.trim();
    final gemKey = _geminiController.text.trim();
    final hfKey = _hfController.text.trim();

    if (orKey.isNotEmpty) {
      await DatabaseService().saveSetting('openrouter_key', orKey);
    }
    if (gemKey.isNotEmpty) {
      await DatabaseService().saveSetting('api_key', gemKey);
    }
    if (hfKey.isNotEmpty) {
      await DatabaseService().saveSetting('hf_key', hfKey);
    }

    if (mounted) {
      await _checkKeys();
      if (_hasOpenRouter || _hasGemini) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // If already has keys, skip to home
    if (_hasOpenRouter || _hasGemini) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed('/home');
      });
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              Icon(Icons.auto_awesome, size: 64, color: AppTheme.accent),
              const SizedBox(height: 24),
              Text(
                'Welcome to Shadow AI',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Add your API keys to get started',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              _buildKeyCard(
                'OpenRouter (Recommended)',
                'Free AI access to GPT-4, Claude, and more',
                Icons.router,
                _orController,
                'Get free key: openrouter.ai/keys',
                'https://openrouter.ai/keys',
              ),
              const SizedBox(height: 16),
              _buildKeyCard(
                'Gemini (Optional)',
                'Google\'s AI models',
                Icons.auto_awesome,
                _geminiController,
                'Get free key: aistudio.google.com/apikey',
                'https://aistudio.google.com/apikey',
              ),
              const SizedBox(height: 16),
              _buildKeyCard(
                'Hugging Face (Optional)',
                'For image generation',
                Icons.image,
                _hfController,
                'Get free token: huggingface.co/settings/tokens',
                'https://huggingface.co/settings/tokens',
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _saveKeys,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Continue',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Your keys are stored locally on your device and are never shared.',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKeyCard(
    String title,
    String subtitle,
    IconData icon,
    TextEditingController controller,
    String helpText,
    String helpUrl,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.accent, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            obscureText: true,
            style: TextStyle(color: AppTheme.textPrimary, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Paste your API key here',
              hintStyle: TextStyle(color: AppTheme.textSecondary),
              filled: true,
              fillColor: AppTheme.surfaceAlt,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppTheme.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppTheme.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppTheme.accent),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () {
              // Open URL - would use url_launcher in real app
            },
            child: Text(
              helpText,
              style: TextStyle(
                color: AppTheme.accent,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
