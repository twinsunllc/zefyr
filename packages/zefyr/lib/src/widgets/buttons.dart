// Copyright (c) 2018, the Zefyr project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:notus/notus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_colorpicker/grid_picker.dart';
import 'scope.dart';
import 'theme.dart';
import 'toolbar.dart';

/// A button used in [ZefyrToolbar].
///
/// Create an instance of this widget with [ZefyrButton.icon] or
/// [ZefyrButton.text] constructors.
///
/// Toolbar buttons are normally created by a [ZefyrToolbarDelegate].
/// 
Color fromHexString(String hexString) => Color(
                                int.parse(hexString.substring(1),
                                    radix: 16),
                              ).withOpacity(1.0);

  List<Color> pickerColors = [
  Colors.white,
  fromHexString('#000000'),
  fromHexString('#ab3a72'),
  fromHexString('#ff5cc7'),
  fromHexString('#fe0156'),
  fromHexString('#d40000'),
  fromHexString('#ff2800'),
  fromHexString('#e0403d'),
  fromHexString('#f1592a'),
  fromHexString('#f4811f'),
  fromHexString('#f8ad19'),
  fromHexString('#ecc320'),
  fromHexString('#ffdf15'),
  fromHexString('#ede41d'),
  fromHexString('#00864e'),
  fromHexString('#29b573'),
  fromHexString('#4da42a'),
  fromHexString('#007f7f'),
  fromHexString('#53bcbd'),
  fromHexString('#01d2b0'),
  fromHexString('#334aa3'),
  fromHexString('#4379ba'),
  fromHexString('#7c9dd2'),
  fromHexString('#61365f'),
  fromHexString('#684e93'),
  fromHexString('#7f3f98'),
];

class ZefyrButton extends StatefulWidget {
  /// Creates a toolbar button with an icon.
  ZefyrButton.icon({
    @required this.action,
    @required IconData icon,
    double iconSize,
    this.onPressed,
    this.editorContext,
  })  : assert(action != null),
        assert(icon != null),
        _icon = icon,
        _iconSize = iconSize,
        _text = null,
        _textStyle = null,
        super();

  /// Creates a toolbar button containing text.
  ///
  /// Note that [ZefyrButton] has fixed width and does not expand to accommodate
  /// long texts.
  ZefyrButton.text({
    @required this.action,
    @required String text,
    TextStyle style,
    this.onPressed,
    this.editorContext,
  })  : assert(action != null),
        assert(text != null),
        _icon = null,
        _iconSize = null,
        _text = text,
        _textStyle = style,
        super();

  /// Toolbar action associated with this button.
  final ZefyrToolbarAction action;
  final IconData _icon;
  final double _iconSize;
  final String _text;
  final TextStyle _textStyle;
  final BuildContext editorContext;

  /// Callback to trigger when this button is tapped.
  final VoidCallback onPressed;

  @override
  _ZefyrButtonState createState() => _ZefyrButtonState();
}

class _ZefyrButtonState extends State<ZefyrButton> {

  ZefyrScope savedEditor;
  bool pickerIsShowing = false;
  TextSelection storedTextSelection;
  bool isTextColorAttribute = false;

  bool get isAttributeAction {
    return kZefyrToolbarAttributeActions.keys.contains(widget.action);
  }

  @override
  Widget build(BuildContext context) {
    final toolbar = ZefyrToolbar.of(context);
    final editor = toolbar.editor;
    final toolbarTheme = ZefyrTheme.of(context).toolbarTheme;
    final pressedHandler = _getPressedHandler(editor, toolbar);
    final iconColor = (pressedHandler == null)
        ? toolbarTheme.disabledIconColor
        : toolbarTheme.iconColor;
    if (widget._icon != null) {
      return RawZefyrButton.icon(
        action: widget.action,
        icon: widget._icon,
        size: widget._iconSize,
        iconColor: iconColor,
        color: _getColor(editor, toolbarTheme),
        onPressed: _getPressedHandler(editor, toolbar),
      );
    } else {
      assert(widget._text != null);
      var style = widget._textStyle ?? new TextStyle();
      style = style.copyWith(color: iconColor);
      return RawZefyrButton(
        action: widget.action,
        child: new Text(widget._text, style: style),
        color: _getColor(editor, toolbarTheme),
        onPressed: _getPressedHandler(editor, toolbar),
      );
    }
  }

