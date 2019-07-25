// Copyright (c) 2018, the Zefyr project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:notus/notus.dart';

import 'buttons.dart';
import 'scope.dart';
import 'theme.dart';

/// List of all button actions supported by [ZefyrToolbar] buttons.
enum ZefyrToolbarAction {
  bold,
  italic,
  underline,
  strikeThrough,
  //link,
  textAlignment,
  textAlignLeft,
  textAlignCenter,
  textAlignRight,
  textAlignJustify,
  size,
  sizeSmall,
  sizeNormal,
  sizeLarge,
  sizeHuge,
  //clipboardCopy,
  //openInBrowser,
  //heading,
  headingLevel2,
  bulletList,
  numberList,
  checklist,
  textColor,
  backgroundColor,
  // code,
  // quote,
  //horizontalRule,
  // image,
  // cameraImage,
  // galleryImage,
  //hideKeyboard,
  close,
}

final kZefyrToolbarAttributeActions = <ZefyrToolbarAction, NotusAttributeKey>{
  ZefyrToolbarAction.bold: NotusAttribute.bold,
  ZefyrToolbarAction.italic: NotusAttribute.italic,
  ZefyrToolbarAction.underline: NotusAttribute.underline,
  ZefyrToolbarAction.strikeThrough: NotusAttribute.strikeThrough,
  //ZefyrToolbarAction.link: NotusAttribute.link,
  ZefyrToolbarAction.textAlignment: NotusAttribute.alignment,
  ZefyrToolbarAction.textAlignLeft: NotusAttribute.alignment.al,
  ZefyrToolbarAction.textAlignCenter: NotusAttribute.alignment.ac,
  ZefyrToolbarAction.textAlignRight: NotusAttribute.alignment.ar,
  ZefyrToolbarAction.textAlignJustify: NotusAttribute.alignment.aj,
  ZefyrToolbarAction.size: NotusAttribute.size,
  ZefyrToolbarAction.sizeSmall: NotusAttribute.size.small,
  ZefyrToolbarAction.sizeNormal: NotusAttribute.size.normal,
  ZefyrToolbarAction.sizeLarge: NotusAttribute.size.large,
  ZefyrToolbarAction.sizeHuge: NotusAttribute.size.huge,
  // ZefyrToolbarAction.heading: NotusAttribute.heading,
  ZefyrToolbarAction.headingLevel2: NotusAttribute.heading.level2,
  ZefyrToolbarAction.bulletList: NotusAttribute.block.bulletList,
  ZefyrToolbarAction.numberList: NotusAttribute.block.numberList,
  ZefyrToolbarAction.checklist: NotusAttribute.block.checklistUnchecked,
  ZefyrToolbarAction.textColor: NotusAttribute.textColor,
  ZefyrToolbarAction.backgroundColor: NotusAttribute.backgroundColor,
  // ZefyrToolbarAction.code: NotusAttribute.block.code,
  // ZefyrToolbarAction.quote: NotusAttribute.block.quote,
  //ZefyrToolbarAction.horizontalRule: NotusAttribute.embed.horizontalRule,
};

/// Allows customizing appearance of [ZefyrToolbar].
abstract class ZefyrToolbarDelegate {
  /// Builds toolbar button for specified [action].
  ///
  /// Returned widget is usually an instance of [ZefyrButton].
  Widget buildButton(BuildContext context, ZefyrToolbarAction action,
      {VoidCallback onPressed});
}

/// Scaffold for [ZefyrToolbar].
class ZefyrToolbarScaffold extends StatelessWidget {
  const ZefyrToolbarScaffold({
    Key key,
    @required this.body,
    this.trailing,
    this.autoImplyTrailing: true,
    this.shrinkToolbar: false,
  }) : super(key: key);

  final Widget body;
  final Widget trailing;
  final bool autoImplyTrailing;
  final bool shrinkToolbar;

