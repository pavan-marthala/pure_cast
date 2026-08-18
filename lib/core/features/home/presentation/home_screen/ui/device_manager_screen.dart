import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:pure_cast/core/features/casting/presentation/logic/discovery/cast_discovery_bloc.dart';
import 'package:pure_cast/core/features/casting/presentation/logic/session/cast_session_bloc.dart';
import 'package:pure_cast/core/theme/app_theme.dart';
import 'package:pure_cast/core/utils/app_buitton.dart';
import 'package:pure_cast/core/utils/app_toast.dart';
import 'package:pure_cast/core/utils/sized_context.dart';
import 'package:pure_cast/core/utils/state_status.dart';

class DeviceManagerScreen extends StatefulWidget {
  const DeviceManagerScreen({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      useRootNavigator: true,
      showDragHandle: true,
      backgroundColor: context.appColors.surfaceLight,
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

    return BlocBuilder<CastDiscoveryBloc, CastDiscoveryState>(
      builder: (context, state) {
        return BlocConsumer<CastSessionBloc, CastSessionState>(
          listener: (context, sessionState) {
            if (sessionState.connectionError != null &&
                sessionState.connectionStatus == StateStatus.error) {
              showErrorToast(message: sessionState.connectionError!);
            }
          },
          builder: (context, sessionState) {
            return SingleChildScrollView(
              padding: .symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: .start,
                children: [
                  Text(
                    "Choose where to play",
                    style: typo.titleMedium.copyWith(fontSize: 18),
                  ),
                  Text("Devices on your network"),
                  SizedBox(height: 20),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemBuilder: (context, index) {
                      final device = state.devices[index];
                      final isSelected =
                          device.id == sessionState.activeDevice?.id;
                      final isConnecting =
                          isSelected &&
                          sessionState.connectionStatus == StateStatus.loading;
                      final isConnected =
                          isSelected &&
                          sessionState.connectionStatus == StateStatus.loaded;
                      return GestureDetector(
                        onTap: () {
                          context.read<CastSessionBloc>().add(
                            isConnected
                                ? CastSessionEvent.disconnectDevice()
                                : CastSessionEvent.connectDevice(device),
                          );
                        },
                        child: Row(
                          spacing: 12,
                          children: [
                            Icon(
                              isSelected
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_off,
                              color: isSelected ? colors.primary : colors.gray4,
                            ),
                            Container(
                              padding: .all(8),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? colors.primary.withValues(alpha: 0.2)
                                    : colors.surfaceDark,
                                borderRadius: .circular(8),
                              ),
                              child: Icon(
                                Icons.tv,
                                size: 20,
                                color: isSelected
                                    ? colors.primary
                                    : colors.textSecondary,
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: .start,
                                children: [
                                  Text(device.name, style: typo.titleSmall),
                                  Text(device.protocol.name),
                                ],
                              ),
                            ),
                            if (isConnecting) ...[
                              SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: colors.primary400,
                                ),
                              ),
                              Text(
                                "Connecting...",
                                style: typo.labelSmall.copyWith(
                                  color: colors.primary400,
                                ),
                              ),
                            ],
                            if (isConnected) ...[
                              Icon(Icons.clear, size: 20, color: colors.error),
                              Text(
                                "Disconnect",
                                style: typo.labelSmall.copyWith(
                                  color: colors.error,
                                ),
                              ),
                            ],
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
                  if (state.discoveryStatus == .loading) ...[
                    SizedBox(height: 20),
                    Row(
                      spacing: 12,
                      children: [
                        SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        Text("Still looking for more devices..."),
                      ],
                    ),
                  ],
                  SizedBox(height: 20),
                  AppButton(
                    text: "Cancel",
                    color: colors.surfaceDark,
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
      },
    );
  }
}
