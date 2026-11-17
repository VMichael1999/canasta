import 'package:flutter_test/flutter_test.dart';
import 'package:canasta/blocs/address/address_cubit.dart';
import 'package:canasta/blocs/search/search_cubit.dart';
import 'package:canasta/data/initial_data.dart';
import 'package:canasta/domain/models/address.dart';

void main() {
  group('SearchCubit Tests', () {
    test('searches case-insensitive and accent-insensitive', () {
      final cubit = SearchCubit();

      cubit.search('platano');
      expect(cubit.state.results.any((p) => p.id == 'banana'), isTrue);

      cubit.search('PALTA');
      expect(cubit.state.results.any((p) => p.id == 'avocado'), isTrue);

      cubit.search('brocoli');
      expect(cubit.state.results.any((p) => p.id == 'broccoli'), isTrue);

      cubit.close();
    });

    test('adds submitted query to recent searches', () {
      final cubit = SearchCubit();
      cubit.submitQuery('manzanas');
      expect(cubit.state.recent.contains('manzanas'), isTrue);
      cubit.clearRecent();
      expect(cubit.state.recent, isEmpty);
      cubit.close();
    });
  });

  group('AddressCubit Tests', () {
    test('validates covered and out-of-coverage districts correctly', () {
      expect(InitialData.isDistrictCovered('Miraflores'), isTrue);
      expect(InitialData.isDistrictCovered('San Isidro'), isTrue);
      expect(InitialData.isDistrictCovered('Barranco'), isTrue);

      expect(InitialData.isDistrictCovered('Chorrillos'), isFalse);
      expect(InitialData.isDistrictCovered('La Molina'), isFalse);
      expect(InitialData.isDistrictCovered('Callao'), isFalse);
    });

    test('default address is Casa in Miraflores and selection warns on out-of-coverage', () {
      final cubit = AddressCubit();
      expect(cubit.state.selectedAddress.district, 'Miraflores');

      // Attempt to select out-of-coverage address
      const outOfCoverageAddr = Address(
        id: 'chorrillos',
        tag: 'Playa',
        line: 'Malecón Grau 120',
        district: 'Chorrillos',
        reference: 'Frente al mar',
      );
      cubit.selectAddress(outOfCoverageAddr);
      expect(cubit.state.hasCoverageWarning, isTrue);
      expect(cubit.state.coverageWarningDistrict, 'Chorrillos');

      cubit.dismissCoverageWarning();
      expect(cubit.state.hasCoverageWarning, isFalse);

      cubit.close();
    });
  });
}
