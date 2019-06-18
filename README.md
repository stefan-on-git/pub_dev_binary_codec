# binary_codec
Dart library for converting standard data types to a binary format and back

Supported datatypes: Null, bool, double, int, Uint8List, String, Map, List. Maps and Lists may contain any of the supported datatypes as keys and values.

On dart2js ints are always encoded as doubles. And if you try to decode ints on dart2js out of the safe range you will probably not get the exact value. But as long as you stay on one platform (not switching between dartvm and dart2js) your on the safe side and don't need to think about it.
