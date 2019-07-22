// Copyright (c) 2018, the Zefyr project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:collection';

import 'package:flutter/cupertino.dart';
import 'package:flutter/widgets.dart';
import 'package:notus/notus.dart';

import 'code.dart';
import 'common.dart';
import 'controller.dart';
import 'cursor_timer.dart';
import 'editor.dart';
import 'image.dart';
import 'input.dart';
import 'list.dart';
import 'paragraph.dart';
import 'quote.dart';
import 'render_context.dart';
import 'scope.dart';
import 'selection.dart';
import 'theme.dart';

/// Core widget responsible for editing Zefyr documents.
///
/// Depends on presence of [ZefyrTheme] and [ZefyrScope] somewhere up the
/// widget tree.
///
/// Consider using [ZefyrEditor] which wraps this widget and adds a toolbar to
/// edit style attributes.
class ZefyrEditableText extends StatefulWidget {
  const ZefyrEditableText({
    Key key,
    @required this.controller,
    @required this.focusNode,
    @required this.imageDelegate,
    this.autofocus: true,
    this.enabled: true,
    this.padding: const EdgeInsets.symmetric(horizontal: 16.0),
    this.physics,
    this.onCheckboxToggled,
    this.onSnooze,
    this.showCheckListDelete = false,
  }) : super(key: key);

  final ZefyrController controller;
  final FocusNode focusNode;
  final ZefyrImageDelegate imageDelegate;
  final bool autofocus;
  final bool enabled;
  final ScrollPhysics physics;
  final VoidCallback onCheckboxToggled;
  final Function(DateTime, String, bool) onSnooze;
  final bool showCheckListDelete;

  /// Padding around editable area.
  final EdgeInsets padding;

  @override
  _ZefyrEditableTextState createState() => new _ZefyrEditableTextState();
}

