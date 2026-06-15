import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_user.dart';
import '../services/auth_repository.dart';
import 'supabase_providers.dart';

enum AuthStatus { loading, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final AppUser? user;
  final String? errorMessage;

  const AuthState({required this.status, this.user, this.errorMessage});

  bool get isAuthenticated => status == AuthStatus.authenticated;

  AuthState copyWith({AuthStatus? status, AppUser? user, String? errorMessage}) =>
      AuthState(
        status: status ?? this.status,
        user: user ?? this.user,
        errorMessage: errorMessage,
      );
}

class AuthNotifier extends Notifier<AuthState> {
  AuthRepository get _repo => ref.read(authRepositoryProvider);

  @override
  AuthState build() {
    // Restore session on cold start
    _restoreSession();
    return const AuthState(status: AuthStatus.loading);
  }

  Future<void> _restoreSession() async {
    try {
      // Add timeout to prevent infinite loading if Supabase is not configured
      final user = await _repo.getCurrentUser().timeout(
        const Duration(seconds: 5),
        onTimeout: () => null,
      );
      state = user != null
          ? AuthState(status: AuthStatus.authenticated, user: user)
          : const AuthState(status: AuthStatus.unauthenticated);
    } catch (_) {
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  Future<bool> signIn(String email, String password) async {
    state = const AuthState(status: AuthStatus.loading);
    try {
      final user = await _repo.signIn(email, password);
      state = AuthState(status: AuthStatus.authenticated, user: user);
      return true;
    } catch (e) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: _parseError(e),
      );
      return false;
    }
  }

  Future<bool> signUp(String name, String email, String password) async {
    state = const AuthState(status: AuthStatus.loading);
    try {
      final user = await _repo.signUp(name, email, password);
      state = AuthState(status: AuthStatus.authenticated, user: user);
      return true;
    } catch (e) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: _parseError(e),
      );
      return false;
    }
  }

  Future<void> signOut() async {
    await _repo.signOut();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  Future<bool> resetPassword(String email) async {
    try {
      await _repo.resetPassword(email);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> updateUser(AppUser updated) async {
    try {
      await _repo.updateProfile(updated);
      state = state.copyWith(user: updated);
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  String _parseError(Object e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('invalid login') ||
        msg.contains('invalid credentials') ||
        msg.contains('invalid_credentials') ||
        msg.contains('bad request') ||
        msg.contains('400')) {
      return 'Invalid email or password.';
    }
    if (msg.contains('already registered') || msg.contains('user already')) {
      return 'This email is already registered.';
    }
    if (msg.contains('network') || msg.contains('failed to fetch')) {
      return 'Network error. Please check your connection.';
    }
    if (msg.contains('email not confirmed') || msg.contains('confirmation')) {
      return 'Please confirm your email address first.';
    }
    return 'Sign in failed. Please try again.';
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);
