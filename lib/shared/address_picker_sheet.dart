import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../blocs/address/address_cubit.dart';
import '../core/haptics.dart';
import '../core/tokens.dart';
import 'app_svg_icon.dart';
import 'app_toast.dart';

class AddressPickerSheet extends StatelessWidget {
  const AddressPickerSheet({super.key});

  static Future<void> show(BuildContext context) {
    CaHaptics.lightImpact();
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const AddressPickerSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final addressState = context.watch<AddressCubit>().state;
    final addresses = addressState.addresses;
    final selectedId = addressState.selectedAddress.id;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 34),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFD8DCE5),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Entregar en',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: tokens.ink,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: addresses.length,
            separatorBuilder: (_, __) =>
                Divider(color: tokens.line, height: 1),
            itemBuilder: (context, index) {
              final addr = addresses[index];
              final isSelected = addr.id == selectedId;
              final iconName = addr.tag == 'Casa'
                  ? 'home'
                  : (addr.tag == 'Trabajo' ? 'brief' : 'pin');

              return InkWell(
                onTap: () {
                  CaHaptics.selectionClick();
                  context.read<AddressCubit>().selectAddress(addr);
                  Navigator.of(context).pop();
                  AppToast.show(context, 'Entregamos en ${addr.district}.');
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      AppSvgIcon(
                        iconName,
                        size: 22,
                        color: isSelected ? tokens.blue : tokens.ink2,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              addr.tag,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: isSelected ? tokens.blue : tokens.ink,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${addr.line}, ${addr.district}',
                              style: TextStyle(
                                fontSize: 13,
                                color: tokens.ink2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        AppSvgIcon(
                          'checkc',
                          size: 20,
                          color: tokens.blue,
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
          Divider(color: tokens.line, height: 1),
          InkWell(
            onTap: () {
              Navigator.of(context).pop();
              context.push('/location');
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(
                children: [
                  AppSvgIcon('plus', size: 20, color: tokens.blue),
                  const SizedBox(width: 14),
                  Text(
                    'Agregar dirección',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: tokens.blue,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
