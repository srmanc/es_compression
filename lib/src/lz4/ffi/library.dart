// Copyright (c) 2020, Seth Berman (Instantiations, Inc). Please see the AUTHORS
// file for details. All rights reserved. Use of this source code is governed by
// a BSD-style license that can be found in the LICENSE file.

import 'dart:ffi';

import 'constants.dart';
import 'functions.dart';
import 'types.dart';

/// An [Lz4Library] is the gateway to the native Lz4 shared library.
///
/// It has a series of mixins for making available constants, types and
/// functions that are described in C header files.
class Lz4Library with Lz4Constants, Lz4Functions, Lz4Types {
  static final Lz4Library _instance = Lz4Library._();

  DynamicLibrary _libraryImpl;

  /// Lz4 Version Number
  int versionNumber;

  /// Return the [Lz4Library] singleton library instance.
  factory Lz4Library() {
    return _instance;
  }

  Lz4Library._() {
    // TODO: Have this configurable and platform-detectable
    _libraryImpl = DynamicLibrary.open('lib/src/lz4/blobs/eslz4_c-win64.dll');
    resolveFunctions(_libraryImpl);
  }
}
