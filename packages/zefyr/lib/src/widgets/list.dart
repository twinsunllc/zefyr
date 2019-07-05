// Copyright (c) 2018, the Zefyr project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'package:flutter/material.dart';
import 'package:notus/notus.dart';
import 'package:zefyr/src/widgets/checklist_item_box.dart';
import 'package:zefyr/src/widgets/delete_button.dart';
import 'package:zefyr/src/widgets/snooze_button.dart';

import 'common.dart';
import 'paragraph.dart';
import 'theme.dart';

/// Represents number lists and bullet lists in a Zefyr editor.
class ZefyrList extends StatelessWidget {

  final Function(int) toggleList, onDelete;
  final Function(DateTime, int) onSnooze;

  const ZefyrList({Key key, @required this.node, this.toggleList, this.onSnooze, this.onDelete}) : super(key: key);

  final BlockNode node;

  @override
  Widget build(BuildContext context) {
    final theme = ZefyrTheme.of(context);

    List<Widget> items = [];
    int index = 0;
    for (var line in node.children) {
      items.add(_buildItem(line, index, node.style.get(NotusAttribute.block) == NotusAttribute.block.checklistChecked));
      index++;
    }

    final isNumberList =
        node.style.get(NotusAttribute.block) == NotusAttribute.block.numberList;
    EdgeInsets padding = isNumberList
        ? theme.blockTheme.numberList.padding
        : theme.blockTheme.bulletList.padding;
    padding = padding.copyWith(left: theme.indentSize);

    return new Padding(
      padding: EdgeInsets.all(0.0),
      child: new Column(children: items),
    );
  }

  Widget _buildItem(Node node, int index, bool checked) {
    LineNode line = node;
    return new ZefyrListItem(index: index, node: line, isChecked: checked, onChecked: toggleList, onSnooze: onSnooze, onDelete: onDelete,);
  }
}

class ZefyrListItem extends StatelessWidget {
  final int index;
  final LineNode node;
  final bool isChecked;
  final Function(int) onChecked, onDelete;
  final Function(DateTime, int) onSnooze;

  ZefyrListItem({Key key, this.isChecked = false, this.index, this.node, this.onChecked, this.onSnooze, this.onDelete}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    int numberIndex = index + 1;
    if (node.style.contains(NotusAttribute.textColor)) {
      print('Contains Text Color');
    }
    final BlockNode block = node.parent;
    final style = block?.style?.get(NotusAttribute.block);
    final TextAlign textAlign = (node.style.contains(NotusAttribute.alignment)) ? _getTextAlign(node.style) : TextAlign.start;
    final theme = ZefyrTheme.of(context);
    final bulletText =
        (style == NotusAttribute.block.bulletList) ? '•' : (style == NotusAttribute.block.numberList) ? '$numberIndex.' : '•';

    TextStyle textStyle;
    Widget content;
    EdgeInsets padding;

    if (node.style.contains(NotusAttribute.heading)) {
      final headingTheme = ZefyrHeading.themeOf(node, context);
      if (style != NotusAttribute.block.checklistChecked && style != NotusAttribute.block.checklistUnchecked) {
        textStyle = headingTheme.textStyle;
      } else {
        textStyle = (!isChecked) ? headingTheme.textStyle : theme.strikeThrough;
      }
      padding = headingTheme.padding;
      content = new ZefyrHeading(node: node, textAlign: textAlign,);
    } else {
      if (style != NotusAttribute.block.checklistChecked && style != NotusAttribute.block.checklistUnchecked) {
        textStyle = theme.paragraphTheme.textStyle;
      } else {
        textStyle = (!isChecked) ? theme.paragraphTheme.textStyle : theme.strikeThrough;
      }
      content = new RawZefyrLine(node: node, style: textStyle, textAlign: textAlign);
    }

    Widget bullet = (style != NotusAttribute.block.checklistChecked && style != NotusAttribute.block.checklistUnchecked) ?
        SizedBox(width: 28.0, child: Text(bulletText, style: textStyle)) :
        SizedBox(width: 28.0, child: Padding(
          padding: const EdgeInsets.only(right: 4.0),
          child: ChecklistItemBox(isChecked: isChecked, onToggle: () {
            onChecked(index);
          })),
        );
    if (padding != null) {
      bullet = Padding(padding: padding, child: bullet);
    }

    Widget snoozeButton = (onSnooze == null) ? Container() : SizedBox(width: 28.0, child: Padding(
          padding: const EdgeInsets.only(right: 4.0),
          child: SnoozeButton(onSnooze: (DateTime snoozeDate) {
            if(onSnooze != null){
              onSnooze(snoozeDate, index);
            }
          })),
        );
    if (padding != null) {
      bullet = Padding(padding: padding, child: bullet);
    }

    Widget deleteButton = (onDelete == null) ? Container() : SizedBox(width: 28.0, child: Padding(
          padding: const EdgeInsets.only(right: 4.0),
          child: DeleteButton(onDelete: () {
            if(onDelete != null){
              onDelete(index);
            }
          })),
        );
    if (padding != null) {
      bullet = Padding(padding: padding, child: bullet);
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[bullet, Expanded(child: content), snoozeButton, deleteButton],
    );
  }

  TextAlign _getTextAlign(NotusStyle style) {
    if (_doesContainAttribute(style, NotusAttribute.alignment.ac)) {
      return TextAlign.center;
    } else if (_doesContainAttribute(style, NotusAttribute.alignment.ar)) {
      return TextAlign.right;
    } else if (_doesContainAttribute(style, NotusAttribute.alignment.al)) {
      return TextAlign.left;
    } else if (_doesContainAttribute(style, NotusAttribute.alignment.al)) {
      return TextAlign.justify;
    }
    return TextAlign.start;
  }

  bool _doesContainAttribute(NotusStyle style, NotusAttribute attribute) {
    if (style.containsSame(attribute)) {
      return true;
    }
    return false;
  }
}
