import 'package:flutter/material.dart';

class _ColorSlider extends StatelessWidget {
  final String label;
  final double value;
  final double max;
  final Gradient gradient;
  final ValueChanged<double> onChanged;

  const _ColorSlider({
    required this.label,
    required this.value,
    required this.max,
    required this.gradient,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: tt.labelMedium?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                height: 12,
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: Colors.black.withValues(alpha: 0.08),
                  ),
                ),
              ),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 12,
                  activeTrackColor: Colors.transparent,
                  inactiveTrackColor: Colors.transparent,
                  thumbColor: Colors.white,
                  overlayColor: Colors.white.withValues(alpha: 0.15),
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 9,
                    elevation: 2,
                  ),
                ),
                child: Slider(
                  value: value,
                  max: max,
                  onChanged: onChanged,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 打开自定义主题色选择对话框，返回选中的颜色（取消返回 null）
Future<Color?> showCustomColorPickerDialog(
  BuildContext context, {
  required Color initialColor,
}) {
  return showDialog<Color>(
    context: context,
    builder: (context) => _CustomColorPickerDialog(initialColor: initialColor),
  );
}

class _CustomColorPickerDialog extends StatefulWidget {
  final Color initialColor;
  const _CustomColorPickerDialog({required this.initialColor});

  @override
  State<_CustomColorPickerDialog> createState() =>
      _CustomColorPickerDialogState();
}

class _CustomColorPickerDialogState extends State<_CustomColorPickerDialog> {
  late HSVColor _hsv;
  late final TextEditingController _hexController;

  @override
  void initState() {
    super.initState();
    _hsv = HSVColor.fromColor(widget.initialColor);
    _hexController = TextEditingController(text: _toHex(widget.initialColor));
  }

  @override
  void dispose() {
    _hexController.dispose();
    super.dispose();
  }

  static String _toHex(Color c) {
    final hex = c.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase();
    return '#${hex.substring(2)}';
  }

  void _syncHexFromHsv() {
    final text = _toHex(_hsv.toColor());
    _hexController.text = text;
    _hexController.selection = TextSelection.collapsed(offset: text.length);
  }

  void _applyHex(String value) {
    var v = value.trim().replaceFirst('#', '');
    if (v.length == 6) v = 'FF$v';
    final parsed = int.tryParse(v, radix: 16);
    if (parsed == null) return;
    setState(() => _hsv = HSVColor.fromColor(Color(parsed)));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final color = _hsv.toColor();

    return AlertDialog(
      title: const Text('自定义主题色'),
      content: SizedBox(
        width: 360,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.45),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _toHex(color),
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 20),
              _ColorSlider(
                label: '色相',
                value: _hsv.hue,
                max: 360,
                gradient: LinearGradient(
                  colors: [
                    for (var i = 0; i <= 360; i += 60)
                      HSVColor.fromAHSV(1, (i % 360).toDouble(), 1, 1).toColor(),
                  ],
                ),
                onChanged: (v) => setState(() {
                  _hsv = _hsv.withHue(v % 360);
                  _syncHexFromHsv();
                }),
              ),
              _ColorSlider(
                label: '饱和度',
                value: _hsv.saturation,
                max: 1,
                gradient: LinearGradient(
                  colors: [
                    HSVColor.fromAHSV(1, _hsv.hue, 0, _hsv.value).toColor(),
                    HSVColor.fromAHSV(1, _hsv.hue, 1, _hsv.value).toColor(),
                  ],
                ),
                onChanged: (v) => setState(() {
                  _hsv = _hsv.withSaturation(v);
                  _syncHexFromHsv();
                }),
              ),
              _ColorSlider(
                label: '明度',
                value: _hsv.value,
                max: 1,
                gradient: LinearGradient(
                  colors: [
                    HSVColor
                        .fromAHSV(1, _hsv.hue, _hsv.saturation, 0)
                        .toColor(),
                    HSVColor
                        .fromAHSV(1, _hsv.hue, _hsv.saturation, 1)
                        .toColor(),
                  ],
                ),
                onChanged: (v) => setState(() {
                  _hsv = _hsv.withValue(v);
                  _syncHexFromHsv();
                }),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _hexController,
                onSubmitted: _applyHex,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: '十六进制色值',
                  hintText: '#RRGGBB',
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_hsv.toColor()),
          child: const Text('确定'),
        ),
      ],
    );
  }
}
