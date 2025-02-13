import 'package:flutter/material.dart';
import 'package:zefyr/views/helpers/artful_agenda_icons.dart';

class DeleteButton extends StatelessWidget {
  final VoidCallback onDelete;

  DeleteButton({this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 0.0),
      height: 21.0,
      child: Row(
        children: [
          Listener(
            onPointerDown: (event){
              print("delete has been tapped");
              onDelete();
            },
            child: InkWell(
              borderRadius: BorderRadius.circular(20.0),
              child: Padding(
                padding: const EdgeInsets.all(1.0),
                child: Icon(ArtfulAgenda.trash_empty, size: 18.0, color: Colors.grey[400])
              ),
            ),
          ),
        ],
      ),
    );
  }
}