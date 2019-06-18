import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'byte_reader.dart';
import 'byte_writer.dart';
import 'tags.dart';

class BinaryCodec extends Codec<dynamic, Uint8List> {
  const BinaryCodec();

  @override
  Converter<Uint8List, dynamic> get decoder => Decoder();

  @override
  Converter<dynamic, Uint8List> get encoder => Encoder();
}

class Decoder extends Converter<Uint8List, dynamic> {
  @override
  dynamic convert(Uint8List input) {
    return decode(ByteReader(input));
  }

  dynamic decode(ByteReader reader) {
    int tag = reader.read();
    if (tag < Tags.vNegInt) {
      return tag - Tags.vPosInt;
    } else if (tag < Tags.vShortBlob) {
      return -(tag - Tags.vNegInt);
    } else if (tag < Tags.vShortText) {
      return decodeBlob(tag - Tags.vShortBlob, reader);
    } else if (tag < Tags.vInt) {
      return decodeText(tag - Tags.vShortText, reader);
    } else if (tag < Tags.vNull) {
      return decodeInt(tag, reader);
    } else if (tag == Tags.vNull) {
      return null;
    } else if (tag == Tags.vTrue) {
      return true;
    } else if (tag == Tags.vFalse) {
      return false;
    } else if (tag == Tags.vDouble) {
      return decodeDouble(reader);
    } else if (tag == Tags.vBlob) {
      return decodeBlob(decodeLength(reader), reader);
    } else if (tag == Tags.vText) {
      return decodeText(decodeLength(reader), reader);
    } else if (tag == Tags.vList) {
      return decodeList(reader);
    } else if (tag == Tags.vMap) {
      return decodeMap(reader);
    } else {
      throw 'Tag \'$tag\' not handled';
    }
  }

  int decodeInt(int tag, ByteReader reader) {
    int byteCountMinusOne = tag - Tags.vInt;
    var value = 0;
    for (int i = 0; i < byteCountMinusOne; i++) {
      value += pow(2, i * 8) * reader.read();
    }
    var last = reader.read();
    value += pow(2, byteCountMinusOne * 8) * (last & 0x7F);
    if (last & 0x80 != 0) {
      value -= pow(2, byteCountMinusOne * 8 + 7);
    }
    return value;
  }

  double decodeDouble(ByteReader reader) {
    var bytes = reader.readAll(8);
    return bytes.buffer
        .asByteData(bytes.offsetInBytes, 8)
        .getFloat64(0, Endian.little);
  }

  int decodeLength(ByteReader reader) {
    int tag = reader.read();
    if (tag < Tags.vNegInt) {
      return tag - Tags.vPosInt;
    } else if (tag < Tags.vInt) {
      throw 'Tag \'$tag\' is no length';
    } else if (tag < Tags.vNull) {
      return decodeInt(tag, reader);
    } else if (tag == Tags.vDouble) {
      // Also expect doubles as length for dart2js
      var length = decodeDouble(reader);
      var rounded = length.round();
      if (length != rounded) {
        throw 'Tag \'$tag\' is a double value ($length) and no length (lengths must have no decimal places)';
      }
      return rounded;
    } else {
      throw 'Tag \'$tag\' is no length';
    }
  }

  Uint8List decodeBlob(int length, ByteReader reader) {
    return reader.readAll(length);
  }

  String decodeText(int length, ByteReader reader) {
    return utf8.decode(decodeBlob(length, reader));
  }

  List decodeList(ByteReader reader) {
    int length = decodeLength(reader);
    var list = List();
    for (int i = 0; i < length; i++) {
      list.add(decode(reader));
    }
    return list;
  }

  Map decodeMap(ByteReader reader) {
    int length = decodeLength(reader);
    var map = Map();
    for (int i = 0; i < length; i++) {
      var key = decode(reader);
      var value = decode(reader);
      map[key] = value;
    }
    return map;
  }
}

class Encoder extends Converter<dynamic, Uint8List> {
  @override
  Uint8List convert(dynamic value) {
    ByteWriter writer = ByteWriter();
    encode(value, writer);
    return writer.done();
  }

  void encode(dynamic value, ByteWriter writer) {
    if (value == null) {
      writer.write(Tags.vNull);
    } else if (value is bool) {
      writer.write(value ? Tags.vTrue : Tags.vFalse);
    } else if (value is double) {
      // Check for doubles first because of dart2js
      encodeDouble(value, writer);
    } else if (value is int) {
      encodeInt(value, writer);
    } else if (value is Uint8List) {
      encodeBlob(value, writer);
    } else if (value is String) {
      encodeText(value, writer);
    } else if (value is List) {
      encodeList(value, writer);
    } else if (value is Map) {
      encodeMap(value, writer);
    } else {
      throw 'Type of $value is not supported (${value.runtimeType})';
    }
  }

  void encodeDouble(double value, ByteWriter writer) {
    writer.write(Tags.vDouble);
    var bytes = Uint8List(8);
    bytes.buffer.asByteData().setFloat64(0, value, Endian.little);
    writer.writeAll(bytes);
  }

  void encodeInt(int value, ByteWriter writer) {
    if (value >= 0 && value < 128) {
      writer.write(Tags.vPosInt + value);
    } else if (value < 0 && value > -64) {
      writer.write(Tags.vNegInt - value);
    } else {
      int byteCountMinusOne = (value.bitLength / 8).floor();
      writer.write(Tags.vInt + byteCountMinusOne);
      bool neg = value < 0;
      if (neg) {
        value = -value - 1;
      }
      for (int i = 0; i <= byteCountMinusOne; i++) {
        var byte = value ~/ pow(2, i * 8);
        if (neg) {
          byte = -(byte + 1);
        }
        writer.write(byte);
      }
    }
  }

  void encodeLength(int length, ByteWriter writer) {
    // Store lengths in dart2js as doubles
    if (identical(0, 0.0)) {
      encodeDouble(length.toDouble(), writer);
    } else {
      encodeInt(length, writer);
    }
  }

  void encodeBlob(Uint8List value, ByteWriter writer) {
    encodeData(value, false, writer);
  }

  void encodeText(String value, ByteWriter writer) {
    encodeData(utf8.encode(value), true, writer);
  }

  void encodeData(Uint8List value, bool isText, ByteWriter writer) {
    var length = value.length;
    if (length < 24) {
      int tag = isText ? Tags.vShortText : Tags.vShortBlob;
      writer.write(tag + length);
    } else {
      writer.write(isText ? Tags.vText : Tags.vBlob);
      encodeLength(length, writer);
    }
    writer.writeAll(value);
  }

  void encodeList(List value, ByteWriter writer) {
    writer.write(Tags.vList);
    encodeLength(value.length, writer);
    for (var element in value.toList()) {
      encode(element, writer);
    }
  }

  void encodeMap(Map value, ByteWriter writer) {
    writer.write(Tags.vMap);
    encodeLength(value.length, writer);
    for (var entry in value.entries.toList()) {
      encode(entry.key, writer);
      encode(entry.value, writer);
    }
  }
}
