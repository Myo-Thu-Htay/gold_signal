import 'package:flutter/material.dart';
import 'package:numberpicker/numberpicker.dart';

class TimePickerWidget extends StatefulWidget {
  final TimeOfDay? initialTime;
  final Function(Duration) onTimeChanged;

  const TimePickerWidget(
      {super.key, required this.onTimeChanged, required this.initialTime});

  @override
  State<TimePickerWidget> createState() => _TimePickerWidgetState();
}

class _TimePickerWidgetState extends State<TimePickerWidget> {
  int hour = 0;
  int minute = 0;
  int second = 0;

  @override
  Widget build(BuildContext context) {
    String timeStr =
        "${widget.initialTime!.hour.toString().padLeft(2, '0')}:${widget.initialTime!.minute.toString().padLeft(2, '0')}";
    return AlertDialog(
      title: const Text('Select Time'),
      alignment: Alignment.center,
      content: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(timeStr, style: const TextStyle(fontSize: 24)),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                NumberPicker(
                  value: hour,
                  minValue: 0,
                  maxValue: 23,
                  onChanged: (value) {
                    setState(() {
                      hour = value;
                    });
                  },
                ),
                const Text(':'),
                NumberPicker(
                  value: minute,
                  minValue: 0,
                  maxValue: 59,
                  onChanged: (value) {
                    setState(() {
                      minute = value;
                    });
                  },
                ),
                const Text(':'),
                NumberPicker(
                  value: second,
                  minValue: 0,
                  maxValue: 59,
                  onChanged: (value) {
                    setState(() {
                      second = value;
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            final duration = Duration(
              hours: hour,
              minutes: minute,
              seconds: second,
            );
            widget.onTimeChanged(duration);
            //Navigator.of(context).pop();
          },
          child: const Text('OK'),
        ),
      ],
    );
  }
}
