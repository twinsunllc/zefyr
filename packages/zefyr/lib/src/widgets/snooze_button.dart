import 'package:flutter/material.dart';

class SnoozeButton extends StatelessWidget {
  final Function(DateTime) onSnooze;

  SnoozeButton({this.onSnooze});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 0.0),
      height: 21.0,
      child: Row(
        children: [
          Listener(
            onPointerDown: (event) async{
              DateTime selectedDate = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2018),
                lastDate: DateTime(2030),
                builder: (BuildContext context, Widget child) {
                  return Theme(
                    data: ThemeData.dark(),
                    child: child,
                  );
                },
              );
              print("Snoozed until ${selectedDate}");
              onSnooze(selectedDate);
            },
            child: InkWell(
              borderRadius: BorderRadius.circular(20.0),
              child: Padding(
                padding: const EdgeInsets.all(1.0),
                child: Icon(Icons.calendar_today, size: 18.0, color: Colors.grey[400])
              ),
            ),
          ),
        ],
      ),
    );
  }
}