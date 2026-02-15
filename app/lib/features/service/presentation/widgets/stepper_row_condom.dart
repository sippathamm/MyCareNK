import 'package:flutter/material.dart';
import 'dart:async';

// Color Palette
const Color primaryColor = Color(0xFFFF8A50);
const Color textColor = Color(0xFF333333);
const Color textGrey = Color(0xFF777777);

class StepperRowCondom extends StatefulWidget {
  final String label;
  final int count;
  final int max;
  final ValueChanged<int> onChanged;

  const StepperRowCondom({
    super.key,
    required this.label,
    required this.count,
    required this.max,
    required this.onChanged,
  });

  @override
  State<StepperRowCondom> createState() => _StepperRowCondomState();
}

class _StepperRowCondomState extends State<StepperRowCondom> {
  late TextEditingController _controller;

  // Timer for long press
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.count.toString());
  }

  @override
  void didUpdateWidget(covariant StepperRowCondom oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.count != oldWidget.count) {
      final textVal = int.tryParse(_controller.text) ?? 0;
      if (textVal != widget.count) {
        _controller.text = widget.count.toString();
        _controller.selection = TextSelection.fromPosition(
          TextPosition(offset: _controller.text.length),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _cancelTimer();
    super.dispose();
  }

  void _startTimer(bool isAdd) {
    _cancelTimer();
    // Initial delay then periodic
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      final newCount = widget.count + (isAdd ? 1 : -1);
      // Check limits
      if (newCount >= 0 && newCount <= widget.max) {
        widget.onChanged(newCount);
      }
    });
  }

  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            widget.label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(width: 4),
          const Text('มม.', style: TextStyle(fontSize: 14, color: textGrey)),
          const Spacer(),
          _buildStepperButton(
            icon: Icons.remove,
            onTap: () {
              if (widget.count > 0) widget.onChanged(widget.count - 1);
            },
            onLongPressStart: () => _startTimer(false),
            onLongPressEnd: () => _cancelTimer(),
            isEnabled: widget.count > 0,
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 50,
            child: TextField(
              controller: _controller,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 0),
              ),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
              onChanged: (value) {
                final newValue = int.tryParse(value);
                if (newValue != null) {
                  if (newValue >= 0 && newValue <= widget.max) {
                    widget.onChanged(newValue);
                  } else if (newValue > widget.max) {
                    widget.onChanged(widget.max);
                  }
                } else if (value.isEmpty) {
                  widget.onChanged(0);
                }
              },
            ),
          ),
          const SizedBox(width: 12),
          _buildStepperButton(
            icon: Icons.add,
            onTap: () => widget.onChanged(widget.count + 1),
            onLongPressStart: () => _startTimer(true),
            onLongPressEnd: () => _cancelTimer(),
            isEnabled: widget.count < widget.max,
            isAdd: true,
          ),
        ],
      ),
    );
  }

  Widget _buildStepperButton({
    required IconData icon,
    required VoidCallback onTap,
    required VoidCallback onLongPressStart,
    required VoidCallback onLongPressEnd,
    required bool isEnabled,
    bool isAdd = false,
  }) {
    return GestureDetector(
      onLongPress: isEnabled ? onLongPressStart : null,
      onLongPressUp: onLongPressEnd,
      onLongPressCancel: onLongPressEnd,
      child: InkWell(
        onTap: isEnabled ? onTap : null,
        customBorder: const CircleBorder(),
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isEnabled
                ? (isAdd ? primaryColor : Colors.grey[200])
                : Colors.grey[100],
          ),
          child: Icon(
            icon,
            color: isEnabled
                ? (isAdd ? Colors.white : textGrey)
                : Colors.grey[300],
            size: 18,
          ),
        ),
      ),
    );
  }
}