  @override
  Widget build(BuildContext context) {
    final theme = ZefyrTheme.of(context).toolbarTheme;
    final toolbar = ZefyrToolbar.of(context);
    final constraints =
        BoxConstraints.tightFor(height: ZefyrToolbar.kToolbarHeight);
    final children = <Widget>[
      (shrinkToolbar) ?
      Expanded(
        child: body,
      ): body,
    ];

    if (trailing != null) {
      children.add(trailing);
    } 
    // else if (autoImplyTrailing) {
    //   children.add(toolbar.buildButton(context, ZefyrToolbarAction.close));
    // }
    if (!shrinkToolbar) {
      return new Container(
        child: Material(color: theme.color, child: Wrap(children: children)),
      );
    }
    return new Container(
      constraints: constraints,
      child: Material(color: theme.color, child: Row(children: children)),
    );
  }
}

/// Toolbar for [ZefyrEditor].
class ZefyrToolbar extends StatefulWidget implements PreferredSizeWidget {
  static const kToolbarHeight = 30.0;

  const ZefyrToolbar({
    Key key,
    @required this.editor,
    this.autoHide: true,
    this.delegate,
    this.editorContext,
    this.shrinkToolbar = false,
  }) : super(key: key);

  final ZefyrToolbarDelegate delegate;
  final ZefyrScope editor;
  final BuildContext editorContext;
  final bool shrinkToolbar;

  /// Whether to automatically hide this toolbar when editor loses focus.
  final bool autoHide;

  static ZefyrToolbarState of(BuildContext context) {
    final _ZefyrToolbarScope scope =
        context.inheritFromWidgetOfExactType(_ZefyrToolbarScope);
    return scope?.toolbar;
  }

  @override
  ZefyrToolbarState createState() => ZefyrToolbarState();

  @override
  ui.Size get preferredSize => new Size.fromHeight(ZefyrToolbar.kToolbarHeight);
}

class _ZefyrToolbarScope extends InheritedWidget {
  _ZefyrToolbarScope({Key key, @required Widget child, @required this.toolbar})
      : super(key: key, child: child);

  final ZefyrToolbarState toolbar;

  @override
  bool updateShouldNotify(_ZefyrToolbarScope oldWidget) {
    return toolbar != oldWidget.toolbar;
  }
}

