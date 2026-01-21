import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:novella/features/settings/settings_provider.dart';
import 'package:novella/features/settings/widgets/settings_ui_helper.dart';
import 'package:novella/features/settings/theme_selection_page.dart';

import 'package:novella/features/settings/widgets/settings_header_card.dart';

class AppearanceSettingsPage extends ConsumerWidget {
  const AppearanceSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const SliverAppBar(),
          const SliverToBoxAdapter(
            child: SettingsHeaderCard(
              icon: Icons.palette,
              title: '外观设置',
              subtitle: '管理主题颜色、深浅色模式与界面样式',
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              // 主题与颜色
              ListTile(
                leading: const Icon(Icons.palette_outlined),
                title: const Text('主题与颜色'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        // 使用当前主题的 primary 色（已考虑系统颜色）
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.chevron_right, size: 20),
                  ],
                ),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const ThemeSelectionPage(),
                    ),
                  );
                },
              ),

              // 封面取色
              SwitchListTile(
                secondary: const Icon(Icons.colorize),
                title: const Text('封面取色'),
                subtitle: const Text('从封面提取颜色作为详情页主题'),
                value: settings.coverColorExtraction,
                onChanged: (value) => notifier.setCoverColorExtraction(value),
              ),

              // OLED 纯黑模式
              SwitchListTile(
                secondary: const Icon(Icons.contrast),
                title: const Text('纯黑模式'),
                subtitle: Text(
                  settings.coverColorExtraction ? '需关闭封面取色' : '更深邃的黑色背景',
                ),
                value: settings.oledBlack,
                onChanged:
                    // 仅在深色模式且未开启封面取色时可用
                    (colorScheme.brightness == Brightness.dark &&
                            !settings.coverColorExtraction)
                        ? (value) => notifier.setOledBlack(value)
                        : null,
              ),

              // iOS 显示样式（仅 iOS 平台显示）
              if (Platform.isIOS)
                ListTile(
                  leading: const Icon(Icons.phone_iphone),
                  title: const Text('iOS 显示样式'),
                  subtitle: const Text('实验性功能'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        const {
                              'md3': 'Material',
                              'ios18': 'iOS 18',
                              'ios26': 'iOS 26',
                            }[settings.iosDisplayStyle] ??
                            'Material',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.chevron_right, size: 20),
                    ],
                  ),
                  onTap: () {
                    final options = {
                      'md3': 'Material Design 3',
                      'ios18': 'iOS 18',
                    };
                    final icons = {'md3': Icons.android, 'ios18': Icons.apple};

                    if (PlatformInfo.isNativeIOS26OrHigher()) {
                      options['ios26'] = 'iOS 26';
                      icons['ios26'] = Icons.blur_on;
                    }

                    SettingsUIHelper.showSelectionSheet<String>(
                      context: context,
                      title: 'iOS 显示样式',
                      subtitle: '选择界面控件风格（实验性功能）',
                      currentValue: settings.iosDisplayStyle,
                      options: options,
                      icons: icons,
                      onSelected: (value) => notifier.setIosDisplayStyle(value),
                    );
                  },
                ),
              const SizedBox(height: 32),
            ]),
          ),
        ],
      ),
    );
  }
}
