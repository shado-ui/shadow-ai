import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../theme/app_theme.dart';
import '../models/app_state.dart';
import '../services/database_service.dart';

class AgentsScreen extends StatelessWidget {
  const AgentsScreen({super.key});

  static final _agents = <_AgentInfo>[
    _AgentInfo(
      name: 'Deep Research',
      description: 'Analyzes complex topics with multi-step reasoning and citations.',
      icon: Icons.travel_explore,
      gradient: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
      greeting: 'I am your Deep Research assistant. I can analyze complex topics, synthesize information from multiple angles, and provide detailed citations. What would you like me to research?',
    ),
    _AgentInfo(
      name: 'Codex',
      description: 'Software architect that designs systems, writes code, and debugs.',
      icon: Icons.code,
      gradient: [Color(0xFF10B981), Color(0xFF059669)],
      greeting: 'I am Codex, your software engineering assistant. I can help you design systems, write code, debug issues, and review architecture. What are we building?',
    ),
    _AgentInfo(
      name: 'Creative Writer',
      description: 'Writes stories, poems, essays, and creative content with flair.',
      icon: Icons.edit_note,
      gradient: [Color(0xFFF59E0B), Color(0xFFEF4444)],
      greeting: 'I am your Creative Writer. I can craft stories, poems, essays, marketing copy, and more. What would you like me to write?',
    ),
    _AgentInfo(
      name: 'Math Tutor',
      description: 'Step-by-step math solutions from algebra to calculus.',
      icon: Icons.calculate_outlined,
      gradient: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
      greeting: 'I am your Math Tutor. I solve problems step-by-step and explain concepts clearly. What math problem can I help with?',
    ),
    _AgentInfo(
      name: 'Translator',
      description: 'Translates text between languages with context awareness.',
      icon: Icons.translate,
      gradient: [Color(0xFFEC4899), Color(0xFFBE185D)],
      greeting: 'I am your Translator assistant. I can translate text between languages while preserving context and nuance. What would you like translated?',
    ),
    _AgentInfo(
      name: 'Summarizer',
      description: 'Condenses long text into clear, concise summaries.',
      icon: Icons.compress,
      gradient: [Color(0xFF14B8A6), Color(0xFF0F766E)],
      greeting: 'I am your Summarizer. Paste any long text, article, or document and I will create a clear, concise summary. What would you like summarized?',
    ),
  ];

  Future<void> _launchAgent(BuildContext context, _AgentInfo agent) async {
    final db = DatabaseService();
    final newId = const Uuid().v4();
    await db.createProject(newId, agent.name);
    await db.insertMessage({
      'id': const Uuid().v4(),
      'project_id': newId,
      'content': agent.greeting,
      'role': 'assistant',
      'mode': 'auto',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
    AppState().activeProjectId.value = newId;
    AppState().currentTab.value = 0;
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text('AI Agents', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose a specialized agent to start a focused conversation.',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
            ),
            SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isWide ? 3 : 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: isWide ? 1.1 : 0.95,
                ),
                itemCount: _agents.length,
                itemBuilder: (context, index) => _buildAgentCard(context, _agents[index]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAgentCard(BuildContext context, _AgentInfo agent) {
    return GestureDetector(
      onTap: () => _launchAgent(context, agent),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border),
        ),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: agent.gradient),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(agent.icon, color: Colors.white, size: 24),
              ),
              SizedBox(height: 12),
              Text(
                agent.name,
                style: TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 4),
              Expanded(
                child: Text(
                  agent.description,
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, height: 1.4),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.arrow_forward, size: 14, color: agent.gradient.first),
                  SizedBox(width: 4),
                  Text('Start', style: TextStyle(color: agent.gradient.first, fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AgentInfo {
  final String name;
  final String description;
  final IconData icon;
  final List<Color> gradient;
  final String greeting;

  const _AgentInfo({
    required this.name,
    required this.description,
    required this.icon,
    required this.gradient,
    required this.greeting,
  });
}
