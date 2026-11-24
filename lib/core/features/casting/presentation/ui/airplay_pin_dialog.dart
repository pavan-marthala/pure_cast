import 'package:material_ui/material_ui.dart';
import 'package:pure_cast/core/theme/app_theme.dart';
import 'package:pure_cast/core/utils/app_buitton.dart';

/// Asks for the PIN an AirPlay receiver displays while pairing.
///
/// Returns the entered PIN, or `null` when the user cancelled.
Future<String?> showAirPlayPinDialog(
  BuildContext context, {
  required String deviceName,
}) {
  return showDialog<String>(
    context: context,
    useRootNavigator: true,
    useSafeArea: true,
    barrierDismissible: false,
    builder: (_) => _AirPlayPinDialog(deviceName: deviceName),
  );
}

class _AirPlayPinDialog extends StatefulWidget {
  const _AirPlayPinDialog({required this.deviceName});

  final String deviceName;

  @override
  State<_AirPlayPinDialog> createState() => _AirPlayPinDialogState();
}

class _AirPlayPinDialogState extends State<_AirPlayPinDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onChanged() => setState(() {});

  bool get _isComplete => _controller.text.length == 4;

  void _submit() {
    if (_isComplete) Navigator.of(context).pop(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typo = context.appTypography;

    return Dialog(
      backgroundColor: colors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.border),
      ),
      insetPadding: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: .min,
          crossAxisAlignment: .start,
          spacing: 12,
          children: [
            Row(
              spacing: 12,
              children: [
                Container(
                  padding: .all(8),
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: .2),
                    borderRadius: .circular(8),
                  ),
                  child: Icon(
                    Icons.lock_outline,
                    size: 20,
                    color: colors.primary,
                  ),
                ),
                Expanded(
                  child: Text('AirPlay pairing', style: typo.titleLarge),
                ),
              ],
            ),
            Text(
              'Enter the 4-digit code shown on ${widget.deviceName}.',
              style: typo.labelMedium.copyWith(color: colors.textSecondary),
            ),
            TextField(
              controller: _controller,
              autofocus: true,
              keyboardType: TextInputType.number,
              textAlign: .center,
              maxLength: 4,
              style: typo.titleLarge.copyWith(letterSpacing: 8),
              onSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                counterText: '',
                hintText: '0000',
                filled: true,
                fillColor: colors.background,
                enabledBorder: OutlineInputBorder(
                  borderRadius: .circular(12),
                  borderSide: BorderSide(color: colors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: .circular(12),
                  borderSide: BorderSide(color: colors.primary),
                ),
              ),
            ),
            Row(
              spacing: 12,
              children: [
                Expanded(
                  child: AppButton(
                    text: 'Cancel',
                    color: colors.background,
                    side: Border.all(color: colors.border),
                    padding: .symmetric(vertical: 12),
                    textStyle: typo.titleMedium,
                    width: double.infinity,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                Expanded(
                  child: AppButton(
                    text: 'Connect',
                    color: _isComplete ? colors.primary : colors.surfaceDark,
                    padding: .symmetric(vertical: 12),
                    textStyle: typo.titleMedium,
                    width: double.infinity,
                    onPressed: _isComplete ? _submit : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
