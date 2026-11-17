import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/initial_data.dart';
import '../../domain/models/address.dart';

class AddressState extends Equatable {
  const AddressState({
    required this.addresses,
    required this.selectedAddress,
    this.coverageWarningDistrict,
  });

  final List<Address> addresses;
  final Address selectedAddress;
  final String? coverageWarningDistrict;

  bool get hasCoverageWarning => coverageWarningDistrict != null;

  AddressState copyWith({
    List<Address>? addresses,
    Address? selectedAddress,
    String? coverageWarningDistrict,
    bool clearWarning = false,
  }) {
    return AddressState(
      addresses: addresses ?? this.addresses,
      selectedAddress: selectedAddress ?? this.selectedAddress,
      coverageWarningDistrict: clearWarning
          ? null
          : (coverageWarningDistrict ?? this.coverageWarningDistrict),
    );
  }

  @override
  List<Object?> get props =>
      [addresses, selectedAddress, coverageWarningDistrict];
}

class AddressCubit extends Cubit<AddressState> {
  AddressCubit()
      : super(AddressState(
          addresses: InitialData.addresses,
          selectedAddress: InitialData.addresses.first,
        ));

  void selectAddress(Address address) {
    if (!InitialData.isDistrictCovered(address.district)) {
      emit(state.copyWith(coverageWarningDistrict: address.district));
      return;
    }
    emit(state.copyWith(
      selectedAddress: address,
      clearWarning: true,
    ));
  }

  void addAddress(Address address) {
    if (!InitialData.isDistrictCovered(address.district)) {
      emit(state.copyWith(coverageWarningDistrict: address.district));
      return;
    }
    final updated = [...state.addresses, address];
    emit(state.copyWith(
      addresses: updated,
      selectedAddress: address,
      clearWarning: true,
    ));
  }

  void dismissCoverageWarning() {
    emit(state.copyWith(clearWarning: true));
  }
}
