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

  @override
  List<Object?> get props => [id, name, subtitle, subs, previewProductIds];
}
