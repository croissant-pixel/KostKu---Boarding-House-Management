import 'package:flutter/material.dart';
import 'package:kostku/core/database/db_helper.dart';
import '../models/inspection_model.dart';

class InspectionProvider extends ChangeNotifier {
  bool isLoading = false;
  List<Inspection> inspections = [];

  Future<void> fetchInspections(int roomId) async {
    isLoading = true;
    notifyListeners();

    try {
      final maps = await DBHelper().getInspectionsByRoom(roomId);
      inspections = maps.map((e) => Inspection.fromMap(e)).toList();
    } catch (e) {
      print('Error fetch inspections: $e');
      inspections = [];
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> addInspection(Inspection inspection) async {
    await DBHelper().addInspection(
      inspection.roomId,
      inspection.conditionNotes,
      inspection.photoUrl,
    );
    await fetchInspections(inspection.roomId);
  }

  Future<void> deleteInspection(int id, int roomId) async {
    await DBHelper().deleteInspection(id);
    await fetchInspections(roomId);
  }
}
