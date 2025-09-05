import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppSelectorScreen extends StatefulWidget {
  const AppSelectorScreen({super.key});

  @override
  State<AppSelectorScreen> createState() => _AppSelectorScreenState();
}

class _AppSelectorScreenState extends State<AppSelectorScreen> {
  static const MethodChannel _apps = MethodChannel('msg_mirror_apps');
  static const MethodChannel _prefs = MethodChannel('msg_mirror_prefs');

  List<Map<String, String>> _appsList = [];
  Set<String> _selected = {};
  bool _loading = true;
  final Map<String, ImageProvider> _icons = {};
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  static List<Map<String, String>>? _cachedApps;
  static Map<String, ImageProvider>? _cachedIcons;
  bool _onlySelected = false;

  List<Map<String, String>> get _visibleApps {
    Iterable<Map<String, String>> it = _appsList;
    if (_query.isNotEmpty) {
      it = it.where((e) {
        final pkg = e['package']!.toLowerCase();
        final label = e['label']!.toLowerCase();
        return pkg.contains(_query) || label.contains(_query);
      });
    }
    if (_onlySelected) {
      it = it.where((e) => _selected.contains(e['package']!));
    }
    final list = it.toList();
    list.sort((a, b) {
      final aSel = _selected.contains(a['package']!);
      final bSel = _selected.contains(b['package']!);
      if (aSel != bSel) return aSel ? -1 : 1; // selected first
      return a['label']!.toLowerCase().compareTo(b['label']!.toLowerCase());
    });
    return list;
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; });
    // Load selected set regardless
    final selRaw = await _prefs.invokeMethod('getAllowedPackages') as List<dynamic>;
    final sel = selRaw.map((e) => e.toString()).toSet();
    // Use runtime cache if available
    if (_cachedApps != null && _cachedIcons != null) {
      setState(() {
        _appsList = List<Map<String,String>>.from(_cachedApps!);
        _icons.addAll(_cachedIcons!);
        _selected = sel;
        _loading = false;
      });
      return;
    }
    // Fetch once and cache
    final appsRaw = await _apps.invokeMethod('list') as List<dynamic>;
    final list = appsRaw.map((e) => {
      'package': (e['package'] ?? '').toString(),
      'label': (e['label'] ?? '').toString(),
    }).toList();
    setState(() {
      _appsList = list;
      _selected = sel;
    });
    for (final app in list) {
      final pkg = app['package']!;
      try {
        final bytes = await _apps.invokeMethod('icon', pkg) as Uint8List?;
        if (bytes != null) {
          _icons[pkg] = MemoryImage(bytes);
        }
      } catch (_) {}
      if (mounted) setState(() {});
    }
    _cachedApps = List<Map<String,String>>.from(_appsList);
    _cachedIcons = Map<String, ImageProvider>.from(_icons);
    if (mounted) setState(() { _loading = false; });
  }

  Future<void> _save() async {
    await _prefs.invokeMethod('setAllowedPackages', _selected.toList());
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final visibleApps = _visibleApps;

    if (_loading) {
      return Scaffold(
        backgroundColor: colorScheme.surface,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: CircularProgressIndicator(
                  color: colorScheme.primary,
                  strokeWidth: 3,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Loading Applications',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Discovering installed apps...',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          // Modern SliverAppBar with search
          SliverAppBar(
            backgroundColor: colorScheme.surface,
            foregroundColor: colorScheme.onSurface,
            expandedHeight: 160,
            floating: true,
            pinned: true,
            snap: true,
            elevation: 0,
            scrolledUnderElevation: 1,
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.apps_rounded,
                    color: colorScheme.onPrimaryContainer,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Select Apps',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.primaryContainer,
                      colorScheme.primaryContainer.withOpacity(0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 80, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                     
                        TextField(
                          controller: _searchCtrl,
                          decoration: InputDecoration(
                            hintText: 'Search applications...',
                            hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                            prefixIcon: Icon(Icons.search_rounded, color: colorScheme.primary),
                            suffixIcon: _query.isEmpty ? null : IconButton(
                              icon: Icon(Icons.clear_rounded, color: colorScheme.onSurfaceVariant),
                              onPressed: () { 
                                setState(() { 
                                  _searchCtrl.clear(); 
                                  _query = ''; 
                                }); 
                              },
                            ),
                            filled: true,
                            fillColor: colorScheme.surface.withOpacity(0.9),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          ),
                          onChanged: (v) { setState(() { _query = v.trim().toLowerCase(); }); },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          // Stats and Filter Section
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: colorScheme.outlineVariant,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.analytics_rounded,
                    color: colorScheme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_selected.length} Selected',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          '${visibleApps.length} of ${_appsList.length} apps shown',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  FilterChip(
                    label: Text(
                      'Selected Only',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _onlySelected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
                      ),
                    ),
                    selected: _onlySelected,
                    onSelected: (v) { setState(() { _onlySelected = v; }); },
                    backgroundColor: colorScheme.surface,
                    selectedColor: colorScheme.primary,
                    checkmarkColor: colorScheme.onPrimary,
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Apps List
          if (visibleApps.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        _query.isNotEmpty ? Icons.search_off_rounded : Icons.apps_outage_rounded,
                        size: 64,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      _query.isNotEmpty ? 'No Apps Found' : 'No Apps Available',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _query.isNotEmpty 
                          ? 'Try a different search term'
                          : 'No applications to display',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final app = visibleApps[index];
                    final pkg = app['package']!;
                    final label = app['label']!;
                    final checked = _selected.contains(pkg);
                    
                    return Padding(
                      padding: EdgeInsets.only(bottom: index == visibleApps.length - 1 ? 100 : 8),
                      child: _CompactAppCard(
                        package: pkg,
                        label: label,
                        icon: _icons[pkg],
                        isSelected: checked,
                        onToggle: () {
                          setState(() {
                            if (checked) { 
                              _selected.remove(pkg); 
                            } else { 
                              _selected.add(pkg); 
                            }
                          });
                        },
                      ),
                    );
                  },
                  childCount: visibleApps.length,
                ),
              ),
            ),
        ],
      ),
      
      // Bottom Action Bar
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          border: Border(
            top: BorderSide(
              color: colorScheme.outlineVariant,
              width: 1,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      if (_selected.length == _appsList.length) {
                        _selected.clear();
                      } else {
                        _selected = _appsList.map((e) => e['package']!).toSet();
                      }
                    });
                  },
                  icon: Icon(_selected.length == _appsList.length 
                      ? Icons.deselect_rounded 
                      : Icons.select_all_rounded),
                  label: Text(_selected.length == _appsList.length 
                      ? 'Deselect All' 
                      : 'Select All'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Save Selection'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompactAppCard extends StatelessWidget {
  final String package;
  final String label;
  final ImageProvider? icon;
  final bool isSelected;
  final VoidCallback onToggle;

  const _CompactAppCard({
    required this.package,
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected 
                ? colorScheme.primaryContainer.withOpacity(0.2)
                : colorScheme.surfaceContainerHighest.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected 
                  ? colorScheme.primary.withOpacity(0.6)
                  : colorScheme.outlineVariant.withOpacity(0.5),
              width: isSelected ? 1.5 : 0.5,
            ),
          ),
          child: Row(
            children: [
              // App Icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: colorScheme.surface.withOpacity(0.8),
                  image: icon != null ? DecorationImage(
                    image: icon!,
                    fit: BoxFit.cover,
                  ) : null,
                ),
                child: icon == null ? Icon(
                  Icons.apps_rounded,
                  color: colorScheme.onSurfaceVariant,
                  size: 20,
                ) : null,
              ),
              
              const SizedBox(width: 12),
              
              // App Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      package,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontFamily: 'monospace',
                        fontSize: 11,
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Selection State
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isSelected 
                      ? colorScheme.primary 
                      : Colors.transparent,
                  border: Border.all(
                    color: isSelected 
                        ? colorScheme.primary 
                        : colorScheme.outline.withOpacity(0.6),
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: isSelected ? Icon(
                  Icons.check_rounded,
                  color: colorScheme.onPrimary,
                  size: 14,
                ) : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
