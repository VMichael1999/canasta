import 'package:equatable/equatable.dart';

class Category extends Equatable {
  const Category({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.subs,
    required this.previewProductIds,
  });

  final String id;
  final String name;
  final String subtitle;
  final List<String> subs;
  final List<String> previewProductIds;

  /// Ilustración de la fila de categorías del inicio (igual que el HTML).
  String? get homeArtId => previewProductIds.isEmpty
      ? null
      : previewProductIds[previewProductIds.length - 1 > 1 ? 1 : 0];

  @override
  List<Object?> get props => [id, name, subtitle, subs, previewProductIds];
}