class ZefyrToolbarState extends State<ZefyrToolbar>
    with SingleTickerProviderStateMixin {
  final Key _toolbarKey = UniqueKey();
  final Key _overlayKey = UniqueKey();

  ZefyrToolbarDelegate _delegate;
  AnimationController _overlayAnimation;
  WidgetBuilder _overlayBuilder;
  Completer<void> _overlayCompleter;
  BuildContext editorContext;

  TextSelection _selection;

  void markNeedsRebuild() {
    setState(() {
      if (_selection != editor.selection) {
        _selection = editor.selection;
        closeOverlay();
      }
    });
  }

  Widget buildButton(BuildContext context, ZefyrToolbarAction action,
      {VoidCallback onPressed}) {
    return _delegate.buildButton(context, action, onPressed: onPressed);
  }

  Future<void> showOverlay(WidgetBuilder builder) async {
    assert(_overlayBuilder == null);
    final completer = new Completer<void>();
    setState(() {
      _overlayBuilder = builder;
      _overlayCompleter = completer;
      _overlayAnimation.forward();
    });
    return completer.future;
  }

  void closeOverlay() {
    if (!hasOverlay) return;
    _overlayAnimation.reverse().whenComplete(() {
      setState(() {
        _overlayBuilder = null;
        _overlayCompleter?.complete();
        _overlayCompleter = null;
      });
    });
  }

  bool get hasOverlay => _overlayBuilder != null;

  ZefyrScope get editor => widget.editor;

  @override
  void initState() {
    super.initState();
    _delegate = widget.delegate ?? new _DefaultZefyrToolbarDelegate(editorConext: widget.editorContext);
    _overlayAnimation = new AnimationController(
        vsync: this, duration: Duration(milliseconds: 100));
    _selection = editor.selection;
  }

  @override
  void didUpdateWidget(ZefyrToolbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.delegate != oldWidget.delegate) {
      _delegate = widget.delegate ?? new _DefaultZefyrToolbarDelegate(editorConext: widget.editorContext);
    }
  }

  @override
  void dispose() {
    _overlayAnimation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final layers = <Widget>[];

    // Must set unique key for the toolbar to prevent it from reconstructing
    // new state each time we toggle overlay.
    final toolbar = ZefyrToolbarScaffold(
      key: _toolbarKey,
      shrinkToolbar: widget.shrinkToolbar,
      body: Container(child: ZefyrButtonList(buttons: _buildButtons(context), shrinkToolbar: widget.shrinkToolbar,), decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(width: 1.0, color: Colors.grey[500])
        )
      ),),
      //trailing: buildButton(context, ZefyrToolbarAction.hideKeyboard),
    );

    if (hasOverlay) {
      Widget widget = new Builder(builder: _overlayBuilder);
      assert(widget != null);
      final overlay = FadeTransition(
        key: _overlayKey,
        opacity: _overlayAnimation,
        child: widget,
      );
      layers.add(overlay);
    }

    layers.add(toolbar);


    final constraints =
        BoxConstraints.tightFor(height: ZefyrToolbar.kToolbarHeight);
    return _ZefyrToolbarScope(
      toolbar: this,
        child: (widget.shrinkToolbar) ? Container(
          constraints: constraints,
          child: Stack(children: layers),
        ) : Column(children: layers),
    );
  }

  List<Widget> _buildButtons(BuildContext context) {
    final buttons = <Widget>[
      buildButton(context, ZefyrToolbarAction.bold),
      buildButton(context, ZefyrToolbarAction.italic),
      buildButton(context, ZefyrToolbarAction.underline),
      buildButton(context, ZefyrToolbarAction.strikeThrough),
      SizeButton(),
      buildButton(context, ZefyrToolbarAction.textColor),
      buildButton(context, ZefyrToolbarAction.backgroundColor),
      buildButton(context, ZefyrToolbarAction.headingLevel2),
      buildButton(context, ZefyrToolbarAction.textAlignLeft),
      buildButton(context, ZefyrToolbarAction.textAlignCenter),
      buildButton(context, ZefyrToolbarAction.textAlignRight),
      buildButton(context, ZefyrToolbarAction.textAlignJustify),
      // buildButton(context, ZefyrToolbarAction.sizeSmall),
      // buildButton(context, ZefyrToolbarAction.sizeNormal),
      // buildButton(context, ZefyrToolbarAction.sizeLarge),
      // buildButton(context, ZefyrToolbarAction.sizeHuge),
      //LinkButton(),
      //AlignmentButton(),
      buildButton(context, ZefyrToolbarAction.checklist),
      buildButton(context, ZefyrToolbarAction.bulletList),
      buildButton(context, ZefyrToolbarAction.numberList),
      // buildButton(context, ZefyrToolbarAction.quote),
      // buildButton(context, ZefyrToolbarAction.code),
      //buildButton(context, ZefyrToolbarAction.horizontalRule),
      //ImageButton(),
    ];
    return buttons;
  }
}

/// Scrollable list of toolbar buttons.
class ZefyrButtonList extends StatefulWidget {
  const ZefyrButtonList({Key key, @required this.buttons, this.shrinkToolbar = false}) : super(key: key);
  final List<Widget> buttons;
  final bool shrinkToolbar;

  @override
  _ZefyrButtonListState createState() => _ZefyrButtonListState();
}

class _ZefyrButtonListState extends State<ZefyrButtonList> {
  final ScrollController _controller = new ScrollController();

  @override
  void initState() {
    super.initState();
   // _controller.addListener(_handleScroll);
    // Workaround to allow scroll controller attach to our ListView so that
    // we can detect if overflow arrows need to be shown on init.
    // TODO: find a better way to detect overflow
    //Timer.run(_handleScroll);
  }

  @override
  Widget build(BuildContext context) {
    final theme = ZefyrTheme.of(context).toolbarTheme;
    final list = (widget.shrinkToolbar) ?
    ListView(
      scrollDirection: Axis.horizontal,
      controller: _controller,
      children: widget.buttons,
      physics: ClampingScrollPhysics(),
    ) : Wrap(
        spacing: -15.0,
        children: widget.buttons,
      );
    return list;
  }

  // void _handleScroll() {
  //   setState(() {
  //     _showLeftArrow =
  //         _controller.position.minScrollExtent != _controller.position.pixels;
  //     _showRightArrow =
  //         _controller.position.maxScrollExtent != _controller.position.pixels;
  //   });
  // }
}

