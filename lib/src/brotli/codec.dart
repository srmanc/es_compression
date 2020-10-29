// Copyright (c) 2020, Instantiations, Inc. Please see the AUTHORS
// file for details. All rights reserved. Use of this source code is governed by
// a BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import '../../framework.dart';
import 'decoder.dart';
import 'encoder.dart';
import 'ffi/dispatcher.dart';
import 'ffi/library.dart';
import 'options.dart';

/// The [BrotliCodec] encodes/decodes raw bytes using the Brotli algorithm
class BrotliCodec extends Codec<List<int>, List<int>> {
  /// The compression-[level] or quality can be set in the range of
  /// [BrotliOption.minLevel]..[BrotliOption.maxLevel].
  /// The higher the level, the slower the compression.
  /// Default: [BrotliOption.defaultLevel]
  final int level;

  /// Tune the encoder for a specific input.
  /// The allowable values are:
  /// [BrotliOption.fontMode], [BrotliOption.genericMode],
  /// [BrotliOption.textMode], [BrotliOption.defaultMode].
  /// Default: [BrotliOption.defaultMode].
  final int mode;

  /// Recommended sliding LZ77 windows bit size.
  /// The encoder may reduce this value if the input is much smaller than the
  /// windows size.
  /// Range: [BrotliOption.minWindowBits]..[BrotliOption.maxWindowBits]
  /// Default: [BrotliOption.defaultWindowBits].
  final int windowBits;

  /// Recommended input block size.
  /// Encoder may reduce this value, e.g. if the input is much smalltalk than
  /// the input block size.
  /// Range: [BrotliOption.minBlockBits]..[BrotliOption.maxBlockBits].
  /// Default: nil (dynamically computed).
  final int blockBits;

  /// Recommended number of postfix bits.
  /// Encode may change this value.
  /// Range: [BrotliOption.minPostfixBits]..[BrotliOption.maxPostfixBits]
  final int postfixBits;

  /// Flag that affects usage of "literal context modeling" format feature.
  /// This flag is a "decoding-speed vs compression ratio" trade-off.
  /// Default: [:true:]
  final bool literalContextModeling;

  /// Estimated total input size for all encoding compress stream calls.
  /// Default: 0 (means the total input size if unknown).
  final int sizeHint;

  /// Flag that determines if "Large Window Brotli" is ued.
  /// If set to [:true:], then the LZ-Window can be set up to 30-bits but the
  /// result will not be RFC7932 compliant.
  /// Default: [:false:]
  final bool largeWindow;

  /// Recommended number of direct distance codes.
  /// Encoder may change this value.
  final int directDistanceCodeCount;

  /// Flag the determines if "canny" ring buffer allocation is enabled.
  /// Ring buffer is allocated according to window size, despite the real size
  /// of content.
  final bool ringBufferReallocation;

  /// Length in bytes of the buffer used for input data.
  ///
  /// Note: This is a preferred value. There are algorithm specific
  /// constraints that may need to coerce this value to a required minimum or
  /// maximum.
  final int inputBufferLength;

  /// Length in bytes of the buffer used for processed output data.
  ///
  /// Note: This is a preferred value. There are algorithm specific
  /// constraints that may need to coerce this value to a required minimum or
  /// maximum.
  final int outputBufferLength;

  /// Return the base binding version this binding code was developed for.
  BrotliVersion get bindingVersion => BrotliVersion(0x1000009);

  /// Return the encoder library version.
  BrotliVersion get encoderVersion =>
      BrotliVersion(BrotliDispatcher.encoderVersionNumber);

  /// Return the decoder library version.
  BrotliVersion get decoderVersion =>
      BrotliVersion(BrotliDispatcher.decoderVersionNumber);

  /// Construct an [BrotliCodec] that is configured with the following parameters.
  ///
  /// Default values are provided for unspecified parameters.
  /// Validation is performed which may result in throwing a [RangeError] or
  /// [ArgumentError]
  BrotliCodec(
      {this.level = BrotliOption.defaultLevel,
      this.mode = BrotliOption.defaultMode,
      this.windowBits = BrotliOption.defaultWindowBits,
      this.blockBits,
      this.postfixBits,
      this.literalContextModeling = true,
      this.sizeHint = 0,
      this.largeWindow = false,
      this.directDistanceCodeCount,
      this.ringBufferReallocation = true,
      this.inputBufferLength = CodecBufferHolder.autoLength,
      this.outputBufferLength = CodecBufferHolder.autoLength,
      String libraryPath}) {
    validateBrotliLevel(level);
    validateBrotliWindowBits(windowBits);
    validateBrotliBlockBits(blockBits);
    validateBrotliPostfixBits(postfixBits);
    if (libraryPath != null) BrotliLibrary.userDefinedLibraryPath = libraryPath;
  }

  const BrotliCodec._default()
      : level = BrotliOption.defaultLevel,
        mode = BrotliOption.defaultMode,
        windowBits = BrotliOption.defaultWindowBits,
        blockBits = null,
        postfixBits = null,
        literalContextModeling = true,
        sizeHint = 0,
        largeWindow = false,
        directDistanceCodeCount = null,
        ringBufferReallocation = true,
        inputBufferLength = CodecBufferHolder.autoLength,
        outputBufferLength = CodecBufferHolder.autoLength;

  @override
  Converter<List<int>, List<int>> get encoder => BrotliEncoder(
      level: level,
      mode: mode,
      windowBits: windowBits,
      blockBits: blockBits,
      postfixBits: postfixBits,
      literalContextModeling: literalContextModeling,
      sizeHint: sizeHint,
      largeWindow: largeWindow,
      directDistanceCodeCount: directDistanceCodeCount,
      inputBufferLength: inputBufferLength,
      outputBufferLength: outputBufferLength);

  @override
  Converter<List<int>, List<int>> get decoder => BrotliDecoder(
      ringBufferReallocation: ringBufferReallocation,
      largeWindow: largeWindow,
      inputBufferLength: inputBufferLength,
      outputBufferLength: outputBufferLength);
}

/// Helper class to decode the version number returned from the brotli FFI
/// library.
class BrotliVersion {
  /// Encoded version number from brotli.
  final int versionNumber;

  const BrotliVersion(this.versionNumber);

  /// Return the major element of the version.
  int get major => versionNumber >> 24;

  /// Return the minor element of the version.
  int get minor => (versionNumber >> 12) & 0xFFF;

  /// Return the patch element of the version.
  int get patch => versionNumber & 0xFFF;

  @override
  String toString() => '$major.$minor.$patch';
}

/// An instance of the default implementation of the [BrotliCodec].
const BrotliCodec brotli = BrotliCodec._default();
