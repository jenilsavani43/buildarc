import 'package:ardennes/models/projects/project_metadata.dart';
import 'package:flutter/cupertino.dart';

sealed class HomeScreenEvent {}

class InitEvent extends HomeScreenEvent {}

class FetchHomeScreenContentEvent extends HomeScreenEvent {
  final ProjectMetadata selectedProject;

  FetchHomeScreenContentEvent(this.selectedProject);
}

class RecentlyViewedSheetsEvent extends HomeScreenEvent {
  final String projectId;
  final String userId;
  final String title;
  final String drawingThumbnailUrl;
  final List<Map<String, dynamic>> drawingsList;
  final BuildContext? context;

  RecentlyViewedSheetsEvent({
    required this.projectId,
    required this.userId,
    this.context,
    required this.title,
    required this.drawingThumbnailUrl,
    required List<DrawingsModel> drawingsList,
  }) : drawingsList = drawingsList.map((e) => e.toJson()).toList();
}

class DrawingsModel {
  final String title;
  final String subtitle;
  final String drawingThumbnailUrl;

  DrawingsModel({
    required this.title,
    required this.subtitle,
    required this.drawingThumbnailUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'subtitle': subtitle,
      'drawingThumbnailUrl': drawingThumbnailUrl,
    };
  }

  factory DrawingsModel.fromJson(Map<String, dynamic> json) {
    return DrawingsModel(
      title: json['title'],
      subtitle: json['subtitle'],
      drawingThumbnailUrl: json['drawingThumbnailUrl'],
    );
  }
}
