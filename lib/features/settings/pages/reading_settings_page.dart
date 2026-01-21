import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:novella/features/settings/settings_provider.dart';
import 'package:novella/features/settings/widgets/settings_ui_helper.dart';

import 'package:novella/features/settings/widgets/settings_header_card.dart';

class ReadingSettingsPage extends ConsumerWidget {
  const ReadingSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const SliverAppBar(),
          const SliverToBoxAdapter(
            child: SettingsHeaderCard(
              icon: Icons.menu_book,
              title: '阅读设置',
              subtitle: '管理排版与阅读习惯',
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              // 字体大小
              ListTile(
                leading: const Icon(Icons.text_fields),
                title: const Text('字体大小'),
                subtitle: Text('${settings.fontSize.toInt()} px'),
                trailing: SizedBox(
                  width: 200,
                  child: Slider(
                    value: settings.fontSize,
                    min: 12,
                    max: 32,
                    divisions: 20,
                    label: '${settings.fontSize.toInt()}',
                    onChanged: (value) => notifier.setFontSize(value),
                  ),
                ),
              ),

              // 繁简转换
              ListTile(
                leading: const Icon(Icons.translate),
                title: const Text('繁简转换'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      const {'none': '关闭', 't2s': '繁→简', 's2t': '简→繁'}[settings
                              .convertType] ??
                          '关闭',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right, size: 20),
                  ],
                ),
                onTap:
                    () => SettingsUIHelper.showSelectionSheet<String>(
                      context: context,
                      title: '繁简转换',
                      subtitle: '阅读时自动转换文字',
                      currentValue: settings.convertType,
                      options: const {'none': '关闭', 't2s': '繁→简', 's2t': '简→繁'},
                      icons: const {
                        'none': Icons.close,
                        't2s': Icons.arrow_circle_down_outlined,
                        's2t': Icons.arrow_circle_up_outlined,
                      },
                      onSelected: (value) => notifier.setConvertType(value),
                    ),
              ),

              // 显示章节序号
              SwitchListTile(
                secondary: const Icon(Icons.format_list_numbered),
                title: const Text('显示章节序号'),
                value: settings.showChapterNumber,
                onChanged: (value) => notifier.setShowChapterNumber(value),
              ),

              // 简化续读按钮的章节标题
              SwitchListTile(
                secondary: const Icon(Icons.auto_fix_high),
                title: const Text('简化章节标题'),
                subtitle: const Text('实验性功能，建议启用'),
                value: settings.cleanChapterTitle,
                onChanged: (value) => notifier.setCleanChapterTitle(value),
              ),
              const SizedBox(height: 32),
            ]),
          ),
        ],
      ),
    );
  }
}
