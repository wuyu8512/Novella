import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:novella/core/auth/auth_service.dart';
import 'package:novella/core/sync/gist_sync_service.dart';
import 'package:novella/core/sync/sync_crypto.dart';
import 'package:novella/core/sync/sync_manager.dart';
import 'package:novella/features/auth/login_browser_page.dart';
import 'package:novella/features/main_page.dart';
import 'package:url_launcher/url_launcher.dart';

/// MD3 风格登录/引导页
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final AuthService _authService = AuthService();
  bool _checkingLogin = true;

  @override
  void initState() {
    super.initState();
    _checkAutoLogin();
  }

  Future<void> _checkAutoLogin() async {
    final isLoggedIn = await _authService.tryAutoLogin();
    if (mounted) {
      if (isLoggedIn) {
        // 自动登录成功
        Navigator.of(
          context,
        ).pushReplacement(MaterialPageRoute(builder: (_) => const MainPage()));
      } else {
        // 显示登录页
        setState(() {
          _checkingLogin = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingLogin) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primaryContainer,
              colorScheme.surface,
              colorScheme.secondaryContainer.withAlpha(77),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              children: [
                const Spacer(flex: 2),
                // 应用图标
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.primary.withAlpha(77),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.auto_stories_rounded,
                    size: 64,
                    color: colorScheme.onPrimary,
                  ),
                ),
                const SizedBox(height: 32),
                // 标题
                Text(
                  'Novella',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                // 副标题
                Text(
                  '轻书架第三方客户端',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(flex: 1),
                // 信息卡片
                Card(
                  elevation: 0,
                  color: colorScheme.surfaceContainerHighest.withAlpha(128),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        Icon(
                          Icons.login_rounded,
                          size: 40,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '网页登录',
                          style: Theme.of(
                            context,
                          ).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '通过浏览器完成验证',
                          textAlign: TextAlign.center,
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(flex: 2),
                // 登录按钮
                FilledButton.icon(
                  onPressed: () => _startLogin(context),
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: const Text('开始登录'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // 从 GitHub 还原按钮
                OutlinedButton.icon(
                  onPressed: () => _startGitHubRestore(context),
                  icon: const Icon(Icons.cloud_download_outlined),
                  label: const Text('从 GitHub 还原'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // 跳过提示
                TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('需登录后使用，否则无法阅读书籍'),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                  },
                  child: Text(
                    '为什么需要登录？',
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _startLogin(BuildContext context) async {
    final result = await Navigator.of(context).push<Map<String, String>>(
      MaterialPageRoute(builder: (_) => const LoginBrowserPage()),
    );

    if (result != null && context.mounted) {
      // 登录成功，跳转主页
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const MainPage()));
    }
  }

  Future<void> _startGitHubRestore(BuildContext context) async {
    final syncManager = SyncManager();

    try {
      // 1. 开始 Device Flow 获取验证码
      final flowData = await syncManager.startDeviceFlow();

      if (!context.mounted) return;

      // 2. 显示验证码对话框并等待用户授权
      final authorized = await _showDeviceCodeDialog(
        context,
        syncManager,
        flowData,
      );

      if (!authorized || !context.mounted) {
        return;
      }

      // 3. 输入同步密码
      final password = await _showPasswordInputDialog(context);
      if (password == null || !context.mounted) {
        return;
      }

      // 4. 尝试从 Gist 恢复数据
      final restored = await syncManager.restoreFromGist(password);

      if (!context.mounted) return;

      if (restored) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('数据还原成功！')));

        // 5. 检查是否已有登录凭据，尝试自动登录
        final isLoggedIn = await _authService.tryAutoLogin();
        if (isLoggedIn && context.mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const MainPage()),
          );
        } else if (context.mounted) {
          // 还原成功但没有有效登录凭据，提示需要登录
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('请继续登录以完成设置')));
        }
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('未找到同步数据')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('恢复失败: $e')));
      }
    }
  }

  Future<bool> _showDeviceCodeDialog(
    BuildContext context,
    SyncManager syncManager,
    DeviceFlowResponse flowData,
  ) async {
    bool success = false;
    int remainingSeconds = flowData.expiresIn;

    // 使用 ValueNotifier 控制对话框状态
    final dialogClosed = ValueNotifier<bool>(false);
    NavigatorState? navigator;

    // 在对话框显示后启动轮询
    Future<void> startPolling(StateSetter setDialogState) async {
      try {
        final result = await syncManager.completeDeviceFlow(
          flowData,
          onTick: (remaining) {
            if (!dialogClosed.value) {
              setDialogState(() => remainingSeconds = remaining);
            }
          },
        );
        success = result;
      } catch (e) {
        success = false;
      } finally {
        if (!dialogClosed.value && navigator?.mounted == true) {
          navigator?.pop();
        }
      }
    }

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        // 保存 navigator 引用
        navigator = Navigator.of(dialogContext);
        bool pollStarted = false;
        Timer? uiTimer; // UI 倒计时定时器

        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            // 确保只启动一次轮询
            if (!pollStarted) {
              pollStarted = true;

              // 1. 启动 API 轮询 (不负责 UI 倒计时)
              Future.microtask(
                () => startPolling(setDialogState),
              ); // 传递 setDialogState 但不再依赖 onTick 更新 UI

              // 2. 启动本地 1秒 UI 倒计时
              uiTimer = Timer.periodic(const Duration(seconds: 1), (t) {
                if (!dialogClosed.value) {
                  setDialogState(() {
                    if (remainingSeconds > 0) {
                      remainingSeconds--;
                    } else {
                      uiTimer?.cancel();
                    }
                  });
                }
              });
            }

            // 监听对话框关闭以取消定时器 (由于 showDialog builder 无法直接获得 dispose 回调，
            // 但我们的逻辑主要由 dialogClosed 和外部控制，且 startPolling 的 finally 会负责 pop)
            // 更安全的做法：在 actions 的取消按钮中取消 timer

            return AlertDialog(
              title: const Text('连接 GitHub'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('请在浏览器中访问：'),
                  const SizedBox(height: 8),
                  SelectableText(
                    flowData.verificationUri,
                    style: TextStyle(
                      color: Theme.of(ctx).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('然后输入验证码：'),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        flowData.userCode,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy, size: 20),
                        onPressed: () {
                          Clipboard.setData(
                            ClipboardData(text: flowData.userCode),
                          );
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(content: Text('已复制验证码')),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '剩余时间: ${remainingSeconds ~/ 60}:${(remainingSeconds % 60).toString().padLeft(2, '0')}',
                    style: TextStyle(
                      color:
                          remainingSeconds < 60
                              ? Theme.of(ctx).colorScheme.error
                              : null,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    launchUrl(Uri.parse(flowData.verificationUri));
                  },
                  child: const Text('打开浏览器'),
                ),
                TextButton(
                  onPressed: () {
                    uiTimer?.cancel();
                    dialogClosed.value = true;
                    navigator?.pop();
                  },
                  child: const Text('取消'),
                ),
              ],
            );
          },
        );
      },
    );

    dialogClosed.value = true;
    return success;
  }

  Future<String?> _showPasswordInputDialog(BuildContext context) async {
    final controller = TextEditingController();
    String? errorText;

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('输入同步密码'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('请输入之前设置的同步密码以解密数据：'),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: '同步密码',
                      errorText: errorText,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(null),
                  child: const Text('取消'),
                ),
                FilledButton(
                  onPressed: () {
                    final password = controller.text;
                    if (!SyncCrypto.isValidPassword(password)) {
                      setState(() {
                        errorText = '密码格式不正确';
                      });
                      return;
                    }
                    Navigator.of(dialogContext).pop(password);
                  },
                  child: const Text('确定'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
