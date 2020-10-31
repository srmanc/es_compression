## Description
Compression framework for Dart providing FFI implementations for Brotli, Lz4, Zstd with ready-to-use prebuilt binaries
for Win/Linux/Mac.

This work is an inspired port of the *Unified Compression Framework* from the [VAST Platform] (VA Smalltalk) language
and development environment.\
See the [Design Document](DESIGN.md) for detailed information on how this package was designed and implemented.

Below is a simple example of what an encode/decode would look like:
```dart
import 'dart:convert';
import 'package:es_compression/lz4.dart';

void main() {
  var bytes = utf8.encode('Hello Dart');
  var encoded = lz4.encode(bytes);
  var decoded = lz4.decode(encoded);
  print(utf8.decode(decoded));
}
```

## Executables
In the `bin` subdirectory, the following executables are provided.

| Executable    | Source                | Description                                            |
| --------------| ----------------------|------------------------------------------------------- |
| `escompress`  | `es_compress.dart`    | Encode/Decode files using brotli, gzip, lz4 and zstd   |

If you want to use escompress on the command line,
install it using `pub global activate`:

```console
> pub global activate escompress
```

### escompress
`escompress` is a program that will encode/decode files using `brotli`, `gzip`, `lz4` or `zstd`.

The user provides the input and output file names from the command line.\
By default, the file extension of either the input or output file name is used to determine which algorithm and
encode/decode mode to use.\
The user can provide additional command line arguments to make these decisions explicitly.\
Some examples are provided below.

#### Examples

Encode *input.txt* to *output.lz4* using Lz4 compression:
```console
> escompress -i"input.txt" -o"output.lz4"
```

Encode *input.txt* to *output.lz4* using Lz4 compression at compression level 3:
```console
> escompress -l 3 -i"input.txt" -o"output.lz4"
```

Decode *input.brotli* to *output.txt* using Brotli compression:
```console
> escompress -i"input.brotli" -o"output.txt"
```

Encode *input.txt* to *output.compressed* using Zstd compression:
```console
> escompress -e -a zstd -i"input.txt" -o"output.compressed"
```

Decode *input.compressed* to *output.txt* using GZip compression:
```console
> escompress -d -a gzip -i"input.compressed" -o"output.txt"
```

Print help:
```console
> escompress -h
```

## Examples
In the `example` subdirectory, the following examples are provided to demonstrate usage of the converters and the
framework.

| Example                   | Description                                                                               |
| ------------------------- | ----------------------------------------------------------------------------------------- |
| `brotli_example.dart`     | Encode/Decode in one-shot and streaming modes using the Brotli FFI-based implementation   |
| `lz4_example.dart`        | Encode/Decode in one-shot and streaming modes using the Lz4 FFI-based implementation      |
| `rle_example.dart`        | A simple RLE compression example designed to show how build custom codecs                 |
| `zstd_example.dart`       | Encode/Decode in one-shot and streaming modes using the Zstd FFI-based implementation     |

To run (brotli shown below):
```console
> dart example/brotli_example.dart
```

## Tests
In the `test` subdirectory, the following tests are provided for the compression framework and encoder/decoder
implementations.

| Test                  | Description                                                   |
| ----------------------| ------------------------------------------------------------- |
| `brotli_tests.dart`   | Test encoding/decode of the Brotli FFI-based implementation   |
| `buffer_tests.dart`   | Test `CodecBuffer` and friends in the compression framework   |
| `lz4_tests.dart`      | Test encoding/decode of the Lz4 FFI-based implementation      |
| `zstd_tests.dart`     | Test encoding/decode of the Zstd FFI-based implementation     |

To run test suite:
```console
> pub run test
```

## Benchmarks
In the `benchmark` subdirectory, the following benchmarks are provided to help understand encoder/decoder performance
and tradeoffs involved with parameters like buffer sizing.

| Benchmark                 | Description                                                        |
| ------------------------- | ------------------------------------------------------------------ |
| `brotli_benchmark.dart`   | Benchmark encoding/decode of the Brotli FFI-based implementation   |
| `gzip_benchmark.dart`     | Benchmark encoding/decode of the GZip implementation from the Dart SDK |
| `lz4_benchmark.dart`      | Benchmark encoding/decode of the Lz4 FFI-based implementation      |
| `zstd_benchmark.dart`     | Benchmark encoding/decode of the Zstd FFI-based implementation     |

