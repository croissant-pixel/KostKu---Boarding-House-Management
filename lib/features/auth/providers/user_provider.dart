import 'package:flutter/material.dart';
import '../../../core/database/db_helper.dart';
import '../models/user_model.dart';

class UserProvider with ChangeNotifier {
  User? _currentUser;

  User? get currentUser => _currentUser;

  bool get isLoggedIn => _currentUser != null;

  final DBHelper _dbHelper = DBHelper();

  Future<bool> login(String username, String password) async {
    final user = await _dbHelper.getUserByUsername(username);
    if (user != null && user.password == password) {
      _currentUser = user;
      notifyListeners();
      return true;
    }
    return false;
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }

  Future<void> register(User user) async {
    await _dbHelper.insertUser(user);
  }
}
