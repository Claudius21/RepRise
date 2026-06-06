import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_user.dart';
import '../services/mock_data.dart';

enum AuthStatus { loading, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final AppUser? user;

  const AuthState({required this.status, this.user});

  bool get isAuthenticated => status == AuthStatus.authenticated;

  AuthState copyWith({AuthStatus? status, AppUser? user}) => AuthState(
        status: status ?? this.status,
        user: user ?? this.user,
      );
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthState(status: AuthStatus.unauthenticated);

  Future<bool> signIn(String email, String password) async {
    state = const AuthState(status: AuthStatus.loading);
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));
    // Mock: any credentials work
    state = AuthState(
      status: AuthStatus.authenticated,
      user: MockData.currentUser,
    );
    return true;
  }

  Future<bool> signUp(String name, String email, String password) async {
    state = const AuthState(status: AuthStatus.loading);
    await Future.delayed(const Duration(milliseconds: 1000));
    state = AuthState(
      status: AuthStatus.authenticated,
      user: MockData.currentUser.copyWith(name: name, email: email),
    );
    return true;
  }

  void signOut() {
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  void updateUser(AppUser updated) {
    state = state.copyWith(user: updated);
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);
