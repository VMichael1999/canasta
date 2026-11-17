import 'package:equatable/equatable.dart';

class Courier extends Equatable {
  const Courier({
    required this.name,
    required this.rating,
    required this.reviewsCount,
    required this.vehicle,
    required this.plate,
    required this.phone,
  });

  final String name;
  final double rating;
  final int reviewsCount;
  final String vehicle;
  final String plate;
  final String phone;

  static const Courier defaultCourier = Courier(
    name: 'Carlos Huamán',
    rating: 4.9,
    reviewsCount: 235,
    vehicle: 'Moto',
    plate: 'ABC-123',
    phone: '+51 987 111 222',
  );

  @override
  List<Object?> get props => [name, rating, reviewsCount, vehicle, plate, phone];
}
