/*
 * Copyright (C) 2019-2022 The Kraken authors. All rights reserved.
 * Copyright (C) 2022-present The WebF authors. All rights reserved.
 */
#ifndef BRIDGE_ARRAYBUFFER_H
#define BRIDGE_ARRAYBUFFER_H

#include <cstdint>
#include <string>
#include <vector>
#include "array_buffer_data.h"
#include "bindings/qjs/macros.h"
#include "bindings/qjs/script_promise.h"
#include "bindings/qjs/script_wrappable.h"
#include "blob_part.h"
#include "blob_property_bag.h"

namespace webf {

class ArrayBuffer : public ScriptWrappable {
  DEFINE_WRAPPERTYPEINFO();

 public:
  using ImplType = ArrayBuffer*;
  static ArrayBuffer* Create(ExecutingContext* context, ExceptionState& exception_state);
  static ArrayBuffer* Create(ExecutingContext* context);
  static ArrayBuffer* Create(ExecutingContext* context,
                      int32_t byteLength,
                      ExceptionState& exception_state);

  ArrayBuffer() = delete;
  explicit ArrayBuffer(JSContext* ctx) : ScriptWrappable(ctx){};
  explicit ArrayBuffer(JSContext* ctx, const int32_t byteLength) : ScriptWrappable(ctx){};
  /// get an pointer of bytes data from JSBlob
  uint8_t* bytes();
  /// get bytes data's length
  int32_t byteLength();

  ArrayBuffer* slice(ExceptionState& exception_state);
  ArrayBuffer* slice(int64_t start, ExceptionState& exception_state);
  ArrayBuffer* slice(int64_t start, int64_t end, ExceptionState& exception_state);

  void Trace(GCVisitor* visitor) const override;
  std::string StringResult();

 private:
  std::vector<uint8_t> _data;
};

}  // namespace webf

#endif  // BRIDGE_ARRAYBUFFER_H
