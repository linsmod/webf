/*
 * Copyright (C) 2019-2022 The Kraken authors. All rights reserved.
 * Copyright (C) 2022-present The WebF authors. All rights reserved.
 */
#include "array_buffer.h"
#include <modp_b64/modp_b64.h>
#include <string>
#include "bindings/qjs/script_promise_resolver.h"
#include "built_in_string.h"
#include "core/executing_context.h"

namespace webf {

ArrayBuffer* ArrayBuffer::Create(ExecutingContext* context, ExceptionState& exception_state) {
  return MakeGarbageCollected<ArrayBuffer>(context->ctx());
}

ArrayBuffer* ArrayBuffer::Create(ExecutingContext* context) {
  return MakeGarbageCollected<ArrayBuffer>(context->ctx());
}

ArrayBuffer* ArrayBuffer::Create(ExecutingContext* context,
                   int32_t byteLength,
                   ExceptionState& exception_state) {
  return MakeGarbageCollected<ArrayBuffer>(context->ctx(), byteLength);
}

int32_t ArrayBuffer::byteLength() {
  return _data.size();
}

uint8_t* ArrayBuffer::bytes() {
  return _data.data();
}

void ArrayBuffer::Trace(GCVisitor* visitor) const {}

ArrayBuffer* ArrayBuffer::slice(int64_t start, ExceptionState& exception_state) {
  return slice(start, _data.size(), exception_state);
}

ArrayBuffer* ArrayBuffer::slice(ExceptionState& exception_state) {
  return slice(0, _data.size(), exception_state);
}
ArrayBuffer* ArrayBuffer::slice(int64_t start, int64_t end, ExceptionState& exception_state) {
  auto* newBlob = MakeGarbageCollected<ArrayBuffer>(ctx());
  std::vector<uint8_t> newData;
  newData.reserve(_data.size() - (end - start));
  newData.insert(newData.begin(), _data.begin() + start, _data.end() - (_data.size() - end));
  newBlob->_data = newData;
  return newBlob;
}

std::string ArrayBuffer::StringResult() {
  return std::string(bytes(), bytes() + byteLength());
}
}  // namespace webf
