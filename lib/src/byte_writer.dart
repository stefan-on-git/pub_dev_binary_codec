import 'dart:typed_data';

class ByteWriter {
  static const _initialLength = 8;

  var _buffer = Uint8List(_initialLength);
  var _length = _initialLength;
  var _index = 0;

  int get currentLength => _index;

  void _reserve(int byteCount) {
    assert(byteCount != null);
    assert(byteCount >= 0);
    while (_index + byteCount > _length) {
      _length *= 2;
    }
    if (_length != _buffer.length) {
      var next = Uint8List(_length);
      next.setRange(0, _index, _buffer);
      _buffer = next;
    }
  }

  void write(int byte) {
    assert(byte != null);
    _reserve(1);
    _buffer[_index++] = byte;
  }

  void writeAll(Iterable<int> bytes) {
    assert(bytes != null);
    _reserve(bytes.length);
    _buffer.setRange(_index, _index + bytes.length, bytes);
    _index += bytes.length;
  }

  Uint8List done() {
    var result = Uint8List.view(_buffer.buffer, 0, _index);
    _buffer = Uint8List(_initialLength);
    _index = 0;
    return result;
  }
}
