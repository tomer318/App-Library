import 'package:flutter/material.dart';
import '../state/app_state.dart';

class SettingsDialog extends StatefulWidget {
  const SettingsDialog({super.key});

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  @override
  Widget build(BuildContext context) {
    final state = globalAppState;

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.settings, color: Colors.deepPurpleAccent),
          const SizedBox(width: 8),
          Text(state.t('settings_title'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        ],
      ),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              title: Text(state.t('dark_mode')),
              subtitle: Text(state.t('dark_mode_desc')),
              secondary: const Icon(Icons.dark_mode_outlined),
              value: state.themeMode == ThemeMode.dark,
              onChanged: (_) {
                state.toggleTheme();
                setState(() {});
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.language_outlined),
              title: Text(state.t('lang_label')),
              trailing: SegmentedButton<String>(
                segments: [
                  ButtonSegment(value: 'vi', label: Text(state.t('filter_vi'))),
                  ButtonSegment(value: 'en', label: Text(state.t('filter_en'))),
                ],
                selected: {state.language},
                onSelectionChanged: (val) {
                  state.toggleLanguage();
                  setState(() {});
                },
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.font_download_outlined),
              title: Text(state.t('font_family_label')),
              trailing: DropdownButton<String>(
                value: state.fontFamily,
                items: [
                  DropdownMenuItem(value: 'Mặc định', child: Text(state.t('font_sans'))),
                  DropdownMenuItem(value: 'Serif', child: Text(state.t('font_serif'))),
                ],
                onChanged: (val) {
                  if (val != null) {
                    state.updateReadingSettings(font: val);
                    setState(() {});
                  }
                },
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.format_size),
              title: Text(state.t('default_font_size')),
              trailing: Text('${state.defaultFontSize.toInt()} px', style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Slider(
                value: state.defaultFontSize,
                min: 14,
                max: 28,
                divisions: 7,
                onChanged: (v) {
                  state.updateReadingSettings(fontSize: v);
                  setState(() {});
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: Text(state.t('close')),
        ),
      ],
    );
  }
}