class _ZefyrEditableTextState extends State<ZefyrEditableText>
    with AutomaticKeepAliveClientMixin {
  //
  // New public members
  //

  /// Focus node of this widget.
  FocusNode get focusNode => widget.focusNode;

  /// Document controlled by this widget.
  NotusDocument get document => widget.controller.document;

  /// Current text selection.
  TextSelection get selection => widget.controller.selection;

  /// Express interest in interacting with the keyboard.
  ///
  /// If this control is already attached to the keyboard, this function will
  /// request that the keyboard become visible. Otherwise, this function will
  /// ask the focus system that it become focused. If successful in acquiring
  /// focus, the control will then attach to the keyboard and request that the
  /// keyboard become visible.
  void requestKeyboard() {
    if (focusNode.hasFocus)
      _input.openConnection(widget.controller.plainTextEditingValue);
    else
      FocusScope.of(context).requestFocus(focusNode);
  }

  void focusOrUnfocusIfNeeded() {
    if (!_didAutoFocus && widget.autofocus && widget.enabled) {
      FocusScope.of(context).autofocus(focusNode);
      _didAutoFocus = true;
    }
    if (!widget.enabled && focusNode.hasFocus) {
      _didAutoFocus = false;
      focusNode.unfocus();
    }
  }

  //
  // Overridden members of State
  //

  @override
  Widget build(BuildContext context) {
    FocusScope.of(context).reparentIfNeeded(focusNode);
    super.build(context); // See AutomaticKeepAliveState.

    Widget body = ListBody(children: _buildChildren(context));
    if (widget.padding != null) {
      body = new Padding(padding: widget.padding, child: body);
    }
    final scrollable = SingleChildScrollView(
      physics: widget.physics,
      controller: _scrollController,
      child: body,
    );

    final overlay = Overlay.of(context, debugRequiredFor: widget);
    final layers = <Widget>[scrollable];
    if (widget.enabled) {
      layers.add(ZefyrSelectionOverlay(
        controller: widget.controller,
        controls: cupertinoTextSelectionControls,
        overlay: overlay,
      ));
    }

    return Stack(fit: StackFit.expand, children: layers);
  }

  @override
  void initState() {
    super.initState();
    _input = new InputConnectionController(_handleRemoteValueChange);
    _updateSubscriptions();
  }

  @override
  void didUpdateWidget(ZefyrEditableText oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateSubscriptions(oldWidget);
    focusOrUnfocusIfNeeded();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final scope = ZefyrScope.of(context);
    if (_renderContext != scope.renderContext) {
      _renderContext?.removeListener(_handleRenderContextChange);
      _renderContext = scope.renderContext;
      _renderContext.addListener(_handleRenderContextChange);
    }
    if (_cursorTimer != scope.cursorTimer) {
      _cursorTimer?.stop();
      _cursorTimer = scope.cursorTimer;
      _cursorTimer.startOrStop(focusNode, selection);
    }
    focusOrUnfocusIfNeeded();
  }

  @override
  void dispose() {
    _cancelSubscriptions();
    super.dispose();
  }

  //
  // Overridden members of AutomaticKeepAliveClientMixin
  //

  @override
  bool get wantKeepAlive => focusNode.hasFocus;

  //
  // Private members
  //

  final ScrollController _scrollController = ScrollController();
  ZefyrRenderContext _renderContext;
  CursorTimer _cursorTimer;
  InputConnectionController _input;
  bool _didAutoFocus = false;

  List<Widget> _buildChildren(BuildContext context) {
    final result = <Widget>[];
    for (var node in document.root.children) {
      result.add(_defaultChildBuilder(context, node));
    }
    return result;
  }

  Widget _defaultChildBuilder(BuildContext context, Node node) {
    if (node is LineNode) {
      if (node.hasEmbed) {
        return new RawZefyrLine(node: node);
      } else if (node.style.contains(NotusAttribute.heading)) {
        if (node.style.contains(NotusAttribute.alignment)) {
          return ZefyrHeading(node: node, textAlign: _getTextAlign(node.style),);
        }
        return new ZefyrHeading(node: node, textAlign: TextAlign.start,);
      }
      if (node.style.contains(NotusAttribute.alignment)) {
        return ZefyrParagraph(node: node, textAlign: _getTextAlign(node.style),);
      }
      return new ZefyrParagraph(node: node, textAlign: TextAlign.start,);
    }

    final BlockNode block = node;

    final blockStyle = block.style.get(NotusAttribute.block);
    if (blockStyle == NotusAttribute.block.code) {
      return new ZefyrCode(node: block);
    } else if (blockStyle == NotusAttribute.block.bulletList) {
      return new ZefyrList(node: block);
    } else if (blockStyle == NotusAttribute.block.checklistChecked) {
      return new ZefyrList(node: block,
        toggleList: (index) {
          widget.controller.formatText(block.children.elementAt(index).documentOffset, 0, NotusAttribute.block.checklistUnchecked);
          if(widget.onCheckboxToggled != null)
            widget.onCheckboxToggled();
        },
        onSnooze: (date, index){
          if(widget.onSnooze != null)
            widget.onSnooze(date, block.children.elementAt(index).toPlainText(), true);
        },
        onDelete: widget.showCheckListDelete ? (index){
          widget.controller.replaceText(block.children.elementAt(index).documentOffset, block.children.elementAt(index).length, '');
        } : null,
      );
    } else if (blockStyle == NotusAttribute.block.checklistUnchecked) {
      return new ZefyrList(node: block,
        toggleList: (index) {
          widget.controller.formatText(block.children.elementAt(index).documentOffset, 0, NotusAttribute.block.checklistChecked);
          if(widget.onCheckboxToggled != null)
            widget.onCheckboxToggled();
        },
        onSnooze: (date, index){
          print('snoozing ${block.children.elementAt(index).toPlainText()}');
          if(widget.onSnooze != null)
            widget.onSnooze(date, block.children.elementAt(index).toPlainText(), false);
        },
        onDelete: widget.showCheckListDelete ? (index){
           widget.controller.replaceText(block.children.elementAt(index).documentOffset, block.children.elementAt(index).length, '');
        } : null,
      );
    } else if (blockStyle == NotusAttribute.block.numberList) {
      return new ZefyrList(node: block);
    } else if (blockStyle == NotusAttribute.block.quote) {
      return new ZefyrQuote(node: block);
    }

    throw new UnimplementedError('Block format $blockStyle.');
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
    return style.containsSame(attribute);
  }

  void _updateSubscriptions([ZefyrEditableText oldWidget]) {
    if (oldWidget == null) {
      widget.controller.addListener(_handleLocalValueChange);
      focusNode.addListener(_handleFocusChange);
      return;
    }

    if (widget.controller != oldWidget.controller) {
      oldWidget.controller.removeListener(_handleLocalValueChange);
      widget.controller.addListener(_handleLocalValueChange);
      _input.updateRemoteValue(widget.controller.plainTextEditingValue);
    }
    if (widget.focusNode != oldWidget.focusNode) {
      oldWidget.focusNode.removeListener(_handleFocusChange);
      widget.focusNode.addListener(_handleFocusChange);
      updateKeepAlive();
    }
  }

  void _cancelSubscriptions() {
    _renderContext.removeListener(_handleRenderContextChange);
    widget.controller.removeListener(_handleLocalValueChange);
    focusNode.removeListener(_handleFocusChange);
    _input.closeConnection();
    _cursorTimer.stop();
  }

  // Triggered for both text and selection changes.
  void _handleLocalValueChange() {
    if (widget.enabled &&
        widget.controller.lastChangeSource == ChangeSource.local) {
      // Only request keyboard for user actions.
      requestKeyboard();
    }
    _input.updateRemoteValue(widget.controller.plainTextEditingValue);
    //_cursorTimer.startOrStop(focusNode, selection);
    _cursorTimer.stop();
    _cursorTimer.start();
    setState(() {
      // nothing to update internally.
    });
  }

  void _handleFocusChange() {
    _input.openOrCloseConnection(
        focusNode, widget.controller.plainTextEditingValue);
    _cursorTimer.startOrStop(focusNode, selection);
    updateKeepAlive();
  }

  void _handleRemoteValueChange(
      int start, String deleted, String inserted, TextSelection selection) {
    widget.controller
        .replaceText(start, deleted.length, inserted, selection: selection);
  }

  void _handleRenderContextChange() {
    setState(() {
      // nothing to update internally.
    });
  }
}
