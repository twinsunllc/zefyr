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

  ZefyrList({Key key, @required this.node, this.toggleList, this.onSnooze, this.onDelete}) : super(key: key);

  final BlockNode node;

  final List<String> secondNumberIndex = ['a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x','y','z'];
  final List<String> thirdNumberIndex = ['i','ii','iii','iv','v','vi','vii','viii','ix','x','xi','xii','xiii','xiv','xv','xvi','xvii','xviii','xix','xx','xxi','xxii','xxiii','xxiv','xxv','xxvi'];
  
  @override
  Widget build(BuildContext context) {
    final theme = ZefyrTheme.of(context);

    List<Widget> items = [];
    int index = 0;
    int indentOneIndex = 0;
    int indentTwoIndex = 0;
    int indentThreeIndex = 0;
    int indentFourIndex = 0;
    int indentFiveIndex = 0;
    int indentSixIndex = 0;
    int indentSevenIndex = 0;
    int indentEightIndex = 0;
    int indentNineIndex = 0;
    int indentTenIndex = 0;
    for (var line in node.children) {
      int indentLevel = getIndentLevel(line);
      String bulletText;
      if (indentLevel == 1) {
        // a.
        bulletText = '${secondNumberIndex[indentOneIndex]}';
      } else if (indentLevel == 2) {
        // i.
        bulletText = '${thirdNumberIndex[indentTwoIndex]}';
      } else if (indentLevel == 3) {
        // 1.
        bulletText = '${indentThreeIndex + 1}';
      } else if (indentLevel == 4) {
        // a.
        bulletText = '${secondNumberIndex[indentFourIndex]}';
      } else if (indentLevel == 5) {
        // i.
        bulletText = '${thirdNumberIndex[indentFiveIndex]}';
      } else if (indentLevel == 6) {
        // 1.
        bulletText = '${indentSixIndex + 1}';
      } else if (indentLevel == 7) {
        // a.
        bulletText = '${secondNumberIndex[indentSevenIndex]}';
      } else {
        bulletText = null;
      }
      items.add(_buildItem(line, index, node.style.get(NotusAttribute.block) == NotusAttribute.block.checklistChecked, indentLevel, bulletText));
      
      if (indentLevel == 0) {
        index++;
        indentOneIndex = 0;
        indentTwoIndex = 0;
        indentThreeIndex = 0;
        indentFourIndex = 0;
        indentFiveIndex = 0;
        indentSixIndex = 0;
        indentSevenIndex = 0;
      } else if (indentLevel == 1) {
        indentOneIndex++;
        indentTwoIndex = 0;
        indentThreeIndex = 0;
        indentFourIndex = 0;
        indentFiveIndex = 0;
        indentSixIndex = 0;
        indentSevenIndex = 0;
      } else if (indentLevel == 2) {
        indentTwoIndex++;
        indentThreeIndex = 0;
        indentFourIndex = 0;
        indentFiveIndex = 0;
        indentSixIndex = 0;
        indentSevenIndex = 0;
      } else if (indentLevel == 3) {
        indentThreeIndex++;
        indentFourIndex = 0;
        indentFiveIndex = 0;
        indentSixIndex = 0;
        indentSevenIndex = 0;
      } else if (indentLevel == 4) {
        indentFourIndex++;
        indentFiveIndex = 0;
        indentSixIndex = 0;
        indentSevenIndex = 0;
      } else if (indentLevel == 5) {
        indentFiveIndex++;
        indentSixIndex = 0;
        indentSevenIndex = 0;
      } else if (indentLevel == 6) {
        indentSixIndex++;
        indentSevenIndex = 0;
      } else if (indentLevel == 7) {
        indentSevenIndex++;
      }
    }

    final isNumberList =
        node.style.get(NotusAttribute.block) == NotusAttribute.block.numberList;
    final isChecklistList =
        node.style.get(NotusAttribute.block) == NotusAttribute.block.checklistChecked || node.style.get(NotusAttribute.block) == NotusAttribute.block.checklistUnchecked;
    EdgeInsets padding = isNumberList
        ? theme.blockTheme.numberList.padding
        : theme.blockTheme.bulletList.padding;
    padding = padding.copyWith(left: theme.indentSize);

    return new Padding(
      padding: EdgeInsets.only(left: (isChecklistList) ? 25.0 : 30.0),
      child: new Column(children: items),
    );
  }

  Widget _buildItem(Node node, int index, bool checked, int indentLevel, String bulletText) {
    LineNode line = node;
    return new ZefyrListItem(index: index, node: line, isChecked: checked, onChecked: toggleList, onSnooze: onSnooze, onDelete: onDelete, passedIndentLevel: indentLevel, passedBulletText: bulletText,);
  }

  int getIndentLevel(LineNode childNode) {
    if (childNode.style.contains(NotusAttribute.indent)) {
      NotusAttribute<String> attribute = childNode.style.get(NotusAttribute.indent);
      print('INDENT!!! Level: ${attribute.value}');
      return int.parse(attribute.value);
    }
    return 0;
  }
}

class ZefyrListItem extends StatelessWidget {
  final int index;
  final LineNode node;
  final bool isChecked;
  final Function(int) onChecked, onDelete;
  final Function(DateTime, int) onSnooze;
  final int passedIndentLevel;
  String passedBulletText;

  ZefyrListItem({Key key, this.isChecked = false, this.index, this.node, this.onChecked, this.onSnooze, this.onDelete, this.passedIndentLevel = 0, this.passedBulletText = ''}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    int numberIndex = index + 1;
    int indentLevel = passedIndentLevel;
    final BlockNode block = node.parent;
    final style = block?.style?.get(NotusAttribute.block);
    final TextAlign textAlign = (node.style.contains(NotusAttribute.alignment)) ? _getTextAlign(node.style) : TextAlign.start;
    final theme = ZefyrTheme.of(context);
    final bulletText =
        (style == NotusAttribute.block.bulletList) ? '•' : (style == NotusAttribute.block.numberList) ? (passedBulletText == null && passedBulletText != '') ? '$numberIndex.' : '$passedBulletText.' : '•';

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
        SizedBox(width: 18.0, child: Text(bulletText, style: textStyle)) :
        SizedBox(width: 28.0, child: Padding(
          padding: const EdgeInsets.only(right: 2.0),
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
      mainAxisAlignment: getAlignmentForListItem(textAlign),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        //bullet,
        Expanded(
          child: Padding(
            padding: new EdgeInsets.only(left: 30.0 * indentLevel),
            child: 
            //content,
            Row(
              mainAxisAlignment: getAlignmentForListItem(textAlign),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[bullet, Flexible(child: content)],
            ),
          ),
        ),
        snoozeButton, deleteButton
      ],
    );
  }

  void assignIndentLevel(NotusStyle style) {
    
  }

  MainAxisAlignment getAlignmentForListItem(TextAlign alignment) {
      switch(alignment) {
        case TextAlign.left:
          return MainAxisAlignment.start;
        case TextAlign.center: // Poppins
          return MainAxisAlignment.center;
        case TextAlign.right: // Shadows Into Light
          return MainAxisAlignment.end;
        default:
          return MainAxisAlignment.start;
      }
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
