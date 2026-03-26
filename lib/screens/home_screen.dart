import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'chat_screen.dart';
import 'image_screen.dart';
import 'video_screen.dart';
import 'agents_screen.dart';
import 'settings_screen.dart';
import 'models_screen.dart';
import '../models/app_state.dart';
import '../services/database_service.dart';
import 'package:uuid/uuid.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;
  final _db = DatabaseService();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  List<Map<String, dynamic>> _projects = [];
  Map<String, int> _messageCounts = {};
  final String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadProjects();
    AppState().currentTab.addListener(() {
      if (mounted && _index != AppState().currentTab.value) {
        setState(() => _index = AppState().currentTab.value);
      }
    });
    AppState().activeProjectId.addListener(() {
      if (mounted) {
        _loadProjects();
        setState(() {});
      }
    });
    AppState().projectsVersion.addListener(() {
      if (mounted) _loadProjects();
    });
  }

  bool get _isMobile => MediaQuery.of(context).size.width < 700;

  Widget _getPage(int index) {
    switch (index) {
      case 0:
        return ValueListenableBuilder<String>(
          valueListenable: AppState().activeProjectId,
          builder: (context, id, child) => ChatScreen(key: ValueKey(id), projectId: id),
        );
      case 1:
        return const ImageScreen();
      case 2:
        return const AgentsScreen();
      case 3:
        return const SettingsScreen();
      case 4:
        return const VideoScreen();
      case 5:
        return const ModelsScreen();
      default:
        return const SizedBox.shrink();
    }
  }

  Future<void> _loadProjects() async {
    final projects = await _db.getProjects();
    final counts = <String, int>{};
    for (final p in projects) {
      final id = p['id'] as String;
      counts[id] = await _db.getMessageCount(id);
    }
    if (mounted) {
      setState(() {
        _projects = projects;
        _messageCounts = counts;
      });
    }
  }

  Future<void> _createNewChat() async {
    await _db.deleteEmptyProjects(excludeId: 'default');
    final newId = const Uuid().v4();
    await _db.createProject(newId, 'New Chat');
    await _loadProjects();
    AppState().activeProjectId.value = newId;
    AppState().currentTab.value = 0;
    if (mounted && _isMobile) Navigator.of(context).pop();
  }

  Future<void> _deleteProject(String id) async {
    await _db.clearHistory(id);
    await _db.deleteProject(id);
    await _loadProjects();
    if (AppState().activeProjectId.value == id) {
      AppState().activeProjectId.value = _projects.isNotEmpty ? _projects.first['id'] : 'default';
    }
  }

  void _showDeleteDialog(String id, String title) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 36, height: 4, margin: EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(color: AppTheme.border, borderRadius: BorderRadius.circular(2))),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Text(title, style: TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w600),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              SizedBox(height: 4),
              ListTile(
                leading: Icon(Icons.delete_outline, color: Colors.red, size: 20),
                title: Text('Delete chat', style: TextStyle(color: Colors.red, fontSize: 14)),
                onTap: () {
                  Navigator.pop(ctx);
                  _deleteProject(id);
                },
              ),
              ListTile(
                leading: Icon(Icons.close, color: AppTheme.textSecondary, size: 20),
                title: Text('Cancel', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                onTap: () => Navigator.pop(ctx),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============ SIDEBAR ============
  Widget _buildSidebar() {
    final activeId = AppState().activeProjectId.value;
    final allProjects = _searchQuery.isEmpty
        ? _projects
        : _projects.where((p) => (p['title'] ?? '').toString().toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    // Hide empty chats unless they are the currently active chat
    final filteredProjects = allProjects.where((p) {
      final id = p['id'] as String;
      final count = _messageCounts[id] ?? 0;
      return count > 0 || id == activeId;
    }).toList();

    return Container(
      color: AppTheme.sidebar,
      child: SafeArea(
        child: Column(
          children: [
            // New Chat button
            Padding(
              padding: EdgeInsets.fromLTRB(12, 14, 12, 6),
              child: Material(
                color: AppTheme.surfaceAlt.withOpacity(0.5),
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: _createNewChat,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Row(
                      children: [
                        Icon(Icons.add, size: 18, color: AppTheme.textPrimary),
                        SizedBox(width: 10),
                        Text('New chat', style: TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Nav items
            _SidebarItem(icon: Icons.search, label: 'Search chats', isActive: false, onTap: () {}),
            _SidebarItem(icon: Icons.image_outlined, label: 'Images', isActive: _index == 1, onTap: () {
              AppState().currentTab.value = 1;
              if (_isMobile) Navigator.of(context).pop();
            }),
            _SidebarItem(icon: Icons.smart_toy_outlined, label: 'Agents', isActive: _index == 2, onTap: () {
              AppState().currentTab.value = 2;
              if (_isMobile) Navigator.of(context).pop();
            }),
            _SidebarItem(icon: Icons.code, label: 'Video Gen', isActive: _index == 4, onTap: () {
              AppState().currentTab.value = 4;
              if (_isMobile) Navigator.of(context).pop();
            }),
            _SidebarItem(icon: Icons.download_outlined, label: 'Offline Models', isActive: _index == 5, onTap: () {
              AppState().currentTab.value = 5;
              if (_isMobile) Navigator.of(context).pop();
            }),

            SizedBox(height: 6),

            // Recent label
            Padding(
              padding: EdgeInsets.fromLTRB(18, 8, 18, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Recent', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
              ),
            ),

            // Chat list (hide empty chats unless active)
            Expanded(
              child: filteredProjects.isEmpty
                  ? Padding(
                      padding: EdgeInsets.all(20),
                      child: Text('No conversations yet', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      itemCount: filteredProjects.length,
                      itemBuilder: (context, index) {
                        final p = filteredProjects[index];
                        final isActive = AppState().activeProjectId.value == p['id'] && _index == 0;
                        return Dismissible(
                          key: ValueKey(p['id']),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: EdgeInsets.only(right: 16),
                            margin: EdgeInsets.only(bottom: 2),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.delete_outline, color: Colors.red.shade300, size: 18),
                          ),
                          onDismissed: (_) => _deleteProject(p['id']),
                          child: Material(
                            color: isActive ? AppTheme.surfaceAlt.withOpacity(0.6) : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(10),
                              onTap: () async {
                                final oldId = AppState().activeProjectId.value;
                                AppState().activeProjectId.value = p['id'];
                                AppState().currentTab.value = 0;
                                if (_isMobile) Navigator.of(context).pop();
                                // Clean up the old chat if it was empty
                                if (oldId != p['id'] && oldId != 'default') {
                                  final count = await _db.getMessageCount(oldId);
                                  if (count == 0) {
                                    await _db.deleteProject(oldId);
                                    _loadProjects();
                                  }
                                }
                              },
                              onLongPress: () => _showDeleteDialog(p['id'], p['title'] ?? 'Chat'),
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                child: Row(
                                  children: [
                                    Icon(Icons.chat_bubble_outline, size: 15, color: AppTheme.textSecondary),
                                    SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        p['title'] ?? 'New conversation',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () => _showDeleteDialog(p['id'], p['title'] ?? 'Chat'),
                                      child: Icon(Icons.more_horiz, size: 16, color: AppTheme.textSecondary.withOpacity(0.5)),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),

            // Bottom section
            Container(
              decoration: BoxDecoration(border: Border(top: BorderSide(color: AppTheme.border.withOpacity(0.3)))),
              child: Column(
                children: [
                  _SidebarItem(icon: Icons.settings_outlined, label: 'Settings', isActive: _index == 3, onTap: () {
                    AppState().currentTab.value = 3;
                    if (_isMobile) Navigator.of(context).pop();
                  }),
                  Padding(
                    padding: EdgeInsets.only(bottom: 10),
                    child: Text('AI Chat Interface', style: TextStyle(color: AppTheme.textSecondary.withOpacity(0.5), fontSize: 11)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = _isMobile;

    return ValueListenableBuilder<String>(
      valueListenable: AppState().currentTheme,
      builder: (context, theme, child) {
        if (isMobile) {
          return Scaffold(
            key: _scaffoldKey,
            backgroundColor: AppTheme.background,
            drawer: Drawer(width: 280, backgroundColor: AppTheme.sidebar, child: _buildSidebar()),
            body: Column(
              children: [
                Container(
                  padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
                  color: AppTheme.background,
                  child: Container(
                    height: 52,
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.menu, color: AppTheme.textSecondary, size: 22),
                          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                        ),
                        Spacer(),
                        Text('Shadow AI', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 16)),
                        Spacer(),
                        IconButton(
                          icon: Icon(Icons.edit_square, color: AppTheme.textSecondary, size: 20),
                          onPressed: _createNewChat,
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(child: _getPage(_index)),
                // Bottom nav
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.background,
                    border: Border(top: BorderSide(color: AppTheme.border.withOpacity(0.3))),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildNavItem(Icons.chat_outlined, 'Chat', 0),
                          _buildNavItem(Icons.image_outlined, 'Image', 1),
                          _buildNavItem(Icons.smart_toy_outlined, 'Agents', 2),
                          _buildNavItem(Icons.download_outlined, 'Models', 5),
                          _buildNavItem(Icons.settings_outlined, 'Settings', 3),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        // Desktop layout
        return Scaffold(
          backgroundColor: AppTheme.background,
          body: Row(
            children: [
              SizedBox(width: 260, child: _buildSidebar()),
              Expanded(child: _getPage(_index)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNavItem(IconData icon, String label, int tabIndex) {
    final isActive = _index == tabIndex;
    return GestureDetector(
      onTap: () => AppState().currentTab.value = tabIndex,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: isActive ? AppTheme.accent : AppTheme.textSecondary),
            SizedBox(height: 2),
            Text(label, style: TextStyle(
              fontSize: 10,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              color: isActive ? AppTheme.accent : AppTheme.textSecondary,
            )),
          ],
        ),
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _SidebarItem({required this.icon, required this.label, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 18, vertical: 11),
          child: Row(
            children: [
              Icon(icon, size: 18, color: isActive ? AppTheme.textPrimary : AppTheme.textSecondary),
              SizedBox(width: 12),
              Text(label, style: TextStyle(
                color: isActive ? AppTheme.textPrimary : AppTheme.textSecondary,
                fontSize: 14,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              )),
            ],
          ),
        ),
      ),
    );
  }
}
