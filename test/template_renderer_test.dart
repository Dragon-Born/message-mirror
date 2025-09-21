import 'package:flutter_test/flutter_test.dart';
import 'package:message_mirror/template_renderer.dart';

void main() {
  group('TemplateRenderer', () {
    test('renders placeholders and parses JSON', () {
      const tpl = '{"a":"{{body}}","b":"{{from}}","c":"{{date}}","t":"{{type}}","x":"{{reception}}"}';
      final res = TemplateRenderer.render(tpl, {
        'body': 'hello',
        'from': 'Alice',
        'date': '2025-09-21 10:00',
        'type': 'notification',
        'reception': 'site-1',
      });
      expect(res['a'], 'hello');
      expect(res['b'], 'Alice');
      expect(res['c'], '2025-09-21 10:00');
      expect(res['t'], 'notification');
      expect(res['x'], 'site-1');
    });

    test('falls back on invalid JSON', () {
      const tpl = '{"a":"{{body}}"'; // missing closing brace
      final res = TemplateRenderer.render(tpl, {'body': 'x'}, fallback: {'z': 1});
      expect(res['z'], 1);
    });

    test('escapes quotes and newlines', () {
      const tpl = '{"a":"{{body}}"}';
      final res = TemplateRenderer.render(tpl, {'body': 'He said: "Hi"\nNext'}, fallback: {});
      expect(res['a'], 'He said: "Hi"\nNext');
    });
  });
}


