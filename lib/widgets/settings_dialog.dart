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
    final screenWidth = MediaQuery.of(context).size.width;

    return AlertDialog(
      backgroundColor: const Color(0xFF1E1E1E),
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.settings, color: Colors.deepPurpleAccent, size: 20),
              const SizedBox(width: 8),
              Text(
                state.t('settings_title'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20, color: Colors.grey),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      content: SizedBox(
        width: screenWidth < 500 ? screenWidth * 0.9 : 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. GIAO DIỆN TỐI (DARK MODE)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(state.t('dark_mode'), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                subtitle: Text(state.t('dark_mode_desc'), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                secondary: const Icon(Icons.dark_mode_outlined),
                value: state.themeMode == ThemeMode.dark,
                onChanged: (_) {
                  state.toggleTheme();
                  setState(() {});
                },
              ),
              const Divider(height: 20),

              // 2. NGÔN NGỮ HIỂN THỊ (VI / EN GỌN GÀNG)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.language_outlined, size: 20, color: Colors.grey),
                      const SizedBox(width: 12),
                      Text(state.t('lang_label'), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  SegmentedButton<String>(
                    style: const ButtonStyle(
                      visualDensity: VisualDensity.compact,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    segments: const [
                      ButtonSegment(value: 'vi', label: Text('VI', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                      ButtonSegment(value: 'en', label: Text('EN', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                    ],
                    selected: {state.language},
                    onSelectionChanged: (val) {
                      state.toggleLanguage();
                      setState(() {});
                    },
                  ),
                ],
              ),
              const Divider(height: 24),

              // 3. KIỂU PHÔNG CHỮ ĐỌC (XẾP DỌC TRÁNH TRÀN BỀ NGANG)
              Row(
                children: [
                  const Icon(Icons.font_download_outlined, size: 20, color: Colors.grey),
                  const SizedBox(width: 12),
                  Text(state.t('font_family_label'), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: state.fontFamily,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
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
              const Divider(height: 24),

              // 4. CỠ CHỮ ĐỌC MẶC ĐỊNH
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.format_size, size: 20, color: Colors.grey),
                      const SizedBox(width: 12),
                      Text(state.t('default_font_size'), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  Text('${state.defaultFontSize.toInt()} px', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurpleAccent)),
                ],
              ),
              Slider(
                value: state.defaultFontSize,
                min: 14,
                max: 28,
                divisions: 7,
                activeColor: Colors.deepPurpleAccent,
                onChanged: (v) {
                  state.updateReadingSettings(fontSize: v);
                  setState(() {});
                },
              ),
            ],
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.only(right: 16, bottom: 16),
      actions: [
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Colors.deepPurpleAccent),
          onPressed: () => Navigator.pop(context),
          child: Text(state.t('close')),
        ),
      ],
    );
  }
}