// Copyright (c) 2020, Instantiations, Inc. Please see the AUTHORS
// file for details. All rights reserved. Use of this source code is governed by
// a BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:ffi';

import '../framework/buffers.dart';
import '../framework/converters.dart';
import '../framework/filters.dart';
import '../framework/sinks.dart';
import '../framework/native/buffers.dart';

import 'ffi/constants.dart';
import 'ffi/dispatcher.dart';
import 'ffi/types.dart';

/// The [BrotliDecoder] decoder is used by [BrotliCodec] to decompress brotli data.
class BrotliDecoder extends CodecConverter {
  /// Flag the determines if "canny" ring buffer allocation is enabled.
  /// Ring buffer is allocated according to window size, despite the real size
  /// of content.
  final bool ringBufferReallocation;

  /// Flag that determines if "Large Window Brotli" is ued.
  /// If set to [:true:], then the LZ-Window can be set up to 30-bits but the
  /// result will not be RFC7932 compliant.
  /// Default: [:false:]
  final bool largeWindow;

  /// Construct an [BrotliDecoder] with the supplied parameters.
  ///
  /// Validation will be performed which may result in a [RangeError] or
  /// [ArgumentError]
  BrotliDecoder({this.ringBufferReallocation = true, this.largeWindow = false});

  @override
  ByteConversionSink startChunkedConversion(Sink<List<int>> sink) {
    final byteSink = asByteSink(sink);
    return _BrotliDecoderSink._(byteSink, ringBufferReallocation, largeWindow);
  }
}

class _BrotliDecoderSink extends CodecSink {
  _BrotliDecoderSink._(
      ByteConversionSink sink, bool ringBufferReallocation, bool largeWindow)
      : super(sink,
            _makeBrotliDecompressFilter(ringBufferReallocation, largeWindow));
}

class _BrotliDecompressFilter extends CodecFilter<Pointer<Uint8>,
    NativeCodecBuffer, _BrotliDecodingResult> {
  /// Dispatcher to make calls via FFI to brotli shared library
  final BrotliDispatcher _dispatcher = BrotliDispatcher();

  final List<int> parameters = List(5);

  /// Native brotli state object
  BrotliDecoderState _state;

  _BrotliDecompressFilter(
      {bool ringBufferReallocation = true, bool largeWindow = false})
      : super() {
    parameters[BrotliConstants
            .BROTLI_DECODER_PARAM_DISABLE_RING_BUFFER_REALLOCATION] =
        ringBufferReallocation == false
            ? BrotliConstants.BROTLI_TRUE
            : BrotliConstants.BROTLI_FALSE;
    parameters[BrotliConstants.BROTLI_DECODER_PARAM_LARGE_WINDOW] =
        largeWindow == true
            ? BrotliConstants.BROTLI_TRUE
            : BrotliConstants.BROTLI_FALSE;
  }

  @override
  CodecBufferHolder<Pointer<Uint8>, NativeCodecBuffer> newBufferHolder(
      int length) {
    final holder = CodecBufferHolder<Pointer<Uint8>, NativeCodecBuffer>(length);
    return holder..bufferBuilderFunc = (length) => NativeCodecBuffer(length);
  }

  /// Init the filter
  ///
  /// Provide appropriate buffer lengths to codec builders
  /// [inputBufferHolder.length] decoding buffer length and
  /// [outputBufferHolder.length] encoding buffer length.
  @override
  int doInit(
      CodecBufferHolder<Pointer<Uint8>, NativeCodecBuffer> inputBufferHolder,
      CodecBufferHolder<Pointer<Uint8>, NativeCodecBuffer> outputBufferHolder,
      List<int> bytes,
      int start,
      int end) {
    _initState();
    return 0;
  }

  @override
  _BrotliDecodingResult doProcessing(
      NativeCodecBuffer inputBuffer, NativeCodecBuffer outputBuffer) {
    final result = _dispatcher.callBrotliDecoderDecompressStream(
        _state,
        inputBuffer.unreadCount,
        inputBuffer.readPtr,
        outputBuffer.unwrittenCount,
        outputBuffer.writePtr);
    final read = result[0];
    final written = result[1];
    final nextReadState = result[2];
    return _BrotliDecodingResult(read, written, nextReadState);
  }

  @override
  int doFlush(CodecBuffer outputBuffer) {
    return 0;
  }

  @override
  int doFinalize(CodecBuffer outputBuffer) {
    return 0;
  }

  /// Release lz4 resources
  @override
  void doClose() {
    _destroyState();
    _releaseDispatcher();
  }

  /// Apply the parameter value to the encoder.
  void _applyParameter(int parameter) {
    final value = parameters[parameter];
    if (value != null) {
      _dispatcher.callBrotliDecoderSetParameter(_state, parameter, value);
    }
  }

  void _initState() {
    final result = _dispatcher.callBrotliDecoderCreateInstance();
    if (result == nullptr) {
      throw StateError('Could not allocate brotli decoder state');
    }
    _state = result.ref;
    _applyParameter(
        BrotliConstants.BROTLI_DECODER_PARAM_DISABLE_RING_BUFFER_REALLOCATION);
    _applyParameter(BrotliConstants.BROTLI_DECODER_PARAM_LARGE_WINDOW);
  }

  void _destroyState() {
    if (_state != null) {
      try {
        _dispatcher.callBrotliDecoderDestroyInstance(_state);
      } finally {
        _state = null;
      }
    }
  }

  void _releaseDispatcher() {
    _dispatcher.release();
  }
}

/// Construct a new brotli filter which is configured with the options
/// provided
CodecFilter _makeBrotliDecompressFilter(
    bool ringBufferReallocation, bool largeWindow) {
  return _BrotliDecompressFilter(
      ringBufferReallocation: ringBufferReallocation, largeWindow: largeWindow);
}

/// Result object for an Brotli Decompression operation
class _BrotliDecodingResult extends CodecResult {
  /// Next state of the decoder.
  final int nextReadState;

  const _BrotliDecodingResult(
      int bytesRead, int bytesWritten, this.nextReadState)
      : super(bytesRead, bytesWritten);
}