import 'package:equatable/equatable.dart';

class DeliverySlot extends Equatable {
  const DeliverySlot({
    required this.dayIndex, // 0 = Hoy, 1 = Mañana, etc.
    required this.hour, // 8..21
  });

  final int dayIndex;
  final int hour;

  String get label {
    final start = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final end = (hour + 1) > 12 ? (hour + 1) - 12 : ((hour + 1) == 0 ? 12 : (hour + 1));
    final period = (hour + 1) >= 12 ? 'p. m.' : 'a. m.';
    return '$start:00 – $end:00 $period';
  }

  @override
  List<Object?> get props => [dayIndex, hour];
}
