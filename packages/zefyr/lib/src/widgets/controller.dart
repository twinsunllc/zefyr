// Copyright (c) 2018, the Zefyr project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:notus/notus.dart';
import 'package:quill_delta/quill_delta.dart';
import 'package:zefyr/util.dart';

const TextSelection _kZeroSelection = const TextSelection.collapsed(
  offset: 0,
  affinity: TextAffinity.upstream,
);

/// Owner of focus.
enum FocusOwner {
  /// Current owner is the editor.
  editor,

  /// Current owner is the toolbar.
  toolbar,

  /// No focus owner.
  none,
}

/// Controls instance of [ZefyrEditor].
class ZefyrController extends ChangeNotifier {
  ZefyrController(NotusDocument document)
      : assert(document != null),
        _document = document;

  /// Zefyr document managed by this controller.
  NotusDocument get document => _document;
  NotusDocument _document;

  /// Currently selected text within the [document].
  TextSelection get selection => _selection;
  TextSelection _selection = _kZeroSelection;

  final List<NotusAttribute> _toggledAttributes = [];

  ChangeSource _lastChangeSource;

  /// Source of the last text or selection change.
  ChangeSource get lastChangeSource => _lastChangeSource;

  /// Updates selection with specified [value].
  ///
  /// [value] and [source] cannot be `null`.
  void updateSelection(TextSelection value, {ChangeSource source: ChangeSource.remote}) {
    _updateSelectionSilent(value, source: source);
    notifyListeners();
  }

  // Updates selection without triggering notifications to listeners.
  void _updateSelectionSilent(TextSelection value, {ChangeSource source: ChangeSource.remote}) {
    assert(value != null && source != null);
    _selection = value;
    _lastChangeSource = source;
    _ensureSelectionBeforeLastBreak();
  }

  @override
  void dispose() {
    _document.close();
    super.dispose();
  }

  /// Composes [change] into document managed by this controller.
  ///
  /// This method does not apply any adjustments or heuristic rules to
  /// provided [change] and it is caller's responsibility to ensure this change
  /// can be composed without errors.
  ///
  /// If composing this change fails then this method throws [ComposeError].
  void compose(Delta change, {TextSelection selection, ChangeSource source: ChangeSource.remote}) {
    if (change.isNotEmpty) {
      _document.compose(change, source);
    }
    if (selection != null) {
      _updateSelectionSilent(selection, source: source);
    } else {
      // Transform selection against the composed change and give priority to
      // current position (force: false).
      final base = change.transformPosition(_selection.baseOffset, force: false);
      final extent = change.transformPosition(_selection.extentOffset, force: false);
      selection = _selection.copyWith(baseOffset: base, extentOffset: extent);
      if (_selection != selection) {
        _updateSelectionSilent(selection, source: source);
      }
    }
    _lastChangeSource = source;
    notifyListeners();
  }

  void replaceText(int index, int length, String text, {TextSelection selection}) {

    Delta delta;

    Map attributes = Map<String, dynamic>();

    if (length > 0 || text.isNotEmpty) {
      delta = document.replace(index, length, text);
    }

    if (selection != null) {
      if (delta == null) {
        _updateSelectionSilent(selection, source: ChangeSource.local);
      } else {
        // need to transform selection position in case actual delta
        // is different from user's version (in deletes and inserts).
        Delta user = new Delta()
          ..retain(index)
          ..insert(text, attributes)
          ..delete(length);
        int positionDelta = getPositionDelta(user, delta);
        _updateSelectionSilent(
          selection.copyWith(
            baseOffset: selection.baseOffset + positionDelta,
            extentOffset: selection.extentOffset + positionDelta,
          ),
          source: ChangeSource.local,
        );
      }
    }

    _lastChangeSource = ChangeSource.local;
    notifyListeners();

    if (delta != null) {
      for(var i = 0; i < delta.length; i++){
        if(delta.elementAt(i).isDelete){
          _toggledAttributes.clear();
        }
      }
      _toggledAttributes.forEach((NotusAttribute attributeToAdd) {
        formatText(index, 1, attributeToAdd);
      });
    }
  }

  void formatText(int index, int length, NotusAttribute attribute) {
    final change = document.format(index, length, attribute);
    _lastChangeSource = ChangeSource.local;
    // Transform selection against the composed change and give priority to
    // the change. This is needed in cases when format operation actually
    // inserts data into the document (e.g. embeds).
    final base = change.transformPosition(_selection.baseOffset);
    final extent = change.transformPosition(_selection.extentOffset);
    final adjustedSelection = _selection.copyWith(baseOffset: base, extentOffset: extent);
    if (_selection != adjustedSelection) {
      _updateSelectionSilent(adjustedSelection, source: _lastChangeSource);
    }
    notifyListeners();
  }

  void toggleOnStyle(NotusAttribute attribute) {
    _toggledAttributes.remove(attribute.unset);
    _toggledAttributes.remove(attribute);
    _toggledAttributes.add(attribute);
    //notifyListeners();
  }

  void toggleOffStyle(NotusAttribute attribute) {
    _toggledAttributes.remove(attribute);
    _toggledAttributes.remove(attribute.unset);
    _toggledAttributes.add(attribute.unset);
    //notifyListeners();
  }

  List<NotusAttribute> get currentToggles => _toggledAttributes;

  /// Formats current selection with [attribute].
  void formatSelection(NotusAttribute attribute, {TextSelection selectedText}) {
    int index = (selectedText != null) ? selectedText.start : _selection.start;
    int length = (selectedText != null) ? selectedText.end - index : _selection.end - index;
    formatText(index, length, attribute);
  }

  TextSelection getSelectedText() {
    return _selection;
  }

  NotusStyle getSelectionStyle() {
    int start = _selection.start;
    int length = _selection.end - start;
    return _document.collectStyle(start, length);
  }

  TextEditingValue get plainTextEditingValue {
    return new TextEditingValue(
      text: document.toPlainText(),
      selection: selection,
      composing: new TextRange.collapsed(0),
    );
  }

  void _ensureSelectionBeforeLastBreak() {
    final end = _document.length - 1;
    final base = math.min(_selection.baseOffset, end);
    final extent = math.min(_selection.extentOffset, end);
    _selection = _selection.copyWith(baseOffset: base, extentOffset: extent);
  }
}
