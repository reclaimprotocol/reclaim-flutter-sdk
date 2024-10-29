import 'dart:io';
import 'package:yaml/yaml.dart';

void main() {
  // Read pubspec.yaml
  final pubspecFile = File('pubspec.yaml');
  final pubspecContent = pubspecFile.readAsStringSync();
  final pubspec = loadYaml(pubspecContent);

  // Extract version
  final version = pubspec['version'] ?? '0.0.0';

  // Read CHANGELOG.md
  final changelogFile = File('CHANGELOG.md');

  // Create new changelog entry
  final newEntry = '''
## [$version] - ${DateTime.now().toIso8601String().split('T')[0]}

- TODO: Add release notes.
''';

  // Write new content (this will overwrite existing content)
  changelogFile.writeAsStringSync(newEntry.trim());
  print('CHANGELOG.md updated with version $version.');
}
