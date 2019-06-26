// Copyright (c) 2018, the Zefyr project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'package:flutter/material.dart';
import 'package:notus/notus.dart';

import 'common.dart';
import 'paragraph.dart';
import 'theme.dart';

/// Represents number lists and bullet lists in a Zefyr editor.
class ZefyrList extends StatelessWidget {
  const ZefyrList({Key key, @required this.node}) : super(key: key);

  final BlockNode node;

  @override
  Widget build(BuildContext context) {
    final theme = ZefyrTheme.of(context);
    List<Widget> items = [];
    int index = 1;
    for (var line in node.children) {
      items.add(_buildItem(line, index));
      index++;
    }

    final isNumberList =
        node.style.get(NotusAttribute.block) == NotusAttribute.block.numberList;
    EdgeInsets padding = isNumberList
        ? theme.blockTheme.numberList.padding
        : theme.blockTheme.bulletList.padding;
    padding = padding.copyWith(left: theme.indentSize);

    return new Padding(
      padding: padding,
      child: new Column(children: items),
    );
  }

  Widget _buildItem(Node node, int index) {
    LineNode line = node;
    return new ZefyrListItem(index: index, node: line);
  }
}

/// An item in a [ZefyrList].
class ZefyrListItem extends StatelessWidget {
  ZefyrListItem({Key key, this.index, this.node}) : super(key: key);

  final int index;
  final LineNode node;

  @override
  Widget build(BuildContext context) {
    final BlockNode block = node.parent;
    final style = block.style.get(NotusAttribute.block);
    final TextAlign textAlign = (node.style.contains(NotusAttribute.alignment)) ? _getTextAlign(node.style) : TextAlign.start;
    final theme = ZefyrTheme.of(context);
    final bulletText =
        (style == NotusAttribute.block.bulletList) ? '•' : (style == NotusAttribute.block.numberList) ? '$index.' : '';

    TextStyle textStyle;
    Widget content;
    EdgeInsets padding;

    if (node.style.contains(NotusAttribute.heading)) {
      final headingTheme = ZefyrHeading.themeOf(node, context);
      textStyle = headingTheme.textStyle;
      padding = headingTheme.padding;
      content = new ZefyrHeading(node: node, textAlign: textAlign,);
    } else {
      textStyle = theme.paragraphTheme.textStyle;
      content = new RawZefyrLine(node: node, style: textStyle, textAlign: textAlign);
    }

    Widget bullet = (style != NotusAttribute.block.checklist) ?
        SizedBox(width: 24.0, child: Text(bulletText, style: textStyle)) : 
        SizedBox(width: 24.0, child: Padding(
          padding: const EdgeInsets.only(right: 12.0),
          child: Checkbox(value: true, onChanged: (bool) {},),
        ));
    if (padding != null) {
      bullet = Padding(padding: padding, child: bullet);
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[bullet, Expanded(child: content)],
    );
  }

  TextAlign _getTextAlign(NotusStyle style) {
    if (_doesContainAttribute(style, NotusAttribute.alignment.ac)) {
      return TextAlign.center;
    } else if (_doesContainAttribute(style, NotusAttribute.alignment.ar)) {
      return TextAlign.right;
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