class _DefaultZefyrToolbarDelegate implements ZefyrToolbarDelegate {
  static const kDefaultButtonIcons = {
    ZefyrToolbarAction.bold: Icons.format_bold,
    ZefyrToolbarAction.italic: Icons.format_italic,
    ZefyrToolbarAction.underline: Icons.format_underlined,
    ZefyrToolbarAction.strikeThrough: Icons.format_strikethrough,
    // ZefyrToolbarAction.link: Icons.link,
    // ZefyrToolbarAction.unlink: Icons.link_off,
    ZefyrToolbarAction.textAlignment: Icons.format_align_justify,
    ZefyrToolbarAction.textAlignLeft: Icons.format_align_left,
    ZefyrToolbarAction.textAlignCenter: Icons.format_align_center,
    ZefyrToolbarAction.textAlignRight: Icons.format_align_right,
    ZefyrToolbarAction.textAlignJustify: Icons.format_align_justify,
    ZefyrToolbarAction.size: Icons.format_size,
    //ZefyrToolbarAction.headingLevel2: Icons.format_size,
    //ZefyrToolbarAction.clipboardCopy: Icons.content_copy,
    //ZefyrToolbarAction.openInBrowser: Icons.open_in_new,
    //ZefyrToolbarAction.headingLevel2: Icons.format_size,
    ZefyrToolbarAction.bulletList: Icons.format_list_bulleted,
    ZefyrToolbarAction.numberList: Icons.format_list_numbered,
    ZefyrToolbarAction.checklist: Icons.check_circle,
    ZefyrToolbarAction.textColor: Icons.format_color_text,
    ZefyrToolbarAction.backgroundColor: Icons.format_color_fill,
    // ZefyrToolbarAction.code: Icons.code,
    // ZefyrToolbarAction.quote: Icons.format_quote,
    //ZefyrToolbarAction.horizontalRule: Icons.remove,
    // ZefyrToolbarAction.image: Icons.photo,
    // ZefyrToolbarAction.cameraImage: Icons.photo_camera,
    // ZefyrToolbarAction.galleryImage: Icons.photo_library,
    //ZefyrToolbarAction.hideKeyboard: Icons.keyboard_hide,
    ZefyrToolbarAction.close: Icons.close,
    //ZefyrToolbarAction.confirm: Icons.check,
  };

  static const kSpecialIconSizes = {
    //ZefyrToolbarAction.unlink: 20.0,
    //ZefyrToolbarAction.clipboardCopy: 20.0,
    ZefyrToolbarAction.headingLevel2: 20.0,
    ZefyrToolbarAction.sizeSmall: 40.0,
    ZefyrToolbarAction.sizeNormal: 40.0,
    ZefyrToolbarAction.sizeLarge: 40.0,
    ZefyrToolbarAction.sizeHuge: 40.0,
    ZefyrToolbarAction.close: 20.0,
    //ZefyrToolbarAction.confirm: 20.0,
  };

  static const kDefaultButtonTexts = {
    ZefyrToolbarAction.headingLevel2: 'H',
    ZefyrToolbarAction.sizeSmall: 'Small',
    ZefyrToolbarAction.sizeNormal: 'Normal',
    ZefyrToolbarAction.sizeLarge: 'Large',
    ZefyrToolbarAction.sizeHuge: 'Huge'
  };

  BuildContext editorConext;

  _DefaultZefyrToolbarDelegate({this.editorConext});

  @override
  Widget buildButton(BuildContext context, ZefyrToolbarAction action,
      {VoidCallback onPressed}) {
    final theme = Theme.of(context);
    if (kDefaultButtonIcons.containsKey(action)) {
      final icon = kDefaultButtonIcons[action];
      final size = kSpecialIconSizes[action];
      return ZefyrButton.icon(
        action: action,
        icon: icon,
        iconSize: size,
        onPressed: onPressed,
        editorContext: editorConext,
      );
    } else {
      final text = kDefaultButtonTexts[action];
      assert(text != null);
      final style = theme.textTheme.caption
          .copyWith(fontWeight: FontWeight.bold, fontSize: 14.0);
      return ZefyrButton.text(
        action: action,
        text: text,
        style: style,
        onPressed: onPressed,
        editorContext: editorConext,
      );
    }
  }
}
