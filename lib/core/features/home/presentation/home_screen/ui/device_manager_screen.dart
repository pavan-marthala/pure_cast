import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:pure_cast/core/features/casting/presentation/logic/discovery/cast_discovery_bloc.dart';
import 'package:pure_cast/core/features/casting/presentation/logic/session/cast_session_bloc.dart';
import 'package:pure_cast/core/theme/app_theme.dart';
import 'package:pure_cast/core/utils/app_buitton.dart';
import 'package:pure_cast/core/utils/app_toast.dart';
import 'package:pure_cast/core/utils/state_status.dart';

class DeviceManagerScreen extends StatefulWidget {
  const DeviceManagerScreen({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      useRootNavigator: true,
      backgroundColor: context.appColors.background,
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
            final activeDevice = sessionState.activeDevice;
            return Padding(
              padding: MediaQuery.of(context).viewInsets,
              child: SafeArea(
                child: AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: .start,
                      children: [
                        SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: Text("Cast To", style: typo.titleLarge),
                            ),
                            GestureDetector(
                              onTap: () {
                                context.pop();
                              },
                              child: Container(
                                padding: .all(8),
                                decoration: BoxDecoration(
                                  color: colors.card,
                                  border: Border.all(color: colors.border),
                                  shape: .circle,
                                ),
                                child: Icon(Icons.close, size: 18),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 20),
                        Text(
                          "CONNECTED",
                          style: typo.titleSmall.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                        SizedBox(height: 12),
                        Container(
                          padding: .all(12),
                          decoration: BoxDecoration(
                            color: colors.card,
                            border: Border.all(color: colors.border),
                            borderRadius: .circular(12),
                          ),
                          child: Column(
                            spacing: 12,
                            children: [
                              Row(
                                spacing: 12,
                                children: [
                                  Container(
                                    padding: .all(8),
                                    decoration: BoxDecoration(
                                      color: activeDevice != null
                                          ? colors.primary.withValues(alpha: .2)
                                          : colors.surfaceDark,
                                      borderRadius: .circular(8),
                                    ),
                                    child: Icon(
                                      Icons.tv,
                                      size: 20,
                                      color: activeDevice != null
                                          ? colors.primary
                                          : colors.textSecondary,
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: .start,
                                      children: [
                                        Text(
                                          activeDevice?.name ?? "Not Connected",
                                          style: typo.titleMedium,
                                        ),
                                        Text(
                                          activeDevice != null
                                              ? "${activeDevice.protocol.name} . Connected"
                                              : "Choose a device below to start casting",
                                          style: typo.labelMedium,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              if (activeDevice != null)
                                AppButton(
                                  text: "Disconnect",
                                  color: colors.card,
                                  width: double.infinity,
                                  side: Border.all(color: colors.border),
                                  padding: .symmetric(vertical: 10),
                                  borderRadius: 16,
                                  textStyle: typo.titleMedium,
                                  onPressed: () {
                                    context.read<CastSessionBloc>().add(
                                      CastSessionEvent.disconnectDevice(),
                                    );
                                  },
                                ),
                            ],
                          ),
                        ),
                        SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                "AVALIBLE",
                                style: typo.titleSmall.copyWith(
                                  color: colors.textSecondary,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                context.read<CastDiscoveryBloc>().add(
                                  CastDiscoveryEvent.refreshDiscovery(),
                                );
                              },
                              child: Row(
                                mainAxisSize: .min,
                                spacing: 4,
                                children: [
                                  Icon(
                                    Icons.refresh,
                                    size: 18,
                                    color: colors.primary,
                                  ),
                                  Text(
                                    "Rescan",
                                    style: typo.titleSmall.copyWith(
                                      color: colors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        Flexible(
                          child: ListView.separated(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemBuilder: (context, index) {
                              final device = state.devices[index];
                              final isSelected = device.id == activeDevice?.id;
                              final isConnecting =
                                  isSelected &&
                                  sessionState.connectionStatus ==
                                      StateStatus.loading;
                              final isConnected =
                                  isSelected &&
                                  sessionState.connectionStatus ==
                                      StateStatus.loaded;
                              return GestureDetector(
                                onTap: () {
                                  context.read<CastSessionBloc>().add(
                                    isConnected
                                        ? CastSessionEvent.disconnectDevice()
                                        : CastSessionEvent.connectDevice(
                                            device,
                                          ),
                                  );
                                },
                                child: Container(
                                  padding: .symmetric(
                                    horizontal: 8,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colors.card,
                                    border: Border.all(
                                      color: isSelected
                                          ? colors.primary
                                          : colors.border,
                                    ),
                                    borderRadius: .circular(12),
                                  ),
                                  child: Row(
                                    spacing: 12,
                                    children: [
                                      Container(
                                        padding: .all(8),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? colors.primary.withValues(
                                                  alpha: 0.2,
                                                )
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
                                        child: Text(
                                          device.name,
                                          style: typo.titleMedium,
                                        ),
                                      ),
                                      Container(
                                        padding: .all(5),
                                        decoration: BoxDecoration(
                                          color: colors.background,
                                          border: Border.all(
                                            color: colors.surfaceDark,
                                            width: 2,
                                          ),
                                          borderRadius: .circular(12),
                                        ),
                                        child: Row(
                                          spacing: 6,
                                          mainAxisSize: .min,
                                          children: [
                                            if (isConnecting)
                                              SizedBox(
                                                height: 14,
                                                width: 14,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      color: colors.primary400,
                                                    ),
                                              ),
                                            Text(
                                              isConnecting
                                                  ? "Connecting..."
                                                  : device.protocol.name,
                                              style: typo.bodySmall.copyWith(
                                                color: colors.textPrimary,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      // if (isConnecting) ...[
                                      // SizedBox(
                                      //   height: 20,
                                      //   width: 20,
                                      //   child: CircularProgressIndicator(
                                      //     strokeWidth: 2,
                                      //     color: colors.primary400,
                                      //   ),
                                      // ),
                                      //   Text(
                                      //     "Connecting...",
                                      //     style: typo.labelSmall.copyWith(
                                      //       color: colors.primary400,
                                      //     ),
                                      //   ),
                                      // ],
                                      // if (isConnected) ...[
                                      //   Icon(
                                      //     Icons.clear,
                                      //     size: 20,
                                      //     color: colors.error,
                                      //   ),
                                      //   Text(
                                      //     "Disconnect",
                                      //     style: typo.labelSmall.copyWith(
                                      //       color: colors.error,
                                      //     ),
                                      //   ),
                                      // ],
                                    ],
                                  ),
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
                        ),
                        if (state.discoveryStatus == .loading) ...[
                          SizedBox(height: 20),
                          Row(
                            spacing: 12,
                            children: [
                              SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                              Text("Still looking for more devices..."),
                            ],
                          ),
                        ],
                        SizedBox(height: 50),
                        AppButton(
                          text: "Add device by IP address",
                          color: colors.surfaceDark,
                          width: double.infinity,
                          side: Border.all(color: colors.border),
                          icon: Icon(Icons.add),
                          padding: .symmetric(vertical: 12),
                          borderRadius: 16,
                          textStyle: typo.titleMedium,
                          onPressed: () {
                            context.pop();
                          },
                        ),
                        SizedBox(height: 20),
                        Text(
                          "Can't see your device? Make sure it is one the same Wi-Fi network as this one ",
                          textAlign: .center,
                        ),
                        SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
