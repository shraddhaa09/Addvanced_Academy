import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart'; // ✅ Added

import '../services/auth_service.dart';

enum AppUserRole {
  admin,
  faculty,
  student,
  unknown,
}

class AuthStateModel {
  const AuthStateModel({
    required this.isLoading,
    required this.isAuthenticated,
    required this.userId,
    required this.email,
    required this.role,
    this.errorMessage,
  });

  final bool isLoading;
  final bool isAuthenticated;
  final String? userId;
  final String? email;
  final AppUserRole role;
  final String? errorMessage;

  AuthStateModel copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    String? userId,
    String? email,
    AppUserRole? role,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AuthStateModel(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      userId: userId ?? this.userId,
      email: email ?? this.email,
      role: role ?? this.role,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  factory AuthStateModel.initial() {
    return const AuthStateModel(
      isLoading: false,
      isAuthenticated: false,
      userId: null,
      email: null,
      role: AppUserRole.unknown,
      errorMessage: null,
    );
  }
}

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(Supabase.instance.client);
});

final authProvider =
StateNotifierProvider<AuthNotifier, AuthStateModel>((ref) {
  return AuthNotifier(ref.read(authServiceProvider));
});

class AuthNotifier extends StateNotifier<AuthStateModel> {
  AuthNotifier(this._authService) : super(AuthStateModel.initial()) {
    _bootstrap();
  }

  final AuthService _authService;
  StreamSubscription<AuthState>? _authSubscription;

  void _bootstrap() {
    final user = _authService.currentUser;

    if (user != null) {
      _updateUserAndCrashlytics(user);
    }

    _authSubscription = _authService.authStateChanges.listen((authState) {
      final user = authState.session?.user;

      if (user == null) {
        // ✅ Handle logout reactively
        _safeUpdateCrashlytics(null);
        state = AuthStateModel.initial();
        return;
      }

      _updateUserAndCrashlytics(user);
    });
  }

  void _safeUpdateCrashlytics(String? userId) {
    try {
      FirebaseCrashlytics.instance.setUserIdentifier(userId ?? '');
    } catch (e) {
      debugPrint('Crashlytics error: $e');
    }
  }

  void _updateUserAndCrashlytics(User user) {
    _safeUpdateCrashlytics(user.id);
    state = AuthStateModel(
      isLoading: false,
      isAuthenticated: true,
      userId: user.id,
      email: user.email,
      role: _resolveTemporaryRole(user.email),
      errorMessage: null,
    );
  }

  AppUserRole _resolveTemporaryRole(String? email) {
    if (email == null) return AppUserRole.unknown;

    final normalizedEmail = email.toLowerCase();

    if (normalizedEmail.contains('admin')) return AppUserRole.admin;
    if (normalizedEmail.contains('faculty')) return AppUserRole.faculty;
    return AppUserRole.student;
  }

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
    );

    try {
      await _authService.signIn(
        email: email.trim(),
        password: password.trim(),
      );
      return true;
    } on AuthException catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: error.message,
      );
      return false;
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Something went wrong. Please try again.',
      );
      return false;
    }
  }

  Future<bool> signOut() async {
    if (state.isLoading) return false;

    state = state.copyWith(isLoading: true);

    try {
      _safeUpdateCrashlytics(null);
      await _authService.signOut();
      // Note: state is reset reactively by the stream listener in _bootstrap
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Logout failed. Please try again.',
      );
      return false;
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
