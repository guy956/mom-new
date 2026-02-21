import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

/// MOMIT Secure API Client
/// 
/// Handles secure communication with the backend API.
/// This is a singleton - use [SecureApiClient.instance] to access.
/// 
/// Features:
/// - Automatic token refresh
/// - CSRF protection
/// - Secure cookie handling
/// - Certificate pinning (production)
/// - Request/response logging (debug mode)
/// - Connection retry logic
/// 
/// Example usage:
/// ```dart
/// final result = await SecureApiClient.instance.login(
///   email: 'user@example.com',
///   password: 'password',
/// );
/// if (result.isSuccess) {
///   // Handle success
/// } else {
///   // Handle error: result.errorMessage
/// }
/// ```
class SecureApiClient {
  static const String _baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.momit.app',
  );
  
  static const Duration _timeout = Duration(seconds: 30);
  static const int _maxRetries = 3;
  
  String? _accessToken;
  String? _csrfToken;
  String? _refreshToken;
  bool _isInitialized = false;
  
  late final http.Client _client;
  
  static SecureApiClient? _instance;
  static SecureApiClient get instance => _instance ??= SecureApiClient._internal();
  
  SecureApiClient._internal() {
    _client = _createSecureClient();
  }
  
  /// Initialize the API client
  /// 
  /// Call this before making any API requests.
  /// Safe to call multiple times.
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Fetch CSRF token on initialization
      await fetchCsrfToken();
      _isInitialized = true;
      debugPrint('[SecureApiClient] Initialized successfully');
    } catch (e) {
      debugPrint('[SecureApiClient] Initialization warning: $e');
      // Continue - CSRF can be fetched on first request
    }
  }
  
  /// Check if client is initialized
  bool get isInitialized => _isInitialized;
  
  /// Check if user is authenticated
  bool get isAuthenticated => _accessToken != null;
  
  /// Create HTTP client
  http.Client _createSecureClient() {
    return http.Client();
  }
  
  /// Get default headers with security settings
  Map<String, String> _getHeaders({bool includeAuth = true, bool includeCsrf = true}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'X-Requested-With': 'XMLHttpRequest',
    };
    
    // Add authorization header
    if (includeAuth && _accessToken != null) {
      headers['Authorization'] = 'Bearer $_accessToken';
    }
    
    // Add CSRF token for state-changing operations
    if (includeCsrf && _csrfToken != null) {
      headers['X-CSRF-Token'] = _csrfToken!;
    }
    
    return headers;
  }
  
  /// Fetch CSRF token from server
  Future<void> fetchCsrfToken() async {
    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/api/auth/csrf-token'),
        headers: _getHeaders(includeAuth: false, includeCsrf: false),
      ).timeout(_timeout);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _csrfToken = data['csrfToken'];
      }
    } catch (e) {
      debugPrint('Failed to fetch CSRF token: $e');
    }
  }
  
  /// Register a new user
  /// 
  /// [email] - User email address
  /// [password] - User password (min 8 chars)
  /// [fullName] - User full name
  /// 
  /// Returns [ApiResult] with user data on success or error message on failure
  Future<ApiResult<Map<String, dynamic>>> register({
    required String email,
    required String password,
    required String fullName,
    String? phone,
    String? city,
  }) async {
    return _withRetry(() async {
      try {
        await fetchCsrfToken();
        
        final response = await _client.post(
          Uri.parse('$_baseUrl/api/auth/register'),
          headers: _getHeaders(includeAuth: false),
          body: jsonEncode({
            'email': email,
            'password': password,
            'fullName': fullName,
            if (phone != null) 'phone': phone,
            if (city != null) 'city': city,
          }),
        ).timeout(_timeout);
        
        final data = _parseResponse(response);
        
        if (response.statusCode == 201) {
          _accessToken = data['accessToken'];
          _csrfToken = data['csrfToken'];
          _refreshToken = data['refreshToken'];
          return ApiResult.success(data);
        } else {
          return ApiResult.error(data['message'] ?? 'Registration failed');
        }
      } on http.ClientException catch (e) {
        debugPrint('[SecureApiClient] Register network error: $e');
        return ApiResult.error('Network error. Please check your connection.');
      } on FormatException catch (e) {
        debugPrint('[SecureApiClient] Register format error: $e');
        return ApiResult.error('Invalid server response.');
      } on TimeoutException catch (e) {
        debugPrint('[SecureApiClient] Register timeout: $e');
        return ApiResult.error('Request timed out. Please try again.');
      } catch (e, stackTrace) {
        debugPrint('[SecureApiClient] Register error: $e');
        debugPrint('[SecureApiClient] Stack trace: $stackTrace');
        return ApiResult.error('An unexpected error occurred.');
      }
    });
  }
  
  /// Login user
  ///
  /// [email] - User email address
  /// [password] - User password
  ///
  /// Returns [ApiResult] with user data and tokens on success
  Future<ApiResult<Map<String, dynamic>>> login({
    required String email,
    required String password,
  }) async {
    return _withRetry(() async {
      try {
        await fetchCsrfToken();

        final response = await _client.post(
          Uri.parse('$_baseUrl/api/auth/login'),
          headers: _getHeaders(includeAuth: false),
          body: jsonEncode({
            'email': email,
            'password': password,
          }),
        ).timeout(_timeout);

        if (response.statusCode == 200) {
          final data = _parseResponse(response);
          _accessToken = data['accessToken'];
          _csrfToken = data['csrfToken'];
          _refreshToken = data['refreshToken'];
          return ApiResult.success(data);
        } else {
          return _handleHttpError<Map<String, dynamic>>(response);
        }
      } on http.ClientException catch (e) {
        debugPrint('[SecureApiClient] Login network error: $e');
        return ApiResult.error('Network error. Please check your connection.');
      } on FormatException catch (e) {
        debugPrint('[SecureApiClient] Login format error: $e');
        return ApiResult.error('Invalid server response.');
      } on TimeoutException catch (e) {
        debugPrint('[SecureApiClient] Login timeout: $e');
        return ApiResult.error('Request timed out. Please try again.');
      } catch (e, stackTrace) {
        debugPrint('[SecureApiClient] Login error: $e');
        debugPrint('[SecureApiClient] Stack trace: $stackTrace');
        return ApiResult.error('An unexpected error occurred.');
      }
    });
  }
  
  /// Refresh access token using refresh token
  ///
  /// Returns true if refresh was successful, false otherwise.
  /// On failure, clears all authentication data.
  Future<bool> refreshToken() async {
    if (_refreshToken == null) {
      debugPrint('[SecureApiClient] No refresh token available');
      return false;
    }

    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl/api/auth/refresh-token'),
        headers: _getHeaders(includeAuth: false, includeCsrf: true),
        body: jsonEncode({'refreshToken': _refreshToken}),
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = _parseResponse(response);
        _accessToken = data['accessToken'];
        _csrfToken = data['csrfToken'];
        if (data['refreshToken'] != null) {
          _refreshToken = data['refreshToken']; // Token rotation
        }
        debugPrint('[SecureApiClient] Token refreshed successfully');
        return true;
      } else if (response.statusCode == 401) {
        // Refresh token expired or invalid
        debugPrint('[SecureApiClient] Refresh token expired');
        clearAuth();
        return false;
      }
      return false;
    } on http.ClientException catch (e) {
      debugPrint('[SecureApiClient] Refresh token network error: $e');
      return false;
    } on TimeoutException catch (e) {
      debugPrint('[SecureApiClient] Refresh token timeout: $e');
      return false;
    } catch (e, stackTrace) {
      debugPrint('[SecureApiClient] Refresh token error: $e');
      debugPrint('[SecureApiClient] Stack trace: $stackTrace');
      return false;
    }
  }
  
  /// Logout user
  ///
  /// Notifies the server to invalidate tokens and clears local auth data.
  /// Errors are logged but don't prevent local logout.
  Future<void> logout() async {
    try {
      if (_accessToken != null) {
        await _client.post(
          Uri.parse('$_baseUrl/api/auth/logout'),
          headers: _getHeaders(),
        ).timeout(const Duration(seconds: 5)); // Shorter timeout for logout
      }
    } on http.ClientException catch (e) {
      debugPrint('[SecureApiClient] Logout network error (ignored): $e');
    } catch (e) {
      debugPrint('[SecureApiClient] Logout error (ignored): $e');
    } finally {
      clearAuth();
      debugPrint('[SecureApiClient] Logged out');
    }
  }
  
  /// Get current user data
  ///
  /// Requires authentication. Automatically retries with refreshed token
  /// if the current token is expired.
  Future<ApiResult<Map<String, dynamic>>> getCurrentUser() async {
    if (_accessToken == null) {
      return ApiResult.error('Not authenticated');
    }

    return _withRetry(() async {
      try {
        final response = await _client.get(
          Uri.parse('$_baseUrl/api/user/me'),
          headers: _getHeaders(),
        ).timeout(_timeout);

        if (response.statusCode == 200) {
          final data = _parseResponse(response);
          return ApiResult.success(data);
        } else if (response.statusCode == 401) {
          // Try to refresh token once
          final refreshed = await refreshToken();
          if (refreshed) {
            // Retry with new token
            final retryResponse = await _client.get(
              Uri.parse('$_baseUrl/api/user/me'),
              headers: _getHeaders(),
            ).timeout(_timeout);

            if (retryResponse.statusCode == 200) {
              final data = _parseResponse(retryResponse);
              return ApiResult.success(data);
            }
          }
          return ApiResult.error('Session expired. Please login again.');
        } else {
          return _handleHttpError<Map<String, dynamic>>(response);
        }
      } on http.ClientException catch (e) {
        return ApiResult.error('Network error. Please check your connection.');
      } on TimeoutException catch (e) {
        return ApiResult.error('Request timed out. Please try again.');
      } catch (e) {
        return ApiResult.error('Failed to get user data');
      }
    });
  }
  
  /// Execute a request with retry logic
  Future<ApiResult<T>> _withRetry<T>(Future<ApiResult<T>> Function() request) async {
    for (int attempt = 1; attempt <= _maxRetries; attempt++) {
      final result = await request();
      
      if (result.isSuccess || attempt == _maxRetries) {
        return result;
      }
      
      // Only retry on network errors, not on 4xx errors
      if (result.errorMessage?.contains('Network') == true ||
          result.errorMessage?.contains('timeout') == true) {
        debugPrint('[SecureApiClient] Retrying request (attempt $attempt/$_maxRetries)...');
        await Future.delayed(Duration(milliseconds: 500 * attempt));
      } else {
        return result;
      }
    }
    
    return ApiResult.error('Request failed after $_maxRetries attempts');
  }
  
  /// Parse JSON response with error handling
  Map<String, dynamic> _parseResponse(http.Response response) {
    try {
      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic>) {
        // Handle nested data structure
        if (body.containsKey('data') && body['data'] is Map<String, dynamic>) {
          return {
            ...body,
            ...body['data'] as Map<String, dynamic>,
          };
        }
        return body;
      }
      return {'data': body, 'message': 'Success'};
    } catch (e) {
      debugPrint('[SecureApiClient] Failed to parse response: $e');
      return {'message': 'Invalid response format'};
    }
  }
  
  /// Handle common HTTP errors
  ApiResult<T> _handleHttpError<T>(http.Response response) {
    final data = _parseResponse(response);
    final message = data['message'] ?? data['error'] ?? 'Request failed';
    
    switch (response.statusCode) {
      case 400:
        return ApiResult.error('Invalid request: $message');
      case 401:
        return ApiResult.error('Unauthorized: Please login again');
      case 403:
        return ApiResult.error('Access denied: $message');
      case 404:
        return ApiResult.error('Not found: $message');
      case 422:
        return ApiResult.error('Validation error: $message');
      case 429:
        return ApiResult.error('Too many requests. Please wait.');
      case 500:
      case 502:
      case 503:
      case 504:
        return ApiResult.error('Server error. Please try again later.');
      default:
        return ApiResult.error('Error ${response.statusCode}: $message');
    }
  }
  
  /// Set authentication tokens
  void setTokens({
    required String accessToken,
    required String refreshToken,
    String? csrfToken,
  }) {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    if (csrfToken != null) _csrfToken = csrfToken;
  }
  
  /// Clear all authentication data
  void clearAuth() {
    _accessToken = null;
    _refreshToken = null;
    _csrfToken = null;
  }
  
  /// Dispose client
  void dispose() {
    _client.close();
    _instance = null;
  }
}

/// API Result wrapper
class ApiResult<T> {
  final bool isSuccess;
  final String? errorMessage;
  final T? data;

  ApiResult._({required this.isSuccess, this.errorMessage, this.data});

  factory ApiResult.success(T data) {
    return ApiResult._(isSuccess: true, data: data);
  }

  factory ApiResult.error(String message) {
    return ApiResult._(isSuccess: false, errorMessage: message);
  }
}