  Color _getColor(ZefyrScope editor, ZefyrToolbarTheme theme) {
    if (isAttributeAction) {
      final attribute = kZefyrToolbarAttributeActions[widget.action];
      final isToggled = (attribute is NotusAttribute)
          ? editor.selectionStyle.containsSame(attribute)
          : editor.selectionStyle.contains(attribute);
      return isToggled || editor.toggledStyles.contains(attribute) ? theme.toggleColor : null;
    }
    return null;
  }

  void _onColorChanged(Color color) {
    var attr = NotusAttribute.fromKeyValue((isTextColorAttribute) ? "text-color" : "background-color", "rgb(${color.red}, ${color.green}, ${color.blue})");
    _toggleAttribute(attr, savedEditor);
  }

  VoidCallback _getPressedHandler(
      ZefyrScope editor, ZefyrToolbarState toolbar) {
    if (widget.onPressed != null) {
      return widget.onPressed;
    } else if (isAttributeAction) {
      final attribute = kZefyrToolbarAttributeActions[widget.action];
      if (attribute is NotusAttribute) {
        if (attribute.key == NotusAttribute.textColor.key || attribute.key == NotusAttribute.backgroundColor.key){
          isTextColorAttribute = (attribute.key == NotusAttribute.textColor.key);
          return () => _showColorPickerDialog(widget.editorContext, editor, _onColorChanged);
        }
        return () => _toggleAttribute(attribute, editor);
      }
    } 
    else if (widget.action == ZefyrToolbarAction.close) {
      return () => toolbar.closeOverlay();
    } 
    // else if (widget.action == ZefyrToolbarAction.hideKeyboard) {
    //   return () => editor.hideKeyboard();
    // }

    return null;
  }

  void _toggleAttribute(NotusAttribute attribute, ZefyrScope editor) {
    final isToggled = editor.toggledStyles.contains(attribute);
    if (isToggled) {
      editor.toggleOffStyle(attribute);
    } else {
      editor.toggleOnStyle(attribute);
    }
    var isTextToggled = editor.selectionStyle.containsSame(attribute);
    if (isTextToggled) {
      editor.toggleOffStyle(attribute);
      (storedTextSelection == null) ? editor.formatSelection(attribute.unset) : editor.formatSelection(attribute.unset, selectedText: storedTextSelection);
    } else {
      editor.toggleOnStyle(attribute);
      (storedTextSelection == null) ? editor.formatSelection(attribute) : editor.formatSelection(attribute, selectedText: storedTextSelection);
    }
    storedTextSelection = null;
    setState(() {
    });
  }

  void _showColorPickerDialog(BuildContext editorContext, ZefyrScope editor, Function(Color) onColorChanged) {
    savedEditor = editor;
    pickerIsShowing = true;

    if (editor.controller.getSelectedText() != null) {
      storedTextSelection = editor.controller.getSelectedText();
    }

    showDialog<dynamic>(
      context: editorContext,
      builder: (BuildContext context) {
        return AlertDialog(
          titlePadding: EdgeInsets.all(0.0),
          contentPadding: EdgeInsets.all(0.0),
          content: SingleChildScrollView(
            child: GridPicker(
              pickerColor: (isTextColorAttribute) ? Colors.black : Colors.white,
              onColorChanged: (Color color) {
                Navigator.pop(context);
                onColorChanged(color);
              },
              enableLabel: false,
              showHexInput: false,
              availableColors: pickerColors,
            ),
          ),
        );
      },
    );
  }
}

