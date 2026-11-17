import 'package:equatable/equatable.dart';

class Address extends Equatable {
  const Address({
    required this.id,
    required this.tag,
    required this.line,
    required this.district,
    this.reference = '',
  });

  final String id;
  final String tag; // Casa, Trabajo, Otro
  final String line;
  final String district;
  final String reference;

  String get shortLine => line.split(',').first.trim();

  @override
  List<Object?> get props => [id, tag, line, district, reference];
}