To run (lz4 shown below):
```console
> dart benchmark/lz4_benchmark.dart
```

## Tools
In the `tool` subdirectory, the following tools are provided.

### Blob Builder
[blob_builder](tool/blob_builder) is a `cmake`-based build generator which builds all the prebuilt shared libraries and
copies them to their appropriate location in the dart library.

The maintainers use this tool to update the prebuilt shared libraries.\
It can also be used to build custom versions of the various libraries by making adjustments to CMake variables that
define the version level information.

Prebuilt shared libraries for Win/Linux/Mac are provided in the `blob` directory for each FFI codec implementation.\
The distributed shared libs for a codec named *xxx* is expected to be located in `lib/src/xxx/blobs`.

There are instructions in the main [CMakeLists.txt](tool/blob_builder/CMakeLists.txt) file that describe how to run
the tool.

## Framework
Initial codecs provided by this library use FFI-based implementations. However, the framework easily allows for pure
dart implementations for use within a web context.\
[rle_example.dart](example/rle_example.dart) shows a simple example of how to accomplish this.

The `GZipCodec` from `dart:io` served as a great starting point for understanding how to put the VAST Platform framework
abstractions in terms of Dart codecs, converters, filters, sinks.

The major compression framework abstractions are:
- `CodecConverter` - Connects the compression framework to `Converter` in `dart:convert`.
- `CodecFilter` - Direct processing of byte data and provides low-level compression implementation and hooks.
- `CodecSink` - A type of `ByteConversionSink` for efficient transmission of byte data.
- `CodecBuffer` - A buffer with a streaming API that is backed by either [native](lib/src/framework/native/buffers.dart)
or [dart](lib/src/framework/dart/buffers.dart) heap bytes.

### OS Shared Libraries
FFI-based implementations will need access to the low-level shared libraries (i.e. .dll, .so, .dylib).\
Prebuilt shared libraries for Win/Linux/Mac are provided in the `blob` directory for each FFI codec implementation.\
The distributed shared libs for a codec named *'xxx'* is expected to be located in `lib/src/xxx/blobs` by default.\
A flexible [library loader] exists that allows these locations to be customized.

#### Codec Configuration
Provided FFI Codecs have constructors with a `libraryPath` named parameter.

```dart
final codec = ZstdCodec(libraryPath: '/path/to/shared/library.so');
```

#### Environment Variables
An environment variable can be defined that provides the path to the shared library.\
This is either the path to the shared library file or the directory which contains it.\
See the comments for the mixin `OpenLibrary` in the [library loader];

| Codec      | Environment Variable  |
| -----------| --------------------- |
| `brotli`   | BROTLI_LIBRARY_PATH   |
| `lz4`      | LZ4_LIBRARY_PATH      |
| `zstd`     | ZSTD_LIBRARY_PATH     |

#### Code Signing

##### Windows
Provided dlls are digitally signed with an MS authenticode certificate owned by [Instantiations, Inc].

##### Linux
*N/A*

##### Mac
Provided dylibs are not currently signed, and recent versions of OSX will refuse to load them unless you allow
it from the *Security & Privacy* dialog.\
The build scripts have been provided [blob_builder](tool/blob_builder) and gives you access to build and sign them
yourself, if desired.\
*Instantiations may sign the libraries in the future, and if so, it will be noted in the changelog and here.*

## Features and bugs
Please file feature requests and bugs at the [issue tracker][tracker].\
They will be reviewed and addressed on a best-effort basis by [Instantiations, Inc].

[library loader]: lib/src/framework/native/open_library.dart
[tracker]: https://github.com/instantiations/es_compression/issues
[VAST Platform]: https://www.instantiations.com/products/vasmalltalk/index.html
[Instantiations, Inc]: https://www.instantiations.com

## About Us

Since 1988, Instantiations has been building software to meet the diverse and evolutionary needs of our customers. We've now added Dart and Flutter to our toolbox.
	
For more information about our custom development or consulting services with Dart, Flutter, and other languages, please visit: https://www.instantiations.com/services/
