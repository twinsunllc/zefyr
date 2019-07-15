// Copyright (c) 2018, the Zefyr project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:notus/notus.dart';

import 'editable_box.dart';
import 'horizontal_rule.dart';
import 'image.dart';
import 'rich_text.dart';
import 'scope.dart';
import 'theme.dart';

/// Raw widget representing a single line of rich text document in Zefyr editor.
///
/// See [ZefyrParagraph] and [ZefyrHeading] which wrap this widget and
/// integrate it with current [ZefyrTheme].
class RawZefyrLine extends StatefulWidget {
  const RawZefyrLine({
    Key key,
    @required this.node,
    this.style,
    this.padding,
    this.textAlign,
  }) : super(key: key);

  final TextAlign textAlign;

  /// Line in the document represented by this widget.
  final LineNode node;

  /// Style to apply to this line. Required for lines with text contents,
  /// ignored for lines containing embeds.
  final TextStyle style;

  /// Padding to add around this paragraph.
  final EdgeInsets padding;

  @override
  _RawZefyrLineState createState() => new _RawZefyrLineState();
}

class _RawZefyrLineState extends State<RawZefyrLine> {
  final LayerLink _link = new LayerLink();
  bool _shouldAddStrikeThrough = false;

  @override
  Widget build(BuildContext context) {
    final scope = ZefyrScope.of(context);
    if (scope.isEditable) {
      ensureVisible(context, scope);
    }
    final theme = ZefyrTheme.of(context);

    Widget content;
    if (widget.node.hasEmbed) {
      content = buildEmbed(context, scope);
    } else {
      assert(widget.style != null);
      content = ZefyrRichText(
        node: widget.node,
        text: buildText(context),
        textAlign: (widget.textAlign == null) ? TextAlign.center : widget.textAlign,
      );
    }

    if (scope.isEditable) {
      content = EditableBox(
        child: content,
        node: widget.node,
        layerLink: _link,
        renderContext: scope.renderContext,
        showCursor: scope.showCursor,
        selection: scope.selection,
        selectionColor: theme.selectionColor,
        cursorColor: theme.cursorColor,
      );
      content = CompositedTransformTarget(link: _link, child: content);
    }

    if (widget.padding != null) {
      return Padding(padding: widget.padding, child: content);
    }
    return content;
  }

  void ensureVisible(BuildContext context, ZefyrScope scope) {
    if (scope.selection.isCollapsed &&
        widget.node.containsOffset(scope.selection.extentOffset)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        bringIntoView(context);
      });
    }
  }

  void addStrikeThrough(bool shouldAdd) {
    setState(() {
      _shouldAddStrikeThrough = shouldAdd;
    });
  }

  void bringIntoView(BuildContext context) {
    ScrollableState scrollable = Scrollable.of(context);
    final object = context.findRenderObject();
    assert(object.attached);
    final RenderAbstractViewport viewport = RenderAbstractViewport.of(object);
    assert(viewport != null);

    final double offset = scrollable.position.pixels;
    double target = viewport.getOffsetToReveal(object, 0.0).offset;
    if (target - offset < 0.0) {
      scrollable.position.jumpTo(target);
      return;
    }
    target = viewport.getOffsetToReveal(object, 1.0).offset;
    if (target - offset > 0.0) {
      scrollable.position.jumpTo(target);
    }
  }

  TextSpan buildText(BuildContext context) {
    final theme = ZefyrTheme.of(context);
    final List<TextSpan> children = widget.node.children
        .map((node) => _segmentToTextSpan(node, theme))
        .toList(growable: false);
    return new TextSpan(style: widget.style, children: children);
  }

  TextSpan _segmentToTextSpan(Node node, ZefyrThemeData theme) {
    final TextNode segment = node;
    final attrs = segment.style;

    return new TextSpan(
      text: segment.value,
      style: _getTextStyle(attrs, theme),
    );
  }

  TextStyle _getTextStyle(NotusStyle style, ZefyrThemeData theme) {
    TextStyle result = new TextStyle();
    if (style.containsSame(NotusAttribute.bold)) {
      result = result.merge(theme.boldStyle);
    }
    if (style.containsSame(NotusAttribute.underline)) {
      result = result.merge(theme.underlineStyle);
    }
    if (style.containsSame(NotusAttribute.italic)) {
      result = result.merge(theme.italicStyle);
    }
    if (style.containsSame(NotusAttribute.strikeThrough)) {
      result = result.merge(theme.strikeThroughStyle);
    }
    if (style.contains(NotusAttribute.link)) {
      result = result.merge(theme.linkStyle);
    }
    if (style.containsSame(NotusAttribute.size.small)) {
      result = result.merge(theme.smallSizeStyle);
    }
    if (style.containsSame(NotusAttribute.size.normal)) {
      result = result;
    }
    if (style.containsSame(NotusAttribute.size.large)) {
      result = result.merge(theme.largeSizeStyle);
    }
    if (style.containsSame(NotusAttribute.size.huge)) {
      result = result.merge(theme.hugeSizeStyle);
    }
    if (style.contains(NotusAttribute.textColor)) {
      NotusAttribute<String> attribute = style.get(NotusAttribute.textColor);
      if (attribute != null && attribute.value != null) {
        result = result.merge(new TextStyle(color: _getColorFromValue(attribute.value, isTextColor: true)));
      }
    }
    if (style.contains(NotusAttribute.backgroundColor)) {
      NotusAttribute<String> attribute = style.get(NotusAttribute.backgroundColor);
      if (attribute != null && attribute.value != null) {
        result = result.merge(new TextStyle(background: Paint()..color = _getColorFromValue(attribute.value)));
      }
    }
    return result;
  }

  Color _getColorFromValue(String value, {bool isTextColor = false}) {
    if (value == 'black' || value == 'white') {
      return (value == 'black') ? Colors.black : Colors.white;
    }

    List<int> rgbValues = _parseOutRgbValues(value);
    return Color.fromRGBO(rgbValues[0], rgbValues[1], rgbValues[2], (isTextColor) ?  1.0 : 1.0);
  }

  List<int> _parseOutRgbValues(String value) {
    String numbersString = value.substring(value.indexOf('(') + 1, value.indexOf(')'));
    List<String> values = numbersString.split(',');
    List<int> intRgbValues = [];
    for (var value in values) {
      int val = int.tryParse(value.trim()) ?? 0;
      intRgbValues.add(val);
    }
    return intRgbValues;
  }

  Widget buildEmbed(BuildContext context, ZefyrScope scope) {
    EmbedNode node = widget.node.children.single;
    EmbedAttribute embed = node.style.get(NotusAttribute.embed);

    if (embed.type == EmbedType.horizontalRule) {
      return ZefyrHorizontalRule(node: node);
    } else if (embed.type == EmbedType.image) {
      return ZefyrImage(node: node, delegate: scope.imageDelegate);
    } else {
      throw new UnimplementedError('Unimplemented embed type ${embed.type}');
    }
  }
}
