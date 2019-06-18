import 'dart:math';
import 'dart:typed_data';

import '../lib/binary_codec.dart';

/// Example text
const loremIpsum = 'Lorem ipsum dolor sit amet, consetetur sadipscing elitr, '
    'sed diam nonumy eirmod tempor invidunt ut labore et dolore '
    'magna aliquyam erat, sed diam voluptua. At vero eos et accusam '
    'et justo duo dolores et ea rebum. Stet clita kasd gubergren, no '
    'sea takimata sanctus est Lorem ipsum dolor sit amet. Lorem '
    'ipsum dolor sit amet, consetetur sadipscing elitr, sed diam '
    'nonumy eirmod tempor invidunt ut labore et dolore magna '
    'aliquyam erat, sed diam voluptua. At vero eos et accusam '
    'et justo duo dolores et ea rebum. Stet clita kasd gubergren, '
    'no sea takimata sanctus est Lorem ipsum dolor sit amet.';

void main() {
  var exampleObject = generateSomeData();

  /// Encode the generated data
  Uint8List encoded = binaryCodec.encode(exampleObject);

  /// Decode the encoded data
  var decoded = binaryCodec.decode(encoded);

  /// Check if they are the same
  if (exampleObject.toString() == decoded.toString()) {
    /// They should be the same
    print('Success');
  } else {
    /// Else theres a bug in the library
    /// Please send the [exampleObject] that leads here and on which 
    /// platform you are to the author of this library (stefan.zemljic@gmx.ch)
    print('Wait... What???');
  }
}

dynamic generateSomeData() {
  var random = Random();
  var shortBinaryLists = List.generate(16, (length) {
    return Uint8List.fromList(
      List.generate(length, (_) => random.nextInt(256)),
    );
  });
  var someDoubles = [
    2930543.324960,
    -134943.2345,
    0.0,
    1.0,
    -1.0,
    double.infinity,
    double.nan,
    double.maxFinite,
    double.negativeInfinity,
    double.minPositive,
  ];
  var someInts = [321, 43956, -23459, 0, 1, -1, -239458];
  return {
    'small positive ints': List.generate(128, (x) => x),
    'small negative ints': List.generate(64, (x) => -x),
    'short binary lists': shortBinaryLists,
    'short texts': ['hello world', 'lorem ipsum', 'asdf qwer jklö'],
    'ints': someInts,
    'null': null,
    'booleans': [true, false],
    'doubles': someDoubles,
    'bigger binary lists':
        Uint8List.fromList(List.generate(1266, (x) => x % 256)),
    'bigger texts': loremIpsum.substring(0, 430),
    'lists': ['1', 2, 3.0, List.generate(4, (_) => 4), 'Five'],
    'maps': {'key1': 'value1', true: false, false: true, 4.0: 4, 5: 5.0},
  };
}
