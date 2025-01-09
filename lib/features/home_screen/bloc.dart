import 'dart:developer';

import 'package:ardennes/models/projects/project_metadata.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:ardennes/models/screens/home_screen_data.dart';
import 'event.dart';
import 'state.dart';

class HomeScreenBloc extends Bloc<HomeScreenEvent, HomeScreenState> {
  ProjectMetadata? _currentSelectedProject;

  HomeScreenBloc() : super(HomeScreenState().init()) {
    on<InitEvent>(_handleInit);
    on<FetchHomeScreenContentEvent>(_handleFetchHomeScreenContent);
    on<RecentlyViewedSheetsEvent>(_handleRecentlyViewedSheets);
  }

  void _handleInit(InitEvent event, Emitter<HomeScreenState> emit) {
    emit(state.clone());
  }

  Future<HomeScreenData?> _fetchHomeScreenData({
    required String userId,
    required String projectId,
  }) async {
    try {
      final query = FirebaseFirestore.instance
          .collection('home_screens')
          .where('user_id', isEqualTo: userId)
          .where('project_id', isEqualTo: projectId)
          .withConverter(
            fromFirestore: HomeScreenData.fromFirestore,
            toFirestore: HomeScreenData.toFirestore,
          );

      final querySnapshot = await query.get();
      return querySnapshot.docs.firstOrNull?.data();
    } catch (e, stackTrace) {
      _logError("Error fetching home screen data", e, stackTrace);
      return null;
    }
  }

  Future<void> _handleFetchHomeScreenContent(
      FetchHomeScreenContentEvent event, Emitter<HomeScreenState> emit) async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (_currentSelectedProject == event.selectedProject) return;

    if (currentUser == null) {
      _emitErrorState("User not authenticated", emit);
      return;
    }

    emit(FetchingHomeScreenContentState());

    try {
      final userId = currentUser.uid;
      final homeScreenData = await _fetchHomeScreenData(
        userId: userId,
        projectId: event.selectedProject.id.toString(),
      );

      if (homeScreenData != null) {
        _currentSelectedProject = event.selectedProject;
        emit(FetchedHomeScreenContentState(
          recentlyViewedDrawingTiles: homeScreenData.drawings ?? [],
        ));
      } else {
        _emitErrorState("No data found for the selected project", emit);
      }
    } catch (e, stackTrace) {
      _logError("Error fetching home screen content", e, stackTrace);
      _emitErrorState("An error occurred while fetching content", emit);
    }
  }

  Future<void> _handleRecentlyViewedSheets(
      RecentlyViewedSheetsEvent event, Emitter<HomeScreenState> emit) async {
    try {
      final homeScreenCollection =
          FirebaseFirestore.instance.collection('home_screens');

      final querySnapshot = await homeScreenCollection
          .where("project_id", isEqualTo: event.projectId)
          .where("user_id", isEqualTo: event.userId)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final existingDoc = querySnapshot.docs.first.reference;
        await existingDoc.update({
          "drawings": FieldValue.arrayUnion(event.drawingsList),
        });
        log("Updated document: ${existingDoc.id}");
      } else {
        final newDocData = {
          "project_id": event.projectId,
          "user_id": event.userId,
          "drawings": event.drawingsList,
        };
        final newDoc = await homeScreenCollection.add(newDocData);
        log("Created new document: ${newDoc.id}");
      }

      await _refreshHomeScreenData(event, emit);
    } catch (e, stackTrace) {
      _logError("Error updating recently viewed sheets", e, stackTrace);
      _emitErrorState("Error updating recently viewed sheets", emit);
    }
  }

  Future<void> _refreshHomeScreenData(
      RecentlyViewedSheetsEvent event, Emitter<HomeScreenState> emit) async {
    final homeScreenData = await _fetchHomeScreenData(
      userId: event.userId,
      projectId: event.projectId,
    );

    if (homeScreenData != null) {
      log("Drawings length: ${homeScreenData.drawings?.length ?? 0}");
      emit(FetchedHomeScreenContentState(
        recentlyViewedDrawingTiles: homeScreenData.drawings ?? [],
      ));
    } else {
      _emitErrorState("No data found for the selected project", emit);
    }
  }

  void _emitErrorState(String message, Emitter<HomeScreenState> emit) {
    emit(HomeScreenFetchErrorState(message));
  }

  void _logError(String message, dynamic error, StackTrace stackTrace) {
    log("$message: $error", error: error, stackTrace: stackTrace);
  }
}
