import 'package:flutter/material.dart';
import 'package:zefyr/views/helpers/artful_agenda_icons.dart';

class ChecklistItemBox extends StatelessWidget {
  final bool isChecked;
  final VoidCallback onToggle;

  ChecklistItemBox({this.isChecked, this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 0.0),
      height: 21.0,
      child: Row(
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(20.0),
            child: Padding(
              padding: const EdgeInsets.all(1.0),
              child: isChecked
                  ? Icon(ArtfulAgenda.check_closed, size: 18.0, color: Colors.grey[400])
                  : Icon(ArtfulAgenda.check_open, size: 18.0, color: Colors.grey[400]),
            ),
          ),
        ],
      ),
    );
  }
}