/// Raw button widget used by [ZefyrToolbar].
///
/// See also:
///
///   * [ZefyrButton], which wraps this widget and implements most of the
///     action-specific logic.
class RawZefyrButton extends StatelessWidget {
  const RawZefyrButton({
    Key key,
    @required this.action,
    @required this.child,
    @required this.color,
    @required this.onPressed,
  }) : super(key: key);

  /// Creates a [RawZefyrButton] containing an icon.
  RawZefyrButton.icon({
    @required this.action,
    @required IconData icon,
    double size,
    Color iconColor,
    @required this.color,
    @required this.onPressed,
  })  : child = new Icon(icon, size: size, color: iconColor),
        super();

  /// Toolbar action associated with this button.
  final ZefyrToolbarAction action;

  /// Child widget to show inside this button. Usually an icon.
  final Widget child;

  /// Background color of this button.
  final Color color;

  /// Callback to trigger when this button is pressed.
  final VoidCallback onPressed;

  /// Returns `true` if this button is currently toggled on.
  bool get isToggled => color != null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = theme.buttonTheme.constraints.minHeight + 4.0;
    final constraints = theme.buttonTheme.constraints.copyWith(minWidth: width, maxHeight: theme.buttonTheme.constraints.minHeight);
    // final width = theme.buttonTheme.constraints.minHeight + 0.0;
    // final constraints = BoxConstraints.tight(Size(30.0, 30.0));
    final radius = BorderRadius.all(Radius.circular(3.0));
    return RawMaterialButton(
      shape: RoundedRectangleBorder(borderRadius: radius),
      elevation: 0.0,
      fillColor: color,
      constraints: constraints,
      onPressed: onPressed,
      child: child,
    );
  }
}

/// Controls heading styles.
///
/// When pressed, this button displays overlay toolbar with three
/// buttons for each heading level.
class HeadingButton extends StatefulWidget {
  const HeadingButton({Key key}) : super(key: key);

  @override
  _HeadingButtonState createState() => _HeadingButtonState();
}

class _HeadingButtonState extends State<HeadingButton> {
  @override
  Widget build(BuildContext context) {
    final toolbar = ZefyrToolbar.of(context);
    // return toolbar.buildButton(
    //   context,
    //   ZefyrToolbarAction.heading,
    //   onPressed: showOverlay,
    // );
  }

  // void showOverlay() {
  //   final toolbar = ZefyrToolbar.of(context);
  //   toolbar.showOverlay(buildOverlay);
  // }

  // Widget buildOverlay(BuildContext context) {
  //   final toolbar = ZefyrToolbar.of(context);
  //   final buttons = Row(
  //     children: <Widget>[
  //       SizedBox(width: 8.0),
  //       toolbar.buildButton(context, ZefyrToolbarAction.headingLevel2),
  //     ],
  //   );
  //   return ZefyrToolbarScaffold(body: buttons);
  // }
}

class AlignmentButton extends StatefulWidget {
  const AlignmentButton({Key key}) : super(key: key);

  @override
  _AlignmentButtonState createState() => _AlignmentButtonState();
}

class _AlignmentButtonState extends State<AlignmentButton> {
  @override
  Widget build(BuildContext context) {
    final toolbar = ZefyrToolbar.of(context);
    return toolbar.buildButton(
      context,
      ZefyrToolbarAction.textAlignment,
      onPressed: showOverlay,
    );
  }

  void showOverlay() {
    final toolbar = ZefyrToolbar.of(context);
    toolbar.showOverlay(buildOverlay);
  }

  Widget buildOverlay(BuildContext context) {
    final toolbar = ZefyrToolbar.of(context);
    final buttons = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        SizedBox(width: 8.0),
        toolbar.buildButton(context, ZefyrToolbarAction.textAlignLeft),
        toolbar.buildButton(context, ZefyrToolbarAction.textAlignCenter),
        toolbar.buildButton(context, ZefyrToolbarAction.textAlignRight),
        toolbar.buildButton(context, ZefyrToolbarAction.textAlignJustify),
      ],
    );
    return ZefyrToolbarScaffold(body: buttons);
  }
}

