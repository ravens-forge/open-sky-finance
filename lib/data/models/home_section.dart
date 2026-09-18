import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../enums/home_section_id.dart';

/// A Home page section and whether it is shown.
@immutable
class HomeSection {
  const HomeSection(this.id, {required this.visible});

  final HomeSectionId id;
  final bool visible;

  /// Every [HomeSectionId] once, in display order, from the stored JSON: unknown
  /// ids (and duplicates) are ignored and missing ones are appended with their
  /// default visibility, so later versions can add sections without a migration.
  static List<HomeSection> listFromJson(String? json) {
    final sections = <HomeSectionId, HomeSection>{};
    Object? decoded;
    try {
      decoded = json == null ? null : jsonDecode(json);
    } on FormatException {
      decoded = null;
    }
    if (decoded is List) {
      for (final item in decoded) {
        if (item case {
          'id': final String name,
          'visible': final bool visible,
        }) {
          final id = HomeSectionId.values.asNameMap()[name];
          if (id != null) {
            sections.putIfAbsent(id, () => HomeSection(id, visible: visible));
          }
        }
      }
    }
    for (final id in HomeSectionId.values) {
      sections.putIfAbsent(
        id,
        () => HomeSection(id, visible: id.visibleByDefault),
      );
    }
    return sections.values.toList();
  }

  static String listToJson(List<HomeSection> sections) => jsonEncode([
    for (final s in sections) {'id': s.id.name, 'visible': s.visible},
  ]);

  @override
  bool operator ==(Object other) =>
      other is HomeSection && other.id == id && other.visible == visible;

  @override
  int get hashCode => Object.hash(id, visible);
}
