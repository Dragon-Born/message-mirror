import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:message_mirror/prefs.dart';
import 'package:message_mirror/logger.dart';

class PayloadTemplateScreen extends StatefulWidget {
  const PayloadTemplateScreen({super.key});

  @override
  State<PayloadTemplateScreen> createState() => _PayloadTemplateScreenState();
}

class _PayloadTemplateScreenState extends State<PayloadTemplateScreen> {
  final TextEditingController _ctrl = TextEditingController();
  bool _dirty = false;
  String? _error;

  static const String _defaultTemplate = '''
{
  "message_body": "{{body}}",
  "message_from": "{{from}}",
  "message_date": "{{date}}"
}
''';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final tpl = await Prefs.getPayloadTemplate();
    if (!mounted) return;
    String normalized = tpl;
    if (normalized.contains('\\n')) {
      normalized = normalized.replaceAll('\\n', '\n');
    }
    if (normalized.contains('\\"')) {
      normalized = normalized.replaceAll('\\"', '"');
    }
    setState(() {
      _ctrl.text = (normalized.trim().isEmpty) ? _defaultTemplate : normalized;
      _dirty = false;
      _error = null;
    });
  }

  void _validate(String text) {
    try {
      jsonDecode(text);
      setState(() { _error = null; _dirty = true; });
    } catch (e) {
      setState(() { _error = 'Invalid JSON: ${e.toString()}'; _dirty = true; });
    }
  }

  Future<void> _save() async {
    final text = _ctrl.text.trim();
    try {
      jsonDecode(text);
    } catch (e) {
      setState(() { _error = 'Invalid JSON: ${e.toString()}'; });
      return;
    }
    await Prefs.setPayloadTemplate(text);
    await Logger.d('Payload template saved');
    if (!mounted) return;
    setState(() { _dirty = false; });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Template saved')));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.data_object_rounded,
                color: colorScheme.onPrimaryContainer,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Payload Template'),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colorScheme.outlineVariant, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Placeholders', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text('{{body}}, {{from}}, {{date}}, {{app}}, {{type}}, {{reception}}',
                      style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 8),
                  Text('Extra fields (if present): subText, summaryText, bigText, infoText, people, category, priority, channelId, actions, groupKey, visibility, color, badgeIconType, largeIcon, picture',
                      style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 4),
                  Text('See README for full list and examples.',
                      style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.primary)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Scrollbar(
                child: TextField(
                  controller: _ctrl,
                  onChanged: _validate,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  keyboardType: TextInputType.multiline,
                  style: theme.textTheme.bodySmall?.copyWith(fontFamily: 'monospace', height: 1.4),
                  decoration: const InputDecoration(
                    labelText: 'JSON Template',
                    alignLabelWithHint: true,
                    contentPadding: EdgeInsets.all(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () { setState(() { _ctrl.text = _defaultTemplate; _error = null; _dirty = true; }); },
                    icon: const Icon(Icons.restore_rounded),
                    label: const Text('Restore Default'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _dirty && _error == null ? _save : null,
                    icon: const Icon(Icons.save_rounded),
                    label: const Text('Save'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