class SizeButton extends StatefulWidget {
  const SizeButton({Key key}) : super(key: key);

  @override
  _SizeButtonState createState() => _SizeButtonState();
}

class _SizeButtonState extends State<SizeButton> {

  @override
  Widget build(BuildContext context) {
    final toolbar = ZefyrToolbar.of(context);
    return toolbar.buildButton(
      context,
      ZefyrToolbarAction.size,
      onPressed: showOverlay,
    );
  }

  void showOverlay() {
    final toolbar = ZefyrToolbar.of(context);
    toolbar.showOverlay(buildOverlay);
  }

  Widget buildOverlay(BuildContext context) {
    final toolbar = ZefyrToolbar.of(context);
    final buttons = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      //mainAxisSize: MainAxisSize.max,
      children: <Widget>[
        toolbar.buildButton(context, ZefyrToolbarAction.sizeSmall),
        SizedBox(width: 10.0,),
        toolbar.buildButton(context, ZefyrToolbarAction.sizeNormal),
        SizedBox(width: 10.0,),
        toolbar.buildButton(context, ZefyrToolbarAction.sizeLarge),
        SizedBox(width: 10.0,),
        toolbar.buildButton(context, ZefyrToolbarAction.sizeHuge),
        SizedBox(width: 10.0,),
        toolbar.buildButton(context, ZefyrToolbarAction.close),
      ],
    );
    return ZefyrToolbarScaffold(body: buttons);
  }
}

/// Controls image attribute.
///
/// When pressed, this button displays overlay toolbar with three
/// buttons for each heading level.
// class ImageButton extends StatefulWidget {
//   const ImageButton({Key key}) : super(key: key);

//   @override
//   _ImageButtonState createState() => _ImageButtonState();
// }

// class _ImageButtonState extends State<ImageButton> {
//   @override
//   Widget build(BuildContext context) {
//     final toolbar = ZefyrToolbar.of(context);
//     return toolbar.buildButton(
//       context,
//       ZefyrToolbarAction.image,
//       onPressed: showOverlay,
//     );
//   }

  // void showOverlay() {
  //   final toolbar = ZefyrToolbar.of(context);
  //   toolbar.showOverlay(buildOverlay);
  // }

  // Widget buildOverlay(BuildContext context) {
  //   final toolbar = ZefyrToolbar.of(context);
  //   final buttons = Row(
  //     children: <Widget>[
  //       // SizedBox(width: 8.0),
  //       // toolbar.buildButton(context, ZefyrToolbarAction.cameraImage,
  //       //     onPressed: _pickFromCamera),
  //       // toolbar.buildButton(context, ZefyrToolbarAction.galleryImage,
  //       //     onPressed: _pickFromGallery),
  //     ],
  //   );
  //   return ZefyrToolbarScaffold(body: buttons);
  // }

//   void _pickFromCamera() async {
//     final editor = ZefyrToolbar.of(context).editor;
//     final image = await editor.imageDelegate.pickImage(ImageSource.camera);
//     if (image != null)
//       editor.formatSelection(NotusAttribute.embed.image(image));
//   }

//   void _pickFromGallery() async {
//     final editor = ZefyrToolbar.of(context).editor;
//     final image = await editor.imageDelegate.pickImage(ImageSource.gallery);
//     if (image != null)
//       editor.formatSelection(NotusAttribute.embed.image(image));
//   }
// }

class LinkButton extends StatefulWidget {
  const LinkButton({Key key}) : super(key: key);

  @override
  _LinkButtonState createState() => _LinkButtonState();
}

class _LinkButtonState extends State<LinkButton> {
  final TextEditingController _inputController = TextEditingController();
  Key _inputKey;
  bool _formatError = false;
  ZefyrScope _editor;

