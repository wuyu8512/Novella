import 'dart:async';
import 'dart:developer' as developer;
import 'package:dio/dio.dart';
import 'package:novella/core/network/api_client.dart';
import 'package:novella/core/network/signalr_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logging/logging.dart';

class AuthService {
  final ApiClient _apiClient = ApiClient();
  final SignalRService _signalRService = SignalRService();
  final Logger _logger = Logger('AuthService');

  AuthService() {
    // 注入令牌提供者，实现全局单例刷新
    SignalRService.tokenProvider = getValidSessionToken;
  }

  // 内存令牌缓存，避免冷启动及 SignalR 重复请求
  String? _sessionToken;
  DateTime? _lastRefreshTime;
  static const _tokenValidity = Duration(minutes: 5); // 5分钟内存有效期

  // 令牌刷新互斥锁
  Future<String?>? _refreshFuture;

  Future<bool> login(String username, String password) async {
    try {
      final response = await _apiClient.dio.post(
        '/api/user/login',
        data: {
          'email': username,
          'password': password,
          'token': '', // 验证码 token (Turnstile)
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        _logger.info('Login Response: $data');

        final accessToken = data['Token'];
        final refreshToken = data['RefreshToken'];

        if (accessToken != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('auth_token', accessToken);
          if (refreshToken != null) {
            await prefs.setString('refresh_token', refreshToken);
          }

          await _signalRService.init();
          return true;
        }
      }
      return false;
    } catch (e) {
      _logger.severe('Login Failed: $e');
      if (e is DioException) {
        _logger.severe('DioError: ${e.response?.data}');
      }
      return false;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('refresh_token');
  }

  /// 保存刷新令牌并自动获取会话令牌
  Future<void> saveTokens(String token, String refreshToken) async {
    final prefs = await SharedPreferences.getInstance();

    // 若有会话令牌直接保存
    if (token.isNotEmpty) {
      await prefs.setString('auth_token', token);
    }

    // 保存刷新令牌
    if (refreshToken.isNotEmpty) {
      await prefs.setString('refresh_token', refreshToken);

      // 若无会话令牌，尝试刷新获取
      if (token.isEmpty) {
        _logger.info('No session token, attempting to refresh...');
        final tokenCandidate = await _refreshSessionToken(refreshToken);
        if (tokenCandidate == null) {
          throw Exception('Failed to refresh session token');
        }
      }
    }

    _logger.info('Tokens saved. Initializing SignalR...');
    // 等待 SignalR 连接就绪（参考 getMyInfo 模式）
    try {
      await _signalRService.init();
      developer.log('SignalR initialized successfully', name: 'AUTH');
    } catch (e) {
      developer.log('SignalR init error: $e', name: 'AUTH');
      // 不抛出异常，允许用户重试
    }
  }

  /// 使用刷新令牌获取新会话令牌 (带并发锁)
  Future<String?> _refreshSessionToken(String refreshToken) async {
    // 如果已经有正在进行的刷新请求，直接等待它
    if (_refreshFuture != null) {
      _logger.info('Refresh already in progress, waiting...');
      return _refreshFuture;
    }

    // 检查缓存是否有效
    if (_sessionToken != null && _lastRefreshTime != null) {
      if (DateTime.now().difference(_lastRefreshTime!) < _tokenValidity) {
        return _sessionToken;
      }
    }

    final completer = Completer<String?>();
    _refreshFuture = completer.future;

    try {
      _logger.info('Performing network refresh for session token...');
      final response = await _apiClient.dio.post(
        '/api/user/refresh_token',
        data: {'token': refreshToken},
      );

      _logger.info('Refresh API response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        String? newToken;
        if (response.data is String) {
          newToken = response.data;
        } else if (response.data is Map) {
          if (response.data['Response'] != null) {
            newToken = response.data['Response'];
          } else if (response.data['Token'] != null) {
            newToken = response.data['Token'];
          }
        }

        if (newToken != null && newToken.isNotEmpty) {
          _sessionToken = newToken;
          _lastRefreshTime = DateTime.now();

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('auth_token', newToken);

          _logger.info('Session token refreshed successfully');
          completer.complete(newToken);
          return newToken;
        }
      }

      _logger.warning('Refresh token API returned unexpected response');
      completer.complete(null);
      return null;
    } on DioException catch (e) {
      _logger.severe('DioException in refresh: ${e.message}');
      completer.complete(null);
      return null;
    } catch (e) {
      _logger.severe('Failed to refresh session token: $e');
      completer.complete(null);
      return null;
    } finally {
      _refreshFuture = null;
    }
  }

  /// 获取有效的会话令牌 (供 SignalR 使用)
  Future<String> getValidSessionToken() async {
    // 1. 无需刷新直接返回
    if (_sessionToken != null && _lastRefreshTime != null) {
      if (DateTime.now().difference(_lastRefreshTime!) < _tokenValidity) {
        return _sessionToken!;
      }
    }

    // 2. 需要刷新或正在刷新
    final prefs = await SharedPreferences.getInstance();
    final refreshToken = prefs.getString('refresh_token');
    if (refreshToken == null || refreshToken.isEmpty) return '';

    return await _refreshSessionToken(refreshToken) ?? '';
  }

  /// 尝试使用存储的刷新令牌自动登录
  /// 会实际调用 API 验证 refresh token 是否有效
  Future<bool> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final refreshToken = prefs.getString('refresh_token');

    if (refreshToken == null || refreshToken.isEmpty) {
      _logger.info('No refresh token found');
      return false;
    }

    _logger.info('Found refresh token, attempting to refresh session...');

    // 尝试刷新 session token 来验证 refresh token 有效性
    final newToken = await _refreshSessionToken(refreshToken);
    if (newToken == null) {
      _logger.warning('Failed to refresh session token, token may be invalid');
      return false;
    }

    // 在后台启动 SignalR 初始化，不阻塞进入主页的过程
    // 具体的网络请求会通过 RequestQueue 自动等待连接就绪
    unawaited(
      _signalRService.init().catchError((e) {
        _logger.warning('Background SignalR init failed: $e');
      }),
    );

    _logger.info('Auto-login token validated, proceeding to main page');
    return true;
  }
}
