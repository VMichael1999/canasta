import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../blocs/address/address_cubit.dart';
import '../../core/tokens.dart';
import '../../domain/models/address.dart';
import '../../shared/illustrated_map.dart';

class LocationScreen extends StatelessWidget {
  const LocationScreen({super.key});

  void _showAddAddressSheet(BuildContext context) {
    final tokens = context.tokens;
    final addressCtrl = TextEditingController();
    final districtCtrl = TextEditingController(text: 'Miraflores');
    final refCtrl = TextEditingController();
    String selectedTag = 'Casa';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: const EdgeInsets.fromLTRB(22, 12, 22, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: tokens.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Agregar dirección',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: tokens.ink,
                  ),
                ),
                const SizedBox(height: 16),

                // Tag selector (Casa, Trabajo, Otro)
                Row(
                  children: ['Casa', 'Trabajo', 'Otro'].map((tag) {
                    final isSel = selectedTag == tag;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(tag),
                        selected: isSel,
                        onSelected: (_) {
                          setSheetState(() => selectedTag = tag);
                        },
                        selectedColor: tokens.blueSoft,
                        backgroundColor: tokens.chip,
                        labelStyle: TextStyle(
                          color: isSel ? tokens.blue : tokens.ink,
                          fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),

                TextField(
                  controller: addressCtrl,
                  decoration: InputDecoration(
                    labelText: 'Dirección (calle y número / dpto)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: districtCtrl,
                  decoration: InputDecoration(
                    labelText: 'Distrito (ej: Miraflores, San Isidro)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: refCtrl,
                  decoration: InputDecoration(
                    labelText: 'Referencia (opcional)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      if (addressCtrl.text.trim().isEmpty) return;
                      final newAddr = Address(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        tag: selectedTag,
                        line: addressCtrl.text.trim(),
                        district: districtCtrl.text.trim(),
                        reference: refCtrl.text.trim(),
                      );
                      context.read<AddressCubit>().addAddress(newAddr);
                      Navigator.of(ctx).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: tokens.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Guardar dirección',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return BlocConsumer<AddressCubit, AddressState>(
      listener: (context, state) {
        if (state.hasCoverageWarning) {
          showModalBottomSheet(
            context: context,
            backgroundColor: Colors.transparent,
            builder: (ctx) => Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: tokens.badSoft,
                    ),
                    alignment: Alignment.center,
                    child: Icon(Icons.location_off_rounded,
                        size: 28, color: tokens.bad),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aún no llegamos a ${state.coverageWarningDistrict}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: tokens.ink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Estamos expandiendo nuestra cobertura en Lima. Te avisaremos apenas lleguemos a tu zona.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: tokens.ink2,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        context.read<AddressCubit>().dismissCoverageWarning();
                        Navigator.of(ctx).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: tokens.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: const Text('Usar otra dirección'),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: Colors.white,
          body: Stack(
            children: [
              // Map background
              Positioned.fill(
                bottom: 320,
                child: const IllustratedMap(
                  progress: 0.5,
                  showExpandButton: false,
                ),
              ),

              // Back button on top
              Positioned(
                top: 56,
                left: 20,
                child: GestureDetector(
                  onTap: () => context.pop(),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Icon(Icons.arrow_back, color: tokens.ink),
                  ),
                ),
              ),

              // Bottom Sheet with Saved Addresses
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  height: 380,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(28)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 20,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.fromLTRB(22, 16, 22, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 36,
                          height: 4,
                          decoration: BoxDecoration(
                            color: tokens.border,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Dirección de entrega',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: tokens.ink,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Current Location button
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: tokens.blueSoft,
                          ),
                          alignment: Alignment.center,
                          child: Icon(Icons.my_location,
                              size: 20, color: tokens.blue),
                        ),
                        title: Text(
                          'Usar mi ubicación actual',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: tokens.blue,
                          ),
                        ),
                        subtitle: Text(
                          'Miraflores, Lima',
                          style: TextStyle(fontSize: 13, color: tokens.ink2),
                        ),
                        onTap: () {
                          context.read<AddressCubit>().selectAddress(
                                state.addresses.first,
                              );
                          context.pop();
                        },
                      ),
                      const Divider(),

                      // Saved Addresses
                      Expanded(
                        child: ListView.separated(
                          itemCount: state.addresses.length,
                          separatorBuilder: (_, __) =>
                              Divider(color: tokens.line, height: 1),
                          itemBuilder: (context, index) {
                            final addr = state.addresses[index];
                            final isSel = state.selectedAddress.id == addr.id;

                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(
                                addr.tag == 'Casa'
                                    ? Icons.home_outlined
                                    : Icons.work_outline,
                                color: isSel ? tokens.blue : tokens.ink2,
                              ),
                              title: Text(
                                '${addr.tag} · ${addr.line}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight:
                                      isSel ? FontWeight.w700 : FontWeight.w500,
                                  color: tokens.ink,
                                ),
                              ),
                              subtitle: Text(
                                '${addr.district}${addr.reference.isNotEmpty ? ' · ${addr.reference}' : ''}',
                                style: TextStyle(
                                    fontSize: 12.5, color: tokens.ink2),
                              ),
                              trailing: isSel
                                  ? Icon(Icons.check_circle,
                                      color: tokens.blue, size: 20)
                                  : null,
                              onTap: () {
                                context
                                    .read<AddressCubit>()
                                    .selectAddress(addr);
                                context.pop();
                              },
                            );
                          },
                        ),
                      ),

                      // Add Address Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton.icon(
                          onPressed: () => _showAddAddressSheet(context),
                          icon: const Icon(Icons.add),
                          label: const Text('Agregar dirección'),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: tokens.border, width: 1.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