  bool get isEditing => _inputKey != null;

  @override
  Widget build(BuildContext context) {
    final toolbar = ZefyrToolbar.of(context);
    final editor = toolbar.editor;
    final enabled =
        hasLink(editor.selectionStyle) || !editor.selection.isCollapsed;

    // return toolbar.buildButton(
    //   context,
    //   ZefyrToolbarAction.link,
    //   onPressed: enabled ? showOverlay : null,
    // );
  }

  bool hasLink(NotusStyle style) => style.contains(NotusAttribute.link);

  String getLink([String defaultValue]) {
    final editor = ZefyrToolbar.of(context).editor;
    final attrs = editor.selectionStyle;
    if (hasLink(attrs)) {
      return attrs.value(NotusAttribute.link);
    }
    return defaultValue;
  }

  // void showOverlay() {
  //   final toolbar = ZefyrToolbar.of(context);
  //   toolbar.showOverlay(buildOverlay).whenComplete(cancelEdit);
  // }

  // void closeOverlay() {
  //   final toolbar = ZefyrToolbar.of(context);
  //   //toolbar.closeOverlay();
  // }

  void edit() {
    final toolbar = ZefyrToolbar.of(context);
    setState(() {
      _inputKey = new UniqueKey();
      _inputController.text = getLink('https://');
      _inputController.addListener(_handleInputChange);
      toolbar.markNeedsRebuild();
    });
  }

  void doneEdit() {
    final toolbar = ZefyrToolbar.of(context);
    setState(() {
      var error = false;
      if (_inputController.text.isNotEmpty) {
        try {
          var uri = Uri.parse(_inputController.text);
          if ((uri.isScheme('https') || uri.isScheme('http')) &&
              uri.host.isNotEmpty) {
            toolbar.editor.formatSelection(
                NotusAttribute.link.fromString(_inputController.text));
          } else {
            error = true;
          }
        } on FormatException {
          error = true;
        }
      }
      if (error) {
        _formatError = error;
        toolbar.markNeedsRebuild();
      } else {
        _inputKey = null;
        _inputController.text = '';
        _inputController.removeListener(_handleInputChange);
        toolbar.markNeedsRebuild();
        toolbar.editor.focus();
      }
    });
  }

  void cancelEdit() {
    if (mounted) {
      final editor = ZefyrToolbar.of(context).editor;
      setState(() {
        _inputKey = null;
        _inputController.text = '';
        _inputController.removeListener(_handleInputChange);
        editor.focus();
      });
    }
  }

  void unlink() {
    final editor = ZefyrToolbar.of(context).editor;
    editor.formatSelection(NotusAttribute.link.unset);
    //closeOverlay();
  }

  void copyToClipboard() {
    var link = getLink();
    assert(link != null);
    Clipboard.setData(new ClipboardData(text: link));
  }

  void openInBrowser() async {
    final editor = ZefyrToolbar.of(context).editor;
    var link = getLink();
    assert(link != null);
    if (await canLaunch(link)) {
      editor.hideKeyboard();
      await launch(link, forceWebView: true);
    }
  }

  void _handleInputChange() {
    final toolbar = ZefyrToolbar.of(context);
    setState(() {
      _formatError = false;
      toolbar.markNeedsRebuild();
    });
  }

  // Widget buildOverlay(BuildContext context) {
  //   // final toolbar = ZefyrToolbar.of(context);
  //   // final style = toolbar.editor.selectionStyle;

