import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:pure_cast/core/features/casting/presentation/logic/discovery/cast_discovery_bloc.dart';
import 'package:pure_cast/core/theme/app_theme.dart';
import 'package:pure_cast/core/utils/app_buitton.dart';
import 'package:pure_cast/core/utils/sized_context.dart';

class DeviceManagerScreen extends StatefulWidget {
  const DeviceManagerScreen({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      useRootNavigator: true,
      showDragHandle: true,
      backgroundColor: context.appColors.background,
      constraints: BoxConstraints(
        maxHeight: context.heightPx * 0.5,
        minWidth: double.infinity,
      ),
      builder: (sheetContext) => const DeviceManagerScreen(),
    );
  }

  @override
  State<DeviceManagerScreen> createState() => _DeviceManagerScreenState();
}

class _DeviceManagerScreenState extends State<DeviceManagerScreen> {
  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typo = context.appTypography;
    return BlocConsumer<CastDiscoveryBloc, CastDiscoveryState>(
      listener: (context, state) {
        // TODO: implement listener
      },
      builder: (context, state) {
        return SingleChildScrollView(
          // constraints: BoxConstraints(maxHeight: context.heightPx * 0.5),
          // // decoration: BoxDecoration(
          // //   color: colors.background,
          // //   borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          // // ),
          // width: double.infinity,
          padding: .symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: .start,
            children: [
              Text(
                "Choose where to play",
                style: typo.titleMedium.copyWith(fontSize: 20),
              ),
              Text("Devices on your network"),
              SizedBox(height: 20),
              ListView.separated(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  final device = state.devices[index];
                  final isSelected = device == state.selectedDevice;
                  final isLoading =
                      isSelected && state.connectionStatus == .loading;
                  return GestureDetector(
                    onTap: () {
                      context.read<CastDiscoveryBloc>().add(
                        CastDiscoveryEvent.connectToDevice(device),
                      );
                    },
                    child: Row(
                      spacing: 12,
                      children: [
                        Icon(
                          isSelected
                              ? Icons.radio_button_checked
                              : Icons.radio_button_off,
                          color: isSelected ? colors.primary : colors.white,
                        ),
                        Container(
                          padding: .all(6),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? colors.primary.withValues(alpha: 0.2)
                                : colors.gray,
                            borderRadius: .circular(8),
                          ),
                          child: Icon(
                            Icons.tv,
                            size: 20,
                            color: isSelected ? colors.primary : colors.white,
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: .start,
                            children: [
                              Text(device.name),
                              Text(device.protocol.name),
                            ],
                          ),
                        ),
                        if (isLoading) CircularProgressIndicator(),
                      ],
                    ),
                  );
                },
                separatorBuilder: (context, index) => Divider(
                  height: 16,
                  color: colors.borderLight,
                  thickness: 1.5,
                ),
                itemCount: state.devices.length,
              ),
              SizedBox(height: 20),
              AppButton(
                text: "Cancel",
                color: colors.card,
                width: double.infinity,
                borderRadius: 20,
                onPressed: () {
                  context.pop();
                },
              ),
              SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
}
