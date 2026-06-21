import 'package:flutter/material.dart';
import 'package:ksl/controller/authController.dart';
import 'package:ksl/model/user.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? currentUser;
  bool isLoading = false;
  String? errorMessage;

  Future<void> loadSavedUser() async {
    currentUser = await AuthController.getSavedUser();
    notifyListeners();
  }

  Future<Map<String, dynamic>> login(String username, String password) async {
    isLoading = true;
    notifyListeners();

    final result = await AuthController.login(username, password);
    if (result['success'] == true) {
      currentUser = result['user'];
      errorMessage = null;
    } else {
      errorMessage = result['message'];
    }
    isLoading = false;
    notifyListeners();
    return result;
  }

  Future<Map<String, dynamic>> register({
    required String username,
    required String fullname,
    required String email,
    required String password,
    String? phone,
    String? gender,
    String? birthday,
    String? address,
  }) async {
    isLoading = true;
    notifyListeners();

    final result = await AuthController.register(
      username: username,
      fullname: fullname,
      email: email,
      password: password,
      phone: phone,
      gender: gender,
      birthday: birthday,
      address: address,
    );
    isLoading = false;
    notifyListeners();
    return result;
  }

  Future<Map<String, dynamic>> getProfile() async {
    final result = await AuthController.getProfile();
    if (result['success'] == true) {
      currentUser = result['user'];
      notifyListeners();
    }
    return result;
  }

  Future<Map<String, dynamic>> updateProfile({
    required String fullname,
    String? phone,
    String? gender,
    String? birthday,
    String? address,
    String? avatar,
  }) async {
    final result = await AuthController.updateProfile(
      fullname: fullname,
      phone: phone,
      gender: gender,
      birthday: birthday,
      address: address,
      avatar: avatar,
    );
    if (result['success'] == true) {
      currentUser = result['user'];
      notifyListeners();
    }
    return result;
  }

  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String username,
    required String email,
    required String newPassword,
  }) {
    return AuthController.changePassword(
      currentPassword: currentPassword,
      username: username,
      email: email,
      newPassword: newPassword,
    );
  }

  Future<void> logout() async {
    await AuthController.logout();
    currentUser = null;
    notifyListeners();
  }
}
