import 'dart:convert';
import 'dart:typed_data';

import 'src/binary_codec.dart';

/// Converts between dynamic and Uint8List
///
/// Supported dynamic types: Null, bool, double, int, Uint8List, String, Map, List
///
/// Uint8List is slightly more efficient (especially for small lists) than List<int> which is also supported
///
/// Map and List may contain keys and values of any of the supported types
///
/// Note (dart2js): Encoding an int in dart2js will always encode as a double, since that is the underlying datatype
///
/// Note (dart2js): If you are encoding data in dartvm and decoding in dart2js ints bigger than 2^54
/// or smaller than -2^54 will only be approximately correct (because again, there are not standard ints in dart2js)
const Codec<dynamic, Uint8List> binaryCodec = const BinaryCodec();