  //   // String value = 'Tap to edit link';
  //   // if (style.contains(NotusAttribute.link)) {
  //   //   value = style.value(NotusAttribute.link);
  //   // }
  //   // final clipboardEnabled = value != 'Tap to edit link';
  //   // final body = !isEditing
  //   //     ? _LinkView(value: value, onTap: edit)
  //   //     : _LinkInput(
  //   //         key: _inputKey,
  //   //         controller: _inputController,
  //   //         formatError: _formatError,
  //   //       );
  //   // final items = <Widget>[Expanded(child: body)];
  //   // if (!isEditing) {
  //   //   final unlinkHandler = hasLink(style) ? unlink : null;
  //   //   final copyHandler = clipboardEnabled ? copyToClipboard : null;
  //   //   final openHandler = hasLink(style) ? openInBrowser : null;
  //   //   final buttons = <Widget>[
  //   //     // toolbar.buildButton(context, ZefyrToolbarAction.unlink,
  //   //     //     onPressed: unlinkHandler),
  //   //     // toolbar.buildButton(context, ZefyrToolbarAction.clipboardCopy,
  //   //     //     onPressed: copyHandler),
  //   //     // toolbar.buildButton(
  //   //     //   context,
  //   //     //   ZefyrToolbarAction.openInBrowser,
  //   //     //   onPressed: openHandler,
  //   //     // ),
  //   //   ];
  //   //   items.addAll(buttons);
  //   // }
  //   //final trailingPressed = isEditing ? doneEdit : closeOverlay;
  //   //final trailingAction =
  //       //isEditing ? ZefyrToolbarAction.confirm : ZefyrToolbarAction.close;

  //   // return ZefyrToolbarScaffold(
  //   //   body: Row(children: items),
  //   //   trailing: toolbar.buildButton(
  //   //     context,
  //   //     trailingAction,
  //   //     onPressed: trailingPressed,
  //   //   ),
  //   // );
  // }
}

class _LinkInput extends StatefulWidget {
  final TextEditingController controller;
  final bool formatError;

  const _LinkInput(
      {Key key, @required this.controller, this.formatError: false})
      : super(key: key);

  @override
  _LinkInputState createState() {
    return new _LinkInputState();
  }
}

class _LinkInputState extends State<_LinkInput> {
  final FocusNode _focusNode = FocusNode();

  ZefyrScope _editor;
  bool _didAutoFocus = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didAutoFocus) {
      FocusScope.of(context).requestFocus(_focusNode);
      _didAutoFocus = true;
    }

    final toolbar = ZefyrToolbar.of(context);

    if (_editor != toolbar.editor) {
      _editor?.toolbarFocusNode = null;
      _editor = toolbar.editor;
      _editor.toolbarFocusNode = _focusNode;
    }
  }

  @override
  void dispose() {
    _editor?.toolbarFocusNode = null;
    _focusNode.dispose();
    _editor = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final toolbarTheme = ZefyrTheme.of(context).toolbarTheme;
    final color =
        widget.formatError ? Colors.redAccent : toolbarTheme.iconColor;
    final style = theme.textTheme.subhead.copyWith(color: color);
    return TextField(
      style: style,
      keyboardType: TextInputType.url,
      focusNode: _focusNode,
      controller: widget.controller,
      autofocus: true,
      decoration: new InputDecoration(
        hintText: 'https://',
        filled: true,
        fillColor: toolbarTheme.color,
        border: InputBorder.none,
        contentPadding: const EdgeInsets.all(10.0),
      ),
    );
  }
}

class _LinkView extends StatelessWidget {
  const _LinkView({Key key, @required this.value, this.onTap})
      : super(key: key);
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final toolbarTheme = ZefyrTheme.of(context).toolbarTheme;
    Widget widget = new ClipRect(
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: <Widget>[
          Container(
            alignment: AlignmentDirectional.centerStart,
            constraints: BoxConstraints(minHeight: ZefyrToolbar.kToolbarHeight),
            padding: const EdgeInsets.all(10.0),
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.subhead
                  .copyWith(color: toolbarTheme.disabledIconColor),
            ),
          )
        ],
      ),
    );
    if (onTap != null) {
      widget = GestureDetector(
        child: widget,
        onTap: onTap,
      );
    }
    return widget;
  }
}
