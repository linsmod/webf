/*
 * Copyright (C) 2019-present Alibaba Inc. All rights reserved.
 * Author: Kraken Team.
 */

import 'package:flutter/rendering.dart';
import 'package:kraken/rendering.dart';
import 'package:kraken/src/style/css_style_declaration.dart';
import 'css_style_declaration.dart';

mixin FlowMixin {
  static const String TEXT_ALIGN = 'textAlign';

  void decorateRenderFlow(RenderObject renderObject, CSSStyleDeclaration style) {
    if (style != null && renderObject is RenderFlowLayout) {
      renderObject.mainAxisAlignment = _getTextAlign(style);
    }
  }

  MainAxisAlignment _getTextAlign(CSSStyleDeclaration style) {
    MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start;

    if (style.contains(TEXT_ALIGN)) {
      String textAlign = style[TEXT_ALIGN];
      switch (textAlign) {
        case 'right':
          mainAxisAlignment = MainAxisAlignment.end;
          break;
        case 'center':
          mainAxisAlignment = MainAxisAlignment.center;
          break;
      }
    }

    return mainAxisAlignment;
  }
}

